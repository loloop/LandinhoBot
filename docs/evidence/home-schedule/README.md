# Home schedule evidence

Actual SwiftUI screenshots from an iPhone 16 Pro simulator (iOS 27.0), backed by the local fixture in `fixture-server.py`. The fixture contains ten rounds from Formula 1, Formula 2 and Stock Car Brazil; Stock Car is saved locally as a favorite, despite its rounds having later dates. One session has a pending time.

- `before-home.png`: the previously installed compatible app build, using the unchanged baseline Home implementation. Its request has no page or favorite parameters; earlier Formula 1 / Formula 2 rounds appear first.
- `after-home-first-page.png`: the shipping app, showing five loaded rounds and Stock Car globally prioritized, including its pending session.
- `after-home-second-page.png`: actual Root / Router / Home views. A temporary native launch harness sends the same `loadMore` action used by the button after the first response; the counter advances to ten of ten. No screenshot pixels were fabricated.
- `after-categories-favorite.png`: actual `CategoriesView` inside a temporary native `NavigationStack`, loading the category fixture and sending `favoriteTapped("stock")` twice to exercise persistence while returning to the selected state. This captures the category heart independently because Device Hub native accessibility timed out.

The temporary launch harness was removed before the final shipping build. Screenshots use local fixture data, not production data. The backend's actual partition ordering is separately covered by PostgreSQL integration tests.

## Verification

- Backend: 16 tests passed, including global favorite ordering across four pages, chronological / UUID tie-breaks, category filtering, cancelled rounds, pending sessions, ongoing rounds and invalid query parameters.
- Core: 6 simulator tests passed, covering one initial request, repeated load-more guards, deduplication, page-specific retry, failed refresh preservation, favorite ordering invalidation, stale responses, empty refresh, persistence and navigation cancellation / return.
- Final `VroomVroom` simulator build passed after restoring the original app entry and removing the temporary Core package lockfile. Tests used the app's pinned TCA 1.11.2 / Collections 1.1.1 resolutions.

The fixture runs with `python3 docs/evidence/home-schedule/fixture-server.py`; launch the app with `LANDINHO_API_URL=http://127.0.0.1:18083`. Simulator, fixture server and disposable PostgreSQL cluster were stopped after capture.
