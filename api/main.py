from fastapi import FastAPI, HTTPException, BackgroundTasks, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
import logging
import random
import asyncio
import aiofiles
import os
from typing import Optional, Dict, List
from datetime import datetime, timezone
import json
import time

# Configure logging based on environment
log_level = os.getenv('LOG_LEVEL', 'INFO').upper()
debug_mode = os.getenv('DEBUG', 'false').lower() == 'true'

logging.basicConfig(
    level=getattr(logging, log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

if debug_mode:
    logger.info("🐛 Debug mode enabled - Enhanced async processing")
    logger.info(f"📊 Log level set to: {log_level}")

app = FastAPI(
    title="Random Corp API",
    description="Asynchronous API for processing name submissions with enhanced performance",
    version="2.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://frontend:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add timing middleware for request performance monitoring
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """Async middleware to add request timing and logging"""
    start_time = time.time()
    
    if debug_mode:
        logger.debug(f"🔍 Starting request: {request.method} {request.url.path}")
    
    response = await call_next(request)
    process_time = time.time() - start_time
    
    response.headers["X-Process-Time"] = str(process_time)
    
    if debug_mode:
        logger.debug(f"⏱️ Request completed in {process_time:.3f}s: {request.method} {request.url.path}")
    
    return response

# In-memory storage for demonstration (in production, use async database)
submission_store: Dict[str, List[Dict]] = {
    "submissions": [],
    "stats": {"total_submissions": 0, "last_submission": None}
}

class SubmissionRequest(BaseModel):
    firstName: str
    lastName: str
    
    @validator('firstName', 'lastName')
    def validate_names(cls, v):
        if not v or not v.strip():
            raise ValueError('Name cannot be empty')
        if len(v.strip()) < 1:
            raise ValueError('Name must be at least 1 character long')
        if len(v.strip()) > 50:
            raise ValueError('Name cannot be longer than 50 characters')
        return v.strip()

class SubmissionResponse(BaseModel):
    firstName: str
    lastName: str
    message: str
    submissionId: str
    timestamp: datetime
    processingTime: float

class StatsResponse(BaseModel):
    total_messages: int
    total_submissions: int
    api_version: str
    status: str
    debug_mode: bool
    last_submission: Optional[datetime]
    uptime_seconds: float

class BatchSubmissionRequest(BaseModel):
    submissions: List[SubmissionRequest]
    
    @validator('submissions')
    def validate_batch_size(cls, v):
        if len(v) > 10:
            raise ValueError('Batch size cannot exceed 10 submissions')
        if len(v) < 1:
            raise ValueError('Batch must contain at least 1 submission')
        return v

class BatchSubmissionResponse(BaseModel):
    total_processed: int
    processing_time: float
    results: List[SubmissionResponse]
    batch_id: str

# Predefined positive messages
POSITIVE_MESSAGES = [
    "Welcome to Random Corp! We're excited to have you.",
    "Thank you for joining our community!",
    "Great to meet you! Your journey with Random Corp begins now.",
    "Welcome aboard! We look forward to working with you.",
    "Fantastic! You're now part of the Random Corp family.",
    "Excellent! Your submission has been processed successfully.",
    "Welcome! We're thrilled to have you on our team.",
    "Congratulations! You've successfully registered with Random Corp.",
    "Amazing! Your information has been received and processed.",
    "Perfect! Welcome to the Random Corp experience."
]

# Track application start time for uptime calculation
app_start_time = datetime.now(timezone.utc)

# Async helper functions
async def simulate_database_save(data: Dict) -> str:
    """Simulate async database save operation"""
    if debug_mode:
        logger.debug(f"💾 Simulating database save for: {data.get('firstName', 'Unknown')}")
    
    # Simulate network/database delay
    await asyncio.sleep(0.1 + random.uniform(0.05, 0.2))
    
    submission_id = f"sub_{random.randint(10000, 99999)}_{int(datetime.now().timestamp())}"
    
    # Store in memory (in production, this would be an async database call)
    submission_store["submissions"].append({
        **data,
        "submission_id": submission_id,
        "timestamp": datetime.now(timezone.utc).isoformat()
    })
    
    if debug_mode:
        logger.debug(f"✅ Database save completed with ID: {submission_id}")
    
    return submission_id

async def simulate_external_api_call(name: str) -> Dict:
    """Simulate calling an external API for additional processing"""
    if debug_mode:
        logger.debug(f"🌐 Making external API call for: {name}")
    
    # Simulate API call delay
    await asyncio.sleep(0.05 + random.uniform(0.02, 0.1))
    
    # Simulate API response
    result = {
        "name_length": len(name),
        "processed_at": datetime.now(timezone.utc).isoformat(),
        "external_id": f"ext_{random.randint(1000, 9999)}"
    }
    
    if debug_mode:
        logger.debug(f"📡 External API response: {result}")
    
    return result

async def log_submission_async(submission_data: Dict) -> None:
    """Async background task to log submission to file"""
    try:
        log_file = "submissions.log"
        log_entry = f"{datetime.now().isoformat()} - {json.dumps(submission_data)}\n"
        
        # Use aiofiles for async file operations
        async with aiofiles.open(log_file, "a") as f:
            await f.write(log_entry)
            
        if debug_mode:
            logger.debug(f"📝 Async log entry written to {log_file}")
            
    except Exception as e:
        logger.error(f"❌ Failed to write async log: {str(e)}")

async def update_stats_async() -> None:
    """Update application statistics asynchronously"""
    submission_store["stats"]["total_submissions"] += 1
    submission_store["stats"]["last_submission"] = datetime.now(timezone.utc)
    
    if debug_mode:
        logger.debug(f"📊 Stats updated: {submission_store['stats']['total_submissions']} total submissions")

@app.get("/")
async def root():
    """Enhanced async root endpoint with system information"""
    try:
        uptime = (datetime.now(timezone.utc) - app_start_time).total_seconds()
        
        # Simulate minimal async operation for demo
        await asyncio.sleep(0.001)
        
        return {
            "message": "Random Corp API is running",
            "version": "2.0.0",
            "status": "healthy",
            "async_enabled": True,
            "debug_mode": debug_mode,
            "uptime_seconds": uptime,
            "endpoints": {
                "submit": "/api/submit",
                "stats": "/api/stats",
                "health": "/health"
            }
        }
    except Exception as e:
        logger.error(f"❌ Error in root endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="Root endpoint error")

@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {"status": "healthy", "service": "Random Corp API"}

@app.post("/api/submit", response_model=SubmissionResponse)
async def submit_names(submission: SubmissionRequest, background_tasks: BackgroundTasks):
    """
    Process name submission asynchronously with background tasks
    """
    start_time = datetime.now(timezone.utc)
    
    try:
        full_name = f"{submission.firstName} {submission.lastName}"
        logger.info(f"🚀 Processing async submission for: {full_name}")
        
        # Prepare submission data
        submission_data = {
            "firstName": submission.firstName,
            "lastName": submission.lastName,
            "timestamp": start_time.isoformat()
        }
        
        # Async operations that can run concurrently
        async_tasks = [
            simulate_database_save(submission_data),
            simulate_external_api_call(full_name),
        ]
        
        # Execute async operations concurrently
        if debug_mode:
            logger.debug(f"⏳ Starting {len(async_tasks)} concurrent async operations")
        
        submission_id, external_data = await asyncio.gather(*async_tasks)
        
        # Generate a random positive message
        message = random.choice(POSITIVE_MESSAGES)
        
        # Update stats asynchronously in background
        background_tasks.add_task(update_stats_async)
        
        # Log submission in background (fire-and-forget)
        log_data = {
            **submission_data,
            "submission_id": submission_id,
            "external_data": external_data,
            "message": message
        }
        background_tasks.add_task(log_submission_async, log_data)
        
        # Calculate processing time
        end_time = datetime.now(timezone.utc)
        processing_time = (end_time - start_time).total_seconds()
          # Create response
        response = SubmissionResponse(
            firstName=submission.firstName,
            lastName=submission.lastName,
            message=message,
            submissionId=submission_id,
            timestamp=start_time,
            processingTime=processing_time
        )
        
        if debug_mode:
            logger.info(f"✅ Async processing completed for: {full_name} in {processing_time:.3f}s")
        else:
            logger.info(f"Successfully processed submission for: {full_name}")
        
        return response
        
    except Exception as e:
        logger.error(f"❌ Error processing async submission: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error occurred during async processing")

@app.post("/api/submit/batch", response_model=BatchSubmissionResponse)
async def submit_names_batch(batch_request: BatchSubmissionRequest, background_tasks: BackgroundTasks):
    """
    Process multiple name submissions concurrently using async batch processing
    """
    start_time = datetime.now(timezone.utc)
    batch_id = f"batch_{random.randint(10000, 99999)}_{int(start_time.timestamp())}"
    
    try:
        logger.info(f"🚀 Processing async batch submission with {len(batch_request.submissions)} items (ID: {batch_id})")
        
        # Process all submissions concurrently
        async def process_single_submission(submission: SubmissionRequest) -> SubmissionResponse:
            """Process a single submission within the batch"""
            full_name = f"{submission.firstName} {submission.lastName}"
            
            # Prepare submission data
            submission_data = {
                "firstName": submission.firstName,
                "lastName": submission.lastName,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "batch_id": batch_id
            }
            
            # Async operations for this submission
            submission_id, external_data = await asyncio.gather(
                simulate_database_save(submission_data),
                simulate_external_api_call(full_name)
            )
            
            # Generate response
            message = random.choice(POSITIVE_MESSAGES)
            return SubmissionResponse(
                firstName=submission.firstName,
                lastName=submission.lastName,
                message=message,
                submissionId=submission_id,
                timestamp=start_time,
                processingTime=0.0  # Will be calculated for the whole batch
            )
        
        # Process all submissions concurrently
        if debug_mode:
            logger.debug(f"⏳ Starting concurrent processing of {len(batch_request.submissions)} submissions")
        
        results = await asyncio.gather(*[
            process_single_submission(submission) 
            for submission in batch_request.submissions
        ])
        
        # Calculate total processing time
        end_time = datetime.now(timezone.utc)
        total_processing_time = (end_time - start_time).total_seconds()
        
        # Update processing time for all results
        for result in results:
            result.processingTime = total_processing_time
        
        # Update stats for all submissions in background
        for _ in range(len(results)):
            background_tasks.add_task(update_stats_async)
        
        # Log batch completion
        batch_log_data = {
            "batch_id": batch_id,
            "total_submissions": len(results),
            "processing_time": total_processing_time,
            "timestamp": start_time.isoformat()
        }
        background_tasks.add_task(log_submission_async, batch_log_data)
        
        response = BatchSubmissionResponse(
            total_processed=len(results),
            processing_time=total_processing_time,
            results=results,
            batch_id=batch_id
        )
        
        if debug_mode:
            logger.info(f"✅ Batch processing completed: {len(results)} submissions in {total_processing_time:.3f}s")
        else:
            logger.info(f"Successfully processed batch: {len(results)} submissions")
        
        return response
        
    except Exception as e:
        logger.error(f"❌ Error processing async batch submission: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error occurred during batch processing")

@app.get("/api/stats", response_model=StatsResponse)
async def get_stats():
    """
    Get comprehensive API statistics asynchronously
    """
    try:
        # Calculate uptime
        current_time = datetime.now(timezone.utc)
        uptime = (current_time - app_start_time).total_seconds()
        
        if debug_mode:
            logger.debug(f"📊 Generating async stats report - Uptime: {uptime:.1f}s")
        
        # Simulate async stats gathering (in production, this might query multiple databases)
        await asyncio.sleep(0.01)  # Simulate minimal async operation
        
        stats = StatsResponse(
            total_messages=len(POSITIVE_MESSAGES),
            total_submissions=submission_store["stats"]["total_submissions"],
            api_version="2.0.0",
            status="operational",
            debug_mode=debug_mode,
            last_submission=submission_store["stats"]["last_submission"],
            uptime_seconds=uptime
        )
        
        if debug_mode:
            logger.debug(f"📈 Stats report generated: {stats.total_submissions} submissions, {uptime:.1f}s uptime")
        
        return stats
        
    except Exception as e:
        logger.error(f"❌ Error generating async stats: {str(e)}")
        raise HTTPException(status_code=500, detail="Error retrieving API statistics")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
