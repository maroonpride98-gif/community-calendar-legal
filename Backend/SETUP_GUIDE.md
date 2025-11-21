# Backend Setup Guide

Both Node.js and Python FastAPI backends are now ready to use! Here's how to get them running.

## What's Been Set Up

✅ **Node.js Backend** (Express + MongoDB)
- All dependencies installed
- Environment configured with secure JWT secret
- Complete with models, routes, and middleware
- Location: `Backend/nodejs-example/`

✅ **Python Backend** (FastAPI + MongoDB)
- Requirements file ready
- Environment configured
- Single-file implementation
- Location: `Backend/python-fastapi/`

## Next Steps

### 1. Install and Start MongoDB

You need a MongoDB database for either backend to work. Choose one option:

#### Option A: Install MongoDB Locally

**Ubuntu/Debian:**
```bash
# Install MongoDB
sudo apt-get update
sudo apt-get install -y mongodb

# Start MongoDB
sudo systemctl start mongodb
sudo systemctl enable mongodb

# Verify it's running
sudo systemctl status mongodb
```

**Or install MongoDB Community Edition:**
```bash
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```

#### Option B: Use MongoDB Atlas (Free Cloud Database)

1. Go to https://www.mongodb.com/cloud/atlas/register
2. Create a free account
3. Create a new cluster (free tier is fine)
4. Click "Connect" > "Connect your application"
5. Copy the connection string
6. Update the `MONGODB_URI` in both `.env` files:
   ```
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/community_calendar
   ```

### 2. Run the Node.js Backend

```bash
cd ~/CommunityCalendar/Backend/nodejs-example

# Development mode (auto-reload on changes)
npm run dev

# Or production mode
npm start
```

Server will start at http://localhost:3000

**Test it:**
```bash
# Health check
curl http://localhost:3000/api/health

# Register a user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
```

### 3. Run the Python FastAPI Backend

```bash
cd ~/CommunityCalendar/Backend/python-fastapi

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run server
python main.py

# Or use uvicorn directly
uvicorn main:app --reload --port 3000
```

Server will start at http://localhost:3000

**Interactive API docs:** http://localhost:3000/docs

**Test it:**
```bash
# Health check
curl http://localhost:3000/api/health

# Register a user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
```

## Choose Your Backend

Both backends implement the exact same API specification from `BACKEND_API.md`. Choose based on your preference:

### Node.js Backend
**Pros:**
- Very popular for web APIs
- Huge ecosystem (npm packages)
- Great for JavaScript developers
- Excellent documentation and community

**Cons:**
- May use more memory for large workloads
- Callback-heavy code (though promises/async help)

### Python FastAPI Backend
**Pros:**
- Automatic interactive API documentation
- Type hints and validation with Pydantic
- Very fast (built on Starlette/Uvicorn)
- Clean, modern Python code
- Great for data science integration

**Cons:**
- Smaller ecosystem compared to Node.js
- Fewer deployment options

## API Endpoints

Both backends support these endpoints:

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Events
- `GET /api/events` - Get all events (with optional filters)
- `GET /api/events/:id` - Get single event
- `POST /api/events` - Create event (requires auth)
- `PUT /api/events/:id` - Update event (requires auth)
- `DELETE /api/events/:id` - Delete event (requires auth)
- `POST /api/events/:id/rsvp` - RSVP to event (requires auth)
- `POST /api/events/:id/favorite` - Toggle favorite (requires auth)

## Connect to Godot Frontend

Once your backend is running, update the Godot app to use it:

1. Open `Scripts/APIManager.gd` in your Godot project
2. Update the `BASE_URL`:
   ```gdscript
   const BASE_URL = "http://localhost:3000/api"
   ```
3. Run your Godot app and test the integration!

## Production Deployment

When you're ready to deploy:

### Free Hosting Options

1. **Railway** (recommended for beginners)
   - Free tier available
   - Supports both Node.js and Python
   - Automatic deployments from Git
   - https://railway.app

2. **Render**
   - Free tier with limitations
   - Easy to set up
   - https://render.com

3. **Heroku** (limited free tier)
   - Popular platform
   - Good documentation
   - https://heroku.com

4. **DigitalOcean App Platform**
   - $5/month minimum
   - Very reliable
   - https://www.digitalocean.com/products/app-platform

### Deployment Checklist

Before deploying:
- [ ] Change JWT_SECRET to a new random value
- [ ] Update CORS_ORIGIN to your actual domain
- [ ] Set NODE_ENV=production (Node.js)
- [ ] Use MongoDB Atlas or managed MongoDB
- [ ] Enable HTTPS
- [ ] Set up database backups
- [ ] Add error monitoring (Sentry, etc.)

## Troubleshooting

### "Cannot connect to MongoDB"
- Make sure MongoDB is running: `sudo systemctl status mongodb`
- Check your MONGODB_URI in .env
- Try using MongoDB Atlas instead

### Port already in use
- Change the PORT in .env to something else (e.g., 3001)
- Or kill the process using port 3000: `sudo lsof -ti:3000 | xargs kill`

### Dependencies not installing
- **Node.js:** Make sure you have Node 16+ installed: `node --version`
- **Python:** Make sure you have Python 3.8+ installed: `python3 --version`

## Need Help?

- Check the README in each backend folder for detailed instructions
- Review the BACKEND_API.md for API specification
- Test endpoints using the interactive docs (Python) or Postman/curl (Node.js)

---

**Ready to build something awesome!** 🚀
