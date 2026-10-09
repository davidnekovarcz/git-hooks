# Git Hooks for Secure & Clean Code 🔐 (by ⚡Smarlify)

- 🌟 Used by "Vibe-Coding Cleaning Specialists" — effectively guides your AI model to better results, never compromise security, and never push broken code

- 🛡️ **Block secrets, API keys & credentials in every commit/push**
- 🚦 **Catch errors early: TypeScript, Lint, Tests & Build run when available**
- 📝 **Beautiful commit messages — fully supports [Conventional Commits](https://www.conventionalcommits.org) & [Gitmoji](https://gitmoji.dev/)**
- ⚡ Zero config for most Node / TypeScript / React / Vue / Three.js repos
- 🚀 Easy install, totally portable, and proven across real-world codebases

_Protect your main branch. Ship with confidence. Focus on building, not fixing leaks/reviewing noisy PRs._

**Source of truth:** [davidnekovarcz/git-hooks](https://github.com/davidnekovarcz/git-hooks). The [smarlify/git-hooks](https://github.com/smarlify/git-hooks) fork tracks it 1:1.

---

## Installation

### Quick Install

1. **Clone or copy this repository** to a location on your machine:
   ```bash
   git clone git@github.com:davidnekovarcz/git-hooks.git ~/Development/__git-hooks
   ```

2. **Install hooks in your repository**:
   ```bash
   cd /path/to/your/repo
   cp ~/Development/__git-hooks/pre-commit .git/hooks/
   cp ~/Development/__git-hooks/pre-push .git/hooks/
   cp ~/Development/__git-hooks/prepare-commit-msg .git/hooks/
   cp -r ~/Development/__git-hooks/shared .git/hooks/
   ```

3. **Make hooks executable**:
   ```bash
   chmod +x .git/hooks/pre-commit
   chmod +x .git/hooks/pre-push
   chmod +x .git/hooks/prepare-commit-msg
   chmod +x .git/hooks/shared/*.sh
   ```

### Point `core.hooksPath` at the shared clone

```bash
git config core.hooksPath "$HOME/Development/__git-hooks"
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
- **Personal data**: identity columns (`birth_number`, `rodne_cislo`, `phone`, `phone_alt`, `national_id`) outside tables listed in `config/personal_data.yml`. Without that file, those columns are blocked on every table except `users`. `users.email` stays allowed for sign-in.

**What happens**: If sensitive data is detected, the commit/push is blocked with helpful error messages and suggestions on how to fix it.

### 📝 Code Quality Checks (`pre-commit`)

Checks are **capability-based** at the **repo root**. A check runs only when the project exposes it.

#### TypeScript
- Prefer `npm run tsc` when that script exists
- Else run `npx tsc --noEmit` when a root `tsconfig.json` / `tsconfig.app.json` / `tsconfig.node.json` exists
- Otherwise skip

#### Linting
- Runs `npm run lint` when that script exists; otherwise skip

Nested apps (e.g. code under `web/`) should expose root npm scripts that delegate into the package — hooks stay root-oriented and do not probe subfolders.

### 🧪 Testing & Build (`pre-push`)

#### Tests
- Runs `npm test` when a `test` script exists (Vitest, Jest, Cypress wrappers, etc.)
- Skipped for Heroku pushes (deploy first, then test the deployed app if needed)

#### Kaloko
- When `kaloko.config.yml` exists and the root `package.json` has `kaloko:smoke` (or `kaloko`), pre-push runs that script only if the push updates `main` or `master` on a remote other than Heroku
- Feature-branch pushes skip Kaloko
- Heroku pushes skip Kaloko the same way they skip unit tests
- Repos without Kaloko skip this check
- A merge button on GitHub does not execute this laptop hook

#### Build Checks
- Runs `npm run build` when pushing to a Heroku remote and a `build` script exists
- Blocks the push if the build fails

### 🎯 Commit Message Helper (`prepare-commit-msg`)

Interactive helper for creating consistent commit messages using Gitmoji and Conventional Commits format.

#### Features:
- **Gitmoji Support**: Suggests appropriate emojis based on staged files
- **Conventional Commits**: Encourages format like `feat(scope): description`
- **Smart Suggestions**: Analyzes staged files and suggests commit type
- **Interactive Prompt**: Guides you through creating a proper commit message
- **Help System**: Type `help` to see full Gitmoji reference

Skipped for `merge` / `squash` / `commit -m` / `-F` sources so existing messages are not overwritten.

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

## Hook Execution Flow

### Pre-Commit Hook
1. 🔒 Block commits on `main` / `master`
2. 🔒 Security check on staged files
3. 📝 TypeScript check (if available)
4. 🧹 Linting (if available)
5. ✅ Commit proceeds if all checks pass

### Pre-Push Hook
1. 🔒 Block pushes to `main` / `master` (except remote named `heroku`)
2. 🔒 Security check on commits being pushed
3. 🧪 `npm test` (non-Heroku, if available)
4. 🧪 Kaloko smoke only when the push updates `main` or `master` (not a feature branch, not Heroku)
5. 🔨 Build check (Heroku only, if available)
6. ✅ Push proceeds if all checks pass

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

### Local skips

If a repo should skip certain checks, do that **locally** (omit the npm script, or use a local hook override). This shared repo does not hard-code repository names.

## Troubleshooting

### Hooks not running?
- Ensure hooks are executable: `chmod +x .git/hooks/*`
- Check that hooks are in `.git/hooks/` (or that `core.hooksPath` points at this clone)
- Verify hook file names match exactly (no `.sample` extension)

### TypeScript check fails but code works?
- Run `npm run tsc` or `npx tsc --noEmit` manually to see errors
- Check your `tsconfig.json` configuration
- For nested packages, add a root `tsc` script that runs the package check

### Tests not running?
- Ensure `package.json` has a `test` script
- Run `npm test` manually to confirm it works without a special environment

### Security check false positives?
- Review the detected pattern
- Consider adding the file to `.gitignore` if it's a test fixture
- Adjust patterns in `shared/security-check.sh` if needed

## Best Practices

1. **Never commit sensitive data**: Use environment variables or secrets management
2. **Keep hooks updated**: Pull latest changes from this repository regularly
3. **Fix issues locally**: Don't bypass hooks, fix the underlying issues
4. **Use consistent commit messages**: Follow the Gitmoji and Conventional Commits format
5. **Expose root scripts**: Nest packages behind root `lint` / `tsc` / `test` / `build` scripts

## Contributing

Feel free to submit issues or pull requests to improve these hooks!

## License

This collection of git hooks is provided as-is for use across your repositories.
