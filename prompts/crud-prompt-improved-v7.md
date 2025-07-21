# FastAPI MVC CRUD Application - Implementation Prompt (Version 7)

Create tech specs and implement a complete MVC CRUD application using Python, FastAPI and SQLAlchemy with idiomatic FastAPI project structure.

## Key Requirements:

### 1. **Model Discovery & Schema Review**:

- **IMPORTANT**: Review the `migrations/` directory for existing database schema definitions
- Identify and implement models for all tables found in the migration files (in addition to core auth models)
- Use existing schema definitions as the source of truth for model structure and relationships
- Ensure all discovered models are properly integrated into the CRUD application
- Create complete CRUD interfaces for all discovered models with appropriate permissions

### 2. **Authentication & Authorization**:

- **IMPORTANT**: Use dependency injection for authentication, NOT middleware (FastAPI middleware can cause routing conflicts)
- Implement Role Based Access Control with fine-grain permissions
- Create permission system with format: `<model>:<action>:<scope>` where scope is:
  - `all` - perform action on all records
  - `own` - perform action only on records owned by the user
  - `group` - perform action on records owned by user's group(s)
- Admin role permissions: ALL models with full CRUD permissions (create:all, read:all, update:all, delete:all)
- Regular user role permissions: user:read:own, user:update:own, plus appropriate permissions for owned records
- **PUBLIC ACCESS**: Include user registration functionality (no authentication required)
- Design to allow future JWT token support

### 3. **Database & Models**:

- Create SQLAlchemy models based on discovered schema in `migrations/`
- **REQUIRED MODELS**: users, roles, permissions, sessions, plus all additional models found in migration files
- **CRITICAL**: Use explicit foreign_keys in relationships to avoid conflicts:

  ```python
  # In User model
  sessions = relationship("Session", back_populates="user", cascade="all, delete", foreign_keys="Session.user_id")

  # In Session model
  user = relationship("User", back_populates="sessions", foreign_keys=[user_id])
  ```

- Use proper relationship mappings (many-to-many for user_roles, role_permissions)
- Include timestamps (created_at, updated_at) on all models with timezone awareness
- Add password hashing for user model
- Add ownership fields to models: owner_user_id and owner_group_id for record-level permissions
- Permission model should store the three-part format: model, action, scope
- **IMPORTANT**: Use timezone-aware datetime objects consistently (datetime.now(timezone.utc))

### 4. **Project Structure (Idiomatic FastAPI)**:

```
app/
├── __init__.py
├── main.py                    # FastAPI app creation and configuration
├── core/                      # Core functionality
│   ├── __init__.py
│   ├── config.py             # Settings with environment variables
│   ├── database.py           # Database connection and session management
│   └── security.py           # Password hashing, session management
├── models/                    # SQLAlchemy models
│   ├── __init__.py
│   ├── user.py
│   ├── role.py
│   ├── permission.py
│   ├── session.py
│   └── [additional models]   # Models discovered from migrations/
├── schemas/                   # Pydantic models for request/response validation
│   ├── __init__.py
│   ├── user.py               # UserCreate, UserUpdate, UserResponse
│   ├── role.py               # RoleCreate, RoleUpdate, RoleResponse
│   ├── permission.py         # PermissionCreate, PermissionUpdate, PermissionResponse
│   ├── session.py            # SessionResponse
│   ├── [additional schemas]  # Schemas for discovered models
│   └── auth.py               # LoginRequest, RegisterRequest, AuthResponse
├── crud/                      # Database operations (separate from routes)
│   ├── __init__.py
│   ├── base.py               # Base CRUD class with common operations
│   ├── user.py               # User CRUD operations
│   ├── role.py               # Role CRUD operations
│   ├── permission.py         # Permission CRUD operations
│   ├── session.py            # Session CRUD operations
│   └── [additional crud]     # CRUD operations for discovered models
├── api/                       # JSON API routes
│   ├── __init__.py
│   ├── deps.py               # Dependencies (auth, db session, permissions)
│   └── v1/                   # API versioning
│       ├── __init__.py
│       ├── router.py         # Main API router
│       └── endpoints/
│           ├── __init__.py
│           ├── auth.py       # Authentication endpoints
│           ├── users.py      # User CRUD endpoints
│           ├── roles.py      # Role CRUD endpoints
│           ├── permissions.py # Permission CRUD endpoints
│           ├── sessions.py   # Session CRUD endpoints
│           └── [additional endpoints] # Endpoints for discovered models
├── routers/                   # HTML routes (using Jinja2 templates)
│   ├── __init__.py
│   └── html.py               # All HTML routes for web interface
├── templates/                 # Jinja2 templates (moved to app root)
│   ├── base.html
│   ├── login.html
│   ├── register.html
│   ├── dashboard.html
│   ├── users/
│   │   ├── list.html
│   │   ├── detail.html
│   │   └── form.html
│   ├── roles/
│   │   ├── list.html
│   │   ├── detail.html
│   │   └── form.html
│   ├── permissions/
│   │   ├── list.html
│   │   ├── detail.html
│   │   └── form.html
│   ├── sessions/
│   │   ├── list.html
│   │   └── detail.html
│   └── [additional templates]/ # Templates for discovered models
│       ├── list.html
│       ├── detail.html
│       └── form.html
├── utils/                     # Utility functions
│   ├── __init__.py
│   └── permissions.py        # Permission checking helpers
├── static/                    # Static files (CSS/JS/images)
│   ├── css/
│   ├── js/
│   └── images/
├── init_db.py                # Database initialization script
├── run_server.py             # Uvicorn startup script with --reload
└── supervisord.conf          # Supervisor configuration for process management
```

### 5. **Technical Specifications**:

- Use Pydantic v2 for request/response validation
- **IMPORTANT**: Add pydantic-settings for configuration management
- **IMPORTANT**: Handle CORS_ORIGINS as both string and list in config
- **IMPORTANT**: Add `model_config = ConfigDict(extra="ignore")` to Pydantic models to handle additional environment variables
- Implement dual interfaces: JSON API (`/api/v1/`) and HTML web interface (`/`)
- Support URL_PREFIX environment variable for reverse proxy deployment
- Use python-dotenv for environment variables
- **PORT CONFIGURATION**: Use CLAUDE_INTERNAL_PORT environment variable instead of hardcoded ports
- Required dependencies: python3-venv, fastapi, sqlalchemy, psycopg2-binary, uvicorn, pydantic, pydantic-settings, python-jose, passlib, bcrypt, python-multipart, jinja2, python-dotenv, email-validator, supervisor
- Development dependencies: ruff (for linting and formatting)

### 6. **Implementation Details**:

- **Separation of Concerns**: Keep routes, business logic, and data access separate
  - `api/` and `routers/` - Route definitions only
  - `crud/` - Database operations
  - `schemas/` - Data validation and serialization
- Use dependency injection for database sessions, current user, and permissions
- Implement proper error handling with HTTP exceptions
- Add CORS middleware configuration
- Create utility functions for permission checking
- Use async/await patterns consistently
- Include basic HTML forms with CSRF protection
- Configure ruff for code linting and formatting (include ruff.toml or pyproject.toml configuration)
- **IMPORTANT**: Create database initialization script with default data
- **USER REGISTRATION**: Implement public registration form that assigns default "user" role
- **ADMIN TABLES**: Create full CRUD interfaces for ALL models (admin access only for system models)
- **NAVIGATION**: Add navigation menu with conditional links based on user permissions
- **DEVELOPMENT SCRIPT**: Create `run_server.py` script that starts uvicorn with --reload for fast development iterations

### 7. **Dependency Injection Pattern**:

- **Centralized Dependencies** in `api/deps.py`:

  ```python
  # Database session dependency
  def get_db() -> Generator[Session, None, None]:
      ...

  # Authentication dependencies
  def get_current_user(db: Session = Depends(get_db), session_id: str = Cookie(None)) -> Optional[User]:
      ...

  def get_current_user_required(current_user: User = Depends(get_current_user)) -> User:
      ...

  # Permission dependencies
  def require_permission(permission_string: str):
      def dependency(current_user: User = Depends(get_current_user_required)):
          if not current_user.has_permission_string(permission_string):
              raise HTTPException(status_code=403, detail="Insufficient permissions")
          return current_user
      return dependency
  ```

### 8. **Form Handling (Critical for HTML Interface)**:

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

### 9. **Database Setup**:

- **CRITICAL**: Include database creation step before running initialization
- Create initialization script that sets up:
  - Default permissions for ALL discovered models with all action:scope combinations
  - Admin and user roles with appropriate permissions
  - Default admin user (admin/admin123) and demo user (demo/demo123)
  - Assign default "user" role to new registrations
- Handle database connection gracefully with proper error messages

### 9.1. **Development Server Management with Supervisor**:

- **IMPORTANT**: Create supervisor configuration to manage uvicorn server:
  - Use supervisor to control uvicorn process with `--reload` flag
  - Automatic restart on crashes or file changes
  - Process logging and monitoring
  - Easy start/stop/restart commands
  - Uses CLAUDE_INTERNAL_PORT from environment variables

- **IMPORTANT**: Create `supervisord.conf` configuration file:
```ini
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:uvicorn]
command=uvicorn app.main:app --host 0.0.0.0 --port %(ENV_CLAUDE_INTERNAL_PORT)s --reload
directory=/workspace
autostart=true
autorestart=true
stderr_logfile=/var/log/uvicorn.err.log
stdout_logfile=/var/log/uvicorn.out.log
environment=PATH="/workspace/.venv/bin:%(ENV_PATH)s"
user=claude
```

- **IMPORTANT**: Create `run_server.py` script that:
  - Initializes the database if needed
  - Starts supervisor to manage uvicorn process
  - Provides easy control commands (start/stop/restart)
  - Shows process status and logs

```python
# Example run_server.py structure
#!/usr/bin/env python3
"""
Development server script with supervisor management
Usage: python run_server.py [start|stop|restart|status|logs]
"""
import os
import subprocess
import sys
from pathlib import Path

def manage_server(action="start"):
    """Manage uvicorn server via supervisor"""
    # Load environment variables
    # Initialize database if needed
    # Control supervisor process
    # Handle start/stop/restart/status commands
    # Show logs when requested
```

### 10. **Configuration Management**:

- Create both .env.example and .env files
- Handle environment variable parsing properly (especially lists)
- Include all required database connection parameters
- Set appropriate defaults for development
- **PORT CONFIGURATION**: Use CLAUDE_INTERNAL_PORT environment variable for uvicorn binding

### 11. **API Endpoints Specification**:

**HTML Routes (in `routers/html.py`):**

```
GET  /                     # Home page (redirect to appropriate dashboard)
GET  /login                # Login form
POST /login                # Process login
GET  /register             # Registration form (public access)
POST /register             # Process registration (public access)
POST /logout               # Logout user

# Users
GET  /users                # List users
GET  /users/{id}           # View user detail
GET  /users/new            # New user form
POST /users                # Create user
GET  /users/{id}/edit      # Edit user form
POST /users/{id}           # Update user
DELETE /users/{id}         # Delete user

# Roles (admin only)
GET  /roles                # List roles
GET  /roles/{id}           # View role detail
GET  /roles/new            # New role form
POST /roles                # Create role
GET  /roles/{id}/edit      # Edit role form
POST /roles/{id}           # Update role
DELETE /roles/{id}         # Delete role

# Permissions (admin only)
GET  /permissions          # List permissions
GET  /permissions/{id}     # View permission detail
GET  /permissions/new      # New permission form
POST /permissions          # Create permission
GET  /permissions/{id}/edit # Edit permission form
POST /permissions/{id}     # Update permission
DELETE /permissions/{id}   # Delete permission

# Sessions (admin only)
GET  /sessions             # List sessions
GET  /sessions/{id}        # View session detail
DELETE /sessions/{id}      # Delete session

# Additional Models (discovered from migrations/)
# Complete CRUD routes for each discovered model following the pattern:
GET  /model_name           # List records
GET  /model_name/{id}      # View record detail
GET  /model_name/new       # New record form
POST /model_name           # Create record
GET  /model_name/{id}/edit # Edit record form
POST /model_name/{id}      # Update record
DELETE /model_name/{id}    # Delete record
```

**JSON API Routes (in `api/v1/endpoints/`):**

```
# Authentication (api/v1/endpoints/auth.py)
POST /api/v1/auth/login       # JSON login
POST /api/v1/auth/logout      # JSON logout
POST /api/v1/auth/register    # JSON registration (public access)
GET  /api/v1/auth/me          # Current user info

# Users (api/v1/endpoints/users.py)
GET|POST /api/v1/users        # List/Create users
GET|PUT|DELETE /api/v1/users/{id} # Get/Update/Delete user

# Roles (api/v1/endpoints/roles.py)
GET|POST /api/v1/roles        # List/Create roles (admin only)
GET|PUT|DELETE /api/v1/roles/{id} # Get/Update/Delete role (admin only)

# Permissions (api/v1/endpoints/permissions.py)
GET|POST /api/v1/permissions  # List/Create permissions (admin only)
GET|PUT|DELETE /api/v1/permissions/{id} # Get/Update/Delete permission (admin only)

# Sessions (api/v1/endpoints/sessions.py)
GET|DELETE /api/v1/sessions   # List/Delete sessions (admin only)
GET|DELETE /api/v1/sessions/{id} # Get/Delete session (admin only)

# Additional Models (api/v1/endpoints/[model_name].py)
# Complete API endpoints for each discovered model following the pattern:
GET|POST /api/v1/model_name   # List/Create records
GET|PUT|DELETE /api/v1/model_name/{id} # Get/Update/Delete record
```

### 12. **Documentation**:

- Create comprehensive tech specs document including:
  - Complete database schema with SQL examples for ALL models
  - Authentication/authorization flow diagrams
  - API endpoints (both HTML and JSON) with examples for ALL models
  - User registration flow and default role assignment
  - Admin interface documentation for managing ALL system models
  - Deployment configuration instructions
  - Error handling strategies
  - Future JWT migration path
- Include example .env file with all required variables
- Document default user accounts and permissions

### 13. **Testing & Validation**:

- **MUST INCLUDE**: After implementation, test the following:
  - Database connection and table creation for ALL models
  - User authentication (both API and HTML)
  - **User registration functionality** (public access)
  - Permission enforcement (admin vs regular user)
  - CRUD operations for ALL models (both core auth models and all models discovered from migrations/)
  - **Admin table access** (system model management)
  - Session management and expiration
  - **Navigation menu** with proper permission-based visibility
- Provide curl commands for testing API endpoints for ALL models
- Verify HTML interface functionality for ALL implemented features

### 14. **Common Pitfalls to Avoid**:

- **SQLAlchemy Relationships**: Always use explicit foreign_keys to avoid circular references
- **FastAPI Middleware**: Use dependency injection instead of custom middleware for authentication
- **Form Handling**: Use `await request.form()` and `getlist()` for complex forms
- **Route Completeness**: Ensure ALL CRUD operations have corresponding HTML routes for ALL models
- **422 Errors**: Handle Pydantic validation properly with `extra="ignore"` in model_config
- **Import Organization**: Keep imports clean with proper module organization
- **Template Paths**: Update template paths to reflect new `templates/` location
- **Circular Imports**: Avoid circular imports with proper dependency structure
- **Timezone Issues**: Always use timezone-aware datetime objects
- **Dependency Missing**: Install email-validator for EmailStr validation
- **Configuration Parsing**: Handle comma-separated environment variables properly
- **Database Creation**: Ensure database exists before running migrations
- **Session Security**: Use proper session validation and cleanup

### 15. **Delivery Requirements**:

- Complete working application with database initialized
- All endpoints tested and functional for ALL models
- Both HTML and API interfaces working
- **Public user registration** functional and assigning default role
- **Admin interfaces** for all system tables with proper permission checks
- **Business data interfaces** for all models discovered from migrations/
- Permission system fully operational with navigation menu
- Clear documentation of how to run and test the application
- **Development script** (`run_server.py`) with supervisor management for robust server control
- **Supervisor configuration** (`supervisord.conf`) for process management and auto-reload
- **API versioning** properly implemented with `/api/v1/` prefix
- **Idiomatic FastAPI structure** following community standards

Keep implementation focused on core functionality, avoiding test suites or mocks, but structure code to be easily testable and extensible. Prioritize getting a working system that can be easily deployed and extended.

## Environment Details:

- **Environment Configuration**: Use the .env file in the workspace directory which contains:
  - DATABASE_URL=postgresql://claude:claudepassword321@postgres:5432/claude
  - POSTGRES_HOST=postgres
  - POSTGRES_PORT=5432
  - POSTGRES_USER=claude
  - POSTGRES_PASSWORD=claudepassword321
  - POSTGRES_DB=claude
  - CLAUDE_HOST_PORT=[varies by version]
  - CLAUDE_INTERNAL_PORT=8000
  - POSTGRES_HOST_PORT=[varies by version]
- **Docker Container**: Development within Docker container with host port binding
- **Port Configuration**: Container port 8000 → Host port varies by version (check .env file)
- **Database**: Use existing "claude" database (already available in postgres container)

## Success Criteria:

1. Application starts without errors
2. **Public user registration** works and assigns default "user" role
3. Admin user can login and access all system tables (users, roles, permissions, sessions)
4. Regular user can login and see appropriate data based on permissions
5. All CRUD operations work via API and HTML for ALL models
6. **Navigation menu** shows appropriate links based on user permissions
7. Permission system correctly enforces access controls across ALL models
8. Session management works properly
9. **Admin interface** allows full management of all system models
10. **Business data interface** allows management of all models discovered from migrations/
11. Application is ready for production deployment
12. **API endpoints** are properly versioned under `/api/v1/`
13. **Project structure** follows FastAPI community standards

## Key Improvements in Version 7:

- **Schema Discovery**: Reviews existing migration files to identify required models
- **Extended Model Support**: Includes all models discovered from existing migrations/
- **Complete CRUD Coverage**: Ensures all discovered models have full CRUD interfaces
- **Enhanced Permission System**: Supports permissions for all model types
- **Comprehensive Documentation**: Covers all models in API and HTML interfaces
- **Business Data Management**: Provides interfaces for managing business-critical data
- **Migration Integration**: Uses existing schema definitions as source of truth
- **Supervisor Integration**: Uses supervisor for robust process management with auto-reload
- **Development Script**: Enhanced `run_server.py` with supervisor control and process management

This prompt incorporates schema discovery and extends the application to support additional business models while maintaining all FastAPI best practices and security features from previous versions.