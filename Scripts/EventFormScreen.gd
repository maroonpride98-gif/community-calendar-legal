extends Control

signal back_clicked()
signal event_saved()

@onready var api = get_tree().root.get_node("Main/APIManager")
@onready var back_button = $TopBar/BackButton
@onready var save_button = $SaveButton
@onready var title_label = $ScrollContainer/FormContainer/TitleLabel
@onready var title_input = $ScrollContainer/FormContainer/TitleInput
@onready var category_dropdown = $ScrollContainer/FormContainer/CategoryDropdown
@onready var date_input = $ScrollContainer/FormContainer/DateInput
@onready var time_input = $ScrollContainer/FormContainer/TimeInput
@onready var location_input = $ScrollContainer/FormContainer/LocationInput
@onready var contact_input = $ScrollContainer/FormContainer/ContactInput
@onready var description_input = $ScrollContainer/FormContainer/DescriptionInput
@onready var error_label = $ErrorLabel

var current_event: Event = null
var is_editing = false
var user_zipcode = ""
var override_zipcode = ""  # Zipcode from city filter (takes priority over user zipcode)
var zipcode_cache = {}  # Cache for zip to city lookups

# Character count labels (will be created dynamically)
var title_counter: Label
var description_counter: Label
var location_label: Label = null  # City display label

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)

	api.event_created.connect(_on_event_created)
	api.event_updated.connect(_on_event_updated)

	# Track screen view
	Analytics.track_screen_view("event_form")

	# Load user data and create location display
	_load_user_data()
	_create_location_label()

	_setup_categories()
	_setup_placeholders()
	_setup_character_counters()
	_setup_realtime_validation()

func _setup_categories():
	category_dropdown.clear()

	var categories = Event.CATEGORIES
	var idx = 0
	for cat_key in categories.keys():
		category_dropdown.add_item(categories[cat_key], idx)
		category_dropdown.set_item_metadata(idx, cat_key)
		idx += 1

func set_city_zipcode(zipcode: String):
	# Set the zipcode for the city being browsed
	override_zipcode = zipcode
	_update_location_display()

func _load_user_data():
	# Get user zip code from cached profile
	var cached_user = DataCache.get_cached_user_profile()
	if cached_user and cached_user.has("zipcode"):
		user_zipcode = cached_user["zipcode"]

func _create_location_label():
	# Create prominent location display at top
	location_label = Label.new()
	location_label.name = "EventLocationLabel"
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1))  # Bright cyan
	location_label.add_theme_font_size_override("font_size", 48)

	# Add to form container at the top (after TopMargin)
	var form_container = $ScrollContainer/FormContainer
	form_container.add_child(location_label)
	form_container.move_child(location_label, 2)  # Position after TopMargin and TitleLabel

	# Update the display
	_update_location_display()

func _update_location_display():
	if not location_label:
		return

	# Use override zipcode if set (from city filter), otherwise use user's zipcode
	var active_zipcode = override_zipcode if override_zipcode != "" else user_zipcode

	if active_zipcode.length() == 5 and active_zipcode.is_valid_int():
		var city_name = _get_city_from_zipcode(active_zipcode)
		location_label.text = "📍 Creating event in " + city_name
		location_label.add_theme_font_size_override("font_size", 48)  # Reset to normal size
		location_label.visible = true
	else:
		# If no zipcode, show a helpful message
		location_label.text = "📍 Creating Community Event (add zipcode in profile for location-based discovery)"
		location_label.add_theme_font_size_override("font_size", 28)  # Smaller text for long message
		location_label.visible = true

func _get_city_from_zipcode(zipcode: String) -> String:
	# Check cache first
	if zipcode_cache.has(zipcode):
		return zipcode_cache[zipcode]

	# Start async lookup
	_lookup_city_from_zipcode(zipcode)

	# Return temporary text while loading
	return "ZIP: " + zipcode

func _lookup_city_from_zipcode(zipcode: String):
	# Use Zippopotam.us API - free, no API key required
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_zipcode_lookup_completed.bind(zipcode, http))

	var url = "https://api.zippopotam.us/us/" + zipcode
	var result = http.request(url)

	if result != OK:
		# Fallback - cache the zip code itself
		zipcode_cache[zipcode] = "ZIP: " + zipcode

func _on_zipcode_lookup_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, zipcode: String, http: HTTPRequest):
	http.queue_free()

	if response_code == 200:
		var json = JSON.new()
		var error = json.parse(body.get_string_from_utf8())

		if error == OK and json.data is Dictionary:
			var data = json.data
			if data.has("places") and data["places"].size() > 0:
				var place = data["places"][0]
				var city = place.get("place name", "")
				var state = place.get("state abbreviation", "")

				if city != "" and state != "":
					var city_name = city + ", " + state
					zipcode_cache[zipcode] = city_name

					# Refresh display if this is the current user's zip
					if user_zipcode == zipcode:
						_update_location_display()
					return

	# Fallback if API fails
	zipcode_cache[zipcode] = "ZIP: " + zipcode

func set_event(event: Event):
	if event:
		current_event = event
		is_editing = true
		title_label.text = "Edit Event"
		_populate_form()
	else:
		current_event = null
		is_editing = false
		title_label.text = "Create New Event"
		_clear_form()

func _populate_form():
	if not current_event:
		return

	title_input.text = current_event.title
	date_input.text = current_event.date
	time_input.text = current_event.time
	location_input.text = current_event.location
	contact_input.text = current_event.contact_info
	description_input.text = current_event.description

	# Set category dropdown
	for i in range(category_dropdown.item_count):
		if category_dropdown.get_item_metadata(i) == current_event.category:
			category_dropdown.selected = i
			break

func _clear_form():
	title_input.text = ""
	category_dropdown.selected = 0
	date_input.text = ""
	time_input.text = ""
	location_input.text = ""
	contact_input.text = ""
	description_input.text = ""

func _on_back_pressed():
	back_clicked.emit()

func _on_save_pressed():
	# Check if user is logged in
	if api.auth_token == "":
		error_label.text = "❌ Please log in to create events"
		error_label.modulate = Color.RED
		return

	# Validate form
	if not _validate_form():
		return

	# Prepare event data
	var event_data = {
		"title": title_input.text.strip_edges(),
		"category": category_dropdown.get_item_metadata(category_dropdown.selected),
		"date": date_input.text.strip_edges(),
		"time": time_input.text.strip_edges(),
		"location": location_input.text.strip_edges(),
		"contact_info": contact_input.text.strip_edges(),
		"description": description_input.text.strip_edges()
	}

	# NOTE: Backend doesn't support zipcode field yet
	# Location-based filtering will use text search on location field for now

	error_label.text = "⏳ Saving your event..."
	error_label.modulate = Color(0.7, 0.7, 1.0)
	save_button.disabled = true

	print("[EventFormScreen] Creating event with auth token: ", api.auth_token != "")
	print("[EventFormScreen] Event data: ", event_data)

	if is_editing and current_event:
		api.update_event(current_event.id, event_data)
	else:
		api.create_event(event_data)

func _validate_form() -> bool:
	var title = title_input.text.strip_edges()
	var date = date_input.text.strip_edges()
	var time = time_input.text.strip_edges()
	var location = location_input.text.strip_edges()
	var description = description_input.text.strip_edges()

	# Title validation
	if title == "":
		error_label.text = "❌ Please enter an event title"
		error_label.modulate = Color.RED
		title_input.grab_focus()
		return false

	if title.length() < 5:
		error_label.text = "❌ Title is too short - please be more descriptive (at least 5 characters)"
		error_label.modulate = Color.RED
		title_input.grab_focus()
		return false

	if title.length() > 100:
		error_label.text = "❌ Title is too long - please keep it under 100 characters"
		error_label.modulate = Color.RED
		title_input.grab_focus()
		return false

	# Date validation
	if date == "":
		error_label.text = "❌ Please enter an event date (format: YYYY-MM-DD, e.g. 2025-12-25)"
		error_label.modulate = Color.RED
		date_input.grab_focus()
		return false

	if not _is_valid_date_format(date):
		error_label.text = "❌ Date must be in YYYY-MM-DD format (e.g. 2025-12-25)"
		error_label.modulate = Color.RED
		date_input.grab_focus()
		return false

	# Time validation (optional but if provided should be valid)
	if time != "" and not (time.match("*[0-9]:[0-9][0-9]*")):
		error_label.text = "❌ Time format should be HH:MM (e.g. 10:00 AM or 14:30)"
		error_label.modulate = Color.RED
		time_input.grab_focus()
		return false

	# Location validation
	if location == "":
		error_label.text = "❌ Please enter a location for your event"
		error_label.modulate = Color.RED
		location_input.grab_focus()
		return false

	if location.length() < 10:
		error_label.text = "❌ Please provide a more detailed location (address or venue name)"
		error_label.modulate = Color.RED
		location_input.grab_focus()
		return false

	# Description validation (optional but recommended)
	if description == "":
		error_label.text = "⚠️ No description provided - consider adding details to attract more attendees"
		error_label.modulate = Color.YELLOW
		# Don't return false, just warn

	if description.length() > 500:
		error_label.text = "❌ Description is too long - please keep it under 500 characters"
		error_label.modulate = Color.RED
		description_input.grab_focus()
		return false

	error_label.text = ""
	return true

func _is_valid_date_format(date_str: String) -> bool:
	var parts = date_str.split("-")
	if parts.size() != 3:
		return false

	var year = parts[0].to_int()
	var month = parts[1].to_int()
	var day = parts[2].to_int()

	if year < 2024 or year > 2100:
		return false
	if month < 1 or month > 12:
		return false
	if day < 1 or day > 31:
		return false

	return true

func _on_event_created(success: bool, event_data: Dictionary):
	save_button.disabled = false

	print("[EventFormScreen] Event creation completed - Success: ", success)
	print("[EventFormScreen] Response data: ", event_data)

	if success:
		error_label.text = "✅ Event created successfully!"
		error_label.modulate = Color.GREEN
		Analytics.track_event("event_created_success")

		# Emit immediately to go back to event list
		print("[EventFormScreen] Emitting event_saved signal")
		event_saved.emit()
	else:
		var message = event_data.get("message", "Failed to create event. Please try again.")
		print("[EventFormScreen] Event creation failed: ", message)

		if message.contains("network") or message.contains("connection"):
			error_label.text = "❌ Connection error. Please check your internet and try again."
		elif message.contains("duplicate"):
			error_label.text = "❌ An event with this title already exists. Please use a different title."
		elif message.contains("login") or message.contains("auth") or message.contains("token"):
			error_label.text = "❌ Session expired. Please log in again."
		else:
			error_label.text = "❌ " + message
		error_label.modulate = Color.RED

func _on_event_updated(success: bool, event_data: Dictionary):
	save_button.disabled = false

	if success:
		error_label.text = "✅ Event updated successfully!"
		error_label.modulate = Color.GREEN
		await get_tree().create_timer(1.0).timeout
		event_saved.emit()
	else:
		var message = event_data.get("message", "Failed to update event. Please try again.")
		error_label.text = "❌ " + message
		error_label.modulate = Color.RED

func _setup_placeholders():
	# Add helpful placeholder text
	title_input.placeholder_text = "e.g. Community Garage Sale, Summer Festival..."
	date_input.placeholder_text = "YYYY-MM-DD (e.g. 2025-12-25)"
	time_input.placeholder_text = "HH:MM AM/PM (e.g. 10:00 AM)"
	location_input.placeholder_text = "Address or venue name (e.g. 123 Main St, City, State 12345)"
	contact_input.placeholder_text = "Phone or email (e.g. 555-1234 or event@example.com)"
	description_input.placeholder_text = "Tell people what your event is about, what to bring, who can attend, etc..."

func _setup_character_counters():
	# Title character counter (max 100)
	title_counter = Label.new()
	title_counter.add_theme_font_size_override("font_size", 18)
	title_counter.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	title_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var title_parent = title_input.get_parent()
	if title_parent:
		title_parent.add_child(title_counter)
		title_parent.move_child(title_counter, title_input.get_index() + 1)

	title_input.text_changed.connect(func(text):
		var length = text.length()
		title_counter.text = str(length) + " / 100 characters"
		if length > 100:
			title_counter.add_theme_color_override("font_color", Color.RED)
			title_input.modulate = Color(1, 0.8, 0.8)
		elif length > 80:
			title_counter.add_theme_color_override("font_color", Color.YELLOW)
			title_input.modulate = Color.WHITE
		else:
			title_counter.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
			title_input.modulate = Color.WHITE
	)

	# Description character counter (max 500)
	description_counter = Label.new()
	description_counter.add_theme_font_size_override("font_size", 18)
	description_counter.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	description_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var desc_parent = description_input.get_parent()
	if desc_parent:
		desc_parent.add_child(description_counter)
		desc_parent.move_child(description_counter, description_input.get_index() + 1)

	description_input.text_changed.connect(func():
		var length = description_input.text.length()
		description_counter.text = str(length) + " / 500 characters"
		if length > 500:
			description_counter.add_theme_color_override("font_color", Color.RED)
			description_input.modulate = Color(1, 0.8, 0.8)
		elif length > 400:
			description_counter.add_theme_color_override("font_color", Color.YELLOW)
			description_input.modulate = Color.WHITE
		else:
			description_counter.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
			description_input.modulate = Color.WHITE
	)

func _setup_realtime_validation():
	# Date validation with visual feedback
	date_input.text_changed.connect(func(text):
		if text.length() == 0:
			date_input.modulate = Color.WHITE
			return

		if _is_valid_date_format(text):
			# Check if date is in the future
			var parts = text.split("-")
			var year = parts[0].to_int()
			var month = parts[1].to_int()
			var day = parts[2].to_int()

			var now = Time.get_datetime_dict_from_system()
			var is_future = year > now.year or (year == now.year and month > now.month) or (year == now.year and month == now.month and day >= now.day)

			if is_future:
				date_input.modulate = Color(0.7, 1, 0.7)
			else:
				date_input.modulate = Color(1, 1, 0.7)  # Past date warning
		else:
			date_input.modulate = Color(1, 0.8, 0.8)
	)

	# Time validation
	time_input.text_changed.connect(func(text):
		if text.length() == 0:
			time_input.modulate = Color.WHITE
			return

		# Simple time format check (HH:MM)
		if text.match("*[0-9][0-9]:[0-9][0-9]*") or text.match("*[0-9]:[0-9][0-9]*"):
			time_input.modulate = Color(0.7, 1, 0.7)
		else:
			time_input.modulate = Color(1, 0.8, 0.8)
	)

	# Location validation (should contain state or zip code)
	location_input.text_changed.connect(func(text):
		if text.length() == 0:
			location_input.modulate = Color.WHITE
			return

		if text.length() > 10:
			# Check if it contains a US zip code pattern (5 digits)
			if text.match("*[0-9][0-9][0-9][0-9][0-9]*"):
				location_input.modulate = Color(0.7, 1, 0.7)
			else:
				location_input.modulate = Color(1, 1, 0.7)  # Warning, might want zip code
		else:
			location_input.modulate = Color.WHITE
	)
