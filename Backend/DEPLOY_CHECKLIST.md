# Render Deployment Checklist

Use this checklist to deploy your backend to Render step by step.

## ☐ Phase 1: MongoDB Atlas Setup (5 minutes)

- [ ] Go to https://www.mongodb.com/cloud/atlas/register
- [ ] Create free account
- [ ] Create M0 FREE cluster
- [ ] Create database user (save username & password!)
- [ ] Allow network access from anywhere (0.0.0.0/0)
- [ ] Get connection string
- [ ] Replace `<password>` in connection string
- [ ] Change database name to `community_calendar`
- [ ] Save final connection string somewhere safe

**Your MongoDB URI should look like:**
```
mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/community_calendar?retryWrites=true&w=majority
```

## ☐ Phase 2: Choose Your Backend

Pick ONE:
- [ ] **Node.js Backend** (`Backend/nodejs-example/`)
- [ ] **Python Backend** (`Backend/python-fastapi/`)

Both implement the same API - choose what you're comfortable with!

## ☐ Phase 3: Push to GitHub

```bash
# Navigate to your chosen backend
cd ~/CommunityCalendar/Backend/nodejs-example  # or python-fastapi

# Initialize git
git init
git add .
git commit -m "Initial backend for Render deployment"

# Create repo on GitHub: https://github.com/new
# Name: community-calendar-backend

# Push to GitHub
git remote add origin https://github.com/YOUR_USERNAME/community-calendar-backend.git
git branch -M main
git push -u origin main
```

- [ ] Code pushed to GitHub
- [ ] Repository is public (or Render has access)

## ☐ Phase 4: Deploy to Render

- [ ] Go to https://render.com
- [ ] Sign up (use GitHub login)
- [ ] Click "New +" → "Web Service"
- [ ] Connect your GitHub repository
- [ ] Configure service:

### Node.js Settings:
```
Name: community-calendar-api
Environment: Node
Build Command: npm install
Start Command: npm start
```

### Python Settings:
```
Name: community-calendar-api
Environment: Python 3
Build Command: pip install -r requirements.txt
Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT
```

## ☐ Phase 5: Environment Variables

Add these in Render → Environment:

- [ ] `MONGODB_URI` = (your MongoDB Atlas connection string)
- [ ] `JWT_SECRET` = (click "Generate")
- [ ] `JWT_EXPIRATION` = `24h`
- [ ] `CORS_ORIGIN` = `*`
- [ ] `NODE_ENV` = `production` (Node.js only)

## ☐ Phase 6: Deploy & Test

- [ ] Click "Create Web Service"
- [ ] Wait for build to complete (2-5 minutes)
- [ ] Copy your Render URL: `https://your-service.onrender.com`
- [ ] Test health endpoint:
```bash
curl https://your-service.onrender.com/api/health
```
- [ ] Test registration:
```bash
curl -X POST https://your-service.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test123456"}'
```

## ☐ Phase 7: Connect Godot App

- [ ] Open Godot project
- [ ] Edit `Scripts/APIManager.gd`
- [ ] Update `BASE_URL` to your Render URL:
```gdscript
const BASE_URL = "https://your-service.onrender.com/api"
```
- [ ] Save and test the app!

## ☐ Bonus: Keep Service Awake (Optional)

Since free tier sleeps after 15 minutes:

- [ ] Go to https://cron-job.org
- [ ] Create free account
- [ ] Create new cron job
- [ ] URL: `https://your-service.onrender.com/api/health`
- [ ] Schedule: Every 10 minutes
- [ ] This prevents your service from sleeping!

## 🎉 You're Done!

Your backend is now live at: `https://your-service.onrender.com`

### What You Built:
✅ Full REST API with authentication
✅ Event management system
✅ RSVP and favorites functionality
✅ Free cloud hosting
✅ Free cloud database
✅ Automatic HTTPS

### Next Steps:
- Test all features in your Godot app
- Share with friends!
- Monitor usage in Render dashboard
- Check MongoDB Atlas for data

## Need Help?

See `RENDER_DEPLOYMENT.md` for detailed instructions and troubleshooting.

---

**Total Time:** ~15-20 minutes
**Total Cost:** $0/month 💰
