#!/usr/bin/env python3
"""
Test the FastAPI app locally to see if endpoints are properly registered
"""

import sys
import os

# Add the api directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'api'))

def test_fastapi_app():
    """Test the FastAPI app locally to see registered endpoints"""
    
    try:
        # Import the FastAPI app
        from main import app
        
        print("✅ FastAPI app imported successfully")
        print(f"App title: {app.title}")
        print(f"App version: {app.version}")
        
        # List all registered routes
        print("\n📋 Registered routes:")
        for route in app.routes:
            if hasattr(route, 'path') and hasattr(route, 'methods'):
                methods = getattr(route, 'methods', set())
                print(f"  {route.path:30} -> {', '.join(methods)}")
            elif hasattr(route, 'path'):
                print(f"  {route.path:30} -> (no methods)")
        
        # Specifically check for our problematic endpoints
        problematic_endpoints = ["/api/stats", "/api/submissions", "/api/submit"]
        
        print(f"\n🔍 Checking for problematic endpoints:")
        for endpoint in problematic_endpoints:
            found = False
            for route in app.routes:
                if hasattr(route, 'path') and route.path == endpoint:
                    found = True
                    methods = getattr(route, 'methods', set())
                    print(f"  ✅ {endpoint} found with methods: {', '.join(methods)}")
                    break
            if not found:
                print(f"  ❌ {endpoint} NOT FOUND")
        
        return True
        
    except ImportError as e:
        print(f"❌ Failed to import FastAPI app: {e}")
        return False
    except Exception as e:
        print(f"❌ Error testing FastAPI app: {e}")
        return False

def test_database_connection():
    """Test if database connection issues might affect endpoint registration"""
    
    try:
        from database import get_db_manager
        
        print("\n🔍 Testing database connection...")
        
        # Check environment variables
        db_host = os.getenv('DB_HOST')
        print(f"DB_HOST: {db_host}")
        
        if not db_host:
            print("⚠️  No DB_HOST set - app should run in demo mode")
        
        # Try to create database manager
        db_manager = get_db_manager()
        print(f"✅ Database manager created: {type(db_manager)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Database test failed: {e}")
        return False

def main():
    print("🔍 Testing FastAPI App Registration")
    print("=" * 60)
    
    # Test the FastAPI app
    app_ok = test_fastapi_app()
    
    # Test database connection
    db_ok = test_database_connection()
    
    print("\n" + "=" * 60)
    print("Summary:")
    if app_ok:
        print("✅ FastAPI app loads successfully")
    else:
        print("❌ FastAPI app has issues")
        
    if db_ok:
        print("✅ Database module loads successfully")
    else:
        print("❌ Database module has issues")

if __name__ == "__main__":
    main()
