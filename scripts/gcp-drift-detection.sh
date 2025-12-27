#!/bin/bash

# GCP Infrastructure Drift Detection Script
# Addresses GitHub Issue #444: Legacy Cloud Infrastructure Discovery and Terraform Import
# https://github.com/lornu-ai/lornu-ai/issues/444
#
# This script implements Phase 3 requirement: Continuous Drift Detection
# - Scheduled daily GitHub Action "Drift Check"
# - Alerts team via GitHub Issues when manual changes are detected
#
# GitHub CLI Integration:
#   gh workflow run drift-detection.yml
#   ./scripts/gcp-drift-detection.sh
#   gh issue create --title "🚨 Infrastructure Drift Detected" --body "$(cat drift-report.md)"

# Note: We use explicit error handling instead of 'set -e' to control
# when errors should cause script termination.

PROJECT_ID="${GCP_PROJECT_ID:-gcp-lornu-ai}"
TERRAFORM_DIR="${TERRAFORM_DIR:-terraform/gcp}"
DRIFT_REPORT="drift-report.md"
ALERT_THRESHOLD="${DRIFT_ALERT_THRESHOLD:-1}"  # Number of changes to trigger alert

echo "🔍 GCP Infrastructure Drift Detection"
echo "GitHub Issue: https://github.com/lornu-ai/lornu-ai/issues/444"
echo "Project: $PROJECT_ID"
echo "Terraform Directory: $TERRAFORM_DIR"
echo "=================================================================="

# Function to check prerequisites
check_prerequisites() {
    # Check if we're in the right directory
    if [ ! -d "$TERRAFORM_DIR" ]; then
        echo "❌ Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    
    # Check if gcloud is configured
    if ! gcloud auth application-default print-access-token &> /dev/null; then
        echo "❌ No gcloud authentication found"
        exit 1
    fi
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        echo "❌ terraform CLI not found"
        exit 1
    fi
    
    echo "✅ Prerequisites check passed"
}

# Function to run terraform plan and detect drift
detect_drift() {
    echo ""
    echo "🔄 Running Terraform Plan to Detect Drift..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize terraform (in case of new backend configuration)
    terraform init -input=false
    
    # Run terraform plan and capture output
    local plan_output
    local plan_exit_code
    
    if plan_output=$(terraform plan -detailed-exitcode -no-color 2>&1); then
        plan_exit_code=0
        echo "✅ No infrastructure drift detected"
        return 0
    else
        plan_exit_code=$?
        
        case $plan_exit_code in
            1)
                echo "❌ Terraform plan failed with errors"
                echo "$plan_output"
                return 1
                ;;
            2)
                echo "⚠️  Infrastructure drift detected!"
                
                # Count the number of changes
                local changes_count
                changes_count=$(echo "$plan_output" | grep -E "Plan:|# " | wc -l)
                
                echo "📊 Detected $changes_count configuration changes"
                
                # Generate detailed drift report
                generate_drift_report "$plan_output" "$changes_count"
                
                # Check if we should trigger an alert
                if [ "$changes_count" -ge "$ALERT_THRESHOLD" ]; then
                    echo "🚨 Change count ($changes_count) exceeds threshold ($ALERT_THRESHOLD)"
                    return 2  # Drift detected, alert needed
                else
                    echo "ℹ️  Change count ($changes_count) below alert threshold ($ALERT_THRESHOLD)"
                    return 0  # Drift detected but no alert needed
                fi
                ;;
            *)
                echo "❌ Unexpected terraform exit code: $plan_exit_code"
                return 1
                ;;
        esac
    fi
}

# Function to generate detailed drift report
generate_drift_report() {
    local plan_output="$1"
    local changes_count="$2"
    
    echo ""
    echo "📝 Generating Drift Report..."
    
    cat > "$DRIFT_REPORT" << EOF
# 🚨 Infrastructure Drift Detected

**Date:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')  
**Project:** $PROJECT_ID  
**Environment:** GCP Production  
**Changes Detected:** $changes_count  

## 📊 Summary

Configuration drift has been detected in the GCP infrastructure. This indicates that manual changes were made outside of Terraform.

## 🔍 Terraform Plan Output

\`\`\`hcl
$plan_output
\`\`\`

## ⚠️  Impact Assessment

- **Security Risk:** Manual changes bypass peer review and audit trails
- **Compliance Risk:** Changes may not meet security baselines
- **Operational Risk:** Configuration drift can cause deployment failures

## 🔧 Recommended Actions

1. **Immediate:**
   - Review the changes shown above
   - Determine if changes are intentional or accidental
   - If intentional, update Terraform configuration to match

2. **Investigation:**
   - Check GCP Audit Logs to identify who made the changes
   - Verify if changes follow change management procedures
   - Assess if changes impact security or compliance

3. **Remediation:**
   - If changes are valid: Update Terraform configuration and apply
   - If changes are invalid: Run \`terraform apply\` to revert to desired state
   - Update access controls to prevent unauthorized changes

## 📚 References

- **Original Issue:** [#444 Legacy Cloud Infrastructure Discovery](https://github.com/lornu-ai/lornu-ai/issues/444)
- **Terraform Directory:** \`$TERRAFORM_DIR\`
- **GCP Project:** $PROJECT_ID

## 🔄 Next Steps

- [ ] Review and approve/reject the detected changes
- [ ] Update Terraform configuration if changes are valid
- [ ] Apply Terraform to restore desired state if changes are invalid
- [ ] Update IAM policies to prevent future unauthorized changes

---

*This report was automatically generated by the drift detection system.*
*To disable these alerts, update the DRIFT_ALERT_THRESHOLD environment variable.*
EOF

    echo "✅ Drift report generated: $DRIFT_REPORT"
}

# Function to send alerts via GitHub
send_github_alert() {
    echo ""
    echo "🚨 Sending Drift Alert via GitHub..."
    
    if command -v gh &> /dev/null; then
        # Create a GitHub issue for the drift
        local issue_title="🚨 Infrastructure Drift Detected - $(date '+%Y-%m-%d')"
        
        if gh issue create \
            --title "$issue_title" \
            --body-file "$DRIFT_REPORT" \
            --label "infrastructure,drift-alert,priority:high" \
            --assignee "@me"; then
            
            echo "✅ GitHub issue created for drift alert"
            
            # Also comment on the original issue #444
            gh issue comment 444 --body "🚨 **Drift Alert:** Infrastructure changes detected. See related issue: $issue_title"
            
        else
            echo "❌ Failed to create GitHub issue"
            return 1
        fi
        
    else
        echo "⚠️  GitHub CLI not available. Manual alerting required."
        echo "   Please review the drift report: $DRIFT_REPORT"
        return 1
    fi
}

# Function to generate summary for CI/CD
generate_ci_summary() {
    local drift_status="$1"
    
    case $drift_status in
        0)
            echo "✅ No drift detected"
            echo "::notice::Infrastructure state matches Terraform configuration"
            ;;
        1)
            echo "❌ Drift detection failed"
            echo "::error::Unable to complete drift detection due to errors"
            exit 1
            ;;
        2)
            echo "⚠️  Drift detected - alert sent"
            echo "::warning::Infrastructure drift detected and alert created"
            ;;
    esac
}

# Function to cleanup temporary files
cleanup() {
    # Keep drift report for debugging but clean up other temp files
    if [ -f "terraform.tfstate.backup" ]; then
        rm -f "terraform.tfstate.backup"
    fi
}

# Main execution function
main() {
    echo "🚀 Starting Infrastructure Drift Detection..."
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Check prerequisites
    check_prerequisites
    
    # Detect drift
    local drift_result=0
    detect_drift || drift_result=$?
    
    # Handle results based on drift status
    case $drift_result in
        0)
            echo "✅ Drift detection completed - no action needed"
            ;;
        1)
            echo "❌ Drift detection failed"
            exit 1
            ;;
        2)
            echo "⚠️  Drift detected - sending alerts"
            send_github_alert
            ;;
    esac
    
    # Generate CI/CD summary
    generate_ci_summary "$drift_result"
    
    echo ""
    echo "✅ Drift Detection Complete!"
    echo "🔗 GitHub Issue: https://github.com/lornu-ai/lornu-ai/issues/444"
}

# Run main function
main "$@"