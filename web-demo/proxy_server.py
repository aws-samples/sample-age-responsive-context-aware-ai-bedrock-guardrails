#!/usr/bin/env python3
"""
Simple proxy server to bypass CORS issues
"""
import http.server
import socketserver
import requests
import json
import os

class CORSProxyHandler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_POST(self):
        if self.path == '/api/ask':
            # Proxy to real API
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            # Get auth header
            auth_header = self.headers.get('Authorization', '')
            
            # Forward to real API
            api_url = 'https://hncat4kbmc.execute-api.us-east-1.amazonaws.com/prod/ask'
            headers = {
                'Content-Type': 'application/json',
                'Authorization': auth_header
            }
            
            try:
                # Validate URL to prevent SSRF attacks
                if not api_url.startswith('https://') or 'amazonaws.com' not in api_url:
                    raise ValueError('Invalid API URL')
                    
                response = requests.post(api_url, data=post_data, headers=headers, timeout=30)
                response.raise_for_status()
                result = response.content
                    
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(result)
                
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                error_response = json.dumps({'error': str(e)}).encode()
                self.wfile.write(error_response)
        else:
            super().do_POST()

    def do_GET(self):
        super().do_GET()

if __name__ == "__main__":
    PORT = 8081
    with socketserver.TCPServer(("", PORT), CORSProxyHandler) as httpd:
        print(f"Proxy server running at http://localhost:{PORT}")
        print("Use /api/ask endpoint to proxy to real API")
        httpd.serve_forever()