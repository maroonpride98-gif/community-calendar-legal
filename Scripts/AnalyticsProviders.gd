extends Node

## Analytics Providers Integration
## Ready-to-use integrations for popular analytics services

# Firebase Analytics Configuration
const FIREBASE_API_KEY = ""  # Add your Firebase API key
const FIREBASE_PROJECT_ID = ""  # Add your Firebase project ID
const FIREBASE_APP_ID = ""  # Add your Firebase app ID
const FIREBASE_ENABLED = false  # Set to true when configured

# Google Analytics 4 Configuration
const GA4_MEASUREMENT_ID = ""  # Add your GA4 Measurement ID (G-XXXXXXXXXX)
const GA4_API_SECRET = ""  # Add your GA4 API secret
const GA4_ENABLED = false  # Set to true when configured

# Mixpanel Configuration
const MIXPANEL_TOKEN = ""  # Add your Mixpanel token
const MIXPANEL_ENABLED = false  # Set to true when configured

## Initialize analytics providers
func _ready():
	Analytics.event_tracked.connect(_on_event_tracked)

	if Config.is_feature_enabled("show_debug_info"):
		print("[AnalyticsProviders] Initialized")
		print("  Firebase: ", "Enabled" if FIREBASE_ENABLED else "Disabled")
		print("  GA4: ", "Enabled" if GA4_ENABLED else "Disabled")
		print("  Mixpanel: ", "Enabled" if MIXPANEL_ENABLED else "Disabled")

## Handle analytics events from Analytics.gd
func _on_event_tracked(event_name: String, properties: Dictionary):
	if FIREBASE_ENABLED:
		_send_to_firebase(event_name, properties)

	if GA4_ENABLED:
		_send_to_ga4(event_name, properties)

	if MIXPANEL_ENABLED:
		_send_to_mixpanel(event_name, properties)

## ============================================
## FIREBASE ANALYTICS INTEGRATION
## ============================================

func _send_to_firebase(event_name: String, properties: Dictionary):
	if not FIREBASE_ENABLED or FIREBASE_API_KEY == "":
		return

	# Firebase Analytics REST API
	# https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages/send

	var http = HTTPRequest.new()
	get_tree().root.add_child(http)

	# Firebase event format
	var event_data = {
		"app_instance_id": _get_or_create_instance_id(),
		"events": [{
			"name": _sanitize_event_name(event_name),
			"params": _convert_properties_to_firebase(properties),
			"timestamp_micros": Time.get_unix_time_from_system() * 1000000
		}]
	}

	var url = "https://www.google-analytics.com/mp/collect?firebase_app_id=" + FIREBASE_APP_ID + "&api_secret=" + FIREBASE_API_KEY
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(event_data)

	var result = http.request(url, headers, HTTPClient.METHOD_POST, body)

	if result != OK and Config.is_feature_enabled("show_debug_info"):
		print("[Firebase] Failed to send event: ", result)

	await get_tree().create_timer(5.0).timeout
	if http and is_instance_valid(http):
		http.queue_free()

func _convert_properties_to_firebase(properties: Dictionary) -> Dictionary:
	var firebase_params = {}

	for key in properties.keys():
		var value = properties[key]
		var sanitized_key = key.replace(" ", "_").to_lower()

		# Firebase parameter value types: string, int, float
		if value is String:
			firebase_params[sanitized_key] = {"string_value": value}
		elif value is int:
			firebase_params[sanitized_key] = {"int_value": value}
		elif value is float:
			firebase_params[sanitized_key] = {"double_value": value}
		elif value is bool:
			firebase_params[sanitized_key] = {"int_value": 1 if value else 0}

	return firebase_params

## ============================================
## GOOGLE ANALYTICS 4 INTEGRATION
## ============================================

func _send_to_ga4(event_name: String, properties: Dictionary):
	if not GA4_ENABLED or GA4_MEASUREMENT_ID == "" or GA4_API_SECRET == "":
		return

	var http = HTTPRequest.new()
	get_tree().root.add_child(http)

	# GA4 Measurement Protocol
	# https://developers.google.com/analytics/devguides/collection/protocol/ga4

	var client_id = _get_or_create_instance_id()

	var event_data = {
		"client_id": client_id,
		"user_id": str(device_info.get("user_id", "")),
		"events": [{
			"name": _sanitize_event_name(event_name),
			"params": properties
		}],
		"user_properties": {
			"app_version": {"value": Config.APP_VERSION},
			"platform": {"value": OS.get_name()}
		}
	}

	var url = "https://www.google-analytics.com/mp/collect?measurement_id=" + GA4_MEASUREMENT_ID + "&api_secret=" + GA4_API_SECRET
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(event_data)

	var result = http.request(url, headers, HTTPClient.METHOD_POST, body)

	if result != OK and Config.is_feature_enabled("show_debug_info"):
		print("[GA4] Failed to send event: ", result)

	await get_tree().create_timer(5.0).timeout
	if http and is_instance_valid(http):
		http.queue_free()

## ============================================
## MIXPANEL INTEGRATION
## ============================================

func _send_to_mixpanel(event_name: String, properties: Dictionary):
	if not MIXPANEL_ENABLED or MIXPANEL_TOKEN == "":
		return

	var http = HTTPRequest.new()
	get_tree().root.add_child(http)

	# Mixpanel HTTP API
	# https://developer.mixpanel.com/docs/http

	var distinct_id = _get_or_create_instance_id()
	if device_info.has("user_id"):
		distinct_id = str(device_info["user_id"])

	var event_data = {
		"event": event_name,
		"properties": properties.duplicate()
	}

	# Add default properties
	event_data["properties"]["token"] = MIXPANEL_TOKEN
	event_data["properties"]["distinct_id"] = distinct_id
	event_data["properties"]["time"] = Time.get_unix_time_from_system()
	event_data["properties"]["$app_version"] = Config.APP_VERSION
	event_data["properties"]["$os"] = OS.get_name()

	# Base64 encode the event data
	var json_string = JSON.stringify([event_data])
	var encoded = Marshalls.utf8_to_base64(json_string)

	var url = "https://api.mixpanel.com/track?data=" + encoded
	var result = http.request(url, [], HTTPClient.METHOD_GET)

	if result != OK and Config.is_feature_enabled("show_debug_info"):
		print("[Mixpanel] Failed to send event: ", result)

	await get_tree().create_timer(5.0).timeout
	if http and is_instance_valid(http):
		http.queue_free()

## ============================================
## HELPER FUNCTIONS
## ============================================

var device_info: Dictionary = {}

# Get or create unique instance ID
func _get_or_create_instance_id() -> String:
	var instance_id_file = "user://instance_id.txt"

	if FileAccess.file_exists(instance_id_file):
		var file = FileAccess.open(instance_id_file, FileAccess.READ)
		var id = file.get_as_text()
		file.close()
		return id

	# Generate new instance ID
	var new_id = _generate_uuid()
	var file = FileAccess.open(instance_id_file, FileAccess.WRITE)
	file.store_string(new_id)
	file.close()
	return new_id

# Generate UUID
func _generate_uuid() -> String:
	var uuid = ""
	for i in range(32):
		uuid += "0123456789abcdef"[randi() % 16]
	return uuid.substr(0, 8) + "-" + uuid.substr(8, 4) + "-4" + uuid.substr(12, 3) + "-" + uuid.substr(15, 4) + "-" + uuid.substr(19)

# Sanitize event name (Firebase/GA4 requirements)
func _sanitize_event_name(event_name: String) -> String:
	# Event names must start with letter, can contain letters, numbers, underscores
	# Max 40 characters
	var sanitized = event_name.replace(" ", "_").replace("-", "_").to_lower()
	sanitized = sanitized.substr(0, 40)
	return sanitized

## ============================================
## ECOMMERCE TRACKING (Optional)
## ============================================

# Track purchase (if you add paid events)
func track_purchase(event_id: int, event_title: String, amount: float, currency: String = "USD"):
	var properties = {
		"event_id": event_id,
		"event_title": event_title,
		"revenue": amount,
		"currency": currency
	}

	Analytics.track_event("purchase", properties)

# Track add to cart
func track_add_to_cart(event_id: int, event_title: String):
	Analytics.track_event("add_to_cart", {
		"event_id": event_id,
		"event_title": event_title
	})

## ============================================
## USER PROPERTIES
## ============================================

# Set user properties (call after login)
func set_user_properties(user_id: int, properties: Dictionary = {}):
	device_info["user_id"] = user_id

	# Send to GA4
	if GA4_ENABLED:
		_set_ga4_user_properties(properties)

	# Send to Mixpanel
	if MIXPANEL_ENABLED:
		_set_mixpanel_user_properties(user_id, properties)

func _set_ga4_user_properties(properties: Dictionary):
	var http = HTTPRequest.new()
	get_tree().root.add_child(http)

	var user_props = {}
	for key in properties.keys():
		user_props[key] = {"value": properties[key]}

	var data = {
		"client_id": _get_or_create_instance_id(),
		"user_properties": user_props
	}

	var url = "https://www.google-analytics.com/mp/collect?measurement_id=" + GA4_MEASUREMENT_ID + "&api_secret=" + GA4_API_SECRET
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(data)

	http.request(url, headers, HTTPClient.METHOD_POST, body)

	await get_tree().create_timer(5.0).timeout
	if http and is_instance_valid(http):
		http.queue_free()

func _set_mixpanel_user_properties(user_id: int, properties: Dictionary):
	var http = HTTPRequest.new()
	get_tree().root.add_child(http)

	var data = {
		"$token": MIXPANEL_TOKEN,
		"$distinct_id": str(user_id),
		"$set": properties
	}

	var json_string = JSON.stringify([data])
	var encoded = Marshalls.utf8_to_base64(json_string)

	var url = "https://api.mixpanel.com/engage?data=" + encoded
	http.request(url, [], HTTPClient.METHOD_GET)

	await get_tree().create_timer(5.0).timeout
	if http and is_instance_valid(http):
		http.queue_free()
