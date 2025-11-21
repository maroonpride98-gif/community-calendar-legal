# Community Calendar - Production Setup Guide

This guide walks you through preparing your Community Calendar app for production deployment.

## Table of Contents

1. [Configuration](#configuration)
2. [Backend Setup](#backend-setup)
3. [Building for Production](#building-for-production)
4. [Deployment Options](#deployment-options)
5. [Post-Deployment](#post-deployment)
6. [Troubleshooting](#troubleshooting)

---

## Configuration

### Step 1: Configure Environment

Open `Scripts/Config.gd` and update the following:

```gdscript
# Change from DEMO to PRODUCTION
var current_environment: Environment = Environment.PRODUCTION

# Update API URLs
const API_URLS = {
    Environment.PRODUCTION: "https://api.yourcommunity.com/api",  # ← Change this!
    Environment.STAGING: "https://staging-api.yourcommunity.com/api",
    # ...
}
```

### Step 2: Update Legal and Support URLs

Still in `Scripts/Config.gd`:

```gdscript
const PRIVACY_POLICY_URL = "https://yourcommunity.com/privacy"  # ← Change this!
const TERMS_OF_SERVICE_URL = "https://yourcommunity.com/terms"  # ← Change this!
const SUPPORT_EMAIL = "support@yourcommunity.com"  # ← Change this!
const FEEDBACK_URL = "https://yourcommunity.com/feedback"  # ← Change this!
```

### Step 3: Configure Feature Flags

Enable/disable features based on your backend capabilities:

```gdscript
const FEATURE_FLAGS = {
    "allow_image_uploads": false,  # Set to true when backend supports it
    "enable_notifications": false,  # Set to true when push notifications ready
    "enable_analytics": true,  # Keep true for production
    "show_debug_info": false,  # MUST be false for production
    "require_email_verification": true,  # Recommended for production
}
```

### Step 4: Review Security Settings

Adjust security settings as needed:

```gdscript
const SECURITY = {
    "min_password_length": 8,  # Recommended: 8-12
    "password_require_uppercase": true,
    "password_require_number": true,
    "password_require_special": false,  # Optional
    "max_login_attempts": 5,
    "lockout_duration_seconds": 300,  # 5 minutes
}
```

---

## Backend Setup

### Required Backend Endpoints

Your backend must implement these REST API endpoints:

#### Authentication

- `POST /api/auth/register` - Create new user account
- `POST /api/auth/login` - User login

#### Events

- `GET /api/events` - List events (supports `?category=...` and `?search=...`)
- `POST /api/events` - Create event (requires auth)
- `PUT /api/events/{id}` - Update event (requires auth)
- `DELETE /api/events/{id}` - Delete event (requires auth)

#### Social Features (Optional but recommended)

- `POST /api/events/{id}/rsvp` - Update RSVP status
- `POST /api/events/{id}/favorite` - Toggle favorite

See `BACKEND_API.md` for detailed API specifications.

### Backend Requirements

1. **HTTPS Required**: All API endpoints must use HTTPS in production
2. **CORS**: Configure CORS to allow requests from your web app domain
3. **JWT Authentication**: Use JWT tokens for authenticated endpoints
4. **Rate Limiting**: Implement rate limiting to prevent abuse
5. **Input Validation**: Validate all inputs on backend (don't trust client)
6. **Error Handling**: Return consistent error responses

### Example Backend Stack Options

- **Node.js**: Express + MongoDB/PostgreSQL + JWT
- **Python**: FastAPI/Django + PostgreSQL + JWT
- **PHP**: Laravel + MySQL + JWT
- **Ruby**: Rails + PostgreSQL + JWT

### Environment Variables for Backend

```bash
DATABASE_URL=your_database_url
JWT_SECRET=your_super_secret_key_here
CORS_ORIGIN=https://yourcommunity.com
PORT=3000
```

---

## Building for Production

### For Android

#### 1. Install Prerequisites

- Android SDK
- Godot export templates for Android

#### 2. Create Keystore

```bash
keytool -genkeypair -v -keystore community_calendar.keystore \
  -alias community_calendar -keyalg RSA -keysize 2048 -validity 10000
```

**Important**: Keep your keystore file and passwords safe!

#### 3. Configure Export Settings

In Godot:

1. Go to **Project → Export**
2. Select **Android** preset
3. Set **Package/Unique Name**: `com.yourcommunity.calendar`
4. Set **Version Code**: `1` (increment for each release)
5. Set **Version Name**: `1.0.0`
6. Under **Keystore**, configure:
   - Debug Keystore: (optional, for testing)
   - Release Keystore: Path to your `.keystore` file
   - Release User: Your keystore alias
   - Release Password: Your keystore password

#### 4. Build APK

1. Click **Export Project**
2. Choose output location: `Exports/Android/CommunityCalendar-v1.0.0.apk`
3. Save

#### 5. Test APK

Install on a real device and test thoroughly:

```bash
adb install Exports/Android/CommunityCalendar-v1.0.0.apk
```

### For Web (HTML5)

#### 1. Configure Export Settings

In Godot:

1. Go to **Project → Export**
2. Select **Web** preset
3. Enable **Progressive Web App**
4. Set **PWA/Orientation**: Portrait
5. Add PWA icons (144x144, 180x180, 512x512)

#### 2. Build Web Export

1. Click **Export Project**
2. Choose output location: `Exports/Web/`
3. This creates:
   - `index.html`
   - `*.wasm` files
   - `*.pck` file
   - `manifest.json` (if PWA enabled)

#### 3. Test Locally

```bash
cd Exports/Web
python3 -m http.server 8000
```

Visit `http://localhost:8000` to test.

---

## Deployment Options

### Option 1: Netlify (Web - Easiest)

1. Create account at netlify.com
2. Drag and drop your `Exports/Web` folder
3. Configure custom domain
4. SSL is automatic
5. Done!

**Cost**: Free tier available

### Option 2: Vercel (Web)

1. Create account at vercel.com
2. Install Vercel CLI: `npm i -g vercel`
3. Deploy:
   ```bash
   cd Exports/Web
   vercel --prod
   ```
4. Configure custom domain in dashboard

**Cost**: Free tier available

### Option 3: AWS S3 + CloudFront (Web - Scalable)

1. Create S3 bucket
2. Enable static website hosting
3. Upload files from `Exports/Web`
4. Create CloudFront distribution
5. Configure SSL certificate
6. Point your domain to CloudFront

**Cost**: Pay-as-you-go (typically $1-5/month for small apps)

### Option 4: Google Play Store (Android)

1. Create Google Play Developer account ($25 one-time fee)
2. Create app listing
3. Upload APK or App Bundle
4. Fill out store listing:
   - Title
   - Description
   - Screenshots (2-8 images)
   - Feature graphic (1024x500)
   - Icon (512x512)
5. Set content rating
6. Set pricing (Free)
7. Submit for review

**Review time**: 1-3 days typically

### Option 5: Self-Hosted (Web)

Requirements:
- Web server (Apache/Nginx)
- HTTPS certificate (Let's Encrypt)
- Domain name

**Nginx Configuration Example:**

```nginx
server {
    listen 80;
    server_name yourcommunity.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourcommunity.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    root /var/www/community-calendar;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/javascript application/json;

    # Cache static assets
    location ~* \.(wasm|pck|png|jpg|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## Post-Deployment

### 1. Integrate Analytics

Update `Scripts/Analytics.gd` to send events to your analytics service:

```gdscript
func _flush_events():
    if event_queue.is_empty():
        return

    # Send to your analytics service
    var http = HTTPRequest.new()
    get_tree().root.add_child(http)

    var data = JSON.stringify(event_queue)
    http.request(
        "https://analytics.yourcommunity.com/events",
        ["Content-Type: application/json"],
        HTTPClient.METHOD_POST,
        data
    )

    event_queue.clear()
```

### 2. Set Up Error Monitoring

Recommended services:
- **Sentry**: Error tracking and monitoring
- **LogRocket**: Session replay and monitoring
- **Bugsnag**: Error monitoring

### 3. Monitor Backend

- Set up uptime monitoring (UptimeRobot, Pingdom)
- Monitor API response times
- Set up database backups
- Monitor error rates

### 4. Create Support Channels

- Set up support email
- Create FAQ page
- Consider adding in-app feedback form
- Monitor app store reviews

---

## Troubleshooting

### App doesn't connect to backend

1. Check `Config.get_api_url()` returns correct URL
2. Verify backend is accessible via HTTPS
3. Check CORS configuration on backend
4. Check browser console for errors (web)
5. Check API is not behind firewall

### Authentication fails

1. Verify JWT implementation on backend
2. Check token format in responses
3. Test API endpoints with Postman
4. Check password validation matches backend requirements

### Events don't load

1. Check `/api/events` endpoint returns data
2. Verify response format matches expected format
3. Check cache isn't serving stale data (clear `user://data_cache.json`)
4. Check network connectivity

### Web app doesn't work offline

1. Verify PWA is enabled in export settings
2. Check service worker is registered
3. Check cache configuration
4. Test in supported browsers (Chrome, Edge, Safari)

### Android build fails

1. Verify Android SDK is installed
2. Check export templates are installed
3. Verify keystore path and passwords
4. Check `build.gradle` for errors
5. Try cleaning project: **Project → Tools → Clean**

### Performance issues

1. Reduce number of events loaded at once
2. Implement pagination on backend
3. Optimize images
4. Enable compression
5. Use CDN for web builds

---

## Version Updates

### Updating the App

1. Increment version in `Scripts/Config.gd`:
   ```gdscript
   const APP_VERSION = "1.0.1"  # Update this
   const APP_BUILD = 2  # Increment this
   ```

2. For Android, update in export presets:
   - Version Code: Increment by 1
   - Version Name: Update to match APP_VERSION

3. Add changelog in app or on website

4. Test thoroughly before releasing

5. Submit update to store or redeploy web app

---

## Security Best Practices

1. **Never** commit API keys or secrets to git
2. **Always** use HTTPS for backend
3. **Always** validate input on both client and server
4. **Enable** password requirements in production
5. **Implement** rate limiting on backend
6. **Monitor** for unusual activity
7. **Keep** dependencies updated
8. **Regular** security audits
9. **Encrypt** sensitive data in transit and at rest
10. **Follow** OWASP security guidelines

---

## Support

Need help?

- Check `DEPLOYMENT_CHECKLIST.md` for detailed checklist
- Review `BACKEND_API.md` for API specifications
- Check Godot documentation: https://docs.godotengine.org/
- Community support: Create an issue or contact support

---

**Ready to Deploy?** Follow the `DEPLOYMENT_CHECKLIST.md` for a comprehensive pre-launch checklist!
