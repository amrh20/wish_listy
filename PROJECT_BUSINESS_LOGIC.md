# Wish Listy - Business Logic & Functional Specification Document

**Version:** 1.0  
**Last Updated:** Current  
**Purpose:** Comprehensive business rules and functional specifications for QA Testing  
**Target Audience:** QA Team, Manual Testers

---

## 1. Project Overview

### 1.1 Description
**Wish Listy** is a social gifting platform that enables users to create and manage gift wishlists, share them with friends and family, coordinate group gifts for events, and enhance relationships through thoughtful gifting.

**Tagline:** "Connect through thoughtful gifting" 🎁

### 1.2 Target Audience

#### Guest Users
- Can browse public wishlists and events without registration
- Cannot create wishlists, manage events, or add friends
- Must sign in to access full features
- Restrictions:
  - Cannot reserve items
  - Cannot create events
  - Cannot manage friends
  - Cannot access profile settings

#### Registered Users
- Full access to all features
- Can create unlimited wishlists
- Can manage events and invite friends
- Can connect with other users
- Can reserve and purchase items
- Access to profile customization and settings

---

## 2. Core Features & User Stories

### 2.1 Authentication

#### 2.1.1 Guest Mode
**How it works:**
- User clicks "Explore as Guest" on Welcome Screen
- App sets user state to `guest`
- Clears any authentication tokens
- Navigates to Main Navigation with limited features

**What guests can do:**
- ✅ Browse public wishlists
- ✅ View public events
- ✅ Search for users and their public wishlists
- ✅ View wishlist items (read-only)

**What guests cannot do:**
- ❌ Create wishlists
- ❌ Reserve items
- ❌ Create or manage events
- ❌ Send/accept friend requests
- ❌ Access profile settings
- ❌ Mark items as purchased/received

**Guest restrictions handling:**
- When guest tries to access restricted feature, a prompt dialog appears
- Dialog shows: "This feature requires sign in" with Sign In/Sign Up buttons

#### 2.1.2 Sign Up
**Required fields:**
- Full Name (minimum 2 characters, maximum 50 characters)
- Username (Email or Phone Number - must be valid)
- Password (minimum 6 characters)
- Confirm Password (must match password)
- **Mandatory:** Privacy Policy & Terms & Conditions agreement checkbox

**Validation rules:**
- Full Name:
  - Required
  - Minimum 2 characters
  - Maximum 50 characters
- Username:
  - Required
  - Must be valid email OR valid phone number
  - Email format validation
  - Phone number: 7-15 digits (international format with + allowed)
- Password:
  - Required
  - Minimum 6 characters
- Confirm Password:
  - Required
  - Must match password exactly
- Terms Agreement:
  - **MUST** be checked before Sign Up button becomes active

**User flow:**
1. User enters all required fields
2. User checks "I agree to the Privacy Policy and Terms & Conditions"
3. User can click links to view Privacy Policy and Terms in separate screen
4. Sign Up button is enabled only when all fields valid AND terms agreed
5. On successful registration:
   - User receives success message
   - Token is saved
   - User is automatically logged in
   - Navigates to Home Screen

#### 2.1.3 Login
**Required fields:**
- Username (Email or Phone Number)
- Password

**User flow:**
1. User enters username and password
2. Clicks "Sign In"
3. On success:
   - Token is saved
   - User state set to `authenticated`
   - Socket.IO connection established for real-time notifications
   - Navigates to Home Screen

#### 2.1.4 Forgot Password
**User flow:**
1. User enters email address
2. Clicks "Send Reset Link"
3. Success message: "Check your email"
4. User receives password reset link via email

---

### 2.2 Profile Management

#### 2.2.1 Profile Information
**Editable fields:**
- Full Name
- Email/Phone
- Profile Picture
- Bio
- Location
- Birth Date
- Gender (Male, Female, Other)

**Privacy settings:**
- Profile Visibility (Public, Friends Only, Private)
- Wishlist Visibility (Public, Friends Only, Private)
- Event Visibility (Public, Friends Only, Private)
- Allow Friend Requests (Yes/No)
- Show Online Status (Yes/No)
- Show Last Seen (Yes/No)
- Show Birth Date (Yes/No)

---

### 2.3 Wishlists

#### 2.3.1 Creating Wishlists
**Required fields:**
- Wishlist Name (required)
- Privacy Setting (required): Public, Friends Only, or Private
- Description (optional)
- Category (optional)

**Privacy options:**
- **Public:** Anyone can find and view this wishlist
- **Friends Only:** Only approved friends can view
- **Private:** Only you can view (not recommended for gifting)

**User flow:**
1. Navigate to Wishlists tab
2. Click "Create Wishlist" button
3. Fill in required fields
4. Select privacy setting
5. Optionally add description and category
6. Click "Create"
7. Success message appears
8. Navigate to newly created wishlist items screen

#### 2.3.2 Adding Items to Wishlist
**Required fields:**
- Item Name (required)
- Priority (required): Low, Medium, High, Urgent

**Optional fields:**
- Description
- Image (upload or URL)
- Price/Price Range
- Product Link (URL)
- Store Name
- Store Location
- Brand/Keywords
- Category

**User flow:**
1. Open wishlist
2. Click "Add Item" button
3. Fill in item name and priority (minimum required)
4. Optionally add other details
5. Click "Save"
6. Item appears in wishlist

#### 2.3.3 Wishlist Visibility Rules

**Public Wishlists:**
- Visible to everyone (including guests)
- Appears in search results
- Can be viewed by non-friends
- Items can be reserved by any registered user

**Friends Only:**
- Visible only to approved friends
- Not visible in public search
- Items can be reserved only by friends

**Private:**
- Visible only to owner
- Not visible to anyone else
- Items cannot be reserved by others (defeats purpose, but technically allowed)

---

### 2.4 Gifting Logic (Critical Business Rules)

#### 2.4.1 Reserving an Item (Secret Reservation)

**How it works:**
- A registered user (friend or public user) can reserve an item from someone's wishlist
- **IMPORTANT:** Reservation is **SECRET** - the wishlist owner does NOT see who reserved it
- Owner only sees that the item is "Reserved" but not by whom
- Reserved items show as "Reserved" with a lock icon
- Reserved items cannot be reserved by another user

**User flow (Reserver perspective):**
1. Browse friend's or public wishlist
2. Find item that is not yet reserved or purchased
3. Click "Reserve This Item" button
4. Item is marked as reserved
5. Reservation notification is sent to wishlist owner (item_reserved notification)
6. Owner sees "Item Reserved" but not who reserved it

**User flow (Owner perspective):**
1. Owner sees item status changed to "Reserved"
2. Owner does NOT see who reserved it
3. Owner receives notification: "Someone reserved [Item Name]"
4. Owner cannot unreserve the item (only the reserver can)

**Business rules:**
- ✅ Only registered users can reserve (guests cannot)
- ✅ Items can only be reserved if not already reserved or purchased
- ✅ Only one user can reserve an item at a time
- ✅ Reservation is SECRET (owner doesn't know who reserved)
- ✅ Reserver can cancel their own reservation
- ✅ When item is reserved, it cannot be reserved by others

**API endpoint:** `PUT /api/items/{itemId}/reserve`  
**Request body:** `{ "action": "reserve", "quantity": 1 }`

#### 2.4.2 Purchasing an Item

**How it works:**
- After reserving an item, the reserver can mark it as "Purchased"
- This indicates the reserver has bought the item
- **Owner still does not see who purchased it** (maintains secrecy)
- Item status changes from "Reserved" to "Purchased"
- Owner receives notification: "Someone purchased [Item Name]"

**User flow (Purchaser perspective):**
1. User has reserved an item
2. User purchases the physical item
3. User opens the reserved item details
4. Clicks "Mark as Purchased" button
5. Item status changes to "Purchased"
6. Notification sent to owner

**Business rules:**
- ✅ Only the person who reserved can mark as purchased
- ✅ Item must be reserved before it can be marked as purchased
- ✅ Purchase is SECRET (owner doesn't see who purchased)
- ✅ Once purchased, item cannot be unreserved or repurchased

**API endpoint:** `PUT /api/items/{itemId}/purchase`  
**Request body:** `{}` (optional: `{ "purchasedBy": userId }`)

#### 2.4.3 Receiving an Item (Owner Marks as Received)

**How it works:**
- **Only the wishlist owner** can mark an item as "Received"
- Owner marks item as received after physically receiving the gift
- This is a confirmation that the gift was successfully received
- When marked as received, the purchaser (giver) receives notification: "Item Received"
- Item status changes from "Purchased" to "Received"

**User flow (Owner perspective):**
1. Owner receives a purchased item as a gift
2. Owner opens item details
3. Sees item status is "Purchased"
4. Clicks "Mark Received" button
5. Item status changes to "Received"
6. Giver receives notification: "[Owner Name] marked [Item Name] as received"

**Business rules:**
- ✅ Only wishlist owner can mark item as received
- ✅ Item must be purchased before it can be marked as received
- ✅ Owner can toggle received status (mark/unmark)
- ✅ When marked as received, giver is notified (item_received notification)

**API endpoint:** `PUT /api/items/{itemId}/received`  
**Request body:** `{ "isReceived": true/false }`

#### 2.4.4 Item Status Flow Summary

```
Available → Reserved (Secret) → Purchased (Secret) → Received (Owner confirms)
   ↓              ↓                    ↓
Owner sees    Owner sees          Owner marks
"Available"   "Reserved"          as "Received"
             (but not by whom)    (giver notified)
```

**Key points:**
- Owner never sees who reserved/purchased until marked as received
- Only reserver can mark as purchased
- Only owner can mark as received
- All status changes trigger notifications

#### 2.4.5 Unreserving an Item

**How it works:**
- The person who reserved an item can cancel their reservation
- Item status changes back to "Available"
- Owner receives notification: "Item Unreserved"

**User flow:**
1. User has reserved an item
2. User opens item details
3. Clicks "Unreserve" or "Cancel Reservation" button
4. Confirmation dialog appears
5. User confirms
6. Item status changes back to "Available"
7. Owner notified

**Business rules:**
- ✅ Only the reserver can unreserve their own reservation
- ✅ Owner cannot unreserve (they don't know who reserved)
- ✅ Once purchased, cannot unreserve (must mark as purchased first)

**API endpoint:** `PUT /api/items/{itemId}/reserve`  
**Request body:** `{ "action": "cancel" }`

---

### 2.5 Events

#### 2.5.1 Creating Events

**Required fields:**
- Event Name (required)
- Event Type (required): Birthday, Wedding, Anniversary, Graduation, Baby Shower, Housewarming, Holiday, Other
- Date (required)
- Privacy Setting (required): Public, Friends Only, Private

**Optional fields:**
- Time
- Location/Address
- Description
- Event Mode: In Person, Online, Hybrid
- Online Meeting Link (for online/hybrid events)
- Wishlist: Create new or link existing

**User flow:**
1. Navigate to Events tab
2. Click "Create Event" button
3. Fill in required fields
4. Optionally add location, description, etc.
5. Choose wishlist option:
   - Create new wishlist for event
   - Link to existing wishlist
   - No wishlist (can add later)
6. Click "Create Event"
7. Success message appears
8. Navigate to event details screen

**Privacy options:**
- **Public:** Anyone can see and join the event
- **Friends Only:** Only friends can see the event
- **Private:** Only invited guests can see the event

#### 2.5.2 Inviting Guests to Events

**How it works:**
- Event creator can invite friends as guests
- Guests receive event invitation notification
- Guests can respond with RSVP: Accept, Maybe, or Decline

**User flow (Event Creator):**
1. Open event details
2. Navigate to "Guest Management" or "Invite Guests"
3. Search for friends by name or email
4. Select friends to invite
5. Optionally add personal message
6. Click "Send Invitations"
7. Friends receive notifications

**User flow (Guest):**
1. Receive event invitation notification
2. Tap notification to open event details
3. See RSVP buttons: Accept, Maybe, Decline
4. Select response
5. Event creator sees updated guest list with RSVP status

#### 2.5.3 RSVP Logic (Accept/Maybe/Decline)

**RSVP Options:**
- **Accepted:** Guest confirms attendance
- **Maybe:** Guest is unsure (interested but not confirmed)
- **Declined:** Guest cannot attend
- **Pending:** Guest has not responded yet (default state)

**User flow:**
1. Guest receives event invitation
2. Guest opens event details
3. Guest sees current RSVP status (if already responded)
4. Guest can change response at any time
5. Event creator sees updated status in guest list

**Business rules:**
- ✅ Guest can change RSVP response multiple times
- ✅ Default status is "Pending" for new invitations
- ✅ Event creator can see all guest RSVP statuses
- ✅ Event creator cannot force RSVP (guest must respond)
- ✅ RSVP changes trigger notifications to event creator

**API endpoint:** `PUT /api/events/{eventId}/respond`  
**Request body:** `{ "status": "accepted" | "maybe" | "declined" }`

**RSVP Status Display:**
- **Accepted:** Green highlight, "You are going! Don't forget a gift 🎁"
- **Maybe:** Orange highlight, "Maybe" with help icon
- **Declined:** Red highlight, "You declined"
- **Pending:** Shows RSVP action buttons

---

### 2.6 Social Features

#### 2.6.1 Friend Requests

**How it works:**
- Users can send friend requests to other users
- Recipient receives notification
- Recipient can Accept or Decline
- Once accepted, users become friends

**User flow (Sending request):**
1. Search for user by name, username, or email
2. View user profile
3. Click "Send Friend Request" button
4. Recipient receives notification

**User flow (Responding to request):**
1. Receive friend request notification
2. Tap notification or go to Friends screen → Requests tab
3. See request with Accept/Decline buttons
4. Click Accept or Decline
5. If accepted, users become friends
6. If declined, request is removed

**Business rules:**
- ✅ Users cannot send friend request to themselves
- ✅ Users cannot send duplicate requests (if already sent, shows "Request Pending")
- ✅ Users cannot send request if already friends (shows "Already Friends")
- ✅ Recipient must respond before becoming friends
- ✅ Declined requests do not allow retry automatically (user must send new request)

**API endpoints:**
- Send request: `POST /api/friends/request`
- Accept: `POST /api/friends/request/{requestId}/respond` with `{ "action": "accept" }`
- Decline: `POST /api/friends/request/{requestId}/respond` with `{ "action": "decline" }`

#### 2.6.2 Friend Search

**How it works:**
- Users can search for friends by:
  - Full Name
  - Username
  - Email address

**Search results show:**
- User profile picture
- Full name
- Friendship status:
  - "Send Request" (not friends, no pending request)
  - "Request Pending" (request sent, waiting for response)
  - "Already Friends" (friends)
  - Mutual friends count

---

## 3. Notification Logic (Detailed Reference)

### 3.1 Notification Types

The app supports the following notification types:

1. `friendRequest` - Friend request received
2. `friendRequestAccepted` - Friend request was accepted
3. `friendRequestRejected` - Friend request was declined
4. `eventInvitation` - Event invitation received
5. `eventResponse` - Event RSVP response (accepted/maybe/declined by guest)
6. `eventUpdate` - Event details were updated
7. `eventReminder` - Event reminder (upcoming event)
8. `itemReserved` - Item was reserved by someone
9. `itemUnreserved` - Item reservation was canceled
10. `itemPurchased` - Item was marked as purchased (also includes `item_received` type)
11. `wishlistShared` - Wishlist was shared with user
12. `general` - General notification

### 3.2 Notification Details

#### 3.2.1 Friend Request Notification
- **Type:** `friendRequest`
- **Trigger:** When User A sends friend request to User B
- **Recipient:** User B (the person receiving the request)
- **Notification contains:**
  - Title: "New Friend Request"
  - Message: "[Sender Name] wants to be friends"
  - `relatedId`: Friend request ID
  - `data.relatedUser`: Sender's user object (for profile navigation)
- **Action when tapped:**
  - Navigates to Friend Profile screen (sender's profile)
  - Shows Accept/Decline buttons in notification UI
- **Actions available:**
  - **Accept:** Calls API to accept request, removes notification, adds to friends list
  - **Decline:** Calls API to decline request, removes notification

#### 3.2.2 Friend Request Accepted Notification
- **Type:** `friendRequestAccepted`
- **Trigger:** When User B accepts User A's friend request
- **Recipient:** User A (the person who sent the request)
- **Notification contains:**
  - Title: "Friend Request Accepted"
  - Message: "[User B Name] accepted your friend request"
  - `relatedId`: Friend ID or request ID
  - `data.relatedUser`: Accepter's user object
- **Action when tapped:**
  - Navigates to Friend Profile screen (accepter's profile)

#### 3.2.3 Friend Request Rejected Notification
- **Type:** `friendRequestRejected`
- **Trigger:** When User B declines User A's friend request
- **Recipient:** User A (the person who sent the request)
- **Notification contains:**
  - Title: "Friend Request Declined"
  - Message: "[User B Name] declined your friend request"
  - `data.relatedUser`: Decliner's user object
- **Action when tapped:**
  - Navigates to Friend Profile screen (decliner's profile)

#### 3.2.4 Event Invitation Notification
- **Type:** `eventInvitation`
- **Trigger:** When Event Creator invites User to event
- **Recipient:** Invited user
- **Notification contains:**
  - Title: "Event Invitation"
  - Message: "[Creator Name] invited you to [Event Name]"
  - `relatedId`: Event ID
  - `data.event`: Event object
- **Action when tapped:**
  - Navigates to Event Details screen
- **Actions available:**
  - RSVP buttons in notification UI: Accept, Maybe, Decline
  - When RSVP is selected, calls API and updates notification

#### 3.2.5 Event Response Notification
- **Type:** `eventResponse`
- **Trigger:** When invited guest responds to event invitation (Accept/Maybe/Decline)
- **Recipient:** Event Creator
- **Notification contains:**
  - Title: "Event RSVP"
  - Message: "[Guest Name] is going to [Event Name]" (or "marked as maybe" or "declined")
  - `relatedId`: Event ID
  - `data.relatedUser`: Guest's user object
  - `data.responseType`: "accepted", "maybe", or "declined"
- **Action when tapped:**
  - Navigates to Event Details screen
  - Shows updated guest list with RSVP status

#### 3.2.6 Event Update Notification
- **Type:** `eventUpdate`
- **Trigger:** When Event Creator updates event details (date, location, description, etc.)
- **Recipient:** All invited guests
- **Notification contains:**
  - Title: "Event Updated"
  - Message: "[Event Name] has been updated"
  - `relatedId`: Event ID
- **Action when tapped:**
  - Navigates to Event Details screen

#### 3.2.7 Event Reminder Notification
- **Type:** `eventReminder`
- **Trigger:** Automated reminder before event date (e.g., 1 day before, 1 hour before)
- **Recipient:** All invited guests (and optionally event creator)
- **Notification contains:**
  - Title: "Event Reminder"
  - Message: "[Event Name] is [time period] away"
  - `relatedId`: Event ID
- **Action when tapped:**
  - Navigates to Event Details screen

#### 3.2.8 Item Reserved Notification
- **Type:** `itemReserved`
- **Trigger:** When someone reserves an item from user's wishlist
- **Recipient:** Wishlist Owner
- **Notification contains:**
  - Title: "Item Reserved"
  - Message: "Someone reserved [Item Name]" (SECRET - does not reveal who)
  - `relatedId`: Item ID
  - `relatedWishlistId`: Wishlist ID
  - `data.item`: Item object
- **Action when tapped:**
  - Navigates to Wishlist Items screen
  - Shows item with "Reserved" status (but not by whom)

#### 3.2.9 Item Unreserved Notification
- **Type:** `itemUnreserved`
- **Trigger:** When someone cancels their reservation of an item
- **Recipient:** Wishlist Owner
- **Notification contains:**
  - Title: "Item Unreserved"
  - Message: "Item [Item Name] is now available"
  - `relatedId`: Item ID
  - `relatedWishlistId`: Wishlist ID
- **Action when tapped:**
  - Navigates to Wishlist Items screen
  - Shows item with "Available" status

#### 3.2.10 Item Purchased Notification
- **Type:** `itemPurchased` (also handles `item_received`)
- **Trigger:** When reserver marks item as purchased
- **Recipient:** Wishlist Owner
- **Notification contains:**
  - Title: "Item Purchased"
  - Message: "Someone purchased [Item Name]" (SECRET - does not reveal who)
  - `relatedId`: Item ID
  - `relatedWishlistId`: Wishlist ID
- **Action when tapped:**
  - Navigates to Wishlist Items screen or Item Details screen
  - Shows item with "Purchased" status

#### 3.2.11 Item Received Notification (Special Case)
- **Type:** `itemPurchased` (with `data.type: "item_received"` or `notificationType: "item_received"`)
- **Trigger:** When wishlist owner marks item as received
- **Recipient:** Item Purchaser (the person who reserved and purchased)
- **Notification contains:**
  - Title: "Item Received"
  - Message: "[Owner Name] marked [Item Name] as received"
  - `relatedId`: Item ID
  - `relatedWishlistId`: Wishlist ID
  - `data.type`: "item_received"
- **Action when tapped:**
  - Navigates to Item Details screen
  - Shows item with "Received" status

**Note:** The `item_received` notification is a special case that uses the `itemPurchased` type but has different data. The app checks for `data.type == "item_received"` to distinguish it.

#### 3.2.12 Wishlist Shared Notification
- **Type:** `wishlistShared`
- **Trigger:** When user shares wishlist with another user
- **Recipient:** User with whom wishlist was shared
- **Notification contains:**
  - Title: "Wishlist Shared"
  - Message: "[Owner Name] shared [Wishlist Name] with you"
  - `relatedId`: Wishlist ID
- **Action when tapped:**
  - Navigates to Wishlist Items screen

### 3.3 Notification Marking as Read

- Notifications can be marked as read individually
- "Mark All as Read" button marks all notifications as read
- Read notifications appear with different styling (no unread indicator)
- Tapping a notification automatically marks it as read

### 3.4 Notification Display

**Notification Screen:**
- Shows all notifications in chronological order
- Groups by "Today" and "Earlier"
- Unread notifications show blue dot indicator
- Shows notification count in header

**Notification Dropdown:**
- Shows last 5 notifications
- Appears when tapping notification bell icon
- Quick actions (Accept/Decline for friend requests, RSVP for events)
- "View All Notifications" button at bottom

---

## 4. Validation Rules

### 4.1 Authentication Validation

#### 4.1.1 Registration
- **Full Name:**
  - Required field
  - Minimum 2 characters
  - Maximum 50 characters
  - Cannot be empty or whitespace only

- **Username (Email or Phone):**
  - Required field
  - Must be valid email format OR valid phone number
  - Email validation: Standard email regex pattern
  - Phone validation:
    - International format: + followed by 7-15 digits
    - Local format: 7-15 digits only
    - Can include spaces, dashes, parentheses (cleaned before validation)

- **Password:**
  - Required field
  - Minimum 6 characters
  - No maximum length restriction (reasonable limit should be applied)

- **Confirm Password:**
  - Required field
  - Must match password exactly
  - Case-sensitive

- **Terms Agreement:**
  - **Mandatory checkbox**
  - Sign Up button is disabled until checked
  - User must click links to view Privacy Policy and Terms & Conditions

#### 4.1.2 Login
- **Username:**
  - Required field
  - Must be valid email or phone (same validation as registration)

- **Password:**
  - Required field
  - Minimum 6 characters

### 4.2 Wishlist Validation

- **Wishlist Name:**
  - Required field
  - Cannot be empty

- **Privacy Setting:**
  - Required field
  - Must be one of: Public, Friends Only, Private

- **Description:**
  - Optional field
  - No length restrictions (reasonable limit recommended)

### 4.3 Item Validation

- **Item Name:**
  - Required field
  - Cannot be empty

- **Priority:**
  - Required field
  - Must be one of: Low, Medium, High, Urgent

- **Price:**
  - Optional field
  - Must be valid number if provided
  - Cannot be negative

- **Product Link:**
  - Optional field
  - Must be valid URL format if provided

- **Image URL:**
  - Optional field
  - Must be valid URL format if provided

### 4.4 Event Validation

- **Event Name:**
  - Required field
  - Cannot be empty

- **Event Type:**
  - Required field
  - Must be one of: Birthday, Wedding, Anniversary, Graduation, Baby Shower, Housewarming, Holiday, Other

- **Date:**
  - Required field
  - Must be valid date
  - Can be in past or future (no restriction)

- **Privacy Setting:**
  - Required field
  - Must be one of: Public, Friends Only, Private

### 4.5 Friend Request Validation

- **Search Query:**
  - Can search by name, username, or email
  - Minimum 1 character to trigger search
  - No special validation required (search handles partial matches)

- **Cannot send friend request to:**
  - Yourself
  - Users who are already friends
  - Users who have a pending request (either direction)

### 4.6 General Validation Rules

- **Required fields:** Must be filled before form submission
- **Email format:** Must match standard email regex
- **Phone format:** 7-15 digits (international or local)
- **URL format:** Must be valid HTTP/HTTPS URL
- **Password strength:** Minimum 6 characters (enhanced validation with uppercase/lowercase/numbers recommended but not currently enforced)
- **Name fields:** Cannot contain only whitespace
- **Text length:** Reasonable limits should be enforced (e.g., 50 chars for names, 500 chars for descriptions)

---

## 5. User State Management

### 5.1 User States

The app supports three user states:

1. **Guest (`UserState.guest`):**
   - No authentication token
   - Limited feature access
   - Can browse public content

2. **Authenticated (`UserState.authenticated`):**
   - Has valid authentication token
   - Full feature access
   - Socket.IO connected for real-time notifications

3. **Loading (`UserState.loading`):**
   - Initial state while checking authentication
   - Shows loading screen

### 5.2 State Transitions

```
Loading → Guest (if no saved login)
Loading → Authenticated (if valid token found)
Guest → Authenticated (after login/register)
Authenticated → Guest (after logout)
```

---

## 6. Privacy & Security

### 6.1 Data Privacy

- **Guest users:** No personal data stored, no API calls made
- **Authenticated users:** Data stored locally and on server
- **Authentication tokens:** Stored securely in SharedPreferences
- **Tokens cleared:** On logout and when switching to guest mode

### 6.2 Privacy Settings

Users can control:
- Profile visibility (Public, Friends Only, Private)
- Wishlist visibility (Public, Friends Only, Private)
- Event visibility (Public, Friends Only, Private)
- Who can send friend requests
- Online status visibility
- Last seen visibility

---

## 7. Error Handling

### 7.1 Network Errors

- **No internet connection:** Shows error message, allows retry
- **Server error:** Shows generic error message
- **Timeout:** Shows timeout error, allows retry

### 7.2 Authentication Errors

- **Invalid credentials:** Shows "Invalid email or password" message
- **Account not found:** Shows appropriate error message
- **Token expired:** Automatically logs out user, shows login screen

### 7.3 Validation Errors

- **Required fields:** Shows inline error messages
- **Invalid format:** Shows format-specific error messages
- **Mismatched passwords:** Shows "Passwords do not match" message

### 7.4 Guest Restriction Errors

- **Feature requires login:** Shows dialog with Sign In/Sign Up options
- **Cannot perform action:** Shows message explaining guest limitations

---

## 8. Localization

### 8.1 Supported Languages

- **English (en)** - Default
- **Arabic (ar)** - Full RTL support

### 8.2 Language Switching

- Users can switch language in Profile → Settings → Language
- App automatically detects device language on first launch
- Language preference is saved and persists across app restarts

### 8.3 Font Support

- **English:** Nunito (Google Fonts)
- **Arabic:** Mestika (Local font files)

---

## 9. Testing Scenarios (Quick Reference)

### 9.1 Authentication Testing

1. ✅ Guest mode - browse without account
2. ✅ Sign up with valid data
3. ✅ Sign up with invalid email
4. ✅ Sign up with weak password (< 6 chars)
5. ✅ Sign up without agreeing to terms (button disabled)
6. ✅ Login with valid credentials
7. ✅ Login with invalid credentials
8. ✅ Forgot password flow
9. ✅ Logout functionality

### 9.2 Wishlist Testing

1. ✅ Create public wishlist
2. ✅ Create friends-only wishlist
3. ✅ Create private wishlist
4. ✅ Add item to wishlist
5. ✅ Edit item
6. ✅ Delete item
7. ✅ Search wishlists
8. ✅ View friend's public wishlist
9. ✅ Cannot view friend's private wishlist

### 9.3 Gifting Logic Testing

1. ✅ Reserve item (secret - owner doesn't see who)
2. ✅ Cannot reserve already reserved item
3. ✅ Unreserve own reservation
4. ✅ Mark reserved item as purchased
5. ✅ Owner marks purchased item as received
6. ✅ Guest cannot reserve items
7. ✅ Item status flow: Available → Reserved → Purchased → Received

### 9.4 Event Testing

1. ✅ Create event with all fields
2. ✅ Create event with minimal fields
3. ✅ Invite friends to event
4. ✅ Guest RSVP: Accept
5. ✅ Guest RSVP: Maybe
6. ✅ Guest RSVP: Decline
7. ✅ Change RSVP response
8. ✅ Event creator sees guest RSVP statuses
9. ✅ Link wishlist to event
10. ✅ Create new wishlist for event

### 9.5 Friend Request Testing

1. ✅ Send friend request
2. ✅ Accept friend request
3. ✅ Decline friend request
4. ✅ Cannot send duplicate request
5. ✅ Cannot send request to existing friend
6. ✅ Search for friends
7. ✅ View friend profile
8. ✅ View friend's public wishlists

### 9.6 Notification Testing

1. ✅ Receive friend request notification
2. ✅ Receive event invitation notification
3. ✅ Receive item reserved notification
4. ✅ Receive item purchased notification
5. ✅ Receive item received notification (as giver)
6. ✅ Tap notification navigates to correct screen
7. ✅ Mark notification as read
8. ✅ Mark all notifications as read
9. ✅ Notification actions work (Accept/Decline/RSVP)

### 9.7 Guest Mode Testing

1. ✅ Guest can browse public wishlists
2. ✅ Guest can view public events
3. ✅ Guest cannot reserve items
4. ✅ Guest cannot create events
5. ✅ Guest cannot send friend requests
6. ✅ Guest sees restriction dialogs
7. ✅ Guest can sign in from restriction dialog

---

## 10. API Endpoints Reference

### 10.1 Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/forgot-password` - Request password reset

### 10.2 Wishlists
- `GET /api/wishlists` - Get user's wishlists
- `POST /api/wishlists` - Create wishlist
- `GET /api/wishlists/{id}` - Get wishlist details
- `PUT /api/wishlists/{id}` - Update wishlist
- `DELETE /api/wishlists/{id}` - Delete wishlist
- `POST /api/wishlists/{id}/items` - Add item to wishlist
- `PUT /api/items/{id}/reserve` - Reserve/unreserve item
- `PUT /api/items/{id}/purchase` - Mark item as purchased
- `PUT /api/items/{id}/received` - Mark item as received

### 10.3 Events
- `GET /api/events` - Get user's events
- `POST /api/events` - Create event
- `GET /api/events/{id}` - Get event details
- `PUT /api/events/{id}` - Update event
- `DELETE /api/events/{id}` - Delete event
- `PUT /api/events/{id}/respond` - Respond to event invitation (RSVP)

### 10.4 Friends
- `GET /api/friends` - Get friends list
- `POST /api/friends/request` - Send friend request
- `POST /api/friends/request/{id}/respond` - Accept/decline friend request

### 10.5 Notifications
- `GET /api/notifications` - Get notifications
- `PUT /api/notifications/{id}/read` - Mark notification as read
- `PUT /api/notifications/read-all` - Mark all as read

---

## 11. Glossary

- **Guest User:** User browsing app without account (limited features)
- **Registered User:** User with account (full features)
- **Wishlist Owner:** User who created the wishlist
- **Reserver/Purchaser/Giver:** User who reserves/purchases item for owner
- **Event Creator/Host:** User who created the event
- **Guest (Event):** User invited to an event
- **RSVP:** Response to event invitation (Accept/Maybe/Decline)
- **Secret Reservation:** Reservation where owner doesn't see who reserved
- **Public:** Visible to everyone
- **Friends Only:** Visible only to approved friends
- **Private:** Visible only to owner

---

## 12. Important Notes for QA

1. **Secret Reservation:** Always verify that wishlist owner does NOT see who reserved/purchased items until marked as received.

2. **Guest Restrictions:** Verify all guest restrictions are properly enforced with appropriate dialogs.

3. **Notifications:** Test notification triggers, recipients, and navigation actions thoroughly.

4. **RSVP Changes:** Verify users can change RSVP responses multiple times.

5. **Friend Requests:** Verify duplicate request prevention and status updates.

6. **Item Status Flow:** Verify the complete flow: Available → Reserved → Purchased → Received.

7. **Privacy Settings:** Test visibility rules for Public, Friends Only, and Private settings.

8. **Validation:** Test all required fields and format validations.

9. **Error Handling:** Test network errors, invalid credentials, and edge cases.

10. **Localization:** Test app in both English and Arabic (RTL layout).

---

**Document End**

For questions or clarifications, please refer to the codebase or contact the development team.

