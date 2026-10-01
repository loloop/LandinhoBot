#!/usr/bin/env python3
"""Read-only, deterministic Siri /next-races and /category fixture API."""
import argparse
import json
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit


def category(index, title, tag):
    return {"id": f"00000000-0000-0000-0000-{index:012d}", "title": title, "tag": tag}


def event(index, title, date, main, cancelled=False, day=None):
    return {
        "id": f"10000000-0000-0000-0000-{index:012d}",
        "title": title,
        "date": date.strftime("%Y-%m-%dT%H:%M:%SZ") if date else None,
        "isMainEvent": main,
        "isCancelled": cancelled,
        "scheduledDay": day,
    }


def round_(index, title, category_, events):
    return {
        "id": f"20000000-0000-0000-0000-{index:012d}",
        "title": title,
        "shortTitle": title,
        "category": category_,
        "events": events,
        "isCancelled": False,
    }


class Fixture:
    def __init__(self):
        self.now = datetime.now(timezone.utc).replace(microsecond=0)
        self.f1 = category(1, "Fórmula 1", "f1")
        self.stock = category(2, "Stock Car Brasil", "stock")
        self.categories = [self.f1, self.stock]
        self.rounds = [
            round_(1, "São Paulo", self.f1, [
                event(1, "Treino livre", self.now + timedelta(hours=1), False),
                event(2, "Corrida", self.now + timedelta(days=2, hours=3), True),
                event(3, "Sprint cancelada", self.now + timedelta(minutes=30), True, True),
            ]),
            # Deliberately on page 2: round order must not decide the next start.
            round_(2, "Interlagos", self.stock, [
                event(4, "Corrida 1", self.now + timedelta(days=1, hours=2), True),
            ]),
        ]

    def response(self, path, query):
        parts = path.strip("/").split("/")
        mode = parts[0] if len(parts) == 2 else "confirmed"
        endpoint = parts[-1]
        if mode == "offline":
            return 503, {"reason": "The local evidence fixture is unavailable."}
        if endpoint == "category":
            return 200, self.categories
        if endpoint != "next-races":
            return 404, {"reason": "This fixture only serves public calendar reads."}
        rounds = self.rounds
        if mode == "pending":
            rounds = [round_(3, "São Paulo", self.f1, [
                event(5, "Corrida", None, True, day=self.now.strftime("%Y-%m-%d")),
            ])]
        elif mode == "cancelled":
            rounds = [round_(4, "São Paulo", self.f1, [
                event(6, "Corrida", None, True, cancelled=True),
            ])]
        elif mode == "empty":
            rounds = []
        tag = query.get("category", [""])[0]
        if tag:
            rounds = [round_ for round_ in rounds if round_["category"]["tag"] == tag]
        page = int(query.get("page", ["1"])[0])
        # Smaller pages reproduce API-imposed page limits and exercise traversal.
        per = 1
        return 200, {
            "items": rounds[(page - 1) * per:page * per],
            "metadata": {"page": page, "per": per, "total": len(rounds)},
        }


def serve(port):
    fixture = Fixture()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            url = urlsplit(self.path)
            code, body = fixture.response(url.path, parse_qs(url.query))
            encoded = json.dumps(body, ensure_ascii=False).encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

    print(f"Siri fixture http://127.0.0.1:{port}; clock {fixture.now.isoformat()}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=18088)
    serve(parser.parse_args().port)
