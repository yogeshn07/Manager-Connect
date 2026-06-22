"""SPA-aware static file server for Flutter web builds."""

import http.server
import os
import sys
import posixpath

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080


class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        _, ext = posixpath.splitext(self.path.split("?")[0])
        if not ext:
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            with open("index.html", "rb") as f:
                content = f.read()
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)
            return
        return super().do_GET()

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    web_dir = os.path.join(script_dir, "build", "web")
    if not os.path.isfile(os.path.join(web_dir, "index.html")):
        print("Error: build/web/index.html not found. Run 'flutter build web' first.")
        sys.exit(1)
    os.chdir(web_dir)
    with http.server.HTTPServer(("", PORT), SPAHandler) as server:
        print(f"Serving at http://localhost:{PORT}")
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nStopped.")
