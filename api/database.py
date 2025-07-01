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
        self.host = os.getenv('DB_HOST')
        logger.info(f"🔍 DatabaseManager init - DB_HOST: {self.host}")
        self.port = os.getenv('DB_PORT', '1433')
        self.database = os.getenv('DB_NAME', 'RandomCorpDB')
        self.username = os.getenv('DB_USER', 'sa')
        self.password = os.getenv('DB_PASSWORD', 'RandomCorp123!')
        self.connection_string = None
        self.pool = None
        
        # Only build connection string if host is provided
        if self.host:
            logger.info("🔗 Building database connection string...")
            self.connection_string = self._build_connection_string()
        else:
            logger.info("🚫 No database host configured, skipping connection string")
        
    def _build_connection_string(self) -> str:
        """Build SQL Server connection string from environment variables"""
        # Connection string for SQL Server with ODBC driver
        # Optimized for Kubernetes networking with better timeouts and retry logic
        conn_str = (
            f"DRIVER={{ODBC Driver 18 for SQL Server}};"
            f"SERVER={self.host},{self.port};"
            f"DATABASE={self.database};"
            f"UID={self.username};"
            f"PWD={self.password};"
            f"TrustServerCertificate=yes;"
            f"Connection Timeout=90;"      # Increased to 90 seconds for Kubernetes
            f"Command Timeout=90;"         # Increased command timeout
            f"Login Timeout=60;"           # Increased login timeout to 60 seconds
            f"Encrypt=no;"                 # Disable encryption for internal cluster communication
            f"MultipleActiveResultSets=true;"  # Allow multiple result sets
            f"ConnectRetryCount=5;"        # Increased retry count
            f"ConnectRetryInterval=15;"    # Increased wait time between retries
        )
        logger.info(f"🔌 Database connection configured for: {self.host}:{self.port}/{self.database}")
        return conn_str
    
    async def initialize(self):
        """Initialize database connection pool and create tables with retry logic"""
        if not self.connection_string:
            raise ValueError("Database host not configured - cannot initialize database")
            
        max_retries = 5
        retry_delay = 2  # Start with 2 seconds
        
        for attempt in range(max_retries):
            try:
                logger.info(f"🚀 Initializing database connection pool (attempt {attempt + 1}/{max_retries})...")
                
                # First, test direct connection
                if not await self.test_direct_connection():
                    raise Exception("Direct connection test failed")
                
                # Create the database if it doesn't exist
                await self._ensure_database_exists()
                
                # Create connection pool with better configuration for Kubernetes
                self.pool = await aioodbc.create_pool(
                    dsn=self.connection_string,
                    minsize=2,        # Minimum connections in pool
                    maxsize=10,       # Maximum connections in pool
                    loop=asyncio.get_event_loop()
                )
                
                logger.info("✅ Database connection pool created successfully")
                
                # Test the connection pool
                await self._test_connection_pool()
                
                # Create tables if they don't exist
                await self._create_tables()
                
                logger.info("🎯 Database initialization completed successfully")
                return  # Success, exit retry loop
                
            except Exception as e:
                logger.error(f"❌ Database initialization attempt {attempt + 1} failed: {str(e)}")
                
                # Clean up failed pool
                if self.pool:
                    try:
                        self.pool.close()
                        await self.pool.wait_closed()
                    except:
                        pass
                    self.pool = None
                
                if attempt < max_retries - 1:
                    logger.info(f"⏳ Retrying in {retry_delay} seconds...")
                    await asyncio.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    logger.error("💥 All database initialization attempts failed!")
                    raise Exception(f"Failed to initialize database after {max_retries} attempts: {str(e)}")
    
    async def _test_connection_pool(self):
        """Test the connection pool to ensure it's working"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute("SELECT 1")
                    result = await cursor.fetchone()
                    if result[0] != 1:
                        raise Exception("Connection test query failed")
            logger.info("✅ Database connection pool test successful")
        except Exception as e:
            logger.error(f"❌ Database connection pool test failed: {str(e)}")
            raise
    
    async def _ensure_database_exists(self):
        """Create the database if it doesn't exist by connecting to master first"""
        try:
            # Create connection string for master database
            master_conn_str = self.connection_string.replace(f"DATABASE={self.database};", "DATABASE=master;")
            
            logger.info("🔍 Checking if database exists...")
            
            # Connect to master database with autocommit
            conn = await aioodbc.connect(dsn=master_conn_str, autocommit=True)
            
            try:
                cursor = await conn.cursor()
                
                # Check if database exists
                await cursor.execute("""
                    SELECT database_id FROM sys.databases WHERE name = ?
                """, (self.database,))
                
                result = await cursor.fetchone()
                
                if not result:
                    logger.info(f"📝 Creating database: {self.database}")
                    try:
                        # Create database (cannot use parameters for database name)
                        await cursor.execute(f"CREATE DATABASE [{self.database}]")
                        logger.info(f"✅ Database {self.database} created successfully")
                    except Exception as create_e:
                        # Handle race condition where another pod created the DB in the meantime
                        if "already exists" in str(create_e):
                            logger.warning(f"⚠️ Database {self.database} was created by another process.")
                        else:
                            raise create_e
                else:
                    logger.info(f"✅ Database {self.database} already exists")
                    
                await cursor.close()
                
            finally:
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
                      # Create app_statistics table (avoiding 'statistics' reserved keyword)
                    await cursor.execute("""
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='app_statistics' AND xtype='U')
                        CREATE TABLE app_statistics (
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
            error_msg = str(e).lower()
            if any(keyword in error_msg for keyword in ['connection', 'network', 'timeout', 'unreachable', 'refused']):
                logger.error(f"❌ Database connection error saving submission: {str(e)}")
            else:
                logger.error(f"❌ Database error saving submission: {str(e)}")
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
            error_msg = str(e).lower()
            if any(keyword in error_msg for keyword in ['connection', 'network', 'timeout', 'unreachable', 'refused']):
                logger.error(f"❌ Database connection error getting statistics: {str(e)}")
            else:
                logger.error(f"❌ Database error getting statistics: {str(e)}")
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
    
    async def get_paginated_submissions(self, limit: int = 10, offset: int = 0) -> List[Dict]:
        """Get paginated submissions from the database"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute(f"""
                        SELECT 
                            submission_id, first_name, last_name, message, 
                            batch_id, processing_time, created_at
                        FROM submissions 
                        ORDER BY created_at DESC
                        OFFSET {offset} ROWS
                        FETCH NEXT {limit} ROWS ONLY
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
            logger.error(f"❌ Failed to get paginated submissions: {str(e)}")
            raise
    
    async def get_submissions_count(self) -> int:
        """Get total count of submissions"""
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute("SELECT COUNT(*) FROM submissions")
                    result = await cursor.fetchone()
                    return int(result[0]) if result else 0
                    
        except Exception as e:
            logger.error(f"❌ Failed to get submissions count: {str(e)}")
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
                            MERGE app_statistics AS target
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
    
    async def is_database_available(self) -> bool:
        """Check if database connection is available and healthy"""
        if not self.connection_string:
            logger.debug("🚫 No connection string configured")
            return False
            
        if not self.pool:
            logger.debug("🚫 No connection pool available")
            return False
            
        try:
            async with self.pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    await cursor.execute("SELECT 1")
                    result = await cursor.fetchone()
                    is_healthy = result[0] == 1
                    if is_healthy:
                        logger.debug("✅ Database health check passed")
                    else:
                        logger.warning("⚠️ Database health check failed - unexpected result")
                    return is_healthy
        except Exception as e:
            logger.warning(f"⚠️ Database health check failed: {str(e)}")
            return False
    
    async def _ensure_connection_pool(self):
        """Ensure connection pool is available, reinitialize if needed"""
        if not self.pool or not await self.is_database_available():
            logger.warning("🔄 Database connection lost, attempting to reinitialize...")
            try:
                if self.pool:
                    self.pool.close()
                    await self.pool.wait_closed()
                
                await self.initialize()
                logger.info("✅ Database connection pool reinitialized successfully")
            except Exception as e:
                logger.error(f"❌ Failed to reinitialize database connection: {str(e)}")
                raise

    async def test_direct_connection(self) -> bool:
        """Test direct database connection without using the pool"""
        if not self.connection_string:
            logger.warning("🚫 No connection string configured for direct test")
            return False
            
        try:
            # Test connection to master database first
            master_conn_str = self.connection_string.replace(f"DATABASE={self.database};", "DATABASE=master;")
            logger.info("🔍 Testing direct database connection to master...")
            
            conn = await aioodbc.connect(dsn=master_conn_str)
            try:
                cursor = await conn.cursor()
                await cursor.execute("SELECT 1")
                result = await cursor.fetchone()
                await cursor.close()
                success = result[0] == 1
                if success:
                    logger.info("✅ Direct database connection test successful")
                else:
                    logger.warning("⚠️ Direct database connection test failed - unexpected result")
                return success
            finally:
                await conn.close()
        except Exception as e:
            logger.error(f"❌ Direct database connection test failed: {str(e)}")
            return False

# Global database manager instance - initialized lazily
db_manager = None

def get_db_manager():
    """Get or create the database manager instance"""
    global db_manager
    if db_manager is None:
        db_manager = DatabaseManager()
    return db_manager
