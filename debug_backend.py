#!/usr/bin/env python3
"""
Test the backend API directly to understand endpoint structure
"""

import asyncio
import aiohttp
from datetime import datetime

BASE_URL = "http://104.237.148.210"

async def test_backend_endpoints():
    """Test various endpoint patterns"""
    
    # The ingress rewrites /api/stats to /stats, so let's test what the backend actually expects
    endpoints_to_test = [
        # What the ingress should forward to (after rewrite)
        "/api/stats",      # Original frontend call
        "/api/submissions", # Original frontend call
        "/api/health",     # This one works
        "/api/",           # Root API
        
        # Test if backend expects these after rewrite:
        "/stats",          # After rewrite from /api/stats  
        "/submissions",    # After rewrite from /api/submissions
        "/health",         # After rewrite from /api/health
        "/",               # After rewrite from /api/
    ]
    
    async with aiohttp.ClientSession() as session:
        print("Testing endpoints that might exist on the backend:")
        for endpoint in endpoints_to_test:
            try:
                async with session.get(f"{BASE_URL}{endpoint}", timeout=aiohttp.ClientTimeout(total=10)) as response:
                    content_type = response.headers.get('content-type', '')
                    
                    if response.status == 200:
                        print(f"✅ {endpoint:20} -> {response.status} ({content_type})")
                        
                        if 'application/json' in content_type:
                            try:
                                data = await response.json()
                                # Print some info about the response
                                if isinstance(data, dict):
                                    if "total_submissions" in data:
                                        print(f"   📊 Stats: {data.get('total_submissions')} submissions")
                                    elif "submissions" in data:
                                        print(f"   📋 {len(data.get('submissions', []))} submissions, total: {data.get('total', 'N/A')}")
                                    elif "message" in data:
                                        print(f"   💬 {data.get('message')}")
                                    else:
                                        print(f"   📄 Keys: {list(data.keys())[:5]}")
                            except Exception as e:
                                print(f"   ❌ JSON parse error: {e}")
                        else:
                            text = await response.text()
                            if len(text) < 100:
                                print(f"   📄 Text: {text}")
                            else:
                                print(f"   📄 HTML content ({len(text)} chars)")
                    else:
                        print(f"❌ {endpoint:20} -> {response.status} ({response.reason})")
                        
            except Exception as e:
                print(f"❌ {endpoint:20} -> ERROR: {str(e)}")

async def main():
    print("🔍 Testing Backend API Endpoints")
    print(f"Base URL: {BASE_URL}")
    print(f"Time: {datetime.now()}")
    print("=" * 80)
    
    await test_backend_endpoints()
    
    print("=" * 80)
    print("Analysis:")
    print("- If /api/health works but /api/stats doesn't, there's a routing issue")
    print("- The ingress rewrite rule might be incorrectly configured")
    print("- We need to check if backend endpoints exist at the rewritten paths")

if __name__ == "__main__":
    asyncio.run(main())
