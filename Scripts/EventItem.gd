extends Panel

signal clicked()
signal rsvp_changed(event_id: int, rsvp_status: String)
signal favorite_toggled(event_id: int, is_favorited: bool)
signal share_requested(event: Event)

@onready var title_label = $Content/MainContent/VBox/HeaderRow/TitleColumn/Title
@onready var category_label = $Content/MainContent/VBox/HeaderRow/TitleColumn/Category
@onready var status_badge = $Content/MainContent/VBox/HeaderRow/BadgesColumn/StatusBadge
@onready var status_label = $Content/MainContent/VBox/HeaderRow/BadgesColumn/StatusBadge/Label
@onready var favorite_button = $Content/MainContent/VBox/HeaderRow/BadgesColumn/FavoriteButton
@onready var countdown_label = $Content/MainContent/VBox/CountdownRow/CountdownLabel
@onready var attendee_label = $Content/MainContent/VBox/CountdownRow/AttendeeLabel
@onready var date_label = $Content/MainContent/VBox/InfoGrid/LeftColumn/DateTime
@onready var location_label = $Content/MainContent/VBox/InfoGrid/LeftColumn/Location
@onready var organizer_label = $Content/MainContent/VBox/InfoGrid/RightColumn/Organizer
@onready var capacity_label = $Content/MainContent/VBox/InfoGrid/RightColumn/Capacity
@onready var going_button = $Content/MainContent/VBox/RSVPRow/GoingButton
@onready var interested_button = $Content/MainContent/VBox/RSVPRow/InterestedButton
@onready var share_button = $Content/MainContent/VBox/RSVPRow/ShareButton
@onready var accent_bar = $Content/AccentBar

var event: Event
var hover_tween: Tween

func _ready():
	gui_input.connect(_on_gui_input)
	going_button.pressed.connect(_on_going_pressed)
	interested_button.pressed.connect(_on_interested_pressed)
	share_button.pressed.connect(_on_share_pressed)
	favorite_button.pressed.connect(_on_favorite_pressed)

	# Setup hover effects
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_event(e: Event):
	event = e
	_update_display()

func _update_display():
	if not event:
		return

	# Basic info
	title_label.text = event.title.to_upper()
	category_label.text = "⟫ " + event.get_category_display().to_upper()
	date_label.text = "⟫ " + event.get_formatted_datetime().to_upper()
	location_label.text = "⟫ " + event.location.to_upper()
	organizer_label.text = "⟫ " + event.organizer.to_upper()

	# Status badge
	var status = event.get_event_status()
	status_label.text = "◉ " + status
	_update_status_badge_color(status)

	# Countdown
	countdown_label.text = "⏱ " + event.get_countdown()

	# Attendee count
	attendee_label.text = "◈ " + event.get_attendee_count_text()

	# Capacity
	capacity_label.text = "⟫ " + event.get_capacity_status()

	# Favorite button
	favorite_button.text = "★" if event.is_favorited else "☆"

	# RSVP buttons
	_update_rsvp_buttons()

	# Category color for accent bar
	var category_color = _get_category_color(event.category)
	if accent_bar:
		var style = accent_bar.get_theme_stylebox("panel").duplicate()
		style.bg_color = category_color
		style.shadow_color = Color(category_color.r, category_color.g, category_color.b, 0.6)
		accent_bar.add_theme_stylebox_override("panel", style)

func _update_status_badge_color(status: String):
	var badge_style = status_badge.get_theme_stylebox("panel").duplicate()

	match status:
		"LIVE":
			badge_style.bg_color = Color(0, 1, 0.5, 0.25)
			badge_style.border_color = Color(0, 1, 0.5, 1)
			status_label.add_theme_color_override("font_color", Color(0, 1, 0.5, 1))
		"UPCOMING":
			badge_style.bg_color = Color(0, 0.8, 1, 0.2)
			badge_style.border_color = Color(0, 1, 1, 0.8)
			status_label.add_theme_color_override("font_color", Color(0, 1, 1, 1))
		"PAST":
			badge_style.bg_color = Color(0.5, 0.5, 0.6, 0.15)
			badge_style.border_color = Color(0.6, 0.6, 0.7, 0.6)
			status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1))

	status_badge.add_theme_stylebox_override("panel", badge_style)

func _update_rsvp_buttons():
	# Reset all buttons
	going_button.text = "✓ GOING"
	interested_button.text = "★ INTERESTED"

	# Highlight active RSVP
	match event.user_rsvp:
		"going":
			going_button.text = "✓ GOING ◀"
		"interested":
			interested_button.text = "★ INTERESTED ◀"

func _get_category_color(category: String) -> Color:
	match category:
		"garage_sale":
			return Color(0.3, 1.0, 0.5)  # Neon Green
		"sports":
			return Color(0.2, 0.7, 1.0)  # Bright Blue
		"church":
			return Color(1.0, 0.8, 0.3)  # Bright Gold
		"town_meeting":
			return Color(1.0, 0.3, 0.4)  # Bright Red
		"community":
			return Color(0.8, 0.4, 1.0)  # Bright Purple
		"fundraiser":
			return Color(1.0, 0.5, 0.2)  # Bright Orange
		"workshop":
			return Color(0.3, 0.9, 0.9)  # Bright Cyan
		"festival":
			return Color(1.0, 0.4, 0.8)  # Bright Pink
		_:
			return Color(0, 1, 1)  # Cyan default

func _on_gui_input(input_event: InputEvent):
	if input_event is InputEventMouseButton and input_event.pressed and input_event.button_index == MOUSE_BUTTON_LEFT:
		# Check if click wasn't on a button
		if not _is_click_on_button(input_event.position):
			clicked.emit()
	elif input_event is InputEventScreenTouch and input_event.pressed:
		if not _is_click_on_button(input_event.position):
			clicked.emit()

func _is_click_on_button(pos: Vector2) -> bool:
	# Simple check to avoid opening detail when clicking buttons
	var buttons = [going_button, interested_button, share_button, favorite_button]
	for button in buttons:
		if button.get_global_rect().has_point(get_global_mouse_position()):
			return true
	return false

func _on_going_pressed():
	var old_status = event.user_rsvp
	var new_status = "going" if old_status != "going" else ""
	event.user_rsvp = new_status

	# Update counts locally for immediate feedback
	if old_status == "interested":
		event.attendees_interested -= 1
	elif old_status == "going":
		event.attendees_going -= 1

	if new_status == "going":
		event.attendees_going += 1

	_update_display()
	rsvp_changed.emit(event.id, new_status)

func _on_interested_pressed():
	var old_status = event.user_rsvp
	var new_status = "interested" if old_status != "interested" else ""
	event.user_rsvp = new_status

	# Update counts locally
	if old_status == "going":
		event.attendees_going -= 1
	elif old_status == "interested":
		event.attendees_interested -= 1

	if new_status == "interested":
		event.attendees_interested += 1

	_update_display()
	rsvp_changed.emit(event.id, new_status)

func _on_favorite_pressed():
	event.is_favorited = !event.is_favorited
	_update_display()
	favorite_toggled.emit(event.id, event.is_favorited)

func _on_share_pressed():
	share_requested.emit(event)

func _on_mouse_entered():
	# Animate glow effect on hover
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_CUBIC)

	var style = get_theme_stylebox("panel").duplicate()
	hover_tween.tween_property(style, "border_color", Color(0, 1, 1, 0.9), 0.2)
	hover_tween.parallel().tween_property(style, "shadow_size", 20, 0.2)
	add_theme_stylebox_override("panel", style)

func _on_mouse_exited():
	# Reset glow effect
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_IN)
	hover_tween.set_trans(Tween.TRANS_CUBIC)

	var style = get_theme_stylebox("panel").duplicate()
	hover_tween.tween_property(style, "border_color", Color(0, 1, 1, 0.5), 0.2)
	hover_tween.parallel().tween_property(style, "shadow_size", 12, 0.2)
	add_theme_stylebox_override("panel", style)
