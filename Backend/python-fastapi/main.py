"""
Community Calendar - FastAPI Backend
Production-ready REST API with MongoDB
"""

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from pymongo import MongoClient
from bson import ObjectId
import os
from dotenv import load_dotenv

load_dotenv()

# Configuration
SECRET_KEY = os.getenv("JWT_SECRET", "your-secret-key-change-this")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 24
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DATABASE_NAME = "community_calendar"

# Initialize FastAPI
app = FastAPI(
    title="Community Calendar API",
    description="REST API for Community Calendar App",
    version="1.0.0"
)

# CORS
origins = os.getenv("CORS_ORIGIN", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database
client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]
users_collection = db["users"]
events_collection = db["events"]

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Security
security = HTTPBearer()

# ============ Models ============

class UserRegister(BaseModel):
    username: str = Field(min_length=3, max_length=30)
    email: EmailStr
    password: str = Field(min_length=8)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class EventCreate(BaseModel):
    title: str = Field(min_length=3, max_length=100)
    description: str = Field(default="", max_length=2000)
    category: str
    date: str  # YYYY-MM-DD
    time: str = ""
    location: str = Field(max_length=200)
    contact_info: str = Field(default="", max_length=100)
    max_capacity: int = Field(default=0, ge=0)
    tags: List[str] = Field(default=[])

class RSVPUpdate(BaseModel):
    rsvp_status: str  # "going", "interested", "not_going", ""

class FavoriteUpdate(BaseModel):
    is_favorited: bool

# ============ Helper Functions ============

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

async def get_current_user_optional(credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False))):
    if credentials is None:
        return None
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None

# ============ Routes ============

@app.get("/api/health")
async def health_check():
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}

@app.post("/api/auth/register")
async def register(user: UserRegister):
    # Check if user exists
    if users_collection.find_one({"$or": [{"email": user.email}, {"username": user.username}]}):
        raise HTTPException(status_code=409, detail="Email or username already registered")

    # Create user
    user_doc = {
        "username": user.username,
        "email": user.email,
        "password": hash_password(user.password),
        "created_at": datetime.utcnow(),
    }
    result = users_collection.insert_one(user_doc)
    user_id = str(result.inserted_id)

    # Generate token
    token = create_access_token({"sub": user_id})

    return {
        "id": user_id,
        "username": user.username,
        "email": user.email,
        "token": token
    }

@app.post("/api/auth/login")
async def login(user: UserLogin):
    # Find user
    db_user = users_collection.find_one({"email": user.email})
    if not db_user or not verify_password(user.password, db_user["password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # Update last login
    users_collection.update_one(
        {"_id": db_user["_id"]},
        {"$set": {"last_login": datetime.utcnow()}}
    )

    # Generate token
    token = create_access_token({"sub": str(db_user["_id"])})

    return {
        "id": str(db_user["_id"]),
        "username": db_user["username"],
        "email": db_user["email"],
        "token": token
    }

@app.get("/api/events")
async def get_events(
    category: Optional[str] = None,
    search: Optional[str] = None,
    user_id: Optional[str] = Depends(get_current_user_optional)
):
    query = {}
    if category:
        query["category"] = category
    if search:
        query["$or"] = [
            {"title": {"$regex": search, "$options": "i"}},
            {"description": {"$regex": search, "$options": "i"}}
        ]

    events = list(events_collection.find(query).sort("date", 1))

    # Add user-specific data
    for event in events:
        event["id"] = str(event.pop("_id"))
        event["organizer_id"] = str(event["organizer_id"])

        # User RSVP status
        rsvp = next((r for r in event.get("rsvps", []) if str(r["user_id"]) == user_id), None)
        event["user_rsvp"] = rsvp["status"] if rsvp else ""

        # Is favorited
        event["is_favorited"] = any(str(f) == user_id for f in event.get("favorites", []))

        # Remove internal fields
        event.pop("rsvps", None)
        event.pop("favorites", None)

    return events

@app.post("/api/events", status_code=201)
async def create_event(event: EventCreate, user_id: str = Depends(get_current_user)):
    user = users_collection.find_one({"_id": ObjectId(user_id)})

    event_doc = event.dict()
    event_doc.update({
        "organizer": user["username"],
        "organizer_id": ObjectId(user_id),
        "attendees_going": 0,
        "attendees_interested": 0,
        "rsvps": [],
        "favorites": [],
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    })

    result = events_collection.insert_one(event_doc)
    event_doc["id"] = str(result.inserted_id)
    event_doc.pop("_id")
    event_doc["organizer_id"] = str(event_doc["organizer_id"])

    return event_doc

@app.put("/api/events/{event_id}")
async def update_event(event_id: str, event: EventCreate, user_id: str = Depends(get_current_user)):
    db_event = events_collection.find_one({"_id": ObjectId(event_id)})

    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    if str(db_event["organizer_id"]) != user_id:
        raise HTTPException(status_code=403, detail="You can only edit your own events")

    events_collection.update_one(
        {"_id": ObjectId(event_id)},
        {"$set": {**event.dict(), "updated_at": datetime.utcnow()}}
    )

    return {"message": "Event updated"}

@app.delete("/api/events/{event_id}", status_code=204)
async def delete_event(event_id: str, user_id: str = Depends(get_current_user)):
    db_event = events_collection.find_one({"_id": ObjectId(event_id)})

    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    if str(db_event["organizer_id"]) != user_id:
        raise HTTPException(status_code=403, detail="You can only delete your own events")

    events_collection.delete_one({"_id": ObjectId(event_id)})
    return

@app.post("/api/events/{event_id}/rsvp")
async def update_rsvp(event_id: str, rsvp: RSVPUpdate, user_id: str = Depends(get_current_user)):
    event = events_collection.find_one({"_id": ObjectId(event_id)})

    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Remove old RSVP
    events_collection.update_one(
        {"_id": ObjectId(event_id)},
        {"$pull": {"rsvps": {"user_id": ObjectId(user_id)}}}
    )

    # Recalculate counts
    event = events_collection.find_one({"_id": ObjectId(event_id)})
    going_count = sum(1 for r in event.get("rsvps", []) if r["status"] == "going")
    interested_count = sum(1 for r in event.get("rsvps", []) if r["status"] == "interested")

    # Add new RSVP
    updates = {
        "attendees_going": going_count,
        "attendees_interested": interested_count
    }

    if rsvp.rsvp_status and rsvp.rsvp_status != "not_going":
        events_collection.update_one(
            {"_id": ObjectId(event_id)},
            {"$push": {"rsvps": {"user_id": ObjectId(user_id), "status": rsvp.rsvp_status}}}
        )
        if rsvp.rsvp_status == "going":
            updates["attendees_going"] += 1
        elif rsvp.rsvp_status == "interested":
            updates["attendees_interested"] += 1

    events_collection.update_one({"_id": ObjectId(event_id)}, {"$set": updates})

    return {"event_id": event_id, "rsvp_status": rsvp.rsvp_status}

@app.post("/api/events/{event_id}/favorite")
async def toggle_favorite(event_id: str, favorite: FavoriteUpdate, user_id: str = Depends(get_current_user)):
    event = events_collection.find_one({"_id": ObjectId(event_id)})

    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    if favorite.is_favorited:
        events_collection.update_one(
            {"_id": ObjectId(event_id)},
            {"$addToSet": {"favorites": ObjectId(user_id)}}
        )
    else:
        events_collection.update_one(
            {"_id": ObjectId(event_id)},
            {"$pull": {"favorites": ObjectId(user_id)}}
        )

    return {"event_id": event_id, "is_favorited": favorite.is_favorited}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=3000, reload=True)
