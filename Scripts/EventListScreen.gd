extends Control

signal event_clicked(event: Event)
signal create_event_clicked(city_zipcode: String)
signal logout_clicked()

@onready var api = get_tree().root.get_node("Main/APIManager")
@onready var event_container = $ScrollContainer/EventList
@onready var search_input = $TopBarPanel/TopBarContent/SearchRow/SearchBar
@onready var category_dropdown = $TopBarPanel/TopBarContent/SearchRow/CategoryFilter
@onready var zipcode_filter = $TopBarPanel/TopBarContent/SearchRow/ZipCodeFilter
@onready var refresh_button = $TopBarPanel/TopBarContent/SearchRow/RefreshButton
@onready var create_button = $BottomBar/CreateButton
@onready var profile_button = $TopBarPanel/TopBarContent/HeaderRow/ProfileButton
@onready var loading_label = $LoadingLabel
@onready var favorites_toggle = $TopBarPanel/TopBarContent/FilterRow/FavoritesToggle
@onready var past_events_toggle = $TopBarPanel/TopBarContent/FilterRow/PastEventsToggle
@onready var sort_dropdown = $TopBarPanel/TopBarContent/FilterRow/SortDropdown
@onready var stats_label = $TopBarPanel/TopBarContent/FilterRow/StatsLabel
@onready var logo_container = $TopBarPanel/TopBarContent/HeaderRow/LogoContainer

# Event item template
const EVENT_ITEM = preload("res://UI/EventItem.tscn")

var events: Array[Event] = []
var current_category = ""
var current_search = ""
var current_zipcode = ""
var show_favorites_only = false
var show_past_events = false
var current_sort = "date"  # "date", "popularity", "alphabetical"
var current_user_data = {}
var zipcode_cache = {}  # Cache zip code -> city name mappings
var location_label: Label = null  # Prominent location display
var is_showing_welcome = true  # Track if we're on welcome screen or city view
var welcome_screen: Control = null  # The welcome/landing page

func _ready():
	# Connect signals
	api.events_fetched.connect(_on_events_fetched)
	api.rsvp_updated.connect(_on_rsvp_updated)
	api.favorite_updated.connect(_on_favorite_updated)
	search_input.text_changed.connect(_on_search_changed)
	category_dropdown.item_selected.connect(_on_category_selected)
	zipcode_filter.text_changed.connect(_on_zipcode_changed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	create_button.pressed.connect(_on_create_pressed)
	profile_button.pressed.connect(_on_profile_pressed)
	favorites_toggle.toggled.connect(_on_favorites_toggled)
	past_events_toggle.toggled.connect(_on_past_events_toggled)
	sort_dropdown.item_selected.connect(_on_sort_changed)

	# Track screen view
	Analytics.track_screen_view("event_list")

	# Create prominent location label under EventHive logo
	_create_location_label()

	# Setup category dropdown
	_setup_categories()

	# Load user data
	_load_user_data()

	# Show welcome screen instead of loading all events
	_show_welcome_screen()

func _show_welcome_screen():
	"""Display a cool welcome/landing page instead of all events"""
	# Set state
	is_showing_welcome = true
	loading_label.visible = false

	# Clear event container
	for child in event_container.get_children():
		if child.name != "TopSpacer":
			child.queue_free()

	# Hide location label
	if location_label:
		location_label.visible = false

	# Create welcome screen container
	welcome_screen = VBoxContainer.new()
	welcome_screen.name = "WelcomeScreen"
	welcome_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	welcome_screen.add_theme_constant_override("separation", 30)
	event_container.add_child(welcome_screen)

	# Top spacer for centering
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 80)
	welcome_screen.add_child(top_spacer)

	# App Logo/Icon
	var logo = Label.new()
	logo.text = "🎉"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 120)
	welcome_screen.add_child(logo)

	# Welcome Title - High-tech with glow
	var title = Label.new()
	title.text = "EVENTHIVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1, 0.5, 0, 1))  # Orange
	title.add_theme_color_override("font_outline_color", Color(1, 0.8, 0.2, 0.8))  # Gold outline
	title.add_theme_constant_override("outline_size", 4)
	welcome_screen.add_child(title)

	# Subtitle - Cyan accent
	var subtitle = Label.new()
	subtitle.text = "◈ Your Community, Your Events ◈"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 30)
	subtitle.add_theme_color_override("font_color", Color(0, 1, 1, 1))  # Cyan
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0.5, 0.5, 0.5))
	subtitle.add_theme_constant_override("outline_size", 2)
	welcome_screen.add_child(subtitle)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	welcome_screen.add_child(spacer1)

	# Instructions Panel - High-tech styling with neon glow
	var instructions_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.15, 0.9)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0, 1, 1, 0.8)  # Cyan neon border
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.shadow_color = Color(0, 1, 1, 0.4)  # Cyan glow
	panel_style.shadow_size = 20
	panel_style.shadow_offset = Vector2(0, 0)
	panel_style.content_margin_left = 45
	panel_style.content_margin_right = 45
	panel_style.content_margin_top = 35
	panel_style.content_margin_bottom = 35
	instructions_panel.add_theme_stylebox_override("panel", panel_style)

	var center_container = CenterContainer.new()
	center_container.custom_minimum_size = Vector2(800, 0)
	welcome_screen.add_child(center_container)
	center_container.add_child(instructions_panel)

	var instructions_vbox = VBoxContainer.new()
	instructions_vbox.add_theme_constant_override("separation", 20)
	instructions_panel.add_child(instructions_vbox)

	# Instruction Title - Cyan neon theme
	var instruction_title = Label.new()
	instruction_title.text = "⚡ GET STARTED"
	instruction_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_title.add_theme_font_size_override("font_size", 38)
	instruction_title.add_theme_color_override("font_color", Color(0, 1, 1, 1))  # Cyan
	instruction_title.add_theme_color_override("font_outline_color", Color(0, 0.5, 0.5, 0.8))
	instruction_title.add_theme_constant_override("outline_size", 3)
	instructions_vbox.add_child(instruction_title)

	# Instruction Text
	var instruction_text = Label.new()
	instruction_text.text = "Enter your CITY NAME or ZIP CODE in the search bar above to discover events in your area."
	instruction_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_text.add_theme_font_size_override("font_size", 26)
	instruction_text.add_theme_color_override("font_color", Color(0.85, 0.95, 1, 1))
	instruction_text.custom_minimum_size = Vector2(700, 0)
	instructions_vbox.add_child(instruction_text)

	# Quick access if user has zipcode in profile
	if current_user_data.has("zipcode") and current_user_data["zipcode"] != "":
		var user_zip = current_user_data["zipcode"]

		var sep = HSeparator.new()
		instructions_vbox.add_child(sep)

		var quick_access_label = Label.new()
		quick_access_label.text = "or jump to your home city:"
		quick_access_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quick_access_label.add_theme_font_size_override("font_size", 22)
		quick_access_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1))
		instructions_vbox.add_child(quick_access_label)

		# Quick access button - High-tech orange glow
		var btn_container = CenterContainer.new()
		instructions_vbox.add_child(btn_container)

		var quick_btn = Button.new()
		quick_btn.text = "🚀 JUMP TO " + user_zip
		quick_btn.custom_minimum_size = Vector2(380, 75)
		quick_btn.add_theme_font_size_override("font_size", 30)
		quick_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))

		# Style the button with orange neon glow
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(1, 0.5, 0, 1)  # Orange
		btn_style.border_width_left = 3
		btn_style.border_width_top = 3
		btn_style.border_width_right = 3
		btn_style.border_width_bottom = 3
		btn_style.border_color = Color(1, 0.8, 0.2, 1)
		btn_style.corner_radius_top_left = 18
		btn_style.corner_radius_top_right = 18
		btn_style.corner_radius_bottom_left = 18
		btn_style.corner_radius_bottom_right = 18
		btn_style.shadow_color = Color(1, 0.5, 0, 0.6)
		btn_style.shadow_size = 20
		btn_style.shadow_offset = Vector2(0, 0)
		quick_btn.add_theme_stylebox_override("normal", btn_style)

		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(1, 0.6, 0.1, 1)
		btn_hover.border_color = Color(1, 0.9, 0.3, 1)
		btn_hover.shadow_color = Color(1, 0.6, 0.1, 0.9)
		btn_hover.shadow_size = 30
		quick_btn.add_theme_stylebox_override("hover", btn_hover)

		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(1, 0.7, 0.2, 1)
		btn_pressed.shadow_size = 10
		quick_btn.add_theme_stylebox_override("pressed", btn_pressed)

		quick_btn.pressed.connect(func():
			# Set the zipcode and switch to city view
			zipcode_filter.text = user_zip
			_on_zipcode_changed(user_zip)
		)

		btn_container.add_child(quick_btn)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	welcome_screen.add_child(spacer2)

	# Features Grid
	var features_grid = GridContainer.new()
	features_grid.columns = 3
	features_grid.add_theme_constant_override("h_separation", 30)
	features_grid.add_theme_constant_override("v_separation", 20)

	var grid_center = CenterContainer.new()
	grid_center.add_child(features_grid)
	welcome_screen.add_child(grid_center)

	# Feature items
	var features = [
		{"icon": "🔍", "title": "Discover", "text": "Find local events"},
		{"icon": "➕", "title": "Create", "text": "Host your own events"},
		{"icon": "💬", "title": "Connect", "text": "Chat with attendees"},
		{"icon": "⭐", "title": "Favorite", "text": "Save events you love"},
		{"icon": "📅", "title": "RSVP", "text": "Show you're going"},
		{"icon": "🔔", "title": "Stay Updated", "text": "Never miss an event"}
	]

	for feature in features:
		var feature_box = VBoxContainer.new()
		feature_box.custom_minimum_size = Vector2(250, 180)
		feature_box.add_theme_constant_override("separation", 10)

		# Feature panel - High-tech with cyan/purple accents
		var feature_panel = PanelContainer.new()
		var feature_style = StyleBoxFlat.new()
		feature_style.bg_color = Color(0.06, 0.06, 0.12, 0.95)
		feature_style.border_width_left = 2
		feature_style.border_width_top = 2
		feature_style.border_width_right = 2
		feature_style.border_width_bottom = 2
		feature_style.border_color = Color(0.3, 0.6, 1, 0.5)  # Blue-cyan border
		feature_style.corner_radius_top_left = 15
		feature_style.corner_radius_top_right = 15
		feature_style.corner_radius_bottom_left = 15
		feature_style.corner_radius_bottom_right = 15
		feature_style.shadow_color = Color(0.3, 0.6, 1, 0.2)  # Subtle blue glow
		feature_style.shadow_size = 10
		feature_style.shadow_offset = Vector2(0, 2)
		feature_style.content_margin_left = 22
		feature_style.content_margin_right = 22
		feature_style.content_margin_top = 22
		feature_style.content_margin_bottom = 22
		feature_panel.add_theme_stylebox_override("panel", feature_style)

		var feature_vbox = VBoxContainer.new()
		feature_vbox.add_theme_constant_override("separation", 8)
		feature_panel.add_child(feature_vbox)

		var icon = Label.new()
		icon.text = feature["icon"]
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 50)
		feature_vbox.add_child(icon)

		var feat_title = Label.new()
		feat_title.text = feature["title"]
		feat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		feat_title.add_theme_font_size_override("font_size", 25)
		feat_title.add_theme_color_override("font_color", Color(0, 1, 1, 1))  # Cyan
		feat_title.add_theme_color_override("font_outline_color", Color(0, 0.5, 0.5, 0.5))
		feat_title.add_theme_constant_override("outline_size", 1)
		feature_vbox.add_child(feat_title)

		var feat_text = Label.new()
		feat_text.text = feature["text"]
		feat_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		feat_text.add_theme_font_size_override("font_size", 19)
		feat_text.add_theme_color_override("font_color", Color(0.75, 0.85, 1, 1))  # Light cyan-blue
		feat_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feature_vbox.add_child(feat_text)

		feature_box.add_child(feature_panel)
		features_grid.add_child(feature_box)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 50)
	welcome_screen.add_child(bottom_spacer)

func _hide_welcome_screen():
	"""Remove welcome screen and switch to city view mode"""
	is_showing_welcome = false

	# Remove welcome screen if it exists
	if welcome_screen:
		welcome_screen.queue_free()
		welcome_screen = null

func _load_user_data():
	# Get cached user profile
	var cached_user = DataCache.get_cached_user_profile()
	if cached_user:
		set_user_data(cached_user)

func set_user_data(user_data: Dictionary):
	current_user_data = user_data
	# Keep profile button simple with just the icon
	profile_button.text = "👤"
	profile_button.tooltip_text = user_data.get("username", "Profile") + " - Click for settings"

func _setup_categories():
	category_dropdown.clear()
	category_dropdown.add_item("All Events", 0)

	var categories = Event.CATEGORIES
	var idx = 1
	for cat_key in categories.keys():
		category_dropdown.add_item(categories[cat_key], idx)
		category_dropdown.set_item_metadata(idx, cat_key)
		idx += 1

func _create_location_label():
	# Create a prominent location label under the EventHive logo
	location_label = Label.new()
	location_label.name = "LocationLabel"
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1))  # Bright cyan
	location_label.add_theme_font_size_override("font_size", 44)  # Increased from 32 to 44
	location_label.text = ""
	location_label.visible = false  # Hidden by default

	# Add to logo container
	logo_container.add_child(location_label)

func _update_location_display():
	if current_zipcode.length() == 5 and location_label:
		var city_name = _get_city_from_zipcode(current_zipcode)
		location_label.text = "📍 " + city_name
		location_label.visible = true
	elif location_label:
		location_label.visible = false

func _refresh_events():
	loading_label.visible = true
	# Combine search text with location filter for backend search
	var combined_search = current_search
	if current_zipcode != "":
		# Add location to search query
		combined_search = combined_search + " " + current_zipcode if combined_search != "" else current_zipcode
	api.fetch_events(current_category, combined_search.strip_edges(), "")

func _on_events_fetched(events_data: Array):
	loading_label.visible = false
	events.clear()

	# Parse events
	for event_data in events_data:
		var event = Event.from_dict(event_data)
		events.append(event)

	_update_event_list()

func _update_event_list():
	# Clear existing items
	for child in event_container.get_children():
		if child.name != "TopSpacer":  # Keep the top spacer
			child.queue_free()

	# Filter and sort events
	var filtered_events = _filter_events(events)
	var sorted_events = _sort_events(filtered_events)

	# Update stats label
	_update_stats_label(sorted_events)

	# Add event items with improved empty states
	if sorted_events.is_empty():
		_show_empty_state()
	else:
		for event in sorted_events:
			var item = EVENT_ITEM.instantiate()
			event_container.add_child(item)
			if item.has_method("set_event"):
				item.set_event(event)
			if item.has_signal("clicked"):
				item.clicked.connect(_on_event_item_clicked.bind(event))
			if item.has_signal("rsvp_changed"):
				item.rsvp_changed.connect(_on_item_rsvp_changed)
			if item.has_signal("favorite_toggled"):
				item.favorite_toggled.connect(_on_item_favorite_toggled)
			if item.has_signal("share_requested"):
				item.share_requested.connect(_on_item_share_requested)

func _on_event_item_clicked(event: Event):
	event_clicked.emit(event)

func _on_search_changed(new_text: String):
	current_search = new_text.strip_edges()
	# Debounce search - wait 0.5s before searching
	if current_search.length() >= 2:
		# User is searching - hide welcome screen
		if is_showing_welcome:
			_hide_welcome_screen()
		await get_tree().create_timer(0.5).timeout
		_refresh_events()
	elif current_search == "":
		# Search cleared - only refresh if we already have a city selected
		await get_tree().create_timer(0.5).timeout
		if current_zipcode != "":
			_refresh_events()
		elif not is_showing_welcome:
			_show_welcome_screen()

func _on_category_selected(index: int):
	if index == 0:
		current_category = ""
	else:
		current_category = category_dropdown.get_item_metadata(index)

	# Only refresh if we're in city view (not welcome screen)
	if not is_showing_welcome:
		_refresh_events()

func _on_zipcode_changed(new_text: String):
	var input = new_text.strip_edges()

	# If empty, clear filter and return to welcome screen
	if input.length() == 0:
		current_zipcode = ""
		_update_location_display()
		await get_tree().create_timer(0.3).timeout
		if is_showing_welcome:
			_show_welcome_screen()
		else:
			_update_event_list()
		return

	# User is searching - hide welcome screen and switch to city view
	if is_showing_welcome:
		_hide_welcome_screen()

	# If it's a 5-digit zip code, use it and show city name
	if input.length() == 5 and input.is_valid_int():
		current_zipcode = input
		_update_location_display()
		await get_tree().create_timer(0.5).timeout
		_refresh_events()  # Load events from API
		return

	# If it's text (city name), show it and search
	# Wait for user to finish typing (at least 3 characters)
	if input.length() >= 3:
		await get_tree().create_timer(0.8).timeout  # Debounce
		# Check if input hasn't changed (user stopped typing)
		if zipcode_filter.text.strip_edges() == input:
			# Use the city name directly in search
			current_zipcode = input
			_update_location_display()
			_refresh_events()  # Load events from API

func _search_city_for_zipcode(city_name: String):
	# Use Nominatim OpenStreetMap API to search for city
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_city_search_completed.bind(city_name, http))

	# Search for city in United States
	var search_query = city_name.uri_encode()
	var url = "https://nominatim.openstreetmap.org/search?city=" + search_query + "&country=United%20States&format=json&limit=1"

	var headers = ["User-Agent: EventHive Community Calendar App"]
	var result = http.request(url)

	if result != OK:
		print("[EventListScreen] Failed to search for city: " + city_name)

func _on_city_search_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, city_name: String, http: HTTPRequest):
	http.queue_free()

	if response_code != 200:
		print("[EventListScreen] City search failed with code: " + str(response_code))
		return

	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())

	if error != OK or not (json.data is Array):
		print("[EventListScreen] Failed to parse city search response")
		return

	var results = json.data
	if results.size() == 0:
		print("[EventListScreen] No results found for city: " + city_name)
		return

	# Get the first result
	var location = results[0]
	if location.has("lat") and location.has("lon"):
		# Now use reverse geocoding to get zip code
		_get_zipcode_from_coordinates(location["lat"], location["lon"], city_name)

func _get_zipcode_from_coordinates(lat: String, lon: String, city_name: String):
	# Use Nominatim reverse geocoding to get zip code
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_zipcode_from_coords_completed.bind(city_name, http))

	var url = "https://nominatim.openstreetmap.org/reverse?lat=" + lat + "&lon=" + lon + "&format=json&addressdetails=1"
	var headers = ["User-Agent: EventHive Community Calendar App"]
	var result = http.request(url)

	if result != OK:
		print("[EventListScreen] Failed to get zipcode for coordinates")

func _on_zipcode_from_coords_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, city_name: String, http: HTTPRequest):
	http.queue_free()

	if response_code != 200:
		return

	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())

	if error != OK or not (json.data is Dictionary):
		return

	var data = json.data
	if data.has("address") and data["address"].has("postcode"):
		var zipcode = data["address"]["postcode"]
		# Clean up zipcode (remove any extra characters)
		zipcode = zipcode.substr(0, 5) if zipcode.length() >= 5 else zipcode

		if zipcode.length() == 5 and zipcode.is_valid_int():
			# Cache this city → zipcode mapping
			zipcode_cache[city_name.to_lower()] = city_name + ", " + data["address"].get("state", "")

			# Update current zipcode and refresh events
			current_zipcode = zipcode
			_update_location_display()
			_update_event_list()
		else:
			print("[EventListScreen] Invalid zipcode format: " + zipcode)
	else:
		print("[EventListScreen] No postcode in response for: " + city_name)

func _on_refresh_pressed():
	# Only refresh if we're in city view (not welcome screen)
	if not is_showing_welcome:
		_refresh_events()

func _on_create_pressed():
	# Pass the current zipcode so event is created in the browsed city
	create_event_clicked.emit(current_zipcode)

func _on_profile_pressed():
	_show_profile_menu()

func _show_profile_menu():
	var popup = PopupMenu.new()

	# Add items with better styling
	popup.add_item("👤 Profile Settings", 0)
	popup.add_item("⚙️ App Settings", 1)
	popup.add_separator()
	popup.add_item("🚪 Logout", 2)

	# Style the popup with high visibility
	popup.min_size = Vector2(350, 0)

	# Create custom theme for better visibility
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.22, 0.98)  # Dark blue-grey, almost opaque
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(1, 0.84, 0.35, 1)  # Gold border
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_size = 15

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1, 0.84, 0.35, 0.3)  # Gold highlight on hover
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8

	popup.add_theme_stylebox_override("panel", style_box)
	popup.add_theme_stylebox_override("hover", hover_style)
	popup.add_theme_color_override("font_color", Color(1, 1, 1, 1))  # White text
	popup.add_theme_color_override("font_hover_color", Color(1, 0.84, 0.35, 1))  # Gold on hover
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_constant_override("v_separation", 12)

	# Position it near the profile button
	var button_pos = profile_button.global_position
	var button_size = profile_button.size

	add_child(popup)
	popup.popup(Rect2(button_pos.x - 300, button_pos.y + button_size.y + 10, 350, 0))

	# Connect selection
	popup.id_pressed.connect(func(id):
		match id:
			0:
				_show_profile_settings()
			1:
				_show_app_settings()
			2:
				logout_clicked.emit()
		popup.queue_free()
	)

	popup.close_requested.connect(popup.queue_free)

func _show_profile_settings():
	# Show profile settings popup
	var popup = _create_profile_settings_popup()
	add_child(popup)
	popup.popup_centered()

func _create_profile_settings_popup() -> Window:
	var popup = Window.new()
	popup.title = "Profile Settings"
	popup.size = Vector2i(900, 1200)
	popup.unresizable = false

	# Main container
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)

	# Add margin
	var top_margin = Control.new()
	top_margin.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(top_margin)

	# Title
	var title = Label.new()
	title.text = "⚙️ PROFILE SETTINGS"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separator
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)

	# Status Label (created early so callbacks can reference it)
	var status = Label.new()
	status.custom_minimum_size = Vector2(0, 40)
	status.add_theme_font_size_override("font_size", 22)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(status)

	# Profile Picture Section
	var profile_section = VBoxContainer.new()
	profile_section.add_theme_constant_override("separation", 15)
	vbox.add_child(profile_section)

	# Profile Picture Display
	var pic_container = CenterContainer.new()
	profile_section.add_child(pic_container)

	var profile_pic = ColorRect.new()
	profile_pic.custom_minimum_size = Vector2(200, 200)
	profile_pic.color = Color(0.2, 0.2, 0.25, 1)
	pic_container.add_child(profile_pic)

	var pic_icon = Label.new()
	pic_icon.text = "👤"
	pic_icon.add_theme_font_size_override("font_size", 120)
	pic_icon.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	pic_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pic_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pic_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile_pic.add_child(pic_icon)

	# Load existing profile picture if available
	if current_user_data.has("profile_picture") and current_user_data["profile_picture"] != "":
		var saved_pic_path = current_user_data["profile_picture"]
		var image = Image.new()
		if image.load(saved_pic_path) == OK:
			var texture = ImageTexture.create_from_image(image)
			pic_icon.visible = false

			var pic_rect = TextureRect.new()
			pic_rect.name = "ProfileImage"
			pic_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			pic_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			pic_rect.texture = texture
			profile_pic.add_child(pic_rect)

	# Username under picture
	var username_label = Label.new()
	username_label.text = current_user_data.get("username", "Username")
	username_label.add_theme_font_size_override("font_size", 32)
	username_label.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	username_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_section.add_child(username_label)

	# Email
	var email_label = Label.new()
	email_label.text = current_user_data.get("email", "email@example.com")
	email_label.add_theme_font_size_override("font_size", 24)
	email_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1))
	email_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_section.add_child(email_label)

	# Upload Photo Button
	var upload_btn = Button.new()
	upload_btn.text = "📷 Change Profile Picture"
	upload_btn.custom_minimum_size = Vector2(300, 60)
	upload_btn.add_theme_font_size_override("font_size", 26)
	upload_btn.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))

	var upload_container = CenterContainer.new()
	upload_container.add_child(upload_btn)
	profile_section.add_child(upload_container)

	# Store reference to profile picture display for updating
	var profile_pic_display = profile_pic
	var profile_icon_display = pic_icon
	var selected_profile_pic_path = ""

	upload_btn.pressed.connect(func():
		# Request permissions on Android
		if OS.get_name() == "Android":
			var permissions = ["android.permission.READ_EXTERNAL_STORAGE", "android.permission.READ_MEDIA_IMAGES"]
			for permission in permissions:
				if not OS.request_permission(permission):
					status.text = "⚠️ Storage permission required. Please enable in settings."
					status.add_theme_color_override("font_color", Color.YELLOW)

		# Create mobile-friendly file dialog
		var file_dialog = FileDialog.new()
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Image Files"])

		# Make dialog fullscreen on mobile for better touch experience
		if OS.has_feature("mobile"):
			file_dialog.size = Vector2i(DisplayServer.window_get_size())
			file_dialog.borderless = false
		else:
			file_dialog.size = Vector2i(700, 500)

		# Set initial path to common photo directories
		if OS.get_name() == "Android":
			file_dialog.current_dir = "/storage/emulated/0/DCIM"
		elif OS.get_name() == "iOS":
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
		else:
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)

		file_dialog.file_selected.connect(func(path: String):
			print("Selected profile picture: ", path)
			selected_profile_pic_path = path

			# Show loading status
			status.text = "⏳ Loading image..."
			status.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))

			# Load and display the image
			var image = Image.new()
			var error = image.load(path)
			if error == OK:
				# Resize image to fit profile picture size
				image.resize(200, 200, Image.INTERPOLATE_LANCZOS)

				# Create texture from image
				var texture = ImageTexture.create_from_image(image)

				# Hide the icon and show the image
				profile_icon_display.visible = false

				# Create or update TextureRect for the image
				var pic_rect = profile_pic_display.get_node_or_null("ProfileImage")
				if not pic_rect:
					pic_rect = TextureRect.new()
					pic_rect.name = "ProfileImage"
					pic_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					pic_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					pic_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
					profile_pic_display.add_child(pic_rect)

				pic_rect.texture = texture
				pic_rect.visible = true

				status.text = "✅ Profile picture updated! Click Save to keep changes."
				status.add_theme_color_override("font_color", Color.GREEN)
			else:
				var error_msg = "Unknown error"
				match error:
					ERR_FILE_NOT_FOUND:
						error_msg = "File not found"
					ERR_FILE_CANT_OPEN:
						error_msg = "Cannot open file"
					ERR_FILE_CANT_READ:
						error_msg = "Cannot read file - check permissions"
					_:
						error_msg = "Error code: " + str(error)

				status.text = "❌ Failed to load image: " + error_msg
				status.add_theme_color_override("font_color", Color.RED)

			file_dialog.queue_free()
		)

		# Handle cancel
		file_dialog.canceled.connect(func():
			file_dialog.queue_free()
		)

		popup.add_child(file_dialog)
		file_dialog.popup_centered()
	)

	# Separator
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Account Settings Title
	var settings_title = Label.new()
	settings_title.text = "ACCOUNT SETTINGS"
	settings_title.add_theme_font_size_override("font_size", 28)
	settings_title.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(settings_title)

	# Username Input
	_add_settings_row(vbox, "Username:", current_user_data.get("username", ""), "username_input")

	# Email Input
	_add_settings_row(vbox, "Email:", current_user_data.get("email", ""), "email_input")

	# Zip Code Input
	_add_settings_row(vbox, "Zip Code:", current_user_data.get("zipcode", ""), "zipcode_input", 5)

	# Separator
	var sep3 = HSeparator.new()
	vbox.add_child(sep3)

	# Theme Settings Title
	var theme_title = Label.new()
	theme_title.text = "THEME CUSTOMIZATION"
	theme_title.add_theme_font_size_override("font_size", 28)
	theme_title.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	theme_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(theme_title)

	# Load saved theme preferences
	var prefs = Config.load_preferences()
	var primary_color = Color(1, 0.84, 0.35, 1)  # Default gold
	var secondary_color = Color(0.05, 0.05, 0.12, 1)  # Default black

	if prefs.has("primary_color"):
		var color_array = prefs["primary_color"]
		primary_color = Color(color_array[0], color_array[1], color_array[2], color_array[3])

	if prefs.has("secondary_color"):
		var color_array = prefs["secondary_color"]
		secondary_color = Color(color_array[0], color_array[1], color_array[2], color_array[3])

	# Primary Color
	_add_color_picker_row(vbox, "Primary Color (Gold):", primary_color, "primary_color")

	# Secondary Color
	_add_color_picker_row(vbox, "Secondary Color (Black):", secondary_color, "secondary_color")

	# Reset Theme Button
	var reset_btn = Button.new()
	reset_btn.text = "🔄 Reset Theme to Default"
	reset_btn.custom_minimum_size = Vector2(0, 50)
	reset_btn.add_theme_font_size_override("font_size", 24)
	reset_btn.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	reset_btn.pressed.connect(func():
		# Reset color pickers to default
		var primary_picker = vbox.find_child("primary_color", true, false)
		var secondary_picker = vbox.find_child("secondary_color", true, false)

		if primary_picker:
			primary_picker.color = Color(1, 0.84, 0.35, 1)  # Default gold
		if secondary_picker:
			secondary_picker.color = Color(0.05, 0.05, 0.12, 1)  # Default black

		# Save reset preferences
		var reset_prefs = Config.load_preferences()
		reset_prefs["primary_color"] = [1.0, 0.84, 0.35, 1.0]
		reset_prefs["secondary_color"] = [0.05, 0.05, 0.12, 1.0]
		Config.save_preferences(reset_prefs)

		status.text = "✅ Theme reset to default (Gold & Black)"
		status.add_theme_color_override("font_color", Color.GREEN)
	)
	vbox.add_child(reset_btn)

	# Spacer before buttons
	var spacer_before_buttons = Control.new()
	spacer_before_buttons.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer_before_buttons)

	# Buttons Row
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	# Close Button
	var close_btn = Button.new()
	close_btn.text = "❌ CLOSE"
	close_btn.custom_minimum_size = Vector2(200, 60)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))
	close_btn.pressed.connect(popup.queue_free)
	btn_row.add_child(close_btn)

	# Save Button
	var save_btn = Button.new()
	save_btn.text = "💾 SAVE"
	save_btn.custom_minimum_size = Vector2(200, 60)
	save_btn.add_theme_font_size_override("font_size", 28)
	save_btn.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	save_btn.pressed.connect(func():
		# Get input values
		var username_field = vbox.find_child("username_input", true, false)
		var email_field = vbox.find_child("email_input", true, false)
		var zipcode_field = vbox.find_child("zipcode_input", true, false)
		var primary_picker = vbox.find_child("primary_color", true, false)
		var secondary_picker = vbox.find_child("secondary_color", true, false)

		var new_username = username_field.text.strip_edges() if username_field else current_user_data.get("username", "")
		var new_email = email_field.text.strip_edges() if email_field else current_user_data.get("email", "")
		var new_zipcode = zipcode_field.text.strip_edges() if zipcode_field else current_user_data.get("zipcode", "")

		# Validate inputs
		if new_username.length() < 3:
			status.text = "❌ Username must be at least 3 characters"
			status.add_theme_color_override("font_color", Color.RED)
			return

		if not Config.is_valid_email(new_email):
			status.text = "❌ Invalid email format"
			status.add_theme_color_override("font_color", Color.RED)
			return

		if not Config.is_valid_us_zipcode(new_zipcode):
			status.text = "❌ Please enter a valid US zip code (5 digits)"
			status.add_theme_color_override("font_color", Color.RED)
			return

		# Save profile picture if one was selected
		if selected_profile_pic_path != "":
			# Copy image to user data directory
			var user_dir = "user://profile_pictures"
			DirAccess.make_dir_absolute(user_dir)
			var filename = str(Time.get_unix_time_from_system()) + "_profile.png"
			var dest_path = user_dir + "/" + filename

			# Load and save image
			var image = Image.new()
			if image.load(selected_profile_pic_path) == OK:
				image.resize(200, 200, Image.INTERPOLATE_LANCZOS)
				image.save_png(dest_path)
				current_user_data["profile_picture"] = dest_path

		# Update user data
		current_user_data["username"] = new_username
		current_user_data["email"] = new_email
		current_user_data["zipcode"] = new_zipcode

		# Save to DataCache
		DataCache.cache_user_profile(current_user_data)

		# Save theme preferences
		var theme_prefs = Config.load_preferences()
		if primary_picker:
			var color = primary_picker.color
			theme_prefs["primary_color"] = [color.r, color.g, color.b, color.a]
		if secondary_picker:
			var color = secondary_picker.color
			theme_prefs["secondary_color"] = [color.r, color.g, color.b, color.a]
		Config.save_preferences(theme_prefs)

		# Update profile button to show new username
		if profile_button and new_username != "":
			profile_button.text = "👤\n" + new_username

		status.text = "✅ Settings saved successfully!\nChanges will persist on next login."
		status.add_theme_color_override("font_color", Color.GREEN)

		# TODO: Send update to backend API when endpoint is available
		# api.update_user_profile(current_user_data)
	)
	btn_row.add_child(save_btn)

	# Bottom Margin
	var bottom_margin = Control.new()
	bottom_margin.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(bottom_margin)

	return popup

func _add_settings_row(parent: VBoxContainer, label_text: String, default_value: String, input_name: String, max_length: int = 0):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	parent.add_child(row)

	var left_spacer = Control.new()
	left_spacer.custom_minimum_size = Vector2(30, 0)
	row.add_child(left_spacer)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var input = LineEdit.new()
	input.text = default_value
	input.custom_minimum_size = Vector2(0, 55)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_font_size_override("font_size", 24)
	input.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1))
	if max_length > 0:
		input.max_length = max_length
	input.name = input_name
	row.add_child(input)

	var right_spacer = Control.new()
	right_spacer.custom_minimum_size = Vector2(30, 0)
	row.add_child(right_spacer)

func _add_color_picker_row(parent: VBoxContainer, label_text: String, default_color: Color, picker_name: String):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	parent.add_child(row)

	var left_spacer = Control.new()
	left_spacer.custom_minimum_size = Vector2(30, 0)
	row.add_child(left_spacer)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(300, 0)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var picker = ColorPickerButton.new()
	picker.color = default_color
	picker.custom_minimum_size = Vector2(120, 55)
	picker.name = picker_name
	row.add_child(picker)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

func _show_app_settings():
	var dialog = AcceptDialog.new()
	dialog.title = "APP SETTINGS"
	dialog.dialog_text = "App settings:\n\n• Notifications\n• Theme\n• Privacy\n• About EventHive v" + Config.APP_VERSION
	dialog.ok_button_text = "OK"
	dialog.min_size = Vector2(600, 400)

	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

func _on_item_rsvp_changed(event_id: int, rsvp_status: String):
	api.update_rsvp(event_id, rsvp_status)

func _on_item_favorite_toggled(event_id: int, is_favorited: bool):
	api.toggle_favorite(event_id, is_favorited)

func _on_item_share_requested(event: Event):
	_show_share_dialog(event)

func _on_rsvp_updated(success: bool, event_id: int, rsvp_status: String):
	if success:
		# Update the local event data
		for e in events:
			if e.id == event_id:
				e.user_rsvp = rsvp_status
				break

func _on_favorite_updated(success: bool, event_id: int, is_favorited: bool):
	if success:
		# Update the local event data
		for e in events:
			if e.id == event_id:
				e.is_favorited = is_favorited
				break

func _show_share_dialog(event: Event):
	# Create a simple share dialog
	var dialog = AcceptDialog.new()
	dialog.title = "SHARE EVENT"
	dialog.dialog_text = "Share: " + event.title + "\n\n" + event.get_formatted_datetime() + "\n" + event.location
	dialog.ok_button_text = "COPY LINK"

	# Style the dialog with cyberpunk theme
	dialog.min_size = Vector2(600, 400)

	add_child(dialog)
	dialog.popup_centered()

	# When OK is pressed, copy to clipboard
	dialog.confirmed.connect(func():
		var share_text = event.title + " - " + event.get_formatted_datetime() + " at " + event.location
		DisplayServer.clipboard_set(share_text)

		# Show a brief confirmation
		var confirm = AcceptDialog.new()
		confirm.dialog_text = "LINK COPIED TO CLIPBOARD"
		confirm.ok_button_text = "OK"
		add_child(confirm)
		confirm.popup_centered()
		confirm.confirmed.connect(confirm.queue_free)
	)

	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free.call_deferred)

func _on_favorites_toggled(toggled_on: bool):
	show_favorites_only = toggled_on
	# Only update if we're in city view (not welcome screen)
	if not is_showing_welcome:
		_update_event_list()

func _on_past_events_toggled(toggled_on: bool):
	show_past_events = toggled_on
	# Only update if we're in city view (not welcome screen)
	if not is_showing_welcome:
		_update_event_list()

func _on_sort_changed(index: int):
	match index:
		0:
			current_sort = "date"
		1:
			current_sort = "popularity"
		2:
			current_sort = "alphabetical"
	# Only update if we're in city view (not welcome screen)
	if not is_showing_welcome:
		_update_event_list()

func _filter_events(event_list: Array[Event]) -> Array[Event]:
	var filtered: Array[Event] = []

	for event in event_list:
		# Filter by favorites
		if show_favorites_only and not event.is_favorited:
			continue

		# Filter by past events
		if not show_past_events and event.is_past_event():
			continue

		# Filter by zip code (if specified)
		if current_zipcode.length() == 5:
			# Extract zip from event location (assumes format like "City, OK 74631")
			var event_zip = _extract_zipcode(event.location)
			if event_zip != current_zipcode:
				continue

		filtered.append(event)

	return filtered

func _extract_zipcode(location: String) -> String:
	# Try to extract a 5-digit zip code from location string
	var regex = RegEx.new()
	regex.compile("\\b\\d{5}\\b")
	var result = regex.search(location)
	if result:
		return result.get_string()
	return ""

func _sort_events(event_list: Array[Event]) -> Array[Event]:
	var sorted_list = event_list.duplicate()

	match current_sort:
		"date":
			# Sort by date (nearest first)
			sorted_list.sort_custom(func(a, b):
				var a_status = a.get_event_status()
				var b_status = b.get_event_status()
				# Prioritize: LIVE > UPCOMING > PAST
				if a_status == "LIVE" and b_status != "LIVE":
					return true
				if a_status != "LIVE" and b_status == "LIVE":
					return false
				# Then sort by date
				return a.date < b.date
			)
		"popularity":
			# Sort by total attendees (going + interested)
			sorted_list.sort_custom(func(a, b):
				var a_total = a.attendees_going + a.attendees_interested
				var b_total = b.attendees_going + b.attendees_interested
				return a_total > b_total
			)
		"alphabetical":
			# Sort alphabetically by title
			sorted_list.sort_custom(func(a, b):
				return a.title < b.title
			)

	return sorted_list

func _update_stats_label(event_list: Array[Event]):
	var total = event_list.size()
	var live_count = 0
	var upcoming_count = 0
	var favorited_count = 0

	for event in event_list:
		var status = event.get_event_status()
		if status == "LIVE":
			live_count += 1
		elif status == "UPCOMING":
			upcoming_count += 1
		if event.is_favorited:
			favorited_count += 1

	var stats_text = "◈ " + str(total) + " EVENTS"
	if live_count > 0:
		stats_text += " • " + str(live_count) + " LIVE"
	if upcoming_count > 0:
		stats_text += " • " + str(upcoming_count) + " UPCOMING"
	if show_favorites_only:
		stats_text += " • FAVORITES"

	stats_label.text = stats_text

func _show_empty_state():
	# Create contextual empty state based on filters
	var empty_vbox = VBoxContainer.new()
	empty_vbox.custom_minimum_size = Vector2(0, 400)
	empty_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_vbox.add_theme_constant_override("separation", 20)
	event_container.add_child(empty_vbox)

	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 50)
	empty_vbox.add_child(spacer1)

	# Icon
	var icon = Label.new()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 80)
	empty_vbox.add_child(icon)

	# Title
	var title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
	empty_vbox.add_child(title)

	# Message
	var message = Label.new()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(600, 0)
	empty_vbox.add_child(message)

	# Contextual messages based on filters
	if show_favorites_only:
		icon.text = "⭐"
		title.text = "No Favorite Events"
		message.text = "You haven't favorited any events yet.\n\nBrowse events and tap the ★ icon to save your favorites!"
	elif current_zipcode != "":
		icon.text = "📍"
		title.text = "No Events in " + current_zipcode
		message.text = "No events found in zip code " + current_zipcode + ".\n\nTry searching a different zip code or clear the filter to see all events."
	elif current_category != "":
		icon.text = "📂"
		title.text = "No " + Event.CATEGORIES.get(current_category, "Events") + " Found"
		message.text = "There are no " + Event.CATEGORIES.get(current_category, "events") + " at the moment.\n\nTry a different category or be the first to create one!"
	elif current_search != "":
		icon.text = "🔍"
		title.text = "No Results for \"" + current_search + "\""
		message.text = "We couldn't find any events matching your search.\n\nTry different keywords or clear the search to see all events."
	elif not show_past_events:
		icon.text = "📅"
		title.text = "No Upcoming Events"
		message.text = "There are no upcoming events in your area yet.\n\nBe the first to create an event and bring your community together!"
	else:
		icon.text = "🎉"
		title.text = "No Events Yet"
		message.text = "Welcome to EventHive! There are no events posted yet.\n\nBe a community leader - create the first event!"

	# Action button
	var button_container = CenterContainer.new()
	empty_vbox.add_child(button_container)

	var action_button = Button.new()
	action_button.custom_minimum_size = Vector2(300, 70)
	action_button.add_theme_font_size_override("font_size", 28)
	button_container.add_child(action_button)

	if show_favorites_only or current_zipcode != "" or current_category != "" or current_search != "":
		action_button.text = "🔄 Clear Filters"
		action_button.pressed.connect(func():
			show_favorites_only = false
			favorites_toggle.button_pressed = false
			current_zipcode = ""
			zipcode_filter.text = ""
			current_category = ""
			category_dropdown.selected = 0
			current_search = ""
			search_input.text = ""
			_refresh_events()
		)
	else:
		action_button.text = "+ Create First Event"
		action_button.pressed.connect(func():
			create_event_clicked.emit()
		)

# Get city name from zip code
func _get_city_from_zipcode(zipcode: String) -> String:
	# Check cache first
	if zipcode_cache.has(zipcode):
		return zipcode_cache[zipcode]

	# Start async lookup
	_lookup_city_from_zipcode(zipcode)

	# Return temporary text while loading
	return "ZIP: " + zipcode

# Async lookup of city name from zip code
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

					# Refresh display if this is the current zip code
					if current_zipcode == zipcode:
						_update_location_display()
						_update_event_list()
					return

	# Fallback if API fails
	zipcode_cache[zipcode] = "ZIP: " + zipcode
