# FastAPI MVC CRUD Application - Implementation Prompt (Improved)

Create tech specs and implement a complete MVC CRUD application using Python, FastAPI and SQLAlchemy.

## Key Requirements:

### 1. **Authentication & Authorization**:

   - Use middleware for session-based authentication (store sessions in database)
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
   - Use proper relationship mappings (many-to-many for user_roles, role_permissions)
   - Include timestamps (created_at, updated_at) on all models with timezone awareness
   - Add password hashing for user model
   - Add ownership fields to models: owner_user_id and owner_group_id for record-level permissions
   - Permission model should store the three-part format: model, action, scope
   - **IMPORTANT**: Use timezone-aware datetime objects consistently (datetime.now(timezone.utc))

### 3. **Project Structure**:

   ```
   app/
   ├── __init__.py
   ├── main.py
   ├── config.py (settings with environment variables)
   ├── database.py (connection and session management)
   ├── models/
   │   ├── __init__.py
   │   ├── user.py
   │   ├── role.py
   │   ├── permission.py
   │   └── session.py
   ├── controllers/
   │   ├── __init__.py
   │   ├── auth.py (login/logout/registration)
   │   ├── user.py (CRUD operations)
   │   ├── role.py (CRUD operations)
   │   ├── permission.py (CRUD operations)
   │   └── session.py (CRUD operations)
   ├── views/
   │   ├── __init__.py
   │   └── templates/
   │       ├── base.html
   │       ├── login.html
   │       ├── register.html
   │       ├── users/
   │       │   ├── list.html
   │       │   ├── detail.html
   │       │   └── form.html
   │       ├── roles/
   │       │   ├── list.html
   │       │   ├── detail.html
   │       │   └── form.html
   │       ├── permissions/
   │       │   ├── list.html
   │       │   ├── detail.html
   │       │   └── form.html
   │       └── sessions/
   │           ├── list.html
   │           └── detail.html
   ├── middleware/
   │   ├── __init__.py
   │   └── auth.py
   ├── utils/
   │   ├── __init__.py
   │   ├── security.py (password hashing, session management)
   │   └── permissions.py (permission checking helpers)
   └── static/ (for CSS/JS if needed)
   ```

### 4. **Technical Specifications**:

   - Use Pydantic v2 for request/response validation
   - **IMPORTANT**: Add pydantic-settings for configuration management
   - **IMPORTANT**: Handle CORS_ORIGINS as both string and list in config
   - Implement dual routers: one for HTML views (Jinja2), one for JSON API
   - Support URL_PREFIX environment variable for reverse proxy deployment
   - Use python-dotenv for environment variables
   - **DOCKER DEPLOYMENT**: Configure uvicorn to bind to port 8080 (container port bound to host 8080)
   - Required dependencies: fastapi, sqlalchemy, psycopg2-binary, uvicorn, pydantic, pydantic-settings, python-jose, passlib, bcrypt, python-multipart, jinja2, python-dotenv, email-validator
   - Development dependencies: ruff (for linting and formatting)

### 5. **Implementation Details**:

   - Create base controller class with common CRUD operations
   - Use dependency injection for database sessions and current user
   - Implement proper error handling with HTTP exceptions
   - Add CORS middleware configuration
   - Create utility functions for permission checking
   - Use async/await patterns consistently
   - Include basic HTML forms with CSRF protection
   - Configure ruff for code linting and formatting (include ruff.toml or pyproject.toml configuration)
   - **IMPORTANT**: Create database initialization script with default data
   - **USER REGISTRATION**: Implement public registration form that assigns default "user" role
   - **ADMIN TABLES**: Create full CRUD interfaces for roles, permissions, and sessions (admin access only)
   - **NAVIGATION**: Add navigation menu with conditional links based on user permissions

### 6. **Database Setup**:
   - **CRITICAL**: Include database creation step before running initialization
   - Create initialization script that sets up:
     - Default permissions for all model:action:scope combinations (user, role, permission, session)
     - Admin and user roles with appropriate permissions
     - Default admin user (admin/admin123) and demo user (demo/demo123)
     - Assign default "user" role to new registrations
   - Handle database connection gracefully with proper error messages

### 7. **Configuration Management**:
   - Create both .env.example and .env files
   - Handle environment variable parsing properly (especially lists)
   - Include all required database connection parameters
   - Set appropriate defaults for development
   - **DOCKER ENVIRONMENT**: Set default port to 8080 for container deployment

### 8. **API Endpoints Specification**:

   **HTML Routes:**
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
   PUT  /users/{id}           # Update user
   DELETE /users/{id}         # Delete user
   
   # Roles (admin only)
   GET  /roles                # List roles (permission: role:read:all)
   GET  /roles/{id}           # View role detail
   GET  /roles/new            # New role form
   POST /roles                # Create role
   GET  /roles/{id}/edit      # Edit role form
   PUT  /roles/{id}           # Update role
   DELETE /roles/{id}         # Delete role
   
   # Permissions (admin only)
   GET  /permissions          # List permissions (permission: permission:read:all)
   GET  /permissions/{id}     # View permission detail
   GET  /permissions/new      # New permission form
   POST /permissions          # Create permission
   GET  /permissions/{id}/edit # Edit permission form
   PUT  /permissions/{id}     # Update permission
   DELETE /permissions/{id}   # Delete permission
   
   # Sessions (admin only)
   GET  /sessions             # List sessions (permission: session:read:all)
   GET  /sessions/{id}        # View session detail
   DELETE /sessions/{id}      # Delete session
   ```

   **JSON API Routes:**
   ```
   POST /api/auth/login       # JSON login
   POST /api/auth/logout      # JSON logout
   POST /api/auth/register    # JSON registration (public access)
   GET  /api/auth/me          # Current user info
   
   # All models follow same pattern: /api/{model}
   GET|POST /api/users        # List/Create users
   GET|PUT|DELETE /api/users/{id} # Get/Update/Delete user
   
   GET|POST /api/roles        # List/Create roles (admin only)
   GET|PUT|DELETE /api/roles/{id} # Get/Update/Delete role (admin only)
   
   GET|POST /api/permissions  # List/Create permissions (admin only)
   GET|PUT|DELETE /api/permissions/{id} # Get/Update/Delete permission (admin only)
   
   GET|DELETE /api/sessions   # List/Delete sessions (admin only)
   GET|DELETE /api/sessions/{id} # Get/Delete session (admin only)
   ```

### 9. **Documentation**:
   - Create comprehensive tech specs document including:
     - Complete database schema with SQL examples
     - Authentication/authorization flow diagrams
     - API endpoints (both HTML and JSON) with examples for all models
     - User registration flow and default role assignment
     - Admin interface documentation for managing roles, permissions, and sessions
     - Deployment configuration instructions
     - Error handling strategies
     - Future JWT migration path
   - Include example .env file with all required variables
   - Document default user accounts and permissions

### 9. **Testing & Validation**:
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

### 10. **Common Pitfalls to Avoid**:
   - **Timezone Issues**: Always use timezone-aware datetime objects
   - **Dependency Missing**: Install email-validator for EmailStr validation
   - **Configuration Parsing**: Handle comma-separated environment variables properly
   - **Database Creation**: Ensure database exists before running migrations
   - **Session Security**: Use proper session validation and cleanup

### 11. **Delivery Requirements**:
   - Complete working application with database initialized
   - All endpoints tested and functional for all models (users, roles, permissions, sessions)
   - Both HTML and API interfaces working
   - **Public user registration** functional and assigning default role
   - **Admin interfaces** for all system tables with proper permission checks
   - Permission system fully operational with navigation menu
   - Clear documentation of how to run and test the application

Keep implementation focused on core functionality, avoiding test suites or mocks, but structure code to be easily testable and extensible. Prioritize getting a working system that can be easily deployed and extended.

## Environment Details:
- **Docker Container**: Development within Docker container with host port binding
- **Port Configuration**: Container port 8080 → Host port 8080
- **Database Host**: postgres
- **Database Username**: claude  
- **Database Password**: claudepassword321
- **Database Name**: fastapi_crud (must be created first)

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