extends Node

## Production Error Tracking System
## Integrates with Sentry, Bugsnag, or custom error tracking services

signal error_captured(error_data: Dictionary)

# Sentry Configuration
const SENTRY_DSN = ""  # Add your Sentry DSN here: https://sentry.io
const SENTRY_ENABLED = false  # Set to true when you have a DSN

# Error tracking settings
var errors_queue: Array[Dictionary] = []
var max_queue_size = 50
var last_error_time = 0
var error_cooldown_ms = 1000  # Don't send same error more than once per second

# Environment info
var app_version: String = ""
var device_info: Dictionary = {}

func _ready():
	app_version = Config.get_version_string()
	_collect_device_info()

	# Connect to unhandled errors
	get_tree().get_root().connect("tree_exiting", _flush_errors)

	if Config.is_feature_enabled("show_debug_info"):
		print("[ErrorTracker] Initialized - Sentry: ", "Enabled" if SENTRY_ENABLED else "Disabled")

func _collect_device_info():
	device_info = {
		"os": OS.get_name(),
		"os_version": OS.get_version(),
		"device_model": OS.get_model_name(),
		"locale": OS.get_locale(),
		"screen_size": DisplayServer.screen_get_size(),
		"processor_count": OS.get_processor_count(),
	}

## Capture an error/exception
func capture_error(error_message: String, context: Dictionary = {}):
	var current_time = Time.get_ticks_msec()

	# Prevent error spam
	if current_time - last_error_time < error_cooldown_ms:
		return

	last_error_time = current_time

	var error_data = {
		"message": error_message,
		"timestamp": Time.get_datetime_string_from_system(),
		"level": "error",
		"context": context,
		"app_version": app_version,
		"environment": Config.get_environment_name(),
		"device": device_info,
		"stack_trace": _get_stack_trace()
	}

	errors_queue.append(error_data)
	error_captured.emit(error_data)

	# Log to console
	print("[ERROR] ", error_message)
	if not context.is_empty():
		print("  Context: ", context)

	# Send to error tracking service
	if SENTRY_ENABLED:
		_send_to_sentry(error_data)

	# Flush if queue is too large
	if errors_queue.size() >= max_queue_size:
		_flush_errors()

## Capture a warning (non-critical)
func capture_warning(warning_message: String, context: Dictionary = {}):
	var warning_data = {
		"message": warning_message,
		"timestamp": Time.get_datetime_string_from_system(),
		"level": "warning",
		"context": context,
		"app_version": app_version,
		"environment": Config.get_environment_name(),
	}

	if Config.is_feature_enabled("show_debug_info"):
		print("[WARNING] ", warning_message)

	if SENTRY_ENABLED:
		_send_to_sentry(warning_data)

## Capture an info event
func capture_info(info_message: String, context: Dictionary = {}):
	if Config.is_feature_enabled("show_debug_info"):
		print("[INFO] ", info_message)

	var info_data = {
		"message": info_message,
		"timestamp": Time.get_datetime_string_from_system(),
		"level": "info",
		"context": context,
	}

	if SENTRY_ENABLED:
		_send_to_sentry(info_data)

## Capture HTTP request error
func capture_http_error(url: String, status_code: int, response: String = ""):
	capture_error("HTTP Request Failed", {
		"url": url,
		"status_code": status_code,
		"response": response.substr(0, 500)  # Limit response size
	})

## Capture API error
func capture_api_error(endpoint: String, error_message: String, status_code: int = 0):
	capture_error("API Error: " + endpoint, {
		"endpoint": endpoint,
		"message": error_message,
		"status_code": status_code
	})

## Set user context (after login)
func set_user_context(user_id: int, email: String = "", username: String = ""):
	device_info["user_id"] = user_id
	device_info["user_email"] = email
	device_info["user_username"] = username

	if SENTRY_ENABLED:
		# In a real Sentry integration, you'd call:
		# Sentry.setUser({"id": user_id, "email": email, "username": username})
		pass

## Clear user context (after logout)
func clear_user_context():
	device_info.erase("user_id")
	device_info.erase("user_email")
	device_info.erase("user_username")

## Add breadcrumb (trail of events leading to error)
var breadcrumbs: Array[Dictionary] = []
const MAX_BREADCRUMBS = 50

func add_breadcrumb(message: String, category: String = "default", data: Dictionary = {}):
	breadcrumbs.append({
		"message": message,
		"category": category,
		"data": data,
		"timestamp": Time.get_datetime_string_from_system()
	})

	# Keep only last N breadcrumbs
	if breadcrumbs.size() > MAX_BREADCRUMBS:
		breadcrumbs.pop_front()

## Get stack trace (limited in GDScript)
func _get_stack_trace() -> Array:
	var stack = []
	var trace = get_stack()

	for frame in trace:
		stack.append({
			"function": frame.get("function", "unknown"),
			"source": frame.get("source", "unknown"),
			"line": frame.get("line", 0)
		})

	return stack

## Send error to Sentry
func _send_to_sentry(error_data: Dictionary):
	if not SENTRY_ENABLED or SENTRY_DSN == "":
		return

	var http = HTTPRequest.new()
	get_tree().root.add_child(http)

	# Sentry event format
	var sentry_event = {
		"event_id": _generate_event_id(),
		"timestamp": Time.get_unix_time_from_system(),
		"platform": "gdscript",
		"level": error_data.get("level", "error"),
		"message": error_data.get("message", "Unknown error"),
		"release": app_version,
		"environment": Config.get_environment_name().to_lower(),
		"user": {
			"id": device_info.get("user_id", ""),
			"email": device_info.get("user_email", ""),
			"username": device_info.get("user_username", "")
		},
		"contexts": {
			"device": device_info,
			"app": {
				"app_version": app_version,
				"build_number": Config.APP_BUILD
			}
		},
		"breadcrumbs": breadcrumbs.slice(-10),  # Last 10 breadcrumbs
		"extra": error_data.get("context", {})
	}

	# Add stack trace if available
	if error_data.has("stack_trace"):
		sentry_event["exception"] = {
			"values": [{
				"type": "Error",
				"value": error_data["message"],
				"stacktrace": {
					"frames": error_data["stack_trace"]
				}
			}]
		}

	# Extract project ID and key from DSN
	# DSN format: https://[key]@[host]/[project_id]
	var dsn_parts = SENTRY_DSN.replace("https://", "").split("@")
	if dsn_parts.size() != 2:
		print("[ErrorTracker] Invalid Sentry DSN format")
		return

	var key = dsn_parts[0]
	var host_project = dsn_parts[1].split("/")
	if host_project.size() < 2:
		print("[ErrorTracker] Invalid Sentry DSN format")
		return

	var host = host_project[0]
	var project_id = host_project[1]

	var sentry_url = "https://" + host + "/api/" + project_id + "/store/"
	var headers = [
		"Content-Type: application/json",
		"X-Sentry-Auth: Sentry sentry_version=7, sentry_key=" + key + ", sentry_client=godot/1.0"
	]

	var body = JSON.stringify(sentry_event)
	var result = http.request(sentry_url, headers, HTTPClient.METHOD_POST, body)

	if result != OK:
		print("[ErrorTracker] Failed to send error to Sentry: ", result)

	# Clean up HTTP node
	await get_tree().create_timer(5.0).timeout
	if http and is_instance_valid(http):
		http.queue_free()

## Generate unique event ID
func _generate_event_id() -> String:
	var uuid = ""
	for i in range(32):
		uuid += "0123456789abcdef"[randi() % 16]
	return uuid.substr(0, 8) + "-" + uuid.substr(8, 4) + "-" + uuid.substr(12, 4) + "-" + uuid.substr(16, 4) + "-" + uuid.substr(20)

## Flush queued errors
func _flush_errors():
	if errors_queue.is_empty():
		return

	# Save errors to file for later sending
	var file = FileAccess.open("user://error_log.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(errors_queue))
		file.close()

	errors_queue.clear()

## Load and send previously saved errors
func send_saved_errors():
	if not FileAccess.file_exists("user://error_log.json"):
		return

	var file = FileAccess.open("user://error_log.json", FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error == OK and json.data is Array:
		for error_data in json.data:
			if SENTRY_ENABLED:
				_send_to_sentry(error_data)

		# Clear the file after sending
		DirAccess.remove_absolute("user://error_log.json")

## Alternative: Bugsnag Integration
## To use Bugsnag instead of Sentry, implement this function:
func _send_to_bugsnag(error_data: Dictionary):
	# Bugsnag API endpoint: https://notify.bugsnag.com
	# Requires API key from https://app.bugsnag.com/settings/[project]/api-access
	pass

## Alternative: Custom Error Tracking Service
func _send_to_custom_service(error_data: Dictionary):
	# Implement your own error tracking endpoint
	var http = HTTPRequest.new()
	get_tree().root.add_child(http)

	var url = "https://your-error-tracking-service.com/api/errors"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer YOUR_API_KEY"
	]

	var body = JSON.stringify(error_data)
	http.request(url, headers, HTTPClient.METHOD_POST, body)

	await get_tree().create_timer(5.0).timeout
	if http and is_instance_valid(http):
		http.queue_free()
