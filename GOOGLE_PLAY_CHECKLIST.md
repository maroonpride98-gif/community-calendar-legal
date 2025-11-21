# Google Play Launch Checklist - Community Calendar

## ✅ COMPLETED

### Backend Production Setup
- [x] Backend deployed to Render: https://community-calendar-backend-1.onrender.com
- [x] MongoDB Atlas configured and connected
- [x] JWT_SECRET updated to secure production value: `pmT+PgmjnKkzQatYpDHxvuMB9GeK+OVWMLtuqZSKRP8=`
- [x] API endpoints tested and working
- [x] Oklahoma zip code validation (73000-74999) implemented

### App Configuration
- [x] Config.gd production API URL configured
- [x] Password requirements set to 6+ characters
- [x] Export format changed to AAB (Android App Bundle)
- [x] Target SDK updated to 34 (required for Google Play)
- [x] Internet permissions enabled
- [x] Font sizes increased for mobile readability

## ⚠️ REQUIRED BEFORE PUBLISHING

### 1. Update Render Environment Variable (CRITICAL!)
**You must do this before users can log in:**

1. Go to https://dashboard.render.com
2. Click on **community-calendar-backend-1**
3. Click **Environment** tab
4. Update **JWT_SECRET** to: `pmT+PgmjnKkzQatYpDHxvuMB9GeK+OVWMLtuqZSKRP8=`
5. Click **Save Changes**
6. Wait for automatic redeployment (~2-3 minutes)

### 2. Create Android Keystore (REQUIRED!)
**You need a keystore to sign your app:**

```bash
cd /home/whitehammer/CommunityCalendar
keytool -genkeypair -v -keystore release.keystore -alias community_calendar -keyalg RSA -keysize 2048 -validity 10000
```

**IMPORTANT**: Save your keystore password securely! You'll need it for every update.

Then in Godot:
1. Open Project → Export
2. Select "Android" preset
3. Under "Keystore" section:
   - Debug Keystore: `/home/whitehammer/CommunityCalendar/release.keystore`
   - Debug Keystore User: `community_calendar`
   - Debug Keystore Password: [your password]
   - Release Keystore: `/home/whitehammer/CommunityCalendar/release.keystore`
   - Release Keystore User: `community_calendar`
   - Release Keystore Password: [your password]

### 3. Create App Icons (REQUIRED!)
**Google Play requires app icons:**

You need to create icons in these sizes:
- Main icon: 192x192 PNG
- Adaptive foreground: 432x432 PNG (with transparency)
- Adaptive background: 432x432 PNG

Place them in `/home/whitehammer/CommunityCalendar/` and update export_presets.cfg:
```
launcher_icons/main_192x192="res://icon_192.png"
launcher_icons/adaptive_foreground_432x432="res://icon_adaptive_fg.png"
launcher_icons/adaptive_background_432x432="res://icon_adaptive_bg.png"
```

### 4. Privacy Policy (REQUIRED!)
**Google Play requires a privacy policy URL:**

Current placeholder in Config.gd:
```
PRIVACY_POLICY_URL = "https://yourcommunity.com/privacy"
TERMS_OF_SERVICE_URL = "https://yourcommunity.com/terms"
SUPPORT_EMAIL = "support@yourcommunity.com"
```

**You need to:**
1. Create a privacy policy (use a generator like https://www.privacypolicygenerator.info/)
2. Host it online (GitHub Pages, Google Sites, or your own website)
3. Update Config.gd with the real URLs
4. Create terms of service
5. Set up a support email address

**Privacy Policy Must Include:**
- What data you collect (email, username, zip code, event data)
- How you use it (account creation, event management)
- Data storage (MongoDB Atlas)
- User rights (deletion requests)
- Contact information

### 5. Google Play Console Setup

#### A. Create Google Play Developer Account
1. Go to https://play.google.com/console
2. Pay $25 one-time registration fee
3. Complete developer profile

#### B. Create New App
1. Click "Create app"
2. Fill in details:
   - App name: **Community Calendar**
   - Default language: **English (United States)**
   - App or game: **App**
   - Free or paid: **Free**
   - Declarations: Check required boxes

#### C. Store Listing
**Required information:**

**App details:**
- Short description (80 characters):
  ```
  Oklahoma community events calendar. Discover local events by zip code.
  ```

- Full description (4000 characters):
  ```
  Community Calendar is your go-to app for discovering local events in Oklahoma!

  🎉 FEATURES:
  • Browse upcoming community events
  • Filter by location using Oklahoma zip codes (73000-74999)
  • RSVP to events you want to attend
  • Mark events as favorites
  • Share events with friends
  • Create and manage your own events

  📍 OKLAHOMA FOCUSED:
  Built specifically for Oklahoma communities, ensuring you only see relevant local events.

  🔒 SECURE & PRIVATE:
  Your data is protected with enterprise-level security. We only collect what's necessary
  to provide you with a great experience.

  ✨ MODERN DESIGN:
  Sleek, cyberpunk-inspired interface that's easy to use and visually stunning.

  Get started today and never miss another community event!
  ```

- App icon: **512x512 PNG** (high-res version)
- Feature graphic: **1024x500 PNG**
- Phone screenshots: **At least 2, up to 8** (minimum 320px on shortest side)
- Category: **Events**
- Contact details: Your email, website (optional), phone (optional)
- Privacy policy URL: **Your hosted privacy policy URL**

#### D. Content Rating
1. Complete questionnaire
2. Select "Events" category
3. Answer questions about:
   - Violence
   - Sexual content
   - Profanity
   - Controlled substances
   - User-generated content (YES - users can create events)
   - User interaction features (YES - users can RSVP/share)

#### E. Target Audience
1. Select age group: **13+** (or adjust based on your target)
2. Confirm age-appropriate content

#### F. App Content
Complete these sections:
- **App access**: All features available to all users
- **Ads**: Select if you'll show ads (currently: NO)
- **Data safety**:
  - Data collected: Email, username, location (zip code)
  - Data usage: Account creation, event management
  - Data sharing: No third-party sharing
  - Encryption: Data encrypted in transit (HTTPS)
  - Deletion: Users can request account deletion

#### G. Select Countries
- Start with: **United States** only
- Can expand later

### 6. Build & Export

#### In Godot:
1. Open your project in Godot
2. Go to **Project → Export**
3. Select **Android** preset
4. Click **Export Project**
5. Choose location: `/home/whitehammer/CommunityCalendar/Exports/Android/CommunityCalendar.aab`
6. Select **Release** mode
7. Click **Save**

#### Upload to Google Play:
1. In Google Play Console, go to **Production**
2. Click **Create new release**
3. Upload `CommunityCalendar.aab`
4. Add release notes:
   ```
   🎉 Initial release!

   • Browse Oklahoma community events
   • RSVP and manage your calendar
   • Create and share events
   • Filter by zip code
   ```
5. Click **Save** → **Review release** → **Start rollout to Production**

### 7. Testing Before Launch

**Test these features:**
- [ ] User registration with Oklahoma zip code
- [ ] User login
- [ ] Browse events
- [ ] Create event
- [ ] RSVP to event
- [ ] Mark event as favorite
- [ ] Share event
- [ ] Forgot password
- [ ] Logout
- [ ] Network error handling
- [ ] Offline behavior

**Test on:**
- [ ] Physical Android device (recommended)
- [ ] Different screen sizes
- [ ] Slow network conditions

### 8. Marketing Assets Needed

Create these for your store listing:
- [ ] App icon (512x512)
- [ ] Feature graphic (1024x500)
- [ ] 3-5 phone screenshots showing:
  - Login screen
  - Event list
  - Event details
  - Create event
  - User profile

**Screenshot tips:**
- Use actual app screenshots
- Add device frames for polish
- Show key features
- Keep text readable

## 📋 POST-LAUNCH CHECKLIST

After your app is live:

### Monitor
- [ ] Check Google Play Console for crash reports
- [ ] Monitor MongoDB Atlas for database usage
- [ ] Check Render logs for backend errors
- [ ] Watch for user reviews and respond

### Update Schedule
- [ ] Fix critical bugs within 24 hours
- [ ] Regular updates every 2-4 weeks
- [ ] Increment version code for each release

### Analytics
- [ ] Track user registrations
- [ ] Monitor event creation
- [ ] Analyze RSVP rates
- [ ] Track feature usage

### Security
- [ ] Rotate JWT_SECRET every 6 months
- [ ] Update dependencies quarterly
- [ ] Monitor for security vulnerabilities
- [ ] Keep MongoDB Atlas IP whitelist updated

## 🚀 ESTIMATED TIMELINE

- **Account setup**: 1 hour
- **Create assets** (icons, screenshots): 2-4 hours
- **Privacy policy**: 1-2 hours
- **Store listing**: 1-2 hours
- **Testing**: 2-4 hours
- **Google review**: 1-3 days
- **Total**: ~1-2 weeks

## 📞 SUPPORT RESOURCES

- Google Play Console Help: https://support.google.com/googleplay/android-developer
- Godot Android Export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Render Support: https://render.com/docs

## ⚠️ CRITICAL REMINDERS

1. **Never commit your keystore to Git!** Add `*.keystore` to `.gitignore`
2. **Backup your keystore!** You cannot update your app without it
3. **Test on real devices** before publishing
4. **Update JWT_SECRET in Render** or users can't log in
5. **Host your privacy policy** before submitting
6. **Version code must increment** with each update (currently: 1)

---

**Current Status:**
- Package: `com.community.calendar`
- Version: 1.0 (code: 1)
- Format: AAB (Android App Bundle)
- Target SDK: 34 (Android 14)
- Min SDK: 21 (Android 5.0)

**Next immediate steps:**
1. Update Render JWT_SECRET
2. Create keystore
3. Create app icons
4. Host privacy policy
5. Build AAB file
6. Create Google Play Developer account
