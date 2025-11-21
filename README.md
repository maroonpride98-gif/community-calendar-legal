# Community Calendar - Local Events App

A mobile and web application built with Godot 4.3 for posting and discovering local community events.

## Features

- **User Authentication**: Full login/register system with JWT token support
- **Event Management**: Create, view, edit, and delete community events
- **Event Categories**:
  - General Events
  - Garage Sales
  - Sports Games
  - Church Gatherings
  - Town Meetings
  - Community Events
  - Fundraisers
  - Workshops
  - Festivals
- **Search & Filter**: Search events by keyword and filter by category
- **Responsive UI**: Optimized for both mobile touch screens and web browsers
- **Real-time Sync**: Events sync with backend server

## Project Structure

```
CommunityCalendar/
├── Assets/           # Theme and visual assets
├── Scenes/           # Main game scenes
├── Scripts/          # GDScript files
│   ├── APIManager.gd       # Backend API integration
│   ├── Event.gd            # Event data model
│   ├── User.gd             # User data model
│   ├── Main.gd             # Main navigation controller
│   ├── LoginScreen.gd      # Authentication logic
│   ├── EventListScreen.gd  # Event browsing
│   ├── EventDetailScreen.gd # Event details view
│   ├── EventFormScreen.gd   # Create/Edit events
│   └── EventItem.gd        # Event list item component
├── UI/               # UI scene files (.tscn)
├── Exports/          # Built applications (Android, Web)
└── project.godot     # Godot project configuration
```

## Setup Instructions

### 1. Backend Setup

You need to set up a backend API server. Update the `BASE_URL` in `Scripts/APIManager.gd`:

```gdscript
const BASE_URL = "http://localhost:3000/api"  # Change to your backend URL
```

See `BACKEND_API.md` for required API endpoints.

### 2. Godot Editor

1. Install Godot 4.3 from [godotengine.org](https://godotengine.org/)
2. Open the project by selecting the `project.godot` file
3. The project will open in the Godot Editor

### 3. Testing

1. Run the project in Godot (F5)
2. Test on different screen sizes using the viewport size override
3. For mobile testing, export to Android or use Godot Remote app

### 4. Export

#### Web (HTML5)
1. Go to Project → Export
2. Select "Web" preset
3. Click "Export Project"
4. Choose output location in `Exports/Web/`
5. Upload to a web server or test locally

#### Android
1. Install Android SDK and export templates
2. Go to Project → Export
3. Select "Android" preset
4. Configure signing keys (required for release)
5. Click "Export Project"
6. Install APK on Android device

## Configuration

### Display Settings

Mobile-optimized settings in `project.godot`:
- Viewport: 1080x1920 (portrait)
- Stretch mode: canvas_items
- Aspect: expand
- Orientation: portrait

### Backend API

Edit `Scripts/APIManager.gd` to configure:
- API base URL
- Authentication token storage
- Request/response handling

## Usage

### For Users

1. **Register/Login**: Create an account or login
2. **Browse Events**: View all community events on the main screen
3. **Filter**: Use category dropdown to filter by event type
4. **Search**: Type in search bar to find specific events
5. **View Details**: Tap any event to see full details
6. **Create Event**: Tap "+ Create Event" button
7. **Edit/Delete**: Open event details, tap Edit or Delete

### For Developers

#### Adding New Event Categories

Edit `Scripts/Event.gd`:

```gdscript
const CATEGORIES = {
    "your_category": "Display Name",
    # ... existing categories
}
```

#### Customizing Theme

Edit `Assets/theme.tres` to change:
- Colors
- Font sizes
- Button styles
- Input field appearance

#### Adding New Screens

1. Create scene in `UI/` folder
2. Create script in `Scripts/` folder
3. Add navigation in `Scripts/Main.gd`

## Backend Requirements

The app requires a REST API backend with the following endpoints:

### Authentication
- `POST /api/auth/register` - Create new user account
- `POST /api/auth/login` - User login

### Events
- `GET /api/events` - List all events (with optional category & search params)
- `POST /api/events` - Create new event
- `PUT /api/events/{id}` - Update event
- `DELETE /api/events/{id}` - Delete event

See `BACKEND_API.md` for detailed API specifications.

## Dependencies

- Godot 4.3 or higher
- Backend API server (Node.js, Python, PHP, etc.)
- For Android: Android SDK
- For Web: Web server (Apache, Nginx, or any static host)

## Production Deployment 🚀

This app is **production-ready** with the following features:

### ✅ Production Features

- **Secure Authentication**: JWT tokens, password validation, email verification support
- **Input Validation**: All forms have comprehensive validation and sanitization
- **Error Handling**: Graceful error handling with user-friendly messages
- **Offline Support**: Smart caching for offline capability
- **Analytics Hooks**: Built-in analytics tracking (integrate with your provider)
- **Configuration System**: Easy environment switching (Demo/Dev/Staging/Production)
- **Rate Limiting**: Client-side request throttling
- **Security**: XSS prevention, input sanitization, secure token storage
- **PWA Support**: Progressive Web App with offline mode
- **Responsive Design**: Optimized for mobile and web

### 📚 Production Documentation

- **[PRODUCTION_SETUP.md](PRODUCTION_SETUP.md)** - Complete guide to deploying for production
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Pre-launch checklist
- **[BACKEND_API.md](BACKEND_API.md)** - Backend API specifications

### ⚙️ Quick Production Setup

1. **Configure Environment**:
   - Open `Scripts/Config.gd`
   - Set `current_environment = Environment.PRODUCTION`
   - Update API URLs, support email, and legal URLs

2. **Set Up Backend**:
   - Deploy backend API (Node.js, Python, PHP, etc.)
   - Implement required endpoints (see BACKEND_API.md)
   - Configure HTTPS and CORS

3. **Build App**:
   - **Android**: Export with production keystore
   - **Web**: Export with PWA enabled

4. **Deploy**:
   - **Web**: Netlify, Vercel, AWS S3, or self-hosted
   - **Android**: Google Play Store

5. **Configure Analytics** (Optional):
   - Integrate `Scripts/Analytics.gd` with your provider
   - Enable in `Scripts/Config.gd`

See **[PRODUCTION_SETUP.md](PRODUCTION_SETUP.md)** for detailed instructions.

## Roadmap

Implemented features:
- ✅ User authentication with JWT
- ✅ Event RSVP/attendance tracking
- ✅ Offline mode with local caching
- ✅ Social sharing
- ✅ Analytics integration hooks
- ✅ Production-ready security
- ✅ PWA support

Future enhancements:
- [ ] Image uploads for events
- [ ] User profiles
- [ ] Calendar view (grid/list toggle)
- [ ] Push notifications for new events
- [ ] Map integration for event locations
- [ ] Event comments/discussion
- [ ] Recurring events

## Architecture

### Core Systems

- **Config.gd**: Centralized configuration (environments, feature flags, security settings)
- **APIManager.gd**: Production-ready API client (error handling, caching, retry logic)
- **Analytics.gd**: Event tracking system (integrate with Google Analytics, Firebase, etc.)
- **DataCache.gd**: Offline caching and performance optimization
- **LegalScreen.gd**: Privacy policy and terms of service viewer

### Security Features

- Password strength validation (configurable requirements)
- Email format validation
- Input sanitization (XSS prevention)
- Rate limiting (client-side)
- Secure token storage
- Session management
- Comprehensive error handling

## License

This project is provided as-is for educational and community purposes.

## Support

For issues or questions:
- Check the Godot documentation: https://docs.godotengine.org/
- Review `BACKEND_API.md` for API requirements
- Test API endpoints using tools like Postman

## Contributing

To contribute:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on both mobile and web
5. Submit a pull request

---

Built with Godot 4.3 | Designed for Community Engagement
