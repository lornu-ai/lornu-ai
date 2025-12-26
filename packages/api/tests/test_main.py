from fastapi.testclient import TestClient
from ..src.main import app

client = TestClient(app)

def test_contact_form_success_when_email_disabled():
    """
    Tests that the /api/contact endpoint returns a consistent success message
    when the email service is disabled.
    """
    response = client.post("/api/contact", json={
        "name": "Test User",
        "email": "test@example.com",
        "message": "This is a test message."
    })
    assert response.status_code == 200
    json_response = response.json()
    assert json_response["status"] == "success"
    assert "message" in json_response
