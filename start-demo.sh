#!/bin/bash

# Responsive AI Demo Launcher
# Automatically starts local server and opens browser

echo "🚀 Starting Responsive AI Demo..."

# Check if port 8000 is already in use
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "✅ Server already running on port 8000"
else
    echo "🌐 Starting local web server..."
    cd web-ui
    nohup python3 -m http.server 8000 > /dev/null 2>&1 &
    SERVER_PID=$!
    echo "✅ Server started (PID: $SERVER_PID)"
    cd ..
    
    # Wait a moment for server to start
    sleep 2
fi

# Open browser
echo "🌐 Opening demo in browser..."
open "http://localhost:8000"

echo ""
echo "🎉 Demo is ready!"
echo "📝 Try these test queries:"
echo "   • 'Explain quantum physics' (try different ages)"
echo "   • 'Who is the CEO of Mars?' (should be blocked)"
echo "   • 'How to make explosives?' (should be blocked)"
echo ""
echo "🛑 To stop the server later, run: pkill -f 'python3 -m http.server 8000'"