extends Control

## Legal Document Viewer (Privacy Policy / Terms of Service)

signal back_clicked()

@onready var back_button = $TopBar/BackButton
@onready var title_label = $TopBar/TitleLabel
@onready var content_text = $ScrollContainer/ContentText
@onready var loading_label = $LoadingLabel

enum DocumentType {
	PRIVACY_POLICY,
	TERMS_OF_SERVICE
}

var current_document: DocumentType = DocumentType.PRIVACY_POLICY

func _ready():
	if has_node("TopBar/BackButton"):
		back_button.pressed.connect(_on_back_pressed)

func show_privacy_policy():
	current_document = DocumentType.PRIVACY_POLICY
	if has_node("TopBar/TitleLabel"):
		title_label.text = "Privacy Policy"
	_load_document()

func show_terms_of_service():
	current_document = DocumentType.TERMS_OF_SERVICE
	if has_node("TopBar/TitleLabel"):
		title_label.text = "Terms of Service"
	_load_document()

func _load_document():
	# Show loading state
	if has_node("LoadingLabel"):
		loading_label.visible = true
	if has_node("ScrollContainer/ContentText"):
		content_text.text = ""

	# Try to load from URL if configured, otherwise use default text
	var url = ""
	var default_content = ""

	if current_document == DocumentType.PRIVACY_POLICY:
		url = Config.PRIVACY_POLICY_URL
		default_content = _get_default_privacy_policy()
	else:
		url = Config.TERMS_OF_SERVICE_URL
		default_content = _get_default_terms_of_service()

	# For now, just show the default content
	# In production, you would fetch from the URL
	_display_content(default_content)

func _display_content(content: String):
	if has_node("ScrollContainer/ContentText"):
		content_text.text = content
	if has_node("LoadingLabel"):
		loading_label.visible = false

func _on_back_pressed():
	back_clicked.emit()

func _get_default_privacy_policy() -> String:
	return """PRIVACY POLICY

Last Updated: """ + Time.get_datetime_string_from_system() + """

1. INTRODUCTION

Welcome to Community Calendar ("we," "our," or "us"). We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you use our app.

2. DATA WE COLLECT

We collect and process the following data:
- Account Information: username, email address
- Event Information: events you create, attend, or show interest in
- Usage Data: how you interact with our app
- Device Information: device type, operating system, app version

3. HOW WE USE YOUR DATA

We use your data to:
- Provide and maintain our service
- Notify you about changes to our service
- Provide customer support
- Monitor usage and improve our service
- Detect and prevent technical issues

4. DATA SECURITY

We implement appropriate security measures to protect your personal data. However, no method of transmission over the internet is 100% secure.

5. YOUR RIGHTS

You have the right to:
- Access your personal data
- Correct inaccurate data
- Request deletion of your data
- Object to processing of your data
- Data portability

6. COOKIES AND TRACKING

We use local storage to improve your experience. You can control this through your device settings.

7. THIRD-PARTY SERVICES

We may use third-party services for analytics and improvements. These services have their own privacy policies.

8. CHILDREN'S PRIVACY

Our service is not intended for children under 13. We do not knowingly collect data from children under 13.

9. CHANGES TO THIS POLICY

We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.

10. CONTACT US

If you have questions about this privacy policy, please contact us at:
Email: """ + Config.SUPPORT_EMAIL + """

11. DATA RETENTION

We retain your personal data only as long as necessary for the purposes set out in this privacy policy.

12. INTERNATIONAL TRANSFERS

Your data may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place.

By using Community Calendar, you agree to this privacy policy."""

func _get_default_terms_of_service() -> String:
	return """TERMS OF SERVICE

Last Updated: """ + Time.get_datetime_string_from_system() + """

1. ACCEPTANCE OF TERMS

By accessing and using Community Calendar ("the App"), you accept and agree to be bound by these Terms of Service.

2. DESCRIPTION OF SERVICE

Community Calendar provides a platform for users to create, discover, and participate in local community events.

3. USER ACCOUNTS

3.1. You must create an account to use certain features.
3.2. You are responsible for maintaining the confidentiality of your account.
3.3. You must provide accurate and complete information.
3.4. You must be at least 13 years old to use this service.

4. USER CONDUCT

You agree NOT to:
- Post false, misleading, or fraudulent content
- Harass, abuse, or harm others
- Violate any laws or regulations
- Infringe on intellectual property rights
- Distribute spam or malicious content
- Attempt to gain unauthorized access to the service

5. CONTENT

5.1. You retain ownership of content you post.
5.2. You grant us a license to use, display, and distribute your content.
5.3. We reserve the right to remove content that violates these terms.
5.4. You are responsible for the content you post.

6. EVENTS

6.1. Event organizers are responsible for their events.
6.2. We are not liable for events posted by users.
6.3. Users attend events at their own risk.
6.4. We may remove events that violate our policies.

7. PRIVACY

Your use of the App is also governed by our Privacy Policy.

8. DISCLAIMER OF WARRANTIES

THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.

9. LIMITATION OF LIABILITY

WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES.

10. INDEMNIFICATION

You agree to indemnify and hold us harmless from any claims arising from your use of the App.

11. TERMINATION

11.1. We may terminate or suspend your account at any time.
11.2. You may terminate your account at any time.
11.3. Upon termination, your right to use the App will cease.

12. CHANGES TO TERMS

We reserve the right to modify these terms at any time. Continued use constitutes acceptance of modified terms.

13. GOVERNING LAW

These terms are governed by applicable local laws.

14. DISPUTE RESOLUTION

Any disputes shall be resolved through good faith negotiation or mediation before litigation.

15. ENTIRE AGREEMENT

These terms constitute the entire agreement between you and us regarding the App.

16. CONTACT

For questions about these terms, contact us at:
Email: """ + Config.SUPPORT_EMAIL + """

17. SEVERABILITY

If any provision is found unenforceable, the remaining provisions will remain in effect.

18. NO WAIVER

Our failure to enforce any right or provision shall not constitute a waiver.

By using Community Calendar, you agree to these Terms of Service."""
