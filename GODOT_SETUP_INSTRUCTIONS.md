# Godot Android Export Setup - Final Steps

Your Android SDK is ready! Now configure Godot:

## Step 1: Configure Editor Settings

1. In Godot, go to **Editor** → **Editor Settings**
2. In the search box, type "android"
3. Under **Export → Android** section, set:

   - **Android SDK Path**: `/home/whitehammer/Android/Sdk`
   - **Java SDK Path**: `/usr/lib/jvm/java-17-openjdk-amd64`

4. Click **Close**

## Step 2: Install Android Build Template

1. Go to **Project** menu → **Install Android Build Template**
2. Click **Install**
3. Wait for it to complete (~5 seconds)

## Step 3: Configure Keystore in Export Settings

1. Go to **Project** → **Export**
2. Select **Android** preset
3. Scroll down to **Keystore** section
4. Fill in:

   **Debug Keystore:**
   - Path: `/home/whitehammer/CommunityCalendar/release.keystore`
   - User: `community_calendar`
   - Password: `[your keystore password]`

   **Release Keystore:**
   - Path: `/home/whitehammer/CommunityCalendar/release.keystore`
   - User: `community_calendar`
   - Password: `[your keystore password]`

5. **Don't close yet!**

## Step 4: Export Android AAB

1. Still in the Export dialog, with **Android** selected
2. Click **Export Project** button at the bottom
3. Navigate to: `/home/whitehammer/CommunityCalendar/Exports/Android/`
4. Filename: `CommunityCalendar.aab`
5. **Export Mode**: Select **Release**
6. Click **Save**
7. Wait for export to complete (~1-3 minutes)

## Step 5: Export Web Build

1. In Export dialog, select **Web** preset
2. Click **Export Project**
3. Navigate to: `/home/whitehammer/CommunityCalendar/Exports/Web/`
4. Filename: `index.html`
5. Click **Save**
6. Wait for export to complete (~30 seconds)

---

## ✅ Your Builds Will Be Ready At:

- **Android (Google Play)**: `/home/whitehammer/CommunityCalendar/Exports/Android/CommunityCalendar.aab`
- **Web**: `/home/whitehammer/CommunityCalendar/Exports/Web/index.html`

---

## 🚀 Next Steps After Export:

### For Google Play:
1. Go to https://play.google.com/console
2. Create your app listing
3. Upload `CommunityCalendar.aab`
4. Fill in store details
5. Submit for review!

### For Web:
1. Upload the `/Exports/Web/` folder to any web hosting
2. Options:
   - GitHub Pages
   - Netlify (free)
   - Vercel (free)
   - itch.io

---

## ⚠️ CRITICAL: Update Render JWT_SECRET!

**Before publishing, update your backend:**

1. Go to: https://dashboard.render.com
2. Click: community-calendar-backend-1
3. Environment tab
4. Add/Update: `JWT_SECRET = pmT+PgmjnKkzQatYpDHxvuMB9GeK+OVWMLtuqZSKRP8=`
5. Save Changes

**Without this, users cannot log in!**

---

## Testing Checklist:

Before publishing:
- [ ] Test user registration with Oklahoma zip code
- [ ] Test login
- [ ] Test creating an event
- [ ] Test RSVP to event
- [ ] Test favorite/share event
- [ ] Test on actual Android device (if possible)

---

Good luck with your launch! 🎉
