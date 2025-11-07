# Git Hooks for Secure & Clean Code 🛡️✨

Blazingly fast, production-ready git hooks for modern teams:

- 🛡️ **Block secrets, API keys & credentials in every commit/push**
- 🚦 **Catch errors early: TypeScript, Lint, Build & Cypress tests auto-run at the right time**
- 📝 **Beautiful commit messages — fully supports [Conventional Commits](https://www.conventionalcommits.org) & [Gitmoji](https://gitmoji.dev/)**
- ⚡ Zero config for most Node, TypeScript & Rails projects
- 🚀 Easy install, totally portable, and proven across real-world codebases

_Protect your main branch. Ship with confidence. Focus on building, not fixing leaks/reviewing noisy PRs._

---

## Installation

### Quick Install

1. **Clone or copy this repository** to a location on your machine:
   ```bash
   git clone <repository-url> ~/git-hooks
   # or simply copy the directory to your desired location
   ```

2. **Install hooks in your repository**:
   ```bash
   cd /path/to/your/repo
   cp ~/git-hooks/pre-commit .git/hooks/
   cp ~/git-hooks/pre-push .git/hooks/
   cp ~/git-hooks/prepare-commit-msg .git/hooks/
   cp -r ~/git-hooks/shared .git/hooks/
   ```

3. **Make hooks executable**:
   ```bash
   chmod +x .git/hooks/pre-commit
   chmod +x .git/hooks/pre-push
   chmod +x .git/hooks/prepare-commit-msg
   chmod +x .git/hooks/shared/*.sh
   ```

### Automated Install Script

You can create a simple install script to set up hooks across multiple repositories:

```bash
#!/bin/bash
HOOKS_DIR="$HOME/Development/__git-hooks"
REPO_DIR="$1"

if [ -z "$REPO_DIR" ]; then
    echo "Usage: $0 <repository-path>"
    exit 1
fi

cd "$REPO_DIR" || exit 1

cp "$HOOKS_DIR/pre-commit" .git/hooks/
cp "$HOOKS_DIR/pre-push" .git/hooks/
cp "$HOOKS_DIR/prepare-commit-msg" .git/hooks/
cp -r "$HOOKS_DIR/shared" .git/hooks/

chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
chmod +x .git/hooks/prepare-commit-msg
chmod +x .git/hooks/shared/*.sh

echo "✅ Git hooks installed successfully in $REPO_DIR"
```

## Features

### 🔒 Security Checks (`pre-commit` & `pre-push`)

Automatically scans your code for sensitive data before committing or pushing:

- **API Keys**: Google, OpenAI, AWS, Firebase
- **Database Connection Strings**: MongoDB, PostgreSQL, MySQL, Redis
- **Slack Tokens & Webhooks**: Bot tokens, user tokens, webhook URLs
- **Private Keys**: RSA, DSA, EC, OpenSSH private keys
- **Environment Variables**: Next.js, React, Vite env vars with actual values
- **Authentication Credentials**: Passwords, secrets, tokens

**What happens**: If sensitive data is detected, the commit/push is blocked with helpful error messages and suggestions on how to fix it.

### 📝 Code Quality Checks (`pre-commit`)

#### TypeScript Type Checking
- Automatically runs `tsc --noEmit` for TypeScript projects
- Detects TypeScript configuration files (`tsconfig.json`, `tsconfig.app.json`, etc.)
- Blocks commits if type errors are found

#### Linting
- Runs `npm run lint` if available in your project
- Ensures code follows your project's style guidelines
- Blocks commits if linting errors are found

**Note**: Some game repositories (TrafficRun, CrossyRoad, SpaceShooter) are permanently excluded from TypeScript and linting checks.

### 🧪 Testing (`pre-push`)

#### Cypress Tests
- Automatically runs Cypress tests before pushing
- Checks if dev server is running on `localhost:3000`
- **Main branch**: Tests are required (push blocked if server not running)
- **Other branches**: Tests are optional (warning only if server not running)

#### Build Checks
- Automatically runs build checks when pushing to Heroku
- Detects Heroku remotes and ensures production readiness
- Blocks push if build fails

### 🎯 Commit Message Helper (`prepare-commit-msg`)

Interactive helper for creating consistent commit messages using Gitmoji and Conventional Commits format.

#### Features:
- **Gitmoji Support**: Suggests appropriate emojis based on staged files
- **Conventional Commits**: Encourages format like `feat(scope): description`
- **Smart Suggestions**: Analyzes staged files and suggests commit type
- **Interactive Prompt**: Guides you through creating a proper commit message
- **Help System**: Type `help` to see full Gitmoji reference

#### Usage:
```bash
git commit
# Hook will prompt you with suggestions based on your staged files
```

#### Examples:
- `✨ feat(auth): add OAuth2 login`
- `🐛 fix(api): resolve user validation error`
- `📝 docs(readme): update installation guide`
- `🎨 style(ui): improve button hover effects`
- `♻️ refactor(utils): simplify date formatting`

### 📋 Project Type Detection

The hooks automatically detect your project type:
- **TypeScript Projects**: Detects `tsconfig.json` files
- **Rails Projects**: Detects `Gemfile` and `config/application.rb`
- **Repository Name**: Extracts repo name for context-aware checks

## Hook Execution Flow

### Pre-Commit Hook
1. 🔒 Security check on staged files
2. 📝 TypeScript type checking (if TypeScript project)
3. 🧹 Linting (if lint script available)
4. ✅ Commit proceeds if all checks pass

### Pre-Push Hook
1. 🔒 Security check on commits being pushed
2. 🧪 Cypress tests (if available and server running)
3. 🔨 Build check (if pushing to Heroku)
4. ✅ Push proceeds if all checks pass

### Prepare-Commit-Msg Hook
1. 📋 Analyzes staged files
2. 💡 Suggests appropriate Gitmoji and commit type
3. 🎯 Prompts for commit message
4. ✏️ Writes formatted message to commit file

## Bypassing Hooks (Not Recommended)

If you absolutely need to bypass hooks (use with caution):

```bash
# Skip pre-commit hook
git commit --no-verify

# Skip pre-push hook
git push --no-verify
```

⚠️ **Warning**: Only bypass hooks if you're certain about what you're doing. The security checks are especially important!

## Customization

### Excluding Repositories

To exclude specific repositories from certain checks, edit `shared/quality-checks.sh`:

```bash
# Example: Skip TypeScript checks for a specific repo
if [ "$repo_name" = "YourRepoName" ]; then
    echo "${YELLOW}⚠️  Skipping TypeScript check for $repo_name${NC}"
    return 0
fi
```

### Adding Custom Security Patterns

Edit `shared/security-check.sh` to add new sensitive data patterns:

```bash
SENSITIVE_PATTERNS=(
    # ... existing patterns ...
    "your-custom-pattern-here"  # Add your pattern
)
```

### Modifying Commit Message Format

Edit `prepare-commit-msg` to change the commit message format or add new suggestions.

## Troubleshooting

### Hooks not running?
- Ensure hooks are executable: `chmod +x .git/hooks/*`
- Check that hooks are in `.git/hooks/` directory
- Verify hook file names match exactly (no `.sample` extension)

### TypeScript check fails but code works?
- Run `npx tsc --noEmit` manually to see errors
- Check your `tsconfig.json` configuration
- Some projects may need to be excluded (see Customization)

### Cypress tests not running?
- Ensure dev server is running: `npm run dev`
- Check that `cypress` directory exists
- Verify `package.json` has a `test` script

### Security check false positives?
- Review the detected pattern
- Consider adding the file to `.gitignore` if it's a test fixture
- Adjust patterns in `shared/security-check.sh` if needed

## Best Practices

1. **Never commit sensitive data**: Use environment variables or secrets management
2. **Keep hooks updated**: Pull latest changes from this repository regularly
3. **Fix issues locally**: Don't bypass hooks, fix the underlying issues
4. **Use consistent commit messages**: Follow the Gitmoji and Conventional Commits format
5. **Run tests before pushing**: Ensure your dev server is running for Cypress tests

## Contributing

Feel free to submit issues or pull requests to improve these hooks!

## License

This collection of git hooks is provided as-is for use across your repositories.

