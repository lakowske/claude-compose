# Unified - Management Application (Version 1)

Create tech specs and implement "Unified", a complete professional management application using Python and Django with idiomatic project structure

## Key Requirements:

### Authentication & Authorization

- Admin has full access
- Users have the ability to modify their own data.
- **PUBLIC ACCESS**: Include user registration functionality (no authentication require)
- Accepts both service tokens and session ids for authorization
- Transports data over http and websocket
- Serves html and json
- Service tokens with expiration date owned and created by users.
- Service tokens inherit the users permissions, but can be further limited to a subset of the user permissions
- Views and management for permissions.

### **Configuration Management**:

- Use .env files
- Handle environment variable parsing properly (especially lists)
- Include all required database connection parameters
- Set appropriate defaults for development
- **PORT CONFIGURATION**: Use CLAUDE_INTERNAL_PORT environment variable for uvicorn binding

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

- Complete working "Unified" application with professional UI and database initialized
- All endpoints tested and functional for all models (accounts, passwords, roles, permissions, service tokens and sessions)
- Both HTML and API interfaces working with polished Bootstrap design
- **Professional Interface**: Clean, responsive design throughout all pages
- **Unified Branding**: Consistent brand identity, logo, colors, and typography
- **Public user registration** functional and assigning default role with professional UI
- **Admin interfaces** for all system tables with proper permission checks and Bootstrap styling
- Permission system fully operational with professional navigation menu
- **Mobile Responsive**: All interfaces work seamlessly on desktop, tablet, and mobile devices
- Clear documentation of how to run and test the application
- **Supervisor management** for robust server control with direct supervisord/supervisorctl commands
- **Supervisor configuration** (`supervisord.conf`) for process management and auto-reload
- **Idiomatic Django structure** following community standards

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
