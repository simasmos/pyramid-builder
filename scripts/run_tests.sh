#!/bin/bash

# 🧪 Pyramid Builder - Test Runner Script
# Runs GdUnit4 tests locally with various options

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
GODOT_BINARY="godot"
VERBOSE=false
COVERAGE=false
JUNIT_OUTPUT=false
HTML_REPORT=false
FAIL_FAST=false
SPECIFIC_TEST=""
TIMEOUT=30000

print_usage() {
    echo "🎮 Pyramid Builder Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -c, --coverage          Generate coverage report"
    echo "  -j, --junit             Generate JUnit XML report"
    echo "  -h, --html              Generate HTML report"
    echo "  -f, --fail-fast         Stop on first failure"
    echo "  -t, --test TEST_NAME    Run specific test file"
    echo "  -T, --timeout SECONDS   Set test timeout (default: 30)"
    echo "  -g, --godot PATH        Path to Godot binary (default: godot)"
    echo "  --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run all tests"
    echo "  $0 -v -c               # Run with verbose output and coverage"
    echo "  $0 -t test_worker.gd   # Run specific test file"
    echo "  $0 -f -j               # Fail fast and generate JUnit report"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -j|--junit)
            JUNIT_OUTPUT=true
            shift
            ;;
        -h|--html)
            HTML_REPORT=true
            shift
            ;;
        -f|--fail-fast)
            FAIL_FAST=true
            shift
            ;;
        -t|--test)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        -T|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -g|--godot)
            GODOT_BINARY="$2"
            shift 2
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            print_usage
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🎮 Pyramid Builder Test Runner${NC}"
echo "==============================================="

# Check if Godot is available
if ! command -v "$GODOT_BINARY" &> /dev/null; then
    echo -e "${RED}❌ Godot binary not found: $GODOT_BINARY${NC}"
    echo "Please install Godot 4.2+ or specify path with -g option"
    exit 1
fi

# Check Godot version
echo -e "${BLUE}🔍 Checking Godot version...${NC}"
GODOT_VERSION=$($GODOT_BINARY --version 2>/dev/null | head -n1 || echo "Unknown")
echo "Godot version: $GODOT_VERSION"

# Check if GdUnit4 is installed
if [ ! -d "addons/gdUnit4" ]; then
    echo -e "${YELLOW}⚠️  GdUnit4 not found, installing...${NC}"
    mkdir -p addons/gdUnit4
    
    if command -v wget &> /dev/null; then
        wget -O gdunit4.zip https://github.com/MikeSchulze/gdUnit4/releases/latest/download/gdUnit4.zip
        unzip gdunit4.zip -d addons/gdUnit4/
        rm gdunit4.zip
    else
        echo -e "${RED}❌ wget not found. Please install GdUnit4 manually.${NC}"
        exit 1
    fi
fi

# Import project if needed
if [ ! -d ".godot" ]; then
    echo -e "${BLUE}🏗️  Importing Godot project...${NC}"
    timeout 60 $GODOT_BINARY --headless --editor --quit || true
fi

# Build test command
TEST_CMD="$GODOT_BINARY --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd"

# Add test directories
if [ -n "$SPECIFIC_TEST" ]; then
    if [ -f "test/unit/$SPECIFIC_TEST" ]; then
        TEST_CMD="$TEST_CMD --add test/unit/$SPECIFIC_TEST"
    elif [ -f "test/integration/$SPECIFIC_TEST" ]; then
        TEST_CMD="$TEST_CMD --add test/integration/$SPECIFIC_TEST"
    elif [ -f "test/scene/$SPECIFIC_TEST" ]; then
        TEST_CMD="$TEST_CMD --add test/scene/$SPECIFIC_TEST"
    else
        echo -e "${RED}❌ Test file not found: $SPECIFIC_TEST${NC}"
        exit 1
    fi
else
    TEST_CMD="$TEST_CMD --add test/unit/"
    TEST_CMD="$TEST_CMD --add test/integration/"
    TEST_CMD="$TEST_CMD --add test/scene/"
fi

# Add options
if [ "$VERBOSE" = true ]; then
    TEST_CMD="$TEST_CMD --verbose"
fi

if [ "$COVERAGE" = true ]; then
    TEST_CMD="$TEST_CMD --report-coverage"
fi

if [ "$JUNIT_OUTPUT" = true ]; then
    TEST_CMD="$TEST_CMD --report-junit-xml test_results.xml"
fi

if [ "$HTML_REPORT" = true ]; then
    TEST_CMD="$TEST_CMD --report-html test_reports/"
fi

if [ "$FAIL_FAST" = true ]; then
    TEST_CMD="$TEST_CMD --fail-fast"
fi

# Set timeout
TEST_CMD="$TEST_CMD --timeout $TIMEOUT"

# Always add console output
TEST_CMD="$TEST_CMD --report-console"

# Run tests
echo -e "${BLUE}🧪 Running tests...${NC}"
echo "Command: $TEST_CMD"
echo ""

# Create output directories
mkdir -p test_reports coverage

# Run the tests
if eval "$TEST_CMD"; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    
    # Show additional reports if generated
    if [ "$JUNIT_OUTPUT" = true ] && [ -f "test_results.xml" ]; then
        echo -e "${BLUE}📊 JUnit report generated: test_results.xml${NC}"
    fi
    
    if [ "$HTML_REPORT" = true ] && [ -d "test_reports" ]; then
        echo -e "${BLUE}📋 HTML report generated: test_reports/index.html${NC}"
    fi
    
    if [ "$COVERAGE" = true ] && [ -d "coverage" ]; then
        echo -e "${BLUE}📈 Coverage report generated: coverage/index.html${NC}"
    fi
    
    exit 0
else
    echo ""
    echo -e "${RED}❌ Tests failed!${NC}"
    exit 1
fi