extends Control

signal back_clicked()
signal edit_event_clicked(event: Event)

@onready var api = get_tree().root.get_node("Main/APIManager")
@onready var back_button = $TopBar/BackButton
@onready var edit_button = $TopBar/EditButton
@onready var delete_button = $TopBar/DeleteButton
@onready var scroll_container = $ScrollContainer
@onready var title_label = $ScrollContainer/VBox/Title
@onready var category_label = $ScrollContainer/VBox/Category
@onready var date_label = $ScrollContainer/VBox/DateTimeSection/DateTime
@onready var location_label = $ScrollContainer/VBox/LocationSection/Location
@onready var organizer_label = $ScrollContainer/VBox/OrganizerSection/Organizer
@onready var contact_label = $ScrollContainer/VBox/ContactSection/Contact
@onready var description_label = $ScrollContainer/VBox/DescriptionSection/Description

var current_event: Event
var comments_container: VBoxContainer
var comment_input: TextEdit
var comment_submit_button: Button
var comments_list: VBoxContainer
var discussion_board_button: Button
var comments_panel: PanelContainer

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	edit_button.pressed.connect(_on_edit_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	api.event_deleted.connect(_on_event_deleted)
	api.comment_added.connect(_on_comment_added)
	api.comments_fetched.connect(_on_comments_fetched)

	# Track screen view
	Analytics.track_screen_view("event_detail")

	# Create comments section
	_create_comments_section()

	# Create "See Discussion Board" button
	_create_discussion_button()

func set_event(event: Event):
	current_event = event
	_update_display()

	# Track event view
	Analytics.track_event(Config.ANALYTICS_EVENTS["event_viewed"], {
		"event_id": event.id,
		"category": event.category
	})

	# Load comments for this event
	api.fetch_comments(event.id)

func _update_display():
	if not current_event:
		return

	title_label.text = current_event.title
	category_label.text = "📂 " + current_event.get_category_display()
	date_label.text = current_event.get_formatted_datetime()
	location_label.text = current_event.location
	organizer_label.text = current_event.organizer
	contact_label.text = current_event.contact_info if current_event.contact_info != "" else "No contact info provided"
	description_label.text = current_event.description if current_event.description != "" else "No description provided"

	# Color code by category
	var category_color = _get_category_color(current_event.category)
	title_label.add_theme_color_override("font_color", category_color)

	# Only show edit/delete for own events (simplified - in production check user ID)
	# For now, show to everyone
	edit_button.visible = true
	delete_button.visible = true

func _get_category_color(category: String) -> Color:
	match category:
		"garage_sale":
			return Color(0.4, 0.8, 0.4)
		"sports":
			return Color(0.4, 0.6, 1.0)
		"church":
			return Color(0.9, 0.7, 0.4)
		"town_meeting":
			return Color(0.8, 0.4, 0.4)
		"community":
			return Color(0.7, 0.5, 0.9)
		"fundraiser":
			return Color(1.0, 0.6, 0.4)
		"workshop":
			return Color(0.5, 0.8, 0.8)
		"festival":
			return Color(1.0, 0.5, 0.7)
		_:
			return Color.WHITE

func _on_back_pressed():
	back_clicked.emit()

func _on_edit_pressed():
	edit_event_clicked.emit(current_event)

func _on_delete_pressed():
	# Show detailed confirmation dialog
	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.title = "⚠️ Delete Event"
	dialog.dialog_text = "Are you sure you want to permanently delete this event?\n\n📅 " + current_event.title + "\n📍 " + current_event.get_formatted_datetime() + "\n\nThis action cannot be undone!"
	dialog.ok_button_text = "Yes, Delete"
	dialog.cancel_button_text = "Cancel"
	dialog.min_size = Vector2(500, 300)
	dialog.confirmed.connect(_on_delete_confirmed)
	dialog.popup_centered()

func _on_delete_confirmed():
	if current_event:
		# Show loading feedback
		var loading = AcceptDialog.new()
		add_child(loading)
		loading.dialog_text = "⏳ Deleting event..."
		loading.get_ok_button().visible = false
		loading.popup_centered()

		api.delete_event(current_event.id)

		# Close loading dialog after a moment
		await get_tree().create_timer(1.0).timeout
		if loading:
			loading.queue_free()

func _on_event_deleted(success: bool):
	if success:
		# Show success message before going back
		var dialog = AcceptDialog.new()
		add_child(dialog)
		dialog.title = "✅ Success"
		dialog.dialog_text = "Event deleted successfully!"
		dialog.min_size = Vector2(400, 200)
		dialog.confirmed.connect(func():
			back_clicked.emit()
			dialog.queue_free()
		)
		dialog.popup_centered()
	else:
		# Show detailed error message
		var dialog = AcceptDialog.new()
		add_child(dialog)
		dialog.title = "❌ Delete Failed"
		dialog.dialog_text = "Failed to delete event. This could be because:\n\n• You don't have permission to delete this event\n• The event has already been deleted\n• Connection error\n\nPlease try again or contact support if the problem persists."
		dialog.min_size = Vector2(500, 300)
		dialog.popup_centered()

func _create_comments_section():
	# Create main comments container with panel background
	comments_panel = PanelContainer.new()
	comments_panel.name = "CommentsPanel"

	# Create stylebox for the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.12, 0.15, 0.95)  # Dark blue-gray background
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.3, 0.6, 1.0, 0.8)  # Bright blue border
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	comments_panel.add_theme_stylebox_override("panel", panel_style)

	comments_container = VBoxContainer.new()
	comments_container.name = "CommentsSection"
	comments_panel.add_child(comments_container)

	# Add to VBox
	var vbox = $ScrollContainer/VBox
	vbox.add_child(comments_panel)

	# Add divider before comments
	var top_divider = HSeparator.new()
	top_divider.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(top_divider)
	vbox.move_child(comments_panel, vbox.get_child_count())

	# Add animated section header with icon
	var header_container = HBoxContainer.new()
	header_container.alignment = BoxContainer.ALIGNMENT_CENTER
	comments_container.add_child(header_container)

	var header_icon = Label.new()
	header_icon.text = "💬"
	header_icon.add_theme_font_size_override("font_size", 48)
	header_container.add_child(header_icon)

	var header = Label.new()
	header.text = " Discussion Board"
	header.add_theme_font_size_override("font_size", 42)
	header.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	header_container.add_child(header)

	# Add subtitle
	var subtitle = Label.new()
	subtitle.text = "Join the conversation and connect with your community"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comments_container.add_child(subtitle)

	# Add spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 25)
	comments_container.add_child(spacer1)

	# Create comments list container
	comments_list = VBoxContainer.new()
	comments_list.name = "CommentsList"
	comments_container.add_child(comments_list)

	# Add spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	comments_container.add_child(spacer2)

	# Create comment input section with styled panel
	var input_panel = PanelContainer.new()
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color(0.15, 0.18, 0.22, 1.0)
	input_style.border_width_left = 2
	input_style.border_width_right = 2
	input_style.border_width_top = 2
	input_style.border_width_bottom = 2
	input_style.border_color = Color(0.4, 0.7, 1.0, 0.6)
	input_style.corner_radius_top_left = 10
	input_style.corner_radius_top_right = 10
	input_style.corner_radius_bottom_left = 10
	input_style.corner_radius_bottom_right = 10
	input_style.content_margin_left = 20
	input_style.content_margin_right = 20
	input_style.content_margin_top = 15
	input_style.content_margin_bottom = 15
	input_panel.add_theme_stylebox_override("panel", input_style)

	var input_vbox = VBoxContainer.new()
	input_panel.add_child(input_vbox)

	var input_label = Label.new()
	input_label.text = "✍️ Share Your Thoughts"
	input_label.add_theme_font_size_override("font_size", 28)
	input_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	input_vbox.add_child(input_label)

	var input_spacer = Control.new()
	input_spacer.custom_minimum_size = Vector2(0, 10)
	input_vbox.add_child(input_spacer)

	# Create text input with custom style
	comment_input = TextEdit.new()
	comment_input.custom_minimum_size = Vector2(0, 140)
	comment_input.placeholder_text = "Share your thoughts, ask questions, or coordinate with others..."
	comment_input.wrap_mode = TextEdit.LineWrappingMode.LINE_WRAPPING_BOUNDARY

	# Style the text input
	var input_text_style = StyleBoxFlat.new()
	input_text_style.bg_color = Color(0.08, 0.1, 0.13, 1.0)
	input_text_style.border_width_left = 1
	input_text_style.border_width_right = 1
	input_text_style.border_width_top = 1
	input_text_style.border_width_bottom = 1
	input_text_style.border_color = Color(0.3, 0.5, 0.7, 0.5)
	input_text_style.corner_radius_top_left = 8
	input_text_style.corner_radius_top_right = 8
	input_text_style.corner_radius_bottom_left = 8
	input_text_style.corner_radius_bottom_right = 8
	comment_input.add_theme_stylebox_override("normal", input_text_style)
	comment_input.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	comment_input.add_theme_font_size_override("font_size", 22)

	input_vbox.add_child(comment_input)
	comments_container.add_child(input_panel)

	# Character counter
	var char_counter = Label.new()
	char_counter.name = "CharCounter"
	char_counter.text = "0 / 500 characters"
	char_counter.add_theme_font_size_override("font_size", 18)
	char_counter.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	char_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	comments_container.add_child(char_counter)

	# Update char counter on text change
	comment_input.text_changed.connect(func():
		var length = comment_input.text.length()
		char_counter.text = str(length) + " / 500 characters"
		if length > 500:
			char_counter.add_theme_color_override("font_color", Color.RED)
		elif length > 400:
			char_counter.add_theme_color_override("font_color", Color.YELLOW)
		else:
			char_counter.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	)

	# Create submit button with custom style
	comment_submit_button = Button.new()
	comment_submit_button.text = "💬 Post Comment"
	comment_submit_button.custom_minimum_size = Vector2(0, 70)

	# Style the button
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.2, 0.5, 1.0, 1.0)  # Bright blue
	button_style_normal.corner_radius_top_left = 12
	button_style_normal.corner_radius_top_right = 12
	button_style_normal.corner_radius_bottom_left = 12
	button_style_normal.corner_radius_bottom_right = 12
	button_style_normal.content_margin_left = 20
	button_style_normal.content_margin_right = 20
	button_style_normal.content_margin_top = 10
	button_style_normal.content_margin_bottom = 10

	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = Color(0.3, 0.6, 1.0, 1.0)  # Lighter blue on hover
	button_style_hover.corner_radius_top_left = 12
	button_style_hover.corner_radius_top_right = 12
	button_style_hover.corner_radius_bottom_left = 12
	button_style_hover.corner_radius_bottom_right = 12
	button_style_hover.content_margin_left = 20
	button_style_hover.content_margin_right = 20
	button_style_hover.content_margin_top = 10
	button_style_hover.content_margin_bottom = 10

	var button_style_pressed = StyleBoxFlat.new()
	button_style_pressed.bg_color = Color(0.15, 0.4, 0.8, 1.0)  # Darker blue when pressed
	button_style_pressed.corner_radius_top_left = 12
	button_style_pressed.corner_radius_top_right = 12
	button_style_pressed.corner_radius_bottom_left = 12
	button_style_pressed.corner_radius_bottom_right = 12
	button_style_pressed.content_margin_left = 20
	button_style_pressed.content_margin_right = 20
	button_style_pressed.content_margin_top = 10
	button_style_pressed.content_margin_bottom = 10

	comment_submit_button.add_theme_stylebox_override("normal", button_style_normal)
	comment_submit_button.add_theme_stylebox_override("hover", button_style_hover)
	comment_submit_button.add_theme_stylebox_override("pressed", button_style_pressed)
	comment_submit_button.add_theme_font_size_override("font_size", 28)
	comment_submit_button.add_theme_color_override("font_color", Color.WHITE)

	comment_submit_button.pressed.connect(_on_comment_submit)
	comments_container.add_child(comment_submit_button)

func _on_comment_submit():
	print("[EventDetail] Submit button clicked")

	# Validate comment input exists
	if not comment_input:
		print("[EventDetail] ERROR: comment_input is null!")
		_show_error_toast("Error: Comment input not initialized")
		return

	# Validate current event exists
	if not current_event:
		print("[EventDetail] ERROR: current_event is null!")
		_show_error_toast("Error: Event not loaded")
		return

	var text = comment_input.text.strip_edges()
	print("[EventDetail] Comment text: '", text, "' (length: ", text.length(), ")")

	if text.length() == 0:
		print("[EventDetail] Comment is empty")
		_show_error_toast("Comment cannot be empty")
		return

	if text.length() > 500:
		print("[EventDetail] Comment too long")
		_show_error_toast("Comment is too long (max 500 characters)")
		return

	if api.auth_token == "":
		print("[EventDetail] Not logged in")
		_show_error_toast("❌ Please log in to post comments")
		return

	print("[EventDetail] Submitting comment for event ID: ", current_event.id)
	print("[EventDetail] Auth token exists: ", api.auth_token != "")

	# Disable button while submitting
	comment_submit_button.disabled = true
	comment_submit_button.text = "⏳ Posting..."

	api.add_comment(current_event.id, text)

func _on_comment_added(success: bool, comment: Dictionary):
	print("[EventDetail] Comment added callback - Success: ", success)
	print("[EventDetail] Response: ", comment)

	comment_submit_button.disabled = false
	comment_submit_button.text = "💬 Post Comment"

	if success:
		print("[EventDetail] Comment posted successfully!")
		comment_input.text = ""
		_show_success_toast("✅ Comment posted!")
		# Refresh comments
		api.fetch_comments(current_event.id)
	else:
		var message = comment.get("message", "Failed to post comment")
		print("[EventDetail] Comment failed: ", message)
		_show_error_toast("❌ " + message)

func _on_comments_fetched(comments: Array):
	# Clear existing comments
	for child in comments_list.get_children():
		child.queue_free()

	if comments.is_empty():
		# Create styled empty state
		var empty_panel = PanelContainer.new()
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0.1, 0.12, 0.15, 0.5)
		empty_style.border_width_left = 2
		empty_style.border_width_right = 2
		empty_style.border_width_top = 2
		empty_style.border_width_bottom = 2
		empty_style.border_color = Color(0.3, 0.5, 0.7, 0.3)
		empty_style.corner_radius_top_left = 10
		empty_style.corner_radius_top_right = 10
		empty_style.corner_radius_bottom_left = 10
		empty_style.corner_radius_bottom_right = 10
		empty_style.content_margin_left = 40
		empty_style.content_margin_right = 40
		empty_style.content_margin_top = 40
		empty_style.content_margin_bottom = 40
		empty_panel.add_theme_stylebox_override("panel", empty_style)

		var empty_vbox = VBoxContainer.new()
		empty_panel.add_child(empty_vbox)

		var empty_icon = Label.new()
		empty_icon.text = "💭"
		empty_icon.add_theme_font_size_override("font_size", 64)
		empty_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_vbox.add_child(empty_icon)

		var empty_label = Label.new()
		empty_label.text = "No comments yet"
		empty_label.add_theme_font_size_override("font_size", 28)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_vbox.add_child(empty_label)

		var empty_subtitle = Label.new()
		empty_subtitle.text = "Be the first to start the conversation!"
		empty_subtitle.add_theme_font_size_override("font_size", 22)
		empty_subtitle.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		empty_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_vbox.add_child(empty_subtitle)

		comments_list.add_child(empty_panel)
		return

	# Add each comment
	for comment in comments:
		_add_comment_item(comment)

func _add_comment_item(comment: Dictionary):
	# Create comment container with nice styling
	var comment_box = PanelContainer.new()
	comment_box.custom_minimum_size = Vector2(0, 100)

	# Style the comment box
	var comment_style = StyleBoxFlat.new()
	comment_style.bg_color = Color(0.12, 0.15, 0.18, 0.95)
	comment_style.border_width_left = 3
	comment_style.border_width_right = 0
	comment_style.border_width_top = 0
	comment_style.border_width_bottom = 0
	comment_style.border_color = Color(0.3, 0.6, 0.9, 1.0)  # Blue accent border
	comment_style.corner_radius_top_left = 12
	comment_style.corner_radius_top_right = 12
	comment_style.corner_radius_bottom_left = 12
	comment_style.corner_radius_bottom_right = 12
	comment_style.content_margin_left = 20
	comment_style.content_margin_right = 20
	comment_style.content_margin_top = 15
	comment_style.content_margin_bottom = 15
	comment_style.shadow_size = 3
	comment_style.shadow_color = Color(0, 0, 0, 0.3)
	comment_box.add_theme_stylebox_override("panel", comment_style)

	var vbox = VBoxContainer.new()
	comment_box.add_child(vbox)

	# Header with username and time
	var header_box = HBoxContainer.new()
	vbox.add_child(header_box)

	var username_label = Label.new()
	username_label.text = "👤 " + comment.get("username", "Unknown")
	username_label.add_theme_font_size_override("font_size", 24)
	username_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	header_box.add_child(username_label)

	header_box.add_child(Control.new())  # Spacer
	header_box.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var time_label = Label.new()
	time_label.text = "🕐 " + _format_comment_time(comment.get("created_at", ""))
	time_label.add_theme_font_size_override("font_size", 19)
	time_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	header_box.add_child(time_label)

	# Add small spacer between header and text
	var text_spacer = Control.new()
	text_spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(text_spacer)

	# Comment text with better styling
	var text_label = Label.new()
	text_label.text = comment.get("text", "")
	text_label.add_theme_font_size_override("font_size", 24)
	text_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text_label)

	comments_list.add_child(comment_box)

	# Add spacer between comments
	var separator = Control.new()
	separator.custom_minimum_size = Vector2(0, 15)
	comments_list.add_child(separator)

func _format_comment_time(timestamp: String) -> String:
	if timestamp == "":
		return "just now"

	# Simple relative time formatting
	return "recently"  # TODO: Implement proper time formatting

func _show_success_toast(message: String):
	print("[EventDetail] Showing success toast: ", message)
	var toast = PanelContainer.new()

	# Style the toast
	var toast_style = StyleBoxFlat.new()
	toast_style.bg_color = Color(0.2, 0.8, 0.3, 0.95)
	toast_style.corner_radius_top_left = 10
	toast_style.corner_radius_top_right = 10
	toast_style.corner_radius_bottom_left = 10
	toast_style.corner_radius_bottom_right = 10
	toast_style.content_margin_left = 30
	toast_style.content_margin_right = 30
	toast_style.content_margin_top = 20
	toast_style.content_margin_bottom = 20
	toast.add_theme_stylebox_override("panel", toast_style)

	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	toast.add_child(label)

	toast.position = Vector2(get_viewport_rect().size.x / 2 - 200, 100)
	add_child(toast)

	await get_tree().create_timer(3.0).timeout
	if toast:
		toast.queue_free()

func _show_error_toast(message: String):
	print("[EventDetail] Showing error toast: ", message)
	var toast = PanelContainer.new()

	# Style the toast
	var toast_style = StyleBoxFlat.new()
	toast_style.bg_color = Color(0.9, 0.2, 0.2, 0.95)
	toast_style.corner_radius_top_left = 10
	toast_style.corner_radius_top_right = 10
	toast_style.corner_radius_bottom_left = 10
	toast_style.corner_radius_bottom_right = 10
	toast_style.content_margin_left = 30
	toast_style.content_margin_right = 30
	toast_style.content_margin_top = 20
	toast_style.content_margin_bottom = 20
	toast.add_theme_stylebox_override("panel", toast_style)

	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	toast.add_child(label)

	toast.position = Vector2(get_viewport_rect().size.x / 2 - 200, 100)
	add_child(toast)

	await get_tree().create_timer(3.0).timeout
	if toast:
		toast.queue_free()

func _create_discussion_button():
	# Create a container for the button
	var button_container = PanelContainer.new()
	button_container.name = "DiscussionButtonContainer"

	# Style the container with high-tech theme
	var container_style = StyleBoxFlat.new()
	container_style.bg_color = Color(0.08, 0.08, 0.15, 0.95)
	container_style.border_width_left = 3
	container_style.border_width_right = 3
	container_style.border_width_top = 3
	container_style.border_width_bottom = 3
	container_style.border_color = Color(0.3, 0.6, 1.0, 0.7)  # Blue-cyan border
	container_style.corner_radius_top_left = 15
	container_style.corner_radius_top_right = 15
	container_style.corner_radius_bottom_left = 15
	container_style.corner_radius_bottom_right = 15
	container_style.content_margin_left = 20
	container_style.content_margin_right = 20
	container_style.content_margin_top = 15
	container_style.content_margin_bottom = 15
	container_style.shadow_size = 10
	container_style.shadow_color = Color(0.3, 0.6, 1.0, 0.3)
	button_container.add_theme_stylebox_override("panel", container_style)

	# Create the button
	discussion_board_button = Button.new()
	discussion_board_button.text = "💬 See Discussion Board"
	discussion_board_button.custom_minimum_size = Vector2(0, 80)

	# Style the button with neon glow
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.2, 0.5, 1.0, 0.9)  # Bright blue
	button_style_normal.corner_radius_top_left = 12
	button_style_normal.corner_radius_top_right = 12
	button_style_normal.corner_radius_bottom_left = 12
	button_style_normal.corner_radius_bottom_right = 12
	button_style_normal.border_width_left = 2
	button_style_normal.border_width_right = 2
	button_style_normal.border_width_top = 2
	button_style_normal.border_width_bottom = 2
	button_style_normal.border_color = Color(0.4, 0.7, 1.0, 1.0)
	button_style_normal.shadow_size = 15
	button_style_normal.shadow_color = Color(0.2, 0.5, 1.0, 0.5)

	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = Color(0.3, 0.6, 1.0, 1.0)  # Lighter blue on hover
	button_style_hover.corner_radius_top_left = 12
	button_style_hover.corner_radius_top_right = 12
	button_style_hover.corner_radius_bottom_left = 12
	button_style_hover.corner_radius_bottom_right = 12
	button_style_hover.border_width_left = 2
	button_style_hover.border_width_right = 2
	button_style_hover.border_width_top = 2
	button_style_hover.border_width_bottom = 2
	button_style_hover.border_color = Color(0.5, 0.8, 1.0, 1.0)
	button_style_hover.shadow_size = 25
	button_style_hover.shadow_color = Color(0.3, 0.6, 1.0, 0.7)

	var button_style_pressed = StyleBoxFlat.new()
	button_style_pressed.bg_color = Color(0.15, 0.4, 0.8, 1.0)  # Darker blue when pressed
	button_style_pressed.corner_radius_top_left = 12
	button_style_pressed.corner_radius_top_right = 12
	button_style_pressed.corner_radius_bottom_left = 12
	button_style_pressed.corner_radius_bottom_right = 12
	button_style_pressed.border_width_left = 2
	button_style_pressed.border_width_right = 2
	button_style_pressed.border_width_top = 2
	button_style_pressed.border_width_bottom = 2
	button_style_pressed.border_color = Color(0.3, 0.5, 0.9, 1.0)
	button_style_pressed.shadow_size = 10
	button_style_pressed.shadow_color = Color(0.2, 0.5, 1.0, 0.4)

	discussion_board_button.add_theme_stylebox_override("normal", button_style_normal)
	discussion_board_button.add_theme_stylebox_override("hover", button_style_hover)
	discussion_board_button.add_theme_stylebox_override("pressed", button_style_pressed)
	discussion_board_button.add_theme_font_size_override("font_size", 32)
	discussion_board_button.add_theme_color_override("font_color", Color.WHITE)

	# Connect button to scroll function
	discussion_board_button.pressed.connect(_on_discussion_button_pressed)

	button_container.add_child(discussion_board_button)

	# Add to VBox after description section
	var vbox = $ScrollContainer/VBox
	# Insert before the divider that comes before comments
	var insert_index = vbox.get_child_count() - 2  # Before divider and comments panel
	vbox.add_child(button_container)
	vbox.move_child(button_container, insert_index)

	# Add spacing before button
	var spacer_before = Control.new()
	spacer_before.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer_before)
	vbox.move_child(spacer_before, insert_index)

func _on_discussion_button_pressed():
	# Scroll to the comments panel
	if comments_panel:
		# Wait a frame for layout to update
		await get_tree().process_frame

		# Get the position of the comments panel
		var target_position = comments_panel.position.y

		# Scroll to it smoothly
		var tween = create_tween()
		tween.tween_property(scroll_container, "scroll_vertical", int(target_position), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		# Visual feedback
		_show_success_toast("📍 Scrolled to Discussion Board")
