#!/bin/bash

# Stop Responsive AI Demo Server

echo "🛑 Stopping demo server..."

# Kill the Python HTTP server using multiple methods
# Method 1: Kill by process name
pkill -f "python3 -m http.server 8000"

# Method 2: Kill by port (more reliable)
PID=$(lsof -ti:8000)
if [ ! -z "$PID" ]; then
    kill -9 $PID
    echo "✅ Demo server stopped (PID: $PID)"
else
    echo "ℹ️  No demo server was running on port 8000"
fi

# Verify server is stopped
if lsof -i:8000 > /dev/null 2>&1; then
    echo "⚠️  Warning: Something is still running on port 8000"
    lsof -i:8000
else
    echo "✅ Port 8000 is now free"
fi

echo "🧹 Demo cleanup complete"