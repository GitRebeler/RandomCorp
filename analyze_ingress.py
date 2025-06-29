#!/usr/bin/env python3
"""
Test the ingress routing in detail to understand the issue
"""

import asyncio
import aiohttp
from datetime import datetime

BASE_URL = "http://104.237.148.210"

async def test_routing_patterns():
    """Test specific routing patterns to understand ingress behavior"""
    
    async with aiohttp.ClientSession() as session:
        
        print("🔍 Testing routing patterns in detail...")
        
        # Test endpoints that work vs don't work
        test_cases = [
            # Working endpoints
            ("/api/", "Should work - returns JSON"),
            ("/api/health", "Should work - returns JSON"),
            
            # Broken endpoints  
            ("/api/stats", "Should work but returns 404"),
            ("/api/submissions", "Should work but returns 404"),
            ("/api/submit", "Should work but returns 404"),
            
            # OpenAPI endpoints
            ("/docs", "FastAPI docs - should show backend"),
            ("/redoc", "FastAPI redoc - should show backend"),
            ("/openapi.json", "Should return JSON schema"),
            
            # Test with trailing slashes
            ("/api/stats/", "Test with trailing slash"),
            ("/api/submissions/", "Test with trailing slash"),
            
            # Test frontend routes
            ("/", "Frontend root"),
            ("/reporting", "Frontend reporting page"),
        ]
        
        for endpoint, description in test_cases:
            try:
                async with session.get(f"{BASE_URL}{endpoint}", 
                                     timeout=aiohttp.ClientTimeout(total=5),
                                     headers={'Accept': 'application/json'}) as response:
                    
                    content_type = response.headers.get('content-type', '')
                    server = response.headers.get('server', 'unknown')
                    x_process_time = response.headers.get('x-process-time', None)
                    
                    print(f"\n📍 {endpoint}")
                    print(f"   {description}")
                    print(f"   Status: {response.status}")
                    print(f"   Content-Type: {content_type}")
                    print(f"   Server: {server}")
                    
                    if x_process_time:
                        print(f"   X-Process-Time: {x_process_time} (FastAPI)")
                    else:
                        print(f"   X-Process-Time: None (Not FastAPI)")
                    
                    # Check if it's JSON or HTML
                    if 'application/json' in content_type:
                        try:
                            data = await response.json()
                            if isinstance(data, dict) and len(data) < 10:
                                print(f"   JSON Keys: {list(data.keys())}")
                            else:
                                print(f"   JSON Response (large)")
                        except:
                            print(f"   JSON Parse Error")
                    elif 'text/html' in content_type:
                        text = await response.text()
                        if 'Random Corp' in text:
                            print(f"   HTML: Frontend React App")
                        else:
                            print(f"   HTML: Other ({len(text)} chars)")
                    else:
                        print(f"   Other content type")
                        
            except Exception as e:
                print(f"\n📍 {endpoint}")
                print(f"   ERROR: {e}")

async def test_ingress_rewrite():
    """Test to understand the ingress rewrite behavior"""
    
    print(f"\n🔧 Testing ingress rewrite behavior...")
    print("The ingress config has: nginx.ingress.kubernetes.io/rewrite-target: /$2")
    print("With path pattern: /api(/|$)(.*)")
    print()
    
    # This means:
    # /api/stats -> /$2 where $2 is "stats" -> /stats
    # /api/submissions -> /$2 where $2 is "submissions" -> /submissions  
    # /api/health -> /$2 where $2 is "health" -> /health
    # /api/ -> /$2 where $2 is "" -> /
    
    expected_rewrites = [
        ("/api/stats", "/stats", "stats endpoint"),
        ("/api/submissions", "/submissions", "submissions endpoint"),
        ("/api/health", "/health", "health endpoint"),
        ("/api/", "/", "root endpoint"),
    ]
    
    print("Expected rewrites:")
    for original, rewritten, desc in expected_rewrites:
        print(f"  {original:20} -> {rewritten:15} ({desc})")
    
    print(f"\nBut looking at our local FastAPI test:")
    print(f"  The FastAPI app expects endpoints at their original paths!")
    print(f"  /api/stats should stay /api/stats, not become /stats")
    print(f"\nThis explains why /api/health works:")
    print(f"  It's defined as @app.get('/health') in FastAPI")
    print(f"  So /api/health -> /health matches the endpoint")
    print(f"\nBut /api/stats doesn't work because:")
    print(f"  It's defined as @app.get('/api/stats') in FastAPI") 
    print(f"  So /api/stats -> /stats doesn't match!")

async def main():
    print("🔍 Analyzing Ingress Routing Issue")
    print(f"Base URL: {BASE_URL}")
    print(f"Time: {datetime.now()}")
    print("=" * 80)
    
    await test_routing_patterns()
    await test_ingress_rewrite()
    
    print("\n" + "=" * 80)
    print("🎯 ROOT CAUSE IDENTIFIED:")
    print("The ingress rewrite rule is incompatible with the FastAPI endpoint definitions!")
    print()
    print("SOLUTION OPTIONS:")
    print("1. Change FastAPI endpoints to match rewrite (remove /api prefix)")
    print("2. Fix the ingress rewrite rule to not modify the path")
    print("3. Use a different ingress configuration")

if __name__ == "__main__":
    asyncio.run(main())
