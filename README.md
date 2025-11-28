# WishListy - Social Gifting Platform

<div align="center">

**Connect through thoughtful gifting** 🎁

A modern Flutter application for creating and sharing gift wishlists with friends and family.

[![Flutter](https://img.shields.io/badge/Flutter-3.16.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.1+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-Proprietary-red)]()

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Backend API](#backend-api)
- [Getting Started](#getting-started)
- [Development](#development)
- [API Integration Status](#api-integration-status)
- [Roadmap](#roadmap)

---

## 🎯 Overview

**WishListy** is a comprehensive social gifting platform that enables users to:

- Create and manage multiple wishlists for different occasions (birthday, wedding, holiday, etc.)
- Share wishlists with friends and family
- Connect with friends and view their wishlists (with permission)
- Create and manage events (birthdays, weddings, anniversaries)
- Coordinate group gifts for special occasions
- Get AI-powered smart reminders for upcoming events
- Earn rewards and points through gamification
- Browse as a guest without registration

### Business Value

The platform solves the common problem of gift-giving by providing a centralized, social, and organized way to:
- Manage gift preferences efficiently
- Enhance relationships through thoughtful gifting
- Ensure recipients receive gifts they actually want
- Coordinate group gift purchases

---

## ✨ Features

### Core Features

#### 1. **Authentication & User Management**
- User registration and login
- Guest mode (browse without account)
- Profile management with privacy controls
- Multi-language support (English/Arabic with RTL)

#### 2. **Wishlist Management**
- Create multiple wishlists for different occasions
- Add items with descriptions, images, and links
- Set priority levels and categories
- Share wishlists with specific people or publicly
- View friends' wishlists (with permission)
- Track purchased items

#### 3. **Event Management**
- Create events (birthdays, weddings, anniversaries, holidays, etc.)
- Invite friends and family as guests
- Coordinate group gifts
- Event reminders and notifications
- Event settings and privacy controls
- Guest management

#### 4. **Social Features**
- Friend requests and connections
- View friends' profiles and wishlists
- Social feed of gift activities
- Gift history and memories

#### 5. **Smart Features**
- AI-powered smart reminders for upcoming events
- Gift recommendations based on preferences
- Activity tracking and analytics

#### 6. **Gamification**
- Gift points system
- Achievements and badges
- Leaderboard
- Rewards store

#### 7. **Notifications**
- Push notifications for important events
- Email reminders for upcoming occasions
- In-app messaging between friends
- Gift status updates

---

## 🏗️ Architecture

The application follows a **Clean Architecture** pattern with **feature-based** folder structure:

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│   (Screens, Widgets, Cubits)        │
├─────────────────────────────────────┤
│      Business Logic Layer           │
│   (Cubits, Repositories)            │
├─────────────────────────────────────┤
│      Data Layer                     │
│   (API Services, Local Storage)     │
└─────────────────────────────────────┘
```

### Architecture Principles

1. **Feature-based Structure**: Each feature is self-contained in its own folder
2. **Separation of Concerns**: Clear boundaries between UI, business logic, and data
3. **Repository Pattern**: All API calls go through repositories
4. **State Management**: Cubit pattern for predictable state management
5. **Dependency Injection**: Provider pattern for service management

### Design Patterns Used

- **Cubit Pattern**: State management (flutter_bloc)
- **Repository Pattern**: Data access abstraction
- **Singleton Pattern**: Service instances (API, Auth)
- **Provider Pattern**: Dependency injection

---

## 🛠️ Tech Stack

### Core Technologies

- **Framework**: Flutter 3.16.0+
- **Language**: Dart 3.8.1+
- **State Management**: flutter_bloc (Cubit pattern)
- **Dependency Injection**: Provider
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences
- **Internationalization**: flutter_localizations

### Key Packages

```yaml
dependencies:
  flutter_bloc: ^8.1.3          # State management
  equatable: ^2.0.5             # Value equality
  dio: ^5.4.0                   # HTTP client
  shared_preferences: ^2.2.2    # Local storage
  google_fonts: ^6.1.0          # Fonts
  flutter_staggered_animations: ^1.1.1  # Animations
  table_calendar: ^3.1.2        # Calendar widget
```

---

## 📁 Project Structure

```
lib/
├── core/                          # Core functionality shared across features
│   ├── constants/                # App-wide constants
│   ├── models/                   # Shared models
│   ├── services/                 # Core services (API, Localization, Permissions)
│   ├── theme/                    # App theme and styling
│   ├── utils/                    # Utility functions and helpers
│   └── widgets/                  # Reusable widgets
│
├── features/                      # Feature modules
│   ├── auth/                     # Authentication feature
│   │   ├── data/
│   │   │   ├── models/          # Auth models
│   │   │   └── repository/      # Auth repository
│   │   └── presentation/
│   │       ├── screens/         # Auth screens
│   │       └── widgets/         # Auth widgets
│   │
│   ├── wishlists/               # Wishlist management
│   ├── events/                  # Event management
│   ├── friends/                 # Friend management
│   ├── profile/                 # User profile
│   ├── notifications/           # Notifications
│   ├── reminders/               # Smart reminders
│   └── rewards/                 # Rewards & gamification
│
└── main.dart                     # App entry point
```

### Feature Structure

Each feature follows this structure:

```
feature_name/
├── data/
│   ├── models/              # Data models with fromJson/toJson
│   └── repository/          # Repository for API calls
├── presentation/
│   ├── cubit/              # State management (Cubit)
│   ├── screens/            # Feature screens
│   └── widgets/            # Feature-specific widgets
```

---

## 🔌 Backend API

### Configuration

- **Base URL**: `http://localhost:4000/api`
- **Authentication**: JWT Bearer tokens
- **Content Type**: `application/json`

### API Endpoints

#### Authentication

##### Register User
```http
POST /api/auth/register
Content-Type: application/json

Request Body:
{
  "fullName": "John Doe",
  "username": "johndoe",
  "password": "securePassword123"
}

Response:
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "fullName": "John Doe",
    "username": "johndoe"
  }
}
```

##### Login
```http
POST /api/auth/login
Content-Type: application/json

Request Body:
{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "fullName": "John Doe"
  }
}
```

### API Service Implementation

The app uses `Dio` with interceptors for:
- Automatic error handling
- Request/response logging (debug mode)
- Token management
- Timeout configuration (30 seconds)

**Location**: `lib/core/services/api_service.dart`

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / VS Code with Flutter extensions
- iOS development: Xcode (for macOS)
- Android development: Android Studio
- Backend API running on `http://localhost:4000`

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd wish_listy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run -d ios

   # For specific device
   flutter devices
   flutter run -d <device-id>
   ```

### Configuration

#### Backend API URL

The API base URL is configured in:
- `lib/core/services/api_service.dart`

Current setting: `http://localhost:4000/api`

To change it, update the `_baseUrl` constant in the `ApiService` class.

#### Localization

Supported languages:
- English (en)
- Arabic (ar) - with RTL support

Language files are located in: `assets/translations/`

---

## 💻 Development

### Code Style

- Follow [Flutter style guide](https://flutter.dev/docs/development/ui/widgets-intro)
- Use `snake_case` for file names
- Use `camelCase` for variables and functions
- Use `PascalCase` for classes

### State Management

**Always use Cubit pattern** for state management:

```dart
// Example Cubit
class WishlistCubit extends Cubit<WishlistState> {
  final WishlistRepository repository;
  
  WishlistCubit(this.repository) : super(WishlistInitial());
  
  Future<void> loadWishlists() async {
    emit(WishlistLoading());
    try {
      final wishlists = await repository.getWishlists();
      emit(WishlistLoaded(wishlists));
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }
}
```

### API Integration

**Always use Repository pattern** for API calls:

1. Create models with `fromJson`/`toJson`
2. Create repository in `feature/data/repository/`
3. Use `ApiService` for HTTP requests
4. Handle errors in repository
5. Use Cubit to call repository and manage state

Example:
```dart
class WishlistRepository {
  final ApiService apiService;
  
  Future<List<Wishlist>> getWishlists() async {
    try {
      final response = await apiService.get('/wishlists');
      return (response['data'] as List)
          .map((json) => Wishlist.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load wishlists: $e');
    }
  }
}
```

### File Naming Conventions

- Screens: `[feature]_screen.dart` (e.g., `events_screen.dart`)
- Widgets: `[description]_widget.dart` (e.g., `event_card_widget.dart`)
- Cubits: `[feature]_cubit.dart` (e.g., `events_cubit.dart`)
- Repositories: `[feature]_repository.dart` (e.g., `events_repository.dart`)
- Models: `[entity]_model.dart` (e.g., `event_model.dart`)

---

## 📊 API Integration Status

### ✅ Completed

- [x] API Service setup with Dio
- [x] Authentication repository structure
- [x] Register API endpoint (structure documented)

### 🔄 In Progress

- [ ] Verify Register API integration
- [ ] Update base URL to localhost:4000

### ❌ Pending

- [ ] Login API integration
- [ ] Wishlist APIs (CRUD operations)
- [ ] Event APIs (create, update, delete, list)
- [ ] Friend APIs (send request, accept/reject, list)
- [ ] Notification APIs
- [ ] Profile APIs (update, get)
- [ ] Rewards APIs
- [ ] Reminders APIs

---

## 🗺️ Roadmap

### Phase 1: Authentication ✅
- [x] Register endpoint structure
- [ ] Complete Register API integration
- [ ] Login API integration
- [ ] Token management
- [ ] Logout functionality

### Phase 2: Core Features
- [ ] Wishlist CRUD operations
- [ ] Event CRUD operations
- [ ] Friend management
- [ ] Profile management

### Phase 3: Social Features
- [ ] Share wishlists
- [ ] Friend interactions
- [ ] Notifications system
- [ ] Activity feed

### Phase 4: Advanced Features
- [ ] Smart reminders
- [ ] Rewards system
- [ ] Gift recommendations
- [ ] Analytics dashboard

---

## 📱 Screens

### Authentication
- Welcome Screen
- Login Screen
- Signup Screen
- Forgot Password Screen

### Main Navigation (Bottom Tabs)
1. **Home** - Dashboard and overview
2. **Wishlists** - My wishlists and friends' wishlists
3. **Events** - All events (created and invited)
4. **Friends** - Friend list and requests
5. **Profile** - User profile and settings

### Wishlists
- My Wishlists Screen
- Create Wishlist Screen
- Wishlist Items Screen
- Add Item Screen
- Item Details Screen

### Events
- Events Screen (list view)
- Create Event Screen
- Event Details Screen
- Event Management Screen
- Event Wishlist Screen
- Guest Management Screen
- Event Settings Screen

### Friends
- Friends Screen
- Add Friend Screen
- Friend Profile Screen

### Profile
- Profile Screen
- Edit Profile Screen
- Personal Information Screen
- Privacy & Security Screen
- Blocked Users Screen

### Other
- Notifications Screen
- Smart Reminders Screen
- Achievements Screen
- Leaderboard Screen
- Rewards Store Screen

---

## 🌍 Internationalization

The app supports multiple languages:

- **English** (en) - Default
- **Arabic** (ar) - Full RTL support

Translation files: `assets/translations/`

The app automatically detects device language and supports switching languages in-app.

---

## 🤝 Contributing

This is a proprietary project. For internal development:

1. Follow the code style guidelines
2. Use feature branches
3. Write clear commit messages
4. Update documentation for new features
5. Test on both iOS and Android

---

## 📄 License

Proprietary - All rights reserved

---

## 📞 Support

For questions or issues:
- Check documentation files in the project
- Review `PROJECT_RULES.md` for development guidelines
- Contact the development team

---

**Built with ❤️ using Flutter**
