extends Control

## Profile Settings Screen with Theme Customization

signal back_clicked()
signal profile_updated(user_data: Dictionary)

@onready var api = get_tree().root.get_node("Main/APIManager")
@onready var profile_picture = $Panel/VBox/ProfileSection/ProfilePicture
@onready var username_label = $Panel/VBox/ProfileSection/UsernameLabel
@onready var email_label = $Panel/VBox/ProfileSection/EmailLabel
@onready var upload_photo_button = $Panel/VBox/ProfileSection/UploadPhotoButton
@onready var username_input = $Panel/VBox/SettingsSection/UsernameRow/UsernameInput
@onready var email_input = $Panel/VBox/SettingsSection/EmailRow/EmailInput
@onready var zipcode_input = $Panel/VBox/SettingsSection/ZipCodeRow/ZipCodeInput
@onready var save_button = $Panel/VBox/ButtonRow/SaveButton
@onready var back_button = $Panel/VBox/ButtonRow/BackButton
@onready var status_label = $Panel/VBox/StatusLabel

# Theme customization
@onready var theme_section = $Panel/VBox/ThemeSection
@onready var primary_color_picker = $Panel/VBox/ThemeSection/PrimaryColorRow/ColorPicker
@onready var secondary_color_picker = $Panel/VBox/ThemeSection/SecondaryColorRow/ColorPicker
@onready var reset_theme_button = $Panel/VBox/ThemeSection/ResetThemeButton

var current_user_data = {}
var profile_picture_path = ""

# Default theme colors
const DEFAULT_PRIMARY_COLOR = Color(1.0, 0.84, 0.35, 1.0)  # Gold
const DEFAULT_SECONDARY_COLOR = Color(0.05, 0.05, 0.12, 1.0)  # Dark/Black

func _ready():
	# Connect signals
	upload_photo_button.pressed.connect(_on_upload_photo_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	reset_theme_button.pressed.connect(_on_reset_theme_pressed)
	primary_color_picker.color_changed.connect(_on_primary_color_changed)
	secondary_color_picker.color_changed.connect(_on_secondary_color_changed)

	# Connect API signals
	api.profile_updated.connect(_on_profile_update_completed)

	# Load user data
	_load_user_data()

	# Load theme preferences
	_load_theme_preferences()

func _load_user_data():
	var cached_user = DataCache.get_cached_user_profile()
	if cached_user:
		set_user_data(cached_user)

func set_user_data(user_data: Dictionary):
	current_user_data = user_data

	if user_data.has("username"):
		username_label.text = user_data["username"]
		username_input.text = user_data["username"]

	if user_data.has("email"):
		email_label.text = user_data["email"]
		email_input.text = user_data["email"]

	if user_data.has("zipcode"):
		zipcode_input.text = user_data["zipcode"]

	# Load profile picture if exists
	if user_data.has("profile_picture"):
		profile_picture_path = user_data["profile_picture"]
		_load_profile_picture(profile_picture_path)

func _load_profile_picture(path: String):
	# TODO: Load actual profile picture from path
	# For now, just show a placeholder
	pass

func _load_theme_preferences():
	var prefs = Config.load_preferences()

	if prefs.has("primary_color"):
		var color_array = prefs["primary_color"]
		primary_color_picker.color = Color(color_array[0], color_array[1], color_array[2], color_array[3])
	else:
		primary_color_picker.color = DEFAULT_PRIMARY_COLOR

	if prefs.has("secondary_color"):
		var color_array = prefs["secondary_color"]
		secondary_color_picker.color = Color(color_array[0], color_array[1], color_array[2], color_array[3])
	else:
		secondary_color_picker.color = DEFAULT_SECONDARY_COLOR

func _on_upload_photo_pressed():
	# Open file dialog to select profile picture
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Image Files"])
	file_dialog.file_selected.connect(_on_photo_selected)
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2(800, 600))

func _on_photo_selected(path: String):
	profile_picture_path = path
	_load_profile_picture(path)
	status_label.text = "Profile picture updated (save to apply)"
	status_label.modulate = Color.YELLOW

func _on_save_pressed():
	var new_username = username_input.text.strip_edges()
	var new_email = email_input.text.strip_edges()
	var new_zipcode = zipcode_input.text.strip_edges()

	# Validate inputs
	if new_username.length() < 3:
		status_label.text = "Username must be at least 3 characters"
		status_label.modulate = Color.RED
		return

	if not Config.is_valid_email(new_email):
		status_label.text = "Invalid email format"
		status_label.modulate = Color.RED
		return

	if not Config.is_valid_us_zipcode(new_zipcode):
		status_label.text = "Invalid US zip code (5 digits required)"
		status_label.modulate = Color.RED
		return

	# Save theme preferences
	_save_theme_preferences()

	# Prepare updated profile data
	var profile_data = {
		"username": new_username,
		"email": new_email,
		"zipcode": new_zipcode
	}

	if profile_picture_path != "":
		profile_data["profile_picture"] = profile_picture_path

	# Show loading state
	status_label.text = "⏳ Saving profile..."
	status_label.modulate = Color(0.7, 0.7, 1.0)
	save_button.disabled = true

	# Send update to backend API
	api.update_profile(profile_data)

func _save_theme_preferences():
	var prefs = Config.load_preferences()
	prefs["primary_color"] = [primary_color_picker.color.r, primary_color_picker.color.g, primary_color_picker.color.b, primary_color_picker.color.a]
	prefs["secondary_color"] = [secondary_color_picker.color.r, secondary_color_picker.color.g, secondary_color_picker.color.b, secondary_color_picker.color.a]
	Config.save_preferences(prefs)

	# Apply theme immediately
	_apply_theme()

func _apply_theme():
	# Update colors throughout the UI
	# This would need to be expanded to update all UI elements
	status_label.text = "Theme applied! Restart app to see full changes."
	status_label.modulate = primary_color_picker.color

func _on_primary_color_changed(color: Color):
	# Preview color change
	pass

func _on_secondary_color_changed(color: Color):
	# Preview color change
	pass

func _on_reset_theme_pressed():
	primary_color_picker.color = DEFAULT_PRIMARY_COLOR
	secondary_color_picker.color = DEFAULT_SECONDARY_COLOR
	_save_theme_preferences()
	status_label.text = "Theme reset to default (Gold & Black)"
	status_label.modulate = DEFAULT_PRIMARY_COLOR

func _on_profile_update_completed(success: bool, data: Dictionary):
	save_button.disabled = false

	if success:
		# Update local user data with response from server
		current_user_data = data

		# Update display
		if data.has("username"):
			username_label.text = data["username"]
		if data.has("email"):
			email_label.text = data["email"]

		status_label.text = "✅ Profile updated successfully!"
		status_label.modulate = Color.GREEN

		# Emit signal to update other screens
		profile_updated.emit(current_user_data)
	else:
		var message = data.get("message", "Failed to update profile. Please try again.")

		# Make error messages more user-friendly
		if message.contains("network") or message.contains("connection"):
			status_label.text = "❌ Connection error. Please check your internet and try again."
		elif message.contains("Session expired") or message.contains("log in"):
			status_label.text = "❌ Session expired. Please log in again."
		elif message.contains("already taken"):
			status_label.text = "❌ Email or username already in use."
		else:
			status_label.text = "❌ " + message

		status_label.modulate = Color.RED

func _on_back_pressed():
	back_clicked.emit()
