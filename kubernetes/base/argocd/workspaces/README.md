# Workspaces Directory

This directory contains agent environment configurations that are managed via GitOps.

## How It Works

1. **Python Provisioner** commits YAML files to this directory (instead of talking to K8s API directly)
2. **ArgoCD** detects the new/updated files in Git
3. **ArgoCD** syncs them to the cluster
4. **Crossplane** sees the new XAgentEnvironment or XGCPProject objects
5. **Crossplane** provisions the actual AWS/GCP infrastructure

## Example: Creating a New Agent Environment

Instead of using the Kubernetes API directly:
```python
# OLD WAY (Push model)
custom_api.create_cluster_custom_object(
    group="lornu.ai",
    version="v1alpha1",
    plural="xagentenvironments",
    body=agent_config
)
```

Use GitOps (Pull model):
```python
# NEW WAY (GitOps model)
git_repo.index.add(["kubernetes/base/argocd/workspaces/my-agent.yaml"])
git_repo.index.commit("Add agent: my-agent")
git_repo.remote().push()
```

## Directory Structure

```
workspaces/
├── README.md (this file)
├── agent-001.yaml          # Example agent environment
├── agent-002.yaml
└── ...
```

## File Naming Convention

- Use descriptive names: `{agent-name}-{environment}.yaml`
- Examples:
  - `customer-support-prod.yaml`
  - `data-processing-dev.yaml`
  - `ml-training-staging.yaml`

## What Gets Created

When you add a file here, it should contain either:
- An `XGCPProject` (for new GCP projects)
- An `XAgentEnvironment` (for agent environments with AWS/GCP resources)
- Other Crossplane Composite Resources

ArgoCD will sync them, and Crossplane will provision the infrastructure.

