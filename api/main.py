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
from database import get_db_manager

# Global in-memory storage for demo mode when database is not available
in_memory_submissions = []

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
    description="Asynchronous API with SQL Server backend for processing name submissions",
    version="2.1.0"
)

# Track application start time for uptime calculation
app_start_time = datetime.now(timezone.utc)

# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Initialize database connection on startup"""
    logger.info("🚀 Starting Random Corp API...")
    try:
        # Check if SQL Server environment variables are set
        db_host = os.getenv('DB_HOST')
        logger.info(f"🔍 DB_HOST environment variable: {db_host}")
        if db_host:
            logger.info("✅ Database host configured, initializing database...")
            db_manager = get_db_manager()
            await db_manager.initialize()
            logger.info("✅ Database initialized successfully")
        else:
            logger.info("🔄 Running in demo mode without database")
            # Initialize in-memory storage for demo
            in_memory_submissions.clear()
        logger.info("✅ API startup completed successfully")
    except Exception as e:
        logger.error(f"⚠️ Database initialization failed, running in demo mode: {str(e)}")
        # Initialize in-memory storage as fallback
        in_memory_submissions.clear()
        logger.info("✅ API started in demo mode")

@app.on_event("shutdown")
async def shutdown_event():
    """Close database connections on shutdown"""
    logger.info("🛑 Shutting down Random Corp API...")
    db_manager = get_db_manager()
    await db_manager.close()
    logger.info("✅ API shutdown completed")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for production deployment
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

class LatestSubmission(BaseModel):
    id: str
    name: str
    timestamp: str

class StatsResponse(BaseModel):
    total_messages: int
    total_submissions: int
    recent_submissions: int
    avg_processing_time: float
    latest_submission: Optional[LatestSubmission]
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

# Async helper functions
async def simulate_database_save(data: Dict) -> str:
    """Generate submission ID for database save (actual save happens in background)"""
    if debug_mode:
        logger.debug(f"💾 Preparing submission for SQL Server: {data.get('first_name', 'Unknown')}")
    
    # Simulate processing delay
    await asyncio.sleep(0.05 + random.uniform(0.02, 0.1))
    
    submission_id = f"sub_{random.randint(10000, 99999)}_{int(datetime.now().timestamp())}"
    
    if debug_mode:
        logger.debug(f"✅ Generated submission ID: {submission_id}")
    
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
    """Update application statistics in SQL Server database"""
    try:
        db_manager = get_db_manager()
        await db_manager.update_statistics({})
        
        if debug_mode:
            stats = await db_manager.get_statistics()
            logger.debug(f"📊 Stats updated in database: {stats['total_submissions']} total submissions")
    except Exception as e:
        logger.error(f"❌ Failed to update stats: {str(e)}")

async def save_complete_submission(submission_data: Dict) -> None:
    """Save complete submission data to database or in-memory storage"""
    try:
        # Check if database is available
        db_manager = get_db_manager()
        if os.getenv('DB_HOST') and hasattr(db_manager, 'pool') and db_manager.pool:
            await db_manager.save_submission(submission_data)
            if debug_mode:
                logger.debug(f"💾 Complete submission saved to database: {submission_data['submission_id']}")
        else:
            # Save to in-memory storage for demo mode
            in_memory_submissions.append(submission_data)
            if debug_mode:
                logger.debug(f"💾 Complete submission saved to memory: {submission_data['submission_id']}")
    except Exception as e:
        logger.error(f"❌ Failed to save complete submission, falling back to memory: {str(e)}")
        # Fallback to in-memory storage
        in_memory_submissions.append(submission_data)

@app.get("/api/")
async def root():
    """Enhanced async root endpoint with system information"""
    try:
        uptime = (datetime.now(timezone.utc) - app_start_time).total_seconds()
        
        # Simulate minimal async operation for demo
        await asyncio.sleep(0.001)
        
        return {
            "message": "Random Corp API is running",
            "version": "2.1.0",
            "status": "healthy",
            "async_enabled": True,
            "database_enabled": True,
            "debug_mode": debug_mode,
            "uptime_seconds": uptime,
            "endpoints": {
                "submit": "/api/submit",
                "batch_submit": "/api/submit/batch",
                "stats": "/api/stats",
                "submissions": "/api/submissions",
                "health": "/health"
            }
        }
    except Exception as e:
        logger.error(f"❌ Error in root endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="Root endpoint error")

@app.get("/api/health")
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
        
        # Prepare submission data for database
        submission_data = {
            "first_name": submission.firstName,
            "last_name": submission.lastName,
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
        
        # Calculate processing time
        end_time = datetime.now(timezone.utc)
        processing_time = (end_time - start_time).total_seconds()
        
        # Update stats asynchronously in background
        background_tasks.add_task(update_stats_async)
        
        # Log submission in background (fire-and-forget)
        log_data = {
            **submission_data,
            "submission_id": submission_id,
            "external_data": external_data,
            "message": message,
            "processing_time": processing_time
        }
        background_tasks.add_task(log_submission_async, log_data)
        
        # Save complete submission data to database in background
        db_submission_data = {
            **submission_data,
            "submission_id": submission_id,
            "message": message,
            "external_data": external_data,
            "processing_time": processing_time
        }
        background_tasks.add_task(save_complete_submission, db_submission_data)
        
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
            
            # Prepare submission data for database
            submission_data = {
                "first_name": submission.firstName,
                "last_name": submission.lastName,
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
    Get comprehensive API statistics from database or in-memory storage
    """
    try:
        # Calculate uptime
        current_time = datetime.now(timezone.utc)
        uptime = (current_time - app_start_time).total_seconds()
        
        if debug_mode:
            logger.debug(f"📊 Generating stats report - Uptime: {uptime:.1f}s")
        
        # Check if database is available
        db_manager = get_db_manager()
        if os.getenv('DB_HOST') and hasattr(db_manager, 'pool') and db_manager.pool:
            # Get stats from database
            db_stats = await db_manager.get_statistics()
            
            # Extract last submission timestamp
            latest_sub = db_stats["latest_submission"]
            last_submission_time = None
            latest_submission_obj = None
            
            if latest_sub and latest_sub.get('timestamp'):
                try:
                    last_submission_time = datetime.fromisoformat(latest_sub['timestamp'].replace('Z', '+00:00'))
                    latest_submission_obj = LatestSubmission(
                        id=latest_sub['id'],
                        name=latest_sub['name'],
                        timestamp=latest_sub['timestamp']
                    )
                except:
                    last_submission_time = None

            stats = StatsResponse(
                total_messages=len(POSITIVE_MESSAGES),
                total_submissions=db_stats["total_submissions"],
                recent_submissions=db_stats.get("recent_submissions", 0),
                avg_processing_time=db_stats.get("avg_processing_time", 0.0),
                latest_submission=latest_submission_obj,
                api_version="2.1.0",
                status="operational",
                debug_mode=debug_mode,
                last_submission=last_submission_time,
                uptime_seconds=uptime
            )
        else:
            # Use in-memory data for demo mode
            total_submissions = len(in_memory_submissions)
            
            # Calculate average processing time from in-memory data
            avg_processing_time = 0.0
            if in_memory_submissions:
                processing_times = [sub.get('processing_time', 0.0) for sub in in_memory_submissions]
                avg_processing_time = sum(processing_times) / len(processing_times)
            
            # Get latest submission
            latest_submission_obj = None
            last_submission_time = None
            if in_memory_submissions:
                latest_sub = in_memory_submissions[-1]
                latest_submission_obj = LatestSubmission(
                    id=latest_sub.get('submission_id', 'demo'),
                    name=f"{latest_sub.get('first_name', '')} {latest_sub.get('last_name', '')}".strip(),
                    timestamp=latest_sub.get('timestamp', current_time.isoformat())
                )
                try:
                    last_submission_time = datetime.fromisoformat(latest_sub.get('timestamp', current_time.isoformat()))
                except:
                    last_submission_time = current_time

            stats = StatsResponse(
                total_messages=len(POSITIVE_MESSAGES),
                total_submissions=total_submissions,
                recent_submissions=total_submissions,  # All submissions are recent in demo mode
                avg_processing_time=avg_processing_time,
                latest_submission=latest_submission_obj,
                api_version="2.1.0",
                status="demo_mode",
                debug_mode=debug_mode,
                last_submission=last_submission_time,
                uptime_seconds=uptime
            )
        
        if debug_mode:
            logger.debug(f"📈 Stats report generated: {stats.total_submissions} submissions, {uptime:.1f}s uptime")
        
        return stats
        
    except Exception as e:
        logger.error(f"❌ Error generating stats: {str(e)}")
        raise HTTPException(status_code=500, detail="Error retrieving API statistics")

@app.get("/api/submissions")
async def get_submissions(limit: int = 10, offset: int = 0):
    """
    Get paginated submissions from database or in-memory storage
    """
    try:
        if debug_mode:
            logger.debug(f"📋 Retrieving {limit} submissions (offset: {offset})")
        
        # Check if database is available
        db_manager = get_db_manager()
        if os.getenv('DB_HOST') and hasattr(db_manager, 'pool') and db_manager.pool:
            # Get paginated submissions from database
            submissions = await db_manager.get_paginated_submissions(limit=limit, offset=offset)
            total_count = await db_manager.get_submissions_count()
        else:            # Use in-memory data for demo mode
            total_count = len(in_memory_submissions)
            
            # Apply pagination to in-memory data
            start_idx = offset
            end_idx = offset + limit
            submissions = in_memory_submissions[start_idx:end_idx]
        
        if debug_mode:
            logger.debug(f"📄 Retrieved {len(submissions)} submissions (total: {total_count})")
        
        return {
            "submissions": submissions,
            "count": len(submissions),
            "total": total_count,
            "limit": limit,
            "offset": offset,
            "has_more": offset + len(submissions) < total_count
        }
        
    except Exception as e:
        logger.error(f"❌ Error retrieving submissions from database: {str(e)}")
        raise HTTPException(status_code=500, detail="Error retrieving submissions from database")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
