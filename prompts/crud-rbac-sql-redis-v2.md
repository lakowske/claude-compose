## Postgres based CRUD server using RBAC, Redis queues and event streaming

Create tech specs and implement "Unified", a professional management application using Python, FastAPI, Redis, and Postgres (without ORM) with Flyway migrations, idiomatic FastAPI Project Structure and polished Bootstrap UI.

## Key Requirements:

### Request Processing & Queuing Architecture

- **Request Sources**: Accept requests from three channels:
  - JSON over HTTP API endpoints
  - HTML forms via web interface
  - WebSocket connections for real-time operations
- **Request UUID Tracking**: Every incoming request receives a unique UUID for monitoring and tracing
- **Incoming Request Queue**: All requests are immediately placed on a Redis queue (`incoming_requests`) for monitoring and load management
- **Uniform Auth Filter**: All requests pass through a centralized authentication/authorization filter before processing:
  1. **Public Endpoint Check**: First determine if the endpoint allows anonymous access (user registration, login, health checks, etc.)
  2. **Authentication Validation**: For protected endpoints, validate authentication (session, service token, or WebSocket auth)
  3. **RBAC Permission Check**: For authenticated requests, check RBAC permissions for the requested action
  4. **Accept/Reject Decision**: Accept public requests or authenticated+authorized requests; reject all others
- **Response Routing**: Errors and responses are sent back via the original request channel:
  - HTTP requests → JSON or HTML responses with appropriate status codes
  - WebSocket requests → WebSocket messages with error/success indicators
- **Error Handling**: Standardized error responses with helpful messaging and appropriate logging
- **Processed Request Queue**: Successfully processed requests are placed on Redis queue (`processed_requests`) for event monitoring
- **Event Watching**: Users can watch for database changes and action events, filtered by their `<resource>:read:all` permissions

### Authentication & Authorization

- Create permission system with format `<resource>:<action>:<scope>` where scope is:
  - `all` - perform action on all records
  - `own` - perform action on only records owned by the user
  - `group` - perform action on records owned by user's group
- Wildcard syntax:
  - `*:read:all` means access to read from all resources
  - `user:*:all` means user can perform all actions on the user resource
  - `*:*:*` means access to all resources, all operations, all scope
- Admin role permissions: *:*:all
- User role permissions: user:read:own, user:update:own
- **PUBLIC ACCESS**: Include user registration functionality (no authentication required)
- Accepts both service tokens and session ids for authorization
- Transports data over HTTP and WebSocket
- Serves HTML and JSON

### Database Design & Migration Management

- **Migration Tool**: Use Flyway for SQL migrations and version control
- **No ORM**: Use raw SQL with psycopg2 for direct database operations
- Create tables for accounts, passwords, roles, permissions, service tokens and sessions
- Use foreign key relationships
- Use proper relationship mappings (many-to-many for account_roles, role_permissions)
- Include timestamps (created_at, updated_at) on all tables with timezone awareness
- Use bcrypt hashing for user accounts
- Use sha256 hashing for service accounts
- Include the hash function in the passwords table
- Add ownership fields to tables: owner_user_id and owner_group_id for record-level permissions
- Permission table should store the three-part format: resource, action, scope
- **IMPORTANT**: Use timezone-aware datetime objects consistently (datetime.now(timezone.utc))

### Error Handling & Response Management

- **Standardized Error Responses**: All errors follow consistent format across HTTP, HTML, and WebSocket channels
- **Error Categories**:
  - **Authentication Errors** (401): Invalid/missing credentials, expired sessions
  - **Authorization Errors** (403): Insufficient permissions, access denied
  - **Validation Errors** (400): Invalid input data, missing required fields
  - **Business Logic Errors** (422): Data conflicts, constraint violations
  - **System Errors** (500): Database failures, Redis connectivity issues
- **Error Response Format**:
  ```python
  {
      "error": True,
      "error_code": "AUTH_REQUIRED",
      "message": "Authentication required to access this resource",
      "details": "Session expired or invalid. Please login again.",
      "request_uuid": "550e8400-e29b-41d4-a716-446655440000",
      "timestamp": "2024-01-15T10:30:00Z",
      "endpoint": "/api/v1/users",
      "suggestions": ["Login with valid credentials", "Check session expiration"]
  }
  ```
- **Channel-Specific Error Handling**:
  - **HTTP JSON**: Return structured error response with appropriate status codes
  - **HTML Forms**: Show Bootstrap alert messages with user-friendly explanations
  - **WebSocket**: Send error message with connection-appropriate formatting
- **Error Logging**: Log all errors with context (user_id, request_uuid, stack trace)
- **Failed Request Tracking**: Failed requests are queued to `failed_requests` Redis queue for monitoring
- **Common Error Scenarios with Helpful Messages**:
  - **AUTH_REQUIRED**: "Please login to access this resource" → Redirect to login page
  - **AUTH_FAILURE**: "Invalid credentials provided" → Show login form with error
  - **PERMISSION_ERROR**: "You don't have permission to perform this action" → Show access denied page
  - **VALIDATION_ERROR**: "Invalid input data: {specific_field_errors}" → Highlight form fields with errors
  - **NOT_FOUND**: "The requested resource was not found" → Show 404 page with navigation options
  - **CONFLICT**: "This action conflicts with existing data" → Show specific conflict details
  - **DATABASE_ERROR**: "Database operation failed, please try again" → Generic error with retry option
  - **SYSTEM_ERROR**: "An unexpected error occurred" → Contact support information

### Redis Integration

- **Request Queues**:
  - `incoming_requests` - All requests with UUID, timestamp, source, user_id, action
  - `processed_requests` - Successfully processed requests for event monitoring
  - `failed_requests` - Failed requests with error details for monitoring and debugging
- **Event Streaming**: Users can subscribe to Redis queues to watch for:
  - Database changes (INSERT, UPDATE, DELETE operations)
  - Action requests (filtered by user permissions)
  - Real-time notifications
- **Session Storage**: Store session data in Redis for scalability
- **Rate Limiting**: Use Redis for request rate limiting per user/IP

### **Technical Specifications**:

- Use Python without ORM - direct SQL operations with psycopg2
- Use Pydantic v2 for request/response validation
- Use modern logging practices, ensure logging occurs at the boundaries of function calls and service requests
- Use pyproject.toml and a .venv to install dependencies
- **IMPORTANT**: Add pydantic-settings for configuration management
- **IMPORTANT**: Handle CORS_ORIGINS as both string and list in config
- Support URL_PREFIX environment variable for reverse proxy deployment
- Use python-dotenv for environment variables
- **PORT CONFIGURATION**: Always use CLAUDE_INTERNAL_PORT environment variable instead of hardcoded ports
- Required dependencies: python3-venv, fastapi, psycopg2-binary, redis, uvicorn, pydantic, pydantic-settings, python-jose, passlib, bcrypt, python-multipart, jinja2, python-dotenv, email-validator, supervisor, websockets
- **UI FRAMEWORK**: Bootstrap 5.3+ for professional, responsive design with modern components
- Development dependencies: ruff (for linting and formatting)
- **FLYWAY**: Include Flyway configuration and migration scripts

### **Implementation Details**:

- **Separation of Concerns**: Keep routes, business logic, and data access separate under `src/` directory
  - `src/api/` and `src/routers/` - Route definitions only
  - `src/db/` - Raw SQL operations and database utilities
  - `src/schemas/` - Data validation and serialization
  - `src/queues/` - Redis queue management and event processing
  - `src/auth/` - Authentication and authorization logic
- **Uniform Request Processing with Error Handling**:
  ```python
  async def process_request(request_data: RequestModel, source: str, user_context: dict, endpoint_path: str):
      # Assign UUID for tracking
      request_uuid = str(uuid.uuid4())
      request_timestamp = datetime.now(timezone.utc)
      
      try:
          # Queue incoming request (including anonymous requests)
          await redis_client.lpush("incoming_requests", json.dumps({
              "uuid": request_uuid,
              "timestamp": request_timestamp.isoformat(),
              "source": source,  # "http", "websocket", "form"
              "user_id": user_context.get("user_id"),  # None for anonymous requests
              "endpoint": endpoint_path,
              "action": request_data.action,
              "data": request_data.dict(),
              "anonymous": user_context.get("user_id") is None
          }))
          
          # Process through auth filter with public endpoint awareness
          auth_result = await uniform_auth_filter(request_data, user_context, endpoint_path)
          if not auth_result.authorized:
              await log_and_queue_failure(
                  request_uuid, "AUTH_FAILURE", auth_result.error, 
                  user_context, endpoint_path, source
              )
              return create_error_response(auth_result.error, source, request_uuid, endpoint_path)
          
          # Execute request with comprehensive error handling
          try:
              result = await execute_action(request_data, user_context)
          except ValidationError as e:
              await log_and_queue_failure(
                  request_uuid, "VALIDATION_ERROR", str(e), 
                  user_context, endpoint_path, source
              )
              return create_error_response("Invalid input data", source, request_uuid, endpoint_path, 
                                        error_code="VALIDATION_ERROR", details=str(e))
          except PermissionError as e:
              await log_and_queue_failure(
                  request_uuid, "PERMISSION_ERROR", str(e), 
                  user_context, endpoint_path, source
              )
              return create_error_response("Insufficient permissions", source, request_uuid, endpoint_path,
                                        error_code="PERMISSION_ERROR", details=str(e))
          except DatabaseError as e:
              await log_and_queue_failure(
                  request_uuid, "DATABASE_ERROR", str(e), 
                  user_context, endpoint_path, source
              )
              return create_error_response("Database operation failed", source, request_uuid, endpoint_path,
                                        error_code="DATABASE_ERROR", details="Please try again later")
          
          # Queue successful request for event monitoring
          await redis_client.lpush("processed_requests", json.dumps({
              "uuid": request_uuid,
              "timestamp": datetime.now(timezone.utc).isoformat(),
              "user_id": user_context.get("user_id"),
              "endpoint": endpoint_path,
              "action": request_data.action,
              "resource": getattr(request_data, 'resource', None),
              "result": "success",
              "anonymous": user_context.get("user_id") is None
          }))
          
          return create_success_response(result, source, request_uuid)
          
      except Exception as e:
          # Handle unexpected system errors
          logger.error(f"Unexpected error processing request {request_uuid}: {str(e)}", 
                      exc_info=True, extra={"request_uuid": request_uuid, "endpoint": endpoint_path})
          await log_and_queue_failure(
              request_uuid, "SYSTEM_ERROR", str(e), 
              user_context, endpoint_path, source
          )
          return create_error_response("Internal server error", source, request_uuid, endpoint_path,
                                    error_code="SYSTEM_ERROR", details="Please try again later")

  async def log_and_queue_failure(request_uuid: str, error_code: str, error_message: str, 
                                 user_context: dict, endpoint: str, source: str):
      """Log error and queue failed request for monitoring"""
      logger.error(f"Request failed: {error_code} - {error_message}", extra={
          "request_uuid": request_uuid,
          "user_id": user_context.get("user_id"),
          "endpoint": endpoint,
          "source": source,
          "error_code": error_code
      })
      
      await redis_client.lpush("failed_requests", json.dumps({
          "uuid": request_uuid,
          "timestamp": datetime.now(timezone.utc).isoformat(),
          "user_id": user_context.get("user_id"),
          "endpoint": endpoint,
          "source": source,
          "error_code": error_code,
          "error_message": error_message,
          "anonymous": user_context.get("user_id") is None
      }))

  # Error response creation functions
  def create_error_response(message: str, source: str, request_uuid: str, endpoint: str, 
                           error_code: str = "GENERIC_ERROR", details: str = None, 
                           suggestions: List[str] = None) -> dict:
      """Create standardized error response for different channels"""
      error_data = {
          "error": True,
          "error_code": error_code,
          "message": message,
          "details": details or message,
          "request_uuid": request_uuid,
          "timestamp": datetime.now(timezone.utc).isoformat(),
          "endpoint": endpoint,
          "suggestions": suggestions or []
      }
      
      if source == "http":
          # Return JSON response with appropriate HTTP status code
          status_code = get_status_code_for_error(error_code)
          return JSONResponse(content=error_data, status_code=status_code)
      elif source == "form":
          # Return structured error data - let route handler decide on template/redirect
          return {
              "type": "error",
              "data": error_data,
              "status_code": get_status_code_for_error(error_code)
          }
      elif source == "websocket":
          # Return WebSocket message format
          return {
              "type": "error",
              "data": error_data
          }
      
  def create_success_response(data: dict, source: str, request_uuid: str) -> dict:
      """Create standardized success response for different channels"""
      success_data = {
          "error": False,
          "data": data,
          "request_uuid": request_uuid,
          "timestamp": datetime.now(timezone.utc).isoformat()
      }
      
      if source == "http":
          # Return JSON response
          return JSONResponse(content=success_data, status_code=200)
      elif source == "form":
          # Return structured success data - let route handler decide on template/redirect
          return {
              "type": "success",
              "data": success_data
          }
      elif source == "websocket":
          # Return WebSocket message format
          return {
              "type": "success",
              "data": success_data
          }

  def get_status_code_for_error(error_code: str) -> int:
      """Map error codes to HTTP status codes"""
      error_status_map = {
          "AUTH_REQUIRED": 401,
          "AUTH_FAILURE": 401,
          "PERMISSION_ERROR": 403,
          "VALIDATION_ERROR": 400,
          "DATABASE_ERROR": 500,
          "SYSTEM_ERROR": 500,
          "NOT_FOUND": 404,
          "CONFLICT": 409
      }
      return error_status_map.get(error_code, 500)
  ```
- **HTML Form Error Handling**: Route handlers receive structured error data and decide on appropriate template rendering or redirects:
  ```python
  # Example HTML route handler error handling
  @router.post("/users")
  async def create_user_form(request: Request, ...):
      result = await process_request(user_data, "form", user_context, "/users")
      
      if result["type"] == "error":
          # Render form again with error message
          return templates.TemplateResponse("users/create.html", {
              "request": request,
              "error": result["data"],
              "form_data": user_data,  # Preserve user input
              "alert_class": "alert-danger" if result["data"]["error_code"] == "VALIDATION_ERROR" else "alert-warning"
          })
      else:
          # Redirect to success page or user list
          return RedirectResponse(url="/users", status_code=302)
  ```
- Use dependency injection for database connections, Redis client, current user, and permissions
- Implement proper error handling with HTTP exceptions and WebSocket error messages
- Add CORS middleware configuration
- Create utility functions for permission checking
- Use async/await patterns consistently
- **REAL-TIME UPDATES**: Use Redis pub/sub for real-time WebSocket notifications
- **PROFESSIONAL UI**: Implement polished Bootstrap 5.3+ interface with:
  - Modern responsive design and professional color scheme
  - Clean typography and consistent spacing
  - Professional form styling with validation feedback
  - Loading states, success/error notifications
  - Mobile-friendly navigation and layouts
- **SERVER-SIDE RENDERING**: Web pages should be server-side rendered using Jinja2 templates with minimal client-side JavaScript. Only use dynamic client-side functionality for specific features like real-time updates (e.g., /watch endpoint) and interactive components that require immediate feedback
- Include HTML forms with CSRF protection and Bootstrap styling
- Configure ruff for code linting and formatting (include ruff.toml or pyproject.toml configuration)
- **IMPORTANT**: Create Flyway migration scripts with default data
- **USER REGISTRATION**: Implement public registration form that assigns default "user" role
- **ADMIN TABLES**: Create full CRUD interfaces for roles, permissions, and sessions (admin access only)
- **PROFESSIONAL BRANDING**: Implement "Unified" branding throughout:
  - Professional logo and brand colors
  - Consistent typography and spacing
  - Clean, modern Bootstrap 5.3+ design system
  - Responsive layouts for desktop, tablet, and mobile
- **NAVIGATION**: Add professional Bootstrap navigation with:
  - Unified brand logo and name in navbar
  - Conditional links based on user permissions
  - Mobile-responsive hamburger menu
  - User profile dropdown with logout option
- **SUPERVISOR MANAGEMENT**: Use supervisor directly to manage uvicorn with --reload for fast development iterations

### **Database Operations Without ORM**:

- **Raw SQL Approach**:
  ```python
  # src/db/users.py
  async def create_user(db_pool, user_data: dict) -> dict:
      async with db_pool.acquire() as conn:
          query = """
              INSERT INTO users (username, email, created_at, updated_at, owner_user_id)
              VALUES ($1, $2, $3, $4, $5)
              RETURNING id, username, email, created_at
          """
          now = datetime.now(timezone.utc)
          result = await conn.fetchrow(
              query, user_data["username"], user_data["email"], 
              now, now, user_data["owner_user_id"]
          )
          return dict(result)
  
  async def get_users_by_permission(db_pool, user_id: int, permission_scope: str) -> List[dict]:
      async with db_pool.acquire() as conn:
          if permission_scope == "all":
              query = "SELECT * FROM users ORDER BY created_at DESC"
              results = await conn.fetch(query)
          elif permission_scope == "own":
              query = "SELECT * FROM users WHERE owner_user_id = $1 ORDER BY created_at DESC"
              results = await conn.fetch(query, user_id)
          return [dict(row) for row in results]
  ```

### **Flyway Migration Management**:

- **Migration Structure**:
  ```
  db/migrations/
  ├── V1__Create_base_tables.sql
  ├── V2__Create_auth_tables.sql
  ├── V3__Create_permissions_system.sql
  ├── V4__Insert_default_data.sql
  └── flyway.conf
  ```
- **Migration Example**:
  ```sql
  -- V1__Create_base_tables.sql
  CREATE TABLE users (
      id SERIAL PRIMARY KEY,
      username VARCHAR(255) UNIQUE NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      owner_user_id INTEGER REFERENCES users(id),
      owner_group_id INTEGER
  );
  
  CREATE OR REPLACE FUNCTION update_updated_at_column()
  RETURNS TRIGGER AS $$
  BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
  END;
  $$ language 'plpgsql';
  
  CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  ```

### **WebSocket Integration**:

- **WebSocket Manager**:
  ```python
  # src/websocket/manager.py
  class WebSocketManager:
      def __init__(self):
          self.active_connections: Dict[str, WebSocket] = {}
          self.user_connections: Dict[int, List[str]] = {}
      
      async def connect(self, websocket: WebSocket, user_id: int, connection_id: str):
          await websocket.accept()
          self.active_connections[connection_id] = websocket
          if user_id not in self.user_connections:
              self.user_connections[user_id] = []
          self.user_connections[user_id].append(connection_id)
      
      async def broadcast_to_user(self, user_id: int, message: dict):
          if user_id in self.user_connections:
              for connection_id in self.user_connections[user_id]:
                  websocket = self.active_connections.get(connection_id)
                  if websocket:
                      await websocket.send_json(message)
  ```

### **Dependency Injection Pattern**:

- **Centralized Dependencies** in `src/api/deps.py`:
  ```python
  # Database connection pool dependency
  async def get_db_pool() -> asyncpg.Pool:
      return app.state.db_pool

  # Redis client dependency  
  async def get_redis() -> aioredis.Redis:
      return app.state.redis_client

  # Authentication dependencies (allows None for anonymous access)
  async def get_current_user(
      db_pool: asyncpg.Pool = Depends(get_db_pool), 
      redis: aioredis.Redis = Depends(get_redis),
      session_id: str = Cookie(None)
  ) -> Optional[User]:
      # Returns None for unauthenticated requests - this is valid for public endpoints
      ...

  async def get_current_user_required(current_user: User = Depends(get_current_user)) -> User:
      # Only use this dependency for endpoints that require authentication
      if current_user is None:
          raise HTTPException(status_code=401, detail="Authentication required")
      return current_user

  # Permission dependencies for protected endpoints
  def require_permission(permission_string: str):
      def dependency(current_user: User = Depends(get_current_user_required)):
          if not current_user.has_permission_string(permission_string):
              raise HTTPException(status_code=403, detail="Insufficient permissions")
          return current_user
      return dependency

  # Public endpoint dependency (no authentication required)
  def allow_anonymous():
      def dependency(current_user: Optional[User] = Depends(get_current_user)):
          # This dependency allows both authenticated and anonymous users
          return current_user  # Can be None
      return dependency

  # Uniform auth filter implementation
  async def uniform_auth_filter(request_data: RequestModel, user_context: dict, endpoint_path: str) -> AuthResult:
      # Define public endpoints that don't require authentication
      PUBLIC_ENDPOINTS = {
          "/login", "/register", "/health", "/",
          "/api/v1/health", "/api/v1/auth/login", "/api/v1/auth/register"
      }
      
      # Check if this is a public endpoint
      if endpoint_path in PUBLIC_ENDPOINTS:
          return AuthResult(authorized=True, user_context=user_context)
      
      # For protected endpoints, require authentication
      user_id = user_context.get("user_id")
      if not user_id:
          return AuthResult(authorized=False, error="Authentication required")
      
      # Check RBAC permissions for authenticated requests
      required_permission = f"{request_data.resource}:{request_data.action}:{request_data.scope}"
      user_permissions = user_context.get("permissions", [])
      
      if has_permission(user_permissions, required_permission):
          return AuthResult(authorized=True, user_context=user_context)
      else:
          return AuthResult(authorized=False, error="Insufficient permissions")
  ```

### **Form Handling (Critical for HTML Interface)**:

- **IMPORTANT**: Use `await request.form()` for complex form processing
- **IMPORTANT**: Handle multiple select values with `form_data.getlist("field_name")`
- **IMPORTANT**: Validate and convert form data properly:
  ```python
  form_data = await request.form()
  permission_ids = [int(x) for x in form_data.getlist("permission_ids") if x.isdigit()]
  ```
- **COMPLETE CRUD ROUTES**: Ensure ALL models have complete HTML CRUD routes:
  - GET /model/new (form)
  - POST /model (create)
  - GET /model/{id}/edit (form)
  - POST /model/{id} (update)
  - DELETE /model/{id} (delete)

### **Database Setup with Flyway**:

- **CRITICAL**: Use Flyway for all database schema management
- Create migration scripts that set up:
  - All table structures with proper relationships
  - Default permissions for all resource:action:scope combinations
  - Admin and user roles with appropriate permissions
  - Default admin user (admin/admin123) and demo user (demo/demo123)
  - Assign default "user" role to new registrations
- Handle database connection gracefully with proper error messages
- Include Flyway configuration for development and production environments

### **Development Server Management with Supervisor**:

- **IMPORTANT**: Create supervisor configuration to manage uvicorn server:
  - Use supervisor to control uvicorn process with `--reload` flag
  - Automatic restart on crashes or file changes
  - Process logging and monitoring
  - Easy start/stop/restart commands
  - Uses CLAUDE_INTERNAL_PORT from environment variables
  - Store stdout and stderr logs in ./logs/

### **Configuration Management**:

- Use .env files
- Handle environment variable parsing properly (especially lists)
- Include all required database connection parameters
- Include Redis connection parameters
- Set appropriate defaults for development
- **PORT CONFIGURATION**: Use CLAUDE_INTERNAL_PORT environment variable for uvicorn binding

### **API Endpoints Specification**:

**HTML Routes (in `src/routers/html.py`):**

```
# Public endpoints (no authentication required)
GET  /                     # Home page (redirect based on auth status)
GET  /login                # Login form (public access)
POST /login                # Process login (public access)
GET  /register             # Registration form (public access)
POST /register             # Process registration (public access)
GET  /health               # Health check endpoint (public access)

# Protected endpoints (authentication required)
POST /logout               # Logout user (requires session)
GET  /dashboard            # User dashboard (requires authentication)

# Request Monitoring (admin only)
GET  /monitor/requests     # Monitor incoming/processed requests (admin only)
GET  /events               # Event watching interface (requires authentication)

# System Introspection (requires authentication + permission)
GET  /tables               # List editable tables (permission: system:read:all or specific resource permissions)

# Users (authentication + permission required)
GET  /users                # List users (permission: user:read:all or user:read:own)
GET  /users/{id}           # View user detail (permission check based on ownership)
GET  /users/new            # New user form (permission: user:create:all)
POST /users                # Create user (permission: user:create:all)
GET  /users/{id}/edit      # Edit user form (permission check based on ownership)
POST /users/{id}           # Update user (permission check based on ownership)
DELETE /users/{id}         # Delete user (permission check based on ownership)

# Roles (admin only - requires authentication + admin permissions)
GET  /roles                # List roles (permission: role:read:all)
GET  /roles/{id}           # View role detail (permission: role:read:all)
GET  /roles/new            # New role form (permission: role:create:all)
POST /roles                # Create role (permission: role:create:all)
GET  /roles/{id}/edit      # Edit role form (permission: role:update:all)
POST /roles/{id}           # Update role (permission: role:update:all)
DELETE /roles/{id}         # Delete role (permission: role:delete:all)

...
```

**JSON API Routes (in `src/api/v1/endpoints/`):**

```
# Public endpoints (no authentication required)
GET  /api/v1/health              # Health check endpoint (public access)
POST /api/v1/auth/login          # JSON login (public access)
POST /api/v1/auth/register       # JSON registration (public access)

# Protected endpoints (authentication required)
POST /api/v1/auth/logout         # JSON logout (requires authentication)
GET  /api/v1/auth/me             # Current user info (requires authentication)

# Request Monitoring (admin only)
GET  /api/v1/monitor/incoming    # Monitor incoming request queue (admin only)
GET  /api/v1/monitor/processed   # Monitor processed request queue (admin only)
GET  /api/v1/events/{resource}   # Subscribe to resource events (permission: {resource}:read:all)
GET  /api/v1/events              # Subscribe to all events (permission: *:read:all)

# System Introspection (requires authentication + permission)
GET  /api/v1/tables              # List editable tables (permission: system:read:all or specific resource permissions)

# Users (authentication + permission required)
GET  /api/v1/users               # List users (permission: user:read:all or user:read:own)
POST /api/v1/users               # Create user (permission: user:create:all)
GET  /api/v1/users/{id}          # Get user (permission check based on ownership)
PUT  /api/v1/users/{id}          # Update user (permission check based on ownership)
DELETE /api/v1/users/{id}        # Delete user (permission check based on ownership)

# Roles (admin only - requires authentication + admin permissions)
GET  /api/v1/roles               # List roles (permission: role:read:all)
POST /api/v1/roles               # Create role (permission: role:create:all)
GET  /api/v1/roles/{id}          # Get role (permission: role:read:all)
PUT  /api/v1/roles/{id}          # Update role (permission: role:update:all)
DELETE /api/v1/roles/{id}        # Delete role (permission: role:delete:all)

...
```

**WebSocket Routes:**
```
WS   /ws/{user_id}            # User-specific WebSocket connection
WS   /ws/events/{resource}    # Resource-specific event streaming
WS   /ws/monitor              # Real-time request monitoring (admin only)
```

### **Professional UI Design & Branding**:

- **Bootstrap Integration**: Use Bootstrap 5.3+ for professional, enterprise-grade design:
  - Modern card-based layouts for data presentation
  - Professional form styling with proper validation feedback
  - Responsive grid system for all screen sizes
  - Loading spinners and progress indicators
  - Toast notifications for user feedback
  - Modal dialogs for confirmations and forms

- **Unified Brand Identity**:
  - Professional logo and consistent color scheme
  - Typography hierarchy with clean, readable fonts
  - Consistent spacing and component styling
  - Professional error pages (404, 500, etc.)
  - Polished login/registration experience

- **User Experience Enhancements**:
  - Loading states for all async operations
  - Success/error feedback with Bootstrap alerts
  - Breadcrumb navigation for complex workflows
  - Pagination for large data sets
  - Search and filter capabilities with clean UI
  - Professional table styling with sorting indicators
  - Real-time event notifications via WebSocket

### **Adding New Tables to the System**:

This section provides a complete guide for adding a new table/resource to the Unified application system.

#### **Step 1: Create Flyway Migration**
- Create a new migration file in `db/migrations/` following the naming convention `V{next_number}__Add_{table_name}_table.sql`
- Example migration for a "projects" table:
  ```sql
  -- V5__Add_projects_table.sql
  CREATE TABLE projects (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      description TEXT,
      status VARCHAR(50) DEFAULT 'active',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      owner_user_id INTEGER REFERENCES users(id),
      owner_group_id INTEGER
  );

  -- Add update trigger for updated_at
  CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

  -- Add default permissions for the new resource
  INSERT INTO permissions (resource, action, scope, description) VALUES
      ('project', 'create', 'all', 'Create projects for all users'),
      ('project', 'read', 'all', 'Read all projects'),
      ('project', 'read', 'own', 'Read own projects only'),
      ('project', 'update', 'all', 'Update all projects'),
      ('project', 'update', 'own', 'Update own projects only'),
      ('project', 'delete', 'all', 'Delete all projects'),
      ('project', 'delete', 'own', 'Delete own projects only');

  -- Assign permissions to admin role (assuming admin role has id=1)
  INSERT INTO role_permissions (role_id, permission_id)
  SELECT 1, id FROM permissions WHERE resource = 'project';

  -- Assign basic permissions to user role (assuming user role has id=2)
  INSERT INTO role_permissions (role_id, permission_id)
  SELECT 2, id FROM permissions WHERE resource = 'project' AND scope = 'own';
  ```

#### **Step 2: Create Database Operations**
- Create `src/db/projects.py` with raw SQL operations:
  ```python
  # src/db/projects.py
  from datetime import datetime, timezone
  from typing import List, Dict, Optional
  import asyncpg

  async def create_project(db_pool: asyncpg.Pool, project_data: dict, user_id: int) -> dict:
      async with db_pool.acquire() as conn:
          query = """
              INSERT INTO projects (name, description, status, created_at, updated_at, owner_user_id)
              VALUES ($1, $2, $3, $4, $5, $6)
              RETURNING id, name, description, status, created_at, updated_at, owner_user_id
          """
          now = datetime.now(timezone.utc)
          result = await conn.fetchrow(
              query, project_data["name"], project_data.get("description"), 
              project_data.get("status", "active"), now, now, user_id
          )
          return dict(result)

  async def get_projects_by_permission(db_pool: asyncpg.Pool, user_id: int, permission_scope: str) -> List[dict]:
      async with db_pool.acquire() as conn:
          if permission_scope == "all":
              query = "SELECT * FROM projects ORDER BY created_at DESC"
              results = await conn.fetch(query)
          elif permission_scope == "own":
              query = "SELECT * FROM projects WHERE owner_user_id = $1 ORDER BY created_at DESC"
              results = await conn.fetch(query, user_id)
          return [dict(row) for row in results]

  async def get_project_by_id(db_pool: asyncpg.Pool, project_id: int, user_id: int, permission_scope: str) -> Optional[dict]:
      async with db_pool.acquire() as conn:
          if permission_scope == "all":
              query = "SELECT * FROM projects WHERE id = $1"
              result = await conn.fetchrow(query, project_id)
          elif permission_scope == "own":
              query = "SELECT * FROM projects WHERE id = $1 AND owner_user_id = $2"
              result = await conn.fetchrow(query, project_id, user_id)
          return dict(result) if result else None

  async def update_project(db_pool: asyncpg.Pool, project_id: int, project_data: dict, user_id: int, permission_scope: str) -> Optional[dict]:
      async with db_pool.acquire() as conn:
          base_query = "UPDATE projects SET name = $1, description = $2, status = $3, updated_at = $4"
          now = datetime.now(timezone.utc)
          
          if permission_scope == "all":
              query = f"{base_query} WHERE id = $5 RETURNING *"
              result = await conn.fetchrow(query, project_data["name"], project_data.get("description"), 
                                         project_data.get("status", "active"), now, project_id)
          elif permission_scope == "own":
              query = f"{base_query} WHERE id = $5 AND owner_user_id = $6 RETURNING *"
              result = await conn.fetchrow(query, project_data["name"], project_data.get("description"), 
                                         project_data.get("status", "active"), now, project_id, user_id)
          return dict(result) if result else None

  async def delete_project(db_pool: asyncpg.Pool, project_id: int, user_id: int, permission_scope: str) -> bool:
      async with db_pool.acquire() as conn:
          if permission_scope == "all":
              query = "DELETE FROM projects WHERE id = $1"
              result = await conn.execute(query, project_id)
          elif permission_scope == "own":
              query = "DELETE FROM projects WHERE id = $1 AND owner_user_id = $2"
              result = await conn.execute(query, project_id, user_id)
          return result == "DELETE 1"
  ```

#### **Step 3: Create Pydantic Schemas**
- Create `src/schemas/project.py` for request/response validation:
  ```python
  # src/schemas/project.py
  from pydantic import BaseModel, Field
  from typing import Optional
  from datetime import datetime

  class ProjectBase(BaseModel):
      name: str = Field(..., min_length=1, max_length=255)
      description: Optional[str] = None
      status: str = Field(default="active", pattern="^(active|inactive|completed)$")

  class ProjectCreate(ProjectBase):
      pass

  class ProjectUpdate(ProjectBase):
      pass

  class ProjectResponse(ProjectBase):
      id: int
      created_at: datetime
      updated_at: datetime
      owner_user_id: int

      class Config:
          from_attributes = True
  ```

#### **Step 4: Create API Routes**
- Add JSON API routes in `src/api/v1/endpoints/projects.py`:
  ```python
  # src/api/v1/endpoints/projects.py
  from fastapi import APIRouter, Depends, HTTPException
  from typing import List
  import asyncpg
  from src.api.deps import get_db_pool, require_permission, get_current_user_required
  from src.schemas.project import ProjectCreate, ProjectUpdate, ProjectResponse
  from src.db.projects import create_project, get_projects_by_permission, get_project_by_id, update_project, delete_project

  router = APIRouter()

  @router.get("/", response_model=List[ProjectResponse])
  async def list_projects(
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(require_permission("project:read:all")) or Depends(require_permission("project:read:own"))
  ):
      # Determine scope based on user permissions
      scope = "all" if current_user.has_permission("project:read:all") else "own"
      projects = await get_projects_by_permission(db_pool, current_user.id, scope)
      return projects

  @router.post("/", response_model=ProjectResponse)
  async def create_project_endpoint(
      project_data: ProjectCreate,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(require_permission("project:create:all"))
  ):
      project = await create_project(db_pool, project_data.dict(), current_user.id)
      return project

  @router.get("/{project_id}", response_model=ProjectResponse)
  async def get_project(
      project_id: int,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(require_permission("project:read:all")) or Depends(require_permission("project:read:own"))
  ):
      scope = "all" if current_user.has_permission("project:read:all") else "own"
      project = await get_project_by_id(db_pool, project_id, current_user.id, scope)
      if not project:
          raise HTTPException(status_code=404, detail="Project not found")
      return project

  @router.put("/{project_id}", response_model=ProjectResponse)
  async def update_project_endpoint(
      project_id: int,
      project_data: ProjectUpdate,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(require_permission("project:update:all")) or Depends(require_permission("project:update:own"))
  ):
      scope = "all" if current_user.has_permission("project:update:all") else "own"
      project = await update_project(db_pool, project_id, project_data.dict(), current_user.id, scope)
      if not project:
          raise HTTPException(status_code=404, detail="Project not found or no permission")
      return project

  @router.delete("/{project_id}")
  async def delete_project_endpoint(
      project_id: int,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(require_permission("project:delete:all")) or Depends(require_permission("project:delete:own"))
  ):
      scope = "all" if current_user.has_permission("project:delete:all") else "own"
      success = await delete_project(db_pool, project_id, current_user.id, scope)
      if not success:
          raise HTTPException(status_code=404, detail="Project not found or no permission")
      return {"message": "Project deleted successfully"}
  ```

#### **Step 5: Create HTML Routes**
- Add HTML form routes in `src/routers/html.py`:
  ```python
  # Add to src/routers/html.py
  
  @router.get("/projects")
  async def list_projects_html(
      request: Request,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(get_current_user_required)
  ):
      # Check permissions
      if not (current_user.has_permission("project:read:all") or current_user.has_permission("project:read:own")):
          raise HTTPException(status_code=403, detail="Insufficient permissions")
      
      scope = "all" if current_user.has_permission("project:read:all") else "own"
      projects = await get_projects_by_permission(db_pool, current_user.id, scope)
      
      return templates.TemplateResponse("projects/list.html", {
          "request": request,
          "projects": projects,
          "current_user": current_user,
          "can_create": current_user.has_permission("project:create:all")
      })

  @router.get("/projects/new")
  async def new_project_form(
      request: Request,
      current_user = Depends(require_permission("project:create:all"))
  ):
      return templates.TemplateResponse("projects/new.html", {
          "request": request,
          "current_user": current_user
      })

  @router.post("/projects")
  async def create_project_form(
      request: Request,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(require_permission("project:create:all"))
  ):
      form_data = await request.form()
      project_data = {
          "name": form_data.get("name"),
          "description": form_data.get("description"),
          "status": form_data.get("status", "active")
      }
      
      try:
          project = await create_project(db_pool, project_data, current_user.id)
          return RedirectResponse(url="/projects", status_code=302)
      except Exception as e:
          return templates.TemplateResponse("projects/new.html", {
              "request": request,
              "current_user": current_user,
              "error": str(e),
              "form_data": project_data
          })

  @router.get("/projects/{project_id}")
  async def view_project_html(
      request: Request,
      project_id: int,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(get_current_user_required)
  ):
      if not (current_user.has_permission("project:read:all") or current_user.has_permission("project:read:own")):
          raise HTTPException(status_code=403, detail="Insufficient permissions")
      
      scope = "all" if current_user.has_permission("project:read:all") else "own"
      project = await get_project_by_id(db_pool, project_id, current_user.id, scope)
      
      if not project:
          raise HTTPException(status_code=404, detail="Project not found")
      
      return templates.TemplateResponse("projects/detail.html", {
          "request": request,
          "project": project,
          "current_user": current_user,
          "can_edit": (current_user.has_permission("project:update:all") or 
                      (current_user.has_permission("project:update:own") and project["owner_user_id"] == current_user.id)),
          "can_delete": (current_user.has_permission("project:delete:all") or 
                        (current_user.has_permission("project:delete:own") and project["owner_user_id"] == current_user.id))
      })

  @router.get("/projects/{project_id}/edit")
  async def edit_project_form(
      request: Request,
      project_id: int,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(get_current_user_required)
  ):
      if not (current_user.has_permission("project:update:all") or current_user.has_permission("project:update:own")):
          raise HTTPException(status_code=403, detail="Insufficient permissions")
      
      scope = "all" if current_user.has_permission("project:update:all") else "own"
      project = await get_project_by_id(db_pool, project_id, current_user.id, scope)
      
      if not project:
          raise HTTPException(status_code=404, detail="Project not found")
      
      return templates.TemplateResponse("projects/edit.html", {
          "request": request,
          "project": project,
          "current_user": current_user
      })

  @router.post("/projects/{project_id}")
  async def update_project_form(
      request: Request,
      project_id: int,
      db_pool: asyncpg.Pool = Depends(get_db_pool),
      current_user = Depends(get_current_user_required)
  ):
      if not (current_user.has_permission("project:update:all") or current_user.has_permission("project:update:own")):
          raise HTTPException(status_code=403, detail="Insufficient permissions")
      
      form_data = await request.form()
      project_data = {
          "name": form_data.get("name"),
          "description": form_data.get("description"),
          "status": form_data.get("status", "active")
      }
      
      scope = "all" if current_user.has_permission("project:update:all") else "own"
      
      try:
          project = await update_project(db_pool, project_id, project_data, current_user.id, scope)
          if not project:
              raise HTTPException(status_code=404, detail="Project not found")
          return RedirectResponse(url=f"/projects/{project_id}", status_code=302)
      except Exception as e:
          original_project = await get_project_by_id(db_pool, project_id, current_user.id, scope)
          return templates.TemplateResponse("projects/edit.html", {
              "request": request,
              "project": original_project,
              "current_user": current_user,
              "error": str(e),
              "form_data": project_data
          })
  ```

#### **Step 6: Create HTML Templates**
- Create template files in `templates/projects/`:

**`templates/projects/list.html`:**
```html
{% extends "base.html" %}

{% block title %}Projects{% endblock %}

{% block content %}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1>Projects</h1>
                {% if can_create %}
                <a href="/projects/new" class="btn btn-primary">
                    <i class="fas fa-plus"></i> New Project
                </a>
                {% endif %}
            </div>

            {% if projects %}
            <div class="card">
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-striped">
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Description</th>
                                    <th>Status</th>
                                    <th>Created</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {% for project in projects %}
                                <tr>
                                    <td><a href="/projects/{{ project.id }}">{{ project.name }}</a></td>
                                    <td>{{ project.description[:50] + '...' if project.description and project.description|length > 50 else project.description or '' }}</td>
                                    <td>
                                        <span class="badge bg-{% if project.status == 'active' %}success{% elif project.status == 'completed' %}primary{% else %}secondary{% endif %}">
                                            {{ project.status.title() }}
                                        </span>
                                    </td>
                                    <td>{{ project.created_at.strftime('%Y-%m-%d') }}</td>
                                    <td>
                                        <a href="/projects/{{ project.id }}" class="btn btn-sm btn-outline-primary">View</a>
                                        <a href="/projects/{{ project.id }}/edit" class="btn btn-sm btn-outline-secondary">Edit</a>
                                    </td>
                                </tr>
                                {% endfor %}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            {% else %}
            <div class="alert alert-info">
                <h4>No projects found</h4>
                <p>{% if can_create %}Get started by <a href="/projects/new">creating your first project</a>.{% else %}No projects are available for your account.{% endif %}</p>
            </div>
            {% endif %}
        </div>
    </div>
</div>
{% endblock %}
```

**`templates/projects/detail.html`:**
```html
{% extends "base.html" %}

{% block title %}{{ project.name }}{% endblock %}

{% block content %}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <nav aria-label="breadcrumb">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><a href="/projects">Projects</a></li>
                            <li class="breadcrumb-item active">{{ project.name }}</li>
                        </ol>
                    </nav>
                    <h1>{{ project.name }}</h1>
                </div>
                <div>
                    {% if can_edit %}
                    <a href="/projects/{{ project.id }}/edit" class="btn btn-primary">
                        <i class="fas fa-edit"></i> Edit
                    </a>
                    {% endif %}
                    {% if can_delete %}
                    <button class="btn btn-danger" onclick="confirmDelete()">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                    {% endif %}
                </div>
            </div>

            <div class="card">
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-8">
                            <h5>Description</h5>
                            <p>{{ project.description or 'No description provided.' }}</p>
                        </div>
                        <div class="col-md-4">
                            <h5>Details</h5>
                            <dl class="row">
                                <dt class="col-sm-4">Status:</dt>
                                <dd class="col-sm-8">
                                    <span class="badge bg-{% if project.status == 'active' %}success{% elif project.status == 'completed' %}primary{% else %}secondary{% endif %}">
                                        {{ project.status.title() }}
                                    </span>
                                </dd>
                                <dt class="col-sm-4">Created:</dt>
                                <dd class="col-sm-8">{{ project.created_at.strftime('%Y-%m-%d %H:%M') }}</dd>
                                <dt class="col-sm-4">Updated:</dt>
                                <dd class="col-sm-8">{{ project.updated_at.strftime('%Y-%m-%d %H:%M') }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

{% if can_delete %}
<script>
function confirmDelete() {
    if (confirm('Are you sure you want to delete this project? This action cannot be undone.')) {
        fetch('/projects/{{ project.id }}', {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            }
        }).then(response => {
            if (response.ok) {
                window.location.href = '/projects';
            } else {
                alert('Error deleting project');
            }
        });
    }
}
</script>
{% endif %}
{% endblock %}
```

**`templates/projects/new.html` and `templates/projects/edit.html`:**
```html
{% extends "base.html" %}

{% block title %}{% if project %}Edit {{ project.name }}{% else %}New Project{% endif %}{% endblock %}

{% block content %}
<div class="container-fluid">
    <div class="row">
        <div class="col-12 col-md-8 col-lg-6 mx-auto">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="/projects">Projects</a></li>
                    {% if project %}
                    <li class="breadcrumb-item"><a href="/projects/{{ project.id }}">{{ project.name }}</a></li>
                    <li class="breadcrumb-item active">Edit</li>
                    {% else %}
                    <li class="breadcrumb-item active">New</li>
                    {% endif %}
                </ol>
            </nav>

            <h1>{% if project %}Edit {{ project.name }}{% else %}New Project{% endif %}</h1>

            {% if error %}
            <div class="alert alert-danger">{{ error }}</div>
            {% endif %}

            <div class="card">
                <div class="card-body">
                    <form method="POST" action="{% if project %}/projects/{{ project.id }}{% else %}/projects{% endif %}">
                        <div class="mb-3">
                            <label for="name" class="form-label">Name *</label>
                            <input type="text" class="form-control" id="name" name="name" 
                                   value="{{ form_data.name if form_data else (project.name if project else '') }}" required>
                        </div>

                        <div class="mb-3">
                            <label for="description" class="form-label">Description</label>
                            <textarea class="form-control" id="description" name="description" rows="4">{{ form_data.description if form_data else (project.description if project else '') }}</textarea>
                        </div>

                        <div class="mb-3">
                            <label for="status" class="form-label">Status</label>
                            <select class="form-select" id="status" name="status">
                                {% set current_status = form_data.status if form_data else (project.status if project else 'active') %}
                                <option value="active" {% if current_status == 'active' %}selected{% endif %}>Active</option>
                                <option value="inactive" {% if current_status == 'inactive' %}selected{% endif %}>Inactive</option>
                                <option value="completed" {% if current_status == 'completed' %}selected{% endif %}>Completed</option>
                            </select>
                        </div>

                        <div class="d-flex justify-content-between">
                            <a href="{% if project %}/projects/{{ project.id }}{% else %}/projects{% endif %}" class="btn btn-secondary">Cancel</a>
                            <button type="submit" class="btn btn-primary">{% if project %}Update{% else %}Create{% endif %} Project</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
{% endblock %}
```

#### **Step 7: Register Routes in Main Application**
- Add the new routes to your main FastAPI app and router includes:
  ```python
  # In src/api/v1/api.py
  from src.api.v1.endpoints.projects import router as projects_router
  api_router.include_router(projects_router, prefix="/projects", tags=["projects"])

  # In src/routers/html.py (if using separate file)
  # Or add directly to main router configuration
  ```

#### **Step 8: Update Navigation Menu**
- Add navigation links to `templates/base.html` with permission checks:
  ```html
  <!-- In templates/base.html navigation section -->
  {% if current_user and (current_user.has_permission("project:read:all") or current_user.has_permission("project:read:own")) %}
  <li class="nav-item">
      <a class="nav-link" href="/projects">Projects</a>
  </li>
  {% endif %}
  ```

#### **Step 9: Update Table Introspection**
- Ensure the new table appears in the `/tables` endpoint by updating the introspection logic to include "projects" in the available resources list.

#### **Step 10: Run Migration and Test**
- Run Flyway migration: `flyway migrate`
- Test all CRUD operations via HTML forms and JSON API
- Verify permission enforcement works correctly
- Test WebSocket events for the new resource

This comprehensive guide provides everything needed to add a new table to the system while maintaining consistency with the existing architecture and permission system.

### **Documentation**:

- Create comprehensive tech specs document including:
  - Complete database schema with Flyway migration examples
  - Authentication/authorization flow diagrams
  - Request processing flow with Redis queues
  - API endpoints (HTTP, WebSocket, HTML) with examples for all tables
  - Event streaming and monitoring capabilities
  - User registration flow and default role assignment
  - Admin interface documentation for managing roles, permissions, and sessions
  - **UI/UX Guidelines**: Bootstrap component usage and Unified branding standards
  - Flyway migration management and deployment
  - Redis queue management and monitoring
  - Error handling strategies
- Include example .env file with all required variables (database, Redis, ports)
- Document default user accounts and permissions

### **Testing & Validation**:

- **MUST INCLUDE**: After implementation, test the following:
  - Database connection and Flyway migrations
  - Redis connection and queue operations
  - User authentication (HTTP API, HTML forms, WebSocket)
  - **User registration functionality** (public access)
  - Permission enforcement (admin vs regular user)
  - CRUD operations for all tables via all three channels (HTTP, forms, WebSocket)
  - **Request queuing and processing** with UUID tracking
  - **Event monitoring and filtering** based on user permissions
  - **Admin table access** (roles, permissions, sessions management)
  - **Resource introspection** functionality allowing users to discover available resources
  - Session management and expiration
  - **Navigation menu** with proper permission-based visibility
  - **Real-time WebSocket functionality**
- Provide curl commands for testing API endpoints for all resources
- Verify HTML interface functionality for all implemented features
- Test WebSocket connections and event streaming

### **Delivery Requirements**:

- Complete working "Unified" application with professional Bootstrap UI and database initialized via Flyway
- All endpoints tested and functional for all resources via HTTP, HTML forms, and WebSocket
- Redis queue processing for request monitoring and event streaming
- Uniform authentication/authorization filter for all request types
- **Professional Interface**: Clean, responsive Bootstrap 5.3+ design throughout all pages
- **Unified Branding**: Consistent brand identity, logo, colors, and typography
- **Public user registration** functional and assigning default role with professional UI
- **Admin interfaces** for all system tables with proper permission checks and Bootstrap styling
- Permission system fully operational with professional navigation menu
- **Real-time capabilities**: WebSocket integration for live updates and monitoring
- **Mobile Responsive**: All interfaces work seamlessly on desktop, tablet, and mobile devices
- Clear documentation of how to run and test the application
- **Supervisor management** for robust server control with direct supervisord/supervisorctl commands
- **Flyway integration** for database migration management
- **Redis integration** for queuing, session storage, and event streaming
- **API versioning** properly implemented with `/api/v1/` prefix
- **Idiomatic FastAPI structure** following community standards

Keep implementation focused on core functionality, avoiding test suites or mocks, but structure code to be easily testable and extensible. Prioritize getting a working system that can be easily deployed and extended.

## Environment Details:

- **Environment Configuration**: Use the .env file in the workspace directory which contains:
  - DATABASE_URL=postgresql://claude:claudepassword321@postgres:5432/claude
  - REDIS_URL=redis://redis:6379/0
  - POSTGRES_HOST=postgres
  - POSTGRES_PORT=5432
  - POSTGRES_USER=claude
  - POSTGRES_PASSWORD=claudepassword321
  - POSTGRES_DB=claude
  - REDIS_HOST=redis
  - REDIS_PORT=6379
  - CLAUDE_HOST_PORT=[varies by version]
  - CLAUDE_INTERNAL_PORT=8000
  - POSTGRES_HOST_PORT=[varies by version]
- **Docker Container**: Development within Docker container with host port binding
- **Port Configuration**: Container port 8000 → Host port varies by version (check .env file)
- **Database**: Use existing "claude" database (already available in postgres container)
- **Redis**: Use Redis container for queuing and event streaming

## Success Criteria:

1. Application starts without errors with all services (FastAPI, Redis, Postgres)
2. **Flyway migrations** execute successfully and create all required tables
3. **Request UUID tracking** works for all incoming requests
4. **Redis queues** properly handle incoming and processed requests
5. **Uniform auth filter** correctly processes requests from all three sources (HTTP, forms, WebSocket)
6. **Public user registration** works and assigns default "user" role
7. Admin user can login and access all system tables (users, roles, permissions, sessions)
8. Regular user can login and see only their own data
9. All CRUD operations work via HTTP API, HTML forms, and WebSocket for all resources
10. **Event monitoring** works with proper permission filtering
11. **Navigation menu** shows appropriate links based on user permissions
12. Permission system correctly enforces access controls across all resources and request types
13. **WebSocket connections** work for real-time updates and monitoring
14. Session management works properly with Redis storage
15. **Admin interface** allows full management of roles, permissions, and sessions
16. **Resource introspection** allows users to discover which resources they can access based on their permissions
17. Application is ready for production deployment
18. **API endpoints** are properly versioned under `/api/v1/`
19. **Project structure** follows FastAPI community standards
20. **Real-time request monitoring** works for administrators
21. **Database operations** work efficiently without ORM using raw SQL