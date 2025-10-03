#!/bin/bash
echo "🛑 Stopping Age-Responsive AI Demo"

# Kill web server on port 8080
echo "Stopping web server on port 8080..."
lsof -ti:8080 | xargs kill -9 2>/dev/null || echo "No server running on port 8080"

# Kill any Python HTTP servers
echo "Stopping Python HTTP servers..."
ps aux | grep "python3 -m http.server 8080" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || echo "No Python HTTP servers found"

echo "✅ Demo stopped successfully"
echo ""
echo "To restart the demo:"
echo "  ./start_demo.sh"