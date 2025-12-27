import io
import tempfile
from pathlib import Path
from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient

# Import the specific module where the agent instance is created
from ..src.router import message_router
from ..src.main import app

client = TestClient(app)

@pytest.fixture
def mock_dependencies(monkeypatch):
    """A fixture to mock the image agent and control the temp directory."""
    with tempfile.TemporaryDirectory() as tmpdir:
        # 1. Create a dummy output file for the mock to return
        mock_output_path = Path(tmpdir) / "mocked_output.svg"
        mock_output_path.touch() # Create the file

        # 2. Mock the agent to bypass the 'vtracer' dependency check and the processing method
        monkeypatch.setattr(message_router.image_agent, "enabled", True)
        monkeypatch.setattr(
            message_router.image_agent,
            "process_vectorization",
            MagicMock(return_value=mock_output_path)
        )
        # 3. Mock the cleanup function to prevent it from deleting our temp dir
        monkeypatch.setattr(
            message_router,
            "cleanup_temp_dir",
            MagicMock()
        )

        # 4. Mock mkdtemp to return our predictable, controlled directory
        monkeypatch.setattr(tempfile, "mkdtemp", lambda: tmpdir)
        yield tmpdir

def test_vectorize_path_traversal(mock_dependencies):
    """
    Tests that the /api/vectorize endpoint correctly sanitizes a malicious
    filename and does not write outside the designated temporary directory.
    """
    tmpdir = mock_dependencies
    malicious_filename = "../../../../../tmp/pwned.png"
    sanitized_basename = "pwned.png"

    # The path where the file should be safely written (inside our temp dir)
    expected_safe_path = Path(tmpdir) / sanitized_basename

    # A path outside the temp dir that should NOT be written to
    malicious_unsafe_path = Path("/tmp/pwned.png")

    # Ensure neither path exists before the request
    assert not expected_safe_path.exists(), "Safe path should not exist initially"
    assert not malicious_unsafe_path.exists(), "Unsafe path should not exist initially"

    # Create a dummy file in memory to upload
    file_content = b"dummy content"
    file = io.BytesIO(file_content)

    try:
        response = client.post(
            "/api/vectorize",
            files={"file": (malicious_filename, file, "image/png")}
        )

        # The request should now succeed (200) because the agent is fully mocked
        assert response.status_code == 200, f"API returned {response.status_code} with body: {response.text}"

        # Assert that the file was written to the SAFE path inside the temp dir
        assert expected_safe_path.exists(), "Sanitized file was not created in the temp directory"

        # CRITICAL: Assert that the file was NOT written to the malicious path
        assert not malicious_unsafe_path.exists(), "Vulnerability exploited: File written outside temp directory"

    finally:
        # Clean up any files created during the test
        if expected_safe_path.exists():
            expected_safe_path.unlink()
        if malicious_unsafe_path.exists():
            malicious_unsafe_path.unlink()
