# Description

Please include a summary of the changes and the related issue. Please also include relevant motivation and context. List any dependencies that are required for this change.

## Reviewer(s)


## Linked Issue(s)

Fixes # (issue)

## Labels

Please add the appropriate label(s):
- [ ] `cursor-ide` - If this PR is related to Cursor IDE use, features, extensions, or integrations
- [ ] `antigravity` - If this PR is related to Antigravity use, features, extensions, or integrations
- [ ] `lornu-ai` - If this PR is related to Lornu AI use, features, extensions, or integrations
- [ ] Other labels as needed

## Type of change

Please delete options that are not relevant.

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

# How Has This Been Tested?

Please describe the tests that you ran to verify your changes. Provide instructions so we can reproduce. Please also list any relevant details for your test configuration

- [ ] Test A
- [ ] Test B

**Test Configuration**:

- Browser:
- Node version:
- Environment (development/staging/production):
# Checklist:

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules

## Minimum Viable Commit (MVC) Checklist:

Please review the [PR Discipline Guide](docs/CONTRIBUTION_GUIDE_PR_DISCIPLINE.md) before submitting.

- [ ] I have removed all temporary files (notes.md, scratchpad._, _\_SUMMARY.md, etc.)
- [ ] I have removed all local IDE configuration files (.vscode/, .idea/, etc.)
- [ ] I have verified that all committed files are consumed by the application, CI/CD, or IaC
- [ ] I have run `make ci` and all checks pass
- [ ] I have updated .dockerignore if needed to exclude unnecessary files from build context
- [ ] All documentation changes are in the `docs/` folder (not in root)
- [ ] No build artifacts or dependencies are committed (dist/, node_modules/, **pycache**/, etc.)
