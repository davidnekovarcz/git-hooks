#!/bin/bash
# shared/security-check.sh
# Reusable security check functions for git hooks

# Colors for output (only if outputting to a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# List of sensitive patterns to block
SENSITIVE_PATTERNS=(
    "AIza[0-9A-Za-z_-]{35}"  # Google API keys
    "sk-[0-9A-Za-z]{48}"     # OpenAI API keys
    "xoxb-[0-9]{11}-[0-9]{11}-[0-9A-Za-z]{24}"  # Slack bot tokens
    "xoxp-[0-9]{11}-[0-9]{11}-[0-9A-Za-z]{24}"  # Slack user tokens
    "https://hooks\.slack\.com/services/[A-Z0-9]+/[A-Z0-9]+/[A-Za-z0-9]+"  # Slack webhooks
    "-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----"  # Private keys
    "AKIA[0-9A-Z]{16}"       # AWS access keys
    "ya29\.[0-9A-Za-z_-]+"   # Google OAuth tokens
    "1/[0-9A-Za-z_-]{43}"    # Google refresh tokens
    "AIzaSy[0-9A-Za-z_-]{33}" # Firebase API keys
    "firebase.*api.*key"      # Firebase config
    "mongodb://.*:.*@"        # MongoDB connection strings
    "postgres://.*:.*@"       # PostgreSQL connection strings
    "mysql://.*:.*@"          # MySQL connection strings
    "redis://.*:.*@"          # Redis connection strings
    "NEXT_PUBLIC_.*=\s*['\"][^'\"]*['\"]"  # Next.js public env vars with actual values
    "REACT_APP_.*=\s*['\"][^'\"]*['\"]"    # React app env vars with actual values
    "VITE_.*=\s*['\"][^'\"]*['\"]"         # Vite env vars with actual values
    "password\s*=\s*['\"][^'\"]*['\"]"     # Password fields with actual values
    "secret\s*=\s*['\"][^'\"]*['\"]"       # Secret fields with actual values
    "token\s*=\s*['\"][^'\"]*['\"]"        # Token fields with actual values
    "api.*key\s*=\s*['\"][^'\"]*['\"]"     # API key fields with actual values
)

# Function to check files for sensitive data
check_files_for_sensitive_data() {
    local files="$1"
    local context="$2"  # "staged files" or "commits"
    
    echo "${YELLOW}🔒 Checking for sensitive data in $context...${NC}"
    
    local sensitive_found=false
    
    for file in $files; do
        # Skip binary files
        if git diff --cached --numstat "$file" 2>/dev/null | grep -q "^-"; then
            continue
        fi
        
        # Skip package-lock.json and similar lock files from Google refresh token check
        # (they contain legitimate hash values that can match the pattern)
        local skip_google_token_check=false
        if [[ "$file" == *"package-lock.json"* ]] || [[ "$file" == *"yarn.lock"* ]] || [[ "$file" == *"pnpm-lock.yaml"* ]]; then
            skip_google_token_check=true
        fi
        
        # Check file content for sensitive patterns
        for pattern in "${SENSITIVE_PATTERNS[@]}"; do
            # Skip Google refresh token pattern for lock files
            if [ "$skip_google_token_check" = true ] && [ "$pattern" = "1/[0-9A-Za-z_-]{43}" ]; then
                continue
            fi
            
            if git show ":$file" 2>/dev/null | grep -iE "$pattern" >/dev/null 2>&1; then
                echo "${RED}❌ SECURITY VIOLATION DETECTED!${NC}"
                echo "${RED}File: $file${NC}"
                echo "${RED}Pattern: $pattern${NC}"
                echo "${RED}This file contains sensitive data and cannot be committed!${NC}"
                echo ""
                echo "${YELLOW}Common sensitive data types:${NC}"
                echo "  • API keys (Google, OpenAI, AWS, etc.)"
                echo "  • Database connection strings"
                echo "  • Slack webhooks and tokens"
                echo "  • Private keys and certificates"
                echo "  • Environment variables with secrets"
                echo "  • Passwords and authentication tokens"
                echo ""
                echo "${YELLOW}To fix this:${NC}"
                echo "  1. Remove the sensitive data from the file"
                echo "  2. Add the file to .gitignore if it contains secrets"
                echo "  3. Use environment variables instead"
                echo "  4. Consider using a secrets management service"
                echo ""
                sensitive_found=true
            fi
        done
    done
    
    if [ "$sensitive_found" = true ]; then
        echo "${RED}🚨 COMMIT BLOCKED: Sensitive data detected!${NC}"
        echo "${RED}Please remove all sensitive information before committing.${NC}"
        return 1
    fi
    
    echo "${GREEN}✅ No sensitive data detected${NC}"
    return 0
}

# Function to check staged files
check_staged_files() {
    local staged_files=$(git diff --cached --name-only)
    check_files_for_sensitive_data "$staged_files" "staged files"
}

# Function to check commits being pushed
check_commits() {
    local commits="$1"
    local sensitive_found=false
    
    echo "${YELLOW}🔒 Checking for sensitive data in commits...${NC}"
    
    for commit in $commits; do
        if [ "$commit" != "0000000000000000000000000000000000000000" ]; then
            local changed_files=$(git diff-tree --no-commit-id --name-only -r "$commit")
            if ! check_files_for_sensitive_data "$changed_files" "commit $commit"; then
                sensitive_found=true
            fi
        fi
    done
    
    if [ "$sensitive_found" = true ]; then
        echo "${RED}🚨 PUSH BLOCKED: Sensitive data detected!${NC}"
        echo "${RED}Please remove all sensitive information before pushing.${NC}"
        return 1
    fi
    
    echo "${GREEN}✅ No sensitive data detected in commits${NC}"
    return 0
}
