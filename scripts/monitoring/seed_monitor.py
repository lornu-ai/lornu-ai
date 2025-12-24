# /// script
# dependencies = ["requests"]
# ///

import os
import requests
import time

def seed_monitor_user():
    """
    Seeds the dedicated monitoring user for Better Stack checks.

    Required Environment Variables:
    - API_URL: Base URL of the API (e.g., https://api.lornu.ai)
    - ADMIN_API_KEY: Secret key to authorize user creation/reset
    - MONITOR_EMAIL: Email for the monitor user
    - MONITOR_PASSWORD: Password for the monitor user
    """
    api_url = os.getenv("API_URL", "http://localhost:8080")
    admin_key = os.getenv("ADMIN_API_KEY")
    email = os.getenv("MONITOR_EMAIL", "monitor@lornu.ai")
    password = os.getenv("MONITOR_PASSWORD")

    if not admin_key:
        print("❌ ADMIN_API_KEY not set. Cannot seed data.")
        return

    print(f"🌱 Seeding monitor user: {email}")

    # Payload for creating/resetting the user
    payload = {
        "email": email,
        "password": password,
        "role": "monitor",
        "is_active": True
    }

    # Example API call (Mocked for now until Auth API is live)
    # response = requests.post(
    #     f"{api_url}/api/v1/admin/users/seed",
    #     json=payload,
    #     headers={"Authorization": f"Bearer {admin_key}"}
    # )

    # Simulating success for the current infrastructure state
    time.sleep(1)
    print(f"✅ Monitor user {email} ready (Mocked).")

if __name__ == "__main__":
    seed_monitor_user()
