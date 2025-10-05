# 📚 Attendance Tracker - Comprehensive Documentation

This document provides a detailed overview of the Attendance Tracker application, covering all aspects of its functionality, architecture, widgets, and backend integration.

## 🏗️ Project Architecture

The application follows a clean architecture pattern with a clear separation of concerns:

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── subject.dart
│   ├── attendance.dart
│   └── timetable.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── schedule_screen.dart
│   ├── attendance_screen.dart
│   ├── subjects_screen.dart
│   ├── timetable_screen.dart
│   ├── reports_screen.dart
│   ├── past_lectures_screen.dart
│   ├── attendance_history_screen.dart
│   ├── profile_screen.dart
│   └── auth_screen.dart
├── services/                 # Business logic
│   ├── storage_service.dart
│   ├── backend_service.dart
│   └── firebase_service.dart
├── theme/                    # UI theming
│   └── app_theme.dart
└── widgets/                  # Reusable components
    └── schedule_card.dart
```

## 📊 Data Models

### Subject Model (`lib/models/subject.dart`)

Represents an academic subject with the following properties:
- `id`: Unique identifier
- `name`: Subject name
- `type`: Subject type ('lecture' or 'lab')
- `teacherName`: Name of the teacher
- `classroom`: Classroom location
- `color`: Color code for UI representation

### Attendance Model (`lib/models/attendance.dart`)

Represents an attendance record with the following properties:
- `id`: Unique identifier
- `subjectId`: Reference to the subject
- `date`: Date of the class
- `startTime`: Start time of the class
- `endTime`: End time of the class
- `status`: Attendance status ('present', 'absent', or 'free')
- `subjectName`: Name of the subject (for display purposes)
- `teacherName`: Name of the teacher (for display purposes)
- `classroom`: Classroom location (for display purposes)

### Timetable Model (`lib/models/timetable.dart`)

Represents a weekly timetable with the following properties:
- `id`: Unique identifier
- `name`: Timetable name
- `isActive`: Whether this is the currently active timetable
- `days`: Map of days (Monday-Sunday) containing time slots
- `timeSlots`: List of time slots with start and end times

## 🖼️ Screens and Widgets

### Home Screen (`lib/screens/home_screen.dart`)

The main dashboard that provides navigation to all other screens.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar with title and theme toggle
- `BottomNavigationBar`: Navigation between main sections
- `PageView`: Swipable pages for different sections

### Schedule Screen (`lib/screens/schedule_screen.dart`)

Displays the daily schedule and allows attendance marking.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar with date navigation
- `ListView`: Scrollable list of schedule items
- `Card`: Container for schedule items
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `IconButton`: Interactive buttons for attendance marking
- `CircularProgressIndicator`: Loading indicator
- `SnackBar`: User feedback messages

### Attendance Screen (`lib/screens/attendance_screen.dart`)

Shows today's and yesterday's attendance records.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar
- `TabBar`: Switch between Today and Yesterday views
- `TabBarView`: Content for each tab
- `ListView`: Scrollable list of attendance records
- `Card`: Container for attendance items
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `IconButton`: Interactive buttons for attendance marking
- `SegmentedButton`: Filter by attendance status
- `RefreshIndicator`: Pull-to-refresh functionality

### Subjects Screen (`lib/screens/subjects_screen.dart`)

Manages academic subjects with CRUD operations.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar with search functionality
- `ListView`: Scrollable list of subjects
- `Card`: Container for subject items
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `IconButton`: Interactive buttons for editing/deleting
- `FloatingActionButton`: Add new subject button
- `Dialog`: Form for adding/editing subjects
- `TextField`: Input fields
- `DropdownButton`: Subject type selection
- `ColorFiltered`: Color selection
- `SnackBar`: User feedback messages

### Timetable Screen (`lib/screens/timetable_screen.dart`)

Manages weekly timetables with time slot configuration.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar
- `TabBar`: Switch between different timetables
- `TabBarView`: Content for each timetable
- `ListView`: Scrollable list of timetable items
- `Card`: Container for timetable items
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `IconButton`: Interactive buttons for editing/deleting
- `FloatingActionButton`: Add new timetable button
- `Dialog`: Form for adding/editing timetables
- `TextField`: Input fields
- `TimePicker`: Time selection
- `SnackBar`: User feedback messages

### Reports Screen (`lib/screens/reports_screen.dart`)

Generates attendance analytics and visualizations.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar
- `ListView`: Scrollable list of reports
- `Card`: Container for report items
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `PieChart`: Attendance distribution visualization (from fl_chart package)
- `LineChart`: Attendance trend visualization (from fl_chart package)
- `DropdownButton`: Month selection
- `CircularProgressIndicator`: Loading indicator

### Past Lectures Screen (`lib/screens/past_lectures_screen.dart`)

Views historical attendance records with filtering.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar with search functionality
- `ListView`: Scrollable list of past lectures
- `Card`: Container for lecture items
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `IconButton`: Interactive buttons for attendance marking
- `SegmentedButton`: Filter by attendance status
- `DropdownButton`: Subject filtering
- `RefreshIndicator`: Pull-to-refresh functionality

### Attendance History Screen (`lib/screens/attendance_history_screen.dart`)

Provides calendar-based browsing of attendance records.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar
- `TabBar`: Switch between Calendar and Subject views
- `TabBarView`: Content for each tab
- `TableCalendar`: Interactive calendar widget
- `ListView`: Scrollable list of attendance records
- `Card`: Container for attendance items
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `IconButton`: Interactive buttons for attendance marking
- `SegmentedButton`: Filter by attendance status

### Profile Screen (`lib/screens/profile_screen.dart`)

Manages user profile and authentication.

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar
- `Card`: Container for profile information
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `CircleAvatar`: User profile picture
- `ElevatedButton`: Action buttons (Sign Out, Clear Data)
- `AlertDialog`: Confirmation dialogs
- `CircularProgressIndicator`: Loading indicator
- `SnackBar`: User feedback messages

### Auth Screen (`lib/screens/auth_screen.dart`)

Handles user authentication (sign up/in).

**Widgets Used:**
- `Scaffold`: Basic screen structure
- `AppBar`: Top app bar
- `Card`: Container for auth forms
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `TextField`: Email/password input
- `ElevatedButton`: Action buttons (Sign Up, Sign In)
- `TextButton`: Switch between sign up/in
- `SnackBar`: User feedback messages
- `CircularProgressIndicator`: Loading indicator

### Schedule Card Widget (`lib/widgets/schedule_card.dart`)

A reusable widget for displaying schedule items.

**Widgets Used:**
- `Card`: Container for schedule item
- `Row`/`Column`: Layout organization
- `Text`: Display information
- `IconButton`: Interactive buttons for attendance marking
- `Container`: Color-coded subject indicator

## 🧠 Services

### Storage Service (`lib/services/storage_service.dart`)

Manages local data persistence using SharedPreferences with the following key features:

1. **Data Management:**
   - Subjects CRUD operations
   - Attendance records CRUD operations
   - Timetables CRUD operations
   - Settings management

2. **Synchronization:**
   - Automatic sync with backend when internet is available
   - Manual sync functionality
   - Bidirectional data synchronization
   - Conflict resolution

3. **Data Integrity:**
   - Automatic backups
   - Data validation
   - Recovery mechanisms
   - Duplicate detection and cleanup

4. **Connectivity Handling:**
   - Automatic sync when connectivity is restored
   - Offline data storage
   - Online/offline state detection

### Backend Service (`lib/services/backend_service.dart`)

Handles Firebase integration with the following functionality:

1. **Authentication:**
   - User sign up with email/password
   - User sign in with email/password
   - User sign out
   - User profile management (name updates)

2. **Data Operations:**
   - Subjects CRUD operations in Firestore
   - Attendance records CRUD operations in Firestore
   - Timetables CRUD operations in Firestore
   - User profile data management

3. **Data Management:**
   - Sync local data with backend
   - Check if backend has user data
   - Delete all user data from backend
   - Force fetch from backend

### Firebase Service (`lib/services/firebase_service.dart`)

Initializes Firebase with platform-specific configuration.

## 🔧 Backend Integration

### Firebase Architecture

The application uses Firebase for backend services:

1. **Firebase Authentication:**
   - Email/password authentication
   - User session management
   - Profile information storage

2. **Cloud Firestore:**
   - Data structure:
     ```
     users/
       {userId}/
         subjects/
           {subjectId}
         attendance/
           {attendanceId}
         timetables/
           {timetableId}
         profile/
     ```
   - Real-time data synchronization
   - Secure data access with Firebase rules

3. **Data Flow:**
   - Local data is stored in SharedPreferences
   - When online, data is synchronized with Firestore
   - Changes in Firestore are reflected locally
   - Offline-first approach ensures app functionality without internet

### Synchronization Strategy

1. **Automatic Sync:**
   - Triggered when app starts
   - Triggered when connectivity is restored
   - Periodic sync every 5 minutes when online

2. **Manual Sync:**
   - Available through pull-to-refresh
   - Available through explicit sync button

3. **Conflict Resolution:**
   - Local changes take precedence
   - Timestamp-based conflict detection
   - Incremental sync to minimize data transfer

### Security

1. **Authentication:**
   - All backend operations require authentication
   - Secure token-based authentication
   - Session management

2. **Data Protection:**
   - User data isolation
   - Firestore security rules
   - Data encryption in transit

## 🎨 Theme and UI

### App Theme (`lib/theme/app_theme.dart`)

Provides consistent theming with:
- Light and dark mode support
- Material Design 3 compliance
- Responsive design for all screen sizes
- Custom color schemes

## 📱 Platform Support

The application supports:
- Android
- iOS
- Web
- Desktop (Windows, macOS, Linux)

## 🚀 Performance Features

1. **Efficient Storage:**
   - Optimized SharedPreferences operations
   - Smart caching mechanisms
   - Memory management

2. **Data Management:**
   - Incremental sync to minimize data transfer
   - Duplicate detection and cleanup
   - Automatic backups

3. **UI Optimization:**
   - Lazy loading for large data sets
   - Efficient widget rebuilding
   - Responsive layouts

## 🔧 Dependencies

Key dependencies used in the project:
- `shared_preferences`: Local data storage
- `intl`: Date formatting and internationalization
- `fl_chart`: Data visualization
- `phosphor_flutter`: Icon library
- `firebase_core`: Firebase initialization
- `firebase_auth`: Firebase authentication
- `cloud_firestore`: Firebase database
- `connectivity_plus`: Network connectivity detection

## 🔄 Data Flow

1. **App Initialization:**
   - Firebase initialization
   - Local storage initialization
   - Backend sync if user is authenticated

2. **User Authentication:**
   - Sign up/in through Firebase Auth
   - Profile creation/update in Firestore
   - Data sync between local and cloud storage

3. **Data Operations:**
   - Local changes are immediately reflected in UI
   - Changes are persisted to SharedPreferences
   - If online, changes are synced to Firestore
   - If offline, changes are queued for later sync

4. **Data Retrieval:**
   - Data is first loaded from local storage for instant UI
   - If online, data is fetched from Firestore
   - Local storage is updated with latest data
   - UI is refreshed with updated data

## 🛡️ Error Handling

1. **Network Errors:**
   - Graceful degradation to offline mode
   - Retry mechanisms for failed operations
   - User notifications for connectivity issues

2. **Data Errors:**
   - Validation before saving data
   - Recovery from corrupted data
   - Backup restoration mechanisms

3. **Authentication Errors:**
   - Proper error messages for auth failures
   - Session recovery mechanisms
   - Secure credential handling

## 📈 Analytics and Reporting

1. **Attendance Calculation:**
   - Real-time percentage calculation
   - Exclusion of free periods from calculations
   - Separate tracking for lectures and labs

2. **Data Visualization:**
   - Pie charts for attendance distribution
   - Line charts for attendance trends
   - Color-coded subject analysis

3. **Reporting Features:**
   - Monthly attendance reports
   - Subject-wise analysis
   - Overall statistics

This comprehensive documentation covers all aspects of the Attendance Tracker application, providing a complete understanding of its functionality, architecture, and implementation details.