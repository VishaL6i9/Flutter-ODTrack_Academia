from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import pandas as pd
from app.models.od_request import ODRequest
from app.core.logging import logger

class AnalyticsService:
    async def get_stats(self, db: AsyncSession) -> dict:
        try:
            # Fetch all OD requests
            result = await db.execute(select(ODRequest))
            od_requests = result.scalars().all()
            
            if not od_requests:
                return {
                    "total_requests": 0,
                    "status_distribution": {},
                    "top_students": []
                }
                
            # Convert to DataFrame
            data = [
                {
                    "id": r.id,
                    "status": r.status,
                    "student_id": r.student_id,
                    "date": r.date
                }
                for r in od_requests
            ]
            df = pd.DataFrame(data)
            
            # 1. Total Requests
            total_requests = len(df)
            
            # 2. Status Distribution
            status_distribution = df['status'].value_counts().to_dict()
            
            # 3. Top Students (by request count)
            top_students = (
                df['student_id']
                .value_counts()
                .head(5)
                .to_dict()
            )
            
            logger.info(f"Generated analytics for {total_requests} requests")
            return {
                "total_requests": total_requests,
                "status_distribution": status_distribution,
                "top_student_ids": top_students # Returns ID:Count mapping
            }
        except Exception as e:
            logger.error(f"Error generating analytics: {e}")
            raise e
        
        return {
            "total_requests": total_requests,
            "status_distribution": status_distribution,
            "top_student_ids": top_students # Returns ID:Count mapping
        }

analytics_service = AnalyticsService()
