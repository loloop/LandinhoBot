#!/bin/bash
set -euo pipefail

# Run from the worktree root. This script does not build or boot a simulator.
# The evidence entry/source must be restored before the shipping build and commit.
operation="${1:-}"
baseline="${2:-a356e86}"
backup="/tmp/landinho-session-notifications-app-entry.swift"
entry="app/VroomVroom/VroomVroomApp.swift"
generated="app/LandinhoCore/Sources/EventDetail/ReminderEvidenceBaseline.swift"

case "$operation" in
  install)
    test ! -e "$generated"
    test ! -e "$backup"
    cp "$entry" "$backup"
    git show "$baseline:app/LandinhoCore/Sources/EventDetail/EventDetail.swift" > "$generated"
    python3 - "$generated" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
source = path.read_text()
source = source.replace('EventDetail', 'ReminderBaselineEventDetail')
source = source.replace('MainEventsView', 'ReminderBaselineMainEventsView')
path.write_text('// Baseline source with symbol renames only, for native evidence.\n' + source)
PY
    cp docs/evidence/session-notifications/PreviewHarness.swift "$entry"
    ;;
  restore)
    test -e "$backup"
    cp "$backup" "$entry"
    rm -f "$backup" "$generated"
    ;;
  *)
    printf '%s\n' 'Usage: bash docs/evidence/session-notifications/prepare-source.sh install [baseline-commit] | restore' >&2
    exit 2
    ;;
esac
