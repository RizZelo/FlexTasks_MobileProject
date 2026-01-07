# Meeting Place Feature Setup Instructions

## Overview
I've successfully added a meeting place feature to your FlexTasks app with **OpenStreetMap (Leaflet)** integration. The feature includes:
- Meeting place autocomplete search (FREE - No API key needed!)
- Location details with coordinates
- OpenStreetMap link in task details

**✨ Advantages of using OpenStreetMap:**
- 100% FREE - No API key required
- No billing or usage limits
- Open-source and community-driven
- Works worldwide
- No credit card needed

---

## 🔧 Setup Steps

### 1. Backend Setup

#### Install Dependencies
Navigate to the backend folder and install the packages:

```bash
cd backend
npm install
```

This will install:
- `axios` - For making HTTP requests to OpenStreetMap API
- `express` - Web server framework
- `cors` - Cross-origin resource sharing

#### No API Key Needed! 🎉

Unlike Google Maps, OpenStreetMap's Nominatim API is completely free and doesn't require an API key. The backend is already configured to use it.

#### Start Backend Server
```bash
cd backend
node index.js
```

You should see: `Server running on port 3000`

---

### 2. Flutter App Setup

#### Update API Service Base URL

If testing on a real device or different emulator, update the base URL in `api_service.dart`:

```dart
// For local machine
static const String baseUrl = "http://192.168.56.1:3000";

// For real device (replace with your computer's IP)
static const String baseUrl = "http://YOUR_COMPUTER_IP:3000";

// To find your IP:
// Windows: ipconfig
// Mac/Linux: ifconfig
```

#### Run the App
```bash
cd my_app
flutter pub get
flutter run
```

---

## 📱 How to Use the Feature

### For Clients (Posting Tasks):

1. **Navigate to Post Task screen**
2. **Fill in basic details** (title, description, category)
3. **Go to "Info" step**
4. **Find the "Meeting Place" field** (below Location)
5. **Type a location** (e.g., "Central Library", "Starbucks", "City Park")
6. **Wait for suggestions** to appear (autocomplete dropdown)
7. **Select a location** from the suggestions
8. **See confirmation** with full address
9. **Complete the form** and post the task

### For Students (Viewing Tasks):

1. **Open a task** from the task list
2. **Scroll to the Details section**
3. **See the "Meeting Place"** (if specified)
4. **Tap on the meeting place** to view on map (currently shows snackbar with coordinates)

---

## 🔄 New Database Fields

Tasks now have these additional fields in Firestore:

- `meetingPlace` (String) - Place name
- `meetingPlaceId` (String) - Google Place ID
- `meetingPlaceAddress` (String) - Full formatted address
- `meetingPlaceLat` (Number) - Latitude coordinate
- `meetingPlaceLng` (Number) - Longitude coordinate

---

## 🎯 Features Implemented

### Backend (`backend/index.js`)
✅ **OpenStreetMap Nominatim** Places Autocomplete: `/api/places/autocomplete`
✅ **OpenStreetMap Nominatim** Place Details: `/api/places/details`
✅ Error handling and validation
✅ **NO API KEY REQUIRED** - Completely free!
✅ User-Agent header for Nominatim compliance

**OpenStreetMap Nominatim API:**
- Free geocoding service
- No rate limits for reasonable use
- Worldwide coverage
- Addresses, landmarks, businesses
- Returns coordinates automatically

### Flutter App

#### API Service (`lib/api_service.dart`)
✅ `PlacePrediction` model for search results
✅ `PlaceDetails` model for full location data
✅ `getPlacePredictions()` - Fetch autocomplete suggestions
✅ `getPlaceDetails()` - Get full place information
✅ Compatible with OpenStreetMap responses

#### Task Service (`lib/services/task_service.dart`)
✅ Updated `createTask()` with meeting place parameters
✅ Updated `updateTask()` with meeting place parameters
✅ Store coordinates and place ID in Firestore

#### Post Task Screen (`lib/pages/post_task_screen.dart`)
✅ Meeting place text field with autocomplete
✅ Real-time search as you type
✅ Dropdown with place suggestions
✅ Place selection with full details
✅ Visual confirmation of selected place
✅ Loading indicators

#### Task Detail Page (`lib/pages/task_detail_page.dart`)
✅ Display meeting place in details section
✅ Show full address below place name
✅ Map icon and "View on Map" badge
✅ Clickable to open **OpenStreetMap** (free alternative to Google Maps)

---

## 🚀 Future Enhancements

You can extend this feature with:

1. **Launch Maps Directly:**
   - Add `url_launcher` package to `pubspec.yaml`:
   ```yaml
   dependencies:
     url_launcher: ^6.2.0
   ```
   - Update the map opening code:
   ```dart
   import 'package:url_launcher/url_launcher.dart';
   
   Future<void> openMap(double lat, double lng) async {
     final url = 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng';
     if (await canLaunchUrl(Uri.parse(url))) {
       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
     }
   }
   ```

2. **Embed Leaflet Map in Flutter:**
   - Use `flutter_map` package (based on Leaflet)
   - Display interactive map directly in the app
   ```yaml
   dependencies:
     flutter_map: ^6.0.0
     latlong2: ^0.9.0
   ```

3. **Show Map Preview:**
   - Display a static map image from OpenStreetMap
   - Or use `flutter_map` for interactive preview

4. **Distance Calculation:**
   - Calculate distance from user's location
   - Show "X km away" in task list
   - Use `geolocator` package for user location

5. **Route Planning:**
   - Get directions from user's location to meeting place
   - Use OpenRouteService API (also free!)

6. **Meeting Place Filters:**
   - Filter tasks by nearby meeting places
   - Search tasks within a radius

7. **Leaflet Web Integration:**
   If you want to show maps on a web dashboard, use the code you provided:
   ```html
   <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css"/>
   <script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>

   <div id="map" style="height: 400px;"></div>

   <script>
     const map = L.map('map').setView([lat, lng], 15);

     L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
       maxZoom: 19,
       attribution: '© OpenStreetMap contributors'
     }).addTo(map);
     
     // Add a marker for the meeting place
     L.marker([lat, lng]).addTo(map)
       .bindPopup('Meeting Place')
       .openPopup();
   </script>
   ```

---

## 🐛 Troubleshooting

### Backend Issues

**Problem:** "Failed to fetch places"
- **Solution:** 
  - Check if backend server is running (`node index.js`)
  - OpenStreetMap Nominatim has usage policy - don't make too many requests per second
  - Ensure internet connection is stable

**Problem:** Empty results
- **Solution:**
  - Try more specific search terms
  - Add country code if searching specific region
  - OpenStreetMap has fewer commercial places than Google Maps

### Flutter App Issues

**Problem:** No suggestions appearing
- **Solution:**
  - Check backend URL in `api_service.dart`
  - Make sure backend is running
  - Check console for errors
  - Type at least 3 characters to trigger search
  - Wait a moment - Nominatim may be slower than Google

**Problem:** "Connection refused" error
- **Solution:**
  - Update baseUrl with correct IP address
  - For Android emulator: Use `10.0.2.2:3000`
  - For iOS simulator: Use `localhost:3000` or `127.0.0.1:3000`
  - For real device: Use your computer's local IP address

**Problem:** Coordinates not showing
- **Solution:**
  - Select a place from the autocomplete dropdown
  - Don't just type and submit - you must select from suggestions
  - OpenStreetMap provides coordinates automatically

---

## 📝 Testing Checklist

- [ ] Backend server starts without errors
- [ ] `.env` file configured with valid API key
- [ ] Flutter app connects to backend
- [ ] Typing in meeting place field shows suggestions
- [ ] Selecting a place shows confirmation with address
- [ ] Task saves with meeting place data
- [ ] Task detail page displays meeting place correctly
- [ ] Tapping meeting place shows map option

---

## 💡 Example Usage Flow

1. Client posts a tutoring task:
   - Title: "Math tutoring for high school"
   - Location: "Downtown"
   - **Meeting Place:** Types "central library" → Selects "Central Public Library, 123 Main St"

2. Student views the task:
   - Sees all task details
   - Sees meeting place: "Central Public Library"
   - Address: "123 Main St, City, State"
   - Can tap to view on map

3. Both users know exactly where to meet!

---

## 📦 Package Dependencies

No new Flutter packages needed! We used only:
- Existing `http` package for API calls
- Existing `cloud_firestore` for database

Backend requires:
- `express` - Web server
- `axios` - HTTP client
- `cors` - Cross-origin support

**No API keys, no billing, no credit card needed!** 🎉

---

## 🎓 For Your Professor

When presenting this feature, highlight:

1. **Full-stack implementation** - Backend API + Flutter frontend
2. **OpenStreetMap integration** - Free, open-source mapping service
3. **Cost-effective solution** - No API keys or billing required
4. **Real-time autocomplete** - Enhanced UX with instant feedback
5. **Data persistence** - Storing location data in Firestore
6. **Clean architecture** - Separation of concerns (API service, Task service, UI)
7. **Error handling** - Graceful degradation if API fails
8. **Scalability** - Can easily add more location features
9. **Leaflet compatibility** - Can be extended to web with Leaflet.js (as you showed)
10. **Open-source stack** - Using community-driven mapping technology

### Why OpenStreetMap over Google Maps?
- **Free forever** - No usage limits or billing
- **Privacy-friendly** - No tracking or data collection
- **Community-driven** - Open-source and transparent
- **Educational** - Perfect for student projects
- **Professional** - Used by major companies (Apple, Facebook, etc.)

---

## 🗺️ About OpenStreetMap (OSM)

**OpenStreetMap** is like the Wikipedia of maps:
- Created and maintained by volunteers worldwide
- Free to use for any purpose
- Constantly updated and improved
- Powers many major apps and services

**Nominatim** is OSM's geocoding service:
- Converts addresses to coordinates (geocoding)
- Converts coordinates to addresses (reverse geocoding)
- Powers the search on openstreetmap.org
- Free API with fair usage policy

---

Good luck with your project! 🚀
