#!/bin/bash
#
# migrate-provider-namespace.sh
#
# Safely migrates Terraform state from aztfmod/azurecaf to aztfmodnew/azurecaf
# provider namespace without destroying resources.
#
# Usage:
#   ./migrate-provider-namespace.sh [directory]
#
# Examples:
#   ./migrate-provider-namespace.sh                    # Current directory
#   ./migrate-provider-namespace.sh ../caf_launchpad   # Specific directory
#   ./migrate-provider-namespace.sh --all              # All subdirectories with .terraform

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Provider namespaces
OLD_PROVIDER="registry.terraform.io/aztfmod/azurecaf"
NEW_PROVIDER="registry.terraform.io/aztfmodnew/azurecaf"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✖${NC} $1"
}

# Function to check if terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    print_info "Terraform version: $(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)"
}

# Function to check if directory has Terraform state
check_terraform_state() {
    local dir=$1
    
    if [ ! -d "$dir/.terraform" ]; then
        print_warning "Directory $dir has no .terraform state. Run 'terraform init' first."
        return 1
    fi
    
    return 0
}

# Function to check if old provider exists in state
check_old_provider() {
    local dir=$1
    
    # Check state file for old provider
    if terraform -chdir="$dir" show -json 2>/dev/null | grep -q "aztfmod/azurecaf"; then
        return 0  # Found
    fi
    
    return 1  # Not found
}

# Function to perform provider migration
migrate_provider() {
    local dir=$1
    
    print_info "Checking directory: $dir"
    
    # Check if directory has Terraform state
    if ! check_terraform_state "$dir"; then
        return 1
    fi
    
    # Check if old provider exists
    if ! check_old_provider "$dir"; then
        print_success "No migration needed (already using $NEW_PROVIDER)"
        return 0
    fi
    
    print_warning "Found old provider namespace: $OLD_PROVIDER"
    print_info "Migrating to: $NEW_PROVIDER"
    
    # Ask for confirmation
    if [ "$AUTO_CONFIRM" != "yes" ]; then
        read -p "$(echo -e ${YELLOW}Proceed with migration? [y/N]:${NC} )" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Migration cancelled by user"
            return 1
        fi
    fi
    
    # Create backup of state
    print_info "Creating backup of current state..."
    cp "$dir/.terraform/terraform.tfstate" "$dir/.terraform/terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
    
    # Run terraform state replace-provider
    print_info "Running terraform state replace-provider..."
    if terraform -chdir="$dir" state replace-provider -auto-approve \
        "$OLD_PROVIDER" \
        "$NEW_PROVIDER"; then
        print_success "Provider namespace migrated successfully!"
        
        # Verify migration
        print_info "Verifying migration..."
        if terraform -chdir="$dir" show | grep -q "provider\[\"$NEW_PROVIDER\"\]"; then
            print_success "Verification passed: State now uses $NEW_PROVIDER"
            
            # Run terraform plan to check for changes
            print_info "Running terraform plan to verify no resource changes..."
            if terraform -chdir="$dir" plan -detailed-exitcode &>/dev/null; then
                print_success "Perfect! No resource changes detected."
            else
                exit_code=$?
                if [ $exit_code -eq 2 ]; then
                    print_warning "Terraform plan shows changes. Review with 'terraform plan' before applying."
                else
                    print_error "Terraform plan failed. Check configuration."
                fi
            fi
        else
            print_error "Verification failed: State still shows old provider"
            return 1
        fi
    else
        print_error "Migration failed!"
        return 1
    fi
}

# Function to find all Terraform directories
find_terraform_dirs() {
    find . -type d -name ".terraform" -exec dirname {} \; | sort -u
}

# Main script
main() {
    local target_dir="."
    local run_all=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                run_all=true
                shift
                ;;
            --yes|-y)
                AUTO_CONFIRM=yes
                shift
                ;;
            --help|-h)
                cat << EOF
Usage: $0 [OPTIONS] [DIRECTORY]

Safely migrates Terraform state from aztfmod/azurecaf to aztfmodnew/azurecaf
provider namespace without destroying resources.

Options:
    --all           Migrate all subdirectories with Terraform state
    --yes, -y       Auto-confirm all prompts
    --help, -h      Show this help message

Examples:
    $0                           # Migrate current directory
    $0 ../caf_launchpad          # Migrate specific directory
    $0 --all                     # Migrate all Terraform directories
    $0 --yes ../caf_solution     # Auto-confirm migration

EOF
                exit 0
                ;;
            *)
                target_dir=$1
                shift
                ;;
        esac
    done
    
    print_info "═══════════════════════════════════════════════════"
    print_info "  Terraform Provider Namespace Migration Tool"
    print_info "  $OLD_PROVIDER"
    print_info "  → $NEW_PROVIDER"
    print_info "═══════════════════════════════════════════════════"
    echo
    
    # Check prerequisites
    check_terraform
    echo
    
    # Run migration
    if [ "$run_all" = true ]; then
        print_info "Scanning for Terraform directories..."
        dirs=$(find_terraform_dirs)
        
        if [ -z "$dirs" ]; then
            print_warning "No Terraform directories found"
            exit 0
        fi
        
        print_info "Found $(echo "$dirs" | wc -l) Terraform director(ies)"
        echo
        
        success_count=0
        skip_count=0
        error_count=0
        
        for dir in $dirs; do
            echo
            print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if migrate_provider "$dir"; then
                ((success_count++))
            else
                if check_old_provider "$dir"; then
                    ((error_count++))
                else
                    ((skip_count++))
                fi
            fi
        done
        
        echo
        print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "Migration Summary:"
        print_success "Successfully migrated: $success_count"
        print_warning "Skipped (no old provider): $skip_count"
        [ $error_count -gt 0 ] && print_error "Failed: $error_count"
        
    else
        migrate_provider "$target_dir"
    fi
    
    echo
    print_info "═══════════════════════════════════════════════════"
    print_success "Migration complete!"
    print_info "Next steps:"
    print_info "  1. Run 'terraform init -upgrade' in each directory"
    print_info "  2. Run 'terraform plan' to verify no changes"
    print_info "  3. Update your main.tf to use aztfmodnew/azurecaf"
    print_info "═══════════════════════════════════════════════════"
}

# Run main function
main "$@"
