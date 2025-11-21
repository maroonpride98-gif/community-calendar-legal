extends Node

## Pre-Flight Check System
## Validates app configuration before launch

signal check_completed(passed: bool, results: Dictionary)

enum CheckStatus {
	PASS,
	WARN,
	FAIL
}

var check_results: Dictionary = {}

# Run all pre-flight checks
func run_checks() -> Dictionary:
	print("\n🚀 Running Pre-Flight Checks...")
	print("=".repeat(50))

	check_results.clear()

	_check_environment()
	_check_api_configuration()
	_check_security_settings()
	_check_analytics()
	_check_error_tracking()
	_check_legal_urls()
	_check_feature_flags()

	var summary = _generate_summary()
	check_completed.emit(summary["ready_for_launch"], check_results)

	_print_results(summary)

	return summary

# Check environment configuration
func _check_environment():
	var status = CheckStatus.PASS
	var message = "Environment: " + Config.get_environment_name()

	if Config.current_environment == Config.AppEnvironment.DEMO:
		status = CheckStatus.FAIL
		message = "⚠️ Still in DEMO mode! Change to PRODUCTION in Config.gd"
	elif Config.current_environment == Config.AppEnvironment.DEVELOPMENT:
		status = CheckStatus.WARN
		message = "⚠️ In DEVELOPMENT mode. Should be PRODUCTION for launch"
	else:
		message = "✅ Environment: " + Config.get_environment_name()

	check_results["environment"] = {
		"status": status,
		"message": message
	}

# Check API configuration
func _check_api_configuration():
	var api_url = Config.get_api_url()
	var status = CheckStatus.PASS
	var message = ""

	if api_url == "demo":
		status = CheckStatus.FAIL
		message = "⚠️ API URL not configured! Set production URL in Config.gd"
	elif api_url.contains("localhost") or api_url.contains("127.0.0.1"):
		status = CheckStatus.WARN
		message = "⚠️ API URL points to localhost. Use production URL for launch"
	elif not api_url.begins_with("https://"):
		status = CheckStatus.FAIL
		message = "⚠️ API URL must use HTTPS for production!"
	elif api_url.contains("yourcommunity.com") or api_url.contains("example.com"):
		status = CheckStatus.FAIL
		message = "⚠️ API URL is still a placeholder. Update with real URL in Config.gd"
	else:
		message = "✅ API URL: " + api_url

	check_results["api_url"] = {
		"status": status,
		"message": message
	}

# Check security settings
func _check_security_settings():
	var status = CheckStatus.PASS
	var messages = []

	if Config.SECURITY["min_password_length"] < 8:
		status = CheckStatus.WARN
		messages.append("⚠️ Password min length is " + str(Config.SECURITY["min_password_length"]) + ", recommend 8+")
	else:
		messages.append("✅ Password requirements: " + str(Config.SECURITY["min_password_length"]) + "+ chars")

	if not Config.SECURITY["password_require_uppercase"] or not Config.SECURITY["password_require_number"]:
		status = CheckStatus.WARN
		messages.append("⚠️ Weak password requirements. Enable uppercase + numbers")
	else:
		messages.append("✅ Strong password requirements enabled")

	check_results["security"] = {
		"status": status,
		"message": "\n   ".join(messages)
	}

# Check analytics
func _check_analytics():
	var status = CheckStatus.PASS
	var message = ""

	if not Config.is_feature_enabled("enable_analytics"):
		status = CheckStatus.WARN
		message = "⚠️ Analytics disabled. Enable to track users"
	else:
		var providers_configured = 0

		if AnalyticsProviders.GA4_ENABLED and AnalyticsProviders.GA4_MEASUREMENT_ID != "":
			providers_configured += 1
		if AnalyticsProviders.FIREBASE_ENABLED and AnalyticsProviders.FIREBASE_API_KEY != "":
			providers_configured += 1
		if AnalyticsProviders.MIXPANEL_ENABLED and AnalyticsProviders.MIXPANEL_TOKEN != "":
			providers_configured += 1

		if providers_configured == 0:
			status = CheckStatus.WARN
			message = "⚠️ Analytics enabled but no providers configured"
		else:
			message = "✅ Analytics: " + str(providers_configured) + " provider(s) configured"

	check_results["analytics"] = {
		"status": status,
		"message": message
	}

# Check error tracking
func _check_error_tracking():
	var status = CheckStatus.PASS
	var message = ""

	if not ErrorTracker.SENTRY_ENABLED:
		status = CheckStatus.WARN
		message = "⚠️ Error tracking disabled. Configure Sentry for production"
	elif ErrorTracker.SENTRY_DSN == "":
		status = CheckStatus.WARN
		message = "⚠️ Sentry enabled but DSN not configured"
	else:
		message = "✅ Error tracking: Sentry configured"

	check_results["error_tracking"] = {
		"status": status,
		"message": message
	}

# Check legal URLs
func _check_legal_urls():
	var status = CheckStatus.PASS
	var messages = []

	if Config.PRIVACY_POLICY_URL.contains("yourcommunity.com"):
		status = CheckStatus.FAIL
		messages.append("⚠️ Privacy Policy URL is placeholder")
	else:
		messages.append("✅ Privacy Policy URL set")

	if Config.TERMS_OF_SERVICE_URL.contains("yourcommunity.com"):
		status = CheckStatus.FAIL
		messages.append("⚠️ Terms of Service URL is placeholder")
	else:
		messages.append("✅ Terms of Service URL set")

	if Config.SUPPORT_EMAIL.contains("yourcommunity.com"):
		status = CheckStatus.WARN
		messages.append("⚠️ Support email is placeholder")
	else:
		messages.append("✅ Support email set")

	check_results["legal"] = {
		"status": status,
		"message": "\n   ".join(messages)
	}

# Check feature flags
func _check_feature_flags():
	var status = CheckStatus.PASS
	var messages = []

	if Config.is_feature_enabled("show_debug_info"):
		status = CheckStatus.FAIL
		messages.append("⚠️ DEBUG MODE IS ON! Disable for production")
	else:
		messages.append("✅ Debug mode disabled")

	if Config.is_feature_enabled("offline_mode"):
		messages.append("✅ Offline mode enabled")

	if Config.is_feature_enabled("require_email_verification"):
		messages.append("✅ Email verification required (recommended)")
	else:
		status = CheckStatus.WARN
		messages.append("⚠️ Email verification not required (recommended for production)")

	check_results["features"] = {
		"status": status,
		"message": "\n   ".join(messages)
	}

# Generate summary
func _generate_summary() -> Dictionary:
	var failed = 0
	var warnings = 0
	var passed = 0

	for key in check_results:
		match check_results[key]["status"]:
			CheckStatus.FAIL:
				failed += 1
			CheckStatus.WARN:
				warnings += 1
			CheckStatus.PASS:
				passed += 1

	var ready_for_launch = (failed == 0)
	var ready_for_soft_launch = (failed == 0 and warnings <= 3)

	return {
		"ready_for_launch": ready_for_launch,
		"ready_for_soft_launch": ready_for_soft_launch,
		"total_checks": check_results.size(),
		"passed": passed,
		"warnings": warnings,
		"failed": failed
	}

# Print results
func _print_results(summary: Dictionary):
	print("\n" + "=".repeat(50))
	print("📊 PRE-FLIGHT CHECK RESULTS")
	print("=".repeat(50))

	for key in check_results:
		var result = check_results[key]
		print("\n" + key.to_upper() + ":")
		print("   " + result["message"])

	print("\n" + "=".repeat(50))
	print("📈 SUMMARY")
	print("=".repeat(50))
	print("✅ Passed: " + str(summary["passed"]))
	print("⚠️  Warnings: " + str(summary["warnings"]))
	print("❌ Failed: " + str(summary["failed"]))
	print("=".repeat(50))

	if summary["ready_for_launch"]:
		print("\n🎉 READY FOR LAUNCH! All critical checks passed")
	elif summary["ready_for_soft_launch"]:
		print("\n🚀 READY FOR SOFT LAUNCH (with warnings)")
		print("   Fix warnings before public launch")
	else:
		print("\n❌ NOT READY FOR LAUNCH")
		print("   Fix all FAILED checks before launching")

	print("\n" + "=".repeat(50) + "\n")

# Quick check (returns true if ready)
func is_ready_for_launch() -> bool:
	var summary = run_checks()
	return summary["ready_for_launch"]

# Get status message
func get_status_message() -> String:
	if Config.is_demo_mode():
		return "DEMO MODE - Not configured for production"
	elif Config.current_environment == Config.AppEnvironment.DEVELOPMENT:
		return "DEVELOPMENT MODE"
	elif Config.current_environment == Config.AppEnvironment.STAGING:
		return "STAGING MODE"
	else:
		return "PRODUCTION MODE"

# Quick validation without full report
func validate_critical() -> Array:
	var issues = []

	if Config.is_demo_mode():
		issues.append("App is in DEMO mode - change to PRODUCTION")

	var api_url = Config.get_api_url()
	if api_url.contains("example.com") or api_url.contains("yourcommunity.com"):
		issues.append("API URL is still a placeholder")

	if not api_url.begins_with("https://") and Config.current_environment == Config.AppEnvironment.PRODUCTION:
		issues.append("API URL must use HTTPS")

	if Config.is_feature_enabled("show_debug_info"):
		issues.append("Debug mode is enabled - disable for production")

	return issues
