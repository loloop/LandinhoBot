# Automatically publish schedule imports

LandinhoBot will automatically fetch and publish forward-looking calendars and session times from free sources, starting with Formula 1 and adding Stock Car Brazil next. Category integrations will be added incrementally, including integrations we maintain for less accessible series such as Turismo Nacional, so that broad coverage does not delay the first working import. Imports will run without an approval step, with manually editable schedules and a visible diff in the app's admin area; this keeps calendars running unattended while allowing corrections and inspection.

Automatic refresh defaults to weekly, is configurable per category, and has a manual refresh action in the app's admin area. Historical backfill, results, standings, news, and broadcast information are outside the current scope.

Forward-looking coverage includes ongoing meetings with future sessions and future meetings as they are published, rather than limiting imports to the current season. Existing past records are outside the refresh scope; lack of historical data in an import is not a disappearance flag.

Manual additions absent from an import are retained and flagged, as described in [the reconciliation decision](0002-imports-take-precedence-over-manual-corrections.md). Initial reconciliation reuses clear existing matches and flags ambiguous ones, as described in [the identity decision](0006-preserve-existing-round-and-session-identities.md).
