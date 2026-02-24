FROM python:3.9-slim

WORKDIR /app

# Создаем простое веб-приложение на Python
RUN echo 'from http.server import HTTPServer, BaseHTTPRequestHandler\n\
import json\n\
\n\
class HealthHandler(BaseHTTPRequestHandler):\n\
    def do_GET(self):\n\
        if self.path == "/health" or self.path == "/":\n\
            self.send_response(200)\n\
            self.send_header("Content-type", "text/plain")\n\
            self.end_headers()\n\
            self.wfile.write(b"OK")\n\
        else:\n\
            self.send_response(404)\n\
            self.end_headers()\n\
\n\
if __name__ == "__main__":\n\
    server = HTTPServer(("0.0.0.0", 80), HealthHandler)\n\
    print("Server running on port 80...")\n\
    server.serve_forever()' > app.py

EXPOSE 80

CMD ["python", "app.py"]
