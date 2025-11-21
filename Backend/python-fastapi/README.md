# Community Calendar - Python FastAPI Backend

Production-ready REST API for the Community Calendar app built with FastAPI and MongoDB.

## Features

✅ **User Authentication** - JWT-based authentication with bcrypt password hashing
✅ **Event CRUD** - Create, read, update, delete events
✅ **RSVP System** - Users can RSVP to events (going/interested/not going)
✅ **Favorites** - Users can favorite events
✅ **Search & Filter** - Search events by keyword, filter by category
✅ **Security** - CORS, input validation with Pydantic
✅ **Auto Documentation** - Interactive API docs at `/docs`

## Quick Start

### 1. Install Dependencies

```bash
# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Set Up Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env`:

```env
MONGODB_URI=mongodb://localhost:27017/community_calendar
JWT_SECRET=your_super_secret_key_change_this
CORS_ORIGIN=http://localhost:8000,https://yourdomain.com
```

### 3. Set Up MongoDB

**Option A: Local MongoDB**

```bash
# Install MongoDB
# Ubuntu/Debian:
sudo apt-get install mongodb

# macOS:
brew install mongodb-community

# Start MongoDB
mongod
```

**Option B: MongoDB Atlas (Cloud)**

1. Create account at [mongodb.com/cloud/atlas](https://mongodb.com/cloud/atlas)
2. Create a cluster
3. Get connection string
4. Update `MONGODB_URI` in `.env`

### 4. Start Server

**Development:**

```bash
python main.py
# Or use uvicorn directly:
uvicorn main:app --reload --port 3000
```

**Production:**

```bash
uvicorn main:app --host 0.0.0.0 --port 3000
```

Server will start on `http://localhost:3000`

## API Documentation

FastAPI provides automatic interactive API documentation:

- **Swagger UI**: http://localhost:3000/docs
- **ReDoc**: http://localhost:3000/redoc

## API Endpoints

### Authentication

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

**Response:**
```json
{
  "id": "user_id",
  "username": "john_doe",
  "email": "john@example.com",
  "token": "jwt_token_here"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

### Events

#### Get All Events
```http
GET /api/events
# Optional query parameters:
GET /api/events?category=sports&search=soccer
```

#### Create Event (Requires Auth)
```http
POST /api/events
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Community BBQ",
  "description": "Annual summer BBQ event",
  "category": "community",
  "date": "2024-07-15",
  "time": "2:00 PM - 6:00 PM",
  "location": "Central Park",
  "contact_info": "555-1234",
  "max_capacity": 100,
  "tags": ["food", "family-friendly"]
}
```

#### Update Event (Requires Auth)
```http
PUT /api/events/{event_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Updated Title",
  ...
}
```

#### Delete Event (Requires Auth)
```http
DELETE /api/events/{event_id}
Authorization: Bearer {token}
```

#### RSVP to Event (Requires Auth)
```http
POST /api/events/{event_id}/rsvp
Authorization: Bearer {token}
Content-Type: application/json

{
  "rsvp_status": "going"  // "going" | "interested" | "not_going" | ""
}
```

#### Toggle Favorite (Requires Auth)
```http
POST /api/events/{event_id}/favorite
Authorization: Bearer {token}
Content-Type: application/json

{
  "is_favorited": true
}
```

## Project Structure

```
Backend/python-fastapi/
├── main.py              # Main application file (models, routes, logic)
├── requirements.txt     # Python dependencies
├── .env.example         # Environment variables template
├── .env                 # Your local environment (not in git)
└── README.md            # This file
```

## Deployment

### Deploy to Heroku

1. Install Heroku CLI
2. Create Heroku app:
   ```bash
   heroku create your-app-name
   ```
3. Set environment variables:
   ```bash
   heroku config:set JWT_SECRET=your_secret
   heroku config:set MONGODB_URI=your_mongodb_uri
   ```
4. Create `Procfile`:
   ```
   web: uvicorn main:app --host 0.0.0.0 --port $PORT
   ```
5. Deploy:
   ```bash
   git push heroku main
   ```

### Deploy to Railway

1. Install Railway CLI
2. Initialize:
   ```bash
   railway init
   ```
3. Deploy:
   ```bash
   railway up
   ```

### Deploy to DigitalOcean App Platform

1. Connect your GitHub repo
2. Set environment variables in dashboard
3. Deploy automatically on push

### Deploy with Docker

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]
```

Build and run:

```bash
docker build -t community-calendar-api .
docker run -p 3000:3000 --env-file .env community-calendar-api
```

## Security Checklist

Before deploying to production:

- [ ] Change `JWT_SECRET` to a strong random value
- [ ] Use HTTPS (TLS/SSL) for all requests
- [ ] Set proper `CORS_ORIGIN` (not `*`)
- [ ] Keep dependencies updated
- [ ] Use MongoDB connection string with authentication
- [ ] Don't commit `.env` file
- [ ] Implement rate limiting (using slowapi or similar)
- [ ] Set up error monitoring (Sentry, etc.)
- [ ] Configure database backups
- [ ] Use environment variables for all secrets

## Production Tips

1. **Use a process manager** like Supervisor or systemd:
   ```ini
   [program:community-calendar]
   command=/path/to/venv/bin/uvicorn main:app --host 0.0.0.0 --port 3000
   directory=/path/to/app
   autostart=true
   autorestart=true
   ```

2. **Enable MongoDB Replica Set** for production reliability

3. **Set up reverse proxy** (Nginx) for better performance:
   ```nginx
   server {
       listen 80;
       server_name yourdomain.com;

       location / {
           proxy_pass http://127.0.0.1:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

4. **Enable database backups**:
   ```bash
   mongodump --uri="mongodb://..." --out=/backup/directory
   ```

5. **Add rate limiting** to prevent abuse:
   ```bash
   pip install slowapi
   ```

   Then in `main.py`:
   ```python
   from slowapi import Limiter, _rate_limit_exceeded_handler
   from slowapi.util import get_remote_address
   from slowapi.errors import RateLimitExceeded

   limiter = Limiter(key_func=get_remote_address)
   app.state.limiter = limiter
   app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

   @app.get("/api/events")
   @limiter.limit("100/minute")
   async def get_events(...):
       ...
   ```

## Development Tools

```bash
# Format code
pip install black
black main.py

# Type checking
pip install mypy
mypy main.py

# Linting
pip install pylint
pylint main.py
```

## Testing

```bash
# Install pytest
pip install pytest httpx

# Run tests
pytest
```

Example test file `test_main.py`:

```python
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_register():
    response = client.post("/api/auth/register", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpass123"
    })
    assert response.status_code == 200
    assert "token" in response.json()
```

## Support

For issues, refer to:
- FastAPI docs: https://fastapi.tiangolo.com
- MongoDB docs: https://docs.mongodb.com
- Pydantic docs: https://docs.pydantic.dev

---

Built with ❤️ for Community Calendar
