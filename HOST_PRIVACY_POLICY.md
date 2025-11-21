# How to Host Your Privacy Policy & Terms of Service

You have 3 files that need to be hosted online:
- `privacy_policy.html`
- `terms_of_service.html`

## Option 1: GitHub Pages (Recommended - FREE & Easy)

### Step 1: Create a GitHub Repository
```bash
cd /home/whitehammer/CommunityCalendar
git init
git add privacy_policy.html terms_of_service.html
git commit -m "Add privacy policy and terms of service"
```

### Step 2: Create GitHub Repo Online
1. Go to https://github.com/new
2. Repository name: `community-calendar-legal`
3. Make it **Public**
4. Click "Create repository"

### Step 3: Push to GitHub
```bash
# Replace YOUR_USERNAME with your GitHub username
git remote add origin https://github.com/YOUR_USERNAME/community-calendar-legal.git
git branch -M main
git push -u origin main
```

### Step 4: Enable GitHub Pages
1. Go to your repo: `https://github.com/YOUR_USERNAME/community-calendar-legal`
2. Click **Settings** tab
3. Click **Pages** in the left sidebar
4. Under "Source", select **main** branch
5. Click **Save**

### Step 5: Your URLs Will Be:
- Privacy Policy: `https://YOUR_USERNAME.github.io/community-calendar-legal/privacy_policy.html`
- Terms of Service: `https://YOUR_USERNAME.github.io/community-calendar-legal/terms_of_service.html`

---

## Option 2: Using GitHub Gist (Alternative - FREE)

1. Go to https://gist.github.com
2. Create a new gist
3. Paste the content of `privacy_policy.html`
4. Name it `privacy_policy.html`
5. Click "Create public gist"
6. Copy the "Raw" URL
7. Repeat for `terms_of_service.html`

---

## Option 3: Google Sites (FREE - No coding)

1. Go to https://sites.google.com
2. Create a new site
3. Add two pages: "Privacy Policy" and "Terms of Service"
4. Copy-paste the content from the HTML files
5. Publish the site
6. Copy the URLs

---

## After Hosting:

Update `/home/whitehammer/CommunityCalendar/Scripts/Config.gd` lines 110-113 with your URLs:

```gdscript
const PRIVACY_POLICY_URL = "https://your-actual-url.com/privacy_policy.html"
const TERMS_OF_SERVICE_URL = "https://your-actual-url.com/terms_of_service.html"
const SUPPORT_EMAIL = "okkiegaming@gmail.com"
```
