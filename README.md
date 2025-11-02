# Shared Git Hooks

This repository contains shared Git hooks that can be used across multiple projects.

## Setup

To use these hooks in a project, set the `GIT_HOOKS_PATH` environment variable and apply:

```sh
export GIT_HOOKS_PATH="/Users/<you>/Development/git-hooks"
git config core.hooksPath "$GIT_HOOKS_PATH"
```

Or use the helper script in projects:

```sh
export GIT_HOOKS_PATH="/Users/<you>/Development/git-hooks"
npm run hooks:apply
```

## Available Hooks

### `pre-push`

**Purpose**: Protects `main` and `master` branches from direct pushes to `origin`.

**Behavior**:
- Blocks direct pushes to `main` or `master` on `origin` remote
- Allows pushes to feature branches
- Allows pushes to Heroku remotes (for deployment)
- Provides helpful error message guiding users to use feature branches and PRs

**Usage**: Automatically runs on `git push`. Can be bypassed in emergency with `--no-verify` (not recommended).

### `post-push`

**Purpose**: 
- Updates `CYPRESS.md` "Last updated" date after any push
- Runs Cypress tests against Heroku production if push was to Heroku (LifegutDietBuddy only)

**Behavior**:
- Automatically updates `CYPRESS.md` "Last updated" date if file exists
- For LifegutDietBuddy project, runs `npm run test:heroku` after Heroku push
- Stages updated `CYPRESS.md` for next commit

**Usage**: Automatically runs after successful `git push`.

### `pre-commit`

**Purpose**: Runs linting and type checking before commits.

**Behavior**:
- Runs `npm run lint:check` if `package.json` exists
- Runs `npm run tsc` if `package.json` exists and TypeScript is configured
- Blocks commit if checks fail

**Usage**: Automatically runs on `git commit`. Can be bypassed with `--no-verify` (not recommended).

### `prepare-commit-msg`

**Purpose**: Adds helpful commit message templates.

**Behavior**:
- Provides commit message templates for common scenarios
- Can be customized per project

**Usage**: Automatically runs on `git commit`.

## Project-Specific Behavior

Some hooks have project-specific behavior:

- **LifegutDietBuddy**: `post-push` hook runs Heroku Cypress tests and updates `CYPRESS.md`
- **All projects**: `post-push` hook updates `CYPRESS.md` if it exists

## Customization

To customize hooks for a specific project:

1. Create project-specific hook in `.git/hooks/`
2. Or modify the shared hook to detect project name and branch accordingly

Example detection:

```sh
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")

if [ "$REPO_NAME" = "LifegutDietBuddy" ]; then
    # Project-specific logic
fi
```

## Bypassing Hooks

**⚠️ Warning**: Only bypass hooks in emergencies or for automated scripts.

```sh
# Bypass pre-push hook
git push --no-verify origin main

# Bypass pre-commit hook
git commit --no-verify -m "message"
```

## Updating Hooks

1. Make changes to hooks in this repository
2. Commit and push changes
3. Hooks are automatically used by all projects using `core.hooksPath`

## Notes

- Hooks should be executable (`chmod +x`)
- Hooks use `/bin/sh` for portability
- Error messages are colorized for better UX
- Hooks are designed to be non-blocking for deployment flows (Heroku)

## Related Documentation

- **LifegutDietBuddy**: See `CYPRESS.md` for Cypress testing setup
- **Git Hooks**: See [Git Documentation](https://git-scm.com/docs/githooks)

