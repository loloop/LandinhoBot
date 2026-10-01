# Session reminder evidence preparation

This folder contains an evidence harness, not a shipping app entry or a standalone
mockup. It renders the actual EventDetail view and runs the production reducer and
SessionReminderCenter. Native interaction tools are disabled in this environment;
the harness delivers the same reducer action as the session reminder button.

No screenshots or native scheduling/delivery results have been captured yet. The
heavy build and simulator slot is reserved by another task. This document will be
updated with the actual commands, outcomes, and images after that slot is granted.

The prepared modes are:

| Mode | What it checks | Permission/backend |
| --- | --- | --- |
| `before` | Round detail from the parent source, with symbol renames only | Parent source |
| `off` | Upcoming-session controls and cancelled/pending session handling | Injected allowed backend |
| `on` | Opt-in reaches an enabled state after scheduling succeeds | Injected allowed backend |
| `cancel` | The same session action removes an existing reminder | Injected allowed backend |
| `denied` | Denial renders a recoverable error and notification-settings link | Injected denied backend |
| `permission` | The actual production action requests iOS notification permission | Live backend; dialog is left unanswered |
| `native-pending` | Native calendar trigger/request date and pending-request identity | Live native scheduler primitive; no permission grant or display claim |
| `native-provisional` | Real production scheduling followed by a native delivery check | Apple's public provisional authorization, solely as evidence setup |

Injected state images cannot prove an iOS permission grant or visible delivery.
A native pending request cannot prove that iOS displayed a notification. The
permission dialog will not be answered by private APIs, permission database edits,
or automation that bypasses disabled native device access.

The provisional mode uses Apple's documented
[`provisional`](https://developer.apple.com/documentation/usernotifications/unauthorizationoptions/provisional)
authorization option on the task-owned simulator. This noninterrupting setup is
separate from the shipping alert/sound opt-in. The harness then invokes the
production reminder action and checks native pending and delivered notifications;
the run is still pending and no success is claimed. Capture the real shipping
permission prompt first, on a fresh install, before provisional setup. A later
native delivery result will be labeled as provisional authorization evidence.

After obtaining the sole build/simulator lease, run the source preparation from
the worktree root, using the published parent commit for the baseline:

```sh
bash docs/evidence/session-notifications/prepare-source.sh install <parent-commit>
# Build, install, and launch on the exact root-approved task-owned simulator.
# Set SIMCTL_CHILD_LANDINHO_REMINDER_EVIDENCE to a mode above.
# Set SIMCTL_CHILD_LANDINHO_REMINDER_START to a shared ISO8601 UTC session start.
# Capture with simctl io <exact-UDID> screenshot <path>.
bash docs/evidence/session-notifications/prepare-source.sh restore
# Then build the restored shipping app entry.
```

The harness records backend state or native request details in the simulator app's
Documents/session-reminder-evidence.json for runtime verification. The source
preparation script performs no build, simulator boot, or native interaction.
Native mode records are named session-reminder-native-scheduled.json and
session-reminder-native-delivery.json, preserving both the scheduled and delivered
state instead of overwriting the scheduling check.

Reminder behavior is local to this device. Round/schedule reads reconcile only the
rounds supplied by that refresh; there is no background server-change tracking.
An omitted round/session is not treated as an explicit cancellation. UTC triggers
preserve the scheduled instant when the device changes timezone.

Validation so far: the 12 dependency-free SessionReminders tests passed again on
the integrated source, including continued cancellation after another reminder's
reschedule fails. The native adapter typechecked at the initial checkpoint. Swift
syntax parsing, shell syntax validation, and git diff checks pass for this
preparation. The 7 EventDetail and 9 ScheduleList reducer tests have been adapted
or written; their native run, the shipping app build, and runtime evidence are
pending the build lease. Syntax parsing is not a reducer test run.
