extends Node

## Analytics System
## Tracks user events for analytics (Google Analytics, Firebase, etc.)
## This is a hook system - integrate with your analytics provider

signal event_tracked(event_name: String, properties: Dictionary)

var event_queue: Array[Dictionary] = []
var session_id: String = ""
var session_start_time: int = 0
var is_enabled: bool = true

func _ready():
	_start_new_session()
	is_enabled = Config.is_feature_enabled("enable_analytics")

func _start_new_session():
	session_id = _generate_session_id()
	session_start_time = Time.get_unix_time_from_system()
	track_event(Config.ANALYTICS_EVENTS["app_opened"], {
		"session_id": session_id,
		"app_version": Config.APP_VERSION,
		"platform": OS.get_name()
	})

func _generate_session_id() -> String:
	var time = Time.get_unix_time_from_system()
	var random = randi()
	return str(time) + "_" + str(random)

# Track an analytics event
func track_event(event_name: String, properties: Dictionary = {}):
	if not is_enabled:
		return

	var event_data = {
		"event_name": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": session_id,
		"properties": properties
	}

	event_queue.append(event_data)
	event_tracked.emit(event_name, properties)

	# In production, you would send this to your analytics service
	if Config.is_feature_enabled("show_debug_info"):
		print("[Analytics] Event: ", event_name, " | Properties: ", properties)

	# Flush queue if it gets too large
	if event_queue.size() > 50:
		_flush_events()

# Track screen view
func track_screen_view(screen_name: String):
	track_event("screen_view", {
		"screen_name": screen_name
	})

# Track user action
func track_user_action(action: String, details: Dictionary = {}):
	track_event("user_action", {
		"action": action,
		"details": details
	})

# Track error
func track_error(error_message: String, error_code: int = 0):
	track_event("error_occurred", {
		"error_message": error_message,
		"error_code": error_code
	})

# Track timing (how long something took)
func track_timing(category: String, variable: String, time_ms: int):
	track_event("timing", {
		"category": category,
		"variable": variable,
		"time_ms": time_ms
	})

# Flush queued events to analytics service
func _flush_events():
	if event_queue.is_empty():
		return

	# TODO: Implement actual sending to analytics service
	# For now, just clear the queue
	if Config.is_feature_enabled("show_debug_info"):
		print("[Analytics] Flushing ", event_queue.size(), " events")

	event_queue.clear()

# Get session duration in seconds
func get_session_duration() -> int:
	return Time.get_unix_time_from_system() - session_start_time

# Set user properties (for user-level tracking)
func set_user_property(property_name: String, value):
	if not is_enabled:
		return

	# TODO: Implement user property tracking
	if Config.is_feature_enabled("show_debug_info"):
		print("[Analytics] User Property: ", property_name, " = ", value)

# Identify user (when they log in)
func identify_user(user_id, properties: Dictionary = {}):
	if not is_enabled:
		return

	track_event("user_identified", {
		"user_id": str(user_id),
		"properties": properties
	})
