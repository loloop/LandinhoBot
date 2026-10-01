"""Local, read-only schedules for reproducing round-link screenshots."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse
from collections import Counter
import json
import uuid

F1_ID = "4caebfb4-c669-46f1-b74e-ad391517f373"
STOCK_ID = "66b884bc-a00d-43e7-993c-bad5dd135c39"
RETRY_ID = "cf5c4363-4495-4e85-b39d-79178541800b"
CATEGORIES = [
    dict(id="f1", title="Fórmula 1", tag="f1"),
    dict(id="stock", title="Stock Car Brasil", tag="stock"),
]


def round_payload(round_id, title, short_title, category):
    return dict(id=round_id, title=title, shortTitle=short_title,
                category=category, isCancelled=False,
                events=[
                    dict(id=str(uuid.UUID(int=100 + CATEGORIES.index(category))),
                         title="Classificação", date="2026-10-10T13:00:00Z",
                         isMainEvent=False, isCancelled=False),
                    dict(id=str(uuid.UUID(int=200 + CATEGORIES.index(category))),
                         title="Corrida", date="2026-10-11T12:00:00Z",
                         isMainEvent=True, isCancelled=False),
                ])


ROUNDS = {
    F1_ID: round_payload(F1_ID, "Grande Prêmio de Singapura", "Singapura", CATEGORIES[0]),
    STOCK_ID: round_payload(STOCK_ID, "Stock Car Brasil — Interlagos", "Interlagos", CATEGORIES[1]),
    RETRY_ID: round_payload(RETRY_ID, "Grande Prêmio de São Paulo", "São Paulo", CATEGORIES[0]),
}
REQUESTS = Counter()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urlparse(self.path)
        query = parse_qs(url.query)
        REQUESTS[url.path] += 1
        status = 200
        if url.path == "/category":
            body = CATEGORIES
        elif url.path == "/next-races":
            items = [ROUNDS[F1_ID], ROUNDS[STOCK_ID]]
            tag = query.get("category", [""])[0]
            if tag:
                items = [item for item in items if item["category"]["tag"] == tag]
            page = max(1, int(query.get("page", ["1"])[0]))
            per = int(query.get("per", ["10"])[0])
            body = dict(items=items[(page-1)*per:page*per],
                        metadata=dict(page=page, per=per, total=len(items)))
        elif url.path.startswith("/rounds/"):
            round_id = url.path.removeprefix("/rounds/").lower()
            if round_id == RETRY_ID and REQUESTS[url.path] == 1:
                status, body = 503, dict(error=True, reason="Local retry fixture")
            elif round_id in ROUNDS:
                body = ROUNDS[round_id]
            else:
                status, body = 404, dict(error=True, reason="Round not found")
        elif url.path == "/_evidence":
            body = dict(REQUESTS)
        else:
            status, body = 404, dict(error=True, reason="Unknown fixture endpoint")
        payload = json.dumps(body, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 18084), Handler).serve_forever()
