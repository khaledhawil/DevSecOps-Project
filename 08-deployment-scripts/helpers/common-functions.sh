#!/bin/bash

# Common functions for deployment scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Print functions
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed. $2"
        return 1
    fi
    print_success "$1 is installed"
    return 0
}

# Check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        print_warning "Port $port is already in use"
        return 1
    fi
    return 0
}

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=${3:-30}
    local attempt=1
    
    print_info "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    echo ""
    print_error "$service_name failed to become ready"
    return 1
}

# Confirm action
confirm() {
    local prompt="$1"
    local response
    
    read -p "$(echo -e ${YELLOW}⚠${NC}) $prompt (yes/no): " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get environment
get_environment() {
    local env=${1:-dev}
    case "$env" in
        dev|development)
            echo "dev"
            ;;
        staging|stage)
            echo "staging"
            ;;
        prod|production)
            echo "prod"
            ;;
        *)
            print_error "Invalid environment: $env. Use dev, staging, or prod"
            exit 1
            ;;
    esac
}

# Load environment variables
load_env() {
    local env_file=$1
    if [ -f "$env_file" ]; then
        print_info "Loading environment variables from $env_file"
        set -a
        source "$env_file"
        set +a
        print_success "Environment variables loaded"
    else
        print_warning "Environment file not found: $env_file"
    fi
}

# Check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid"
        print_info "Run: aws configure"
        return 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local region=$(aws configure get region)
    
    print_success "AWS credentials configured"
    print_info "Account ID: $account_id"
    print_info "Region: $region"
    return 0
}

# Check kubectl context
check_kubectl_context() {
    local expected_cluster=$1
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        return 1
    fi
    
    local current_context=$(kubectl config current-context)
    print_success "Connected to cluster: $current_context"
    
    if [ -n "$expected_cluster" ] && [[ "$current_context" != *"$expected_cluster"* ]]; then
        print_warning "Current context doesn't match expected cluster: $expected_cluster"
        return 1
    fi
    
    return 0
}

# Display summary
display_summary() {
    local title=$1
    shift
    local items=("$@")
    
    print_header "$title"
    for item in "${items[@]}"; do
        echo -e "  ${GREEN}✓${NC} $item"
    done
    echo ""
}

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Execute with spinner
execute_with_spinner() {
    local command=$1
    local message=$2
    
    print_info "$message"
    eval "$command" > /tmp/spinner_output.log 2>&1 &
    local pid=$!
    spinner $pid
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "$message - Complete"
    else
        print_error "$message - Failed"
        cat /tmp/spinner_output.log
    fi
    
    rm -f /tmp/spinner_output.log
    return $exit_code
}

# Get timestamp
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Log to file
log_message() {
    local message=$1
    local log_file=${2:-deployment.log}
    echo "[$(get_timestamp)] $message" >> "$log_file"
}

# Check disk space
check_disk_space() {
    local required_gb=${1:-20}
    local available_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_gb" -lt "$required_gb" ]; then
        print_warning "Low disk space: ${available_gb}GB available, ${required_gb}GB recommended"
        return 1
    fi
    
    print_success "Sufficient disk space: ${available_gb}GB available"
    return 0
}

# Check memory
check_memory() {
    local required_gb=${1:-8}
    local total_gb=$(free -g | awk 'NR==2 {print $2}')
    
    if [ "$total_gb" -lt "$required_gb" ]; then
        print_warning "Low memory: ${total_gb}GB total, ${required_gb}GB recommended"
        return 1
    fi
    
    print_success "Sufficient memory: ${total_gb}GB total"
    return 0
}
