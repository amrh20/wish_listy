# Wish Listy - Technical API Documentation

## System Architecture Overview

Wish Listy follows a modern microservices architecture with RESTful APIs, real-time communication, and scalable cloud infrastructure.

```
Frontend (Flutter) ↔ API Gateway ↔ Microservices ↔ Database
     ↓                    ↓              ↓           ↓
   Mobile App      Authentication   Business    PostgreSQL
   Web App         Rate Limiting    Logic       Redis
   Admin Panel     Logging         Services    Elasticsearch
```

## Technology Stack

### Backend
- **Framework**: Node.js with Express.js / Python with FastAPI
- **Database**: PostgreSQL (primary), Redis (caching), Elasticsearch (search)
- **Authentication**: JWT tokens, OAuth 2.0
- **Real-time**: WebSocket connections for live updates
- **File Storage**: AWS S3 / Google Cloud Storage
- **Search**: Elasticsearch with advanced filtering

### Infrastructure
- **Cloud**: AWS / Google Cloud Platform
- **Containerization**: Docker with Kubernetes
- **CI/CD**: GitHub Actions / GitLab CI
- **Monitoring**: Prometheus, Grafana, ELK Stack
- **CDN**: CloudFront / Cloud CDN

## API Endpoints Documentation

### Base URL
```
Production: https://api.wishlisty.com/v1
Staging: https://staging-api.wishlisty.com/v1
Development: http://localhost:3000/v1
```

### Authentication

#### 1. User Registration
```http
POST /auth/register
Content-Type: application/json

Request Body:
{
  "email": "user@example.com",
  "password": "securePassword123",
  "firstName": "John",
  "lastName": "Doe",
  "dateOfBirth": "1990-01-01",
  "phoneNumber": "+1234567890"
}

Response:
{
  "success": true,
  "data": {
    "userId": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "accessToken": "jwt_token",
    "refreshToken": "refresh_token"
  },
  "message": "User registered successfully"
}
```

#### 2. User Login
```http
POST /auth/login
Content-Type: application/json

Request Body:
{
  "email": "user@example.com",
  "password": "securePassword123"
}

Response:
{
  "success": true,
  "data": {
    "userId": "uuid",
    "email": "user@example.com",
    "accessToken": "jwt_token",
    "refreshToken": "refresh_token",
    "expiresIn": 3600
  }
}
```

#### 3. Refresh Token
```http
POST /auth/refresh
Authorization: Bearer {refreshToken}

Response:
{
  "success": true,
  "data": {
    "accessToken": "new_jwt_token",
    "expiresIn": 3600
  }
}
```

### User Management

#### 1. Get User Profile
```http
GET /users/profile
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "userId": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "profilePicture": "https://s3.amazonaws.com/profile.jpg",
    "bio": "Love tech and outdoor adventures",
    "dateOfBirth": "1990-01-01",
    "phoneNumber": "+1234567890",
    "privacySettings": {
      "profileVisibility": "friends",
      "showOnlineStatus": true,
      "allowFriendRequests": true,
      "showWishlistActivity": true
    },
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 2. Update User Profile
```http
PUT /users/profile
Authorization: Bearer {accessToken}
Content-Type: application/json

Request Body:
{
  "firstName": "John",
  "lastName": "Smith",
  "bio": "Updated bio",
  "privacySettings": {
    "profileVisibility": "public",
    "showOnlineStatus": false
  }
}

Response:
{
  "success": true,
  "data": {
    "message": "Profile updated successfully",
    "updatedFields": ["firstName", "lastName", "bio", "privacySettings"]
  }
}
```

#### 3. Upload Profile Picture
```http
POST /users/profile/picture
Authorization: Bearer {accessToken}
Content-Type: multipart/form-data

Form Data:
- image: [file]

Response:
{
  "success": true,
  "data": {
    "profilePicture": "https://s3.amazonaws.com/new-profile.jpg",
    "message": "Profile picture uploaded successfully"
  }
}
```

### Wishlist Management

#### 1. Create Wishlist
```http
POST /wishlists
Authorization: Bearer {accessToken}
Content-Type: application/json

Request Body:
{
  "title": "Birthday Wishlist",
  "description": "Things I'd love for my birthday",
  "occasion": "birthday",
  "eventDate": "2024-06-15",
  "isPublic": false,
  "allowComments": true,
  "budget": {
    "min": 10,
    "max": 200
  }
}

Response:
{
  "success": true,
  "data": {
    "wishlistId": "uuid",
    "title": "Birthday Wishlist",
    "description": "Things I'd love for my birthday",
    "occasion": "birthday",
    "eventDate": "2024-06-15",
    "isPublic": false,
    "allowComments": true,
    "budget": {
      "min": 10,
      "max": 200
    },
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 2. Add Item to Wishlist
```http
POST /wishlists/{wishlistId}/items
Authorization: Bearer {accessToken}
Content-Type: application/json

Request Body:
{
  "name": "Wireless Headphones",
  "description": "Noise-cancelling wireless headphones",
  "category": "electronics",
  "priority": "high",
  "price": {
    "amount": 150,
    "currency": "USD"
  },
  "links": [
    {
      "url": "https://amazon.com/headphones",
      "title": "Amazon",
      "price": 150
    }
  ],
  "images": ["image1.jpg", "image2.jpg"],
  "tags": ["wireless", "noise-cancelling", "music"]
}

Response:
{
  "success": true,
  "data": {
    "itemId": "uuid",
    "name": "Wireless Headphones",
    "description": "Noise-cancelling wireless headphones",
    "category": "electronics",
    "priority": "high",
    "price": {
      "amount": 150,
      "currency": "USD"
    },
    "status": "available",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 3. Get User Wishlists
```http
GET /users/{userId}/wishlists
Authorization: Bearer {accessToken}
Query Parameters:
- page: 1
- limit: 20
- occasion: birthday
- isPublic: true

Response:
{
  "success": true,
  "data": {
    "wishlists": [
      {
        "wishlistId": "uuid",
        "title": "Birthday Wishlist",
        "description": "Things I'd love for my birthday",
        "occasion": "birthday",
        "eventDate": "2024-06-15",
        "itemCount": 15,
        "isPublic": false,
        "createdAt": "2024-01-01T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "totalPages": 1
    }
  }
}
```

### Social Features

#### 1. Send Friend Request
```http
POST /friends/requests
Authorization: Bearer {accessToken}
Content-Type: application/json

Request Body:
{
  "recipientId": "uuid",
  "message": "Hi! I'd like to connect with you on Wish Listy"
}

Response:
{
  "success": true,
  "data": {
    "requestId": "uuid",
    "status": "pending",
    "message": "Friend request sent successfully"
  }
}
```

#### 2. Accept/Reject Friend Request
```http
PUT /friends/requests/{requestId}
Authorization: Bearer {accessToken}
Content-Type: application/json

Request Body:
{
  "action": "accept" // or "reject"
}

Response:
{
  "success": true,
  "data": {
    "message": "Friend request accepted",
    "friendshipId": "uuid"
  }
}
```

#### 3. Get Friends List
```http
GET /friends
Authorization: Bearer {accessToken}
Query Parameters:
- page: 1
- limit: 20
- status: active

Response:
{
  "success": true,
  "data": {
    "friends": [
      {
        "friendshipId": "uuid",
        "friend": {
          "userId": "uuid",
          "firstName": "Jane",
          "lastName": "Smith",
          "profilePicture": "https://s3.amazonaws.com/jane.jpg"
        },
        "status": "active",
        "connectedSince": "2024-01-01T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 25,
      "totalPages": 2
    }
  }
}
```

### Event Management

#### 1. Create Event
```http
POST /events
Authorization: Bearer {accessToken}
Content-Type: application/json

Request Body:
{
  "title": "Sarah's Birthday Party",
  "description": "Celebrating Sarah's 30th birthday",
  "type": "birthday",
  "date": "2024-06-15T18:00:00Z",
  "location": "Central Park, NYC",
  "hostId": "uuid",
  "guests": [
    {
      "userId": "uuid",
      "role": "guest"
    }
  ],
  "giftCoordination": {
    "enabled": true,
    "budget": {
      "min": 20,
      "max": 100
    },
    "groupGifts": true
  }
}

Response:
{
  "success": true,
  "data": {
    "eventId": "uuid",
    "title": "Sarah's Birthday Party",
    "description": "Celebrating Sarah's 30th birthday",
    "type": "birthday",
    "date": "2024-06-15T18:00:00Z",
    "location": "Central Park, NYC",
    "hostId": "uuid",
    "giftCoordination": {
      "enabled": true,
      "budget": {
        "min": 20,
        "max": 100
      },
      "groupGifts": true
    },
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 2. Get Event Details
```http
GET /events/{eventId}
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "eventId": "uuid",
    "title": "Sarah's Birthday Party",
    "description": "Celebrating Sarah's 30th birthday",
    "type": "birthday",
    "date": "2024-06-15T18:00:00Z",
    "location": "Central Park, NYC",
    "host": {
      "userId": "uuid",
      "firstName": "John",
      "lastName": "Doe"
    },
    "guests": [
      {
        "userId": "uuid",
        "firstName": "Jane",
        "lastName": "Smith",
        "role": "guest",
        "rsvpStatus": "confirmed"
      }
    ],
    "giftCoordination": {
      "enabled": true,
      "budget": {
        "min": 20,
        "max": 100
      },
      "groupGifts": true,
      "coordinatedGifts": [
        {
          "giftId": "uuid",
          "name": "Spa Day Package",
          "contributors": [
            {
              "userId": "uuid",
              "amount": 50
            }
          ]
        }
      ]
    }
  }
}
```

### Gift Discovery & Recommendations

#### 1. Get Gift Recommendations
```http
GET /gifts/recommendations
Authorization: Bearer {accessToken}
Query Parameters:
- occasion: birthday
- recipientAge: 30
- recipientGender: female
- budget: 100
- category: electronics
- interests: ["music", "technology"]

Response:
{
  "success": true,
  "data": {
    "recommendations": [
      {
        "giftId": "uuid",
        "name": "Wireless Earbuds",
        "description": "Premium wireless earbuds with noise cancellation",
        "category": "electronics",
        "price": {
          "amount": 89.99,
          "currency": "USD"
        },
        "rating": 4.5,
        "reviewCount": 1250,
        "image": "https://s3.amazonaws.com/earbuds.jpg",
        "relevanceScore": 0.95,
        "reasons": [
          "Matches recipient's music interest",
          "Within budget range",
          "High user rating"
        ]
      }
    ],
    "filters": {
      "occasion": "birthday",
      "budget": 100,
      "category": "electronics"
    }
  }
}
```

#### 2. Search Gifts
```http
GET /gifts/search
Authorization: Bearer {accessToken}
Query Parameters:
- q: wireless headphones
- category: electronics
- priceMin: 50
- priceMax: 200
- rating: 4
- sortBy: relevance
- page: 1
- limit: 20

Response:
{
  "success": true,
  "data": {
    "gifts": [
      {
        "giftId": "uuid",
        "name": "Sony WH-1000XM4",
        "description": "Industry-leading noise canceling wireless headphones",
        "category": "electronics",
        "price": {
          "amount": 179.99,
          "currency": "USD"
        },
        "rating": 4.7,
        "reviewCount": 8500,
        "image": "https://s3.amazonaws.com/sony-headphones.jpg",
        "retailer": "Amazon",
        "availability": "in_stock"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "totalPages": 8
    },
    "facets": {
      "categories": [
        {"name": "electronics", "count": 150}
      ],
      "priceRanges": [
        {"range": "50-100", "count": 45},
        {"range": "100-200", "count": 89}
      ],
      "ratings": [
        {"rating": 4, "count": 120},
        {"rating": 5, "count": 30}
      ]
    }
  }
}
```

### Notifications

#### 1. Get User Notifications
```http
GET /notifications
Authorization: Bearer {accessToken}
Query Parameters:
- page: 1
- limit: 20
- type: all
- unreadOnly: true

Response:
{
  "success": true,
  "data": {
    "notifications": [
      {
        "notificationId": "uuid",
        "type": "friend_request",
        "title": "New Friend Request",
        "message": "Jane Smith sent you a friend request",
        "data": {
          "senderId": "uuid",
          "senderName": "Jane Smith"
        },
        "isRead": false,
        "createdAt": "2024-01-01T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 15,
      "totalPages": 1
    },
    "unreadCount": 8
  }
}
```

#### 2. Mark Notification as Read
```http
PUT /notifications/{notificationId}/read
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "message": "Notification marked as read"
  }
}
```

## Real-time Communication (WebSocket)

### Connection
```javascript
const socket = io('wss://api.wishlisty.com', {
  auth: {
    token: 'jwt_access_token'
  }
});
```

### Events

#### 1. Friend Request
```javascript
// Send friend request
socket.emit('friend_request', {
  recipientId: 'uuid',
  message: 'Hi! I\'d like to connect with you'
});

// Receive friend request
socket.on('friend_request_received', (data) => {
  console.log('New friend request from:', data.senderName);
});
```

#### 2. Wishlist Updates
```javascript
// Join wishlist room
socket.emit('join_wishlist', { wishlistId: 'uuid' });

// Receive wishlist updates
socket.on('wishlist_updated', (data) => {
  console.log('Wishlist updated:', data.changes);
});
```

#### 3. Event Notifications
```javascript
// Receive real-time event updates
socket.on('event_update', (data) => {
  console.log('Event updated:', data.eventId);
});

// Receive gift coordination updates
socket.on('gift_coordination_update', (data) => {
  console.log('Gift coordination updated:', data);
});
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  profile_picture VARCHAR(500),
  bio TEXT,
  date_of_birth DATE,
  phone_number VARCHAR(20),
  privacy_settings JSONB DEFAULT '{}',
  email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Wishlists Table
```sql
CREATE TABLE wishlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  occasion VARCHAR(100),
  event_date DATE,
  is_public BOOLEAN DEFAULT FALSE,
  allow_comments BOOLEAN DEFAULT TRUE,
  budget JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Wishlist Items Table
```sql
CREATE TABLE wishlist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wishlist_id UUID REFERENCES wishlists(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100),
  priority VARCHAR(20) DEFAULT 'medium',
  price JSONB,
  links JSONB,
  images JSONB,
  tags JSONB,
  status VARCHAR(20) DEFAULT 'available',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Friendships Table
```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  friend_id UUID REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);
```

### Events Table
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(100),
  date TIMESTAMP NOT NULL,
  location VARCHAR(500),
  host_id UUID REFERENCES users(id) ON DELETE CASCADE,
  gift_coordination JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Email is required"
      }
    ]
  },
  "timestamp": "2024-01-01T00:00:00Z",
  "requestId": "uuid"
}
```

### Common Error Codes
- `AUTHENTICATION_ERROR`: Invalid or expired token
- `AUTHORIZATION_ERROR`: Insufficient permissions
- `VALIDATION_ERROR`: Invalid input data
- `NOT_FOUND`: Resource not found
- `CONFLICT`: Resource already exists
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_SERVER_ERROR`: Server error

## Rate Limiting

### API Rate Limits
- **Authentication endpoints**: 5 requests per minute
- **User management**: 100 requests per hour
- **Wishlist operations**: 200 requests per hour
- **Social features**: 300 requests per hour
- **Search and discovery**: 500 requests per hour

### Rate Limit Response Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Security Considerations

### Authentication
- JWT tokens with short expiration (1 hour)
- Refresh tokens with longer expiration (7 days)
- Secure password hashing (bcrypt)
- Rate limiting on authentication endpoints

### Data Protection
- HTTPS/TLS encryption for all communications
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- CSRF protection

### Privacy
- GDPR compliance
- User consent management
- Data anonymization for analytics
- Secure data deletion

## Performance Optimization

### Caching Strategy
- **Redis**: Session data, user preferences, frequently accessed data
- **CDN**: Static assets, images, profile pictures
- **Database**: Query result caching for complex queries

### Database Optimization
- Proper indexing on frequently queried fields
- Query optimization and monitoring
- Connection pooling
- Read replicas for read-heavy operations

### API Optimization
- Pagination for large datasets
- Field selection to reduce payload size
- Compression for large responses
- Background processing for heavy operations

## Monitoring & Analytics

### Key Metrics
- API response times
- Error rates and types
- User engagement patterns
- Feature usage statistics
- System resource utilization

### Tools
- **Application Monitoring**: New Relic, DataDog
- **Logging**: ELK Stack, Splunk
- **Metrics**: Prometheus, Grafana
- **Error Tracking**: Sentry, Rollbar

## Deployment & DevOps

### Environment Configuration
```bash
# Production
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host:port/db
REDIS_URL=redis://host:port
JWT_SECRET=super_secret_key
AWS_ACCESS_KEY_ID=key
AWS_SECRET_ACCESS_KEY=secret
```

### CI/CD Pipeline
1. **Code Commit** → GitHub/GitLab
2. **Automated Testing** → Unit tests, integration tests
3. **Security Scan** → Dependency vulnerability check
4. **Build** → Docker image creation
5. **Deploy** → Kubernetes deployment
6. **Health Check** → Application health verification

### Scaling Strategy
- **Horizontal Scaling**: Multiple API instances
- **Load Balancing**: Nginx, AWS ALB
- **Auto-scaling**: Based on CPU/memory usage
- **Database Scaling**: Read replicas, sharding

## Testing Strategy

### Test Types
- **Unit Tests**: Individual function testing
- **Integration Tests**: API endpoint testing
- **End-to-End Tests**: Complete user flow testing
- **Performance Tests**: Load and stress testing
- **Security Tests**: Vulnerability assessment

### Test Coverage
- **API Endpoints**: 100% coverage
- **Business Logic**: 90%+ coverage
- **Error Handling**: 100% coverage
- **Authentication**: 100% coverage

## Conclusion

This technical documentation provides a comprehensive overview of the Wish Listy backend architecture, API design, and implementation details. The system is designed to be scalable, secure, and maintainable while providing a robust foundation for the social gifting platform.

Key success factors include:
- Clean API design with consistent patterns
- Comprehensive error handling and validation
- Real-time communication capabilities
- Robust security measures
- Performance optimization strategies
- Comprehensive testing and monitoring

The architecture supports the business requirements while maintaining technical excellence and scalability for future growth.
