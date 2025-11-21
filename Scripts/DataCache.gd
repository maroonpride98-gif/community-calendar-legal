extends Node

## Data Cache System
## Provides offline capability and improves performance by caching API responses

const CACHE_VERSION = 1

var cache_data: Dictionary = {
	"version": CACHE_VERSION,
	"events": {},
	"event_list": {},
	"user_profile": {},
	"metadata": {}
}

var is_enabled: bool = true

func _ready():
	is_enabled = Config.is_feature_enabled("offline_mode")
	_load_cache()

# Cache event list
func cache_event_list(category: String, search: String, events: Array):
	if not is_enabled:
		return

	var cache_key = _get_list_cache_key(category, search)
	cache_data["event_list"][cache_key] = {
		"data": events,
		"timestamp": Time.get_unix_time_from_system(),
		"ttl": Config.CACHE["event_list_ttl_seconds"]
	}

	_save_cache()

# Get cached event list
func get_cached_event_list(category: String, search: String) -> Array:
	if not is_enabled:
		return []

	var cache_key = _get_list_cache_key(category, search)
	if not cache_data["event_list"].has(cache_key):
		return []

	var cached = cache_data["event_list"][cache_key]
	if _is_cache_expired(cached):
		cache_data["event_list"].erase(cache_key)
		return []

	return cached["data"]

# Cache individual event
func cache_event(event_id: int, event_data: Dictionary):
	if not is_enabled:
		return

	cache_data["events"][str(event_id)] = {
		"data": event_data,
		"timestamp": Time.get_unix_time_from_system(),
		"ttl": Config.CACHE["event_detail_ttl_seconds"]
	}

	_save_cache()

# Get cached event
func get_cached_event(event_id: int) -> Dictionary:
	if not is_enabled:
		return {}

	var cache_key = str(event_id)
	if not cache_data["events"].has(cache_key):
		return {}

	var cached = cache_data["events"][cache_key]
	if _is_cache_expired(cached):
		cache_data["events"].erase(cache_key)
		return {}

	return cached["data"]

# Cache user profile
func cache_user_profile(user_data: Dictionary):
	if not is_enabled:
		return

	cache_data["user_profile"] = {
		"data": user_data,
		"timestamp": Time.get_unix_time_from_system(),
		"ttl": Config.CACHE["user_profile_ttl_seconds"]
	}

	_save_cache()

# Get cached user profile
func get_cached_user_profile() -> Dictionary:
	if not is_enabled:
		return {}

	if not cache_data.has("user_profile"):
		return {}

	if _is_cache_expired(cache_data["user_profile"]):
		cache_data.erase("user_profile")
		return {}

	return cache_data["user_profile"]["data"]

# Invalidate specific event cache
func invalidate_event(event_id: int):
	cache_data["events"].erase(str(event_id))
	_invalidate_all_event_lists()
	_save_cache()

# Invalidate all event list caches
func _invalidate_all_event_lists():
	cache_data["event_list"].clear()

# Invalidate all caches
func clear_all_cache():
	cache_data = {
		"version": CACHE_VERSION,
		"events": {},
		"event_list": {},
		"user_profile": {},
		"metadata": {}
	}
	_save_cache()

# Check if cache entry is expired
func _is_cache_expired(cache_entry: Dictionary) -> bool:
	if not cache_entry.has("timestamp") or not cache_entry.has("ttl"):
		return true

	var current_time = Time.get_unix_time_from_system()
	var age = current_time - cache_entry["timestamp"]
	return age > cache_entry["ttl"]

# Generate cache key for event list
func _get_list_cache_key(category: String, search: String) -> String:
	return "list_" + category + "_" + search

# Save cache to disk
func _save_cache():
	var file = FileAccess.open("user://data_cache.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache_data))
		file.close()

# Load cache from disk
func _load_cache():
	if not FileAccess.file_exists("user://data_cache.json"):
		return

	var file = FileAccess.open("user://data_cache.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()

		if error == OK and json.data is Dictionary:
			var loaded_data = json.data

			# Check cache version
			if loaded_data.get("version", 0) == CACHE_VERSION:
				cache_data = loaded_data
			else:
				# Cache version mismatch, clear old cache
				print("[DataCache] Cache version mismatch, clearing old cache")
				clear_all_cache()

# Get cache statistics
func get_cache_stats() -> Dictionary:
	return {
		"events_cached": cache_data["events"].size(),
		"event_lists_cached": cache_data["event_list"].size(),
		"has_user_profile": cache_data.has("user_profile"),
		"cache_version": cache_data["version"]
	}

# Clean up expired cache entries
func cleanup_expired_cache():
	var cleanup_count = 0

	# Clean up events
	var events_to_remove = []
	for event_id in cache_data["events"].keys():
		if _is_cache_expired(cache_data["events"][event_id]):
			events_to_remove.append(event_id)

	for event_id in events_to_remove:
		cache_data["events"].erase(event_id)
		cleanup_count += 1

	# Clean up event lists
	var lists_to_remove = []
	for list_key in cache_data["event_list"].keys():
		if _is_cache_expired(cache_data["event_list"][list_key]):
			lists_to_remove.append(list_key)

	for list_key in lists_to_remove:
		cache_data["event_list"].erase(list_key)
		cleanup_count += 1

	# Clean up user profile
	if cache_data.has("user_profile") and _is_cache_expired(cache_data["user_profile"]):
		cache_data.erase("user_profile")
		cleanup_count += 1

	if cleanup_count > 0:
		_save_cache()

	return cleanup_count

# Check if device is online
func is_online() -> bool:
	# In a real app, you'd check actual network connectivity
	# For now, return true
	return true
