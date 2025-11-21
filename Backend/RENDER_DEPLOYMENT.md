# Deploy to Render - Complete Guide

This guide will walk you through deploying your Community Calendar backend to Render with MongoDB Atlas (both free tiers).

## Overview

- **Render**: Free web service hosting for your API
- **MongoDB Atlas**: Free cloud database (512 MB storage)
- **Total Cost**: $0/month 🎉

## Step 1: Set Up MongoDB Atlas (5 minutes)

### 1.1 Create MongoDB Atlas Account

1. Go to https://www.mongodb.com/cloud/atlas/register
2. Sign up with email or Google
3. Choose the **FREE** tier

### 1.2 Create a Cluster

1. Click **"Build a Database"**
2. Choose **"M0 FREE"** tier
3. Select a cloud provider and region (choose one close to you)
4. Cluster Name: `community-calendar` (or keep default)
5. Click **"Create"**

### 1.3 Create Database User

1. Under **"Security"** → **"Database Access"**
2. Click **"Add New Database User"**
3. Authentication Method: **Password**
4. Username: `communityadmin` (or your choice)
5. Password: Click **"Autogenerate Secure Password"** and **SAVE IT**
6. Database User Privileges: **Read and write to any database**
7. Click **"Add User"**

### 1.4 Allow Network Access

1. Under **"Security"** → **"Network Access"**
2. Click **"Add IP Address"**
3. Click **"Allow Access from Anywhere"** (0.0.0.0/0)
   - This is needed for Render to connect
4. Click **"Confirm"**

### 1.5 Get Connection String

1. Go to **"Database"** → **"Connect"**
2. Click **"Connect your application"**
3. Driver: **Node.js** (works for both backends)
4. Copy the connection string - it looks like:
   ```
   mongodb+srv://communityadmin:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
5. Replace `<password>` with the password you saved earlier
6. Change the database name in the URL:
   ```
   mongodb+srv://communityadmin:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/community_calendar?retryWrites=true&w=majority
   ```
7. **Save this connection string** - you'll need it for Render!

## Step 2: Choose Your Backend

You have two options (both implement the same API):

- **Option A**: Node.js (Express) - Popular, great ecosystem
- **Option B**: Python (FastAPI) - Modern, auto-documentation

Pick the one you're most comfortable with!

## Step 3: Deploy to Render

### 3.1 Push Code to GitHub

First, let's get your backend code on GitHub:

```bash
# Go to the backend you want to deploy
cd ~/CommunityCalendar/Backend/nodejs-example
# OR
cd ~/CommunityCalendar/Backend/python-fastapi

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial backend setup for Render deployment"

# Create a new repository on GitHub
# Go to: https://github.com/new
# Name it: community-calendar-backend
# Don't initialize with README

# Add remote and push
git remote add origin https://github.com/YOUR_USERNAME/community-calendar-backend.git
git branch -M main
git push -u origin main
```

### 3.2 Create Render Account

1. Go to https://render.com
2. Sign up (use GitHub login for easy integration)
3. Verify your email

### 3.3 Deploy the Web Service

#### Method A: Using Render Blueprint (Easiest)

1. In Render dashboard, click **"New +"** → **"Blueprint"**
2. Connect your GitHub repository
3. Give it access to your `community-calendar-backend` repo
4. Render will automatically detect the `render.yaml` file
5. Click **"Apply"**
6. Skip to Step 3.4 to add environment variables

#### Method B: Manual Setup

1. In Render dashboard, click **"New +"** → **"Web Service"**
2. Connect to your GitHub repository
3. Select your `community-calendar-backend` repo
4. Configure:

**For Node.js Backend:**
```
Name: community-calendar-api
Region: Oregon (or closest to you)
Branch: main
Root Directory: (leave blank or enter nodejs-example if repo root)
Environment: Node
Build Command: npm install
Start Command: npm start
Instance Type: Free
```

**For Python Backend:**
```
Name: community-calendar-api
Region: Oregon (or closest to you)
Branch: main
Root Directory: (leave blank or enter python-fastapi if repo root)
Environment: Python 3
Build Command: pip install -r requirements.txt
Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT
Instance Type: Free
```

### 3.4 Add Environment Variables

In your Render service settings, go to **"Environment"** and add:

```
NODE_ENV=production (Node.js only)
MONGODB_URI=mongodb+srv://communityadmin:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/community_calendar?retryWrites=true&w=majority
JWT_SECRET=<click "Generate" to auto-generate>
JWT_EXPIRATION=24h
CORS_ORIGIN=*
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

**Important**:
- Replace `MONGODB_URI` with your actual MongoDB Atlas connection string from Step 1.5
- Use the **"Generate"** button for `JWT_SECRET` to create a secure random value

### 3.5 Deploy

1. Click **"Create Web Service"** (or "Save Changes" if using Blueprint)
2. Render will automatically:
   - Build your application
   - Install dependencies
   - Deploy to a URL like: `https://community-calendar-api-xxxx.onrender.com`
3. Wait 2-5 minutes for the first deployment

### 3.6 Test Your API

Once deployed, test it:

```bash
# Health check
curl https://YOUR_RENDER_URL.onrender.com/api/health

# Should return:
# {"status":"ok","timestamp":"2024-11-19T..."}

# Register a test user
curl -X POST https://YOUR_RENDER_URL.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"testpass123"}'

# Should return user object with token
```

**For Python/FastAPI**: Visit `https://YOUR_RENDER_URL.onrender.com/docs` for interactive API documentation!

## Step 4: Update Your Godot App

Now connect your Godot frontend to the deployed backend:

1. Open your Godot project
2. Open `Scripts/APIManager.gd`
3. Update the `BASE_URL`:
   ```gdscript
   const BASE_URL = "https://YOUR_RENDER_URL.onrender.com/api"
   ```
4. Save and test!

## Important Notes About Free Tier

### Render Free Tier Limitations:
- ✅ 750 hours/month (enough for one service running 24/7)
- ✅ Automatic HTTPS
- ⚠️ **Spins down after 15 minutes of inactivity**
  - First request after sleep takes 30-60 seconds
  - Subsequent requests are fast
- ✅ 100 GB bandwidth/month

### MongoDB Atlas Free Tier:
- ✅ 512 MB storage (enough for ~1000s of events)
- ✅ Shared cluster
- ✅ No credit card required

### Waking Up Your Service

Since the free tier spins down, you can:

1. **Accept the delay**: First user waits 30-60 seconds
2. **Use a ping service**: Set up a cron job to ping every 10 minutes
   - Use https://cron-job.org (free)
   - Ping: `https://YOUR_RENDER_URL.onrender.com/api/health`
3. **Upgrade to paid**: $7/month keeps it always on

## Troubleshooting

### "Cannot connect to MongoDB"
- Double-check your MongoDB URI in Render environment variables
- Make sure you replaced `<password>` with actual password
- Verify IP allowlist includes 0.0.0.0/0 in MongoDB Atlas

### "Build failed"
- Check the build logs in Render dashboard
- Verify package.json or requirements.txt is correct
- Make sure you pushed the latest code to GitHub

### "Service Unavailable"
- Check the Render logs for errors
- Verify your start command is correct
- Make sure PORT environment variable is being used

### CORS Errors
- Update CORS_ORIGIN in Render environment variables
- For development: `*`
- For production: `https://yourdomain.com`

## Updating Your Backend

When you make changes:

```bash
# Make your changes
# Commit and push
git add .
git commit -m "Updated API endpoints"
git push

# Render will automatically detect the push and redeploy!
```

## Monitoring

In Render dashboard you can:
- View logs (real-time and historical)
- See metrics (requests, response times)
- Set up notifications
- Monitor health checks

## Going to Production

When you're ready for real users:

### Security Checklist:
- [ ] Update CORS_ORIGIN to your actual domain
- [ ] Review and rotate JWT_SECRET if needed
- [ ] Set up MongoDB database backups (Atlas has automatic backups)
- [ ] Add monitoring/error tracking (Sentry)
- [ ] Review rate limits
- [ ] Set up custom domain (free on Render)

### Custom Domain:
1. In Render service settings → **"Settings"** → **"Custom Domain"**
2. Add your domain: `api.yourcommunity.com`
3. Add the CNAME record to your DNS provider
4. Render automatically provisions free SSL certificate

### Scaling:
When you outgrow the free tier:
- **Starter** ($7/month): No sleeping, 512MB RAM
- **Standard** ($25/month): More resources
- Or switch to other providers like Railway, DigitalOcean

## Cost Breakdown

Current setup:
- Render Free: $0/month
- MongoDB Atlas Free: $0/month
- **Total: $0/month** ✨

Future (if needed):
- Render Starter: $7/month
- MongoDB Atlas M10: $9/month
- **Total: $16/month** (only if you get lots of users!)

## Need Help?

- Render Docs: https://render.com/docs
- MongoDB Atlas Docs: https://docs.atlas.mongodb.com
- Your backend README files have more details

---

**You're all set! Your backend is now live in the cloud!** 🚀

Your API URL: `https://community-calendar-api-xxxx.onrender.com`
