# API Documentation

## Base URL

```
http://<NODE-IP>:30080
```

## Endpoints

### Health Check

**GET** `/health`

Returns the health status of the application.

**Response:**
```json
{
  "status": "UP",
  "timestamp": "2025-12-16T10:30:00.000Z",
  "uptime": 3600,
  "database": "connected"
}
```

**Status Codes:**
- `200 OK` - Application is healthy
- `503 Service Unavailable` - Application is unhealthy

---

### Metrics

**GET** `/metrics`

Returns Prometheus-compatible metrics.

**Response:**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/",status_code="200"} 42

# HELP http_request_duration_seconds Duration of HTTP requests in seconds
# TYPE http_request_duration_seconds histogram
...
```

**Status Codes:**
- `200 OK` - Metrics returned

---

### Get All Users

**GET** `/api/users`

Returns a list of all users.

**Response:**
```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "name": "John Doe",
      "email": "john@example.com",
      "createdAt": "2025-12-16T10:00:00.000Z"
    },
    {
      "_id": "507f1f77bcf86cd799439012",
      "name": "Jane Smith",
      "email": "jane@example.com",
      "createdAt": "2025-12-16T11:00:00.000Z"
    }
  ]
}
```

**Status Codes:**
- `200 OK` - Users retrieved successfully
- `500 Internal Server Error` - Server error

---

### Get User by ID

**GET** `/api/users/:id`

Returns a specific user by ID.

**Parameters:**
- `id` (string, required) - User ID

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2025-12-16T10:00:00.000Z"
  }
}
```

**Status Codes:**
- `200 OK` - User found
- `404 Not Found` - User not found
- `500 Internal Server Error` - Server error

---

### Create User

**POST** `/api/users`

Creates a new user.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2025-12-16T10:00:00.000Z"
  }
}
```

**Status Codes:**
- `201 Created` - User created successfully
- `400 Bad Request` - Invalid request data
- `500 Internal Server Error` - Server error

**Validation:**
- `name` - Required, string
- `email` - Required, string, must be valid email format

---

### Delete User

**DELETE** `/api/users/:id`

Deletes a user by ID.

**Parameters:**
- `id` (string, required) - User ID

**Response:**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

**Status Codes:**
- `200 OK` - User deleted successfully
- `404 Not Found` - User not found
- `500 Internal Server Error` - Server error

---

## Examples

### Using cURL

```bash
# Health check
curl http://localhost:30080/health

# Get all users
curl http://localhost:30080/api/users

# Create user
curl -X POST http://localhost:30080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Get user by ID
curl http://localhost:30080/api/users/507f1f77bcf86cd799439011

# Delete user
curl -X DELETE http://localhost:30080/api/users/507f1f77bcf86cd799439011

# Get metrics
curl http://localhost:30080/metrics
```

### Using JavaScript (fetch)

```javascript
// Get all users
fetch('http://localhost:30080/api/users')
  .then(response => response.json())
  .then(data => console.log(data));

// Create user
fetch('http://localhost:30080/api/users', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: 'John Doe',
    email: 'john@example.com'
  })
})
  .then(response => response.json())
  .then(data => console.log(data));
```

### Using Python (requests)

```python
import requests

# Get all users
response = requests.get('http://localhost:30080/api/users')
print(response.json())

# Create user
data = {
    'name': 'John Doe',
    'email': 'john@example.com'
}
response = requests.post('http://localhost:30080/api/users', json=data)
print(response.json())

# Delete user
user_id = '507f1f77bcf86cd799439011'
response = requests.delete(f'http://localhost:30080/api/users/{user_id}')
print(response.json())
```

## Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "error": "Error message description"
}
```

## Metrics

The application exposes the following metrics at `/metrics`:

### HTTP Metrics

- `http_requests_total` - Total number of HTTP requests
  - Labels: `method`, `route`, `status_code`

- `http_request_duration_seconds` - HTTP request duration histogram
  - Labels: `method`, `route`, `status_code`

### Node.js Metrics

- `nodejs_heap_size_used_bytes` - Used heap size
- `nodejs_heap_size_total_bytes` - Total heap size
- `nodejs_external_memory_bytes` - External memory
- `process_cpu_user_seconds_total` - User CPU time
- `process_cpu_system_seconds_total` - System CPU time
- `nodejs_active_handles_total` - Active handles
- `nodejs_active_requests_total` - Active requests

## Rate Limiting

Currently, no rate limiting is implemented. For production use, consider adding rate limiting middleware.

## Authentication

Currently, no authentication is implemented. For production use, implement JWT or OAuth2 authentication.

## CORS

CORS is not configured. To enable CORS for cross-origin requests, add CORS middleware:

```javascript
const cors = require('cors');
app.use(cors());
```
