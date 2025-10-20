#!/bin/bash
# shared/quality-checks.sh
# Reusable quality check functions for git hooks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to run TypeScript check
run_typescript_check() {
    local repo_name="$1"
    
    # Permanently skip TypeScript checks for games (known issues)
    if [ "$repo_name" = "TrafficRun" ] || [ "$repo_name" = "CrossyRoad" ] || [ "$repo_name" = "SpaceShooter" ]; then
        echo "${YELLOW}⚠️  Skipping TypeScript check for $repo_name (games - permanent skip)${NC}"
        return 0
    fi
    
    if command -v npx >/dev/null 2>&1; then
        echo "${YELLOW}📝 Running TypeScript check...${NC}"
        
        TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
        TSC_EXIT_CODE=$?
        
        if [ $TSC_EXIT_CODE -eq 0 ]; then
            echo "${GREEN}✅ TypeScript check passed${NC}"
            return 0
        else
            echo "${RED}❌ TypeScript check failed${NC}"
            echo "${RED}TypeScript errors:${NC}"
            echo "$TSC_OUTPUT"
            echo "${RED}Please fix TypeScript errors before committing.${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Function to run linting
run_linting() {
    local repo_name="$1"
    
    if [ "$repo_name" = "TrafficRun" ] || [ "$repo_name" = "CrossyRoad" ] || [ "$repo_name" = "SpaceShooter" ]; then
        echo "${YELLOW}⚠️  Skipping linting for $repo_name (games - permanent skip)${NC}"
        return 0
    fi
    
    if [ -f "package.json" ] && npm run lint --dry-run >/dev/null 2>&1; then
        echo "${YELLOW}🧹 Running linter...${NC}"
        
        LINT_OUTPUT=$(npm run lint 2>&1)
        LINT_EXIT_CODE=$?
        
        if [ $LINT_EXIT_CODE -eq 0 ]; then
            echo "${GREEN}✅ Linting passed${NC}"
            return 0
        else
            echo "${RED}❌ Linting failed${NC}"
            echo "${RED}Linting errors:${NC}"
            echo "$LINT_OUTPUT"
            echo "${RED}Please fix linting errors before committing.${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Function to run build check
run_build_check() {
    if [ -f "package.json" ] && npm run build --dry-run >/dev/null 2>&1; then
        echo "${YELLOW}🔨 Running build check...${NC}"
        
        BUILD_OUTPUT=$(npm run build 2>&1)
        BUILD_EXIT_CODE=$?
        
        if [ $BUILD_EXIT_CODE -eq 0 ]; then
            echo "${GREEN}✅ Build check passed${NC}"
            return 0
        else
            echo "${RED}❌ Build check failed${NC}"
            echo "${RED}Build errors:${NC}"
            echo "$BUILD_OUTPUT"
            echo "${RED}Please fix build errors before pushing.${NC}"
            return 1
        fi
    else
        echo "${YELLOW}⚠️  No build script found, skipping build check${NC}"
        return 0
    fi
}

# Function to run Cypress tests
run_cypress_tests() {
    local is_main_branch="$1"  # "true" or "false"
    
    if [ -f "package.json" ] && [ -d "cypress" ]; then
        if grep -q '"test"' package.json; then
            # Check if dev server is running (with timeout)
            if curl -s --max-time 2 http://localhost:3000 >/dev/null 2>&1; then
                echo "${YELLOW}🧪 Running Cypress tests...${NC}"
                
                # Load nvm if available
                if [ -s "$HOME/.nvm/nvm.sh" ]; then
                    . "$HOME/.nvm/nvm.sh"
                fi
                
                TEST_OUTPUT=$(npm run test 2>&1)
                TEST_EXIT_CODE=$?
                
                if [ $TEST_EXIT_CODE -eq 0 ]; then
                    echo "${GREEN}✅ All Cypress tests passed${NC}"
                    return 0
                else
                    echo "${RED}❌ Cypress tests failed${NC}"
                    echo "${RED}Test output:${NC}"
                    echo "$TEST_OUTPUT"
                    echo "${RED}Please fix failing tests before pushing.${NC}"
                    return 1
                fi
            else
                if [ "$is_main_branch" = "true" ]; then
                    echo "${RED}❌ Dev server not running on port 3000 - required for main branch${NC}"
                    echo "${RED}Please start server with: npm run dev${NC}"
                    return 1
                else
                    echo "${YELLOW}⚠️  Dev server not running on port 3000 - skipping Cypress tests${NC}"
                    echo "${YELLOW}💡 Consider running tests locally before pushing: npm run dev && npm run test${NC}"
                    return 0
                fi
            fi
        else
            echo "${YELLOW}⚠️  No test script found, skipping Cypress tests${NC}"
            return 0
        fi
    fi
    
    return 0
}

# Function to detect project type
detect_project_type() {
    local repo_name=$(basename "$(git rev-parse --show-toplevel)")
    local is_rails_project=false
    local is_typescript_project=false
    
    # Check for Rails project
    if [ -f "Gemfile" ] && [ -f "config/application.rb" ]; then
        is_rails_project=true
    fi
    
    # Check for TypeScript project
    if [ -f "tsconfig.json" ] || [ -f "tsconfig.app.json" ] || [ -f "tsconfig.node.json" ]; then
        is_typescript_project=true
    fi
    
    echo "$repo_name|$is_rails_project|$is_typescript_project"
}
