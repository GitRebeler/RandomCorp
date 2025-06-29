#!/usr/bin/env python3
"""
Simple test to check different API endpoint paths
"""

import asyncio
import aiohttp
from datetime import datetime

BASE_URL = "http://104.237.148.210"

async def test_endpoint_variations():
    """Test different variations of API endpoints"""
    
    endpoints_to_test = [
        # Direct API paths
        "/api/stats",
        "/api/submissions", 
        "/stats",
        "/submissions",
        
        # With trailing slash
        "/api/stats/",
        "/api/submissions/",
        
        # Root level
        "/",
        "/health",
        "/api/health",
        
        # Check if API is on different path
        "/randomcorp/api/stats",
        "/randomcorp/api/submissions",
    ]
    
    async with aiohttp.ClientSession() as session:
        for endpoint in endpoints_to_test:
            try:
                async with session.get(f"{BASE_URL}{endpoint}", timeout=aiohttp.ClientTimeout(total=10)) as response:
                    print(f"{endpoint:30} -> {response.status} ({response.reason})")
                    if response.status == 200:
                        try:
                            data = await response.json()
                            if isinstance(data, dict):
                                if "total_submissions" in data:
                                    print(f"                              📊 Stats endpoint found! Total submissions: {data.get('total_submissions')}")
                                elif "submissions" in data:
                                    print(f"                              📋 Submissions endpoint found! Count: {len(data.get('submissions', []))}")
                                elif "message" in data:
                                    print(f"                              💬 Message: {data.get('message')}")
                        except:
                            text = await response.text()
                            print(f"                              📄 Response: {text[:100]}...")
            except Exception as e:
                print(f"{endpoint:30} -> ERROR: {str(e)}")

async def main():
    print("🔍 Testing API Endpoint Variations")
    print(f"Base URL: {BASE_URL}")
    print(f"Time: {datetime.now()}")
    print("=" * 80)
    
    await test_endpoint_variations()
    
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(main())
