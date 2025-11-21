extends RefCounted
class_name Event

var id: int = 0
var title: String = ""
var description: String = ""
var category: String = "general"  # general, garage_sale, sports, church, town_meeting
var date: String = ""  # ISO format date
var time: String = ""
var location: String = ""
var organizer: String = ""
var organizer_id: int = 0
var contact_info: String = ""
var created_at: String = ""
var updated_at: String = ""

# New features
var image_url: String = ""
var attendees_going: int = 0
var attendees_interested: int = 0
var user_rsvp: String = ""  # "going", "interested", "not_going", ""
var is_favorited: bool = false
var max_capacity: int = 0  # 0 = unlimited
var tags: Array = []  # Additional tags beyond category

# Category display names
const CATEGORIES = {
	"general": "General Event",
	"garage_sale": "Garage Sale",
	"sports": "Sports Game",
	"church": "Church Gathering",
	"town_meeting": "Town Meeting",
	"community": "Community Event",
	"fundraiser": "Fundraiser",
	"workshop": "Workshop",
	"festival": "Festival"
}

static func from_dict(data: Dictionary) -> Event:
	var event = Event.new()
	event.id = data.get("id", 0)
	event.title = data.get("title", "")
	event.description = data.get("description", "")
	event.category = data.get("category", "general")
	event.date = data.get("date", "")
	event.time = data.get("time", "")
	event.location = data.get("location", "")
	event.organizer = data.get("organizer", "")
	event.organizer_id = data.get("organizer_id", 0)
	event.contact_info = data.get("contact_info", "")
	event.created_at = data.get("created_at", "")
	event.updated_at = data.get("updated_at", "")

	# New fields
	event.image_url = data.get("image_url", "")
	event.attendees_going = data.get("attendees_going", 0)
	event.attendees_interested = data.get("attendees_interested", 0)
	event.user_rsvp = data.get("user_rsvp", "")
	event.is_favorited = data.get("is_favorited", false)
	event.max_capacity = data.get("max_capacity", 0)
	event.tags = data.get("tags", [])
	return event

func to_dict() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"category": category,
		"date": date,
		"time": time,
		"location": location,
		"contact_info": contact_info,
		"image_url": image_url,
		"max_capacity": max_capacity,
		"tags": tags
	}

func get_category_display() -> String:
	return CATEGORIES.get(category, "General Event")

func get_formatted_date() -> String:
	# Parse ISO date and format it nicely
	if date == "":
		return "No date set"

	# Simple formatting - you can enhance this
	var parts = date.split("-")
	if parts.size() == 3:
		var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		var month_idx = int(parts[1]) - 1
		if month_idx >= 0 and month_idx < 12:
			return months[month_idx] + " " + parts[2] + ", " + parts[0]

	return date

func get_formatted_datetime() -> String:
	var date_str = get_formatted_date()
	if time != "":
		return date_str + " at " + time
	return date_str

# NEW COOL FEATURES

func get_event_status() -> String:
	var now = Time.get_datetime_dict_from_system()
	var event_date = _parse_date(date)

	if event_date.is_empty():
		return "UNKNOWN"

	# Compare dates
	var now_days = now["year"] * 365 + now["month"] * 30 + now["day"]
	var event_days = event_date["year"] * 365 + event_date["month"] * 30 + event_date["day"]

	if event_days < now_days:
		return "PAST"
	elif event_days == now_days:
		return "LIVE"
	else:
		return "UPCOMING"

func get_countdown() -> String:
	var now = Time.get_datetime_dict_from_system()
	var event_date = _parse_date(date)

	if event_date.is_empty():
		return "Date unavailable"

	var now_days = now["year"] * 365 + now["month"] * 30 + now["day"]
	var event_days = event_date["year"] * 365 + event_date["month"] * 30 + event_date["day"]

	var days_diff = event_days - now_days

	if days_diff < 0:
		return "EVENT ENDED"
	elif days_diff == 0:
		return "HAPPENING NOW"
	elif days_diff == 1:
		return "TOMORROW"
	elif days_diff < 7:
		return str(days_diff) + " DAYS"
	elif days_diff < 30:
		var weeks = int(days_diff / 7.0)
		return str(weeks) + " WEEKS"
	else:
		var months = int(days_diff / 30.0)
		return str(months) + " MONTHS"

func get_capacity_status() -> String:
	if max_capacity == 0:
		return "UNLIMITED"
	var total_attendees = attendees_going
	var percentage = (float(total_attendees) / float(max_capacity)) * 100.0

	if total_attendees >= max_capacity:
		return "FULL"
	elif percentage > 80:
		return "FILLING FAST"
	else:
		return str(max_capacity - total_attendees) + " SPOTS LEFT"

func get_attendee_count_text() -> String:
	var going = attendees_going
	var interested = attendees_interested
	var total = going + interested

	if total == 0:
		return "NO ATTENDEES YET"
	elif going > 0 and interested > 0:
		return str(going) + " GOING • " + str(interested) + " INTERESTED"
	elif going > 0:
		return str(going) + " GOING"
	else:
		return str(interested) + " INTERESTED"

func is_past_event() -> bool:
	return get_event_status() == "PAST"

func is_full() -> bool:
	return max_capacity > 0 and attendees_going >= max_capacity

func _parse_date(date_str: String) -> Dictionary:
	var parts = date_str.split("-")
	if parts.size() != 3:
		return {}

	return {
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2])
	}
