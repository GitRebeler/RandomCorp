#!/usr/bin/env python3
"""
Create a simple endpoint test to see if we can add a new endpoint that works
"""

import asyncio
import aiohttp
from datetime import datetime

BASE_URL = "http://104.237.148.210"

async def test_production_environment():
    """Test the production environment to understand what's different"""
    
    async with aiohttp.ClientSession() as session:
        
        # First, get the root API info to see what the production environment thinks it has
        print("🔍 Getting production environment info...")
        
        try:
            async with session.get(f"{BASE_URL}/api/", timeout=aiohttp.ClientTimeout(total=10)) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    print("📊 Production API Info:")
                    print(f"  Version: {data.get('version', 'Unknown')}")
                    print(f"  Status: {data.get('status', 'Unknown')}")
                    print(f"  Debug mode: {data.get('debug_mode', 'Unknown')}")
                    print(f"  Database enabled: {data.get('database_enabled', 'Unknown')}")
                    print(f"  Uptime: {data.get('uptime_seconds', 'Unknown')} seconds")
                    
                    if 'endpoints' in data:
                        print(f"  Reported endpoints:")
                        for name, path in data['endpoints'].items():
                            print(f"    {name}: {path}")
        
        except Exception as e:
            print(f"❌ Failed to get production info: {e}")
        
        # Test if we can check the OpenAPI docs
        print(f"\n🔍 Testing OpenAPI documentation endpoints...")
        
        openapi_endpoints = [
            "/docs",           # Swagger UI
            "/redoc",          # ReDoc
            "/openapi.json",   # OpenAPI schema
        ]
        
        for endpoint in openapi_endpoints:
            try:
                async with session.get(f"{BASE_URL}{endpoint}", timeout=aiohttp.ClientTimeout(total=5)) as response:
                    print(f"  {endpoint:15} -> {response.status}")
                    
                    if endpoint == "/openapi.json" and response.status == 200:
                        # Check the OpenAPI schema to see what endpoints are actually registered
                        schema = await response.json()
                        if 'paths' in schema:
                            print(f"    📋 Paths in OpenAPI schema:")
                            for path in sorted(schema['paths'].keys()):
                                methods = list(schema['paths'][path].keys())
                                print(f"      {path:25} -> {', '.join(methods)}")
                                
            except Exception as e:
                print(f"  {endpoint:15} -> ERROR: {e}")

async def main():
    print("🔍 Testing Production Environment")
    print(f"Base URL: {BASE_URL}")
    print(f"Time: {datetime.now()}")
    print("=" * 80)
    
    await test_production_environment()
    
    print("\n" + "=" * 80)
    print("Next steps:")
    print("1. Check if OpenAPI schema matches what we expect")
    print("2. Compare local vs production environment")
    print("3. Check if there are startup errors in production")

if __name__ == "__main__":
    asyncio.run(main())
