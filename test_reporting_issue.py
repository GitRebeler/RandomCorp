#!/usr/bin/env python3
"""
Test script to diagnose the reporting page loading issues
"""

import asyncio
import aiohttp
import json
import time
from datetime import datetime
from typing import Dict, Any

BASE_URL = "http://104.237.148.210"

async def test_api_endpoint(session: aiohttp.ClientSession, endpoint: str, retries: int = 3) -> Dict[str, Any]:
    """Test an API endpoint with retries and timing"""
    for attempt in range(retries):
        try:
            start_time = time.time()
            
            async with session.get(f"{BASE_URL}{endpoint}", timeout=aiohttp.ClientTimeout(total=30)) as response:
                end_time = time.time()
                response_time = end_time - start_time
                
                if response.status == 200:
                    data = await response.json()
                    return {
                        "success": True,
                        "status_code": response.status,
                        "response_time": response_time,
                        "attempt": attempt + 1,
                        "data": data,
                        "data_size": len(json.dumps(data)) if data else 0
                    }
                else:
                    text = await response.text()
                    return {
                        "success": False,
                        "status_code": response.status,
                        "response_time": response_time,
                        "attempt": attempt + 1,
                        "error": f"HTTP {response.status}: {text[:200]}"
                    }
        except asyncio.TimeoutError:
            if attempt == retries - 1:
                return {
                    "success": False,
                    "attempt": attempt + 1,
                    "error": "Request timeout"
                }
        except Exception as e:
            if attempt == retries - 1:
                return {
                    "success": False,
                    "attempt": attempt + 1,
                    "error": f"Request failed: {str(e)}"
                }
        
        # Wait before retry
        if attempt < retries - 1:
            await asyncio.sleep(1)
    
    return {"success": False, "error": "All retries failed"}

async def test_multiple_requests(endpoint: str, count: int = 10, delay: float = 0.5) -> list:
    """Test an endpoint multiple times to check for inconsistency"""
    results = []
    
    async with aiohttp.ClientSession() as session:
        for i in range(count):
            print(f"Testing {endpoint} - Request {i+1}/{count}")
            result = await test_api_endpoint(session, endpoint)
            result["request_number"] = i + 1
            result["timestamp"] = datetime.now().isoformat()
            results.append(result)
            
            if delay > 0:
                await asyncio.sleep(delay)
    
    return results

async def analyze_results(results: list, endpoint: str):
    """Analyze test results for patterns"""
    total_requests = len(results)
    successful_requests = [r for r in results if r.get("success", False)]
    failed_requests = [r for r in results if not r.get("success", False)]
    
    print(f"\n=== Analysis for {endpoint} ===")
    print(f"Total requests: {total_requests}")
    print(f"Successful: {len(successful_requests)} ({len(successful_requests)/total_requests*100:.1f}%)")
    print(f"Failed: {len(failed_requests)} ({len(failed_requests)/total_requests*100:.1f}%)")
    
    if successful_requests:
        response_times = [r["response_time"] for r in successful_requests]
        avg_response_time = sum(response_times) / len(response_times)
        max_response_time = max(response_times)
        min_response_time = min(response_times)
        
        print(f"Average response time: {avg_response_time:.3f}s")
        print(f"Min response time: {min_response_time:.3f}s")
        print(f"Max response time: {max_response_time:.3f}s")
        
        # Check for data consistency
        if endpoint == "/api/stats":
            total_submissions = [r["data"].get("total_submissions", 0) for r in successful_requests if "data" in r]
            if total_submissions:
                unique_values = set(total_submissions)
                print(f"Total submissions values seen: {unique_values}")
                if len(unique_values) > 1:
                    print("⚠️  WARNING: Inconsistent total_submissions values detected!")
        
        elif endpoint == "/api/submissions":
            submission_counts = [len(r["data"].get("submissions", [])) for r in successful_requests if "data" in r]
            total_counts = [r["data"].get("total", 0) for r in successful_requests if "data" in r]
            if submission_counts:
                print(f"Submission counts returned: {set(submission_counts)}")
            if total_counts:
                unique_totals = set(total_counts)
                print(f"Total counts seen: {unique_totals}")
                if len(unique_totals) > 1:
                    print("⚠️  WARNING: Inconsistent total counts detected!")
    
    if failed_requests:
        print(f"Failed request errors:")
        error_counts = {}
        for req in failed_requests:
            error = req.get("error", "Unknown error")
            error_counts[error] = error_counts.get(error, 0) + 1
        
        for error, count in error_counts.items():
            print(f"  - {error}: {count} times")
    
    print()

async def test_frontend_page():
    """Test the frontend reporting page"""
    try:
        from playwright.async_api import async_playwright
        
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            
            print("Testing frontend reporting page...")
            
            # Set up network monitoring
            response_data = {}
            
            async def handle_response(response):
                if "/api/" in response.url:
                    endpoint = response.url.split("/api/")[-1].split("?")[0]
                    response_data[endpoint] = {
                        "status": response.status,
                        "url": response.url,
                        "ok": response.ok
                    }
                    
                    if response.ok:
                        try:
                            data = await response.json()
                            response_data[endpoint]["data"] = data
                        except:
                            pass
            
            page.on("response", handle_response)
            
            # Navigate to reporting page
            await page.goto(f"{BASE_URL}/reporting", timeout=30000)
            
            # Wait for page to load and API calls to complete
            await page.wait_for_timeout(5000)
            
            # Check for loading indicators
            loading_indicators = await page.query_selector_all('[role="progressbar"]')
            if loading_indicators:
                print("⚠️  Loading indicators still present on page")
            
            # Check for error messages
            error_alerts = await page.query_selector_all('[role="alert"]')
            if error_alerts:
                print("⚠️  Error alerts found on page")
                for alert in error_alerts:
                    text = await alert.text_content()
                    print(f"  Error: {text}")
            
            # Check statistics cards
            stat_cards = await page.query_selector_all('[data-testid="stats-card"], .MuiCard-root')
            print(f"Found {len(stat_cards)} statistics cards")
            
            # Check if submission table is present and populated
            table_rows = await page.query_selector_all('table tbody tr')
            print(f"Found {len(table_rows)} table rows")
            
            if table_rows:
                # Check if rows contain actual data or "no submissions found" message
                for i, row in enumerate(table_rows[:3]):  # Check first 3 rows
                    text = await row.text_content()
                    if "no submissions found" in text.lower():
                        print("⚠️  'No submissions found' message detected")
                    else:
                        print(f"  Row {i+1}: {text[:100]}...")
            
            await browser.close()
            
            print("\n=== Frontend API Calls ===")
            for endpoint, data in response_data.items():
                print(f"{endpoint}: Status {data['status']} ({'OK' if data['ok'] else 'FAILED'})")
                if 'data' in data:
                    if endpoint == 'stats':
                        stats = data['data']
                        print(f"  Total submissions: {stats.get('total_submissions', 'N/A')}")
                        print(f"  Status: {stats.get('status', 'N/A')}")
                    elif endpoint == 'submissions':
                        subs = data['data']
                        print(f"  Submissions returned: {len(subs.get('submissions', []))}")
                        print(f"  Total count: {subs.get('total', 'N/A')}")
            
    except ImportError:
        print("Playwright not available, skipping frontend test")
    except Exception as e:
        print(f"Frontend test failed: {e}")

async def main():
    """Main test function"""
    print("🔍 Testing RandomCorp Reporting Issues")
    print(f"Base URL: {BASE_URL}")
    print(f"Test started at: {datetime.now()}")
    print("=" * 60)
    
    # Test API endpoints multiple times
    endpoints_to_test = [
        "/api/stats",
        "/api/submissions",
        "/api/submissions?limit=5&offset=0"
    ]
    
    for endpoint in endpoints_to_test:
        print(f"\nTesting endpoint: {endpoint}")
        results = await test_multiple_requests(endpoint, count=10, delay=0.5)
        await analyze_results(results, endpoint)
    
    # Test frontend
    await test_frontend_page()
    
    print("=" * 60)
    print(f"Test completed at: {datetime.now()}")

if __name__ == "__main__":
    asyncio.run(main())
