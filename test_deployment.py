#!/usr/bin/env python3
"""
Test the deployment to verify that the endpoints are now working
"""

import asyncio
import aiohttp
from datetime import datetime
import json

BASE_URL = "http://104.237.148.210"

async def test_endpoints_after_deployment():
    """Test all the endpoints that should now be working"""
    
    endpoints_to_test = [
        ("/api/", "Root API endpoint - should work"),
        ("/api/health", "Health check - should work"),
        ("/api/stats", "Stats endpoint - SHOULD NOW WORK"),
        ("/api/submissions", "Submissions endpoint - SHOULD NOW WORK"),
    ]
    
    async with aiohttp.ClientSession() as session:
        print("🧪 Testing endpoints after deployment fix...")
        print()
        
        for endpoint, description in endpoints_to_test:
            try:
                async with session.get(f"{BASE_URL}{endpoint}", 
                                     timeout=aiohttp.ClientTimeout(total=10)) as response:
                    
                    status_icon = "✅" if response.status == 200 else "❌"
                    print(f"{status_icon} {endpoint:20} -> {response.status} ({response.reason})")
                    print(f"   {description}")
                    
                    if response.status == 200:
                        content_type = response.headers.get('content-type', '')
                        if 'application/json' in content_type:
                            try:
                                data = await response.json()
                                
                                # Show specific info for each endpoint
                                if endpoint == "/api/stats":
                                    total_subs = data.get("total_submissions", "Unknown")
                                    status = data.get("status", "Unknown")
                                    print(f"   📊 Total submissions: {total_subs}, Status: {status}")
                                    
                                elif endpoint == "/api/submissions":
                                    submissions = data.get("submissions", [])
                                    total = data.get("total", "Unknown")
                                    print(f"   📋 Returned {len(submissions)} submissions, Total: {total}")
                                    
                                elif endpoint == "/api/":
                                    version = data.get("version", "Unknown")
                                    uptime = data.get("uptime_seconds", "Unknown")
                                    print(f"   🚀 Version: {version}, Uptime: {uptime}s")
                                    
                                    # Show the endpoints listed
                                    if "endpoints" in data:
                                        print(f"   📋 Listed endpoints:")
                                        for name, path in data["endpoints"].items():
                                            print(f"      {name}: {path}")
                                            
                                elif endpoint == "/api/health":
                                    service = data.get("service", "Unknown")
                                    print(f"   💚 Service: {service}")
                                    
                            except Exception as e:
                                print(f"   ❌ JSON parse error: {e}")
                        else:
                            print(f"   📄 Content-Type: {content_type}")
                    else:
                        # Show error response for failed requests
                        try:
                            text = await response.text()
                            if text and len(text) < 200:
                                print(f"   Error: {text}")
                        except:
                            pass
                            
                    print()
                    
            except Exception as e:
                print(f"❌ {endpoint:20} -> ERROR: {str(e)}")
                print(f"   {description}")
                print()

async def test_frontend_integration():
    """Test that the frontend can now load the reporting page properly"""
    
    print("🌐 Testing frontend integration...")
    
    async with aiohttp.ClientSession() as session:
        try:
            # Test if we can access the frontend reporting page
            async with session.get(f"{BASE_URL}/reporting", 
                                 timeout=aiohttp.ClientTimeout(total=10)) as response:
                if response.status == 200:
                    print("✅ Frontend reporting page accessible")
                    
                    # Check if it's HTML content
                    content_type = response.headers.get('content-type', '')
                    if 'text/html' in content_type:
                        text = await response.text()
                        if 'Random Corp' in text:
                            print("✅ Frontend React app is serving correctly")
                        else:
                            print("⚠️  Frontend may not be the expected React app")
                    else:
                        print(f"⚠️  Unexpected content type: {content_type}")
                else:
                    print(f"❌ Frontend reporting page: {response.status}")
                    
        except Exception as e:
            print(f"❌ Frontend test error: {e}")

async def main():
    print("🔍 Testing RandomCorp Deployment After Fix")
    print(f"Base URL: {BASE_URL}")
    print(f"Time: {datetime.now()}")
    print("=" * 80)
    
    await test_endpoints_after_deployment()
    await test_frontend_integration()
    
    print("=" * 80)
    print("🎯 Summary:")
    print("- If /api/stats and /api/submissions now return 200 OK, the fix is successful!")
    print("- The ingress rewrite rule now matches the FastAPI endpoint definitions")
    print("- Frontend should be able to load the reporting page without 404 errors")

if __name__ == "__main__":
    asyncio.run(main())
