"""
TDD Tests for GCP Terraform Infrastructure (Issue #281, #282)

This test suite verifies that the GCP infrastructure code:
1. Uses Terraform Cloud workspace 'gcp-lornu-ai' in org 'lornu-ai'
2. Provisions Cloud Run service for backend
3. Provisions Firestore database
4. Sets up IAM with Vertex AI and Firestore permissions
5. Configures OIDC via Workload Identity Federation
6. NO HELM DEPENDENCIES

Test Execution: pytest tests/terraform/test_gcp_infrastructure.py -v
"""

import os
import json
import pytest
from pathlib import Path


class TestGCPTerraformStructure:
    """Test that the GCP Terraform directory structure exists and is valid."""

    def test_gcp_terraform_directory_exists(self):
        """Verify terraform/gcp directory exists."""
        gcp_dir = Path("terraform/gcp")
        assert gcp_dir.exists(), "terraform/gcp directory must exist"
        assert gcp_dir.is_dir(), "terraform/gcp must be a directory"

    def test_main_tf_exists(self):
        """Verify main.tf exists in terraform/gcp."""
        main_tf = Path("terraform/gcp/main.tf")
        assert main_tf.exists(), "terraform/gcp/main.tf must exist"

    def test_backend_tf_exists(self):
        """Verify backend.tf exists and points to TFC."""
        backend_tf = Path("terraform/gcp/backend.tf")
        assert backend_tf.exists(), "terraform/gcp/backend.tf must exist"

        content = backend_tf.read_text()
        assert "cloud" in content, "backend.tf must use Terraform Cloud"
        assert "lornu-ai" in content, "backend.tf must reference 'lornu-ai' organization"
        assert "gcp-lornu-ai" in content, "backend.tf must reference 'gcp-lornu-ai' workspace"

    def test_variables_tf_exists(self):
        """Verify variables.tf exists."""
        variables_tf = Path("terraform/gcp/variables.tf")
        assert variables_tf.exists(), "terraform/gcp/variables.tf must exist"


class TestGCPTerraformConfiguration:
    """Test that Terraform configuration is correct for GCP."""

    def test_provider_is_google(self):
        """Verify google provider is configured."""
        main_tf = Path("terraform/gcp/main.tf")
        content = main_tf.read_text()

        assert "google" in content, "main.tf must include google provider"
        assert "provider \"google\"" in content or 'provider "google"' in content

    def test_no_helm_dependencies(self):
        """Verify NO helm provider or helm_release resources exist."""
        gcp_dir = Path("terraform/gcp")

        for tf_file in gcp_dir.glob("*.tf"):
            content = tf_file.read_text()
            assert "helm" not in content.lower(), f"{tf_file.name} must not contain helm references"

    def test_cloud_run_service_defined(self):
        """Verify Cloud Run service is defined for backend."""
        main_tf = Path("terraform/gcp/main.tf")
        content = main_tf.read_text()

        assert "google_cloud_run_v2_service" in content, "main.tf must define Cloud Run service"
        assert "backend" in content or "lornu" in content, "Cloud Run service must be for backend/lornu"

    def test_firestore_database_defined(self):
        """Verify Firestore database is provisioned."""
        main_tf = Path("terraform/gcp/main.tf")
        content = main_tf.read_text()

        assert "google_firestore_database" in content, "main.tf must provision Firestore database"

    def test_iam_service_account_defined(self):
        """Verify IAM service account exists with proper roles."""
        main_tf = Path("terraform/gcp/main.tf")
        content = main_tf.read_text()

        assert "google_service_account" in content, "main.tf must define service account"
        # Check for required roles in variables or IAM bindings
        assert "aiplatform" in content or "vertex" in content, "Must include Vertex AI permissions"
        assert "datastore" in content or "firestore" in content, "Must include Firestore permissions"


class TestGCPOIDCSetup:
    """Test Workload Identity Federation (OIDC) configuration."""

    def test_workload_identity_pool_defined(self):
        """Verify WIF pool is configured."""
        main_tf = Path("terraform/gcp/main.tf")
        content = main_tf.read_text()

        assert ("google_iam_workload_identity_pool" in content or
                "workload_identity" in content), \
                "main.tf must configure Workload Identity Federation"

    def test_github_oidc_provider_configured(self):
        """Verify GitHub OIDC provider is configured."""
        main_tf = Path("terraform/gcp/main.tf")
        content = main_tf.read_text()

        assert "github" in content.lower(), "OIDC must be configured for GitHub"


class TestGCPCICD:
    """Test CI/CD workflow for GCP deployments."""

    def test_github_workflow_exists(self):
        """Verify .github/workflows/terraform-gcp.yml exists."""
        workflow = Path(".github/workflows/terraform-gcp.yml")
        assert workflow.exists(), "CI/CD workflow for GCP must exist"

    def test_workflow_targets_gcp_develop_branch(self):
        """Verify workflow only runs on gcp-develop branch."""
        workflow = Path(".github/workflows/terraform-gcp.yml")
        content = workflow.read_text()

        assert "gcp-develop" in content, "Workflow must target gcp-develop branch"

    def test_workflow_uses_oidc_not_keys(self):
        """Verify workflow uses OIDC authentication, not JSON keys."""
        workflow = Path(".github/workflows/terraform-gcp.yml")
        content = workflow.read_text()

        assert "google-github-actions/auth" in content, "Must use OIDC auth action"
        assert "credentials_json" not in content.lower(), "Must NOT use static credentials"


class TestGCPTerraformOutputs:
    """Test that required outputs are defined."""

    def test_outputs_file_exists(self):
        """Verify outputs.tf exists."""
        outputs_tf = Path("terraform/gcp/outputs.tf")
        assert outputs_tf.exists(), "terraform/gcp/outputs.tf must exist"

    def test_cloud_run_url_output(self):
        """Verify Cloud Run service URL is exported."""
        outputs_tf = Path("terraform/gcp/outputs.tf")
        content = outputs_tf.read_text()

        assert "output" in content, "outputs.tf must define outputs"
        assert "url" in content.lower() or "endpoint" in content.lower(), \
                "Must output Cloud Run URL"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
