## Postgres based CRUD server using RBAC and event streaming

Create tech specs and implement "Unified", a professional management application using Python, FastAPI and Postgres tables with idiomatic
FastAPI Project Structure and polished Bootstrap UI.

## Key Requirements:

### Authentication & Authorization

- Create permission system with format `<table>:<action>:<scope>` where scope is:
  - `all` - perform action on all records
  - `own` - perform action on only records owned by the user
  - `group` - perform action on records owned by user's group
- Wildcard syntax:
  - `*:read:all` means access to read from all tables
  - `user:*:all` means user can perform all actions on the user table
  - `*:*:*` means access to all table, all operations, all scope
- Admin role permissions: _:_:all
- User role permissions: user:read:own, user:update:own
- **PUBLIC ACCESS**: Include user registration functionality (no authentication require)
- Accepts both service tokens and session ids for authorization
- Transports data over http and websocket
- Serves html and json

### Database tables

- Create tables for accounts, passwords, roles, permissions, service tokens and sessions
- Use foreign key in relationships
- Use proper relationship mappings (many-to-many for account_roles, role_permissions)
- Include timestamps (created_at, updated_at) on all tables with timezone awareness
- Use bcrypt hashing for user accounts
- Use sha256 hashing for service accounts
- Include the hash function in the passwords table.
- Add ownership fields to tables: owner_user_id and owner_group_id for record-level permissions
- Permission table should store the three-part format: table, action, scope
- **IMPORTANT**: Use timezone-aware datetime objects consistently (datetime.now(timezone.utc))

### **Technical Specifications**:

- Use Pydantic v2 for request/response validation
- Use modern logging practices, ensure logging occurs at the boundaries of function calls and service requests.
- Use pyproject.toml and a .venv to install dependencies
- **IMPORTANT**: Add pydantic-settings for configuration management
- **IMPORTANT**: Handle CORS_ORIGINS as both string and list in config
- Support URL_PREFIX environment variable for reverse proxy deployment
- Use python-dotenv for environment variables
- **PORT CONFIGURATION**: Always use CLAUDE_INTERNAL_PORT environment variable instead of hardcoded ports
- Required dependencies: python3-venv, fastapi, psycopg2-binary, uvicorn, pydantic, pydantic-settings, python-jose, passlib, bcrypt, python-multipart, jinja2, python-dotenv, email-validator, supervisor
- **UI FRAMEWORK**: Bootstrap 5.3+ for professional, responsive design with modern components
- Development dependencies: ruff (for linting and formatting)- **UI FRAMEWORK**: Bootstrap 5.3+ for professional, responsive design with modern components
- Development dependencies: ruff (for linting and formatting)

### **Implementation Details**:

- **Separation of Concerns**: Keep routes, business logic, and data access separate
  - `api/` and `routers/` - Route definitions only
  - `crud/` - Database operations
  - `schemas/` - Data validation and serialization
- Use dependency injection for database sessions, current user, and permissions
- Implement proper error handling with HTTP exceptions
- Add CORS middleware configuration
- Create utility functions for permission checking
- Use async/await patterns consistently
- Use Postgres notify/listen to serve table change events over websockets
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

### **Dependency Injection Pattern**:

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

### **Database Setup**:

- **CRITICAL**: Include database creation step before running initialization
- Create initialization script that sets up:
  - Default permissions for all model:action:scope combinations (user, role, permission, session)
  - Admin and user roles with appropriate permissions
  - Default admin user (admin/admin123) and demo user (demo/demo123)
  - Assign default "user" role to new registrations
- Handle database connection gracefully with proper error messages

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
- Set appropriate defaults for development
- **PORT CONFIGURATION**: Use CLAUDE_INTERNAL_PORT environment variable for uvicorn binding

### Partial **API Endpoints Specification**:

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

...

```

**Partial list of JSON API Routes (in `api/v1/endpoints/`):**

```
GET  /api/v1/watch/{table}        # Watch for table changes (permission: {table}:read:all).
GET  /api/v1/watch                # Watch all table changes (permission: *:read:all).
GET  /api/v1/tables               # Get the list of tables (permission: *:read:all)

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

...
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

### **Documentation**:

- Create comprehensive tech specs document including:
  - Complete database schema with SQL examples
  - Authentication/authorization flow diagrams
  - API endpoints (both HTML and JSON) with examples for all tables
  - User registration flow and default role assignment
  - Admin interface documentation for managing roles, permissions, and sessions
  - **UI/UX Guidelines**: Bootstrap component usage and Unified branding standards
  - Deployment configuration instructions
  - Error handling strategies
- Include example .env file with all required variables
- Document default user accounts and permissions

### **Testing & Validation**:

- **MUST INCLUDE**: After implementation, test the following:
  - Database connection and table creation
  - User authentication (both API and HTML)
  - **User registration functionality** (public access)
  - Permission enforcement (admin vs regular user)
  - CRUD operations for all tables (accounts, passwords, roles, permissions, service tokens and sessions)
  - **Admin table access** (roles, permissions, sessions management)
  - Session management and expiration
  - **Navigation menu** with proper permission-based visibility
- Provide curl commands for testing API endpoints for all tables
- Verify HTML interface functionality for all implemented features

### **Delivery Requirements**:

- Complete working "Unified" application with professional Bootstrap UI and database initialized
- All endpoints tested and functional for all models (accounts, passwords, roles, permissions, service tokens and sessions)
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
