# 🚀 LAUNCH FOR FREE - Complete Guide

Launch your app with **$0 cost** using free tiers of professional services.

**Only cost:** $25 Google Play fee (one-time, optional)

---

## 🆓 Free Services We'll Use

| Service | Free Tier | What For |
|---------|-----------|----------|
| **Railway** | $5 credit/month (renews) | Backend API |
| **MongoDB Atlas** | 512 MB free forever | Database |
| **Netlify** | 100 GB/month | Web hosting |
| **Google Analytics** | Unlimited | User analytics |
| **Sentry** | 5,000 errors/month | Error tracking |
| **UptimeRobot** | 50 monitors | Uptime monitoring |

**Total Monthly Cost: $0** 🎉

---

## 🚀 The 12 Steps (100% FREE)

### **STEP 1: Deploy Backend to Railway** (20 minutes) - FREE!

#### 1a. Create Railway Account

1. Go to [railway.app](https://railway.app)
2. Click "Start a New Project"
3. Sign up with GitHub (free)

#### 1b. Deploy Backend

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login (opens browser)
railway login

# Go to backend folder
cd /home/whitehammer/CommunityCalendar/Backend/nodejs-example

# Initialize Railway project
railway init

# When prompted:
# - Name: community-calendar-api
# - Environment: production

# Add MongoDB plugin
railway add

# Select: MongoDB
# This creates a free MongoDB instance automatically!

# Deploy!
railway up

# Wait for deployment to complete...

# Generate random JWT secret
railway variables set JWT_SECRET=$(openssl rand -base64 32)

# Set CORS (we'll update this after deploying web app)
railway variables set CORS_ORIGIN=*

# Get your app URL
railway domain

# Copy the URL (looks like: community-calendar-api-production-xxxx.up.railway.app)
```

**Test it works:**
```bash
curl https://your-railway-url.up.railway.app/api/health
```

Should return: `{"status":"ok",...}`

✅ **Your Backend URL:** `https://your-app.up.railway.app/api`

---

### **STEP 2: SSL is Automatic!** (0 minutes) - FREE!

✅ Railway provides HTTPS automatically. Nothing to do!

---

### **STEP 3: Set Up Google Analytics** (10 minutes) - FREE!

1. Go to [analytics.google.com](https://analytics.google.com)
2. Click "Start measuring"
3. Create account:
   - Account name: "Community Calendar"
   - Share data: (your choice)
4. Create property:
   - Property name: "Community Calendar"
   - Time zone: (your timezone)
   - Currency: (your currency)
5. Select platform: **"Web"**
6. Create web stream:
   - Website URL: https://your-site-name.netlify.app (we'll get this in Step 8)
   - Stream name: "Community Calendar Web"
7. Copy your **Measurement ID** (G-XXXXXXXXXX)
8. Go to: Admin → Data Streams → Click your stream → Measurement Protocol API secrets
9. Click "Create" → Name: "API Secret" → Click "Create"
10. Copy the **API Secret**

**Write these down:**
```
GA4 Measurement ID: G-__________
GA4 API Secret:     ________________
```

---

### **STEP 4: Set Up Sentry** (10 minutes) - FREE!

1. Go to [sentry.io](https://sentry.io)
2. Click "Get Started" → Sign up (free)
3. Create organization: "My Apps"
4. Create project:
   - Platform: "Other"
   - Project name: "community-calendar"
5. Copy your **DSN** (shown on screen)
   - Looks like: `https://abc123def456@o123456.ingest.sentry.io/789012`

**Write this down:**
```
Sentry DSN: https://_______________
```

---

### **STEP 5: Configure Your App** (10 minutes)

Open these files and update:

#### File 1: `Scripts/Config.gd`

```gdscript
# Line 19: Change to PRODUCTION
var current_environment: Environment = Environment.PRODUCTION

# Line 28: Update with YOUR Railway URL from Step 1
Environment.PRODUCTION: "https://your-railway-url.up.railway.app/api",

# Line 39: Disable debug
"show_debug_info": false,

# Lines 74-76: Update with YOUR info
const PRIVACY_POLICY_URL = "https://your-site.netlify.app/privacy"
const TERMS_OF_SERVICE_URL = "https://your-site.netlify.app/terms"
const SUPPORT_EMAIL = "youremail@gmail.com"
```

#### File 2: `Scripts/AnalyticsProviders.gd`

```gdscript
# Lines 10-12: Add from Step 3
const GA4_MEASUREMENT_ID = "G-XXXXXXXXXX"  # From Step 3
const GA4_API_SECRET = "your_api_secret"   # From Step 3
const GA4_ENABLED = true
```

#### File 3: `Scripts/ErrorTracker.gd`

```gdscript
# Line 9: Add from Step 4
const SENTRY_DSN = "https://YOUR_KEY@sentry.io/PROJECT"  # From Step 4
const SENTRY_ENABLED = true
```

---

### **STEP 6: Run Pre-Flight Check** (5 minutes)

In Godot, press **F5** to run the app.

Check the console output for:
```
🎉 READY FOR LAUNCH! All critical checks passed
```

If you see warnings or errors, fix them and run again.

---

### **STEP 7: Build Web App** (5 minutes)

In Godot:
1. **Project → Export**
2. Select **"Web"** preset
3. Click **"Export Project"**
4. Navigate to: `/home/whitehammer/CommunityCalendar/Exports/Web/`
5. Click **Save**

---

### **STEP 8: Deploy to Netlify** (10 minutes) - FREE!

#### Option A: Drag & Drop (Easiest)

1. Go to [app.netlify.com](https://app.netlify.com)
2. Sign up (free) with GitHub/email
3. Click "Add new site" → "Deploy manually"
4. Drag your `Exports/Web` folder onto the page
5. Wait for deployment...
6. Click "Domain settings"
7. Click "Edit site name"
8. Change to: `mycommunity-calendar` (or your preferred name)
9. Save

**Your URL:** `https://mycommunity-calendar.netlify.app`

#### Option B: CLI (More Control)

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login
netlify login

# Deploy
cd /home/whitehammer/CommunityCalendar/Exports/Web
netlify deploy --prod

# Follow prompts:
# - Create new site? Yes
# - Site name: mycommunity-calendar
# - Publish directory: . (press Enter)
```

✅ **Your Web App URL:** `https://mycommunity-calendar.netlify.app`

---

### **STEP 9: Update CORS** (2 minutes)

Now that you have your web app URL, update Railway backend:

```bash
railway variables set CORS_ORIGIN=https://mycommunity-calendar.netlify.app

# Restart the service
railway service restart
```

---

### **STEP 10: Test Everything** (15 minutes)

Open `https://mycommunity-calendar.netlify.app` and test:

**✅ Checklist:**
- [ ] App loads without errors
- [ ] Click "Register" → Create account
- [ ] Auto-login after registration
- [ ] Click "+ Create Event" → Fill form → Save
- [ ] See event in list
- [ ] Click event → View details
- [ ] Click "RSVP" → Select "Going"
- [ ] Click heart icon to favorite
- [ ] Use search bar
- [ ] Use category filter
- [ ] Click "Logout" → Login again

**Check Dashboards:**
- [ ] [sentry.io](https://sentry.io) → Check for errors
- [ ] [analytics.google.com](https://analytics.google.com) → Realtime → See yourself

---

### **STEP 11: Set Up Free Backups** (10 minutes)

#### MongoDB Atlas Already Has Backups!

MongoDB Atlas (free tier) automatically backs up your data. But let's add manual backups too:

```bash
# Go to scripts
cd /home/whitehammer/CommunityCalendar/Backend/backup-scripts

# Make executable
chmod +x *.sh

# Get MongoDB URI from Railway
railway variables

# Look for MONGO_URL or MONGODB_URI and copy it

# Test backup
export MONGODB_URI="mongodb://railway.app:27017/railway"
./mongodb-backup.sh

# Verify
ls -lh ~/backups/mongodb/

# Set up weekly backups (Sundays at 2 AM)
crontab -e

# Add (replace with YOUR MongoDB URI):
0 2 * * 0 MONGODB_URI="your_mongodb_uri" /home/whitehammer/CommunityCalendar/Backend/backup-scripts/mongodb-backup.sh >> /var/log/backup.log 2>&1
```

---

### **STEP 12: Set Up Free Monitoring** (10 minutes)

#### UptimeRobot - FREE Uptime Monitoring

1. Go to [uptimerobot.com](https://uptimerobot.com)
2. Sign up (free - no credit card!)
3. Click "Add New Monitor"
4. Settings:
   - Monitor Type: **HTTPS**
   - Friendly Name: **Community Calendar API**
   - URL: `https://your-railway-url.up.railway.app/api/health`
   - Interval: **Every 5 minutes**
5. Alert Contacts: Add your email
6. Click "Create Monitor"

Now you'll get emails if your API goes down!

#### Sentry Alerts

1. Go to [sentry.io](https://sentry.io)
2. Settings → Alerts
3. Create Alert: "High Priority Issues"
4. Action: Email me
5. Save

---

## 🎉 YOU'RE LIVE FOR FREE!

Your app is now:
✅ Live and accessible to anyone
✅ Completely free (except Google Play $25)
✅ Professional error tracking
✅ User analytics
✅ Automatic backups
✅ Uptime monitoring

---

## 📊 Free Tier Limits

**Can handle:**
- **~1,000-5,000 users/month** easily
- **~100,000 API requests/month**
- **512 MB of event data** (thousands of events)
- **5,000 errors/month** (hope you don't need this many!)

**If you outgrow free tiers:**
- Railway: $5-10/month
- MongoDB Atlas: $9/month
- Netlify: Still free!
- Total: ~$14-19/month for **unlimited** users

---

## 💰 Total Cost Breakdown

| Service | Cost |
|---------|------|
| Railway (Backend) | **$0** |
| MongoDB Atlas (Database) | **$0** |
| Netlify (Web Hosting) | **$0** |
| Google Analytics | **$0** |
| Sentry (Errors) | **$0** |
| UptimeRobot (Monitoring) | **$0** |
| SSL Certificates | **$0** (automatic) |
| Domain (optional) | $10-15/year |
| Google Play (optional) | $25 one-time |
| **TOTAL** | **$0/month** 🎉 |

---

## 📱 Bonus: Deploy to Android (FREE except $25 Play Store fee)

### Build Android APK (FREE)

In Godot:
1. **Project → Export**
2. Select **"Android"** preset
3. If you haven't set up signing yet:
   ```bash
   # Generate keystore (FREE)
   keytool -genkeypair -v -keystore ~/community-calendar.keystore \
     -alias community_calendar -keyalg RSA -keysize 2048 -validity 10000

   # Enter a strong password when prompted
   ```
4. In Godot Export settings:
   - Keystore: Browse to `~/community-calendar.keystore`
   - User: `community_calendar`
   - Password: (your keystore password)
5. Click **"Export Project"**
6. Save to: `Exports/Android/CommunityCalendar.apk`

### Test on Your Phone (FREE)

```bash
# Enable USB debugging on phone
# Connect phone to computer

# Install
adb install /home/whitehammer/CommunityCalendar/Exports/Android/CommunityCalendar.apk

# Or just copy APK to phone and install manually
```

### Submit to Google Play ($25 one-time)

1. Go to [play.google.com/console](https://play.google.com/console)
2. Pay $25 developer fee (one-time, forever)
3. Create app
4. Fill store listing
5. Upload APK
6. Submit for review

**That's the ONLY thing you pay for!**

---

## 🔄 How to Update Your App

### Update Backend:
```bash
cd Backend/nodejs-example
# Make your changes
railway up
```

### Update Web App:
```bash
# Export in Godot
cd Exports/Web
netlify deploy --prod
```

### Update Android:
```bash
# Export in Godot
# Upload new APK to Google Play Console
```

**All updates are FREE!**

---

## 📈 Monitoring Your Free Limits

### Railway:
- Dashboard: [railway.app/dashboard](https://railway.app/dashboard)
- Shows: CPU usage, memory, requests
- Free tier: $5 credit/month (renews)

### MongoDB Atlas:
- Dashboard: [cloud.mongodb.com](https://cloud.mongodb.com)
- Shows: Storage used, connections
- Free tier: 512 MB (plenty for thousands of events)

### Netlify:
- Dashboard: [app.netlify.com](https://app.netlify.com)
- Shows: Bandwidth, build minutes
- Free tier: 100 GB/month (huge!)

---

## 🎯 Quick Reference Card

Fill this out as you go:

```
✅ BACKEND
Railway URL:    https://________________________.up.railway.app/api
MongoDB URI:    mongodb://________________________

✅ WEB APP
Netlify URL:    https://________________________.netlify.app

✅ ANALYTICS
GA4 ID:         G-__________
GA4 Secret:     ________________

✅ ERROR TRACKING
Sentry DSN:     https://________________________

✅ MONITORING
UptimeRobot:    Monitoring https://________________________

✅ ACCOUNTS
Railway:        username@email.com
MongoDB:        username@email.com
Netlify:        username@email.com
Google:         username@email.com
Sentry:         username@email.com
```

---

## 🆘 Troubleshooting Free Services

### Railway Issues

**"Out of credits":**
- Wait until next month (credits renew)
- Or upgrade to $5/month plan

**Deployment failed:**
```bash
railway logs
```

**Variables not set:**
```bash
railway variables
railway variables set KEY=value
```

### MongoDB Atlas Issues

**Connection failed:**
- Check if IP whitelist includes `0.0.0.0/0`
- Go to: Security → Network Access → Edit → Allow Access from Anywhere

**Out of storage:**
- Free tier = 512 MB
- Delete old test events
- Or upgrade to $9/month for 10 GB

### Netlify Issues

**Build failed:**
- Check Godot export worked
- Make sure `index.html` exists in exported files

**Domain not working:**
- DNS propagation takes 24-48 hours
- Use the `.netlify.app` URL meanwhile

---

## 💡 Pro Tips for FREE Hosting

1. **Use Railway's free $5 credit wisely:**
   - It renews every month
   - Monitor usage in dashboard
   - Optimize API calls

2. **MongoDB free tier is generous:**
   - 512 MB = thousands of events
   - Clean up test data regularly
   - Enable indexes for speed

3. **Netlify is basically unlimited:**
   - 100 GB bandwidth/month
   - Perfect for small-medium apps
   - Free SSL included

4. **Keep free tier limits in mind:**
   - Railway: ~100,000 requests/month
   - MongoDB: 512 MB storage
   - Sentry: 5,000 errors/month
   - All plenty for starting out!

---

## 🚀 You're Done - Completely FREE!

**Total time:** ~90 minutes
**Total cost:** **$0/month** (+ $25 Google Play if you want)
**Users supported:** 1,000-5,000/month easily
**Professional features:** ✅ All included!

---

**Now go launch your app without spending a penny!** 🎉💰

Need help? All services have great free support and documentation!
