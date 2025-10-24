# API Integration Guide

## Overview
This guide explains how the API integration is implemented in the WishListy Flutter app, including the architecture, services, widgets, and usage patterns. The code has been refactored into modular widgets for better maintainability and organization.

## API Endpoint
- **Base URL**: `https://e-commerce-api-production-ea9f.up.railway.app/api`
- **Register Endpoint**: `/auth/signup`

## Architecture Overview

The app follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────┐
│           UI Layer                  │
│  (Screens + Widgets)                │
├─────────────────────────────────────┤
│         Business Logic              │
│      (Services + Models)            │
├─────────────────────────────────────┤
│         Data Layer                  │
│    (API + Local Storage)            │
└─────────────────────────────────────┘
```

## Core Services

### 1. API Service (`lib/services/api_service.dart`)
**Purpose**: Main HTTP client using Dio for all API communications

**Key Features**:
- Singleton pattern for consistent configuration
- Automatic error handling with custom exceptions
- Request/response logging in debug mode
- Timeout configuration (30 seconds)
- Interceptors for error handling and logging

**Key Methods**:
- `get()` - GET requests
- `post()` - POST requests
- `put()` - PUT requests
- `delete()` - DELETE requests
- `setAuthToken()` - Set authorization header
- `clearAuthToken()` - Remove authorization header

**Error Handling**:
- Custom `ApiException` class for structured error handling
- Automatic error message conversion based on HTTP status codes
- Network connectivity error handling

### 2. Auth API Service (`lib/services/auth_api_service.dart`)
**Purpose**: Authentication-specific API operations

**Key Methods**:
- `register()` - User registration
- `login()` - User login
- `validateUsername()` - Validate email or phone
- `validateFullName()` - Validate full name
- `validatePassword()` - Validate password strength
- `isValidEmail()` - Email format validation
- `isValidPhone()` - Phone number validation

**API Request Format**:
```json
{
  "username": "user@example.com", // email or phone
  "fullName": "John Doe",
  "password": "SecurePassword123"
}
```

### 3. API Response Models (`lib/models/api_response.dart`)
**Purpose**: Type-safe data models for API responses

**Key Models**:
- `ApiResponse<T>` - Generic response wrapper
- `AuthResponse` - Authentication response
- `RegistrationRequest` - Registration request data
- `LoginRequest` - Login request data
- `ValidationError` - Validation error details

### 4. Error Handler Widget (`lib/widgets/error_handler.dart`)
**Purpose**: Consistent error display and user feedback

**Key Methods**:
- `showErrorDialog()` - Error dialog with retry option
- `showErrorSnackBar()` - Error snackbar
- `showSuccessSnackBar()` - Success snackbar
- `handleApiException()` - Handle API-specific errors
- `showLoadingDialog()` - Loading indicator

## Widget Architecture (Refactored)

### 5. Signup Screen Widgets (`lib/widgets/signup/`)
**Purpose**: Modular widgets for the signup screen

#### 5.1 SignupHeaderWidget (`signup_header_widget.dart`)
**Purpose**: Header section with title, subtitle, and back button
**Features**:
- Responsive title and subtitle
- Back navigation button
- Consistent styling with app theme
- Localized text support

#### 5.2 SignupFormWidget (`signup_form_widget.dart`)
**Purpose**: Form fields with real-time validation
**Features**:
- Full name field with validation
- Username field (email or phone) with validation
- Password field with visibility toggle
- Confirm password field with matching validation
- Real-time error messages under each field
- Multilingual error messages
- Form validation integration

#### 5.3 SignupTermsWidget (`signup_terms_widget.dart`)
**Purpose**: Terms and conditions checkbox
**Features**:
- Checkbox with proper styling
- Localized terms text
- Form validation integration
- State management

#### 5.4 SignupActionsWidget (`signup_actions_widget.dart`)
**Purpose**: Action buttons and navigation links
**Features**:
- Signup button with loading state
- Button disabled until form is valid
- Login link for existing users
- Consistent button styling
- Loading indicators

#### 5.5 SignupSuccessDialog (`signup_success_dialog.dart`)
**Purpose**: Success dialog after registration
**Features**:
- User welcome message
- Email verification status
- Continue button to main app
- Responsive design
- User data display

### 6. Main Signup Screen (`lib/screens/auth/signup_screen.dart`)
**Purpose**: Orchestrates all signup widgets and handles business logic
**Features**:
- Form validation state management
- API integration
- Animation handling
- Error handling
- Widget coordination
- State management

## Implementation Details

### Registration Flow
1. **Form Validation**: Client-side validation using `AuthApiService` methods
2. **Real-time Feedback**: Error messages appear under each field
3. **API Call**: Send registration data to `/auth/signup`
4. **Response Handling**: Process success/error responses
5. **State Management**: Update `AuthService` with user data
6. **Local Storage**: Save user data and auth token
7. **UI Feedback**: Show success dialog or error messages

### Validation Strategy
- **Client-side**: Immediate feedback using regex patterns
- **Server-side**: API validation with detailed error messages
- **Consistent**: Same validation rules across client and server
- **Real-time**: Validation happens as user types
- **Multilingual**: Error messages in Arabic and English

### Error Handling Strategy
- **Network Errors**: Connection timeout, no internet
- **API Errors**: HTTP status codes (400, 401, 403, 404, 422, 500)
- **Validation Errors**: Field-specific error messages
- **User Feedback**: Top-positioned snackbars, dialogs, and loading states

### Widget Communication
- **Parent-Child**: Main screen passes data to widgets
- **Callbacks**: Widgets communicate back via callback functions
- **State Management**: Provider pattern for localization
- **Form State**: Global form key for validation

## Usage Examples

### Basic Registration
```dart
final authApiService = AuthApiService();
final response = await authApiService.register(
  username: 'user@example.com',
  fullName: 'John Doe',
  password: 'SecurePassword123',
);
```

### Error Handling
```dart
try {
  final response = await authApiService.register(...);
  // Handle success
} on ApiException catch (e) {
  ErrorHandler.handleApiException(context, e);
} catch (e) {
  ErrorHandler.showErrorSnackBar(context, message: 'Unexpected error');
}
```

### Form Validation
```dart
final authApiService = AuthApiService();
final nameError = authApiService.validateFullName(name);
final usernameError = authApiService.validateUsername(username);
final passwordError = authApiService.validatePassword(password);
```

### Widget Usage
```dart
// In main screen
SignupFormWidget(
  fullNameController: _fullNameController,
  usernameController: _usernameController,
  passwordController: _passwordController,
  confirmPasswordController: _confirmPasswordController,
  obscurePassword: _obscurePassword,
  obscureConfirmPassword: _obscureConfirmPassword,
  fullNameError: _fullNameError,
  usernameError: _usernameError,
  passwordError: _passwordError,
  confirmPasswordError: _confirmPasswordError,
  onPasswordToggle: () {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  },
  onConfirmPasswordToggle: () {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  },
)
```

## Topics to Study

### 1. Dio HTTP Client
- **What**: Advanced HTTP client for Flutter
- **Why**: Better than basic `http` package
- **Features**: Interceptors, timeouts, error handling, request/response transformation
- **Study**: [Dio Documentation](https://pub.dev/packages/dio)

### 2. Singleton Pattern
- **What**: Design pattern ensuring single instance
- **Why**: Consistent configuration across app
- **Implementation**: Private constructor + factory method
- **Study**: [Singleton Pattern in Dart](https://dart.dev/guides/language/language-tour#factory-constructors)

### 3. Error Handling
- **What**: Structured approach to handle errors
- **Why**: Better user experience and debugging
- **Types**: Network, API, validation, unexpected errors
- **Study**: [Error Handling in Dart](https://dart.dev/guides/language/error-handling)

### 4. Form Validation
- **What**: Client-side input validation
- **Why**: Immediate user feedback
- **Types**: Email, phone, password strength, required fields
- **Study**: [Form Validation in Flutter](https://flutter.dev/docs/cookbook/forms/validation)

### 5. State Management
- **What**: Managing app state changes
- **Why**: Consistent UI updates
- **Pattern**: Provider pattern with ChangeNotifier
- **Study**: [Provider Package](https://pub.dev/packages/provider)

### 6. Widget Composition
- **What**: Breaking UI into smaller, reusable components
- **Why**: Better maintainability and reusability
- **Pattern**: Single responsibility principle
- **Study**: [Flutter Widget Composition](https://flutter.dev/docs/development/ui/widgets)

### 7. Local Storage
- **What**: Storing data locally on device
- **Why**: Offline access and session persistence
- **Package**: SharedPreferences
- **Study**: [SharedPreferences](https://pub.dev/packages/shared_preferences)

### 8. API Design Patterns
- **What**: RESTful API design principles
- **Why**: Consistent and predictable APIs
- **Concepts**: HTTP methods, status codes, request/response format
- **Study**: [REST API Design](https://restfulapi.net/)

## File Structure (Refactored)
```
lib/
├── services/
│   ├── api_service.dart              # Main HTTP client
│   ├── auth_api_service.dart         # Authentication API
│   └── auth_service.dart             # Auth state management
├── models/
│   ├── api_response.dart             # API response models
│   └── user_model.dart              # User data models
├── widgets/
│   ├── error_handler.dart            # Error display widgets
│   └── signup/                       # Signup screen widgets
│       ├── index.dart                # Export all widgets
│       ├── signup_header_widget.dart # Header section
│       ├── signup_form_widget.dart   # Form fields
│       ├── signup_terms_widget.dart  # Terms checkbox
│       ├── signup_actions_widget.dart # Buttons and links
│       └── signup_success_dialog.dart # Success dialog
└── screens/
    └── auth/
        └── signup_screen.dart        # Main signup screen (refactored)
```
