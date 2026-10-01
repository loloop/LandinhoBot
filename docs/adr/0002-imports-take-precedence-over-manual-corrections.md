# Imports take precedence over manual corrections

Manual edits correct the currently published schedule; they do not create persistent overrides. Later imports take precedence over those corrections, choosing the source's values rather than requiring a person to release an override. This keeps unattended imports authoritative and avoids a separate layer of permanently pinned schedule fields.

Even a successful import whose source values have not changed can overwrite a manual correction. The admin diff compares the previously published schedule with the resulting published schedule, so those overwrites remain visible.

A round or session absent from the latest import is retained and flagged for inspection rather than automatically deleted or treated as cancelled. This also applies to manually added rounds and sessions that the source has never supplied; their absence does not give the importer a replacement value.

An explicit cancellation from the official source is published automatically: retain the record, mark it cancelled, and suppress its reminders.
