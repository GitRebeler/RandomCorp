"""
Database module for Random Corp API
Handles async SQL Server operations using aioodbc
"""

import os
import logging
import aioodbc
import asyncio
from typing import Dict, List, Optional
from datetime import datetime, timezone
import json

logger = logging.getLogger(__name__)

class DatabaseManager:
    def __init__(self):
        self.host = os.getenv('DB_HOST', 'localhost')
        self.port = os.getenv('DB_PORT', '1433')
        self.database = os.getenv('DB_NAME', 'RandomCorpDB')
        self.username = os.getenv('DB_USER', 'sa')
        self.password = os.getenv('DB_PASSWORD', 'RandomCorp123!')
        self.connection_string = self._build_connection_string()
        self.pool = None
        
    def _build_connection_string(self) -> str:
        """Build SQL Server connection string from environment variables"""
        # Connection string for SQL Server with ODBC driver
        conn_str = (
            f"DRIVER={{ODBC Driver 18 for SQL Server}};"
            f"SERVER={self.host},{self.port};"
            f"DATABASE={self.database};"
            f"UID={self.username};"
            f"PWD={self.password};"
            f"TrustServerCertificate=yes;"
            f"Connection Timeout=30;"
        )
        logger.info(f"🔌 Database connection configured for: {self.host}:{self.port}/{self.database}")
        return conn_str
    
    async def initialize(self):
        """Initialize database connection pool and create tables"""
        try:
            logger.info("🚀 Initializing database connection pool...")
            
            # First, create the database if it doesn't exist
            await self._ensure_database_exists()
            
            # Create connection pool
            self.pool = await aioodbc.create_pool(
                dsn=self.connection_string,
                minsize=1,
                maxsize=10,
                loop=asyncio.get_event_loop()
            )
            
            logger.info("✅ Database connection pool created successfully")
            
            # Create tables if they don't exist
            await self._create_tables()
            
            logger.info("🎯 Database initialization completed")
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize database: {str(e)}")
            raise
    
    async def _ensure_database_exists(self):
        """Create the database if it doesn't exist by connecting to master first"""
        try:
            # Create connection string for master database
            master_conn_str = self.connection_string.replace(f"DATABASE={self.database};", "DATABASE=master;")
            
            logger.info("🔍 Checking if database exists...")
            
            # Connect to master database
            conn = await aioodbc.connect(dsn=master_conn_str)
            
            try:
                cursor = await conn.cursor()
                
                # Check if database exists
                await cursor.execute("""
                    SELECT database_id FROM sys.databases WHERE name = ?
                """, (self.database,))
                
                result = await cursor.fetchone()
                
                if not result:
                    logger.info(f"📝 Creating database: {self.database}")
                    # Create database (cannot use parameters for database name)
                    await cursor.execute(f"CREATE DATABASE [{self.database}]")
                    await conn.commit()
                    logger.info(f"✅ Database {self.database} created successfully")
                else:
                    logger.info(f"✅ Database {self.database} already exists")
                    
            finally:
                await cursor.close()
                await conn.close()
                
        except Exception as e:
            logger.error(f"❌ Failed to ensure database exists: {e}")
            raise
    
    async def _create_tables(self):
        """Create necessary database tables"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    # Create submissions table
                    await cursor.execute("""
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='submissions' AND xtype='U')
                        CREATE TABLE submissions (
                            id BIGINT IDENTITY(1,1) PRIMARY KEY,
                            submission_id NVARCHAR(100) UNIQUE NOT NULL,
                            first_name NVARCHAR(50) NOT NULL,
                            last_name NVARCHAR(50) NOT NULL,
                            message NVARCHAR(500),
                            batch_id NVARCHAR(100),
                            external_data NVARCHAR(MAX),
                            processing_time FLOAT,
                            created_at DATETIME2 DEFAULT GETUTCDATE(),
                            INDEX idx_submission_id (submission_id),
                            INDEX idx_created_at (created_at),
                            INDEX idx_batch_id (batch_id)
                        )
                    """)
                    
                    # Create statistics table
                    await cursor.execute("""
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='statistics' AND xtype='U')
                        CREATE TABLE statistics (
                            id BIGINT IDENTITY(1,1) PRIMARY KEY,
                            stat_name NVARCHAR(100) UNIQUE NOT NULL,
                            stat_value NVARCHAR(MAX),
                            updated_at DATETIME2 DEFAULT GETUTCDATE(),
                            INDEX idx_stat_name (stat_name),
                            INDEX idx_updated_at (updated_at)
                        )
                    """)
                    
                    await conn.commit()
                    logger.info("✅ Database tables created successfully")
                    
        except Exception as e:
            logger.error(f"❌ Failed to create tables: {str(e)}")
            raise
    
    async def save_submission(self, submission_data: Dict) -> str:
        """Save a single submission to the database"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    # Generate unique submission ID if not provided
                    submission_id = submission_data.get('submission_id')
                    if not submission_id:
                        import uuid
                        submission_id = str(uuid.uuid4())[:8]
                    
                    # Insert submission
                    await cursor.execute("""
                        INSERT INTO submissions 
                        (submission_id, first_name, last_name, message, batch_id, external_data, processing_time)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, (
                        submission_id,
                        submission_data.get('first_name', ''),
                        submission_data.get('last_name', ''),
                        submission_data.get('message', ''),
                        submission_data.get('batch_id'),
                        json.dumps(submission_data.get('external_data', {})) if submission_data.get('external_data') else None,
                        submission_data.get('processing_time', 0.0)
                    ))
                    
                    await conn.commit()
                    logger.debug(f"💾 Saved submission: {submission_id}")
                    return submission_id
                    
        except Exception as e:
            logger.error(f"❌ Failed to save submission: {str(e)}")
            raise
    
    async def save_batch_submissions(self, submissions: List[Dict]) -> List[str]:
        """Save multiple submissions to the database"""
        try:
            submission_ids = []
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    for submission_data in submissions:
                        # Generate unique submission ID if not provided
                        submission_id = submission_data.get('submission_id')
                        if not submission_id:
                            import uuid
                            submission_id = str(uuid.uuid4())[:8]
                        
                        submission_ids.append(submission_id)
                        
                        # Insert submission
                        await cursor.execute("""
                            INSERT INTO submissions 
                            (submission_id, first_name, last_name, message, batch_id, external_data, processing_time)
                            VALUES (?, ?, ?, ?, ?, ?, ?)
                        """, (
                            submission_id,
                            submission_data.get('first_name', ''),
                            submission_data.get('last_name', ''),
                            submission_data.get('message', ''),
                            submission_data.get('batch_id'),
                            json.dumps(submission_data.get('external_data', {})) if submission_data.get('external_data') else None,
                            submission_data.get('processing_time', 0.0)
                        ))
                    
                    await conn.commit()
                    logger.info(f"💾 Saved batch of {len(submissions)} submissions")
                    return submission_ids
                    
        except Exception as e:
            logger.error(f"❌ Failed to save batch submissions: {str(e)}")
            raise
    
    async def get_statistics(self) -> Dict:
        """Get current statistics from the database"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    # Get total submissions
                    await cursor.execute("SELECT COUNT(*) FROM submissions")
                    total_count = (await cursor.fetchone())[0]
                    
                    # Get submissions in last 24 hours
                    await cursor.execute("""
                        SELECT COUNT(*) FROM submissions 
                        WHERE created_at >= DATEADD(hour, -24, GETUTCDATE())
                    """)
                    recent_count = (await cursor.fetchone())[0]
                    
                    # Get average processing time
                    await cursor.execute("""
                        SELECT AVG(processing_time) FROM submissions 
                        WHERE processing_time > 0
                    """)
                    avg_time_result = await cursor.fetchone()
                    avg_processing_time = float(avg_time_result[0]) if avg_time_result[0] else 0.0
                    
                    # Get latest submission
                    await cursor.execute("""
                        SELECT TOP 1 submission_id, first_name, last_name, created_at 
                        FROM submissions 
                        ORDER BY created_at DESC
                    """)
                    latest_result = await cursor.fetchone()
                    latest_submission = None
                    if latest_result:
                        latest_submission = {
                            'id': latest_result[0],
                            'name': f"{latest_result[1]} {latest_result[2]}",
                            'timestamp': latest_result[3].isoformat() if latest_result[3] else None
                        }
                    
                    return {
                        'total_submissions': total_count,
                        'recent_submissions': recent_count,
                        'avg_processing_time': round(avg_processing_time, 3),
                        'latest_submission': latest_submission,
                        'last_updated': datetime.now(timezone.utc).isoformat()
                    }
                    
        except Exception as e:
            logger.error(f"❌ Failed to get statistics: {str(e)}")
            raise
    
    async def get_recent_submissions(self, limit: int = 10) -> List[Dict]:
        """Get recent submissions from the database"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(f"""
                        SELECT TOP {limit} 
                            submission_id, first_name, last_name, message, 
                            batch_id, processing_time, created_at
                        FROM submissions 
                        ORDER BY created_at DESC
                    """)
                    
                    results = await cursor.fetchall()
                    submissions = []
                    
                    for row in results:
                        submissions.append({
                            'submission_id': row[0],
                            'first_name': row[1],
                            'last_name': row[2],
                            'message': row[3],
                            'batch_id': row[4],
                            'processing_time': float(row[5]) if row[5] else 0.0,
                            'created_at': row[6].isoformat() if row[6] else None
                        })
                    
                    return submissions
                    
        except Exception as e:
            logger.error(f"❌ Failed to get recent submissions: {str(e)}")
            raise
    
    async def update_statistics(self, stats: Dict):
        """Update statistics in the database"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    for stat_name, stat_value in stats.items():
                        # Convert value to JSON string for storage
                        value_str = json.dumps(stat_value) if not isinstance(stat_value, str) else stat_value
                        
                        # Upsert statistic
                        await cursor.execute("""
                            MERGE statistics AS target
                            USING (SELECT ? AS stat_name, ? AS stat_value) AS source
                            ON target.stat_name = source.stat_name
                            WHEN MATCHED THEN
                                UPDATE SET stat_value = source.stat_value, updated_at = GETUTCDATE()
                            WHEN NOT MATCHED THEN
                                INSERT (stat_name, stat_value) VALUES (source.stat_name, source.stat_value);
                        """, (stat_name, value_str))
                    
                    await conn.commit()
                    logger.debug(f"📊 Updated {len(stats)} statistics")
                    
        except Exception as e:
            logger.error(f"❌ Failed to update statistics: {str(e)}")
            raise
    
    async def close(self):
        """Close database connection pool"""
        if self.pool:
            self.pool.close()
            await self.pool.wait_closed()
            logger.info("🔌 Database connection pool closed")

# Global database manager instance
db_manager = DatabaseManager()
