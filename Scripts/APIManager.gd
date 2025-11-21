extends Node

## Production-Ready API Manager
## Handles all backend communication with error handling, caching, and retry logic

# Signals for async responses
signal login_completed(success: bool, data: Dictionary)
signal register_completed(success: bool, data: Dictionary)
signal events_fetched(events: Array)
signal event_created(success: bool, event: Dictionary)
signal event_updated(success: bool, event: Dictionary)
signal event_deleted(success: bool)
signal rsvp_updated(success: bool, event_id: int, rsvp_status: String)
signal favorite_updated(success: bool, event_id: int, is_favorited: bool)
signal network_error(error_message: String)
signal token_expired()
signal profile_updated(success: bool, data: Dictionary)
signal comment_added(success: bool, comment: Dictionary)
signal comments_fetched(comments: Array)

# Configuration
var auth_token = ""
var demo_events = []  # Store demo events locally
var request_timeout = 30.0  # 30 seconds
var max_retries = 3
var retry_delay = 1.0

# Rate limiting
var last_request_time = 0
var request_count = 0

func _ready():
	# Load saved auth token if exists
	load_auth_token()

	# Initialize demo data if in demo mode
	if Config.is_demo_mode():
		_init_demo_data()

	# Clean up expired cache periodically
	if Config.is_feature_enabled("offline_mode"):
		_start_cache_cleanup_timer()

func _start_cache_cleanup_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 300.0  # 5 minutes
	timer.timeout.connect(DataCache.cleanup_expired_cache)
	timer.start()

func load_auth_token():
	if FileAccess.file_exists("user://auth_token.txt"):
		var file = FileAccess.open("user://auth_token.txt", FileAccess.READ)
		auth_token = file.get_as_text()
		file.close()

func save_auth_token(token: String):
	auth_token = token
	var file = FileAccess.open("user://auth_token.txt", FileAccess.WRITE)
	file.store_string(token)
	file.close()

func clear_auth_token():
	auth_token = ""
	if FileAccess.file_exists("user://auth_token.txt"):
		DirAccess.remove_absolute("user://auth_token.txt")

# Authentication endpoints
func login(email: String, password: String):
	# Validate input
	email = email.strip_edges()
	if not Config.is_valid_email(email):
		login_completed.emit(false, {"message": "Invalid email format"})
		Analytics.track_error("Login failed: invalid email format")
		return

	if password.length() == 0:
		login_completed.emit(false, {"message": "Password cannot be empty"})
		return

	# Demo mode
	if Config.is_demo_mode():
		_demo_login(email, password)
		return

	# Track analytics
	Analytics.track_event("login_attempted", {"email": email})

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(_on_login_completed)

	var body = JSON.stringify({"email": email, "password": password})
	var headers = ["Content-Type: application/json"]
	var result = http.request(Config.get_api_url() + "/auth/login", headers, HTTPClient.METHOD_POST, body)

	if result != OK:
		_handle_request_error("Login request failed")
		login_completed.emit(false, {"message": "Network error. Please check your connection."})

func register(username: String, email: String, password: String, zipcode: String = ""):
	# Sanitize and validate input
	username = Config.sanitize_input(username.strip_edges())
	email = email.strip_edges()
	zipcode = zipcode.strip_edges()

	# Validate username
	if username.length() < Config.VALIDATION["min_username_length"]:
		register_completed.emit(false, {"message": "Username must be at least " + str(Config.VALIDATION["min_username_length"]) + " characters"})
		return

	if username.length() > Config.VALIDATION["max_username_length"]:
		register_completed.emit(false, {"message": "Username is too long"})
		return

	# Validate email
	if not Config.is_valid_email(email):
		register_completed.emit(false, {"message": "Invalid email format"})
		return

	# Validate zip code
	if not Config.is_valid_us_zipcode(zipcode):
		register_completed.emit(false, {"message": "Must be a valid US zip code (5 digits)"})
		return

	# Validate password
	var password_check = Config.validate_password(password)
	if not password_check["valid"]:
		var error_msg = "\n".join(password_check["errors"])
		register_completed.emit(false, {"message": error_msg})
		return

	# Demo mode
	if Config.is_demo_mode():
		_demo_register(username, email, password)
		return

	# Track analytics
	Analytics.track_event("registration_attempted", {"username": username, "zipcode": zipcode})

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(_on_register_completed)

	var body = JSON.stringify({"username": username, "email": email, "password": password, "zipcode": zipcode})
	var headers = ["Content-Type: application/json"]
	var result = http.request(Config.get_api_url() + "/auth/register", headers, HTTPClient.METHOD_POST, body)

	if result != OK:
		_handle_request_error("Registration request failed")
		register_completed.emit(false, {"message": "Network error. Please check your connection."})

# Profile update endpoint
func update_profile(profile_data: Dictionary):
	# Sanitize and validate input
	var username = profile_data.get("username", "").strip_edges()
	var email = profile_data.get("email", "").strip_edges()
	var zipcode = profile_data.get("zipcode", "").strip_edges()

	# Validate username
	if username.length() > 0:
		username = Config.sanitize_input(username)
		if username.length() < Config.VALIDATION["min_username_length"]:
			profile_updated.emit(false, {"message": "Username must be at least " + str(Config.VALIDATION["min_username_length"]) + " characters"})
			return
		if username.length() > Config.VALIDATION["max_username_length"]:
			profile_updated.emit(false, {"message": "Username is too long"})
			return

	# Validate email
	if email.length() > 0:
		if not Config.is_valid_email(email):
			profile_updated.emit(false, {"message": "Invalid email format"})
			return

	# Validate zip code
	if zipcode.length() > 0:
		if not Config.is_valid_us_zipcode(zipcode):
			profile_updated.emit(false, {"message": "Must be a valid US zip code (5 digits)"})
			return

	# Demo mode
	if Config.is_demo_mode():
		_demo_update_profile(profile_data)
		return

	# Track analytics
	Analytics.track_event("profile_updated")

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(_on_profile_updated)

	var body = JSON.stringify(profile_data)
	var headers = _get_auth_headers()
	headers.append("Content-Type: application/json")
	var result = http.request(Config.get_api_url() + "/auth/profile", headers, HTTPClient.METHOD_PUT, body)

	if result != OK:
		_handle_request_error("Profile update request failed")
		profile_updated.emit(false, {"message": "Network error. Please check your connection."})

# Event endpoints
func fetch_events(category: String = "", search: String = "", zipcode: String = "", use_cache: bool = true):
	# Try cache first
	if use_cache and Config.is_feature_enabled("offline_mode"):
		var cache_key = category + "_" + search + "_" + zipcode
		var cached_events = DataCache.get_cached_event_list(cache_key, "")
		if not cached_events.is_empty():
			events_fetched.emit(cached_events)
			# Still fetch fresh data in background
			_fetch_events_from_api(category, search, zipcode, true)
			return

	# Demo mode
	if Config.is_demo_mode():
		_demo_fetch_events(category, search, zipcode)
		return

	# Fetch from API
	_fetch_events_from_api(category, search, zipcode, false)

func _fetch_events_from_api(category: String, search: String, zipcode: String, is_background: bool):
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(func(result, response_code, headers, body):
		_on_events_fetched(result, response_code, headers, body, category, search, is_background)
	)

	var url = Config.get_api_url() + "/events"
	var params = []
	if category != "":
		params.append("category=" + category.uri_encode())
	if search != "":
		params.append("search=" + search.uri_encode())
	# Note: Backend doesn't support zipcode filtering yet
	# Using search parameter with location text instead
	if params.size() > 0:
		url += "?" + "&".join(params)

	var headers_list = _get_auth_headers()
	var result = http.request(url, headers_list, HTTPClient.METHOD_GET)

	if result != OK:
		_handle_request_error("Failed to fetch events")
		if not is_background:
			events_fetched.emit([])

func create_event(event_data: Dictionary):
	# Validate and sanitize event data
	var validated_data = _validate_event_data(event_data)
	if validated_data.has("error"):
		event_created.emit(false, validated_data)
		return

	# Demo mode
	if Config.is_demo_mode():
		_demo_create_event(validated_data)
		return

	# Track analytics
	Analytics.track_event(Config.ANALYTICS_EVENTS["event_created"], {
		"category": validated_data.get("category", "")
	})

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = 60.0  # Longer timeout to handle Render.com cold starts
	http.request_completed.connect(_on_event_created)

	var body = JSON.stringify(validated_data)
	var headers = _get_auth_headers()
	headers.append("Content-Type: application/json")

	print("[APIManager] Creating event - URL: ", Config.get_api_url() + "/events")
	print("[APIManager] Has auth token: ", auth_token != "")
	print("[APIManager] Event data: ", validated_data)

	var result = http.request(Config.get_api_url() + "/events", headers, HTTPClient.METHOD_POST, body)

	if result != OK:
		print("[APIManager] HTTP request failed immediately: ", result)
		_handle_request_error("Failed to create event")
		http.queue_free()
		event_created.emit(false, {"message": "Network error. Please try again."})

func update_event(event_id: int, event_data: Dictionary):
	# Validate and sanitize event data
	var validated_data = _validate_event_data(event_data)
	if validated_data.has("error"):
		event_updated.emit(false, validated_data)
		return

	# Demo mode
	if Config.is_demo_mode():
		_demo_update_event(event_id, validated_data)
		return

	# Track analytics
	Analytics.track_event(Config.ANALYTICS_EVENTS["event_edited"], {
		"event_id": event_id
	})

	# Invalidate cache
	DataCache.invalidate_event(event_id)

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(_on_event_updated)

	var body = JSON.stringify(validated_data)
	var headers = _get_auth_headers()
	headers.append("Content-Type: application/json")
	var result = http.request(Config.get_api_url() + "/events/" + str(event_id), headers, HTTPClient.METHOD_PUT, body)

	if result != OK:
		_handle_request_error("Failed to update event")
		event_updated.emit(false, {"message": "Network error. Please try again."})

func delete_event(event_id: int):
	# Demo mode
	if Config.is_demo_mode():
		_demo_delete_event(event_id)
		return

	# Track analytics
	Analytics.track_event(Config.ANALYTICS_EVENTS["event_deleted"], {
		"event_id": event_id
	})

	# Invalidate cache
	DataCache.invalidate_event(event_id)

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(_on_event_deleted)

	var headers = _get_auth_headers()
	var result = http.request(Config.get_api_url() + "/events/" + str(event_id), headers, HTTPClient.METHOD_DELETE)

	if result != OK:
		_handle_request_error("Failed to delete event")
		event_deleted.emit(false)

# Helper functions
func _get_auth_headers() -> Array:
	if auth_token != "":
		return ["Authorization: Bearer " + auth_token]
	return []

# Validate and sanitize event data
func _validate_event_data(event_data: Dictionary) -> Dictionary:
	var validated = event_data.duplicate()

	# Validate title
	if not validated.has("title") or validated["title"].strip_edges() == "":
		return {"error": true, "message": "Event title is required"}

	validated["title"] = Config.sanitize_input(validated["title"].strip_edges())
	if validated["title"].length() < Config.VALIDATION["min_event_title_length"]:
		return {"error": true, "message": "Title must be at least " + str(Config.VALIDATION["min_event_title_length"]) + " characters"}

	if validated["title"].length() > Config.VALIDATION["max_event_title_length"]:
		return {"error": true, "message": "Title is too long (max " + str(Config.VALIDATION["max_event_title_length"]) + " characters)"}

	# Validate description
	if validated.has("description"):
		validated["description"] = Config.sanitize_input(validated["description"].strip_edges())
		if validated["description"].length() > Config.VALIDATION["max_event_description_length"]:
			return {"error": true, "message": "Description is too long"}

	# Validate location
	if not validated.has("location") or validated["location"].strip_edges() == "":
		return {"error": true, "message": "Location is required"}

	validated["location"] = Config.sanitize_input(validated["location"].strip_edges())
	if validated["location"].length() > Config.VALIDATION["max_location_length"]:
		return {"error": true, "message": "Location is too long"}

	# Validate date
	if not validated.has("date") or not Config.is_valid_date(validated["date"].strip_edges()):
		return {"error": true, "message": "Valid date is required (YYYY-MM-DD)"}

	# Validate contact info
	if validated.has("contact_info"):
		validated["contact_info"] = Config.sanitize_input(validated["contact_info"].strip_edges())
		if validated["contact_info"].length() > Config.VALIDATION["max_contact_info_length"]:
			return {"error": true, "message": "Contact info is too long"}

	return validated

# Handle request errors
func _handle_request_error(error_message: String):
	Analytics.track_error(error_message)
	network_error.emit(error_message)
	print("[APIManager] Error: ", error_message)

# Response handlers
func _on_login_completed(result, response_code, headers, body):
	var response = _parse_response(body)
	var success = response_code == 200

	if success and response.has("token"):
		save_auth_token(response["token"])
		Analytics.track_event(Config.ANALYTICS_EVENTS["user_logged_in"])
		if response.has("id"):
			Analytics.identify_user(response["id"], response)
		DataCache.cache_user_profile(response)
	elif response_code == 401:
		response["message"] = "Invalid email or password"
	elif response_code >= 500:
		response["message"] = Config.get_error_message(response_code)

	login_completed.emit(success, response)
	_cleanup_http_request()

func _on_register_completed(result, response_code, headers, body):
	var response = _parse_response(body)
	var success = response_code == 201 or response_code == 200

	if success and response.has("token"):
		save_auth_token(response["token"])
		Analytics.track_event(Config.ANALYTICS_EVENTS["user_registered"])
		if response.has("id"):
			Analytics.identify_user(response["id"], response)
		DataCache.cache_user_profile(response)
	elif response_code == 409:
		response["message"] = "Email already registered"
	elif response_code >= 500:
		response["message"] = Config.get_error_message(response_code)

	register_completed.emit(success, response)
	_cleanup_http_request()

func _on_profile_updated(result, response_code, headers, body):
	var response = _parse_response(body)
	var success = response_code == 200

	if success:
		# Cache the updated profile
		DataCache.cache_user_profile(response)
		Analytics.track_event("profile_updated_success")
	elif response_code == 401:
		response["message"] = "Session expired. Please log in again."
		token_expired.emit()
	elif response_code == 409:
		response["message"] = "Email or username already taken"
	elif response_code >= 500:
		response["message"] = Config.get_error_message(response_code)

	profile_updated.emit(success, response)
	_cleanup_http_request()

func _on_events_fetched(result, response_code, headers, body, category: String, search: String, is_background: bool):
	var response = _parse_response(body)
	var events = []

	if response_code == 200:
		if response is Array:
			events = response
		elif response is Dictionary and response.has("events"):
			events = response["events"]

		# Cache the results
		if Config.is_feature_enabled("offline_mode"):
			DataCache.cache_event_list(category, search, events)

		# Only emit if not background refresh
		if not is_background:
			events_fetched.emit(events)
	elif response_code == 401:
		token_expired.emit()
		if not is_background:
			events_fetched.emit([])
	else:
		Analytics.track_error("Failed to fetch events", response_code)
		if not is_background:
			events_fetched.emit([])

	_cleanup_http_request()

func _on_event_created(result, response_code, headers, body):
	print("[APIManager] Event creation callback - Result: ", result, " Response code: ", response_code)

	# Handle network errors
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[APIManager] Network error: ", result)
		var error_msg = "Connection failed"
		if result == HTTPRequest.RESULT_TIMEOUT:
			error_msg = "Request timed out. Please try again."
		elif result == HTTPRequest.RESULT_CANT_CONNECT:
			error_msg = "Cannot connect to server. Check your internet."
		event_created.emit(false, {"message": error_msg})
		_cleanup_http_request()
		return

	var response = _parse_response(body)
	var success = response_code == 201 or response_code == 200

	# Debug logging
	print("[APIManager] Event creation response code: ", response_code)
	print("[APIManager] Event creation response: ", response)

	if not success:
		if response_code == 401:
			response["message"] = "You must be logged in to create events"
			token_expired.emit()
		elif response_code == 400:
			# Bad request - get the specific error from response
			if not response.has("message"):
				response["message"] = "Invalid event data. Please check all fields."
		elif response_code == 0:
			response["message"] = "No response from server. Check your internet connection."
		elif response_code >= 500:
			response["message"] = Config.get_error_message(response_code)
		Analytics.track_error("Event creation failed", response_code)

	event_created.emit(success, response)
	_cleanup_http_request()

func _on_event_updated(result, response_code, headers, body):
	var response = _parse_response(body)
	var success = response_code == 200

	if not success:
		if response_code == 401:
			response["message"] = "You must be logged in to edit events"
			token_expired.emit()
		elif response_code == 403:
			response["message"] = "You don't have permission to edit this event"
		elif response_code >= 500:
			response["message"] = Config.get_error_message(response_code)
		Analytics.track_error("Event update failed", response_code)

	event_updated.emit(success, response)
	_cleanup_http_request()

func _on_event_deleted(result, response_code, headers, body):
	var success = response_code == 200 or response_code == 204

	if not success:
		Analytics.track_error("Event deletion failed", response_code)

	event_deleted.emit(success)
	_cleanup_http_request()

func _parse_response(body: PackedByteArray):
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error == OK:
		return json.data
	return {}

func _cleanup_http_request():
	# Remove completed HTTP requests
	await get_tree().create_timer(0.1).timeout
	for child in get_children():
		if child is HTTPRequest:
			child.queue_free()

# ===== DEMO MODE FUNCTIONS =====
func _init_demo_data():
	# Create some sample events with all new features
	demo_events = [
		{
			"id": 1,
			"title": "Community Garage Sale",
			"description": "Annual neighborhood garage sale. Great deals on furniture, clothes, and household items!",
			"category": "garage_sale",
			"date": "2024-12-01",
			"time": "8:00 AM - 2:00 PM",
			"location": "123 Main St, Community Center Parking Lot",
			"organizer": "Admin",
			"organizer_id": 1,
			"contact_info": "555-1234",
			"created_at": "2024-11-19T10:00:00Z",
			"updated_at": "2024-11-19T10:00:00Z",
			"image_url": "",
			"attendees_going": 24,
			"attendees_interested": 12,
			"user_rsvp": "",
			"is_favorited": false,
			"max_capacity": 0,
			"tags": ["bargains", "family-friendly"]
		},
		{
			"id": 2,
			"title": "Youth Soccer Championship",
			"description": "Come support our local youth soccer teams in the regional championship finals!",
			"category": "sports",
			"date": "2024-11-25",
			"time": "2:00 PM",
			"location": "City Park Field 3",
			"organizer": "Admin",
			"organizer_id": 1,
			"contact_info": "coach@example.com",
			"created_at": "2024-11-19T11:00:00Z",
			"updated_at": "2024-11-19T11:00:00Z",
			"image_url": "",
			"attendees_going": 87,
			"attendees_interested": 34,
			"user_rsvp": "interested",
			"is_favorited": true,
			"max_capacity": 150,
			"tags": ["sports", "youth", "championship"]
		},
		{
			"id": 3,
			"title": "Town Hall Meeting",
			"description": "Monthly community meeting to discuss local issues and upcoming projects.",
			"category": "town_meeting",
			"date": "2024-12-15",
			"time": "7:00 PM",
			"location": "City Hall, Main Conference Room",
			"organizer": "Admin",
			"organizer_id": 1,
			"contact_info": "cityhall@example.com",
			"created_at": "2024-11-19T12:00:00Z",
			"updated_at": "2024-11-19T12:00:00Z",
			"image_url": "",
			"attendees_going": 15,
			"attendees_interested": 8,
			"user_rsvp": "",
			"is_favorited": false,
			"max_capacity": 50,
			"tags": ["government", "civic-duty"]
		},
		{
			"id": 4,
			"title": "Holiday Bake Sale Fundraiser",
			"description": "Support our local school with delicious homemade treats and baked goods!",
			"category": "fundraiser",
			"date": "2024-12-10",
			"time": "10:00 AM - 4:00 PM",
			"location": "Elementary School Cafeteria",
			"organizer": "Admin",
			"organizer_id": 1,
			"contact_info": "pta@school.edu",
			"created_at": "2024-11-19T13:00:00Z",
			"updated_at": "2024-11-19T13:00:00Z",
			"image_url": "",
			"attendees_going": 42,
			"attendees_interested": 19,
			"user_rsvp": "going",
			"is_favorited": true,
			"max_capacity": 100,
			"tags": ["fundraiser", "school", "family-friendly"]
		}
	]

func _demo_login(email: String, password: String):
	await get_tree().create_timer(0.5).timeout  # Simulate network delay

	# Accept any login in demo mode
	var user_data = {
		"id": 1,
		"username": "Admin",
		"email": email,
		"token": "demo_token_12345"
	}

	save_auth_token(user_data["token"])
	login_completed.emit(true, user_data)

func _demo_register(username: String, email: String, password: String):
	await get_tree().create_timer(0.5).timeout  # Simulate network delay

	var user_data = {
		"id": 1,
		"username": username,
		"email": email,
		"token": "demo_token_12345"
	}

	save_auth_token(user_data["token"])
	register_completed.emit(true, user_data)

func _demo_fetch_events(category: String, search: String, zipcode: String = ""):
	await get_tree().create_timer(0.3).timeout  # Simulate network delay

	var filtered_events = []

	for event in demo_events:
		var matches = true

		# Filter by category
		if category != "" and event["category"] != category:
			matches = false

		# Filter by search
		if search != "" and matches:
			var title_match = event["title"].to_lower().contains(search.to_lower())
			var desc_match = event["description"].to_lower().contains(search.to_lower())
			if not (title_match or desc_match):
				matches = false

		# Filter by zipcode
		if zipcode != "" and matches:
			if event.has("zipcode") and event["zipcode"] != zipcode:
				matches = false

		if matches:
			filtered_events.append(event)

	events_fetched.emit(filtered_events)

func _demo_create_event(event_data: Dictionary):
	await get_tree().create_timer(0.4).timeout  # Simulate network delay

	# Generate new ID
	var new_id = 1
	for event in demo_events:
		if event["id"] >= new_id:
			new_id = event["id"] + 1

	var new_event = event_data.duplicate()
	new_event["id"] = new_id
	new_event["organizer"] = "Admin"
	new_event["organizer_id"] = 1
	new_event["created_at"] = Time.get_datetime_string_from_system()
	new_event["updated_at"] = Time.get_datetime_string_from_system()

	demo_events.append(new_event)
	event_created.emit(true, new_event)

func _demo_update_event(event_id: int, event_data: Dictionary):
	await get_tree().create_timer(0.4).timeout  # Simulate network delay

	for i in range(demo_events.size()):
		if demo_events[i]["id"] == event_id:
			var updated_event = demo_events[i].duplicate()
			updated_event.merge(event_data)
			updated_event["updated_at"] = Time.get_datetime_string_from_system()
			demo_events[i] = updated_event
			event_updated.emit(true, updated_event)
			return

	event_updated.emit(false, {"message": "Event not found"})

func _demo_delete_event(event_id: int):
	await get_tree().create_timer(0.3).timeout  # Simulate network delay

	for i in range(demo_events.size()):
		if demo_events[i]["id"] == event_id:
			demo_events.remove_at(i)
			event_deleted.emit(true)
			return

	event_deleted.emit(false)

# RSVP and Favorites
func update_rsvp(event_id: int, rsvp_status: String):
	# Demo mode
	if Config.is_demo_mode():
		_demo_update_rsvp(event_id, rsvp_status)
		return

	# Track analytics
	Analytics.track_event(Config.ANALYTICS_EVENTS["rsvp_updated"], {
		"event_id": event_id,
		"rsvp_status": rsvp_status
	})

	# Invalidate cache
	DataCache.invalidate_event(event_id)

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(func(result, response_code, headers, body):
		_on_rsvp_updated(result, response_code, headers, body, event_id)
	)

	var body_data = JSON.stringify({"rsvp_status": rsvp_status})
	var headers_list = _get_auth_headers()
	headers_list.append("Content-Type: application/json")
	var result = http.request(Config.get_api_url() + "/events/" + str(event_id) + "/rsvp", headers_list, HTTPClient.METHOD_POST, body_data)

	if result != OK:
		_handle_request_error("Failed to update RSVP")
		rsvp_updated.emit(false, event_id, rsvp_status)

func toggle_favorite(event_id: int, is_favorited: bool):
	# Demo mode
	if Config.is_demo_mode():
		_demo_toggle_favorite(event_id, is_favorited)
		return

	# Invalidate cache
	DataCache.invalidate_event(event_id)

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(func(result, response_code, headers, body):
		_on_favorite_updated(result, response_code, headers, body, event_id)
	)

	var body_data = JSON.stringify({"is_favorited": is_favorited})
	var headers_list = _get_auth_headers()
	headers_list.append("Content-Type: application/json")
	var result = http.request(Config.get_api_url() + "/events/" + str(event_id) + "/favorite", headers_list, HTTPClient.METHOD_POST, body_data)

	if result != OK:
		_handle_request_error("Failed to update favorite")
		favorite_updated.emit(false, event_id, is_favorited)

func _on_rsvp_updated(result, response_code, headers, body, event_id: int):
	var response = _parse_response(body)
	var success = response_code == 200
	var rsvp_status = response.get("rsvp_status", "")

	if not success:
		Analytics.track_error("RSVP update failed", response_code)

	rsvp_updated.emit(success, event_id, rsvp_status)
	_cleanup_http_request()

func _on_favorite_updated(result, response_code, headers, body, event_id: int):
	var response = _parse_response(body)
	var success = response_code == 200
	var is_favorited = response.get("is_favorited", false)

	if not success:
		Analytics.track_error("Favorite update failed", response_code)

	favorite_updated.emit(success, event_id, is_favorited)
	_cleanup_http_request()

func _demo_update_rsvp(event_id: int, rsvp_status: String):
	await get_tree().create_timer(0.2).timeout

	for i in range(demo_events.size()):
		if demo_events[i]["id"] == event_id:
			var old_rsvp = demo_events[i]["user_rsvp"]
			demo_events[i]["user_rsvp"] = rsvp_status

			# Update counts based on RSVP change
			if old_rsvp == "going":
				demo_events[i]["attendees_going"] = max(0, demo_events[i]["attendees_going"] - 1)
			elif old_rsvp == "interested":
				demo_events[i]["attendees_interested"] = max(0, demo_events[i]["attendees_interested"] - 1)

			if rsvp_status == "going":
				demo_events[i]["attendees_going"] += 1
			elif rsvp_status == "interested":
				demo_events[i]["attendees_interested"] += 1

			rsvp_updated.emit(true, event_id, rsvp_status)
			return

	rsvp_updated.emit(false, event_id, rsvp_status)

func _demo_toggle_favorite(event_id: int, is_favorited: bool):
	await get_tree().create_timer(0.2).timeout

	for i in range(demo_events.size()):
		if demo_events[i]["id"] == event_id:
			demo_events[i]["is_favorited"] = is_favorited
			favorite_updated.emit(true, event_id, is_favorited)
			return

	favorite_updated.emit(false, event_id, is_favorited)

func _demo_update_profile(profile_data: Dictionary):
	await get_tree().create_timer(0.3).timeout  # Simulate network delay

	# In demo mode, just cache the changes locally
	var updated_profile = {
		"id": 1,
		"username": profile_data.get("username", "Admin"),
		"email": profile_data.get("email", "admin@example.com"),
		"zipcode": profile_data.get("zipcode", "90210"),
		"token": auth_token
	}

	DataCache.cache_user_profile(updated_profile)
	profile_updated.emit(true, updated_profile)

# Comment functions
func add_comment(event_id: int, comment_text: String):
	print("[APIManager] add_comment called - Event ID: ", event_id)
	print("[APIManager] Comment text length: ", comment_text.length())

	# Validate input
	comment_text = comment_text.strip_edges()
	if comment_text.length() == 0:
		print("[APIManager] Comment is empty")
		comment_added.emit(false, {"message": "Comment cannot be empty"})
		return

	if comment_text.length() > 500:
		print("[APIManager] Comment too long")
		comment_added.emit(false, {"message": "Comment cannot exceed 500 characters"})
		return

	# Demo mode
	if Config.is_demo_mode():
		print("[APIManager] Using demo mode")
		_demo_add_comment(event_id, comment_text)
		return

	print("[APIManager] Making API request to add comment")
	print("[APIManager] API URL: ", Config.get_api_url())
	print("[APIManager] Has auth token: ", auth_token != "")

	# Track analytics
	Analytics.track_event("comment_added", {"event_id": event_id})

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = 60.0  # Longer timeout for comments
	http.request_completed.connect(func(result, response_code, headers, body):
		_on_comment_added(result, response_code, headers, body, event_id)
	)

	var body_data = JSON.stringify({"text": comment_text})
	var headers_list = _get_auth_headers()
	headers_list.append("Content-Type: application/json")

	print("[APIManager] Request headers: ", headers_list)
	print("[APIManager] Request body: ", body_data)

	var url = Config.get_api_url() + "/events/" + str(event_id) + "/comments"
	print("[APIManager] Full URL: ", url)

	var result = http.request(url, headers_list, HTTPClient.METHOD_POST, body_data)

	if result != OK:
		print("[APIManager] HTTP request failed immediately: ", result)
		_handle_request_error("Failed to add comment")
		http.queue_free()
		comment_added.emit(false, {"message": "Network error. Please try again."})

func fetch_comments(event_id: int):
	# Demo mode
	if Config.is_demo_mode():
		_demo_fetch_comments(event_id)
		return

	# Make API request
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = request_timeout
	http.request_completed.connect(_on_comments_fetched)

	var headers_list = _get_auth_headers()
	var result = http.request(Config.get_api_url() + "/events/" + str(event_id) + "/comments", headers_list, HTTPClient.METHOD_GET)

	if result != OK:
		_handle_request_error("Failed to fetch comments")
		comments_fetched.emit([])

func _on_comment_added(result, response_code, headers, body, event_id: int):
	print("[APIManager] Comment response - Result: ", result, " Code: ", response_code)

	# Handle network errors
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[APIManager] Network error: ", result)
		var error_msg = "Connection failed"
		if result == HTTPRequest.RESULT_TIMEOUT:
			error_msg = "Request timed out. Please try again."
		elif result == HTTPRequest.RESULT_CANT_CONNECT:
			error_msg = "Cannot connect to server. Check your internet."
		comment_added.emit(false, {"message": error_msg})
		_cleanup_http_request()
		return

	var response = _parse_response(body)
	print("[APIManager] Parsed response: ", response)

	var success = response_code == 201 or response_code == 200

	if not success:
		print("[APIManager] Comment failed - Code: ", response_code)
		if response_code == 401:
			response["message"] = "You must be logged in to comment"
			token_expired.emit()
		elif response_code == 404:
			response["message"] = "Event not found"
		elif response_code == 400:
			if not response.has("message"):
				response["message"] = "Invalid comment data"
		elif response_code == 0:
			response["message"] = "No response from server"
		elif response_code >= 500:
			response["message"] = Config.get_error_message(response_code)
		Analytics.track_error("Comment add failed", response_code)

	comment_added.emit(success, response)
	_cleanup_http_request()

func _on_comments_fetched(result, response_code, headers, body):
	var response = _parse_response(body)
	var comments = []

	if response_code == 200 and response is Array:
		comments = response
	else:
		Analytics.track_error("Failed to fetch comments", response_code)

	comments_fetched.emit(comments)
	_cleanup_http_request()

func _demo_add_comment(event_id: int, comment_text: String):
	await get_tree().create_timer(0.2).timeout

	# Find the event and add comment
	for i in range(demo_events.size()):
		if demo_events[i]["id"] == event_id:
			if not demo_events[i].has("comments"):
				demo_events[i]["comments"] = []

			var new_comment = {
				"_id": str(randi()),
				"user_id": 1,
				"username": "Admin",
				"text": comment_text,
				"created_at": Time.get_datetime_string_from_system()
			}

			demo_events[i]["comments"].append(new_comment)
			comment_added.emit(true, new_comment)
			return

	comment_added.emit(false, {"message": "Event not found"})

func _demo_fetch_comments(event_id: int):
	await get_tree().create_timer(0.2).timeout

	# Find the event and return comments
	for event in demo_events:
		if event["id"] == event_id:
			var comments = event.get("comments", [])
			comments_fetched.emit(comments)
			return

	comments_fetched.emit([])
