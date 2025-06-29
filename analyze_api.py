#!/usr/bin/env python3
"""
Test the working endpoints to understand backend state
"""

import asyncio
import aiohttp
from datetime import datetime
import json

BASE_URL = "http://104.237.148.210"

async def get_api_info():
    """Get information from the working API root endpoint"""
    
    async with aiohttp.ClientSession() as session:
        try:
            # Test the root API endpoint that works
            async with session.get(f"{BASE_URL}/api/", timeout=aiohttp.ClientTimeout(total=10)) as response:
                if response.status == 200:
                    data = await response.json()
                    print("✅ API Root endpoint response:")
                    print(json.dumps(data, indent=2))
                    
                    # Check what endpoints are supposed to be available
                    if "endpoints" in data:
                        print("\n📋 Endpoints listed by the API:")
                        for name, path in data["endpoints"].items():
                            print(f"  {name}: {path}")
                        
                        # Test each listed endpoint
                        print("\n🧪 Testing listed endpoints:")
                        for name, path in data["endpoints"].items():
                            try:
                                async with session.get(f"{BASE_URL}{path}", timeout=aiohttp.ClientTimeout(total=5)) as ep_response:
                                    print(f"  {path:25} -> {ep_response.status} ({ep_response.reason})")
                            except Exception as e:
                                print(f"  {path:25} -> ERROR: {str(e)}")
                
        except Exception as e:
            print(f"❌ Failed to get API info: {e}")
        
        # Also test the health endpoint
        try:
            async with session.get(f"{BASE_URL}/api/health", timeout=aiohttp.ClientTimeout(total=10)) as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"\n✅ Health endpoint: {data}")
        except Exception as e:
            print(f"❌ Failed to get health info: {e}")

async def test_submit_endpoint():
    """Test if we can submit data to create some test data"""
    async with aiohttp.ClientSession() as session:
        try:
            # Try to submit some test data
            test_data = {
                "firstName": "Test",
                "lastName": "User"
            }
            
            print("\n🧪 Testing submit endpoint...")
            async with session.post(f"{BASE_URL}/api/submit", 
                                   json=test_data,
                                   timeout=aiohttp.ClientTimeout(total=15)) as response:
                print(f"Submit endpoint: {response.status} ({response.reason})")
                
                if response.status == 200:
                    data = await response.json()
                    print("✅ Submit successful:")
                    print(json.dumps(data, indent=2))
                    
                    # Now try the stats endpoint again
                    print("\n🔄 Retrying stats endpoint after submit...")
                    await asyncio.sleep(2)
                    
                    async with session.get(f"{BASE_URL}/api/stats", timeout=aiohttp.ClientTimeout(total=10)) as stats_response:
                        print(f"Stats after submit: {stats_response.status} ({stats_response.reason})")
                        if stats_response.status == 200:
                            stats_data = await stats_response.json()
                            print(json.dumps(stats_data, indent=2))
                
        except Exception as e:
            print(f"❌ Submit test failed: {e}")

async def main():
    print("🔍 Analyzing Working API Endpoints")
    print(f"Base URL: {BASE_URL}")
    print(f"Time: {datetime.now()}")
    print("=" * 80)
    
    await get_api_info()
    await test_submit_endpoint()
    
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(main())
