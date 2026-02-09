from typing import Any, Annotated
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.models.user import User
from app.services.analytics_service import analytics_service
from app.services.pdf_service import pdf_service
from app.services.od_service import od_service

router = APIRouter()

@router.get("/dashboard", response_model=dict)
async def get_dashboard_stats(
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
) -> Any:
    """
    Get dashboard analytics (Staff/Admin only).
    """
    if current_user.role not in ["staff", "admin", "superuser"]:
        raise HTTPException(status_code=403, detail="Not authorized to view analytics")
        
    stats = await analytics_service.get_stats(db)
    return stats

@router.get("/reports/od_summary.pdf")
async def generate_od_report_pdf(
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
) -> Response:
    """
    Download OD Summary Report as PDF (Staff/Admin only).
    """
    if current_user.role not in ["staff", "admin", "superuser"]:
        raise HTTPException(status_code=403, detail="Not authorized to download reports")
    
    # Fetch data for report
    od_requests = await od_service.get_all(db, limit=1000)
    
    data = [
        {
            "id": r.id, 
            "student_id": r.student_id, 
            "date": r.date.strftime('%Y-%m-%d'), 
            "status": r.status
        } 
        for r in od_requests
    ]
    
    pdf_bytes = pdf_service.generate_od_report(data)
    
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=od_summary_report.pdf"}
    )
