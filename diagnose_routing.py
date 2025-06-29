#!/usr/bin/env python3
"""
Test to see if the issue is with the endpoints or with the ingress routing
"""

import asyncio
import aiohttp
from datetime import datetime

BASE_URL = "http://104.237.148.210"

async def test_direct_vs_routed():
    """Compare what works vs what doesn't to identify the issue"""
    
    async with aiohttp.ClientSession() as session:
        
        print("Testing patterns to identify the routing issue:")
        print()
        
        # Test patterns that work
        working_endpoints = [
            "/api/",           # Works - returns JSON
            "/api/health",     # Works - returns JSON  
        ]
        
        # Test patterns that don't work
        broken_endpoints = [
            "/api/stats",      # Broken - returns 404
            "/api/submissions", # Broken - returns 404
            "/api/submit",     # Broken - returns 404
        ]
        
        print("✅ Working endpoints:")
        for endpoint in working_endpoints:
            try:
                async with session.get(f"{BASE_URL}{endpoint}", timeout=aiohttp.ClientTimeout(total=5)) as response:
                    content_type = response.headers.get('content-type', '')
                    print(f"  {endpoint:20} -> {response.status} ({content_type})")
                    
                    if response.status == 200 and 'application/json' in content_type:
                        data = await response.json()
                        print(f"                       Keys: {list(data.keys())}")
            except Exception as e:
                print(f"  {endpoint:20} -> ERROR: {e}")
        
        print("\n❌ Broken endpoints:")
        for endpoint in broken_endpoints:
            try:
                async with session.get(f"{BASE_URL}{endpoint}", timeout=aiohttp.ClientTimeout(total=5)) as response:
                    content_type = response.headers.get('content-type', '')
                    print(f"  {endpoint:20} -> {response.status} ({content_type})")
                    
                    if response.status != 200:
                        text = await response.text()
                        if len(text) < 200:
                            print(f"                       Response: {text}")
            except Exception as e:
                print(f"  {endpoint:20} -> ERROR: {e}")
        
        print("\n🔍 Additional diagnostic tests:")
        
        # Test with different HTTP methods
        test_endpoints = ["/api/stats", "/api/submissions"]
        for endpoint in test_endpoints:
            print(f"\n  Testing {endpoint} with different methods:")
            
            # GET (already tested above)
            try:
                async with session.get(f"{BASE_URL}{endpoint}") as response:
                    print(f"    GET  -> {response.status}")
            except:
                print(f"    GET  -> ERROR")
            
            # OPTIONS (for CORS preflight)
            try:
                async with session.options(f"{BASE_URL}{endpoint}") as response:
                    print(f"    OPTIONS -> {response.status}")
            except:
                print(f"    OPTIONS -> ERROR")
        
        # Test if there are any response headers that give us clues
        print(f"\n📋 Response headers for /api/stats:")
        try:
            async with session.get(f"{BASE_URL}/api/stats") as response:
                for header, value in response.headers.items():
                    if header.lower() in ['server', 'x-powered-by', 'x-fastapi-version', 'x-process-time']:
                        print(f"    {header}: {value}")
        except Exception as e:
            print(f"    Error getting headers: {e}")

async def main():
    print("🔍 Diagnosing API Endpoint Routing Issue")
    print(f"Base URL: {BASE_URL}")
    print(f"Time: {datetime.now()}")
    print("=" * 80)
    
    await test_direct_vs_routed()
    
    print("\n" + "=" * 80)
    print("Summary:")
    print("- /api/ and /api/health work (return JSON from FastAPI)")
    print("- /api/stats and /api/submissions return 404")
    print("- This suggests the FastAPI app is running but missing some endpoints")
    print("- Possible causes: startup errors, import issues, or conditional registration")

if __name__ == "__main__":
    asyncio.run(main())
