# API Specification: Create Event

## Endpoint
```
POST /api/events
```

## Headers
```
Authorization: Bearer <token>
Content-Type: application/json
```

## Request Body

### Required Fields
- `name` (string, required): Event name
- `date` (string, required): Event date and time in ISO 8601 format (e.g., "2024-12-25T18:00:00Z")
- `type` (string, required): Event type - one of: `birthday`, `wedding`, `anniversary`, `graduation`, `holiday`, `baby_shower`, `house_warming`, `other`
- `privacy` (string, required): Event privacy - one of: `public`, `private`, `friends_only`
- `mode` (string, required): Event mode - one of: `in_person`, `online`, `hybrid`

### Optional Fields
- `description` (string, optional): Event description
- `location` (string, optional): Event location/address
- `meeting_link` (string, optional): Online meeting link (required if mode is `online` or `hybrid`)
- `wishlist_id` (string, optional): ID of existing wishlist to link to this event (if user selected "link existing wishlist")
- `invited_friends` (array of strings, optional): Array of friend IDs or usernames to invite

## Request Body Example

### Example 1: In-Person Event with New Wishlist
```json
{
  "name": "Ahmed's 30th Birthday",
  "description": "Join us for a celebration!",
  "date": "2024-12-25T18:00:00Z",
  "type": "birthday",
  "privacy": "friends_only",
  "mode": "in_person",
  "location": "123 Main Street, Cairo, Egypt",
  "invited_friends": ["friend_id_1", "friend_id_2", "friend_id_3"]
}
```

### Example 2: Online Event with Linked Wishlist
```json
{
  "name": "Virtual Graduation Party",
  "description": "Celebrating our graduation online!",
  "date": "2024-06-15T20:00:00Z",
  "type": "graduation",
  "privacy": "public",
  "mode": "online",
  "meeting_link": "https://zoom.us/j/123456789",
  "wishlist_id": "wishlist_12345",
  "invited_friends": ["friend_id_1", "friend_id_2"]
}
```

### Example 3: Hybrid Event without Wishlist
```json
{
  "name": "Company Anniversary",
  "description": "10 years celebration",
  "date": "2024-08-10T17:00:00Z",
  "type": "anniversary",
  "privacy": "public",
  "mode": "hybrid",
  "location": "Company HQ, Building A",
  "meeting_link": "https://meet.google.com/abc-defg-hij",
  "invited_friends": []
}
```

## Response Format

### Success Response (201 Created)
```json
{
  "success": true,
  "message": "Event created successfully",
  "data": {
    "id": "event_12345",
    "creator_id": "user_67890",
    "name": "Ahmed's 30th Birthday",
    "description": "Join us for a celebration!",
    "date": "2024-12-25T18:00:00Z",
    "type": "birthday",
    "status": "upcoming",
    "privacy": "friends_only",
    "mode": "in_person",
    "location": "123 Main Street, Cairo, Egypt",
    "meeting_link": null,
    "wishlist_id": "wishlist_abc123",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### Error Response (400 Bad Request)
```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "name": "Event name is required",
    "date": "Event date is required",
    "meeting_link": "Meeting link is required for online events"
  }
}
```

### Error Response (401 Unauthorized)
```json
{
  "success": false,
  "message": "Unauthorized. Please login again."
}
```

## Field Validations

### `name`
- Type: string
- Required: Yes
- Min length: 2 characters
- Max length: 100 characters

### `date`
- Type: string (ISO 8601 format)
- Required: Yes
- Must be a future date (not in the past)
- Format: `YYYY-MM-DDTHH:mm:ssZ` or `YYYY-MM-DDTHH:mm:ss.sssZ`



### `privacy`
- Type: string (enum)
- Required: Yes
- Allowed values: `public`, `private`, `friends_only`

### `mode`
- Type: string (enum)
- Required: Yes
- Allowed values: `in_person`, `online`, `hybrid`

### `description`
- Type: string
- Required: No
- Max length: 500 characters

### `location`
- Type: string
- Required: No (but recommended for `in_person` and `hybrid` events)
- Max length: 200 characters

### `meeting_link`
- Type: string (URL)
- Required: Yes if `mode` is `online` or `hybrid`
- Must be a valid URL format
- Common platforms: Zoom, Google Meet, Microsoft Teams, etc.

### `wishlist_id`
- Type: string (UUID or ID)
- Required: No
- Must be a valid existing wishlist ID that belongs to the user
- If provided, the event will be linked to this wishlist

### `invited_friends`
- Type: array of strings
- Required: No
- Each string should be a valid friend ID or username
- If empty array or not provided, no invitations will be sent initially





// Build request body
final requestBody = {
  'name': _nameController.text.trim(),
  'date': eventDateTime.toIso8601String(), // ISO 8601 format
  'type': _selectedEventType, // 'birthday', 'wedding', etc.
  'privacy': _selectedPrivacy, // 'public', 'private', 'friends_only'
  'mode': _selectedEventMode, // 'in_person', 'online', 'hybrid'
  
  // Optional fields
  if (_descriptionController.text.trim().isNotEmpty)
    'description': _descriptionController.text.trim(),
  
  if (_locationController.text.trim().isNotEmpty)
    'location': _locationController.text.trim(),
  
  if ((_selectedEventMode == 'online' || _selectedEventMode == 'hybrid') &&
      _meetingLinkController.text.trim().isNotEmpty)
    'meeting_link': _meetingLinkController.text.trim(),
  
  if (wishlistId != null)
    'wishlist_id': wishlistId,
  
  if (_invitedFriends.isNotEmpty)
    'invited_friends': _invitedFriends, // Array of friend IDs or usernames
};

// Send request
final response = await apiService.post('/events', data: requestBody);
```

## Backend Implementation Notes

### 1. Date/Time Validation
- Ensure the date is in the future (not in the past)
- Validate ISO 8601 format
- Store in UTC timezone

### 2. Meeting Link Validation
- If `mode` is `online` or `hybrid`, `meeting_link` MUST be provided
- Validate URL format
- Return 400 error if missing for online/hybrid events

### 3. Wishlist Validation
- If `wishlist_id` is provided, verify:
  - Wishlist exists
  - Wishlist belongs to the event creator
  - Wishlist is not already linked to another event (if business logic requires)

### 4. Friend Invitations
- Validate all friend IDs in `invited_friends` array
- Verify friendship relationship exists
- Create `EventInvitation` records with status `pending`
- Send notification to invited friends (optional)



### 6. Privacy Options
The frontend sends these values for `privacy`:
- `public` - Anyone can see the event
- `private` - Only creator can see
- `friends_only` - Only creator's friends can see

### 7. Mode Options
The frontend sends these values for `mode`:
- `in_person` - Physical location required
- `online` - Virtual event, meeting_link required
- `hybrid` - Both in-person and online, meeting_link required

## Response Requirements

The backend MUST return:
- `id`: The created event ID (for navigation)
- All event fields as shown in the success response example
- `wishlist_id`: The linked wishlist ID (if any)
- `created_at` and `updated_at`: Timestamps

The frontend uses the returned `id` to navigate to the event details page.

