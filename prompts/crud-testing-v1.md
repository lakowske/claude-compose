# FastAPI CRUD Application - Comprehensive Gherkin Test Generation Prompt

Generate comprehensive Gherkin feature tests for a FastAPI CRUD application using Python's `requests-html` library. The tests should cover all user actions without requiring heavyweight browser automation.

## Application Overview

This is a complete FastAPI MVC CRUD application with:

### **Authentication & Authorization**
- **Session-based authentication** (cookies, not JWT)
- **Role-based access control** with permission format: `model:action:scope`
  - `scope` can be: `all` (admin), `own` (user's records), `group` (group records)
- **Public registration** (assigns default "user" role)
- **Admin interface** for system management

### **Models & Permissions**
- **User**: Basic user management with roles
- **Role**: Groups of permissions (admin, user, custom roles)
- **Permission**: Fine-grained access control (`user:read:all`, `user:update:own`, etc.)
- **Session**: User session management

### **Default Accounts**
- **Admin**: `admin/admin123` (full system access)
- **Demo**: `demo/demo123` (basic user permissions)

### **Interfaces**
- **JSON API**: `/api/v1/` endpoints for programmatic access
- **HTML Web Interface**: `/` for browser-based interaction with forms and navigation

### **Key URLs**
- **Authentication**: `/login`, `/register`, `/logout`
- **API Docs**: `/api/v1/docs`
- **User Management**: `/users`, `/users/{id}`, `/users/{id}/edit`
- **Admin Only**: `/roles`, `/permissions`, `/sessions`

## Testing Requirements

### **Technology Stack**
- **Language**: Python 3.11+
- **HTTP Library**: `requests-html` (NOT Selenium/Playwright)
- **Test Framework**: `pytest` with Gherkin using `pytest-bdd`
- **Assertion Library**: Python `assert` statements
- **Session Management**: Handle cookies and authentication states

### **Coverage Requirements**

#### **Authentication Features**
- [ ] Public user registration with automatic role assignment
- [ ] User login with valid/invalid credentials
- [ ] Session persistence across requests
- [ ] Logout functionality
- [ ] Access control enforcement (401/403 responses)

#### **User Management**
- [ ] Admin can view all users
- [ ] Admin can create new users
- [ ] Admin can edit any user (including activation/deactivation)
- [ ] Admin can delete users (except self)
- [ ] Admin can assign/remove roles from users
- [ ] Regular users can view/edit only their own profile
- [ ] User profile updates (name, email, password)

#### **Role Management (Admin Only)**
- [ ] View all roles with their permissions
- [ ] Create new roles with permission assignment
- [ ] Edit existing roles (name, description, permissions)
- [ ] Delete custom roles (protect system roles: admin, user)
- [ ] Assign roles to users

#### **Permission Management (Admin Only)**
- [ ] View all system permissions
- [ ] Create custom permissions with model:action:scope format
- [ ] Edit existing permissions
- [ ] Delete permissions
- [ ] Validate permission format constraints

#### **Session Management (Admin Only)**
- [ ] View active user sessions
- [ ] View session details (user, IP, user agent, expiry)
- [ ] Delete individual sessions
- [ ] Bulk cleanup of expired sessions

#### **Navigation & UI**
- [ ] Navigation menu shows appropriate links based on permissions
- [ ] Dashboard displays relevant statistics for user role
- [ ] Form validation and error handling
- [ ] Success/error message display

#### **API Endpoint Testing**
- [ ] All CRUD operations via JSON API
- [ ] Authentication via API (login/logout/register)
- [ ] Permission enforcement on API endpoints
- [ ] Role assignment via API
- [ ] Proper HTTP status codes and JSON responses

## Test Structure Requirements

### **Feature File Organization**
Create separate `.feature` files for each major area:

```
features/
├── authentication.feature          # Login, register, logout
├── user_management.feature         # User CRUD operations
├── role_management.feature         # Role CRUD operations  
├── permission_management.feature   # Permission CRUD operations
├── session_management.feature      # Session management
├── api_authentication.feature      # API auth testing
├── api_crud_operations.feature     # API CRUD testing
└── access_control.feature          # Permission enforcement
```

### **Gherkin Best Practices**

#### **Scenario Structure**
- Use **Given-When-Then** format consistently
- Include **Background** sections for common setup
- Use **Scenario Outline** with **Examples** for data-driven tests
- Tag scenarios with `@api`, `@web`, `@admin`, `@user` for filtering

#### **Step Definitions Requirements**
- **Parameterized steps** for different users, roles, and data
- **Session management** to maintain authentication state
- **Form handling** for HTML interface testing
- **JSON parsing** for API response validation
- **Error handling** for both success and failure scenarios

#### **Example Scenario Patterns**

```gherkin
Feature: User Authentication
  
  Background:
    Given the application is running
    And the database is initialized with default data

  @web
  Scenario: Successful user registration
    Given I am not authenticated
    When I visit the registration page
    And I fill in the registration form with:
      | username  | testuser           |
      | email     | test@example.com   |
      | full_name | Test User          |
      | password  | testpass123        |
    And I submit the registration form
    Then I should be redirected to the dashboard
    And I should see "Registration successful"
    And I should have the "user" role assigned

  @api
  Scenario Outline: API authentication with different credentials
    Given I am not authenticated
    When I send a POST request to "/api/v1/auth/login" with:
      | username   | <username> |
      | password   | <password> |
    Then I should receive a <status> status code
    And the response should contain "<message>"

    Examples:
      | username | password  | status | message           |
      | admin    | admin123  | 200    | Login successful  |
      | admin    | wrongpass | 401    | Incorrect         |
      | invalid  | admin123  | 401    | Incorrect         |
```

### **Data Management**

#### **Test Data Strategy**
- **Database reset** before each scenario or feature
- **Fixture data** for consistent testing (admin, demo users, roles, permissions)
- **Dynamic data** generation for create/update operations
- **Cleanup procedures** for test isolation

#### **Session Handling**
```python
# Example session management in step definitions
from requests_html import HTMLSession

class TestContext:
    def __init__(self):
        self.session = HTMLSession()
        self.current_user = None
        self.base_url = "http://localhost:8000"
    
    def login_as(self, username, password):
        response = self.session.post(f"{self.base_url}/login", 
                                   data={"username": username, "password": password})
        assert response.status_code == 302  # Redirect on success
        self.current_user = username
```

### **Validation Requirements**

#### **HTML Interface Testing**
- **Form submission** with various input combinations
- **Navigation link** visibility based on user permissions
- **Error message** display and formatting
- **Success message** confirmation
- **Page redirects** after operations
- **Table/list content** validation

#### **API Interface Testing**
- **HTTP status codes** (200, 201, 400, 401, 403, 404)
- **JSON response structure** and content
- **Authentication headers** and cookies
- **CRUD operation results** in database
- **Permission enforcement** on endpoints

#### **Cross-Interface Consistency**
- **Data synchronization** between HTML and API interfaces
- **Permission enforcement** consistency
- **Session sharing** between interfaces

### **Error Scenarios**

#### **Authentication Errors**
- Invalid credentials (401)
- Expired sessions (401)
- Access to protected resources without auth (401)
- Insufficient permissions (403)

#### **Validation Errors**
- Duplicate usernames/emails (400)
- Invalid email formats (400)
- Password mismatch (400)
- Required field validation (400)

#### **Business Logic Errors**
- Self-deletion prevention (400)
- Essential role protection (400)
- Permission format validation (400)

## Implementation Guidelines

### **File Structure**
```
tests/
├── conftest.py                 # Pytest configuration and fixtures
├── step_definitions/
│   ├── __init__.py
│   ├── common.py              # Shared step definitions
│   ├── authentication.py     # Auth-related steps
│   ├── user_management.py     # User CRUD steps
│   ├── role_management.py     # Role CRUD steps
│   ├── permission_management.py
│   ├── session_management.py
│   └── api_steps.py           # API-specific steps
├── features/                  # Gherkin feature files
└── utils/
    ├── __init__.py
    ├── test_client.py         # requests-html wrapper
    ├── data_helpers.py        # Test data generation
    └── assertions.py          # Custom assertion helpers
```

### **Dependencies**
```python
# requirements-test.txt
pytest>=7.0.0
pytest-bdd>=6.0.0
requests-html>=0.10.0
pytest-html>=3.0.0        # Test reporting
faker>=18.0.0             # Test data generation
```

### **Key Testing Utilities**

#### **HTML Form Helpers**
```python
def fill_form(session, form_selector, data):
    """Fill HTML form fields with provided data"""
    
def submit_form(session, form_selector):
    """Submit HTML form and return response"""
    
def assert_form_error(response, error_message):
    """Assert that form displays specific error"""
```

#### **API Helpers**
```python
def api_request(session, method, endpoint, data=None):
    """Make authenticated API request"""
    
def assert_json_response(response, expected_data):
    """Assert JSON response contains expected data"""
    
def assert_permission_denied(response):
    """Assert 403 Forbidden response"""
```

### **Execution Strategy**
- **Parallel execution** where possible (different user sessions)
- **Sequential execution** for data-dependent scenarios
- **Test reporting** with HTML output showing coverage
- **CI/CD integration** with clear pass/fail criteria

## Success Criteria

The generated test suite should:

1. **Cover 100% of user actions** described in the application
2. **Test both HTML and API interfaces** comprehensively
3. **Validate permission enforcement** at all levels
4. **Handle error scenarios** gracefully
5. **Maintain test isolation** and reliability
6. **Execute efficiently** without browser overhead
7. **Provide clear failure reporting** with actionable information
8. **Support different environments** (local, staging, production)

## Deliverables Expected

1. **Complete Gherkin feature files** covering all scenarios
2. **Python step definitions** implementing all steps
3. **Test utilities and helpers** for common operations
4. **Configuration files** for pytest and test execution
5. **Documentation** for running and maintaining tests
6. **Example test execution** commands and expected output

Generate a comprehensive test suite that ensures the FastAPI CRUD application works correctly for all user types and scenarios while maintaining fast execution through requests-html instead of browser automation.