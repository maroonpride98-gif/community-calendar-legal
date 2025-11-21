extends Node

## Production Configuration System
## Manages all app configuration including API URLs, feature flags, and constants

# App Information
const APP_NAME = "EventHive"
const APP_VERSION = "2.0.0"
const APP_BUILD = 6
const MINIMUM_API_VERSION = "1.0"

# Environment Configuration
enum AppEnvironment {
	DEVELOPMENT,
	STAGING,
	PRODUCTION,
	DEMO
}

# Set this to match your deployment environment
var current_environment: AppEnvironment = AppEnvironment.PRODUCTION

# API Configuration - Set these before deploying!
const API_URLS = {
	AppEnvironment.DEVELOPMENT: "http://localhost:3000/api",
	AppEnvironment.STAGING: "https://staging-api.yourcommunity.com/api",
	AppEnvironment.PRODUCTION: "https://community-calendar-backend-1.onrender.com/api",
	AppEnvironment.DEMO: "demo"  # Uses local demo mode
}

# Feature Flags - Enable/disable features
const FEATURE_FLAGS = {
	"allow_image_uploads": false,  # Set to true when backend supports it
	"enable_notifications": false,  # Set to true when push notifications are ready
	"enable_social_sharing": true,
	"enable_analytics": true,
	"offline_mode": true,
	"show_debug_info": false,  # Set to true for debugging
	"require_email_verification": false,  # Set to true for production
	"enable_event_comments": false,  # Future feature
	"enable_recurring_events": false,  # Future feature
}

# Security Settings
const SECURITY = {
	"min_password_length": 6,
	"max_password_length": 128,
	"password_require_uppercase": false,
	"password_require_number": false,
	"password_require_special": false,
	"max_login_attempts": 5,
	"lockout_duration_seconds": 300,  # 5 minutes
	"session_timeout_hours": 24,
	"token_refresh_hours": 12,
}

# Validation Rules
const VALIDATION = {
	"min_event_title_length": 3,
	"max_event_title_length": 100,
	"max_event_description_length": 2000,
	"max_location_length": 200,
	"max_contact_info_length": 100,
	"max_username_length": 30,
	"min_username_length": 3,
	"max_tags_per_event": 10,
}

# Rate Limiting (client-side)
const RATE_LIMITS = {
	"search_debounce_ms": 500,
	"api_request_cooldown_ms": 100,
	"max_events_create_per_hour": 10,
	"max_events_update_per_hour": 20,
}

# Cache Settings
const CACHE = {
	"event_list_ttl_seconds": 300,  # 5 minutes
	"event_detail_ttl_seconds": 600,  # 10 minutes
	"user_profile_ttl_seconds": 3600,  # 1 hour
	"max_cache_size_mb": 50,
}

# UI Settings
const UI = {
	"items_per_page": 20,
	"max_recent_searches": 10,
	"animation_duration_ms": 200,
	"toast_duration_ms": 3000,
	"enable_haptic_feedback": true,
}

# Analytics Events (for tracking)
const ANALYTICS_EVENTS = {
	"app_opened": "app_opened",
	"user_registered": "user_registered",
	"user_logged_in": "user_logged_in",
	"event_created": "event_created",
	"event_viewed": "event_viewed",
	"event_edited": "event_edited",
	"event_deleted": "event_deleted",
	"event_shared": "event_shared",
	"rsvp_updated": "rsvp_updated",
	"search_performed": "search_performed",
	"filter_applied": "filter_applied",
}

# Privacy & Legal
const PRIVACY_POLICY_URL = "https://maroonpride98-gif.github.io/community-calendar-legal/privacy_policy.html"
const TERMS_OF_SERVICE_URL = "https://maroonpride98-gif.github.io/community-calendar-legal/terms_of_service.html"
const SUPPORT_EMAIL = "okkiegaming@gmail.com"
const FEEDBACK_URL = "https://maroonpride98-gif.github.io/community-calendar-legal/privacy_policy.html"

# Get current API URL based on environment
func get_api_url() -> String:
	return API_URLS[current_environment]

# Check if in demo mode
func is_demo_mode() -> bool:
	return current_environment == AppEnvironment.DEMO

# Check if feature is enabled
func is_feature_enabled(feature_name: String) -> bool:
	return FEATURE_FLAGS.get(feature_name, false)

# Get app version string
func get_version_string() -> String:
	return "v" + APP_VERSION + " (Build " + str(APP_BUILD) + ")"

# Get environment name
func get_environment_name() -> String:
	match current_environment:
		AppEnvironment.DEVELOPMENT:
			return "Development"
		AppEnvironment.STAGING:
			return "Staging"
		AppEnvironment.PRODUCTION:
			return "Production"
		AppEnvironment.DEMO:
			return "Demo"
		_:
			return "Unknown"

# Validate email format
func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

# Validate US zip code (5 digits, 00501-99950)
func is_valid_us_zipcode(zipcode: String) -> bool:
	# US zip codes are 5 digits
	if zipcode.length() != 5:
		return false

	# Must be all digits
	if not zipcode.is_valid_int():
		return false

	var zip_int = zipcode.to_int()
	# Valid US zip code range: 00501 (lowest) to 99950 (highest)
	return zip_int >= 501 and zip_int <= 99950

# Legacy function for backward compatibility (redirects to US validation)
func is_valid_oklahoma_zipcode(zipcode: String) -> bool:
	return is_valid_us_zipcode(zipcode)

# Validate password strength
func validate_password(password: String) -> Dictionary:
	var result = {
		"valid": true,
		"errors": []
	}

	if password.length() < SECURITY["min_password_length"]:
		result["valid"] = false
		result["errors"].append("Password must be at least " + str(SECURITY["min_password_length"]) + " characters")

	if password.length() > SECURITY["max_password_length"]:
		result["valid"] = false
		result["errors"].append("Password is too long")

	if SECURITY["password_require_uppercase"]:
		var has_uppercase = false
		for i in range(password.length()):
			var c = password[i]
			if c >= 'A' and c <= 'Z':
				has_uppercase = true
				break
		if not has_uppercase:
			result["valid"] = false
			result["errors"].append("Password must contain at least one uppercase letter")

	if SECURITY["password_require_number"]:
		var has_number = false
		for i in range(password.length()):
			var c = password[i]
			if c >= '0' and c <= '9':
				has_number = true
				break
		if not has_number:
			result["valid"] = false
			result["errors"].append("Password must contain at least one number")

	if SECURITY["password_require_special"]:
		var special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
		var has_special = false
		for i in range(password.length()):
			if special_chars.contains(password[i]):
				has_special = true
				break
		if not has_special:
			result["valid"] = false
			result["errors"].append("Password must contain at least one special character")

	return result

# Sanitize user input to prevent XSS
func sanitize_input(input: String) -> String:
	var sanitized = input.strip_edges()
	# Remove any potential HTML/script tags
	sanitized = sanitized.replace("<", "&lt;")
	sanitized = sanitized.replace(">", "&gt;")
	sanitized = sanitized.replace("\"", "&quot;")
	sanitized = sanitized.replace("'", "&#39;")
	return sanitized

# Validate date format and range
func is_valid_date(date_str: String) -> bool:
	var parts = date_str.split("-")
	if parts.size() != 3:
		return false

	var year = parts[0].to_int()
	var month = parts[1].to_int()
	var day = parts[2].to_int()

	var current_year = Time.get_datetime_dict_from_system()["year"]

	if year < current_year or year > current_year + 10:
		return false
	if month < 1 or month > 12:
		return false
	if day < 1 or day > 31:
		return false

	# Check days in month
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

	# Check for leap year
	if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
		days_in_month[1] = 29

	if day > days_in_month[month - 1]:
		return false

	return true

# Log analytics event (placeholder for future analytics integration)
func log_analytics_event(event_name: String, properties: Dictionary = {}):
	if not is_feature_enabled("enable_analytics"):
		return

	# Add to analytics queue
	Analytics.track_event(event_name, properties)

# Get user-friendly error message
func get_error_message(error_code: int) -> String:
	match error_code:
		400:
			return "Invalid request. Please check your input."
		401:
			return "Authentication failed. Please log in again."
		403:
			return "You don't have permission to perform this action."
		404:
			return "The requested item was not found."
		409:
			return "This item already exists."
		422:
			return "Validation failed. Please check your input."
		429:
			return "Too many requests. Please try again later."
		500:
			return "Server error. Please try again later."
		503:
			return "Service temporarily unavailable. Please try again later."
		_:
			return "An unexpected error occurred. Please try again."

# Save configuration changes (for future settings screen)
func save_preferences(prefs: Dictionary):
	var file = FileAccess.open("user://preferences.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(prefs))
		file.close()

# Load saved preferences
func load_preferences() -> Dictionary:
	if FileAccess.file_exists("user://preferences.json"):
		var file = FileAccess.open("user://preferences.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			file.close()
			if error == OK and json.data is Dictionary:
				return json.data
	return {}
