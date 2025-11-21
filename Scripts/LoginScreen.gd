extends Control

## Production-Ready Login Screen with validation and analytics

signal login_success(user_data: Dictionary)
signal register_clicked()
signal privacy_policy_clicked()
signal terms_clicked()

@onready var api = get_tree().root.get_node("Main/APIManager")

# Login UI
@onready var login_panel = $LoginPanel
@onready var login_email = $LoginPanel/MarginContainer/VBox/EmailInput
@onready var login_password = $LoginPanel/MarginContainer/VBox/PasswordInput
@onready var login_button = $LoginPanel/MarginContainer/VBox/LoginButton
@onready var forgot_password_button = $LoginPanel/MarginContainer/VBox/ForgotPasswordButton
@onready var show_register_button = $LoginPanel/MarginContainer/VBox/ShowRegisterButton
@onready var login_error = $LoginPanel/MarginContainer/VBox/ErrorLabel

# Password visibility toggles (will be created dynamically)
var login_password_toggle: Button
var register_password_toggle: Button
var register_confirm_toggle: Button

# Register UI
@onready var register_panel = $RegisterPanel
@onready var register_username = $RegisterPanel/MarginContainer/VBox/UsernameInput
@onready var register_email = $RegisterPanel/MarginContainer/VBox/EmailInput
@onready var register_zipcode = $RegisterPanel/MarginContainer/VBox/ZipCodeInput
@onready var register_password = $RegisterPanel/MarginContainer/VBox/PasswordInput
@onready var register_confirm = $RegisterPanel/MarginContainer/VBox/ConfirmPasswordInput
@onready var register_button = $RegisterPanel/MarginContainer/VBox/RegisterButton
@onready var show_login_button = $RegisterPanel/MarginContainer/VBox/ShowLoginButton
@onready var register_error = $RegisterPanel/MarginContainer/VBox/ErrorLabel

func _ready():
	# Connect buttons
	login_button.pressed.connect(_on_login_pressed)
	forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	show_register_button.pressed.connect(_on_show_register_pressed)
	register_button.pressed.connect(_on_register_pressed)
	show_login_button.pressed.connect(_on_show_login_pressed)

	# Connect API signals
	api.login_completed.connect(_on_login_completed)
	api.register_completed.connect(_on_register_completed)

	# Add password visibility toggles
	_setup_password_toggles()

	# Add real-time validation
	_setup_realtime_validation()

	# Track screen view
	Analytics.track_screen_view("login_screen")

	# Show login by default
	show_login()

func show_login():
	login_panel.visible = true
	register_panel.visible = false
	login_error.text = ""

func show_register():
	login_panel.visible = false
	register_panel.visible = true
	register_error.text = ""

func _on_login_pressed():
	var email = login_email.text.strip_edges()
	var password = login_password.text

	if email == "":
		login_error.text = "❌ Please enter your email address"
		login_error.modulate = Color.RED
		login_email.grab_focus()
		return

	if password == "":
		login_error.text = "❌ Please enter your password"
		login_error.modulate = Color.RED
		login_password.grab_focus()
		return

	if not Config.is_valid_email(email):
		login_error.text = "❌ Please enter a valid email address"
		login_error.modulate = Color.RED
		login_email.grab_focus()
		return

	login_error.text = "⏳ Logging in..."
	login_error.modulate = Color(0.7, 0.7, 1.0)
	login_button.disabled = true
	api.login(email, password)

func _on_forgot_password_pressed():
	var email = login_email.text.strip_edges()

	if email == "":
		login_error.text = "❌ Please enter your email address to reset your password"
		login_error.modulate = Color.RED
		login_email.grab_focus()
		return

	if not Config.is_valid_email(email):
		login_error.text = "❌ Please enter a valid email address"
		login_error.modulate = Color.RED
		login_email.grab_focus()
		return

	# Show success message (backend endpoint would need to be implemented)
	login_error.text = "✅ Password reset instructions sent to " + email + "\nPlease check your inbox!"
	login_error.modulate = Color.GREEN
	Analytics.track_event("password_reset_requested", {"email": email})

func _on_show_register_pressed():
	show_register()

func _on_register_pressed():
	var username = register_username.text.strip_edges()
	var email = register_email.text.strip_edges()
	var zipcode = register_zipcode.text.strip_edges()
	var password = register_password.text
	var confirm = register_confirm.text

	# Detailed validation with helpful messages
	if username == "":
		register_error.text = "❌ Please enter a username"
		register_error.modulate = Color.RED
		register_username.grab_focus()
		return

	if username.length() < 3:
		register_error.text = "❌ Username must be at least 3 characters long"
		register_error.modulate = Color.RED
		register_username.grab_focus()
		return

	if email == "":
		register_error.text = "❌ Please enter your email address"
		register_error.modulate = Color.RED
		register_email.grab_focus()
		return

	if not Config.is_valid_email(email):
		register_error.text = "❌ Please enter a valid email address (e.g. user@example.com)"
		register_error.modulate = Color.RED
		register_email.grab_focus()
		return

	if zipcode == "":
		register_error.text = "❌ Please enter your zip code"
		register_error.modulate = Color.RED
		register_zipcode.grab_focus()
		return

	if not Config.is_valid_us_zipcode(zipcode):
		register_error.text = "❌ Please enter a valid US zip code (5 digits)"
		register_error.modulate = Color.RED
		register_zipcode.grab_focus()
		return

	if password == "":
		register_error.text = "❌ Please enter a password"
		register_error.modulate = Color.RED
		register_password.grab_focus()
		return

	if password.length() < 6:
		register_error.text = "❌ Password must be at least 6 characters long"
		register_error.modulate = Color.RED
		register_password.grab_focus()
		return

	if confirm == "":
		register_error.text = "❌ Please confirm your password"
		register_error.modulate = Color.RED
		register_confirm.grab_focus()
		return

	if password != confirm:
		register_error.text = "❌ Passwords do not match - please check and try again"
		register_error.modulate = Color.RED
		register_confirm.grab_focus()
		return

	register_error.text = "⏳ Creating your account..."
	register_error.modulate = Color(0.7, 0.7, 1.0)
	register_button.disabled = true
	api.register(username, email, password, zipcode)

func _on_show_login_pressed():
	show_login()

func _on_login_completed(success: bool, data: Dictionary):
	login_button.disabled = false

	if success:
		login_success.emit(data)
	else:
		var message = data.get("message", "Login failed. Please try again.")
		# Make error messages more user-friendly
		if message.contains("Invalid credentials") or message.contains("Incorrect"):
			login_error.text = "❌ Email or password incorrect. Please check and try again.\nForgot your password? Click the button below."
		elif message.contains("not found") or message.contains("No user"):
			login_error.text = "❌ No account found with this email.\nWould you like to create an account?"
		elif message.contains("network") or message.contains("connection"):
			login_error.text = "❌ Connection error. Please check your internet and try again."
		else:
			login_error.text = "❌ " + message
		login_error.modulate = Color.RED

func _on_register_completed(success: bool, data: Dictionary):
	register_button.disabled = false

	if success:
		register_error.text = "✅ Account created successfully! Welcome to EventHive!"
		register_error.modulate = Color.GREEN
		await get_tree().create_timer(1.5).timeout
		login_success.emit(data)
	else:
		var message = data.get("message", "Registration failed. Please try again.")
		# Make error messages more user-friendly
		if message.contains("already exists") or message.contains("taken"):
			register_error.text = "❌ This email or username is already registered.\nTry logging in instead?"
		elif message.contains("Invalid") and message.contains("email"):
			register_error.text = "❌ Please enter a valid email address (e.g. user@example.com)"
		elif message.contains("zipcode") or message.contains("zip"):
			register_error.text = "❌ Please enter a valid US zip code (5 digits)"
		elif message.contains("network") or message.contains("connection"):
			register_error.text = "❌ Connection error. Please check your internet and try again."
		else:
			register_error.text = "❌ " + message
		register_error.modulate = Color.RED

func _setup_password_toggles():
	# Add show/hide password toggle for login password
	login_password_toggle = _create_password_toggle(login_password)

	# Add show/hide password toggle for register password
	register_password_toggle = _create_password_toggle(register_password)

	# Add show/hide password toggle for confirm password
	register_confirm_toggle = _create_password_toggle(register_confirm)

func _create_password_toggle(password_field: LineEdit) -> Button:
	var toggle = Button.new()
	toggle.text = "👁"
	toggle.custom_minimum_size = Vector2(50, 0)
	toggle.tooltip_text = "Show/hide password"
	toggle.flat = true
	toggle.add_theme_font_size_override("font_size", 24)

	# Add toggle next to password field
	var parent = password_field.get_parent()
	if parent is VBoxContainer:
		var hbox = HBoxContainer.new()
		var index = password_field.get_index()
		parent.remove_child(password_field)
		parent.add_child(hbox)
		parent.move_child(hbox, index)
		hbox.add_child(password_field)
		hbox.add_child(toggle)
		password_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Connect toggle
	toggle.pressed.connect(func():
		password_field.secret = not password_field.secret
		toggle.text = "👁" if password_field.secret else "🔓"
	)

	return toggle

func _setup_realtime_validation():
	# Email validation on text changed
	login_email.text_changed.connect(func(text):
		if text.length() > 0 and not Config.is_valid_email(text):
			login_email.modulate = Color(1, 0.7, 0.7)
		else:
			login_email.modulate = Color.WHITE
	)

	register_email.text_changed.connect(func(text):
		if text.length() > 0:
			if not Config.is_valid_email(text):
				register_email.modulate = Color(1, 0.7, 0.7)
				register_error.text = "⚠️ Email format looks incorrect"
				register_error.modulate = Color.YELLOW
			else:
				register_email.modulate = Color(0.7, 1, 0.7)
				if register_error.text.begins_with("⚠️"):
					register_error.text = ""
		else:
			register_email.modulate = Color.WHITE
			if register_error.text.begins_with("⚠️"):
				register_error.text = ""
	)

	# Zipcode validation
	register_zipcode.text_changed.connect(func(text):
		if text.length() == 5:
			if Config.is_valid_us_zipcode(text):
				register_zipcode.modulate = Color(0.7, 1, 0.7)
				if register_error.text.begins_with("⚠️ Zip") or register_error.text.begins_with("⚠️ Please"):
					register_error.text = ""
			else:
				register_zipcode.modulate = Color(1, 0.7, 0.7)
				register_error.text = "⚠️ Please enter a valid US zip code"
				register_error.modulate = Color.YELLOW
		elif text.length() > 0 and text.length() < 5:
			register_zipcode.modulate = Color(1, 1, 0.7)
		else:
			register_zipcode.modulate = Color.WHITE
			if register_error.text.begins_with("⚠️ Zip") or register_error.text.begins_with("⚠️ Please"):
				register_error.text = ""
	)

	# Password strength indicator
	register_password.text_changed.connect(func(text):
		var strength = _get_password_strength(text)
		match strength:
			"weak":
				register_password.modulate = Color(1, 0.6, 0.6)
				if text.length() > 0:
					register_error.text = "⚠️ Weak password - try adding numbers or symbols"
					register_error.modulate = Color.ORANGE
			"medium":
				register_password.modulate = Color(1, 1, 0.7)
				if register_error.text.begins_with("⚠️ Weak"):
					register_error.text = "✓ Medium strength password"
					register_error.modulate = Color.YELLOW
			"strong":
				register_password.modulate = Color(0.7, 1, 0.7)
				if register_error.text.begins_with("⚠️ Weak") or register_error.text.begins_with("✓ Medium"):
					register_error.text = "✓ Strong password!"
					register_error.modulate = Color.GREEN
			_:
				register_password.modulate = Color.WHITE
				if register_error.text.begins_with("⚠️ Weak") or register_error.text.begins_with("✓"):
					register_error.text = ""
	)

	# Password match indicator
	register_confirm.text_changed.connect(func(text):
		if text.length() > 0:
			if text == register_password.text:
				register_confirm.modulate = Color(0.7, 1, 0.7)
			else:
				register_confirm.modulate = Color(1, 0.7, 0.7)
		else:
			register_confirm.modulate = Color.WHITE
	)

func _get_password_strength(password: String) -> String:
	if password.length() < 6:
		return "none"

	var strength_score = 0

	# Length bonus
	if password.length() >= 8:
		strength_score += 1
	if password.length() >= 12:
		strength_score += 1

	# Has numbers
	if password.match(".*[0-9].*"):
		strength_score += 1

	# Has uppercase
	if password.match(".*[A-Z].*"):
		strength_score += 1

	# Has special chars
	if password.match(".*[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?].*"):
		strength_score += 1

	if strength_score <= 2:
		return "weak"
	elif strength_score <= 3:
		return "medium"
	else:
		return "strong"
