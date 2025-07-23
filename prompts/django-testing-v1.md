# Unified Management Application - Comprehensive Test Suite Generation (v4)

Generate comprehensive Gherkin feature tests for the **Unified Management Application** - a Django management system with authentication, authorization, service accounts, and token management using Python's `requests-html` library.

## Application Overview - Unified Management System

This is a complete professional management application built with FastAPI featuring:

### **Authentication & Authorization**

- **Session-based authentication**
- **Service token authentication** for API access
- **Public registration** (assigns default "user" role)
- **Admin interface** for complete system management

### **Core Models & Functionality**

- **User**: User management with roles, permissions, and authentication
- **Role**: Groups of permissions (admin, user, custom roles)
- **Session**: User session management and monitoring
- **ServiceToken**: API authentication tokens with permission inheritance and expiration

### **Default Accounts**

- **Admin**: `admin/admin123` (full system access including service account management)
- **Demo User**: `demo/demo123` (basic user permissions, can create own service accounts)

### **Dual Interfaces**

- **JSON API**: endpoints for programmatic access
- **HTML Web Interface**: `/` for browser-based interaction with professional UI

**Template Infrastructure Testing**:

- Verify all referenced templates exist on filesystem
- Validate template context variables are defined
- Test template rendering with proper datetime/timezone handling

3. **Response Format Validation**:
   - Strict status code validation (200, not just != 500)
   - Content-type header validation (text/html vs application/json)
   - Form validation and field presence checking

### Foundation Tests with Enhanced Validation\*\*

**IMPORTANT**: Create manual validation tests with strict assertions, then build Gherkin tests on top.

1. **Create enhanced pytest validation suite** (`test_manual_validation.py`)

   - Test app connectivity and database initialization
   - **Enhanced**: Strict response validation with exact status codes
   - Validate authentication flows work (session + service token)
   - Test CRUD operations with proper content-type validation
   - **NEW**: Cross-client consistency testing (requests vs requests-html)

2. **Build enhanced test utilities**

   - RequestsHTML wrapper with strict response validation
   - **NEW**: Multi-client testing support (raw requests, curl comparison)
   - Data generation utilities with unique constraint handling
   - Permission testing helpers with scope validation
   - **NEW**: Template and route validation utilities

3. **Add Gherkin layer with infrastructure scenarios**
   - Import all step definitions explicitly
   - Handle pytest-bdd discovery issues

## Unified Application-Specific Implementation Notes

### **Authentication Endpoint Expectations**

- **Session Login**: returns 200 with session cookie
- **Service Token Login**: Use `Authorization: Bearer {token}` header for API access

### **Service Account & Token System**

- **Token Generation**: Service tokens inherit subset of creator's permissions
- **Token Expiration**: All tokens have required expiration dates
- **Permission Inheritance**: Tokens get permissions from service account creator
- **API Authentication**: Tokens work with `Authorization: Bearer` header
