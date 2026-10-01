# LandinhoBot development

This repository contains the Vapor schedule API (`backend`), the VroomVroom iOS app (`app`), and the Telegram client (`telegram`). The backend imports the official F1 calendar automatically, including published future seasons and preseason testing. Stock Car Brazil is the next provider; it is not implemented yet.

## Run the backend

Use Swift 5.9 or newer and PostgreSQL 15 or newer. On macOS, use the full Xcode toolchain for tests:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Start the development database with Docker Compose:

```sh
docker compose -f backend/docker-compose.yml up -d db
```

Then run the backend from the repository root:

```sh
export LANDINHO_ADMIN_PASSWORD='<your-long-random-admin-password>'
swift run --package-path backend App serve --hostname 127.0.0.1 --port 8080
```

The Compose database matches the backend's default credentials. For another PostgreSQL instance, set `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, and `DATABASE_NAME`. Migrations run at startup. The backend creates an F1 category if needed and enables its official provider with a seven-day interval.

The scheduler checks local due dates an hour apart, beginning ten seconds after startup. It downloads source pages only when a category is due. Set `SCHEDULE_IMPORTS_ENABLED=false` to disable scheduled imports locally; manual refresh remains available.

**Maintenance follow-up (01/10/2026):** Mauricio — check the registration, renewal, and DNS configuration for `vroomvroom.racing`. The hosted API hostname `api.vroomvroom.racing` returned `NXDOMAIN` during the availability check. After resolving the domain issue, verify that `https://api.vroomvroom.racing/category` responds successfully.

## Run the iOS app

Open `app/VroomVroom.xcodeproj` in Xcode and select the `VroomVroom` scheme. In the scheme's Run environment, set `LANDINHO_API_URL=http://127.0.0.1:8080` for the simulator. Without that override, the app uses the hosted API. The workspace uses sibling Swift packages within `app`.

Select the shared `VroomVroomMock` scheme to run with in-memory networking. This builds a separate app, displayed as **VroomVroom Mock**, with bundle ID `me.mauriciocardozo.racing.vroomvroom.mock`. It includes sample F1 and Stock Car schedules with confirmed, pending, and cancelled sessions. Category, race, event, and import-settings edits stay in memory and reset on launch. Manual import refresh creates a simulated successful audit entry without downloading schedules. The hidden admin prompt accepts any nonempty password in this mock app, with verification handled in memory. No backend or `LANDINHO_API_URL` is needed; unsupported routes fail locally. The mock app does not embed the live widget extension.

The mock implementation lives in the `MockAPIClient` Swift package target. Only the mock app target defines `MOCK_NETWORKING` and injects that service into its root store.

In the app, hold the version row in Settings for 1.5 seconds (or use its VoiceOver “Abrir administração” action), then enter the server's admin password. Open Formula 1 → Importações. This screen controls automatic imports and the interval, starts a manual refresh, and shows import history, before/after changes, warnings, and ambiguous matches. Selecting an existing record for an ambiguous match triggers a new import using that identity.

The password is verified by `GET /admin-session` before administration opens. The app keeps the credential only in memory, sends it only to administrative endpoints, and clears it when you choose **Bloquear**, leave administration, background the app, or receive an unauthorized administrative response. A canceled verification cannot restore a locked credential. No password is shipped in the app or saved in UserDefaults.

## Administrator access and deployment

Set `LANDINHO_ADMIN_PASSWORD` in the backend process environment or deployment secret store. Docker Compose forwards this variable without a default password. Missing, empty, or whitespace-only configuration disables all administrative routes with HTTP 503; public calendars and Telegram subscriptions continue to work. Invalid or missing credentials receive HTTP 401. Restart every backend instance after setting or rotating the password; previously entered passwords will then fail and the app will lock on its next administrative request.

The API uses HTTP Basic authorization with username `admin` and the configured shared password. Deploy behind verified HTTPS and avoid recording Authorization headers in proxy logs. The app permits plain HTTP administration only for loopback development URLs. There are no user accounts or persisted server sessions. Deploy the protected backend together with this app update: older app builds can still read calendars but their administrative requests will be rejected. Scheduled imports run internally and do not require an HTTP credential.

Protected endpoints include `POST/PATCH /category`, `POST/PATCH /race`, `POST /events`, the existing destructive `GET /prune-race`, `GET /admin-session`, and every import endpoint below. `GET /category`, `GET /race`, `GET /events`, `GET /next-race`, `GET /next-races`, reminder reads, and Telegram subscription operations remain public.

Public category JSON (including categories embedded in calendar responses) contains category identity, title, tag, and comment; import configuration is returned only by the protected import settings endpoint.


## Import behavior

Imports update future and ongoing meetings; they do not backfill past meetings. Source values overwrite manual corrections on every successful import, even when the upstream data is unchanged. Manually added records and records missing from the latest source remain available with warnings. Explicit cancellations are retained and excluded from upcoming schedules and reminders.

Unknown session times use a nullable `date` and an optional `scheduledDay`; numeric placeholders marked TBC by F1 are never published as confirmed times. The app and bot explain pending times and link the official schedule. Confirmed times use the source's explicit UTC offset and are displayed in the client's timezone.

Each meeting and its audit changes commit in one transaction. An invalid meeting retains its last good data while other valid meetings can publish. A failed calendar discovery publishes no changes. PostgreSQL advisory locks prevent overlapping imports for the same category across backend instances.

The admin API endpoints are:

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/import-settings?category=f1` | Current provider and schedule |
| PATCH | `/import-settings` | Set `categoryTag`, `enabled`, and `intervalDays` from 1 to 365 |
| POST | `/import-refresh` | Refresh the supplied `categoryTag`, even if automation is disabled |
| GET | `/imports?category=f1&page=1&per=25` | Paginated run history and diffs |
| POST | `/import-match` | Link a candidate using `runID`, `issueIndex`, and `recordID` |

Example manual refresh:

```sh
curl --fail -H 'Content-Type: application/json' \
  --user "admin:${LANDINHO_ADMIN_PASSWORD}" \
  --data '{"categoryTag":"f1"}' http://127.0.0.1:8080/import-refresh
```

## Verify changes

The mock networking tests cover schedule loading through the reducer, category filtering, pagination, pending and cancelled sessions, in-memory admin edits, simulated imports, and local request failures. Run them from the package directory using the full Xcode toolchain, replacing `SIMULATOR_ID` with an available iOS simulator ID from `xcrun simctl list devices`:

```sh
cd app/LandinhoCore
xcodebuild -skipMacroValidation -scheme LandinhoCore-Package \
  -destination 'platform=iOS Simulator,id=SIMULATOR_ID' CODE_SIGNING_ALLOWED=NO test
```

Parser tests run without a database:

```sh
swift test --package-path backend
```

Integration tests require a separate disposable database. They truncate schedule and subscription tables, so never point them at development data you want to keep or at production. For the Compose database:

```sh
docker compose -f backend/docker-compose.yml exec db \
  createdb -U race_username landinho_test
LANDINHO_TEST_DATABASE=1 DATABASE_NAME=landinho_test \
  swift test --package-path backend
```

The tests cover F1 parsing, pending times, future-season discovery, identity preservation, manual corrections, missing records, partial imports, cancellations, reminder filtering, failed fetches, concurrent imports, matching, history, and scheduling. Admin route tests run without a database and verify missing, malformed, wrong, valid, and unconfigured credentials across every protected route. App package tests in `AdminSessionTests` and `SettingsTests` cover credential scope, lock invalidation, successful verification, error states, and authorized retry.

Build the app for a simulator from the command line:

```sh
xcodebuild -skipMacroValidation -project app/VroomVroom.xcodeproj \
  -scheme VroomVroom -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

## Add a category provider

Implement `ScheduleProvider` in `backend/Sources/App/Importing`, register it in `ScheduleImporter`, and configure its category's provider ID. Providers return source identities, official links, meeting dates, sessions, and discovery issues. Include rejected meeting URLs in `discoveredURLs` so a parsing failure cannot be mistaken for a disappearance. Fetch failures must throw instead of returning a valid empty snapshot.

The F1 provider reads structured JSON from official page scripts without executing them. It probes successive seasons until an explicit HTTP 404, and follows published season links. HTTP failures and unrecognisable calendar pages fail the run. Meeting failures are reported individually. Source layout changes require parser maintenance; fixtures in `backend/Tests/AppTests/Fixtures` preserve confirmed, pending, and testing examples.

The decisions are recorded in [the glossary](GLOSSARY.md) and [the ingestion ADRs](docs/adr/0001-automatically-publish-schedule-imports.md).

## Telegram client

The bot reads schedules and reminders from the backend at `http://localhost:8080`. Build it with `swift build --package-path telegram`. Running it requires `TELEGRAM_TOKEN`; `DEBUG_CHAT` is optional. Starting the bot contacts Telegram and can send scheduled reminders to subscribed chats, so use a separate development token and database for local work.

With the current Xcode Swift 6.4 toolchain, the pinned TelegramBotSDK fails to compile its existing `readToken` string concatenation in `Utils.swift`. This is independent of schedule ingestion. The updated schedule models and message formatting were compiled separately and checked against live confirmed and pending F1 responses; a full bot build still needs that upstream compiler issue resolved. No SDK upgrade is included in this change.

## Release compatibility

Deploy nullable-time support in the iOS and Telegram clients before enabling imports against a shared production backend. Older clients require a non-null session date and cannot decode pending sessions. To stage the backend migration without starting automation, set `SCHEDULE_IMPORTS_ENABLED=false` until compatible clients are released. The schema rollback refuses to restore a non-null date column while pending rows exist.
