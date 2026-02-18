"""
API endpoints for dummy/reference data (staff, timetables, students, etc.)
"""
from fastapi import APIRouter, Query
from typing import Optional
from app.services.dummy_data_service import dummy_data_service
from app.core.logging import logger

router = APIRouter()

@router.get("/staff")
async def get_staff_list():
    """Get comprehensive list of all staff members (20 staff across all departments)"""
    logger.info("Fetching staff list")
    return {"staff": dummy_data_service.get_staff_list(), "total": len(dummy_data_service.get_staff_list())}

@router.get("/staff/{staff_id}")
async def get_staff_by_id(staff_id: str):
    """Get specific staff member by ID"""
    staff_list = dummy_data_service.get_staff_list()
    staff = next((s for s in staff_list if s["id"] == staff_id), None)
    
    if not staff:
        return {"error": "Staff not found"}, 404
    
    return staff

@router.get("/students")
async def get_students_list(
    department: Optional[str] = Query(None, description="Filter by department code (CS, IT, ECE, etc.)"),
    year: Optional[int] = Query(None, description="Filter by year (1-4)"),
    section: Optional[str] = Query(None, description="Filter by section (A, B, C)"),
    limit: int = Query(100, description="Limit number of results"),
    offset: int = Query(0, description="Offset for pagination"),
):
    """Get list of students with optional filters (4320 total students)"""
    logger.info(f"Fetching students list - dept: {department}, year: {year}, section: {section}")
    
    students = dummy_data_service.get_students_list()
    
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
async def get_student_by_register_number(register_number: str):
    """Get specific student by register number"""
    students = dummy_data_service.get_students_list()
    student = next((s for s in students if s["register_number"] == register_number), None)
    
    if not student:
        return {"error": "Student not found"}, 404
    
    return student

@router.get("/timetable")
async def get_timetable(
    section: str = Query("A", description="Section (A, B, C, etc.)"),
    year: int = Query(3, description="Year (1-4)"),
):
    """Get timetable for a specific section and year"""
    logger.info(f"Fetching timetable for Year {year}, Section {section}")
    return dummy_data_service.get_timetable(section=section, year=year)

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
    department: str = Query("CS", description="Department code (CS, IT, ECE, etc.)"),
    year: int = Query(3, description="Year (1-4)"),
):
    """Get subjects for a department and year"""
    logger.info(f"Fetching subjects for {department}, Year {year}")
    subjects = dummy_data_service.get_subjects(department=department, year=year)
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
async def get_system_stats():
    """Get overall system statistics"""
    staff = dummy_data_service.get_staff_list()
    students = dummy_data_service.get_students_list()
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
