# WishListy - Project Rules & Context for AI Assistants

> **This document provides context and guidelines for AI assistants working on the WishListy project.**
> 
> **Last Updated**: Current session
> **Project Status**: Active development - API integration phase

---

## 🎯 Project Concept

**WishListy** is a social gifting platform that helps people:
- Create and manage gift wishlists for different occasions
- Share wishlists with friends and family
- Coordinate group gifts for events
- Connect socially around gift-giving
- Get smart reminders for upcoming events

### Core Value Proposition
Make gift-giving easier, more organized, and more meaningful by connecting people through thoughtful gifting.

---

## 📍 Current State

### What's Done ✅
- Complete UI/UX implementation for all features
- Feature-based architecture structure
- Authentication screens and flow
- Core services setup (API Service, Localization, Permissions)
- State management structure (Cubit pattern ready)
- Repository pattern structure
- All screens implemented (wishlists, events, friends, profile, etc.)
- Localization support (English/Arabic with RTL)

### What's In Progress 🔄
- **Backend API Integration** - We're currently connecting to the backend APIs
- Base URL configured: `http://localhost:4000/api`
- Register API structure documented from Swagger

### What's Next ❌
- Complete authentication API integration (login, register)
- Integrate all feature APIs (wishlists, events, friends, etc.)
- Connect UI to real backend data
- Replace mock data with API responses

---

## 🏗️ Architecture Overview

### Structure Pattern
**Feature-based architecture** - Each feature is self-contained:

```
feature_name/
├── data/
│   ├── models/          # Data models with fromJson/toJson
│   └── repository/      # API calls go here
├── presentation/
│   ├── cubit/          # State management (use Cubit, NOT StatefulWidget for business logic)
│   ├── screens/        # UI screens
│   └── widgets/        # Feature-specific widgets
```

### State Management Rules

**CRITICAL**: Always use **Cubit pattern** for business logic state management.

✅ **DO Use Cubit For**:
- Data fetched from API
- Business logic state (loading, success, error)
- State shared between multiple screens
- Complex state with multiple possible states

❌ **DON'T Use Cubit For**:
- Simple local UI state (checkbox toggle, text field focus)
- Animation controllers
- Form field visibility

**Example**:
```dart
// ✅ CORRECT: Use Cubit for API data
class EventsCubit extends Cubit<EventsState> {
  final EventsRepository repository;
  
  EventsCubit(this.repository) : super(EventsInitial());
  
  Future<void> loadEvents() async {
    emit(EventsLoading());
    try {
      final events = await repository.getEvents();
      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }
}

// ❌ WRONG: Don't use setState for API calls
setState(() {
  _events = await api.getEvents(); // NO!
});
```

---

## 🔌 Backend API Configuration

### Base Configuration

- **Base URL**: `http://localhost:4000/api`
- **Service Location**: `lib/core/services/api_service.dart`
- **Auth Token**: JWT Bearer tokens stored in SharedPreferences
- **Timeout**: 30 seconds

### API Integration Pattern

**ALWAYS follow this pattern for API integration**:

1. **Create Model** (in `feature/data/models/`):
   ```dart
   class EventModel {
     final String id;
     final String title;
     
     EventModel({required this.id, required this.title});
     
     factory EventModel.fromJson(Map<String, dynamic> json) {
       return EventModel(
         id: json['id'],
         title: json['title'],
       );
     }
     
     Map<String, dynamic> toJson() {
       return {
         'id': id,
         'title': title,
       };
     }
   }
   ```

2. **Create Repository** (in `feature/data/repository/`):
   ```dart
   class EventsRepository {
     final ApiService apiService;
     
     EventsRepository(this.apiService);
     
     Future<List<EventModel>> getEvents() async {
       try {
         final response = await apiService.get('/events');
         return (response['data'] as List)
             .map((json) => EventModel.fromJson(json))
             .toList();
       } catch (e) {
         throw Exception('Failed to load events: $e');
       }
     }
   }
   ```

3. **Create Cubit** (in `feature/presentation/cubit/`):
   ```dart
   class EventsCubit extends Cubit<EventsState> {
     final EventsRepository repository;
     
     EventsCubit(this.repository) : super(EventsInitial());
     
     Future<void> loadEvents() async {
       emit(EventsLoading());
       try {
         final events = await repository.getEvents();
         emit(EventsLoaded(events));
       } catch (e) {
         emit(EventsError(e.toString()));
       }
     }
   }
   ```

4. **Use in UI**:
   ```dart
   BlocBuilder<EventsCubit, EventsState>(
     builder: (context, state) {
       if (state is EventsLoading) return CircularProgressIndicator();
       if (state is EventsError) return Text(state.message);
       if (state is EventsLoaded) {
         return ListView.builder(...);
       }
       return Container();
     },
   )
   ```

### Known API Endpoints

#### Authentication

**Register** (documented from Swagger):
```http
POST /api/auth/register
Body: {
  "fullName": "John Doe",
  "username": "johndoe",
  "password": "securePassword123"
}
Response: {
  "success": true,
  "token": "jwt_token",
  "user": {
    "id": "user_id",
    "fullName": "John Doe",
    "username": "johndoe"
  }
}
```

**Login** (to be integrated):
```http
POST /api/auth/login
Body: {
  "email": "user@example.com",
  "password": "password123"
}
```

---

## 📝 Development Rules

### File Naming
- **Screens**: `[feature]_screen.dart` (snake_case)
- **Widgets**: `[description]_widget.dart`
- **Cubits**: `[feature]_cubit.dart`
- **Repositories**: `[feature]_repository.dart`
- **Models**: `[entity]_model.dart`

### Code Organization

1. **Never put API calls directly in UI/widgets**
   - Always use Repository → Cubit → UI flow

2. **Always handle errors**
   - Use try-catch in repositories
   - Emit error states in Cubits
   - Show user-friendly error messages in UI

3. **Always show loading states**
   - Emit loading state before API call
   - Show loading indicator in UI
   - Clear loading state after success/error

4. **Use models for all API responses**
   - Never use raw `Map<String, dynamic>` in business logic
   - Always create model classes with `fromJson`/`toJson`

### Error Handling Pattern

```dart
// Repository
try {
  final response = await apiService.get('/endpoint');
  return Model.fromJson(response['data']);
} catch (e) {
  if (e is ApiException) {
    throw Exception(e.message); // User-friendly message
  }
  throw Exception('Failed to load data');
}

// Cubit
try {
  emit(LoadingState());
  final data = await repository.getData();
  emit(SuccessState(data));
} catch (e) {
  emit(ErrorState(e.toString()));
}
```

---

## 🎨 UI Guidelines

### Current Theme
- Light and dark theme support
- Material Design 3
- Custom colors defined in `lib/core/theme/app_theme.dart`
- Arabic RTL support

### Common Patterns

**Loading State**:
```dart
if (state is LoadingState) {
  return Center(child: CircularProgressIndicator());
}
```

**Error State**:
```dart
if (state is ErrorState) {
  return Center(
    child: Column(
      children: [
        Text('Error: ${state.message}'),
        ElevatedButton(
          onPressed: () => cubit.retry(),
          child: Text('Retry'),
        ),
      ],
    ),
  );
}
```

**Empty State**:
```dart
if (state is LoadedState && state.data.isEmpty) {
  return EmptyStateWidget(message: 'No items found');
}
```

---

## 🔄 Current Development Focus

### Immediate Tasks

1. **Update API Base URL**
   - Change from Railway URL to `http://localhost:4000/api`
   - Location: `lib/core/services/api_service.dart`

2. **Complete Authentication Integration**
   - Verify Register API works with current implementation
   - Integrate Login API
   - Test token storage and retrieval

3. **API Integration Priority**
   - Authentication (register, login) - **HIGHEST PRIORITY**
   - Wishlists CRUD - **HIGH PRIORITY**
   - Events CRUD - **HIGH PRIORITY**
   - Friends management - **MEDIUM PRIORITY**
   - Profile management - **MEDIUM PRIORITY**
   - Notifications - **LOW PRIORITY**
   - Rewards/Reminders - **LOW PRIORITY**

### What to Do When Adding New API

1. Check Swagger/API docs for endpoint structure
2. Create/update model class with correct fields
3. Add repository method following pattern
4. Update Cubit to call repository
5. Update UI to use Cubit state
6. Test error handling and loading states
7. Update this document if needed

---

## 🐛 Common Issues & Solutions

### Issue: API calls not working
**Check**:
- Backend server running on `localhost:4000`?
- Base URL correct in `api_service.dart`?
- Token set correctly if authenticated endpoint?

### Issue: State not updating
**Check**:
- Using `BlocBuilder` or `BlocListener` correctly?
- Emitting new state in Cubit (not modifying existing state)?
- Cubit provided correctly in widget tree?

### Issue: Models not parsing
**Check**:
- `fromJson` matches API response structure?
- Nullable fields handled correctly?
- Type conversions correct (String vs int, etc.)?

---

## 📚 Key Files Reference

### Core Services
- `lib/core/services/api_service.dart` - Main HTTP client (Dio)
- `lib/core/services/localization_service.dart` - Language management
- `lib/features/auth/data/repository/auth_repository.dart` - Auth logic

### Configuration
- `lib/core/utils/app_routes.dart` - All app routes
- `lib/core/utils/app_constants.dart` - App constants
- `lib/core/theme/app_theme.dart` - Theme configuration

### Main Entry
- `lib/main.dart` - App initialization and setup

---

## 🎯 Project Goals

### Short-term (Current Sprint)
1. Complete authentication API integration
2. Connect wishlists to backend
3. Connect events to backend
4. Replace all mock data with real API calls

### Long-term
1. Full feature parity with backend
2. Real-time notifications
3. Offline support
4. Performance optimization
5. Testing coverage

---

## 💡 Important Reminders

1. **Always use Cubit for business logic** - not StatefulWidget
2. **Always use Repository for API calls** - never call ApiService directly from UI
3. **Always create models** - don't use raw JSON maps
4. **Always handle errors** - user-friendly messages
5. **Always show loading states** - better UX
6. **Follow feature-based structure** - keep features self-contained
7. **Update this file** - when adding new patterns or conventions

---

## 🔗 Related Documentation

- `README.md` - Full project documentation
- `BUSINESS_REQUIREMENTS.md` - Business logic and requirements
- `API_INTEGRATION_GUIDE.md` - Detailed API integration guide
- `TECHNICAL_API_DOCUMENTATION.md` - Complete API documentation

---

**Remember**: When in doubt, follow the existing patterns in the codebase. Consistency is key!

---

*Last Updated: Current development session*
*Next Update: After completing API integration*

