# 📚 Personalised Attendance Monitor

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey.svg)](https://flutter.dev/)
[![Real-time](https://img.shields.io/badge/Real--time-Data%20Sync-brightgreen.svg)]()

A comprehensive Flutter-based attendance tracking application designed for students to efficiently manage their academic subjects, timetables, and attendance records. With intuitive design, real-time data synchronization, and powerful analytics, this app helps students stay organized and monitor their academic progress seamlessly.

## ✨ Features

### 🚀 **Real-time Data Synchronization**
- **Instant Updates**: All screens automatically fetch fresh data when accessed
- **Cross-screen Sync**: Changes made in one screen immediately reflect in all others
- **Smart Refresh**: Advanced lifecycle management ensures data consistency
- **No Manual Refresh**: Zero need for manual data refreshing
- **Debug Logging**: Comprehensive logging for monitoring data flow

### 📅 Schedule Management
- **Daily Schedule View**: View today's classes with time slots and subject details
- **Date Navigation**: Easy switching between today, yesterday, and custom dates
- **Free Period Detection**: Automatically identifies and displays free periods
- **Real-time Attendance Marking**: Mark attendance as Present/Absent with one tap
- **Smart Lecture Tracking**: Only conducted lectures are counted towards attendance
- **Interactive Cards**: Touch-friendly schedule cards with visual feedback

### 📊 Attendance Tracking
- **Today & Yesterday Views**: Quick access to recent attendance records
- **Status-based Filtering**: Filter by Present, Absent, or All records
- **Automatic Record Creation**: Attendance records are created from timetable
- **Location Tracking**: Classroom and teacher information for each class
- **Instant Status Updates**: Real-time attendance status changes

### 📚 Subject Management
- **Enhanced Subject Types**:
  - **Lectures**: 1-hour duration classes with theory focus
  - **Labs**: 2-hour duration classes with practical sessions
- **Teacher Integration**: Full teacher name and classroom location support
- **Color-coded Organization**: Visual identification with 8 custom color options
- **Mobile-Optimized Forms**: Keyboard-friendly dialogs with scrolling support
- **Advanced CRUD**: Complete Create, Read, Update, Delete operations
- **Real-time Validation**: Instant form validation and error handling

### 🗓️ Timetable Management
- **Weekly Schedule Creation**: Comprehensive day-wise timetable management
- **Multiple Timetables**: Support for different semester schedules
- **Smart Subject Integration**: Automatic subject loading with teacher info
- **Time Slot Management**: Flexible time slot creation and editing
- **Visual Schedule Builder**: Intuitive interface for schedule creation
- **Real-time Updates**: Instant timetable synchronization across all screens

### 🕒 Attendance History & Calendar
- **Interactive Calendar View**: Date-based attendance record browsing
- **Smart Date Picker**: Calendar widget with selectable attendance dates
- **Subject-wise Filtering**: Filter history by specific subjects or view all
- **Edit Capability**: Modify past attendance records (Present/Absent/Free Period)
- **Dual View Modes**: 
  - **Calendar View**: Browse by specific dates with grouped records
  - **Subject View**: Filter by individual subjects
- **Visual Date Grouping**: Records organized by date with clear section headers
- **Real-time History Updates**: Instant reflection of attendance changes

### 📈 Advanced Reports & Analytics
- **Monthly Reports**: Comprehensive attendance analytics by month with date picker
- **Overall Statistics**: Total lectures, present count, absent count, percentages
- **Attendance Percentage**: Real-time calculation of attendance rates
- **Lecture vs Lab Breakdown**: Separate analytics for different class types
- **Subject-wise Analysis**: Individual subject attendance tracking with color coding
- **Visual Charts**: Interactive pie charts and progress indicators using FL Chart
- **Export Ready**: Statistics formatted for easy sharing and reporting

### 🕛 Past Lectures
- **Complete History**: View all previously conducted lectures with timestamps
- **Advanced Filtering**: Multi-level filtering by subjects and attendance status
- **Status-based Views**: Filter by Present, Absent, or All attendance records
- **Detailed Information**: Date, time, teacher, classroom, and attendance status
- **Real-time Search**: Instant filtering and navigation through lecture history
- **Chronological Order**: Records sorted by most recent first

### 🎨 Themes & Customization
- **Dark & Light Modes**: Complete theme switching support with system preference detection
- **Material Design 3**: Modern and intuitive user interface with dynamic theming
- **Custom Color Schemes**: 8 pre-defined color options for subject organization
- **Responsive Design**: Optimized for all screen sizes (mobile, tablet, desktop)
- **Accessibility Support**: High contrast modes and readable fonts
- **Modern Icons**: Phosphor Icon library for consistent, modern iconography

### 💾 Data Management & Performance
- **Local Storage**: Secure offline data storage using SharedPreferences
- **Real-time Synchronization**: Advanced lifecycle management for instant data updates
- **Data Persistence**: Information persists across app reinstalls and platform switches
- **Performance Optimized**: Smart caching and efficient data retrieval
- **Debug Monitoring**: Comprehensive logging system for data flow tracking
- **Cross-platform Compatibility**: Consistent behavior across Android, iOS, Web, and Desktop

## 🚀 **Recent Technical Improvements**

### Real-time Data Synchronization System
- **Multi-layer Refresh Strategy**: Data fetches triggered by `initState()`, `didChangeDependencies()`, `didUpdateWidget()`, and `forceRefresh()`
- **Smart Tab Navigation**: Automatic data refresh when switching between app screens
- **Lifecycle Management**: Advanced widget lifecycle monitoring for optimal performance
- **Debug Logging**: Comprehensive console output for monitoring data flow

### Mobile-Optimized UI/UX
- **Keyboard-Responsive Dialogs**: Fixed keyboard overflow issues on mobile devices
- **Scrollable Forms**: All input forms support scrolling when keyboard appears
- **Touch-Friendly Design**: Larger touch targets and intuitive gesture support
- **Responsive Layouts**: Adaptive layouts that work on any screen size

### Enhanced Calendar & History
- **Interactive Date Picker**: Smart calendar with only attendance dates selectable
- **Visual Date Grouping**: Records organized by date with clear section headers
- **Edit Historical Records**: Ability to modify past attendance status
- **Dual View Modes**: Calendar and Subject-wise filtering options

## 🎯 Key Technical Features

### Real-time Data Flow
1. **Subject Creation**: Users create subjects with teacher info, classroom, type (Lecture/Lab)
2. **Timetable Setup**: Subjects are assigned to time slots with real-time loading
3. **Attendance Generation**: Daily records auto-created from active timetable
4. **Real-time Marking**: Instant attendance updates across all screens
5. **Analytics Calculation**: Reports generated in real-time from attendance data
6. **Historical Editing**: Past records can be modified with instant synchronization

### Advanced Performance Features
- **Efficient Storage**: Optimized SharedPreferences operations
- **Smart Caching**: Intelligent data caching for faster load times
- **Memory Management**: Proper widget disposal and resource cleanup
- **Cross-platform**: Consistent behavior across all Flutter platforms

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Siddhantshukla1657/Attendence_Tracker_2.0.git
   cd Attendence_Tracker_2.0
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Download APK

You can download the pre-built APK files for Android:

**[Download APK with Backend Support](APK's/Trackit_with_Backend.apk)** - Includes Firebase integration for cloud synchronization

**[Download APK without Backend](APK's/Trackit.apk)** - Local-only storage version

### Building for Production

**Android APK**
```bash
flutter build apk --release
```

**Android Bundle**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

**Web**
```bash
flutter build web --release
```

**Desktop (Windows)**
```bash
flutter build windows --release
```

## 📱 App Structure

### Main Screens

1. **Schedule Screen** (`lib/screens/schedule_screen.dart`)
   - Daily class schedule view
   - Attendance marking interface
   - Free period identification

2. **Attendance Screen** (`lib/screens/attendance_screen.dart`)
   - Today/Yesterday attendance views
   - Quick attendance overview
   - Navigation to past lectures

3. **Subjects Screen** (`lib/screens/subjects_screen.dart`)
   - Subject management interface
   - Add/Edit/Delete subjects
   - Lecture/Lab categorization

4. **Timetable Screen** (`lib/screens/timetable_screen.dart`)
   - Weekly timetable management with real-time subject loading
   - Time slot creation and editing with teacher/classroom info
   - Multiple timetable support with active timetable selection

5. **Attendance History Screen** (`lib/screens/attendance_history_screen.dart`)
   - Interactive calendar widget for date-based browsing
   - Dual-mode interface: Calendar View and Subject View
   - Edit historical attendance records with real-time updates
   - Smart date picker with only valid dates selectable

6. **Reports Screen** (`lib/screens/reports_screen.dart`)
   - Monthly attendance analytics with interactive date picker
   - Visual charts and statistics using FL Chart library
   - Subject-wise breakdowns with color-coded representation

7. **Past Lectures Screen** (`lib/screens/past_lectures_screen.dart`)
   - Historical lecture records with advanced filtering
   - Multi-level filtering options (subject + status)
   - Real-time search and chronological ordering

### Core Models

- **Subject** (`lib/models/subject.dart`): Subject information and type management
- **Attendance** (`lib/models/attendance.dart`): Attendance records and statistics
- **Timetable** (`lib/models/timetable.dart`): Schedule and time slot management

### Services

- **Storage Service** (`lib/services/storage_service.dart`): 
  - Local data persistence and management
  - Real-time CRUD operations
  - Data validation and error handling
  - Cross-platform storage compatibility

### UI Components

- **App Theme** (`lib/theme/app_theme.dart`): 
  - Dark/Light theme configurations
  - Material Design 3 color schemes
  - Consistent typography and spacing
- **Schedule Card** (`lib/widgets/schedule_card.dart`): 
  - Interactive schedule display widget
  - Real-time attendance status updates
  - Touch-friendly interface design

## 🏗️ Architecture

The app follows a clean architecture pattern with clear separation of concerns:

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
│   └── past_lectures_screen.dart
├── services/                 # Business logic
│   └── storage_service.dart
├── theme/                    # UI theming
│   └── app_theme.dart
└── widgets/                  # Reusable components
    └── schedule_card.dart
```

## 📊 Data Flow

1. **Subject Creation**: Users create subjects with type (Lecture/Lab) and duration
2. **Timetable Setup**: Subjects are assigned to time slots in weekly timetable
3. **Attendance Generation**: Daily attendance records are created from active timetable
4. **Attendance Marking**: Users mark attendance as Present/Absent (default: Free)
5. **Analytics Calculation**: Reports are generated from attendance data

## 🎯 Key Features Explained

### Free Period State
- **Default State**: All attendance records start as "Free Period"
- **Conducted Only**: Only Present/Absent records count as "conducted lectures"
- **Smart Analytics**: Free periods are excluded from attendance calculations

### Subject Types
- **Lectures**: 1-hour duration, typically theory classes
- **Labs**: 2-hour duration, typically practical sessions
- **Auto-duration**: Timetable automatically sets duration based on subject type

### Attendance Calculation
- **Formula**: (Present Count / Conducted Lectures) × 100
- **Exclusions**: Free periods are not included in calculations
- **Real-time**: Updates immediately when attendance is marked

## 🔧 Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.8
  shared_preferences: ^2.2.2  # Local storage
  intl: ^0.19.0                # Date formatting
  fl_chart: ^0.66.2            # Charts and graphs
  phosphor_flutter: ^2.0.1     # Modern icons
```


### Code Style
- Follow Flutter's official style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent formatting
