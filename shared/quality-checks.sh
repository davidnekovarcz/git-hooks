#!/bin/bash
# shared/quality-checks.sh
# Reusable quality check functions for git hooks.
# Capability-based: run a check only when the project exposes it at the repo root.

# Colors for output (only if outputting to a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# True when package.json defines an npm script with the given name.
# Do not use `npm run --dry-run` — some npm versions still execute the script.
has_npm_script() {
    local script_name="$1"
    [ -f "package.json" ] || return 1
    if command -v node >/dev/null 2>&1; then
        node -e "const s=require('./package.json').scripts||{}; process.exit(s[process.argv[1]]?0:1)" "$script_name"
        return $?
    fi
    # Best-effort fallback without Node
    grep -Eq "\"${script_name}\"[[:space:]]*:" package.json
}

has_root_tsconfig() {
    [ -f "tsconfig.json" ] || [ -f "tsconfig.app.json" ] || [ -f "tsconfig.node.json" ]
}

# Prefer `npm run tsc` when present; otherwise bare `npx tsc --noEmit` if a root tsconfig exists.
run_typescript_check() {
    if has_npm_script tsc; then
        echo "${YELLOW}📝 Running TypeScript check (npm run tsc)...${NC}"
        TSC_OUTPUT=$(npm run tsc 2>&1)
        TSC_EXIT_CODE=$?
    elif has_root_tsconfig && command -v npx >/dev/null 2>&1; then
        echo "${YELLOW}📝 Running TypeScript check (npx tsc --noEmit)...${NC}"
        TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
        TSC_EXIT_CODE=$?
    else
        echo "${YELLOW}⚠️  No TypeScript check available, skipping${NC}"
        return 0
    fi

    if [ $TSC_EXIT_CODE -eq 0 ]; then
        echo "${GREEN}✅ TypeScript check passed${NC}"
        return 0
    fi

    echo "${RED}❌ TypeScript check failed${NC}"
    echo "${RED}TypeScript errors:${NC}"
    echo "$TSC_OUTPUT"
    echo "${RED}Please fix TypeScript errors before committing.${NC}"
    return 1
}

run_linting() {
    if ! has_npm_script lint; then
        echo "${YELLOW}⚠️  No lint script found, skipping linting${NC}"
        return 0
    fi

    echo "${YELLOW}🧹 Running linter...${NC}"
    LINT_OUTPUT=$(npm run lint 2>&1)
    LINT_EXIT_CODE=$?

    if [ $LINT_EXIT_CODE -eq 0 ]; then
        echo "${GREEN}✅ Linting passed${NC}"
        return 0
    fi

    echo "${RED}❌ Linting failed${NC}"
    echo "${RED}Linting errors:${NC}"
    echo "$LINT_OUTPUT"
    echo "${RED}Please fix linting errors before committing.${NC}"
    return 1
}

run_build_check() {
    if ! has_npm_script build; then
        echo "${YELLOW}⚠️  No build script found, skipping build check${NC}"
        return 0
    fi

    echo "${YELLOW}🔨 Running build check...${NC}"
    BUILD_OUTPUT=$(npm run build 2>&1)
    BUILD_EXIT_CODE=$?

    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo "${GREEN}✅ Build check passed${NC}"
        return 0
    fi

    echo "${RED}❌ Build check failed${NC}"
    echo "${RED}Build errors:${NC}"
    echo "$BUILD_OUTPUT"
    echo "${RED}Please fix build errors before pushing.${NC}"
    return 1
}

# Runs whatever `npm test` is for this repo (Vitest, Jest, Cypress wrapper, etc.).
run_tests() {
    if ! has_npm_script test; then
        echo "${YELLOW}⚠️  No test script found, skipping tests${NC}"
        return 0
    fi

    echo "${YELLOW}🧪 Running tests (npm test)...${NC}"

    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.nvm/nvm.sh"
    fi

    TEST_OUTPUT=$(npm test 2>&1)
    TEST_EXIT_CODE=$?

    if [ $TEST_EXIT_CODE -eq 0 ]; then
        echo "${GREEN}✅ All tests passed${NC}"
        return 0
    fi

    echo "${RED}❌ Tests failed${NC}"
    echo "${RED}Test output:${NC}"
    echo "$TEST_OUTPUT"
    echo "${RED}Please fix failing tests before pushing.${NC}"
    return 1
}
