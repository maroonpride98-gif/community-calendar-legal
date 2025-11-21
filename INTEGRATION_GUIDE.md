# Community Calendar - Integration Guide

Complete guide to integrating error tracking, analytics, backups, and SSL for production deployment.

## Table of Contents

1. [Error Tracking Integration](#error-tracking-integration)
2. [Analytics Integration](#analytics-integration)
3. [Backend Setup](#backend-setup)
4. [Database Backups](#database-backups)
5. [SSL/HTTPS Setup](#sslhttps-setup)
6. [Testing Everything](#testing-everything)

---

## Error Tracking Integration

### Option 1: Sentry (Recommended)

#### 1. Create Sentry Account

1. Go to [sentry.io](https://sentry.io)
2. Create free account
3. Create new project → select "Other" platform
4. Copy your DSN (looks like: `https://abc123@o456.ingest.sentry.io/789`)

#### 2. Configure in App

Open `Scripts/ErrorTracker.gd`:

```gdscript
const SENTRY_DSN = "https://YOUR_KEY@YOUR_ORG.ingest.sentry.io/YOUR_PROJECT"
const SENTRY_ENABLED = true  # Enable Sentry
```

#### 3. Test Error Tracking

```gdscript
# In any script
ErrorTracker.capture_error("Test error from Community Calendar", {
    "test_key": "test_value"
})
```

Check Sentry dashboard to see the error appear!

### Option 2: Custom Error Service

If you have your own error tracking service:

```gdscript
# In Scripts/ErrorTracker.gd
func _send_to_custom_service(error_data: Dictionary):
    var http = HTTPRequest.new()
    get_tree().root.add_child(http)

    var url = "https://your-error-service.com/api/errors"
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer YOUR_API_KEY"
    ]

    http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(error_data))
```

Then in `capture_error()`:
```gdscript
if SENTRY_ENABLED:
    _send_to_sentry(error_data)
else:
    _send_to_custom_service(error_data)
```

---

## Analytics Integration

### Option 1: Google Analytics 4

#### 1. Create GA4 Property

1. Go to [analytics.google.com](https://analytics.google.com)
2. Create account + property
3. Get Measurement ID (G-XXXXXXXXXX)
4. Create API secret:
   - Admin → Data Streams → Web → Measurement Protocol API secrets
   - Create secret

#### 2. Configure in App

Open `Scripts/AnalyticsProviders.gd`:

```gdscript
const GA4_MEASUREMENT_ID = "G-XXXXXXXXXX"
const GA4_API_SECRET = "your_api_secret_here"
const GA4_ENABLED = true
```

#### 3. Test Analytics

Events are automatically tracked! Check GA4 Realtime reports.

### Option 2: Firebase Analytics

#### 1. Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project
3. Add app
4. Get configuration values

#### 2. Configure in App

Open `Scripts/AnalyticsProviders.gd`:

```gdscript
const FIREBASE_API_KEY = "your_api_key"
const FIREBASE_PROJECT_ID = "your-project-id"
const FIREBASE_APP_ID = "1:123456789:web:abcdef"
const FIREBASE_ENABLED = true
```

### Option 3: Mixpanel

#### 1. Create Mixpanel Project

1. Go to [mixpanel.com](https://mixpanel.com)
2. Create free account
3. Create project
4. Copy Project Token

#### 2. Configure in App

```gdscript
const MIXPANEL_TOKEN = "your_token_here"
const MIXPANEL_ENABLED = true
```

### Custom Events

Track custom events anywhere in your app:

```gdscript
# Track when user creates event
Analytics.track_event("event_created", {
    "category": "sports",
    "has_image": false
})

# Track feature usage
Analytics.track_event("feature_used", {
    "feature_name": "share_event"
})

# Track errors
Analytics.track_error("API request failed", 500)
```

---

## Backend Setup

You have two backend options: Node.js or Python FastAPI.

### Option A: Node.js Backend

#### 1. Navigate to Backend

```bash
cd Backend/nodejs-example
```

#### 2. Install Dependencies

```bash
npm install
```

#### 3. Set Up MongoDB

**Option 1: Local MongoDB**
```bash
# Install MongoDB
sudo apt-get install mongodb  # Ubuntu
brew install mongodb-community  # macOS

# Start MongoDB
mongod
```

**Option 2: MongoDB Atlas (Cloud - Recommended)**
1. Go to [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Create free cluster
3. Create database user
4. Whitelist IP (0.0.0.0/0 for now)
5. Get connection string

#### 4. Configure Environment

```bash
cp .env.example .env
nano .env
```

Update:
```env
PORT=3000
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/community_calendar
JWT_SECRET=CHANGE_THIS_TO_RANDOM_STRING_IN_PRODUCTION
CORS_ORIGIN=http://localhost:8000,https://yourdomain.com
```

#### 5. Start Server

```bash
npm run dev  # Development (with auto-reload)
npm start    # Production
```

#### 6. Test API

```bash
curl http://localhost:3000/api/health
```

Should return: `{"status":"ok", ...}`

### Option B: Python FastAPI Backend

#### 1. Navigate to Backend

```bash
cd Backend/python-fastapi
```

#### 2. Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate  # Windows
```

#### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

#### 4. Configure Environment

```bash
cp .env.example .env
nano .env
```

Update same as Node.js version.

#### 5. Start Server

```bash
python main.py  # Development
# or
uvicorn main:app --host 0.0.0.0 --port 3000  # Production
```

#### 6. Test API

```bash
curl http://localhost:3000/api/health
```

### Update App Configuration

In `Scripts/Config.gd`:

```gdscript
var current_environment: Environment = Environment.DEVELOPMENT

const API_URLS = {
    Environment.DEVELOPMENT: "http://localhost:3000/api",
    Environment.PRODUCTION: "https://api.yourdomain.com/api",
}
```

---

## Database Backups

### Automatic Daily Backups

#### 1. Make Scripts Executable

```bash
chmod +x Backend/backup-scripts/*.sh
```

#### 2. Test Backup

```bash
export MONGODB_URI="your_mongodb_connection_string"
./Backend/backup-scripts/mongodb-backup.sh
```

Check `~/backups/mongodb/` for backup file.

#### 3. Set Up Cron Job (Auto-Backup)

```bash
crontab -e
```

Add:
```cron
# Daily backup at 2 AM
0 2 * * * MONGODB_URI="your_connection_string" /path/to/Backend/backup-scripts/mongodb-backup.sh >> /var/log/mongodb-backup.log 2>&1
```

#### 4. Test Restore

```bash
./Backend/backup-scripts/mongodb-restore.sh ~/backups/mongodb/community_calendar-2024-01-15-020000.tar.gz
```

### Cloud Backup (Optional)

#### AWS S3

Install AWS CLI:
```bash
pip install awscli
aws configure
```

Edit `mongodb-backup.sh`, uncomment:
```bash
aws s3 cp "$BACKUP_DIR/$DATABASE_NAME-$DATE.tar.gz" s3://your-bucket/backups/
```

#### Google Cloud Storage

Install gcloud CLI, then uncomment:
```bash
gsutil cp "$BACKUP_DIR/$DATABASE_NAME-$DATE.tar.gz" gs://your-bucket/backups/
```

---

## SSL/HTTPS Setup

See [SSL_SETUP_GUIDE.md](Backend/SSL_SETUP_GUIDE.md) for detailed instructions.

### Quick Setup with Let's Encrypt

#### 1. Install Certbot

```bash
sudo apt-get install certbot python3-certbot-nginx
```

#### 2. Get Certificate

```bash
sudo certbot --nginx -d api.yourdomain.com
```

#### 3. Update App Config

In `Scripts/Config.gd`:

```gdscript
const API_URLS = {
    Environment.PRODUCTION: "https://api.yourdomain.com/api",  # Note: HTTPS!
}
```

#### 4. Test

```bash
curl https://api.yourdomain.com/api/health
```

---

## Testing Everything

### 1. Test Error Tracking

```gdscript
# Add to any screen, e.g., LoginScreen.gd _ready():
ErrorTracker.capture_error("Test error - please ignore", {
    "screen": "login",
    "test": true
})
```

Check Sentry/your error tracker to confirm.

### 2. Test Analytics

```gdscript
# Events are auto-tracked, but test custom event:
Analytics.track_event("test_event", {
    "source": "integration_test"
})
```

Check GA4/Firebase/Mixpanel dashboard (may take a few minutes).

### 3. Test Backend API

```bash
# Health check
curl https://api.yourdomain.com/api/health

# Register
curl -X POST https://api.yourdomain.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"TestPass123"}'

# Login
curl -X POST https://api.yourdomain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPass123"}'

# Get events (use token from login)
curl https://api.yourdomain.com/api/events \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 4. Test Database Backup

```bash
# Run backup
./Backend/backup-scripts/mongodb-backup.sh

# Verify backup exists
ls -lh ~/backups/mongodb/

# Test restore (be careful - this will overwrite data!)
./Backend/backup-scripts/mongodb-restore.sh ~/backups/mongodb/latest-backup.tar.gz
```

### 5. Test SSL/HTTPS

Visit: https://www.ssllabs.com/ssltest/analyze.html?d=api.yourdomain.com

Should get **A** or **A+** rating.

---

## Production Checklist

Before going live, verify:

**Configuration**
- [ ] `Config.current_environment` set to `PRODUCTION`
- [ ] Production API URL configured (HTTPS)
- [ ] `show_debug_info` set to `false`
- [ ] Privacy Policy and ToS URLs updated

**Error Tracking**
- [ ] Sentry (or alternative) DSN configured
- [ ] Error tracking enabled
- [ ] Test error appears in dashboard

**Analytics**
- [ ] GA4/Firebase/Mixpanel configured
- [ ] Analytics enabled
- [ ] Test event appears in dashboard

**Backend**
- [ ] Backend deployed and accessible via HTTPS
- [ ] MongoDB secured with authentication
- [ ] Environment variables set
- [ ] CORS configured for your domain
- [ ] Rate limiting enabled

**Database**
- [ ] Backups configured and tested
- [ ] Automatic backups scheduled (cron)
- [ ] Restore tested successfully
- [ ] Cloud backup configured (optional)

**SSL/HTTPS**
- [ ] SSL certificate installed
- [ ] HTTPS working
- [ ] HTTP redirects to HTTPS
- [ ] SSL Labs test passes (A or A+)
- [ ] Certificate auto-renewal configured

**Testing**
- [ ] All API endpoints tested
- [ ] User registration works
- [ ] User login works
- [ ] Event CRUD works
- [ ] RSVP works
- [ ] Favorites work
- [ ] Search/filter works
- [ ] Error tracking working
- [ ] Analytics tracking working

---

## Monitoring

### Set Up Monitoring

**Backend Monitoring**
- Use [UptimeRobot](https://uptimerobot.com) (free) to monitor API uptime
- Set up alerts for downtime

**Error Monitoring**
- Check Sentry daily for new errors
- Set up Slack/email notifications in Sentry

**Analytics**
- Check GA4/Firebase daily for user activity
- Set up weekly reports

**Database**
- Monitor MongoDB Atlas metrics
- Set up storage alerts

### Key Metrics to Track

1. **Daily Active Users** (DAU)
2. **Event Creation Rate**
3. **RSVP Conversion Rate**
4. **Error Rate**
5. **API Response Time**
6. **Database Size**

---

## Troubleshooting

### Errors Not Appearing in Sentry

- Check `SENTRY_ENABLED = true`
- Check DSN is correct
- Check internet connectivity
- Look for errors in console

### Analytics Events Not Showing

- Check provider is enabled (e.g., `GA4_ENABLED = true`)
- Check credentials are correct
- Allow 5-10 minutes for events to appear
- Check Realtime reports first

### Backend Connection Fails

- Verify backend is running: `curl http://localhost:3000/api/health`
- Check `Config.get_api_url()` returns correct URL
- Verify CORS is configured for your domain
- Check SSL certificate if using HTTPS

### Database Backup Fails

- Check MongoDB URI is correct
- Verify `mongodump` is installed
- Check disk space
- Verify permissions on backup directory

---

## Next Steps

1. **Deploy Backend** to production server
2. **Configure DNS** to point to your server
3. **Set up SSL** with Let's Encrypt
4. **Configure Analytics** (GA4, Firebase, or Mixpanel)
5. **Set up Error Tracking** (Sentry)
6. **Schedule Backups** with cron
7. **Test Everything** thoroughly
8. **Go Live!** 🚀

---

## Support

Need help?

- Check [PRODUCTION_SETUP.md](PRODUCTION_SETUP.md) for deployment guide
- Check [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) for pre-launch checklist
- Check [SSL_SETUP_GUIDE.md](Backend/SSL_SETUP_GUIDE.md) for SSL setup

---

**You're all set!** Your Community Calendar app is now production-ready with professional error tracking, analytics, backups, and SSL/HTTPS. 🎉
