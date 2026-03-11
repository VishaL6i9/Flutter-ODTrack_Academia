"""
API endpoints for dummy/reference data (staff, timetables, students, etc.)
"""
from fastapi import APIRouter, Query, Depends
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_db
from app.services.dummy_data_service import dummy_data_service
from app.core.logging import logger

router = APIRouter()

@router.get("/staff")
async def get_staff_list(db: AsyncSession = Depends(get_db)):
    """Get list of all staff members from DB"""
    logger.info("Fetching staff list")
    staff = await dummy_data_service.get_staff_list(db)
    return {"staff": staff, "total": len(staff)}

@router.get("/staff/{staff_id}")
async def get_staff_by_id(staff_id: str, db: AsyncSession = Depends(get_db)):
    """Get specific staff member by ID from DB"""
    staff_list = await dummy_data_service.get_staff_list(db)
    staff = next((s for s in staff_list if s["id"] == staff_id), None)
    
    if not staff:
        return {"error": "Staff not found"}, 404
    
    return staff

@router.get("/staff/{staff_id}/timetable")
async def get_staff_timetable(staff_id: str, db: AsyncSession = Depends(get_db)):
    """Get personal timetable for a specific staff member"""
    logger.info(f"Fetching timetable for staff: {staff_id}")
    return await dummy_data_service.get_staff_timetable(db, staff_id=staff_id)

@router.get("/students")
async def get_students_list(
    department: Optional[str] = Query(None),
    year: Optional[int] = Query(None),
    section: Optional[str] = Query(None),
    limit: int = Query(100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db)
):
    """Get list of students from DB"""
    logger.info(f"Fetching students list")
    
    students = await dummy_data_service.get_students_list(db)
    
    # Apply filters
    if department:
        students = [s for s in students if s["department"].startswith(department) or department in s["register_number"]]
    if year:
        students = [s for s in students if s["year"] == year]
    if section:
        students = [s for s in students if s["section"] == section]
    
    total = len(students)
    students = students[offset:offset + limit]
    
    return {
        "students": students,
        "total": total,
        "limit": limit,
        "offset": offset,
        "has_more": offset + limit < total
    }

@router.get("/students/{register_number}")
async def get_student_by_register_number(register_number: str, db: AsyncSession = Depends(get_db)):
    """Get specific student by register number from DB"""
    students = await dummy_data_service.get_students_list(db)
    student = next((s for s in students if s["register_number"] == register_number), None)
    
    if not student:
        return {"error": "Student not found"}, 404
    
    return student

@router.get("/timetable")
async def get_timetable(
    section: str = Query("A"),
    year: int = Query(2),
    db: AsyncSession = Depends(get_db)
):
    """Get timetable from DB"""
    logger.info(f"Fetching timetable")
    return await dummy_data_service.get_timetable(db, section=section, year=year)

@router.get("/departments")
async def get_departments():
    """Get comprehensive list of all departments (6 departments)"""
    logger.info("Fetching departments list")
    departments = dummy_data_service.get_departments()
    return {
        "departments": departments,
        "total": len(departments)
    }

@router.get("/departments/{dept_code}")
async def get_department_by_code(dept_code: str):
    """Get specific department by code"""
    departments = dummy_data_service.get_departments()
    dept = next((d for d in departments if d["code"] == dept_code.upper()), None)
    
    if not dept:
        return {"error": "Department not found"}, 404
    
    return dept

@router.get("/subjects")
async def get_subjects(
    department: str = Query("CS"),
    year: int = Query(2),
    db: AsyncSession = Depends(get_db)
):
    """Get subjects from DB"""
    logger.info(f"Fetching subjects")
    subjects = await dummy_data_service.get_subjects(db, department=department, year=year)
    return {
        "subjects": subjects,
        "department": department,
        "year": year,
        "total": len(subjects)
    }

@router.get("/academic-calendar")
async def get_academic_calendar():
    """Get comprehensive academic calendar with all events"""
    logger.info("Fetching academic calendar")
    return dummy_data_service.get_academic_calendar()

@router.get("/stats")
async def get_system_stats(db: AsyncSession = Depends(get_db)):
    """Get overall system statistics from DB"""
    staff = await dummy_data_service.get_staff_list(db)
    students = await dummy_data_service.get_students_list(db)
    departments = dummy_data_service.get_departments()
    
    return {
        "total_staff": len(staff),
        "total_students": len(students),
        "total_departments": len(departments),
        "students_per_department": 720,
        "sections_per_year": 3,
        "students_per_section": 60,
        "academic_year": "2025-2026",
        "current_semester": "Odd Semester",
    }
