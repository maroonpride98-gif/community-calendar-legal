extends Control

@onready var api = $APIManager
@onready var screen_container = $ScreenContainer

# Screen references (will be loaded dynamically)
var current_screen = null
var current_user: User = null

# Preload scenes
const LOGIN_SCENE = preload("res://UI/LoginScreen.tscn")
const EVENT_LIST_SCENE = preload("res://UI/EventListScreen.tscn")
const EVENT_DETAIL_SCENE = preload("res://UI/EventDetailScreen.tscn")
const EVENT_FORM_SCENE = preload("res://UI/EventFormScreen.tscn")

func _ready():
	# Run pre-flight check in debug mode
	if OS.is_debug_build() and Config.is_feature_enabled("show_debug_info"):
		PreFlightCheck.run_checks()

	# Warn if not configured for production
	if Config.current_environment == Config.AppEnvironment.DEMO:
		push_warning("⚠️ App is in DEMO MODE. See LAUNCH_NOW.md to configure for production.")

	# Check if user is already logged in
	if api.auth_token != "":
		show_event_list()
	else:
		show_login()

func show_login():
	_change_screen(LOGIN_SCENE)

func show_register():
	_change_screen(LOGIN_SCENE)
	if current_screen.has_method("show_register"):
		current_screen.show_register()

func show_event_list():
	_change_screen(EVENT_LIST_SCENE)
	# Pass user data to event list screen
	if current_screen.has_method("set_user_data"):
		var cached_user = DataCache.get_cached_user_profile()
		if cached_user:
			current_screen.set_user_data(cached_user)

func show_event_detail(event: Event):
	_change_screen(EVENT_DETAIL_SCENE)
	if current_screen.has_method("set_event"):
		current_screen.set_event(event)

func show_event_form(event: Event = null, city_zipcode: String = ""):
	_change_screen(EVENT_FORM_SCENE)
	if current_screen.has_method("set_event"):
		current_screen.set_event(event)
	# Pass the city zipcode if browsing a specific city
	if city_zipcode != "" and current_screen.has_method("set_city_zipcode"):
		current_screen.set_city_zipcode(city_zipcode)

func logout():
	api.clear_auth_token()
	current_user = null
	show_login()

func _change_screen(scene: PackedScene):
	# Remove current screen
	if current_screen:
		current_screen.queue_free()

	# Instance new screen
	current_screen = scene.instantiate()
	screen_container.add_child(current_screen)

	# Connect common signals
	if current_screen.has_signal("login_success"):
		current_screen.login_success.connect(_on_login_success)
	if current_screen.has_signal("register_clicked"):
		current_screen.register_clicked.connect(show_register)
	if current_screen.has_signal("back_clicked"):
		current_screen.back_clicked.connect(_on_back_clicked)
	if current_screen.has_signal("event_clicked"):
		current_screen.event_clicked.connect(show_event_detail)
	if current_screen.has_signal("create_event_clicked"):
		current_screen.create_event_clicked.connect(_on_create_event_clicked)
	if current_screen.has_signal("edit_event_clicked"):
		current_screen.edit_event_clicked.connect(show_event_form)
	if current_screen.has_signal("logout_clicked"):
		current_screen.logout_clicked.connect(logout)
	if current_screen.has_signal("event_saved"):
		current_screen.event_saved.connect(_on_event_saved)

func _on_login_success(user_data: Dictionary):
	current_user = User.from_dict(user_data)
	show_event_list()

func _on_back_clicked():
	show_event_list()

func _on_create_event_clicked(city_zipcode: String):
	show_event_form(null, city_zipcode)

func _on_event_saved():
	print("[Main] Event saved - returning to event list")
	show_event_list()
	# Force refresh events
	if current_screen and current_screen.has_method("_refresh_events"):
		await get_tree().create_timer(0.1).timeout
		current_screen._refresh_events()
