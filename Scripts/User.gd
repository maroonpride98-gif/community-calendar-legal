extends RefCounted
class_name User

var id: int = 0
var username: String = ""
var email: String = ""
var created_at: String = ""

static func from_dict(data: Dictionary) -> User:
	var user = User.new()
	user.id = data.get("id", 0)
	user.username = data.get("username", "")
	user.email = data.get("email", "")
	user.created_at = data.get("created_at", "")
	return user

func to_dict() -> Dictionary:
	return {
		"id": id,
		"username": username,
		"email": email
	}
