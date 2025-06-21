from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
import logging
import random
from typing import Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Random Corp API",
    description="API for processing name submissions",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://frontend:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "Random Corp API is running", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {"status": "healthy", "service": "Random Corp API"}

@app.post("/api/submit", response_model=SubmissionResponse)
async def submit_names(submission: SubmissionRequest):
    """
    Process name submission and return a personalized response
    """
    try:
        logger.info(f"Processing submission for: {submission.firstName} {submission.lastName}")
        
        # Generate a random positive message
        message = random.choice(POSITIVE_MESSAGES)
        
        # Create response
        response = SubmissionResponse(
            firstName=submission.firstName,
            lastName=submission.lastName,
            message=message
        )
        
        logger.info(f"Successfully processed submission for: {submission.firstName} {submission.lastName}")
        return response
        
    except Exception as e:
        logger.error(f"Error processing submission: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/stats")
async def get_stats():
    """
    Get basic API statistics
    """
    return {
        "total_messages": len(POSITIVE_MESSAGES),
        "api_version": "1.0.0",
        "status": "operational"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
