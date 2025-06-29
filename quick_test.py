#!/usr/bin/env python3
"""
Quick test to check if the new deployment is active
"""

import asyncio
import aiohttp
from datetime import datetime

BASE_URL = "http://104.237.148.210"

async def quick_test():
    """Quick test to see if the deployment updated"""
    
    async with aiohttp.ClientSession() as session:
        print("🔍 Quick deployment check...")
        
        # Check the root endpoint to see what endpoints are listed
        try:
            async with session.get(f"{BASE_URL}/api/", timeout=aiohttp.ClientTimeout(total=10)) as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✅ API Root: {response.status}")
                    print(f"   Version: {data.get('version', 'Unknown')}")
                    print(f"   Uptime: {data.get('uptime_seconds', 'Unknown')} seconds")
                    
                    if "endpoints" in data:
                        print(f"   📋 Listed endpoints:")
                        for name, path in data["endpoints"].items():
                            print(f"      {name}: {path}")
                            
                        # Check if endpoints now use the correct paths
                        endpoints = data["endpoints"]
                        if endpoints.get("stats") == "/api/stats":
                            print("   ⚠️  Still showing old endpoint paths - deployment not updated yet")
                        elif endpoints.get("stats") == "/stats":
                            print("   ✅ New endpoint paths detected - deployment updated!")
                        else:
                            print("   ❓ Unexpected endpoint configuration")
                    
                else:
                    print(f"❌ API Root: {response.status}")
                    
        except Exception as e:
            print(f"❌ Error: {e}")
            
        # Quick test of the problematic endpoints
        test_endpoints = ["/api/stats", "/api/submissions"]
        for endpoint in test_endpoints:
            try:
                async with session.get(f"{BASE_URL}{endpoint}", timeout=aiohttp.ClientTimeout(total=5)) as response:
                    status_icon = "✅" if response.status == 200 else "❌"
                    print(f"{status_icon} {endpoint}: {response.status}")
                    
            except Exception as e:
                print(f"❌ {endpoint}: ERROR - {e}")

async def main():
    print(f"Quick test at {datetime.now()}")
    print("=" * 50)
    await quick_test()
    print("=" * 50)

if __name__ == "__main__":
    asyncio.run(main())
