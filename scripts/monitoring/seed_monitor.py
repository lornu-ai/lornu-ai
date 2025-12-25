# /// script
# dependencies = ["requests"]
# ///

import os
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
    api_url = os.getenv("API_URL")
    admin_key = os.getenv("ADMIN_API_KEY")
    email = os.getenv("MONITOR_EMAIL")
    password = os.getenv("MONITOR_PASSWORD")

    if not all([api_url, admin_key, email, password]):
        missing = [k for k, v in {
            "API_URL": api_url,
            "ADMIN_API_KEY": admin_key,
            "MONITOR_EMAIL": email,
            "MONITOR_PASSWORD": password
        }.items() if not v]
        print(f"❌ Missing required environment variables: {', '.join(missing)}")
        return

    print(f"🌱 Seeding monitor user: {email}")

    # Payload for creating/resetting the user
    payload = {
        "email": email,
        "password": password,
        "role": "monitor",
        "is_active": True
    }

    # Example API call (Mocked until Auth API is live)
    # response = requests.post(...)

    # Simulating success
    time.sleep(1)
    print(f"✅ Monitor user {payload['email']} ready (Mocked).")

if __name__ == "__main__":
    seed_monitor_user()
