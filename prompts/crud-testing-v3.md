# FastAPI CRUD Application - Enhanced Gherkin Test Generation Prompt (v3)

Generate comprehensive Gherkin feature tests for a FastAPI CRUD application using Python's `requests-html` library. This version incorporates **schema discovery** to test all models found in migration files, aligning with the v7 implementation prompt approach.

## Application Overview

This is a complete FastAPI MVC CRUD application with:

### **Schema Discovery & Dynamic Model Support**
- **Migration-based models**: All models are discovered from `migrations/` directory schema definitions
- **Core authentication models**: users, roles, permissions, sessions (always present)
- **Additional business models**: Dynamically identified from migration files (may include complex multi-table structures)
- **Complete CRUD interfaces**: All discovered models have full API and HTML interfaces

### **Authentication & Authorization**
- **Session-based authentication** (cookies, not JWT)
- **Role-based access control** with permission format: `model:action:scope`
  - `scope` can be: `all` (admin), `own` (user's records), `group` (group records)
- **Public registration** (assigns default "user" role)
- **Admin interface** for system management

### **Default Accounts**
- **Admin**: `admin/admin123` (full system access)
- **Demo**: `demo/demo123` (basic user permissions)

### **Interfaces**
- **JSON API**: `/api/v1/` endpoints for programmatic access
- **HTML Web Interface**: `/` for browser-based interaction with forms and navigation

### **Key URLs**
- **Authentication**: `/login`, `/register`, `/logout`
- **API Docs**: `/api/v1/docs`
- **Core Models**: `/users`, `/roles`, `/permissions`, `/sessions`
- **Discovered Models**: `/[model_name]` (dynamically determined from migrations)

## ⚡ Implementation Strategy (CRITICAL - READ FIRST)

### **Phase 0: Schema Discovery and Model Identification**
**NEW**: Before creating any tests, perform schema discovery:

1. **Analyze migrations directory** (`migrations/`) to identify all tables and models
2. **Document discovered models** with their fields, relationships, and constraints  
3. **Map model permissions** based on discovered schema (determine which models need admin vs user permissions)
4. **Create model registry** for dynamic test generation

### **Phase 1: Create Test Infrastructure Before Gherkin**
**IMPORTANT**: Start with manual validation tests using standard pytest, then build Gherkin tests on top.

1. **Create basic pytest validation suite first** (`test_manual_validation.py`)
   - Test app connectivity and basic functionality
   - Validate authentication flows work
   - Test CRUD operations for CORE models without Gherkin complexity
   - Test at least one DISCOVERED model to validate schema integration
   - This ensures the application works before testing framework issues

2. **Build test utilities independently**
   - RequestsHTML wrapper with session management
   - Data generation utilities (using Faker) for ALL discovered models
   - Assertion helpers for common validations
   - **Model registry utilities** for dynamic test data generation

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

#### **Schema Discovery Integration**
- **Migration parsing**: Tests must read migration files to identify all models
- **Dynamic model testing**: Generate test scenarios for each discovered model
- **Permission mapping**: Determine appropriate permissions for each model type
- **Relationship testing**: Test foreign key relationships discovered in migrations

#### **Authentication Endpoint Expectations**
- **Login**: `POST /api/v1/auth/login` returns 200 with session cookie
- **Me endpoint**: `GET /api/v1/auth/me` should return user data WITH permissions array
- **Permission format**: Use `permission_string` field (not `name`) in API responses
- **User creation**: May return 200 instead of 201 - check actual implementation

#### **Permission System Details**
- **Admin detection**: Simple username check (`username == "admin"`) may be used
- **Permission enforcement**: Regular users should get 403 for admin endpoints
- **Permission format**: Permissions follow `model:action:scope` pattern
- **Dynamic permissions**: All discovered models need corresponding permissions
- **Field names**: API responses use `permission_string` field, not `name`

#### **Data Management Strategies**
- **Unique test data**: Generate unique data with timestamps for ALL models to avoid conflicts
- **Existing data**: Handle cases where test data already exists from previous runs
- **Default data**: Application should initialize with admin/demo users automatically
- **Model-specific data**: Generate appropriate test data for each discovered model's schema

## Test Structure Requirements

### **Recommended File Structure**
```
tests/
├── requirements.txt            # Test dependencies
├── conftest.py                # Pytest fixtures (with explicit imports)
├── test_manual_validation.py  # NON-GHERKIN validation tests (CREATE FIRST)
├── test_authentication.py     # Gherkin scenario imports
├── test_discovered_models.py  # Dynamic tests for migration-discovered models
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
│   ├── dynamic_model_steps.py # Steps for discovered models
│   └── api_steps.py           # API-specific steps
├── features/                  # Gherkin feature files
│   ├── authentication.feature
│   ├── user_management.feature
│   ├── role_management.feature
│   ├── permission_management.feature
│   ├── session_management.feature
│   ├── api_authentication.feature
│   ├── api_crud_operations.feature
│   ├── access_control.feature
│   └── discovered_models/     # Dynamic feature files for each discovered model
│       ├── [model_name]_crud.feature
│       └── [model_name]_permissions.feature
├── utils/
│   ├── __init__.py
│   ├── test_client.py         # RequestsHTML wrapper
│   ├── data_helpers.py        # Test data generation for ALL models
│   ├── schema_discovery.py    # Migration parsing utilities
│   ├── model_registry.py      # Dynamic model management
│   └── assertions.py          # Custom assertion helpers
```

### **Critical Implementation Details**

#### **Schema Discovery Utilities**
```python
# utils/schema_discovery.py
def discover_models_from_migrations(migrations_path):
    """Parse migration files to identify all models and their schemas"""
    
def get_model_fields(model_name):
    """Return field definitions for a discovered model"""
    
def get_model_relationships(model_name):
    """Return relationship definitions for a discovered model"""
    
def determine_model_permissions(model_name):
    """Determine appropriate permission levels for a model"""
```

#### **Dynamic Model Testing**
```python
# utils/model_registry.py
class ModelRegistry:
    def __init__(self, migrations_path):
        self.models = discover_models_from_migrations(migrations_path)
        
    def get_test_data_for_model(self, model_name):
        """Generate appropriate test data for any discovered model"""
        
    def get_required_permissions(self, model_name, action):
        """Return required permissions for model actions"""
```

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
import step_definitions.dynamic_model_steps
import step_definitions.api_steps

# Generate tests from feature file
scenarios('features/authentication.feature')
```

### **Test Client Implementation Requirements**

#### **RequestsHTML Wrapper Must Handle**
```python
class TestClient:
    def __init__(self, base_url, model_registry):
        self.session = HTMLSession()
        self.base_url = base_url
        self.current_user = None
        self.model_registry = model_registry  # NEW: For dynamic model testing
        
    def api_request(self, method, endpoint, json_data=None, params=None):
        """Handle both JSON API and form submissions"""
        
    def login_as(self, username, password):
        """Login and maintain session state"""
        
    def visit_page(self, path):
        """Visit HTML pages and return response"""
        
    def submit_form(self, form_data, action=None):
        """Submit HTML forms with proper encoding"""
        
    def test_model_crud(self, model_name):
        """Dynamic CRUD testing for any discovered model"""
        
    def generate_model_data(self, model_name):
        """Generate test data for any model based on its schema"""
```

### **Coverage Requirements**

#### **Phase 1: Manual Validation Tests (PRIORITY)**
Create these tests FIRST as standard pytest functions:

```python
def test_app_is_running(client):
    """Verify FastAPI is accessible"""
    
def test_migration_schema_discovered(client):
    """Verify migration files were parsed and models identified"""
    
def test_admin_login_works(client):
    """Verify admin authentication and permissions"""
    
def test_demo_login_works(client):
    """Verify regular user authentication"""
    
def test_core_model_crud_operations(client):
    """Test create/read/update/delete for core models (users, roles, etc.)"""
    
def test_discovered_model_crud_operations(client):
    """Test CRUD for at least one model discovered from migrations"""
    
def test_permission_system_works(client):
    """Verify permission endpoint and format for all models"""
    
def test_discovered_model_permissions(client):
    """Verify permissions work for migration-discovered models"""
    
def test_navigation_includes_all_models(client):
    """Verify navigation menu includes links for all discovered models"""
```

#### **Phase 2: Gherkin Feature Coverage**
Only after Phase 1 passes, implement:

**Core Features (always present):**
- **Authentication Features**: Login/logout/registration flows
- **User Management**: CRUD operations with role assignments
- **Role Management**: Role CRUD with permission assignments  
- **Permission Management**: Permission CRUD and usage tracking for ALL models
- **Session Management**: Session viewing and revocation
- **API Authentication**: REST API authentication flows
- **Access Control**: Permission enforcement testing across ALL models

**Dynamic Features (based on migration discovery):**
- **[Model Name] CRUD Operations**: For each discovered model
- **[Model Name] Permission Testing**: Access control for each model
- **[Model Name] Relationship Testing**: Foreign key and relationship validation
- **[Model Name] API Operations**: JSON API testing for each model

## Dynamic Test Generation Requirements

### **Migration File Analysis**
The test suite must:

1. **Parse all migration files** in the `migrations/` directory
2. **Extract table definitions** including columns, constraints, and relationships
3. **Identify model types** (core auth models vs business models)
4. **Generate appropriate test scenarios** for each discovered model
5. **Create permission mappings** for each model (admin-only vs user-accessible)

### **Dynamic Feature File Generation**
```python
def generate_feature_files_for_discovered_models(models, output_dir):
    """Generate Gherkin feature files for each discovered model"""
    for model_name, schema in models.items():
        if model_name not in ['users', 'roles', 'permissions', 'sessions']:
            generate_crud_feature(model_name, schema, output_dir)
            generate_permission_feature(model_name, schema, output_dir)
```

### **Dynamic Step Definition Generation**
```python
def generate_step_definitions_for_model(model_name, schema):
    """Generate step definitions for any discovered model"""
    # Generate steps for CRUD operations
    # Generate steps for permission testing
    # Generate steps for relationship validation
```

## Error Prevention Strategies

### **Common Implementation Pitfalls**

#### **Schema Discovery Issues**
- ❌ **Don't**: Assume specific models exist (like "certificates" or "dns_records")
- ✅ **Do**: Dynamically discover all models from migration files
- ❌ **Don't**: Hardcode model names in test scenarios
- ✅ **Do**: Generate test scenarios based on discovered schema
- ❌ **Don't**: Assume simple table structures
- ✅ **Do**: Handle complex relationships and constraints found in migrations

#### **Import Issues**
- ❌ **Don't**: Use absolute imports like `from tests.utils import`
- ✅ **Do**: Use relative imports and sys.path manipulation
- ❌ **Don't**: Assume pytest-bdd will auto-discover step definitions
- ✅ **Do**: Import step definition modules explicitly

#### **Data Conflicts**
- ❌ **Don't**: Use hardcoded data that may conflict with existing records
- ✅ **Do**: Generate unique data with timestamps for ALL discovered models
- ❌ **Don't**: Assume fresh database for each test
- ✅ **Do**: Handle existing data gracefully across all models

#### **Response Expectations**  
- ❌ **Don't**: Assume standard HTTP status codes for all models
- ✅ **Do**: Validate actual responses for each discovered model
- ❌ **Don't**: Assume consistent field names across all models
- ✅ **Do**: Adapt to actual schema structure from migrations

## Validation and Debugging Strategy

### **Incremental Testing Approach**
1. **Migration file parsing**: Can we read and parse all migration files?
2. **Model discovery**: Are all models properly identified and catalogued?
3. **Application connectivity**: Can we reach the FastAPI server?
4. **Authentication basics**: Do login endpoints work?
5. **Core model CRUD**: Do basic user/role operations work?
6. **Discovered model CRUD**: Does at least one migration-discovered model work?
7. **Permission system**: Are permissions correct for all models?
8. **Dynamic test generation**: Do generated tests execute properly?

### **Debug Utilities to Include**
```python
def debug_discovered_models(model_registry):
    """Print all discovered models and their schemas"""
    
def debug_model_permissions(model_name, user_type):
    """Print expected vs actual permissions for a model"""
    
def debug_migration_parsing(migrations_path):
    """Validate migration file parsing results"""
```

## Success Criteria

The generated test suite should:

1. **Successfully discover all models** from migration files
2. **Generate appropriate test scenarios** for each discovered model  
3. **Phase 1 validation tests pass** before Gherkin implementation
4. **Handle dynamic model testing** without hardcoded assumptions
5. **Work with actual migration-defined schemas** (not assumed ones)
6. **Provide clear error messages** when discovery or tests fail
7. **Execute efficiently** without browser overhead
8. **Support incremental development** (test pieces work independently)
9. **Include debugging utilities** for troubleshooting schema discovery
10. **Document discovered models** and their test coverage

## Implementation Checklist

### **Before Starting Test Implementation**
- [ ] Parse `migrations/` directory and identify all models
- [ ] Create model registry with schema definitions
- [ ] Map permissions for each discovered model
- [ ] Create `test_manual_validation.py` with schema discovery validation
- [ ] Test at least one discovered model manually before Gherkin

### **During Test Implementation**
- [ ] Generate dynamic test data for all discovered models
- [ ] Create step definitions that work with any model
- [ ] Test core authentication models first
- [ ] Add discovered model testing incrementally
- [ ] Validate permission enforcement for all models

### **Final Validation**
- [ ] All discovered models have CRUD test coverage
- [ ] Permission system works for all models
- [ ] Dynamic test generation executes successfully  
- [ ] Navigation menu includes all discovered models
- [ ] API endpoints work for all models
- [ ] Documentation includes discovered model coverage

## Key Improvements in Version 3:

- **Schema Discovery Integration**: Aligns with v7 implementation prompt's migration-based approach
- **Dynamic Model Testing**: Automatically tests all models found in migrations
- **Flexible Architecture**: Adapts to any schema without hardcoded assumptions  
- **Migration File Analysis**: Parses actual database schema definitions
- **Enhanced Coverage**: Ensures all discovered models are fully tested
- **Scalable Approach**: Works with simple or complex multi-table structures

This enhanced prompt ensures comprehensive testing of all models discovered through schema analysis, providing complete coverage regardless of the actual database structure found in the migration files.