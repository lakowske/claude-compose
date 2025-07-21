# FastAPI CRUD Application - Enhanced Gherkin Test Generation Prompt (v2)

Generate comprehensive Gherkin feature tests for a FastAPI CRUD application using Python's `requests-html` library. This prompt incorporates lessons learned from practical implementation to ensure smoother test suite creation.

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

## ⚡ Implementation Strategy (CRITICAL - READ FIRST)

### **Phase 1: Create Test Infrastructure Before Gherkin**
**IMPORTANT**: Start with manual validation tests using standard pytest, then build Gherkin tests on top.

1. **Create basic pytest validation suite first** (`test_manual_validation.py`)
   - Test app connectivity and basic functionality
   - Validate authentication flows work
   - Test CRUD operations without Gherkin complexity
   - This ensures the application works before testing framework issues

2. **Build test utilities independently**
   - RequestsHTML wrapper with session management
   - Data generation utilities (using Faker)
   - Assertion helpers for common validations

3. **Add Gherkin layer after validation passes**
   - Import all step definitions explicitly
   - Handle pytest-bdd discovery issues
   - Test individual scenarios before full suite

### **Import and Dependency Management (CRITICAL)**

#### **Known Issues to Avoid**
- **lxml dependency**: Include `lxml_html_clean` in requirements
- **Import paths**: Use relative imports in step definitions (`from .common import`)
- **Module discovery**: Import step definition modules explicitly in test files
- **pytest-bdd registration**: Create explicit test files that import scenarios

#### **Recommended Requirements**
```python
# requirements-test.txt
pytest>=7.4.0
pytest-bdd>=8.0.0
requests-html>=0.10.0
faker>=21.0.0
pydantic>=2.0.0
pytest-asyncio>=0.21.0
lxml_html_clean>=0.4.0  # CRITICAL - prevents lxml.html.clean import errors
```

## Testing Requirements

### **Technology Stack**
- **Language**: Python 3.11+
- **HTTP Library**: `requests-html` (NOT Selenium/Playwright)
- **Test Framework**: `pytest` with Gherkin using `pytest-bdd`
- **Assertion Library**: Python `assert` statements
- **Session Management**: Handle cookies and authentication states

### **Application-Specific Implementation Notes**

#### **Authentication Endpoint Expectations**
- **Login**: `POST /api/v1/auth/login` returns 200 with session cookie
- **Me endpoint**: `GET /api/v1/auth/me` should return user data WITH permissions array
- **Permission format**: Use `permission_string` field (not `name`) in API responses
- **User creation**: May return 200 instead of 201 - check actual implementation

#### **Permission System Details**
- **Admin detection**: Simple username check (`username == "admin"`) may be used
- **Permission enforcement**: Regular users should get 403 for admin endpoints
- **Permission format**: Permissions follow `model:action:scope` pattern
- **Field names**: API responses use `permission_string` field, not `name`

#### **Data Management Strategies**
- **Unique test data**: Generate unique usernames with timestamps to avoid conflicts
- **Existing data**: Handle cases where test users already exist from previous runs
- **Default data**: Application should initialize with admin/demo users automatically

## Test Structure Requirements

### **Recommended File Structure**
```
tests/
├── requirements.txt            # Test dependencies
├── conftest.py                # Pytest fixtures (with explicit imports)
├── test_manual_validation.py  # NON-GHERKIN validation tests (CREATE FIRST)
├── test_authentication.py     # Gherkin scenario imports
├── pytest.ini                # Pytest configuration
├── run_tests.py               # Test runner with validation
├── step_definitions/
│   ├── __init__.py
│   ├── common.py              # Shared steps (import path fixes)
│   ├── authentication.py     # Auth steps
│   ├── user_management.py     # User CRUD steps
│   ├── role_management.py     # Role CRUD steps
│   ├── permission_management.py
│   ├── session_management.py
│   └── api_steps.py           # API-specific steps
├── features/                  # Gherkin feature files
├── utils/
│   ├── __init__.py
│   ├── test_client.py         # RequestsHTML wrapper
│   ├── data_helpers.py        # Test data generation
│   └── assertions.py          # Custom assertion helpers
```

### **Critical Implementation Details**

#### **Pytest Configuration (pytest.ini)**
```ini
[tool:pytest]
testpaths = features
addopts = -v --tb=short
python_files = test_*.py
python_classes = Test*
python_functions = test_*
```

#### **Step Definition Import Pattern**
```python
# In test_authentication.py - EXPLICIT IMPORTS REQUIRED
from pytest_bdd import scenarios

# Import ALL step definitions to ensure registration
import step_definitions.common
import step_definitions.authentication
import step_definitions.user_management
import step_definitions.role_management
import step_definitions.permission_management
import step_definitions.session_management
import step_definitions.api_steps

# Generate tests from feature file
scenarios('features/authentication.feature')
```

#### **Import Fixes for Step Definitions**
```python
# In each step definition file
from pytest_bdd import given, when, then, parsers
import sys
import os

# Add parent directory to path to import utils
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from utils.assertions import *
from .common import test_context  # Relative import for common steps
```

### **Test Client Implementation Requirements**

#### **RequestsHTML Wrapper Must Handle**
```python
class TestClient:
    def __init__(self, base_url):
        self.session = HTMLSession()
        self.base_url = base_url
        self.current_user = None
        
    def api_request(self, method, endpoint, json_data=None, params=None):
        """Handle both JSON API and form submissions"""
        
    def login_as(self, username, password):
        """Login and maintain session state"""
        
    def visit_page(self, path):
        """Visit HTML pages and return response"""
        
    def submit_form(self, form_data, action=None):
        """Submit HTML forms with proper encoding"""
```

### **Coverage Requirements**

#### **Phase 1: Manual Validation Tests (PRIORITY)**
Create these tests FIRST as standard pytest functions:

```python
def test_app_is_running(client):
    """Verify FastAPI is accessible"""
    
def test_admin_login_works(client):
    """Verify admin authentication and permissions"""
    
def test_demo_login_works(client):
    """Verify regular user authentication"""
    
def test_user_crud_operations(client):
    """Test create/read/update/delete for users"""
    
def test_permission_system_works(client):
    """Verify permission endpoint and format"""
    
def test_regular_user_permissions(client):
    """Verify access control enforcement"""
```

#### **Phase 2: Gherkin Feature Coverage**
Only after Phase 1 passes, implement:

- **Authentication Features**: Login/logout/registration flows
- **User Management**: CRUD operations with role assignments
- **Role Management**: Role CRUD with permission assignments  
- **Permission Management**: Permission CRUD and usage tracking
- **Session Management**: Session viewing and revocation
- **API Authentication**: REST API authentication flows
- **API CRUD Operations**: All resources via JSON API
- **Access Control**: Permission enforcement testing

## Error Prevention Strategies

### **Common Implementation Pitfalls**

#### **Import Issues**
- ❌ **Don't**: Use absolute imports like `from tests.utils import`
- ✅ **Do**: Use relative imports and sys.path manipulation
- ❌ **Don't**: Assume pytest-bdd will auto-discover step definitions
- ✅ **Do**: Import step definition modules explicitly

#### **Data Conflicts**
- ❌ **Don't**: Use hardcoded usernames that may already exist
- ✅ **Do**: Generate unique names with timestamps: `f"testuser_{int(time.time())}"`
- ❌ **Don't**: Assume fresh database for each test
- ✅ **Do**: Handle existing data gracefully

#### **Response Expectations**  
- ❌ **Don't**: Assume standard HTTP status codes (201 for creation)
- ✅ **Do**: Check actual application responses first
- ❌ **Don't**: Assume permission field names (`name` vs `permission_string`)
- ✅ **Do**: Inspect actual API response structure

#### **Authentication State**
- ❌ **Don't**: Assume session persistence across test clients
- ✅ **Do**: Explicitly manage authentication state in test context
- ❌ **Don't**: Test complex scenarios before simple login works
- ✅ **Do**: Validate basic auth flows before advanced features

## Validation and Debugging Strategy

### **Incremental Testing Approach**
1. **Application connectivity**: Can we reach the FastAPI server?
2. **Authentication basics**: Do login endpoints work?
3. **Session management**: Do cookies persist across requests?
4. **Permission system**: Are permissions returned correctly?
5. **CRUD operations**: Do create/read/update/delete work?
6. **Access control**: Are admin endpoints properly protected?
7. **Gherkin integration**: Do step definitions register correctly?

### **Debug Utilities to Include**
```python
def debug_response(response, context=""):
    """Print response details for debugging"""
    print(f"{context} - Status: {response.status_code}")
    print(f"Headers: {dict(response.headers)}")
    if response.headers.get('content-type', '').startswith('application/json'):
        print(f"JSON: {response.json()}")
    else:
        print(f"Text: {response.text[:200]}...")
```

### **Test Runner with Validation**
Create a test runner that:
- Validates test infrastructure exists
- Checks dependencies are installed
- Provides clear instructions for running tests
- Shows test statistics and coverage

## Success Criteria

The generated test suite should:

1. **Phase 1 validation tests pass** before Gherkin implementation
2. **Handle import/dependency issues** automatically
3. **Work with actual application responses** (not assumed ones)
4. **Provide clear error messages** when tests fail
5. **Execute efficiently** without browser overhead
6. **Support incremental development** (test pieces work independently)
7. **Include debugging utilities** for troubleshooting
8. **Document known issues** and their solutions

## Implementation Checklist

### **Before Starting Gherkin Implementation**
- [ ] Create `test_manual_validation.py` with basic connectivity tests
- [ ] Implement RequestsHTML wrapper with session management
- [ ] Test admin login and verify permission response format
- [ ] Test regular user login and access control
- [ ] Verify CRUD operations work with actual status codes
- [ ] Validate test data generation and cleanup

### **During Gherkin Implementation**
- [ ] Use relative imports in step definitions
- [ ] Import step definition modules explicitly in test files
- [ ] Handle existing test data conflicts
- [ ] Test individual scenarios before full feature files
- [ ] Include debugging output for failed steps
- [ ] Validate step definition registration

### **Final Validation**
- [ ] All manual validation tests pass
- [ ] At least one Gherkin scenario executes successfully
- [ ] Test runner provides clear status and instructions
- [ ] Documentation includes troubleshooting section
- [ ] Dependencies are clearly specified with versions

This enhanced prompt addresses the real-world implementation challenges encountered and provides a much more practical approach to creating a robust test suite for FastAPI CRUD applications.