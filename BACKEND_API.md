# Backend API Specification

This document describes the REST API endpoints required for the Community Calendar app.

## Base URL

Configure in `Scripts/APIManager.gd`:
```gdscript
const BASE_URL = "http://your-backend-url.com/api"
```

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <token>
```

## Endpoints

### 1. User Registration

**POST** `/api/auth/register`

Create a new user account.

**Request Body:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Success Response (200/201):**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "created_at": "2024-11-19T12:00:00Z"
}
```

**Error Response (400):**
```json
{
  "message": "Email already exists"
}
```

---

### 2. User Login

**POST** `/api/auth/login`

Authenticate a user and receive a token.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Success Response (200):**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Response (401):**
```json
{
  "message": "Invalid credentials"
}
```

---

### 3. Fetch Events

**GET** `/api/events?category={category}&search={search}`

Retrieve a list of events, optionally filtered.

**Query Parameters:**
- `category` (optional): Filter by category (e.g., "garage_sale", "sports")
- `search` (optional): Search term for title/description

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200):**
```json
[
  {
    "id": 1,
    "title": "Community Garage Sale",
    "description": "Annual neighborhood garage sale",
    "category": "garage_sale",
    "date": "2024-12-01",
    "time": "9:00 AM",
    "location": "123 Main St, Community Center",
    "organizer": "johndoe",
    "organizer_id": 1,
    "contact_info": "555-1234",
    "created_at": "2024-11-19T10:00:00Z",
    "updated_at": "2024-11-19T10:00:00Z"
  },
  {
    "id": 2,
    "title": "Youth Soccer Game",
    "description": "Local youth soccer championship",
    "category": "sports",
    "date": "2024-11-25",
    "time": "2:00 PM",
    "location": "City Park Field 3",
    "organizer": "janedoe",
    "organizer_id": 2,
    "contact_info": "coach@example.com",
    "created_at": "2024-11-19T11:00:00Z",
    "updated_at": "2024-11-19T11:00:00Z"
  }
]
```

**Error Response (401):**
```json
{
  "message": "Unauthorized"
}
```

---

### 4. Create Event

**POST** `/api/events`

Create a new event.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "Town Hall Meeting",
  "description": "Monthly community town hall",
  "category": "town_meeting",
  "date": "2024-12-15",
  "time": "7:00 PM",
  "location": "City Hall",
  "contact_info": "555-5678"
}
```

**Success Response (200/201):**
```json
{
  "id": 3,
  "title": "Town Hall Meeting",
  "description": "Monthly community town hall",
  "category": "town_meeting",
  "date": "2024-12-15",
  "time": "7:00 PM",
  "location": "City Hall",
  "organizer": "johndoe",
  "organizer_id": 1,
  "contact_info": "555-5678",
  "created_at": "2024-11-19T12:00:00Z",
  "updated_at": "2024-11-19T12:00:00Z"
}
```

**Error Response (400):**
```json
{
  "message": "Missing required fields: title, location"
}
```

---

### 5. Update Event

**PUT** `/api/events/{id}`

Update an existing event.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "Updated Event Title",
  "description": "Updated description",
  "category": "community",
  "date": "2024-12-20",
  "time": "3:00 PM",
  "location": "New Location",
  "contact_info": "555-9999"
}
```

**Success Response (200):**
```json
{
  "id": 3,
  "title": "Updated Event Title",
  "description": "Updated description",
  "category": "community",
  "date": "2024-12-20",
  "time": "3:00 PM",
  "location": "New Location",
  "organizer": "johndoe",
  "organizer_id": 1,
  "contact_info": "555-9999",
  "created_at": "2024-11-19T12:00:00Z",
  "updated_at": "2024-11-19T13:00:00Z"
}
```

**Error Response (403):**
```json
{
  "message": "You can only edit your own events"
}
```

**Error Response (404):**
```json
{
  "message": "Event not found"
}
```

---

### 6. Delete Event

**DELETE** `/api/events/{id}`

Delete an event.

**Headers:**
```
Authorization: Bearer <token>
```

**Success Response (200/204):**
```json
{
  "message": "Event deleted successfully"
}
```

Or simply return 204 No Content with empty body.

**Error Response (403):**
```json
{
  "message": "You can only delete your own events"
}
```

**Error Response (404):**
```json
{
  "message": "Event not found"
}
```

---

## Data Models

### User
```json
{
  "id": integer,
  "username": string,
  "email": string,
  "created_at": ISO 8601 datetime
}
```

### Event
```json
{
  "id": integer,
  "title": string (required),
  "description": string (optional),
  "category": string (required),
  "date": string YYYY-MM-DD (required),
  "time": string (optional),
  "location": string (required),
  "organizer": string (username of creator),
  "organizer_id": integer (user ID of creator),
  "contact_info": string (optional),
  "created_at": ISO 8601 datetime,
  "updated_at": ISO 8601 datetime
}
```

### Valid Categories
- `general` - General Event
- `garage_sale` - Garage Sale
- `sports` - Sports Game
- `church` - Church Gathering
- `town_meeting` - Town Meeting
- `community` - Community Event
- `fundraiser` - Fundraiser
- `workshop` - Workshop
- `festival` - Festival

## Database Schema Example

### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Events Table
```sql
CREATE TABLE events (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  time VARCHAR(50),
  location VARCHAR(255) NOT NULL,
  organizer_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  contact_info VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Implementation Examples

### Node.js + Express + PostgreSQL

```javascript
// Login endpoint
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;

  const user = await db.query('SELECT * FROM users WHERE email = $1', [email]);
  if (!user.rows.length) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  const valid = await bcrypt.compare(password, user.rows[0].password_hash);
  if (!valid) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  const token = jwt.sign({ id: user.rows[0].id }, process.env.JWT_SECRET);

  res.json({
    id: user.rows[0].id,
    username: user.rows[0].username,
    email: user.rows[0].email,
    token
  });
});

// Fetch events endpoint
app.get('/api/events', authenticateToken, async (req, res) => {
  const { category, search } = req.query;

  let query = `
    SELECT e.*, u.username as organizer
    FROM events e
    JOIN users u ON e.organizer_id = u.id
    WHERE 1=1
  `;
  const params = [];

  if (category) {
    params.push(category);
    query += ` AND e.category = $${params.length}`;
  }

  if (search) {
    params.push(`%${search}%`);
    query += ` AND (e.title ILIKE $${params.length} OR e.description ILIKE $${params.length})`;
  }

  query += ' ORDER BY e.date ASC';

  const events = await db.query(query, params);
  res.json(events.rows);
});
```

### Python + Flask + SQLAlchemy

```python
@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.json
    user = User.query.filter_by(email=data['email']).first()

    if not user or not check_password_hash(user.password_hash, data['password']):
        return jsonify({'message': 'Invalid credentials'}), 401

    token = jwt.encode({
        'id': user.id,
        'exp': datetime.utcnow() + timedelta(days=30)
    }, app.config['SECRET_KEY'])

    return jsonify({
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'token': token
    })

@app.route('/api/events', methods=['GET'])
@token_required
def get_events():
    category = request.args.get('category')
    search = request.args.get('search')

    query = Event.query.join(User)

    if category:
        query = query.filter(Event.category == category)

    if search:
        query = query.filter(
            (Event.title.ilike(f'%{search}%')) |
            (Event.description.ilike(f'%{search}%'))
        )

    events = query.order_by(Event.date).all()
    return jsonify([event.to_dict() for event in events])
```

## Security Considerations

1. **Password Hashing**: Use bcrypt, argon2, or similar
2. **JWT Tokens**: Sign with strong secret, set expiration
3. **Input Validation**: Validate all inputs server-side
4. **SQL Injection**: Use parameterized queries
5. **CORS**: Configure appropriate CORS headers for web app
6. **Rate Limiting**: Implement rate limiting on all endpoints
7. **Authorization**: Verify users can only edit/delete their own events

## Testing

Use tools like Postman or curl to test endpoints:

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test123"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'

# Fetch events
curl -X GET http://localhost:3000/api/events \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create event
curl -X POST http://localhost:3000/api/events \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Event","category":"general","date":"2024-12-01","location":"Test Location"}'
```

---

**Need Help?** This API can be implemented in any backend framework: Node.js, Python, PHP, Ruby, Go, etc. Choose what you're most comfortable with!
