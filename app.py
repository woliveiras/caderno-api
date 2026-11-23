import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import psycopg


def connect():
    # libpq reads PGHOST, PGPORT, PGDATABASE, PGUSER and PGPASSWORD.
    return psycopg.connect(connect_timeout=5)


class Handler(BaseHTTPRequestHandler):
    def respond(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path not in ("/", "/visits"):
            self.respond(404, {"error": "route not found"})
            return
        try:
            with connect() as conn:
                total = conn.execute("SELECT count(*) FROM visits").fetchone()[0]
            self.respond(200, {"visits": total})
        except psycopg.Error:
            self.respond(503, {"error": "database unavailable"})

    def do_POST(self):
        if self.path != "/visits":
            self.respond(404, {"error": "route not found"})
            return
        try:
            with connect() as conn:
                visit_id = conn.execute(
                    "INSERT INTO visits DEFAULT VALUES RETURNING id"
                ).fetchone()[0]
            self.respond(201, {"id": visit_id})
        except psycopg.Error:
            self.respond(503, {"error": "database unavailable"})


if __name__ == "__main__":
    with connect() as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS visits "
            "(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY)"
        )
    ThreadingHTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
