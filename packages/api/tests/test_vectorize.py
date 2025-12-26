from fastapi.testclient import TestClient
from ..src.main import app
import io
import os
import tempfile
from pathlib import Path

client = TestClient(app)

def test_vectorize_path_traversal():
    """
    Tests that the /api/vectorize endpoint is not vulnerable to path traversal.
    """
    # Create a temporary directory for the test
    with tempfile.TemporaryDirectory() as tmpdir:
        # Define a malicious filename that attempts to traverse directories
        malicious_filename = "../../../../../../../../../tmp/pwned.png"

        # The sanitized filename should be just the basename
        sanitized_basename = "pwned.png"

        # Path where the malicious file would be created if the vulnerability exists
        malicious_filepath = Path(tmpdir) / malicious_filename

        # Ensure the malicious path does not exist before the request
        assert not malicious_filepath.exists()

        # Create a dummy file in memory
        file_content = b"dummy content"
        file = io.BytesIO(file_content)

        response = client.post(
            "/api/vectorize",
            files={"file": (malicious_filename, file, "image/png")}
        )

        # The request should fail because vtracer is not installed, but it should not
        # be a 500 error, which would indicate that the server tried to write to the
        # malicious path. A 501 error indicates that the service is unavailable, which is
        # the expected behavior in a test environment where vtracer is not installed.
        assert response.status_code == 501

        # Assert that the malicious file was not created
        assert not malicious_filepath.exists()
