# Unified Management Application - Comprehensive Test Suite Generation (v4)

Generate comprehensive Gherkin feature tests for the **Unified Management Application** - a FastAPI-based management system with authentication, authorization, service accounts, and token management using Python's `requests-html` library.

## Application Overview - Unified Management System

This is a complete professional management application built with FastAPI featuring:

### **Authentication & Authorization**
- **Session-based authentication** (cookies, not JWT)
- **Service token authentication** for API access
- **Role-based access control** with fine-grained permissions: `<model>:<action>:<scope>`
  - `scope` can be: `all` (admin access), `own` (user's records), `group` (group records)
- **Public registration** (assigns default "user" role)
- **Admin interface** for complete system management

### **Core Models & Functionality**
- **User**: User management with roles, permissions, and authentication
- **Role**: Groups of permissions (admin, user, custom roles)
- **Permission**: Fine-grained access control (`user:read:all`, `service_account:create:own`, etc.)
- **Session**: User session management and monitoring
- **ServiceAccount**: API automation accounts for programmatic access
- **ServiceToken**: API authentication tokens with permission inheritance and expiration

### **Default Accounts**
- **Admin**: `admin/admin123` (full system access including service account management)
- **Demo User**: `demo/demo123` (basic user permissions, can create own service accounts)

### **Dual Interfaces**
- **JSON API**: `/api/v1/` endpoints for programmatic access
- **HTML Web Interface**: `/` for browser-based interaction with professional Bootstrap UI

### **Key URLs & Endpoints**

#### **Authentication & Core**
- **Authentication**: `/login`, `/register`, `/logout`, `/profile`
- **API Docs**: `/docs` (Interactive Swagger documentation)
- **API Authentication**: `/api/v1/auth/login`, `/api/v1/auth/me`, `/api/v1/auth/register`

#### **Management Interfaces** 
- **User Management**: `/users`, `/users/{id}`, `/users/new`, `/users/{id}/edit`
- **Role Management**: `/roles`, `/roles/{id}`, `/roles/new` (admin only)
- **Permission Management**: `/permissions`, `/permissions/{id}` (admin only)
- **Session Management**: `/sessions`, `/sessions/{id}` (admin only)

#### **Service Account & Token Management** (NEW)
- **Service Accounts**: `/service-accounts`, `/service-accounts/{id}`, `/service-accounts/new`
- **Service Tokens**: `/service-tokens`, `/service-tokens/{id}`, `/service-tokens/new`

#### **API Endpoints**
- **Users API**: `/api/v1/users`
- **Roles API**: `/api/v1/roles`
- **Permissions API**: `/api/v1/permissions`
- **Sessions API**: `/api/v1/sessions`
- **Service Accounts API**: `/api/v1/service-accounts`
- **Service Tokens API**: `/api/v1/service-tokens`

## ⚡ Implementation Strategy (CRITICAL - READ FIRST)

### **Phase 0: Infrastructure Validation (NEW - CRITICAL)**
**MANDATORY FIRST STEP**: Before any business logic testing, validate the web framework foundation to prevent route conflicts and template errors.

1. **Route Infrastructure Testing**:
   - Test FastAPI route registration completeness
   - **CRITICAL**: Validate route ordering (specific routes before parameterized)
   - Detect route conflicts that cause 422 parsing errors
   - Verify form routes return HTML, API routes return JSON

2. **Template Infrastructure Testing**:
   - Verify all referenced templates exist on filesystem  
   - Validate template context variables are defined
   - Detect undefined template variables ({{ undefined }}) before runtime
   - Test template rendering with proper datetime/timezone handling

3. **Response Format Validation**:
   - Strict status code validation (200, not just != 500)
   - Content-type header validation (text/html vs application/json)
   - No error response leakage in production pages
   - Form validation and field presence checking

### **Phase 1: Foundation Tests with Enhanced Validation**
**IMPORTANT**: Create manual validation tests with strict assertions, then build Gherkin tests on top.

1. **Create enhanced pytest validation suite** (`test_manual_validation.py`)
   - Test app connectivity and database initialization
   - **NEW**: Validate route conflicts don't exist (specific before parameterized)
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
   - **NEW**: Route conflict detection scenarios
   - Import all step definitions explicitly
   - Handle pytest-bdd discovery issues
   - **NEW**: Infrastructure validation scenarios

## Unified Application-Specific Implementation Notes

### **Authentication Endpoint Expectations**
- **Session Login**: `POST /api/v1/auth/login` returns 200 with session cookie
- **Service Token Login**: Use `Authorization: Bearer {token}` header for API access
- **Me endpoint**: `GET /api/v1/auth/me` returns user data with permissions array
- **Permission format**: Use `permission_string` field in API responses
- **Registration**: `POST /api/v1/auth/register` for public user registration

### **Service Account & Token System**
- **Service Account Creation**: Users can create service accounts for API automation
- **Token Generation**: Service tokens inherit subset of creator's permissions
- **Token Expiration**: All tokens have required expiration dates
- **Permission Inheritance**: Tokens get permissions from service account creator
- **API Authentication**: Tokens work with `Authorization: Bearer` header

### **Permission System Details**
- **Admin Permissions**: `user:*:all`, `role:*:all`, `permission:*:all`, `session:*:all`, `service_account:*:all`, `service_token:*:all`
- **User Permissions**: `user:read:own`, `user:update:own`, `service_account:*:own`, `service_token:*:own`
- **Permission Enforcement**: Regular users get 403 for admin-only endpoints
- **Scope Validation**: `all` vs `own` access properly enforced

## Enhanced Test Coverage Requirements

### **Infrastructure Test Scenarios (NEW - CRITICAL)**
```gherkin
Feature: Route Infrastructure
  Background:
    Given the FastAPI application is running
    
  Scenario Outline: Specific routes beat parameterized routes
    Given I am logged in as admin
    When I navigate to "<specific_route>"
    Then I should get a 200 response
    And the content type should be "text/html"  
    And the response should contain a form
    And the response should not contain JSON error messages
    And the response should not contain parsing errors
    
    Examples:
      | specific_route        |
      | /users/new           |
      | /service-accounts/new|
      | /service-tokens/new  |
      
  Scenario: Route registration order validation
    When I inspect the FastAPI route table
    Then specific routes should be registered before parameterized routes
    And no route ordering conflicts should exist
    And all expected routes should be present

Feature: Template Infrastructure  
  Background:
    Given the FastAPI application is running
    And I am logged in as admin
    
  Scenario Outline: Template rendering integrity
    When I navigate to "<page_url>"
    Then the page should render without template errors
    And no undefined template variables should be present
    And all template context variables should be defined
    And datetime variables should be properly formatted
    
    Examples:
      | page_url              |
      | /                     |
      | /users                |
      | /service-accounts     |
      | /service-tokens       |
      | /users/new            |
      | /service-accounts/new |
      | /service-tokens/new   |

Feature: Response Format Validation
  Background:
    Given the FastAPI application is running
    And I am logged in as admin
    
  Scenario Outline: HTML endpoints return proper HTML
    When I request "<html_endpoint>" 
    Then the status code should be exactly 200
    And the content type should be "text/html"
    And the response should contain valid HTML structure
    And no JSON error responses should be returned
    
    Examples:
      | html_endpoint         |
      | /                     |
      | /users                |
      | /users/new            |
      | /service-accounts/new |
      
  Scenario Outline: API endpoints return proper JSON
    When I request "<api_endpoint>"
    Then the status code should be 200 or 201
    And the content type should be "application/json" 
    And the response should contain valid JSON structure
    And no HTML error pages should be returned
    
    Examples:
      | api_endpoint             |
      | /api/v1/users           |
      | /api/v1/service-accounts|
      | /api/v1/service-tokens  |
```

### **Multi-Client Validation Scenarios (NEW)**
```gherkin
Feature: Cross-Client Consistency
  Background:
    Given the FastAPI application is running
    And I am logged in as admin
    
  Scenario Outline: Same response across HTTP clients
    When I request "<endpoint>" using requests-html
    And I request "<endpoint>" using raw requests  
    And I request "<endpoint>" using curl subprocess
    Then all clients should return the same status code
    And all clients should return the same content type
    And the response content should be consistent across clients
    
    Examples:
      | endpoint              |
      | /users/new           |
      | /service-accounts/new|
      | /api/v1/users        |
```

### **Enhanced User Management Test Scenarios**
```gherkin
Feature: User Management
  Scenario: Admin creates new user with roles
  Scenario: Admin assigns multiple roles to user  
  Scenario: User updates own profile information
  Scenario: User cannot access other users' data
  Scenario: Admin deactivates user account
  Scenario: Registration creates user with default role
  Scenario: User password reset functionality
  # NEW: Infrastructure validation
  Scenario: User form pages return HTML not JSON errors
  Scenario: User API endpoints return JSON not HTML pages
```

### **Service Account Management Test Scenarios**
```gherkin
Feature: Service Account Management
  Scenario: User creates service account for API access
  Scenario: Admin views all service accounts system-wide
  Scenario: User can only see own service accounts
  Scenario: Service account shows associated tokens count
  Scenario: Deactivating service account affects tokens
  Scenario: Service account creator permissions inheritance
  Scenario: Multiple users create separate service accounts
  # NEW: Route validation
  Scenario: Service account form returns HTML form not parsing errors
  Scenario: Service account API returns JSON not template errors
```

### **Service Token Management Test Scenarios**
```gherkin
Feature: Service Token Management
  Scenario: Create service token with expiration date
  Scenario: Service token inherits creator permissions
  Scenario: Token authentication works for API calls
  Scenario: Expired tokens are rejected
  Scenario: Token shows last used timestamp
  Scenario: User can revoke own service tokens
  Scenario: Admin can view all service tokens
  Scenario: Token permissions subset validation
  Scenario: Token usage tracking and audit
  # NEW: Template validation
  Scenario: Service token form renders with proper datetime handling
  Scenario: Service token pages show expiration status correctly
```

### **API Authentication Test Scenarios**
```gherkin
Feature: API Authentication
  Scenario: Session authentication works for web interface
  Scenario: Service token authentication works for API
  Scenario: Invalid service token is rejected
  Scenario: Expired service token is rejected  
  Scenario: Token permissions are enforced in API calls
  Scenario: Mixed authentication (session + token) handling
  # NEW: Response format validation
  Scenario: Authentication errors return proper content types
  Scenario: API endpoints never return HTML error pages
```

### **Permission & Role Management Test Scenarios**
```gherkin
Feature: Permission and Role Management
  Scenario: Admin creates custom role with specific permissions
  Scenario: Role permission assignment and removal
  Scenario: User inherits permissions from multiple roles
  Scenario: Permission scope enforcement (all vs own vs group)
  Scenario: Dynamic permission checking in UI
  Scenario: Permission changes reflected immediately
  Scenario: Default permissions for new registrations
```

### **Session Management Test Scenarios**
```gherkin
Feature: Session Management
  Scenario: Admin views all active sessions
  Scenario: Admin revokes specific user session
  Scenario: Session expiration handling
  Scenario: Multiple concurrent sessions per user
  Scenario: Session activity tracking
  Scenario: Logout invalidates session
```

### **Access Control Test Scenarios**
```gherkin
Feature: Access Control
  Scenario: Regular user cannot access admin functions
  Scenario: User can only modify own service accounts
  Scenario: Service token scope limitations
  Scenario: Permission-based navigation visibility
  Scenario: API endpoint permission enforcement
  Scenario: Role-based feature access
```

### **Integration & Workflow Test Scenarios**
```gherkin
Feature: Complete Workflows
  Scenario: New user registration to API token creation
  Scenario: Admin creates user, assigns roles, user creates service account
  Scenario: Service account creation, token generation, API usage
  Scenario: Role modification affects existing users immediately
  Scenario: Service account deactivation cascades to tokens
  Scenario: User profile update with role changes
  Scenario: Mass user import with role assignment
```

### **Professional UI Test Scenarios**
```gherkin
Feature: Web Interface
  Scenario: Bootstrap navigation works with permissions
  Scenario: Dashboard cards show relevant functionality
  Scenario: Forms handle validation errors gracefully
  Scenario: Tables show pagination and sorting
  Scenario: Breadcrumb navigation is accurate
  Scenario: Mobile responsive design works
  Scenario: Success/error notifications display
  # NEW: Template integrity
  Scenario: No undefined template variables in any page
  Scenario: All form pages contain expected form fields
  Scenario: Error pages render properly without template errors
```

### **API Comprehensive Test Scenarios**
```gherkin
Feature: REST API Operations
  Scenario: CRUD operations for all models via API
  Scenario: API versioning (/api/v1/) works correctly
  Scenario: JSON response format consistency
  Scenario: API error handling and status codes
  Scenario: Swagger documentation accessibility
  Scenario: API rate limiting (if implemented)
  Scenario: Bulk operations via API
  # NEW: Content type validation  
  Scenario: All API responses have correct JSON content type
  Scenario: API endpoints never return HTML error pages
```

## Enhanced Test Structure Requirements

### **Enhanced File Structure for Unified App**
```
tests/
├── requirements.txt                  # Test dependencies with service token support
├── conftest.py                      # Pytest fixtures with API token helpers
├── pytest.ini                      # Pytest configuration
├── run_tests.py                     # Enhanced test runner with coverage
├── test_infrastructure.py           # NEW: Route/template infrastructure validation
├── test_route_conflicts.py          # NEW: Route ordering conflict detection
├── test_response_formats.py         # NEW: Content-type and format validation
├── test_multi_client.py             # NEW: Cross-client consistency validation
├── test_manual_validation.py        # Enhanced with strict assertions
├── test_authentication.py           # Session + token auth scenarios
├── test_user_management.py          # User CRUD scenarios
├── test_service_accounts.py         # Service account scenarios
├── test_service_tokens.py           # Service token scenarios  
├── test_permissions.py              # Permission and role scenarios
├── test_workflows.py                # End-to-end workflow scenarios
├── test_api_comprehensive.py        # Full API test scenarios
├── test_web_interface_comprehensive.py # NEW: Enhanced UI testing
├── test_form_operations.py          # NEW: Form submission validation
├── test_template_rendering.py       # NEW: Template integrity testing
├── step_definitions/
│   ├── __init__.py
│   ├── common.py                    # Shared steps (authentication, navigation)
│   ├── infrastructure_steps.py     # NEW: Infrastructure validation steps
│   ├── authentication.py           # Login/logout/registration steps
│   ├── user_management.py           # User CRUD steps
│   ├── service_account_steps.py     # Service account management steps
│   ├── service_token_steps.py       # Service token management steps
│   ├── role_management.py           # Role and permission steps
│   ├── session_management.py        # Session handling steps
│   ├── api_steps.py                 # API-specific steps with token auth
│   ├── ui_steps.py                  # UI navigation and form steps
│   └── workflow_steps.py            # Complex workflow steps
├── features/                        # Gherkin feature files
│   ├── infrastructure.feature       # NEW: Infrastructure validation
│   ├── route_conflicts.feature      # NEW: Route conflict detection
│   ├── response_formats.feature     # NEW: Response format validation
│   ├── authentication.feature
│   ├── user_management.feature  
│   ├── service_accounts.feature
│   ├── service_tokens.feature
│   ├── permissions.feature
│   ├── sessions.feature
│   ├── workflows.feature
│   └── api_comprehensive.feature
├── utils/
│   ├── __init__.py
│   ├── test_client.py               # Enhanced RequestsHTML wrapper
│   ├── multi_client.py              # NEW: Multi-client testing support
│   ├── service_token_client.py      # Service token authentication helper
│   ├── data_helpers.py              # Test data generation (users, tokens, etc.)
│   ├── permission_helpers.py        # Permission validation utilities
│   ├── route_validators.py          # NEW: Route infrastructure validation
│   ├── template_validators.py       # NEW: Template validation utilities
│   └── assertions.py                # Enhanced assertion helpers
```

## Enhanced Test Client Requirements

### **Enhanced Unified Application Test Client**
```python
class UnifiedTestClient:
    def __init__(self, base_url):
        self.session = HTMLSession()
        self.base_url = base_url
        self.current_user = None
        self.current_service_token = None
        
    # Authentication methods
    def login_as_user(self, username, password):
        """Login with session cookies"""
        
    def login_with_service_token(self, token):
        """Authenticate using service token"""
        
    # Service account/token management
    def create_service_account(self, name, description):
        """Create service account for current user"""
        
    def create_service_token(self, service_account_id, permissions):
        """Generate service token with specific permissions"""
        
    def api_request_with_token(self, method, endpoint, data=None):
        """Make API request with service token authentication"""
        
    # Permission validation
    def check_permissions(self, required_permission):
        """Validate user has required permission"""
        
    # Enhanced navigation with validation
    def navigate_to_page(self, path):
        """Navigate to web interface page with response validation"""
        
    def submit_form_data(self, form_data, action):
        """Submit HTML form with proper encoding and validation"""
        
    # NEW: Infrastructure validation methods
    def validate_route_exists(self, route_path):
        """Verify route is properly registered"""
        
    def validate_no_route_conflicts(self):
        """Check for route ordering conflicts"""
        
    def validate_template_rendering(self, path):
        """Ensure template renders without errors"""
        
    # NEW: Multi-client comparison
    def compare_with_raw_requests(self, path):
        """Compare response with raw requests library"""
        
    def validate_content_type(self, response, expected_type):
        """Strict content-type validation"""

# NEW: Multi-client testing support
class MultiClientTester:
    def __init__(self, base_url):
        self.base_url = base_url
        self.html_session = HTMLSession()
        self.requests_session = requests.Session()
        
    def test_with_all_clients(self, path, auth_data=None):
        """Test same endpoint with multiple HTTP clients"""
        
    def compare_responses(self, path):
        """Compare responses across different clients"""
        
    def validate_consistency(self, responses):
        """Ensure consistent behavior across clients"""
```

## Enhanced Assertion Requirements (CRITICAL)

### **Strict Validation Functions**
```python
def assert_html_form_response(response, expected_fields):
    """Strict HTML form validation - prevents route conflict issues"""
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    assert "text/html" in response.headers.get("content-type", ""), f"Expected HTML, got {response.headers.get('content-type')}"
    assert "<form" in response.text, "Response should contain a form element"
    assert 'method="post"' in response.text.lower(), "Form should have POST method"
    
    # Validate expected form fields are present
    for field in expected_fields:
        assert f'name="{field}"' in response.text, f"Form should contain field: {field}"
    
    # CRITICAL: Ensure no template errors or route conflicts
    assert "{{" not in response.text, "Response should not contain unrendered template variables"
    assert "parsing" not in response.text.lower(), "Response should not contain parsing errors"
    assert "int_parsing" not in response.text, "Response should not contain integer parsing errors"
    assert '"detail":[{' not in response.text, "Response should not contain JSON error details"

def assert_api_json_response(response, expected_fields=None, expected_status=200):
    """Strict API JSON validation"""  
    assert response.status_code == expected_status, f"Expected {expected_status}, got {response.status_code}"
    assert "application/json" in response.headers.get("content-type", ""), f"Expected JSON, got {response.headers.get('content-type')}"
    
    # Ensure it's valid JSON
    try:
        data = response.json()
    except ValueError as e:
        raise AssertionError(f"Response is not valid JSON: {e}")
    
    # Validate expected fields if provided
    if expected_fields:
        for field in expected_fields:
            assert field in data, f"JSON response should contain field: {field}"
    
    # Ensure no HTML error pages leaked through
    assert "<html" not in response.text.lower(), "API response should not contain HTML"
    assert "<!doctype" not in response.text.lower(), "API response should not contain HTML doctype"

def assert_no_route_conflicts(client, routes_to_test):
    """Validate that specific routes work and don't conflict with parameterized routes"""
    for route in routes_to_test:
        response = client.navigate_to_page(route)
        
        # Should not get parsing errors (indicates route conflict)
        assert response.status_code != 422, f"Route conflict detected for {route}: got 422 instead of 200"
        assert "int_parsing" not in response.text, f"Route {route} has integer parsing conflict"
        assert "unable to parse string as an integer" not in response.text, f"Route {route} has parameterized route conflict"
        
        # Should get proper HTML response for form routes
        if route.endswith('/new'):
            assert_html_form_response(response, ["name"])  # All 'new' routes should have name field

def assert_template_integrity(response, page_name):
    """Validate template renders without errors"""
    assert response.status_code == 200, f"{page_name} should render successfully"
    
    # Check for common template errors
    template_errors = [
        "TemplateSyntaxError",
        "UndefinedError", 
        "{{ ",  # Unrendered variables
        "{% ",  # Unrendered blocks
        "Traceback",
        "Internal Server Error"
    ]
    
    for error in template_errors:
        assert error not in response.text, f"Template error found in {page_name}: {error}"
    
    # Validate basic HTML structure
    assert "<html" in response.text.lower() or "<!doctype" in response.text.lower(), f"{page_name} should have HTML structure"
    assert "</html>" in response.text.lower(), f"{page_name} should have closing HTML tag"
```

## Priority Test Implementation Order (Enhanced)

### **Phase 0: Infrastructure Validation (NEW - MANDATORY FIRST)**
1. **Route Registration Testing** - Verify all routes exist in FastAPI
2. **Route Conflict Detection** - Ensure specific routes beat parameterized routes  
3. **Template Existence** - All referenced templates are on filesystem
4. **Response Format Validation** - HTML vs JSON content-type consistency

### **Phase 1: Foundation Tests with Strict Validation**
1. **Application Connectivity** - Server running, database initialized
2. **Basic Authentication** - Admin/demo login via both session and API
3. **Permission System** - Permission strings and scope validation with strict assertions
4. **User CRUD** - Basic user management operations with content-type validation
5. **Service Account Basics** - Create/read service accounts with form validation

### **Phase 2: Service Token Integration with Route Validation** 
1. **Token Generation** - Create tokens with proper permissions and response validation
2. **Token Authentication** - API access using service tokens with format checking
3. **Permission Inheritance** - Tokens inherit creator permissions with strict validation
4. **Token Expiration** - Expired token handling with proper error responses

### **Phase 3: Advanced Scenarios with Infrastructure Testing**
1. **Complex Workflows** - End-to-end user journeys with cross-client validation
2. **Access Control Edge Cases** - Permission boundary testing with response format validation
3. **UI Integration** - Web interface with permission-based navigation and template integrity
4. **Admin Functionality** - System administration features with route conflict prevention

### **Phase 4: Comprehensive Coverage with Multi-Client Testing**
1. **All CRUD Operations** - Every model via both HTML and API with strict assertions
2. **Error Handling** - Graceful failure scenarios with proper content-type responses
3. **Performance** - Bulk operations and scalability testing
4. **Security** - Authorization bypass attempts with response validation

## Enhanced Success Criteria for 100% Coverage

The generated test suite MUST:

### **Infrastructure Validation (NEW - CRITICAL)**
1. **Route Infrastructure**: 
   - [ ] All routes registered correctly in FastAPI
   - [ ] No route ordering conflicts (specific before parameterized routes)
   - [ ] `/users/new`, `/service-accounts/new`, `/service-tokens/new` return forms, not JSON parsing errors
   - [ ] All parameterized routes work after specific routes

2. **Template Infrastructure**:
   - [ ] All referenced templates exist on filesystem  
   - [ ] All template context variables are defined (no {{ undefined }})
   - [ ] Templates render without Jinja2 errors
   - [ ] Datetime variables properly handled (now, expires_at, etc.)

3. **Response Format Validation**:
   - [ ] HTML endpoints return `text/html` content-type
   - [ ] API endpoints return `application/json` content-type  
   - [ ] Form pages contain proper form elements and fields
   - [ ] No JSON error responses on HTML pages
   - [ ] No HTML error pages on API endpoints

### **Enhanced Business Logic Testing**
4. **Validate complete service account and token workflows** with strict response validation
5. **Test both session-based and token-based authentication** with content-type checking
6. **Verify permission inheritance and scope enforcement** with exact status code validation
7. **Cover all CRUD operations for all 6 core models** with multi-client consistency
8. **Test professional UI functionality and navigation** with template integrity validation
9. **Validate API versioning and consistency** with strict JSON format checking
10. **Handle unique data generation for service accounts and tokens** with conflict prevention
11. **Test admin vs user access control comprehensively** with response format validation
12. **Verify workflow integration between all components** with cross-client testing  

### **Quality Assurance (NEW)**
13. **Cross-Client Consistency**: Same behavior across requests, requests-html, and curl
14. **Error Response Integrity**: All errors return appropriate content-types
15. **Template Error Prevention**: No runtime template rendering failures
16. **Route Conflict Prevention**: All form routes accessible without parsing errors

## Implementation Checklist for Unified App (Enhanced)

### **Phase 0: Infrastructure Validation (NEW - MANDATORY)**
- [ ] **Test route registration completeness** - All expected routes present in FastAPI
- [ ] **Validate route ordering** - Specific routes before parameterized routes
- [ ] **Test route conflict prevention** - `/users/new` vs `/users/{id}` ordering
- [ ] **Template existence validation** - All referenced templates on filesystem
- [ ] **Template context validation** - All template variables defined
- [ ] **Response format consistency** - HTML vs JSON content-type validation

### **Phase 1: Enhanced Foundation Testing**
- [ ] Test database initialization with default users and permissions
- [ ] **Validate admin login works with strict response checking**
- [ ] **Test service account creation with content-type validation**
- [ ] **Verify service token generation with format checking**
- [ ] **Test permission scope enforcement with exact status codes**
- [ ] **Validate Bootstrap UI navigation with template integrity**

### **Phase 2: Multi-Client Validation (NEW)**
- [ ] **Test with requests-html** (test framework behavior)
- [ ] **Test with raw requests** (closer to browser behavior)  
- [ ] **Test with curl subprocess** (exact HTTP behavior)
- [ ] **Compare responses across clients** for consistency
- [ ] **Validate error handling across clients**

### **Phase 3: Gherkin Implementation with Infrastructure Scenarios**
- [ ] Create route conflict validation scenarios
- [ ] Create template integrity validation scenarios
- [ ] Create response format validation scenarios
- [ ] **Create service token authentication helpers with strict validation**
- [ ] **Implement permission inheritance validation with response checking**
- [ ] **Test complex workflows with cross-client consistency**
- [ ] **Validate API consistency with strict JSON format checking**
- [ ] **Test responsive UI with template error prevention**
- [ ] **Include audit trail and timestamp validations**

### **Final Validation (Enhanced)**
- [ ] **All infrastructure tests pass** (routes, templates, response formats)
- [ ] **All manual validation tests pass** with strict assertions
- [ ] **No route conflicts exist** (specific routes work properly)
- [ ] **Template integrity verified** (no undefined variables or errors)
- [ ] **Cross-client consistency confirmed** (same behavior across HTTP clients)
- [ ] **Service account and token management works end-to-end** with response validation
- [ ] **Permission system enforces all access controls** with proper error formats
- [ ] **Professional UI provides complete functionality** without template errors
- [ ] **API documentation matches actual implementation** with content-type consistency
- [ ] **Test suite covers all enhanced success criteria above**

## Critical Testing Lessons Learned (NEW)

### **Route Conflict Prevention**
- **Always test specific routes before parameterized routes**: `/users/new` must be tested before `/users/{id}`
- **Validate route registration order in FastAPI**: Use test to inspect actual route table
- **Test with multiple HTTP clients**: requests-html vs raw requests may behave differently
- **Strict status code validation**: Use `== 200`, not just `!= 500`

### **Response Format Validation**  
- **Content-type headers are critical**: Distinguish HTML forms from JSON errors
- **Template error detection**: Look for `{{ }}` unrendered variables
- **Form validation**: Ensure forms contain expected fields and POST methods
- **API consistency**: JSON endpoints should never return HTML error pages

### **Infrastructure Testing First**
- **Test the framework before business logic**: Route registration, template existence
- **Validate template context variables**: Prevent runtime Jinja2 errors  
- **Cross-client consistency**: Ensure test behavior matches real user experience
- **Error response integrity**: Proper error formats prevent user confusion

This enhanced prompt provides comprehensive testing coverage that would have caught the route ordering conflicts, template context errors, and response format issues encountered in production, ensuring 100% reliable delivery of the Unified Management Application.