# 🚀 LAUNCH NOW - Quick Start Guide

Follow these steps in order to launch your Community Calendar app in **under 2 hours**.

---

## ⚡ Before You Start

**You need:**
- [ ] A domain name (e.g., `mycommunity.com`)
- [ ] A server or cloud account (Heroku, Railway, DigitalOcean, etc.)
- [ ] 2 hours of focused time

**Optional but recommended:**
- [ ] Google Analytics account (free)
- [ ] Sentry account for error tracking (free)

---

## 🎯 Step-by-Step Launch Process

### **STEP 1: Deploy Your Backend** (30 minutes)

#### Option A: Heroku (Easiest)

```bash
# 1. Install Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# 2. Login
heroku login

# 3. Create app
cd Backend/nodejs-example
heroku create mycommunity-calendar-api

# 4. Add MongoDB
heroku addons:create mongolab:sandbox

# 5. Set environment variables
heroku config:set JWT_SECRET=$(openssl rand -base64 32)
heroku config:set NODE_ENV=production
heroku config:set CORS_ORIGIN=https://mycommunity.com

# 6. Deploy
git init
git add .
git commit -m "Initial backend"
heroku git:remote -a mycommunity-calendar-api
git push heroku main

# 7. Test
curl https://mycommunity-calendar-api.herokuapp.com/api/health
```

#### Option B: Railway (Also Easy)

```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login
railway login

# 3. Deploy
cd Backend/nodejs-example
railway init
railway up

# 4. Add MongoDB
railway add mongodb

# 5. Set variables in dashboard
railway open
# Set: JWT_SECRET, CORS_ORIGIN

# 6. Get your URL
railway domain
```

**Your Backend URL:** `https://your-app.herokuapp.com/api` or `https://your-app.up.railway.app/api`

✅ **Checkpoint:** Visit `https://your-backend-url/api/health` - Should return `{"status":"ok"}`

---

### **STEP 2: Configure SSL** (10 minutes)

#### If using Heroku/Railway
✅ **SSL is automatic!** They provide HTTPS by default.

#### If using your own server
```bash
# Install Let's Encrypt
sudo apt-get install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d api.mycommunity.com

# Test
curl https://api.mycommunity.com/api/health
```

✅ **Checkpoint:** Your API should work with `https://`

---

### **STEP 3: Set Up Analytics** (10 minutes)

#### Google Analytics 4 (Recommended)

1. Go to [analytics.google.com](https://analytics.google.com)
2. Create account → Create property
3. Get your **Measurement ID** (looks like `G-XXXXXXXXXX`)
4. Go to Admin → Data Streams → Measurement Protocol API secrets
5. Create API secret

**Write these down:**
- Measurement ID: `G-__________`
- API Secret: `________________`

---

### **STEP 4: Set Up Error Tracking** (10 minutes)

#### Sentry (Recommended)

1. Go to [sentry.io](https://sentry.io)
2. Create free account
3. Create new project → Select "Other"
4. Copy your **DSN** (looks like `https://abc123@o456.ingest.sentry.io/789`)

**Write this down:**
- Sentry DSN: `https://_______________`

---

### **STEP 5: Configure Your App** (15 minutes)

#### Open `Scripts/Config.gd` and update:

```gdscript
# Line 19: Change environment
var current_environment: Environment = Environment.PRODUCTION

# Lines 25-29: Update API URLs
const API_URLS = {
    Environment.DEVELOPMENT: "http://localhost:3000/api",
    Environment.STAGING: "https://staging.mycommunity.com/api",  # Optional
    Environment.PRODUCTION: "https://api.mycommunity.com/api",  # ← YOUR URL HERE
    Environment.DEMO: "demo"
}

# Line 39: Disable debug
"show_debug_info": false,  # MUST be false

# Line 42: Enable email verification (recommended)
"require_email_verification": true,

# Lines 74-76: Update legal URLs
const PRIVACY_POLICY_URL = "https://mycommunity.com/privacy"  # ← YOUR URL
const TERMS_OF_SERVICE_URL = "https://mycommunity.com/terms"  # ← YOUR URL
const SUPPORT_EMAIL = "support@mycommunity.com"  # ← YOUR EMAIL
```

#### Open `Scripts/AnalyticsProviders.gd` and update:

```gdscript
# Lines 10-12: Add your GA4 credentials
const GA4_MEASUREMENT_ID = "G-XXXXXXXXXX"  # ← FROM STEP 3
const GA4_API_SECRET = "your_api_secret"   # ← FROM STEP 3
const GA4_ENABLED = true  # Enable it
```

#### Open `Scripts/ErrorTracker.gd` and update:

```gdscript
# Line 9: Add your Sentry DSN
const SENTRY_DSN = "https://YOUR_KEY@sentry.io/PROJECT"  # ← FROM STEP 4
const SENTRY_ENABLED = true  # Enable it
```

✅ **Checkpoint:** Run pre-flight check (see Step 6)

---

### **STEP 6: Run Pre-Flight Check** (5 minutes)

Open Godot and run this in the debugger console:

```gdscript
PreFlightCheck.run_checks()
```

Or add this temporarily to `Main.gd` `_ready()`:

```gdscript
func _ready():
    PreFlightCheck.run_checks()
    # ... rest of code
```

**Expected Output:**
```
🚀 Running Pre-Flight Checks...
==================================================

ENVIRONMENT:
   ✅ Environment: Production

API_URL:
   ✅ API URL: https://api.mycommunity.com/api

SECURITY:
   ✅ Password requirements: 8+ chars
   ✅ Strong password requirements enabled

ANALYTICS:
   ✅ Analytics: 1 provider(s) configured

ERROR_TRACKING:
   ✅ Error tracking: Sentry configured

LEGAL:
   ✅ Privacy Policy URL set
   ✅ Terms of Service URL set
   ✅ Support email set

FEATURES:
   ✅ Debug mode disabled

==================================================
📊 PRE-FLIGHT CHECK RESULTS
==================================================
✅ Passed: 7
⚠️  Warnings: 0
❌ Failed: 0
==================================================

🎉 READY FOR LAUNCH! All critical checks passed
```

**If you see warnings or failures:**
- Fix them before continuing
- Re-run the check

---

### **STEP 7: Build Your App** (10 minutes)

#### For Web (Progressive Web App)

```bash
# In Godot:
1. Project → Export
2. Select "Web" preset
3. Click "Export Project"
4. Save to: Exports/Web/
```

#### For Android

```bash
# In Godot:
1. Project → Export
2. Select "Android" preset
3. Configure signing (if not done):
   - keystore: /path/to/your.keystore
   - keystore password: your_password
4. Click "Export Project"
5. Save to: Exports/Android/CommunityCalendar-v1.0.0.apk
```

✅ **Checkpoint:** You should have exported files

---

### **STEP 8: Deploy Web App** (15 minutes)

#### Option A: Netlify (Recommended for Web)

```bash
# 1. Install Netlify CLI
npm install -g netlify-cli

# 2. Login
netlify login

# 3. Deploy
cd Exports/Web
netlify deploy --prod

# 4. Follow prompts:
#    - Create new site? Yes
#    - Site name: mycommunity-calendar
#    - Publish directory: . (current directory)

# 5. Get your URL
```

#### Option B: Vercel

```bash
# 1. Install Vercel CLI
npm install -g vercel

# 2. Deploy
cd Exports/Web
vercel --prod
```

#### Option C: Your Own Server

```bash
# Upload to your server
scp -r Exports/Web/* user@yourserver.com:/var/www/mycommunity/

# Configure Nginx
sudo nano /etc/nginx/sites-available/mycommunity

# Add:
server {
    listen 443 ssl http2;
    server_name mycommunity.com;

    ssl_certificate /etc/letsencrypt/live/mycommunity.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mycommunity.com/privkey.pem;

    root /var/www/mycommunity;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

# Enable and restart
sudo ln -s /etc/nginx/sites-available/mycommunity /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Your App URL:** `https://mycommunity.com` or `https://your-app.netlify.app`

✅ **Checkpoint:** Visit your web app - should load and work

---

### **STEP 9: Test Everything** (15 minutes)

Open your deployed app and test:

- [ ] App loads without errors
- [ ] Can register new account
- [ ] Can login
- [ ] Can create event
- [ ] Can view events
- [ ] Can RSVP to event
- [ ] Can favorite event
- [ ] Can edit own event
- [ ] Can delete own event
- [ ] Can search events
- [ ] Can filter by category

**Check Dashboards:**
- [ ] Sentry: Go to sentry.io → Check for any errors
- [ ] GA4: Go to analytics.google.com → Realtime → See active users

---

### **STEP 10: Set Up Automated Backups** (10 minutes)

```bash
# 1. Make scripts executable
chmod +x Backend/backup-scripts/*.sh

# 2. Test backup
export MONGODB_URI="your_mongodb_connection_string"
./Backend/backup-scripts/mongodb-backup.sh

# 3. Set up daily backups
crontab -e

# Add this line (runs at 2 AM daily):
0 2 * * * MONGODB_URI="your_connection_string" /full/path/to/mongodb-backup.sh >> /var/log/backup.log 2>&1

# 4. Test restore (be careful!)
./Backend/backup-scripts/mongodb-restore.sh ~/backups/mongodb/latest-backup.tar.gz
```

---

### **STEP 11: Submit to App Stores** (Android Only)

#### Google Play Store

1. Go to [play.google.com/console](https://play.google.com/console)
2. Create Developer Account ($25 one-time fee)
3. Create App
4. Fill out store listing:
   - Title: "Community Calendar"
   - Short description: "Discover and create local community events"
   - Full description: [Use from README.md]
   - Screenshots: Take 2-8 screenshots from app
   - Feature graphic: Create 1024x500 image
   - Icon: 512x512 PNG
5. Upload APK from `Exports/Android/`
6. Set content rating
7. Set pricing: Free
8. Submit for review

**Review time:** 1-3 days typically

---

### **STEP 12: Set Up Monitoring** (10 minutes)

#### Uptime Monitoring (Free)

1. Go to [uptimerobot.com](https://uptimerobot.com)
2. Create free account
3. Add monitor:
   - Type: HTTPS
   - URL: `https://your-backend-url/api/health`
   - Interval: 5 minutes
4. Set up email alerts

#### Error Alerts

1. Go to Sentry dashboard
2. Settings → Alerts
3. Create alert rule:
   - When: Any error occurs
   - Then: Email me
4. Save

✅ **Checkpoint:** You'll get notified if anything breaks

---

## 🎉 YOU'RE LIVE!

Congratulations! Your Community Calendar app is now live and available to the public!

---

## 📊 Post-Launch Checklist

**First 24 Hours:**
- [ ] Monitor Sentry for errors
- [ ] Check GA4 for user activity
- [ ] Test on different devices
- [ ] Check server load
- [ ] Respond to any user feedback

**First Week:**
- [ ] Review analytics data
- [ ] Fix any reported bugs
- [ ] Check database backups are working
- [ ] Monitor server costs
- [ ] Plan first update

**First Month:**
- [ ] Analyze user behavior
- [ ] Implement most-requested features
- [ ] Optimize based on usage patterns
- [ ] Consider scaling if needed

---

## 🆘 Troubleshooting

### "Can't connect to backend"
- Check backend is running: `curl https://your-api-url/api/health`
- Check CORS is configured correctly
- Check SSL certificate is valid

### "Analytics not showing data"
- Wait 5-10 minutes for data to appear
- Check Realtime reports first
- Verify credentials in AnalyticsProviders.gd

### "Errors not appearing in Sentry"
- Check SENTRY_ENABLED = true
- Check DSN is correct
- Try manually: `ErrorTracker.capture_error("test")`

### "Database backup fails"
- Check MongoDB URI is correct
- Check disk space
- Check permissions on backup directory

---

## 📞 Need Help?

- **Backend Issues:** Check `Backend/nodejs-example/README.md`
- **SSL Issues:** Check `Backend/SSL_SETUP_GUIDE.md`
- **Integration Issues:** Check `INTEGRATION_GUIDE.md`
- **Deployment Issues:** Check `PRODUCTION_SETUP.md`

---

## 🎯 Quick Reference

**Your URLs:**
- Web App: `https://___________________`
- Backend API: `https://___________________/api`
- Privacy Policy: `https://___________________/privacy`
- Terms of Service: `https://___________________/terms`

**Your Credentials:**
- GA4 Measurement ID: `G-___________`
- GA4 API Secret: `________________`
- Sentry DSN: `https://________________`
- MongoDB URI: `mongodb+srv://________________`

---

**Total Time:** ~2 hours
**Cost:** $0-5/month (free tier of most services)
**Complexity:** ⭐⭐⭐ (Medium - but we've made it easy!)

---

**🚀 You did it! Your app is LIVE!** 🎉

Now go share it with your community! 🌟
