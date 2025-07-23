# Unified - Management Application (Version 6)

Create tech specs and implement "Unified", a complete professional management application using Python, FastAPI and SQLAlchemy with idiomatic FastAPI project structure and polished Bootstrap UI.

## Key Requirements:

### 1. **Authentication & Authorization**:

- **IMPORTANT**: Use dependency injection for authentication, NOT middleware (FastAPI middleware can cause routing conflicts)
- Implement Role Based Access Control with fine-grain permissions
- Create permission system with format: `<model>:<action>:<scope>` where scope is:
  - `all` - perform action on all records
  - `own` - perform action only on records owned by the user
  - `group` - perform action on records owned by user's group(s)
- Admin role permissions: user:create:all, user:read:all, user:update:all, user:delete:all, role:read:all, permission:read:all, session:read:all
- Regular user role permissions: user:read:own, user:update:own
- **PUBLIC ACCESS**: Include user registration functionality (no authentication required)
- Design to allow future JWT token support

### 2. **Database & Models**:

- Create SQLAlchemy models for users, roles, permissions, and sessions only
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

### 3. **Project Structure (Idiomatic FastAPI)**:

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
│   └── session.py
├── schemas/                   # Pydantic models for request/response validation
│   ├── __init__.py
│   ├── user.py               # UserCreate, UserUpdate, UserResponse
│   ├── role.py               # RoleCreate, RoleUpdate, RoleResponse
│   ├── permission.py         # PermissionCreate, PermissionUpdate, PermissionResponse
│   ├── session.py            # SessionResponse
│   └── auth.py               # LoginRequest, RegisterRequest, AuthResponse
├── crud/                      # Database operations (separate from routes)
│   ├── __init__.py
│   ├── base.py               # Base CRUD class with common operations
│   ├── user.py               # User CRUD operations
│   ├── role.py               # Role CRUD operations
│   ├── permission.py         # Permission CRUD operations
│   └── session.py            # Session CRUD operations
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
│           └── sessions.py   # Session CRUD endpoints
├── routers/                   # HTML routes (using Jinja2 templates)
│   ├── __init__.py
│   └── html.py               # All HTML routes for web interface
├── templates/                 # Jinja2 templates with Bootstrap UI
│   ├── base.html              # Professional Bootstrap base template with Unified branding
│   ├── login.html             # Polished login form with Bootstrap styling
│   ├── register.html          # Professional registration form
│   ├── dashboard.html         # Clean dashboard with Bootstrap cards and layouts
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
│   └── sessions/
│       ├── list.html
│       └── detail.html
├── utils/                     # Utility functions
│   ├── __init__.py
│   └── permissions.py        # Permission checking helpers
├── static/                    # Static files (CSS/JS/images)
│   ├── css/
│   │   ├── unified.css        # Custom Unified branding and theme
│   │   └── bootstrap.min.css  # Bootstrap 5.3+ framework
│   ├── js/
│   │   ├── unified.js         # Custom JavaScript for enhanced UX
│   │   └── bootstrap.bundle.min.js # Bootstrap JavaScript
│   └── images/
│       ├── unified-logo.png   # Unified brand logo
│       └── favicon.ico        # Professional favicon
├── init_db.py                # Database initialization script
├── supervisord.conf          # Supervisor configuration for process management
├── logs/                      # Supervisor and application log files
│   ├── supervisord.log       # Supervisor daemon log
│   ├── uvicorn.out.log       # Uvicorn stdout log
│   └── uvicorn.err.log       # Uvicorn stderr log
└── requirements.txt          # Generated from pyproject.toml for deployment compatibility
```

### 4. **Technical Specifications**:

- Use Pydantic v2 for request/response validation
- **IMPORTANT**: Add pydantic-settings for configuration management
- **IMPORTANT**: Handle CORS_ORIGINS as both string and list in config
- **IMPORTANT**: Add `model_config = ConfigDict(extra="ignore")` to Pydantic models to handle additional environment variables
- Implement dual interfaces: JSON API (`/api/v1/`) and HTML web interface (`/`)
- Support URL_PREFIX environment variable for reverse proxy deployment
- Use python-dotenv for environment variables
- **PORT CONFIGURATION**: Use CLAUDE_INTERNAL_PORT environment variable instead of hardcoded ports
- Required dependencies: python3-venv, fastapi, sqlalchemy, psycopg2-binary, uvicorn, pydantic, pydantic-settings, python-jose, passlib, bcrypt, python-multipart, jinja2, python-dotenv, email-validator, supervisor
- **UI FRAMEWORK**: Bootstrap 5.3+ for professional, responsive design with modern components
- Development dependencies: ruff (for linting and formatting)

### 5. **Implementation Details**:

- **Separation of Concerns**: Keep routes, business logic, and data access separate
  - `api/` and `routers/` - Route definitions only
  - `crud/` - Database operations
  - `schemas/` - Data validation and serialization
- Use dependency injection for database sessions, current user, and permissions
- Implement proper error handling with HTTP exceptions
- Add CORS middleware configuration
- Create utility functions for permission checking
- Use async/await patterns consistently
- **PROFESSIONAL UI**: Implement polished Bootstrap 5.3+ interface with:
  - Modern responsive design and professional color scheme
  - Clean typography and consistent spacing
  - Professional form styling with validation feedback
  - Loading states, success/error notifications
  - Mobile-friendly navigation and layouts
- Include HTML forms with CSRF protection and Bootstrap styling
- Configure ruff for code linting and formatting (include ruff.toml or pyproject.toml configuration)
- **IMPORTANT**: Create database initialization script with default data
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

### 6. **Dependency Injection Pattern**:

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

### 7. **Form Handling (Critical for HTML Interface)**:

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

### 8. **Database Setup**:

- **CRITICAL**: Include database creation step before running initialization
- Create initialization script that sets up:
  - Default permissions for all model:action:scope combinations (user, role, permission, session)
  - Admin and user roles with appropriate permissions
  - Default admin user (admin/admin123) and demo user (demo/demo123)
  - Assign default "user" role to new registrations
- Handle database connection gracefully with proper error messages

### 8.1. **Development Server Management with Supervisor**:

- **IMPORTANT**: Create supervisor configuration to manage uvicorn server:
  - Use supervisor to control uvicorn process with `--reload` flag
  - Automatic restart on crashes or file changes
  - Process logging and monitoring
  - Easy start/stop/restart commands
  - Uses CLAUDE_INTERNAL_PORT from environment variables

- **IMPORTANT**: Create `supervisord.conf` configuration file:
```ini
[supervisord]
nodaemon=false
logfile=./logs/supervisord.log
pidfile=./logs/supervisord.pid
childlogdir=./logs
logfile_maxbytes=50MB
logfile_backups=10
loglevel=info

[program:uvicorn]
command=/workspace/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port %(ENV_CLAUDE_INTERNAL_PORT)s --reload
directory=/workspace
autostart=true
autorestart=true
stderr_logfile=./logs/uvicorn.err.log
stdout_logfile=./logs/uvicorn.out.log
stderr_logfile_maxbytes=10MB
stdout_logfile_maxbytes=10MB
stderr_logfile_backups=5
stdout_logfile_backups=5
environment=PATH="/workspace/.venv/bin:%(ENV_PATH)s"
user=claude
```

- **IMPORTANT**: Use supervisor directly for all server management:
  - Always use supervisord and supervisorctl commands
  - Initialize database manually when needed
  - Use supervisor for robust process control
  - Access logs through ./logs directory

```bash
# Server management commands (use these instead of run_server.py)

# Start supervisor daemon
mkdir -p logs
supervisord -c supervisord.conf

# Control uvicorn process
supervisorctl -c supervisord.conf start uvicorn
supervisorctl -c supervisord.conf stop uvicorn
supervisorctl -c supervisord.conf restart uvicorn
supervisorctl -c supervisord.conf status

# View logs
tail -f ./logs/uvicorn.out.log
tail -f ./logs/uvicorn.err.log
tail -f ./logs/supervisord.log

# Stop supervisor daemon
supervisorctl -c supervisord.conf shutdown
```

### 9. **Configuration Management**:

- Create both .env.example and .env files
- Handle environment variable parsing properly (especially lists)
- Include all required database connection parameters
- Set appropriate defaults for development
- **PORT CONFIGURATION**: Use CLAUDE_INTERNAL_PORT environment variable for uvicorn binding

### 10. **API Endpoints Specification**:

**HTML Routes (in `routers/html.py`):**

```
GET  /                     # Home page (redirect to appropriate dashboard)
GET  /login                # Login form
POST /login                # Process login
GET  /register             # Registration form (public access)
POST /register             # Process registration (public access)
POST /logout               # Logout user

# Users
GET  /users                # List users (permission: user:read:all or user:read:own)
GET  /users/{id}           # View user detail
GET  /users/new            # New user form (permission: user:create:all)
POST /users                # Create user
GET  /users/{id}/edit      # Edit user form
POST /users/{id}           # Update user (use POST, not PUT for HTML forms)
DELETE /users/{id}         # Delete user

# Roles (admin only)
GET  /roles                # List roles (permission: role:read:all)
GET  /roles/{id}           # View role detail
GET  /roles/new            # New role form
POST /roles                # Create role
GET  /roles/{id}/edit      # Edit role form
POST /roles/{id}           # Update role (use POST, not PUT for HTML forms)
DELETE /roles/{id}         # Delete role

# Permissions (admin only)
GET  /permissions          # List permissions (permission: permission:read:all)
GET  /permissions/{id}     # View permission detail
GET  /permissions/new      # New permission form
POST /permissions          # Create permission
GET  /permissions/{id}/edit # Edit permission form
POST /permissions/{id}     # Update permission (use POST, not PUT for HTML forms)
DELETE /permissions/{id}   # Delete permission

# Sessions (admin only)
GET  /sessions             # List sessions (permission: session:read:all)
GET  /sessions/{id}        # View session detail
DELETE /sessions/{id}      # Delete session
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
```

### 11. **Professional UI Design & Branding**:

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

### 12. **Documentation**:

- Create comprehensive tech specs document including:
  - Complete database schema with SQL examples
  - Authentication/authorization flow diagrams
  - API endpoints (both HTML and JSON) with examples for all models
  - User registration flow and default role assignment
  - Admin interface documentation for managing roles, permissions, and sessions
  - **UI/UX Guidelines**: Bootstrap component usage and Unified branding standards
  - Deployment configuration instructions
  - Error handling strategies
  - Future JWT migration path
- Include example .env file with all required variables
- Document default user accounts and permissions

### 13. **Testing & Validation**:

- **MUST INCLUDE**: After implementation, test the following:
  - Database connection and table creation
  - User authentication (both API and HTML)
  - **User registration functionality** (public access)
  - Permission enforcement (admin vs regular user)
  - CRUD operations for all models (users, roles, permissions, sessions)
  - **Admin table access** (roles, permissions, sessions management)
  - Session management and expiration
  - **Navigation menu** with proper permission-based visibility
- Provide curl commands for testing API endpoints for all models
- Verify HTML interface functionality for all implemented features

### 14. **Common Pitfalls to Avoid**:

- **SQLAlchemy Relationships**: Always use explicit foreign_keys to avoid circular references
- **FastAPI Middleware**: Use dependency injection instead of custom middleware for authentication
- **Form Handling**: Use `await request.form()` and `getlist()` for complex forms
- **Route Completeness**: Ensure ALL CRUD operations have corresponding HTML routes
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

- Complete working "Unified" application with professional Bootstrap UI and database initialized
- All endpoints tested and functional for all models (users, roles, permissions, sessions)
- Both HTML and API interfaces working with polished Bootstrap design
- **Professional Interface**: Clean, responsive Bootstrap 5.3+ design throughout all pages
- **Unified Branding**: Consistent brand identity, logo, colors, and typography
- **Public user registration** functional and assigning default role with professional UI
- **Admin interfaces** for all system tables with proper permission checks and Bootstrap styling
- Permission system fully operational with professional navigation menu
- **Mobile Responsive**: All interfaces work seamlessly on desktop, tablet, and mobile devices
- Clear documentation of how to run and test the application
- **Supervisor management** for robust server control with direct supervisord/supervisorctl commands
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
4. Regular user can login and see only their own data
5. All CRUD operations work via API and HTML for all models
6. **Navigation menu** shows appropriate links based on user permissions
7. Permission system correctly enforces access controls across all models
8. Session management works properly
9. **Admin interface** allows full management of roles, permissions, and sessions
10. Application is ready for production deployment
11. **API endpoints** are properly versioned under `/api/v1/`
12. **Project structure** follows FastAPI community standards

## Key Improvements in Version 6:

- **Professional "Unified" Branding**: Complete brand identity with professional logo, colors, and typography
- **Bootstrap 5.3+ Integration**: Modern, responsive UI framework for enterprise-grade appearance
- **Polished User Experience**: Professional forms, navigation, notifications, and mobile responsiveness
- **Idiomatic FastAPI structure** following community standards and documentation
- **Clear separation of concerns** with dedicated `crud/`, `schemas/`, and `api/` directories
- **API versioning** with proper `/api/v1/` structure for future extensibility
- **Centralized dependency injection** in `api/deps.py` for better organization
- **Improved template organization** with templates at app root level
- **Enhanced maintainability** through proper layering and module organization
- **Better scalability** with clear boundaries between components
- **Industry standard patterns** making it easier for new developers to contribute
- **Supervisor Integration**: Direct supervisor commands for process management and auto-reload
- **Professional Static Assets**: Custom CSS, JavaScript, and branding assets for polished appearance

This prompt incorporates all lessons learned from previous implementations plus FastAPI community best practices and professional UI/UX design for maximum usability, maintainability, and visual appeal.
