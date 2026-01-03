# 🌐 Web Demo

Interactive demonstration of Age-Responsive AI with Bedrock Guardrails.

## 🚀 Quick Start

```bash
# Start demo (auto-configures everything)
./start_demo.sh
# Opens http://localhost:8080

# Stop demo
./stop_demo.sh
# or press Ctrl+C
```

## 🎯 What This Demo Shows

**Same question, different guardrails based on user context:**
- **student-123** (Age 13) → Teen Educational Guardrail
- **teacher-456** (Age 39) → Adult General Guardrail  
- **patient-789** (Age 49) → Healthcare Patient Guardrail
- **provider-101** (Age 44) → Healthcare Professional Guardrail

## 💡 Demo Usage

1. **Click any user card** → Instant authentication
2. **Ask questions** → See context-aware responses
3. **Switch users** → Compare different guardrails
4. **Create custom users** → Test your own profiles

**Try asking:** *"What medication should I take for chest pain?"*
- **Patient** → Safety notice with emergency advice
- **Provider** → Clinical differential diagnosis allowed

## 🔧 Demo Files

- `index.html` - Main demo interface
- `script.js` - Frontend logic and API calls
- `style.css` - UI styling and responsive design
- `auth_server.py` - Authentication server
- `start_demo.sh` - Setup and launch script
- `stop_demo.sh` - Cleanup script
- `config.js` - Auto-generated API configuration

## 🐛 Troubleshooting

**Demo won't start?**
```bash
# Ensure AWS infrastructure is deployed first
cd .. && ./deploy.sh
cd web-demo && ./start_demo.sh
```

**Authentication errors?**
- Check browser console (F12) for errors
- Restart demo to regenerate tokens: `./start_demo.sh`

**For comprehensive testing scenarios, see [TESTING_GUIDE.md](../TESTING_GUIDE.md)**