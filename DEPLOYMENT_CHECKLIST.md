# Community Calendar - Production Deployment Checklist

Use this checklist before deploying to production to ensure everything is properly configured.

## 📋 Pre-Deployment Configuration

### 1. Environment Configuration (Scripts/Config.gd)

- [ ] Set `current_environment` to `Environment.PRODUCTION`
- [ ] Update `API_URLS[Environment.PRODUCTION]` to your production API URL
- [ ] Update `API_URLS[Environment.STAGING]` to your staging API URL (if applicable)
- [ ] Set `PRIVACY_POLICY_URL` to your actual privacy policy URL
- [ ] Set `TERMS_OF_SERVICE_URL` to your actual terms of service URL
- [ ] Update `SUPPORT_EMAIL` to your support email address
- [ ] Update `FEEDBACK_URL` to your feedback form URL

### 2. Feature Flags (Scripts/Config.gd)

- [ ] Set `allow_image_uploads` based on backend support
- [ ] Set `enable_notifications` if push notifications are implemented
- [ ] Set `show_debug_info` to `false` for production
- [ ] Set `require_email_verification` to `true` for production (recommended)
- [ ] Review and enable/disable other feature flags as needed

### 3. Security Settings (Scripts/Config.gd)

- [ ] Review `min_password_length` (recommended: 8+)
- [ ] Enable `password_require_uppercase` (recommended: true)
- [ ] Enable `password_require_number` (recommended: true)
- [ ] Review `max_login_attempts` and `lockout_duration_seconds`
- [ ] Review `session_timeout_hours` (recommended: 24)

### 4. Analytics Integration

- [ ] Integrate Analytics.gd with your analytics provider (Google Analytics, Firebase, etc.)
- [ ] Implement `_flush_events()` in Analytics.gd to send events to your service
- [ ] Test analytics event tracking
- [ ] Verify user identification works correctly

### 5. Backend API

- [ ] Backend API is deployed and accessible
- [ ] All required endpoints are implemented (see BACKEND_API.md)
- [ ] API uses HTTPS (not HTTP)
- [ ] CORS is properly configured
- [ ] Authentication tokens (JWT) are working
- [ ] Rate limiting is configured on backend
- [ ] Database backups are configured
- [ ] Error logging is set up on backend

## 📱 Mobile (Android) Deployment

### 1. Android Configuration

- [ ] Update `package/unique_name` in export_presets.cfg (currently: com.community.calendar)
- [ ] Update version code and name in export_presets.cfg
- [ ] Create Android keystore for signing
- [ ] Configure signing in Godot export settings
- [ ] Test on multiple Android devices/versions
- [ ] Create app icons (launcher icons)
- [ ] Create feature graphic for Play Store
- [ ] Create screenshots for Play Store listing

### 2. Google Play Store

- [ ] Create Google Play Developer account
- [ ] Prepare app listing (title, description, screenshots)
- [ ] Set up privacy policy URL
- [ ] Configure content rating
- [ ] Set up pricing and distribution
- [ ] Upload APK or App Bundle
- [ ] Submit for review

## 🌐 Web Deployment

### 1. Web Build

- [ ] Export as Web (HTML5) from Godot
- [ ] Test exported build locally
- [ ] Verify PWA functionality works
- [ ] Create PWA icons (144x144, 180x180, 512x512)
- [ ] Test on multiple browsers (Chrome, Firefox, Safari, Edge)
- [ ] Test on mobile browsers
- [ ] Verify offline mode works (if enabled)

### 2. Web Hosting

- [ ] Choose hosting provider (Netlify, Vercel, AWS S3 + CloudFront, etc.)
- [ ] Configure custom domain
- [ ] Enable HTTPS/SSL
- [ ] Configure CORS headers
- [ ] Set up CDN for faster loading
- [ ] Configure caching headers
- [ ] Test deployment
- [ ] Set up monitoring/analytics

## 🔒 Security & Privacy

### 1. Legal Documents

- [ ] Create actual Privacy Policy (replace default in LegalScreen.gd)
- [ ] Create actual Terms of Service (replace default in LegalScreen.gd)
- [ ] Host privacy policy on your website
- [ ] Host terms of service on your website
- [ ] Update URLs in Config.gd

### 2. Data Protection

- [ ] Implement user data deletion functionality
- [ ] Set up data backup procedures
- [ ] Configure data retention policies
- [ ] Review GDPR compliance (if applicable)
- [ ] Review CCPA compliance (if applicable)
- [ ] Implement cookie consent (if required)

### 3. Security Audit

- [ ] Review all input validation
- [ ] Test for XSS vulnerabilities
- [ ] Test for SQL injection (backend)
- [ ] Review authentication flow
- [ ] Test password reset flow (if implemented)
- [ ] Review API endpoint security
- [ ] Test rate limiting
- [ ] Review error messages (don't expose sensitive info)

## 🧪 Testing

### 1. Functional Testing

- [ ] Test user registration flow
- [ ] Test user login flow
- [ ] Test event creation
- [ ] Test event editing
- [ ] Test event deletion
- [ ] Test event search
- [ ] Test event filtering
- [ ] Test RSVP functionality
- [ ] Test favorites functionality
- [ ] Test logout

### 2. Error Handling

- [ ] Test offline mode
- [ ] Test with slow network
- [ ] Test with no network
- [ ] Test API errors (500, 404, etc.)
- [ ] Test validation errors
- [ ] Test token expiration

### 3. Performance Testing

- [ ] Test with large number of events
- [ ] Test with slow API responses
- [ ] Check memory usage
- [ ] Check battery usage on mobile
- [ ] Test loading times
- [ ] Test cache effectiveness

### 4. Compatibility Testing

- [ ] Test on Android 8.0+ devices
- [ ] Test on different screen sizes
- [ ] Test on tablets
- [ ] Test on different browsers (for web)
- [ ] Test PWA installation
- [ ] Test landscape orientation

## 📊 Monitoring & Analytics

### 1. Application Monitoring

- [ ] Set up error tracking (Sentry, Bugsnag, etc.)
- [ ] Set up performance monitoring
- [ ] Configure alerts for critical errors
- [ ] Set up uptime monitoring
- [ ] Monitor API response times

### 2. Analytics

- [ ] Verify analytics events are being sent
- [ ] Set up conversion tracking
- [ ] Set up user retention tracking
- [ ] Create analytics dashboard
- [ ] Set up regular reporting

## 🚀 Launch

### 1. Soft Launch (Optional)

- [ ] Deploy to beta testers
- [ ] Collect feedback
- [ ] Fix critical issues
- [ ] Monitor metrics

### 2. Public Launch

- [ ] Announce on social media
- [ ] Submit to app stores
- [ ] Update website
- [ ] Notify beta testers
- [ ] Monitor for issues

### 3. Post-Launch

- [ ] Monitor error rates
- [ ] Monitor user feedback
- [ ] Monitor performance metrics
- [ ] Respond to user reviews
- [ ] Plan first update

## 📝 Documentation

- [ ] Update README with production setup
- [ ] Document backend API
- [ ] Create user guide
- [ ] Create admin guide
- [ ] Document troubleshooting steps

## 🔄 Maintenance Plan

- [ ] Set up automated backups
- [ ] Plan for regular updates
- [ ] Set up update notification system
- [ ] Create incident response plan
- [ ] Plan for scaling

---

## Quick Pre-Launch Verification

Before deploying, verify these critical items:

1. ✅ Environment is set to PRODUCTION in Config.gd
2. ✅ All URLs point to production servers
3. ✅ Debug mode is DISABLED
4. ✅ Analytics is properly integrated
5. ✅ Backend API is live and tested
6. ✅ Privacy policy and ToS are live
7. ✅ App is signed with production keys
8. ✅ All tests pass
9. ✅ Error monitoring is active
10. ✅ Backups are configured

---

**Need Help?** Check PRODUCTION_SETUP.md for detailed setup instructions.
