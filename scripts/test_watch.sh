#!/bin/bash

# 🔄 Pyramid Builder - Test Watcher Script
# Continuously runs tests when files change

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔄 Pyramid Builder Test Watcher${NC}"
echo "Watching for changes in scripts/ and test/ directories..."
echo "Press Ctrl+C to stop"
echo ""

# Check if inotifywait is available
if ! command -v inotifywait &> /dev/null; then
    echo -e "${YELLOW}⚠️  inotifywait not found. Installing inotify-tools...${NC}"
    
    # Try to install inotify-tools
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y inotify-tools
    elif command -v brew &> /dev/null; then
        brew install fswatch
        echo "Using fswatch instead of inotifywait on macOS"
        
        # Use fswatch for macOS
        fswatch -o scripts/ test/ | while read num; do
            echo -e "${YELLOW}📁 Files changed, running tests...${NC}"
            ./scripts/run_tests.sh -v || true
            echo -e "${GREEN}🔄 Waiting for changes...${NC}"
        done
        exit 0
    else
        echo "Please install inotify-tools manually"
        exit 1
    fi
fi

# Run tests once initially
echo -e "${YELLOW}🧪 Running initial tests...${NC}"
./scripts/run_tests.sh -v || true
echo -e "${GREEN}🔄 Watching for changes...${NC}"

# Watch for changes
inotifywait -m -r -e modify,create,delete,move scripts/ test/ --format '%w%f %e' | while read file event; do
    # Only react to .gd files
    if [[ "$file" == *.gd ]]; then
        echo -e "${YELLOW}📝 Changed: $file ($event)${NC}"
        echo -e "${YELLOW}🧪 Running tests...${NC}"
        
        # Run tests with a small delay to avoid multiple rapid runs
        sleep 0.5
        ./scripts/run_tests.sh -v || true
        
        echo -e "${GREEN}🔄 Waiting for changes...${NC}"
    fi
done