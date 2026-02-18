import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_full_user_flow(client: AsyncClient):
    # 1. Register Student
    student_data = {
        "email": "student@test.com",
        "password": "password123",
        "full_name": "Test Student",
        "role": "student"
    }
    response = await client.post("/api/v1/users/", json=student_data)
    assert response.status_code == 200
    student_id = response.json()["id"]

    # 2. Register Staff
    staff_data = {
        "email": "staff@test.com",
        "password": "password123",
        "full_name": "Test Staff", 
        "role": "staff"
    }
    response = await client.post("/api/v1/users/", json=staff_data)
    assert response.status_code == 200
    staff_id = response.json()["id"]

    # 3. Student Login
    login_data = {"username": "student@test.com", "password": "password123"}
    response = await client.post("/api/v1/auth/login", data=login_data)
    if response.status_code != 200:
        with open("test_failure.log", "w") as f:
            f.write(f"Status: {response.status_code}\n")
            f.write(f"Body: {response.text}\n")
            f.write(f"Headers: {response.headers}\n")
    assert response.status_code == 200
    student_token = response.json()["access_token"]
    student_headers = {"Authorization": f"Bearer {student_token}"}

    # 4. Create OD Request (Student)
    od_data = {
        "date": "2024-01-01T10:00:00",
        "periods": [1, 2],
        "reason": "Medical appointment",
        "register_number": "REG123",
        "student_name": "Test Student"
    }
    response = await client.post("/api/v1/od-requests/", json=od_data, headers=student_headers)
    assert response.status_code == 200
    od_request_id = response.json()["id"]
    assert response.json()["status"] == "pending"

    # 5. Get My Requests (Student)
    response = await client.get("/api/v1/od-requests/me", headers=student_headers)
    assert response.status_code == 200
    assert len(response.json()) == 1

    # 6. Staff Login
    login_data = {"username": "staff@test.com", "password": "password123"}
    response = await client.post("/api/v1/auth/login", data=login_data)
    assert response.status_code == 200
    staff_token = response.json()["access_token"]
    staff_headers = {"Authorization": f"Bearer {staff_token}"}

    # 7. View Pending Requests (Staff)
    response = await client.get("/api/v1/od-requests/pending", headers=staff_headers)
    assert response.status_code == 200
    assert len(response.json()) >= 1
    assert response.json()[0]["id"] == od_request_id

    # 8. Approve Request (Staff)
    update_data = {"status": "approved"}
    response = await client.put(f"/api/v1/od-requests/{od_request_id}/status", json=update_data, headers=staff_headers)
    assert response.status_code == 200
    assert response.json()["status"] == "approved"
    assert response.json()["approved_by_id"] == staff_id

    # 9. Verify Student Sees Approval
    response = await client.get("/api/v1/od-requests/me", headers=student_headers)
    assert response.json()[0]["status"] == "approved"

    # 10. Check Analytics Dashboard (Staff)
    response = await client.get("/api/v1/analytics/dashboard", headers=staff_headers)
    assert response.status_code == 200
    stats = response.json()
    assert stats["total_requests"] >= 1
    assert "status_distribution" in stats
    
    # 11. Download PDF Report (Staff)
    response = await client.get("/api/v1/analytics/reports/od_summary.pdf", headers=staff_headers)
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert len(response.content) > 0
