"""
Dummy data service for staff, timetables, and other reference data.
This data is used for demo purposes and can be replaced with real data later.
"""
from typing import List, Dict, Any
from datetime import datetime, time

class DummyDataService:
    """Service to provide comprehensive dummy/mock data for the entire system"""
    
    @staticmethod
    def get_staff_list() -> List[Dict[str, Any]]:
        """Get comprehensive list of staff members across all departments"""
        return [
            # Computer Science Department
            {
                "id": "staff_001",
                "name": "Dr. Rajesh Kumar",
                "email": "rajesh.kumar@odtrack.edu",
                "department": "Computer Science",
                "designation": "Professor & HOD",
                "phone": "+91-9876543210",
                "office": "CS-301",
                "specialization": "Machine Learning, Artificial Intelligence, Deep Learning",
                "experience_years": 18,
                "qualification": "Ph.D. in Computer Science",
                "subjects": ["Machine Learning", "Artificial Intelligence", "Deep Learning"],
                "available_hours": ["Mon 10-12", "Wed 2-4", "Fri 10-12"],
            },
            {
                "id": "staff_002",
                "name": "Dr. Priya Sharma",
                "email": "priya.sharma@odtrack.edu",
                "department": "Computer Science",
                "designation": "Associate Professor",
                "phone": "+91-9876543211",
                "office": "CS-302",
                "specialization": "Data Structures, Algorithms, Competitive Programming",
                "experience_years": 12,
                "qualification": "Ph.D. in Computer Science",
                "subjects": ["Data Structures", "Algorithms", "Design & Analysis of Algorithms"],
                "available_hours": ["Tue 11-1", "Thu 3-5", "Fri 2-4"],
            },
            {
                "id": "staff_003",
                "name": "Prof. Arun Patel",
                "email": "arun.patel@odtrack.edu",
                "department": "Computer Science",
                "designation": "Assistant Professor",
                "phone": "+91-9876543212",
                "office": "CS-303",
                "specialization": "Web Development, Cloud Computing, DevOps",
                "experience_years": 8,
                "qualification": "M.Tech in Computer Science",
                "subjects": ["Web Technologies", "Cloud Computing", "Software Engineering"],
                "available_hours": ["Mon 2-4", "Wed 10-12", "Thu 2-4"],
            },
            {
                "id": "staff_004",
                "name": "Dr. Anita Desai",
                "email": "anita.desai@odtrack.edu",
                "department": "Computer Science",
                "designation": "Associate Professor",
                "phone": "+91-9876543213",
                "office": "CS-304",
                "specialization": "Computer Networks, IoT, Wireless Communication",
                "experience_years": 14,
                "qualification": "Ph.D. in Computer Networks",
                "subjects": ["Computer Networks", "IoT", "Network Security"],
                "available_hours": ["Mon 11-1", "Tue 2-4", "Thu 10-12"],
            },
            {
                "id": "staff_005",
                "name": "Prof. Vikram Singh",
                "email": "vikram.singh@odtrack.edu",
                "department": "Computer Science",
                "designation": "Assistant Professor",
                "phone": "+91-9876543214",
                "office": "CS-305",
                "specialization": "Operating Systems, System Programming, Linux",
                "experience_years": 6,
                "qualification": "M.Tech in Computer Science",
                "subjects": ["Operating Systems", "System Programming", "Unix/Linux"],
                "available_hours": ["Tue 10-12", "Wed 3-5", "Fri 11-1"],
            },
            
            # Information Technology Department
            {
                "id": "staff_006",
                "name": "Dr. Meena Reddy",
                "email": "meena.reddy@odtrack.edu",
                "department": "Information Technology",
                "designation": "Professor & HOD",
                "phone": "+91-9876543215",
                "office": "IT-201",
                "specialization": "Cybersecurity, Ethical Hacking, Information Security",
                "experience_years": 20,
                "qualification": "Ph.D. in Information Security",
                "subjects": ["Cybersecurity", "Ethical Hacking", "Cryptography"],
                "available_hours": ["Mon 10-12", "Wed 2-4", "Fri 10-12"],
            },
            {
                "id": "staff_007",
                "name": "Prof. Suresh Nair",
                "email": "suresh.nair@odtrack.edu",
                "department": "Information Technology",
                "designation": "Associate Professor",
                "phone": "+91-9876543216",
                "office": "IT-202",
                "specialization": "Database Systems, Big Data, Data Analytics",
                "experience_years": 11,
                "qualification": "M.Tech in Information Technology",
                "subjects": ["Database Management", "Big Data", "Data Warehousing"],
                "available_hours": ["Tue 11-1", "Thu 2-4", "Fri 3-5"],
            },
            {
                "id": "staff_008",
                "name": "Dr. Kavita Iyer",
                "email": "kavita.iyer@odtrack.edu",
                "department": "Information Technology",
                "designation": "Associate Professor",
                "phone": "+91-9876543217",
                "office": "IT-203",
                "specialization": "Mobile Computing, Android Development, iOS Development",
                "experience_years": 9,
                "qualification": "Ph.D. in Mobile Computing",
                "subjects": ["Mobile Application Development", "Android", "iOS Development"],
                "available_hours": ["Mon 2-4", "Wed 11-1", "Thu 10-12"],
            },
            {
                "id": "staff_009",
                "name": "Prof. Ramesh Gupta",
                "email": "ramesh.gupta@odtrack.edu",
                "department": "Information Technology",
                "designation": "Assistant Professor",
                "phone": "+91-9876543218",
                "office": "IT-204",
                "specialization": "Software Testing, Quality Assurance, Agile",
                "experience_years": 7,
                "qualification": "M.Tech in Software Engineering",
                "subjects": ["Software Testing", "Quality Assurance", "Agile Methodologies"],
                "available_hours": ["Tue 10-12", "Wed 2-4", "Fri 11-1"],
            },
            
            # Electronics and Communication Department
            {
                "id": "staff_010",
                "name": "Dr. Venkat Rao",
                "email": "venkat.rao@odtrack.edu",
                "department": "Electronics and Communication",
                "designation": "Professor & HOD",
                "phone": "+91-9876543219",
                "office": "ECE-101",
                "specialization": "VLSI Design, Embedded Systems, Digital Electronics",
                "experience_years": 22,
                "qualification": "Ph.D. in VLSI Design",
                "subjects": ["VLSI Design", "Embedded Systems", "Digital Signal Processing"],
                "available_hours": ["Mon 10-12", "Wed 3-5", "Fri 10-12"],
            },
            {
                "id": "staff_011",
                "name": "Dr. Sunita Rao",
                "email": "sunita.rao@odtrack.edu",
                "department": "Electronics and Communication",
                "designation": "Associate Professor",
                "phone": "+91-9876543220",
                "office": "ECE-102",
                "specialization": "Communication Systems, Wireless Networks, 5G",
                "experience_years": 13,
                "qualification": "Ph.D. in Communication Engineering",
                "subjects": ["Communication Systems", "Wireless Communication", "Antenna Theory"],
                "available_hours": ["Tue 11-1", "Thu 2-4", "Fri 2-4"],
            },
            {
                "id": "staff_012",
                "name": "Prof. Karthik Menon",
                "email": "karthik.menon@odtrack.edu",
                "department": "Electronics and Communication",
                "designation": "Assistant Professor",
                "phone": "+91-9876543221",
                "office": "ECE-103",
                "specialization": "Microprocessors, Microcontrollers, ARM Architecture",
                "experience_years": 8,
                "qualification": "M.Tech in Embedded Systems",
                "subjects": ["Microprocessors", "Microcontrollers", "Embedded C"],
                "available_hours": ["Mon 2-4", "Wed 10-12", "Thu 3-5"],
            },
            
            # Electrical and Electronics Department
            {
                "id": "staff_013",
                "name": "Dr. Lakshmi Devi",
                "email": "lakshmi.devi@odtrack.edu",
                "department": "Electrical and Electronics",
                "designation": "Professor & HOD",
                "phone": "+91-9876543222",
                "office": "EEE-101",
                "specialization": "Power Systems, Renewable Energy, Smart Grid",
                "experience_years": 19,
                "qualification": "Ph.D. in Power Systems",
                "subjects": ["Power Systems", "Renewable Energy", "Electrical Machines"],
                "available_hours": ["Mon 11-1", "Wed 2-4", "Fri 10-12"],
            },
            {
                "id": "staff_014",
                "name": "Prof. Arjun Reddy",
                "email": "arjun.reddy@odtrack.edu",
                "department": "Electrical and Electronics",
                "designation": "Associate Professor",
                "phone": "+91-9876543223",
                "office": "EEE-102",
                "specialization": "Control Systems, Automation, Robotics",
                "experience_years": 10,
                "qualification": "M.Tech in Control Systems",
                "subjects": ["Control Systems", "Industrial Automation", "PLC Programming"],
                "available_hours": ["Tue 10-12", "Thu 11-1", "Fri 3-5"],
            },
            {
                "id": "staff_015",
                "name": "Dr. Pooja Nambiar",
                "email": "pooja.nambiar@odtrack.edu",
                "department": "Electrical and Electronics",
                "designation": "Associate Professor",
                "phone": "+91-9876543224",
                "office": "EEE-103",
                "specialization": "Power Electronics, Electric Vehicles, Battery Technology",
                "experience_years": 11,
                "qualification": "Ph.D. in Power Electronics",
                "subjects": ["Power Electronics", "Electric Drives", "Battery Management"],
                "available_hours": ["Mon 2-4", "Wed 11-1", "Thu 2-4"],
            },
            
            # Mechanical Engineering Department
            {
                "id": "staff_016",
                "name": "Dr. Sanjay Kulkarni",
                "email": "sanjay.kulkarni@odtrack.edu",
                "department": "Mechanical Engineering",
                "designation": "Professor & HOD",
                "phone": "+91-9876543225",
                "office": "MECH-101",
                "specialization": "Thermal Engineering, Heat Transfer, IC Engines",
                "experience_years": 21,
                "qualification": "Ph.D. in Thermal Engineering",
                "subjects": ["Thermodynamics", "Heat Transfer", "IC Engines"],
                "available_hours": ["Mon 10-12", "Wed 3-5", "Fri 11-1"],
            },
            {
                "id": "staff_017",
                "name": "Prof. Deepak Joshi",
                "email": "deepak.joshi@odtrack.edu",
                "department": "Mechanical Engineering",
                "designation": "Associate Professor",
                "phone": "+91-9876543226",
                "office": "MECH-102",
                "specialization": "Manufacturing, CAD/CAM, CNC Machining",
                "experience_years": 12,
                "qualification": "M.Tech in Manufacturing",
                "subjects": ["Manufacturing Processes", "CAD/CAM", "CNC Programming"],
                "available_hours": ["Tue 11-1", "Thu 2-4", "Fri 10-12"],
            },
            {
                "id": "staff_018",
                "name": "Dr. Neha Agarwal",
                "email": "neha.agarwal@odtrack.edu",
                "department": "Mechanical Engineering",
                "designation": "Assistant Professor",
                "phone": "+91-9876543227",
                "office": "MECH-103",
                "specialization": "Robotics, Mechatronics, Automation",
                "experience_years": 7,
                "qualification": "Ph.D. in Robotics",
                "subjects": ["Robotics", "Mechatronics", "Industrial Automation"],
                "available_hours": ["Mon 2-4", "Wed 10-12", "Thu 3-5"],
            },
            
            # Civil Engineering Department
            {
                "id": "staff_019",
                "name": "Dr. Prakash Rao",
                "email": "prakash.rao@odtrack.edu",
                "department": "Civil Engineering",
                "designation": "Professor & HOD",
                "phone": "+91-9876543228",
                "office": "CIVIL-101",
                "specialization": "Structural Engineering, Earthquake Engineering, Design",
                "experience_years": 23,
                "qualification": "Ph.D. in Structural Engineering",
                "subjects": ["Structural Analysis", "Design of Structures", "Earthquake Engineering"],
                "available_hours": ["Mon 11-1", "Wed 2-4", "Fri 10-12"],
            },
            {
                "id": "staff_020",
                "name": "Prof. Madhavi Iyer",
                "email": "madhavi.iyer@odtrack.edu",
                "department": "Civil Engineering",
                "designation": "Associate Professor",
                "phone": "+91-9876543229",
                "office": "CIVIL-102",
                "specialization": "Environmental Engineering, Water Resources, Sustainability",
                "experience_years": 14,
                "qualification": "M.Tech in Environmental Engineering",
                "subjects": ["Environmental Engineering", "Water Resources", "Waste Management"],
                "available_hours": ["Tue 10-12", "Thu 11-1", "Fri 2-4"],
            },
        ]
    
    @staticmethod
    def get_timetable(section: str = "A", year: int = 3) -> Dict[str, Any]:
        """Get comprehensive timetable for a specific section and year"""
        
        # Define timetables for all departments and years
        timetables = {
            "CS": {
                1: {  # First Year
                    "schedule": {
                        "Monday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "Mathematics-I", "staff": "Dr. Math Professor", "room": "CS-101"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Physics", "staff": "Dr. Physics Prof", "room": "PHY-201"},
                            {"period": 3, "time": "11:00-11:50", "subject": "C Programming", "staff": "Prof. Arun Patel", "room": "CS-102"},
                            {"period": 4, "time": "12:00-12:50", "subject": "English", "staff": "Prof. English Teacher", "room": "ENG-101"},
                            {"period": 5, "time": "14:00-14:50", "subject": "C Programming Lab", "staff": "Prof. Arun Patel", "room": "CS-Lab1"},
                            {"period": 6, "time": "15:00-15:50", "subject": "C Programming Lab", "staff": "Prof. Arun Patel", "room": "CS-Lab1"},
                        ],
                        "Tuesday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "Chemistry", "staff": "Dr. Chem Prof", "room": "CHEM-101"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Mathematics-I", "staff": "Dr. Math Professor", "room": "CS-101"},
                            {"period": 3, "time": "11:00-11:50", "subject": "Engineering Drawing", "staff": "Prof. Drawing Teacher", "room": "DRAW-101"},
                            {"period": 4, "time": "12:00-12:50", "subject": "C Programming", "staff": "Prof. Arun Patel", "room": "CS-102"},
                            {"period": 5, "time": "14:00-14:50", "subject": "Physics Lab", "staff": "Dr. Physics Prof", "room": "PHY-Lab"},
                            {"period": 6, "time": "15:00-15:50", "subject": "Physics Lab", "staff": "Dr. Physics Prof", "room": "PHY-Lab"},
                        ],
                        "Wednesday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "English", "staff": "Prof. English Teacher", "room": "ENG-101"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Physics", "staff": "Dr. Physics Prof", "room": "PHY-201"},
                            {"period": 3, "time": "11:00-11:50", "subject": "Mathematics-I", "staff": "Dr. Math Professor", "room": "CS-101"},
                            {"period": 4, "time": "12:00-12:50", "subject": "Chemistry", "staff": "Dr. Chem Prof", "room": "CHEM-101"},
                            {"period": 5, "time": "14:00-14:50", "subject": "Chemistry Lab", "staff": "Dr. Chem Prof", "room": "CHEM-Lab"},
                            {"period": 6, "time": "15:00-15:50", "subject": "Chemistry Lab", "staff": "Dr. Chem Prof", "room": "CHEM-Lab"},
                        ],
                        "Thursday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "C Programming", "staff": "Prof. Arun Patel", "room": "CS-102"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Engineering Drawing", "staff": "Prof. Drawing Teacher", "room": "DRAW-101"},
                            {"period": 3, "time": "11:00-11:50", "subject": "Physics", "staff": "Dr. Physics Prof", "room": "PHY-201"},
                            {"period": 4, "time": "12:00-12:50", "subject": "Mathematics-I", "staff": "Dr. Math Professor", "room": "CS-101"},
                            {"period": 5, "time": "14:00-14:50", "subject": "Workshop", "staff": "Workshop Instructor", "room": "Workshop"},
                            {"period": 6, "time": "15:00-15:50", "subject": "Workshop", "staff": "Workshop Instructor", "room": "Workshop"},
                        ],
                        "Friday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "Mathematics-I", "staff": "Dr. Math Professor", "room": "CS-101"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Chemistry", "staff": "Dr. Chem Prof", "room": "CHEM-101"},
                            {"period": 3, "time": "11:00-11:50", "subject": "English", "staff": "Prof. English Teacher", "room": "ENG-101"},
                            {"period": 4, "time": "12:00-12:50", "subject": "C Programming", "staff": "Prof. Arun Patel", "room": "CS-102"},
                            {"period": 5, "time": "14:00-14:50", "subject": "Sports/Library", "staff": "-", "room": "Ground/Library"},
                            {"period": 6, "time": "15:00-15:50", "subject": "Sports/Library", "staff": "-", "room": "Ground/Library"},
                        ],
                    }
                },
                3: {  # Third Year (5th Semester)
                    "schedule": {
                        "Monday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "Machine Learning", "staff": "Dr. Rajesh Kumar", "room": "CS-101"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Web Technologies", "staff": "Prof. Arun Patel", "room": "CS-102"},
                            {"period": 3, "time": "11:00-11:50", "subject": "Database Management", "staff": "Prof. Suresh Nair", "room": "IT-201"},
                            {"period": 4, "time": "12:00-12:50", "subject": "Software Engineering", "staff": "Dr. Priya Sharma", "room": "CS-103"},
                            {"period": 5, "time": "14:00-14:50", "subject": "ML Lab", "staff": "Dr. Rajesh Kumar", "room": "CS-Lab1"},
                            {"period": 6, "time": "15:00-15:50", "subject": "ML Lab", "staff": "Dr. Rajesh Kumar", "room": "CS-Lab1"},
                        ],
                        "Tuesday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "Cybersecurity", "staff": "Dr. Meena Reddy", "room": "IT-202"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Machine Learning", "staff": "Dr. Rajesh Kumar", "room": "CS-101"},
                            {"period": 3, "time": "11:00-11:50", "subject": "Web Technologies", "staff": "Prof. Arun Patel", "room": "CS-102"},
                            {"period": 4, "time": "12:00-12:50", "subject": "Database Management", "staff": "Prof. Suresh Nair", "room": "IT-201"},
                            {"period": 5, "time": "14:00-14:50", "subject": "Web Lab", "staff": "Prof. Arun Patel", "room": "CS-Lab2"},
                            {"period": 6, "time": "15:00-15:50", "subject": "Web Lab", "staff": "Prof. Arun Patel", "room": "CS-Lab2"},
                        ],
                        "Wednesday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "Software Engineering", "staff": "Dr. Priya Sharma", "room": "CS-103"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Cybersecurity", "staff": "Dr. Meena Reddy", "room": "IT-202"},
                            {"period": 3, "time": "11:00-11:50", "subject": "Machine Learning", "staff": "Dr. Rajesh Kumar", "room": "CS-101"},
                            {"period": 4, "time": "12:00-12:50", "subject": "Web Technologies", "staff": "Prof. Arun Patel", "room": "CS-102"},
                            {"period": 5, "time": "14:00-14:50", "subject": "Seminar", "staff": "Various", "room": "Auditorium"},
                            {"period": 6, "time": "15:00-15:50", "subject": "Library", "staff": "-", "room": "Library"},
                        ],
                        "Thursday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "Database Management", "staff": "Prof. Suresh Nair", "room": "IT-201"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Software Engineering", "staff": "Dr. Priya Sharma", "room": "CS-103"},
                            {"period": 3, "time": "11:00-11:50", "subject": "Cybersecurity", "staff": "Dr. Meena Reddy", "room": "IT-202"},
                            {"period": 4, "time": "12:00-12:50", "subject": "Machine Learning", "staff": "Dr. Rajesh Kumar", "room": "CS-101"},
                            {"period": 5, "time": "14:00-14:50", "subject": "DBMS Lab", "staff": "Prof. Suresh Nair", "room": "IT-Lab1"},
                            {"period": 6, "time": "15:00-15:50", "subject": "DBMS Lab", "staff": "Prof. Suresh Nair", "room": "IT-Lab1"},
                        ],
                        "Friday": [
                            {"period": 1, "time": "09:00-09:50", "subject": "Web Technologies", "staff": "Prof. Arun Patel", "room": "CS-102"},
                            {"period": 2, "time": "10:00-10:50", "subject": "Database Management", "staff": "Prof. Suresh Nair", "room": "IT-201"},
                            {"period": 3, "time": "11:00-11:50", "subject": "Software Engineering", "staff": "Dr. Priya Sharma", "room": "CS-103"},
                            {"period": 4, "time": "12:00-12:50", "subject": "Cybersecurity", "staff": "Dr. Meena Reddy", "room": "IT-202"},
                            {"period": 5, "time": "14:00-14:50", "subject": "Project Work", "staff": "All Faculty", "room": "CS-Labs"},
                            {"period": 6, "time": "15:00-15:50", "subject": "Project Work", "staff": "All Faculty", "room": "CS-Labs"},
                        ],
                    }
                },
            }
        }
        
        # Get department code from section (assuming format like "CS3A")
        dept = "CS"  # Default to CS
        
        # Get timetable or return default
        dept_timetables = timetables.get(dept, timetables["CS"])
        year_timetable = dept_timetables.get(year, dept_timetables[3])
        
        return {
            "section": section,
            "year": year,
            "semester": (year * 2) - 1,  # Odd semester
            "academic_year": "2025-2026",
            "department": "Computer Science",
            **year_timetable
        }
    
    @staticmethod
    def get_departments() -> List[Dict[str, Any]]:
        """Get comprehensive list of all departments"""
        return [
            {
                "id": "dept_cs",
                "name": "Computer Science",
                "code": "CS",
                "hod": "Dr. Rajesh Kumar",
                "hod_email": "rajesh.kumar@odtrack.edu",
                "hod_phone": "+91-9876543210",
                "building": "CS Block",
                "floor": "3rd Floor",
                "total_staff": 5,
                "total_students": 720,  # 60 students × 3 sections × 4 years
                "established_year": 2005,
                "accreditation": "NBA Accredited",
                "labs": ["AI/ML Lab", "Web Development Lab", "Programming Lab", "Project Lab"],
            },
            {
                "id": "dept_it",
                "name": "Information Technology",
                "code": "IT",
                "hod": "Dr. Meena Reddy",
                "hod_email": "meena.reddy@odtrack.edu",
                "hod_phone": "+91-9876543215",
                "building": "IT Block",
                "floor": "2nd Floor",
                "total_staff": 4,
                "total_students": 720,
                "established_year": 2007,
                "accreditation": "NBA Accredited",
                "labs": ["Cybersecurity Lab", "Database Lab", "Mobile App Lab", "Testing Lab"],
            },
            {
                "id": "dept_ece",
                "name": "Electronics and Communication",
                "code": "ECE",
                "hod": "Dr. Venkat Rao",
                "hod_email": "venkat.rao@odtrack.edu",
                "hod_phone": "+91-9876543219",
                "building": "ECE Block",
                "floor": "1st Floor",
                "total_staff": 3,
                "total_students": 720,
                "established_year": 2003,
                "accreditation": "NBA Accredited",
                "labs": ["VLSI Lab", "Communication Lab", "Embedded Systems Lab", "DSP Lab"],
            },
            {
                "id": "dept_eee",
                "name": "Electrical and Electronics",
                "code": "EEE",
                "hod": "Dr. Lakshmi Devi",
                "hod_email": "lakshmi.devi@odtrack.edu",
                "hod_phone": "+91-9876543222",
                "building": "EEE Block",
                "floor": "Ground Floor",
                "total_staff": 3,
                "total_students": 720,
                "established_year": 2004,
                "accreditation": "NBA Accredited",
                "labs": ["Power Systems Lab", "Control Systems Lab", "Machines Lab", "Power Electronics Lab"],
            },
            {
                "id": "dept_mech",
                "name": "Mechanical Engineering",
                "code": "MECH",
                "hod": "Dr. Sanjay Kulkarni",
                "hod_email": "sanjay.kulkarni@odtrack.edu",
                "hod_phone": "+91-9876543225",
                "building": "Mechanical Block",
                "floor": "Ground Floor",
                "total_staff": 3,
                "total_students": 720,
                "established_year": 2002,
                "accreditation": "NBA Accredited",
                "labs": ["CAD/CAM Lab", "Thermal Lab", "Manufacturing Lab", "Robotics Lab"],
            },
            {
                "id": "dept_civil",
                "name": "Civil Engineering",
                "code": "CIVIL",
                "hod": "Dr. Prakash Rao",
                "hod_email": "prakash.rao@odtrack.edu",
                "hod_phone": "+91-9876543228",
                "building": "Civil Block",
                "floor": "1st Floor",
                "total_staff": 2,
                "total_students": 720,
                "established_year": 2001,
                "accreditation": "NBA Accredited",
                "labs": ["Structural Lab", "Surveying Lab", "Environmental Lab", "Geotechnical Lab"],
            },
        ]
    
    @staticmethod
    def get_subjects(department: str = "CS", year: int = 3) -> List[Dict[str, Any]]:
        """Get comprehensive subjects for a department and year"""
        subjects_map = {
            "CS": {
                1: [
                    {"code": "MA101", "name": "Mathematics-I (Calculus)", "credits": 4, "type": "Theory", "staff": "Dr. Math Professor"},
                    {"code": "PH101", "name": "Engineering Physics", "credits": 3, "type": "Theory", "staff": "Dr. Physics Prof"},
                    {"code": "CH101", "name": "Engineering Chemistry", "credits": 3, "type": "Theory", "staff": "Dr. Chem Prof"},
                    {"code": "CS101", "name": "Programming in C", "credits": 3, "type": "Theory", "staff": "Prof. Arun Patel"},
                    {"code": "EG101", "name": "Engineering Graphics", "credits": 3, "type": "Theory", "staff": "Prof. Drawing Teacher"},
                    {"code": "EN101", "name": "English Communication", "credits": 2, "type": "Theory", "staff": "Prof. English Teacher"},
                    {"code": "CS151", "name": "C Programming Lab", "credits": 2, "type": "Lab", "staff": "Prof. Arun Patel"},
                    {"code": "PH151", "name": "Physics Lab", "credits": 1, "type": "Lab", "staff": "Dr. Physics Prof"},
                    {"code": "CH151", "name": "Chemistry Lab", "credits": 1, "type": "Lab", "staff": "Dr. Chem Prof"},
                    {"code": "WS151", "name": "Workshop Practice", "credits": 2, "type": "Lab", "staff": "Workshop Instructor"},
                ],
                2: [
                    {"code": "MA201", "name": "Mathematics-II (Linear Algebra)", "credits": 4, "type": "Theory", "staff": "Dr. Math Professor"},
                    {"code": "CS201", "name": "Data Structures", "credits": 4, "type": "Theory", "staff": "Dr. Priya Sharma"},
                    {"code": "CS202", "name": "Object Oriented Programming", "credits": 3, "type": "Theory", "staff": "Prof. Vikram Singh"},
                    {"code": "CS203", "name": "Digital Logic Design", "credits": 3, "type": "Theory", "staff": "Dr. Anita Desai"},
                    {"code": "CS204", "name": "Computer Organization", "credits": 3, "type": "Theory", "staff": "Prof. Vikram Singh"},
                    {"code": "EN201", "name": "Technical Writing", "credits": 2, "type": "Theory", "staff": "Prof. English Teacher"},
                    {"code": "CS251", "name": "Data Structures Lab", "credits": 2, "type": "Lab", "staff": "Dr. Priya Sharma"},
                    {"code": "CS252", "name": "OOP Lab (Java)", "credits": 2, "type": "Lab", "staff": "Prof. Vikram Singh"},
                    {"code": "CS253", "name": "Digital Logic Lab", "credits": 1, "type": "Lab", "staff": "Dr. Anita Desai"},
                ],
                3: [
                    {"code": "CS501", "name": "Machine Learning", "credits": 4, "type": "Theory", "staff": "Dr. Rajesh Kumar"},
                    {"code": "CS502", "name": "Web Technologies", "credits": 3, "type": "Theory", "staff": "Prof. Arun Patel"},
                    {"code": "CS503", "name": "Database Management Systems", "credits": 4, "type": "Theory", "staff": "Prof. Suresh Nair"},
                    {"code": "CS504", "name": "Software Engineering", "credits": 3, "type": "Theory", "staff": "Dr. Priya Sharma"},
                    {"code": "CS505", "name": "Cybersecurity", "credits": 3, "type": "Theory", "staff": "Dr. Meena Reddy"},
                    {"code": "CS506", "name": "Computer Networks", "credits": 3, "type": "Theory", "staff": "Dr. Anita Desai"},
                    {"code": "CS551", "name": "Machine Learning Lab", "credits": 2, "type": "Lab", "staff": "Dr. Rajesh Kumar"},
                    {"code": "CS552", "name": "Web Technologies Lab", "credits": 2, "type": "Lab", "staff": "Prof. Arun Patel"},
                    {"code": "CS553", "name": "DBMS Lab", "credits": 2, "type": "Lab", "staff": "Prof. Suresh Nair"},
                ],
                4: [
                    {"code": "CS701", "name": "Artificial Intelligence", "credits": 4, "type": "Theory", "staff": "Dr. Rajesh Kumar"},
                    {"code": "CS702", "name": "Cloud Computing", "credits": 3, "type": "Theory", "staff": "Prof. Arun Patel"},
                    {"code": "CS703", "name": "Compiler Design", "credits": 3, "type": "Theory", "staff": "Dr. Priya Sharma"},
                    {"code": "CS704", "name": "Mobile Application Development", "credits": 3, "type": "Theory", "staff": "Dr. Kavita Iyer"},
                    {"code": "CS705", "name": "Blockchain Technology", "credits": 3, "type": "Theory", "staff": "Prof. Arun Patel"},
                    {"code": "CS751", "name": "AI Lab", "credits": 2, "type": "Lab", "staff": "Dr. Rajesh Kumar"},
                    {"code": "CS752", "name": "Cloud Lab", "credits": 2, "type": "Lab", "staff": "Prof. Arun Patel"},
                    {"code": "CS799", "name": "Major Project", "credits": 6, "type": "Project", "staff": "All Faculty"},
                ],
            },
            "IT": {
                1: [
                    {"code": "MA101", "name": "Mathematics-I", "credits": 4, "type": "Theory", "staff": "Dr. Math Professor"},
                    {"code": "PH101", "name": "Engineering Physics", "credits": 3, "type": "Theory", "staff": "Dr. Physics Prof"},
                    {"code": "CH101", "name": "Engineering Chemistry", "credits": 3, "type": "Theory", "staff": "Dr. Chem Prof"},
                    {"code": "IT101", "name": "Programming Fundamentals", "credits": 3, "type": "Theory", "staff": "Prof. Ramesh Gupta"},
                    {"code": "EG101", "name": "Engineering Graphics", "credits": 3, "type": "Theory", "staff": "Prof. Drawing Teacher"},
                    {"code": "EN101", "name": "English Communication", "credits": 2, "type": "Theory", "staff": "Prof. English Teacher"},
                ],
                3: [
                    {"code": "IT501", "name": "Information Security", "credits": 4, "type": "Theory", "staff": "Dr. Meena Reddy"},
                    {"code": "IT502", "name": "Big Data Analytics", "credits": 3, "type": "Theory", "staff": "Prof. Suresh Nair"},
                    {"code": "IT503", "name": "Mobile Computing", "credits": 3, "type": "Theory", "staff": "Dr. Kavita Iyer"},
                    {"code": "IT504", "name": "Software Testing", "credits": 3, "type": "Theory", "staff": "Prof. Ramesh Gupta"},
                    {"code": "IT505", "name": "Internet of Things", "credits": 3, "type": "Theory", "staff": "Dr. Anita Desai"},
                ],
            },
            "ECE": {
                3: [
                    {"code": "EC501", "name": "VLSI Design", "credits": 4, "type": "Theory", "staff": "Dr. Venkat Rao"},
                    {"code": "EC502", "name": "Embedded Systems", "credits": 3, "type": "Theory", "staff": "Prof. Karthik Menon"},
                    {"code": "EC503", "name": "Communication Systems", "credits": 4, "type": "Theory", "staff": "Dr. Sunita Rao"},
                    {"code": "EC504", "name": "Digital Signal Processing", "credits": 3, "type": "Theory", "staff": "Dr. Venkat Rao"},
                    {"code": "EC505", "name": "Microprocessors", "credits": 3, "type": "Theory", "staff": "Prof. Karthik Menon"},
                ],
            },
            "EEE": {
                3: [
                    {"code": "EE501", "name": "Power Systems", "credits": 4, "type": "Theory", "staff": "Dr. Lakshmi Devi"},
                    {"code": "EE502", "name": "Control Systems", "credits": 3, "type": "Theory", "staff": "Prof. Arjun Reddy"},
                    {"code": "EE503", "name": "Power Electronics", "credits": 4, "type": "Theory", "staff": "Dr. Pooja Nambiar"},
                    {"code": "EE504", "name": "Electrical Machines", "credits": 3, "type": "Theory", "staff": "Dr. Lakshmi Devi"},
                    {"code": "EE505", "name": "Renewable Energy", "credits": 3, "type": "Theory", "staff": "Dr. Lakshmi Devi"},
                ],
            },
            "MECH": {
                3: [
                    {"code": "ME501", "name": "Thermodynamics", "credits": 4, "type": "Theory", "staff": "Dr. Sanjay Kulkarni"},
                    {"code": "ME502", "name": "Manufacturing Processes", "credits": 3, "type": "Theory", "staff": "Prof. Deepak Joshi"},
                    {"code": "ME503", "name": "Fluid Mechanics", "credits": 4, "type": "Theory", "staff": "Dr. Sanjay Kulkarni"},
                    {"code": "ME504", "name": "CAD/CAM", "credits": 3, "type": "Theory", "staff": "Prof. Deepak Joshi"},
                    {"code": "ME505", "name": "Robotics", "credits": 3, "type": "Theory", "staff": "Dr. Neha Agarwal"},
                ],
            },
            "CIVIL": {
                3: [
                    {"code": "CE501", "name": "Structural Analysis", "credits": 4, "type": "Theory", "staff": "Dr. Prakash Rao"},
                    {"code": "CE502", "name": "Geotechnical Engineering", "credits": 3, "type": "Theory", "staff": "Prof. Madhavi Iyer"},
                    {"code": "CE503", "name": "Environmental Engineering", "credits": 4, "type": "Theory", "staff": "Prof. Madhavi Iyer"},
                    {"code": "CE504", "name": "Transportation Engineering", "credits": 3, "type": "Theory", "staff": "Dr. Prakash Rao"},
                    {"code": "CE505", "name": "Water Resources", "credits": 3, "type": "Theory", "staff": "Prof. Madhavi Iyer"},
                ],
            },
        }
        
        return subjects_map.get(department, {}).get(year, [])
    
    @staticmethod
    def get_academic_calendar() -> Dict[str, Any]:
        """Get comprehensive academic calendar with all events"""
        return {
            "academic_year": "2025-2026",
            "semester": "Odd Semester (Sem 1, 3, 5, 7)",
            "semester_start": "2025-07-15",
            "semester_end": "2025-12-15",
            "events": [
                # July 2025
                {"date": "2025-07-15", "event": "Semester Start - Odd Semester", "type": "academic", "description": "Classes begin for all years"},
                {"date": "2025-07-20", "event": "Orientation for First Years", "type": "academic", "description": "Welcome program for new students"},
                
                # August 2025
                {"date": "2025-08-15", "event": "Independence Day", "type": "holiday", "description": "National Holiday"},
                {"date": "2025-08-20", "event": "Internal Assessment-1 Begins", "type": "exam", "description": "First internal exams start"},
                {"date": "2025-08-27", "event": "Internal Assessment-1 Ends", "type": "exam", "description": "First internal exams end"},
                
                # September 2025
                {"date": "2025-09-05", "event": "Teachers' Day", "type": "event", "description": "Celebration of Teachers' Day"},
                {"date": "2025-09-15", "event": "Mid-Term Exams Start", "type": "exam", "description": "Mid-semester examinations begin"},
                {"date": "2025-09-25", "event": "Mid-Term Exams End", "type": "exam", "description": "Mid-semester examinations end"},
                
                # October 2025
                {"date": "2025-10-02", "event": "Gandhi Jayanti", "type": "holiday", "description": "National Holiday"},
                {"date": "2025-10-10", "event": "Internal Assessment-2 Begins", "type": "exam", "description": "Second internal exams start"},
                {"date": "2025-10-17", "event": "Internal Assessment-2 Ends", "type": "exam", "description": "Second internal exams end"},
                {"date": "2025-10-20", "event": "Dussehra", "type": "holiday", "description": "Festival Holiday"},
                {"date": "2025-10-24", "event": "Diwali Break Start", "type": "holiday", "description": "Diwali vacation begins"},
                {"date": "2025-10-28", "event": "Diwali Break End", "type": "holiday", "description": "Classes resume after Diwali"},
                
                # November 2025
                {"date": "2025-11-01", "event": "Technical Fest - TechnoVision 2025", "type": "event", "description": "Annual technical festival"},
                {"date": "2025-11-10", "event": "Internal Assessment-3 Begins", "type": "exam", "description": "Third internal exams start"},
                {"date": "2025-11-17", "event": "Internal Assessment-3 Ends", "type": "exam", "description": "Third internal exams end"},
                {"date": "2025-11-15", "event": "End-Semester Exams Start", "type": "exam", "description": "Final examinations begin"},
                {"date": "2025-11-30", "event": "End-Semester Exams End", "type": "exam", "description": "Final examinations end"},
                
                # December 2025
                {"date": "2025-12-05", "event": "Project Presentations", "type": "academic", "description": "Final year project presentations"},
                {"date": "2025-12-10", "event": "Results Declaration", "type": "academic", "description": "Semester results announced"},
                {"date": "2025-12-15", "event": "Semester End", "type": "academic", "description": "Odd semester concludes"},
                {"date": "2025-12-20", "event": "Winter Break Start", "type": "holiday", "description": "Winter vacation begins"},
                {"date": "2025-12-25", "event": "Christmas", "type": "holiday", "description": "Christmas Holiday"},
                
                # January 2026
                {"date": "2026-01-01", "event": "New Year", "type": "holiday", "description": "New Year Holiday"},
                {"date": "2026-01-05", "event": "Winter Break End", "type": "holiday", "description": "Winter vacation ends"},
                {"date": "2026-01-10", "event": "Even Semester Start", "type": "academic", "description": "Classes begin for even semester"},
                {"date": "2026-01-26", "event": "Republic Day", "type": "holiday", "description": "National Holiday"},
                
                # February 2026
                {"date": "2026-02-14", "event": "Cultural Fest - Kaleidoscope 2026", "type": "event", "description": "Annual cultural festival"},
                {"date": "2026-02-20", "event": "Sports Week", "type": "event", "description": "Inter-department sports competitions"},
                
                # March 2026
                {"date": "2026-03-08", "event": "International Women's Day", "type": "event", "description": "Women's Day celebrations"},
                {"date": "2026-03-15", "event": "Holi", "type": "holiday", "description": "Festival Holiday"},
                {"date": "2026-03-25", "event": "Industry Visit Week", "type": "academic", "description": "Industrial visits for all departments"},
                
                # April 2026
                {"date": "2026-04-01", "event": "Placement Drive Begins", "type": "academic", "description": "Campus recruitment starts"},
                {"date": "2026-04-10", "event": "Guest Lecture Series", "type": "academic", "description": "Industry expert lectures"},
                {"date": "2026-04-14", "event": "Ambedkar Jayanti", "type": "holiday", "description": "National Holiday"},
                
                # May 2026
                {"date": "2026-05-01", "event": "May Day", "type": "holiday", "description": "Labour Day"},
                {"date": "2026-05-10", "event": "End-Semester Exams Start", "type": "exam", "description": "Final examinations begin"},
                {"date": "2026-05-25", "event": "End-Semester Exams End", "type": "exam", "description": "Final examinations end"},
                
                # June 2026
                {"date": "2026-06-01", "event": "Results Declaration", "type": "academic", "description": "Even semester results announced"},
                {"date": "2026-06-10", "event": "Summer Break Start", "type": "holiday", "description": "Summer vacation begins"},
                {"date": "2026-06-15", "event": "Summer Internship Program", "type": "academic", "description": "Internship opportunities for students"},
            ],
            "important_dates": {
                "registration_deadline": "2025-07-10",
                "fee_payment_deadline": "2025-07-20",
                "exam_form_submission": "2025-10-30",
                "revaluation_deadline": "2025-12-20",
            },
            "exam_schedule": {
                "internal_1": {"start": "2025-08-20", "end": "2025-08-27"},
                "mid_term": {"start": "2025-09-15", "end": "2025-09-25"},
                "internal_2": {"start": "2025-10-10", "end": "2025-10-17"},
                "internal_3": {"start": "2025-11-10", "end": "2025-11-17"},
                "end_semester": {"start": "2025-11-15", "end": "2025-11-30"},
            },
            "holidays": {
                "total_holidays": 25,
                "national_holidays": 8,
                "festival_holidays": 10,
                "semester_breaks": 7,
            }
        }
    
    @staticmethod
    def get_students_list() -> List[Dict[str, Any]]:
        """Get comprehensive list of students across all departments and years"""
        students = []
        departments = ["CS", "IT", "ECE", "EEE", "MECH", "CIVIL"]
        sections = ["A", "B", "C"]
        years = [1, 2, 3, 4]
        
        student_id_counter = 1
        
        for dept in departments:
            for year in years:
                for section in sections:
                    # 60 students per section
                    for roll_num in range(1, 61):
                        reg_number = f"{dept}{year}{section}{roll_num:03d}"
                        students.append({
                            "id": f"student_{student_id_counter:04d}",
                            "register_number": reg_number,
                            "name": f"Student {reg_number}",
                            "email": f"{reg_number.lower()}@student.odtrack.edu",
                            "department": {
                                "CS": "Computer Science",
                                "IT": "Information Technology",
                                "ECE": "Electronics and Communication",
                                "EEE": "Electrical and Electronics",
                                "MECH": "Mechanical Engineering",
                                "CIVIL": "Civil Engineering",
                            }[dept],
                            "year": year,
                            "section": section,
                            "phone": f"+91-98765{student_id_counter:05d}",
                            "date_of_birth": f"200{5-year}-{(student_id_counter % 12) + 1:02d}-{(student_id_counter % 28) + 1:02d}",
                            "blood_group": ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"][student_id_counter % 8],
                            "parent_phone": f"+91-97654{student_id_counter:05d}",
                            "address": f"{student_id_counter} Student Street, College Town",
                        })
                        student_id_counter += 1
        
        return students


dummy_data_service = DummyDataService()
