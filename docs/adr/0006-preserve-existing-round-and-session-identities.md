# Preserve existing round and session identities

The first import will reuse clearly matching existing rounds and sessions, preserving their identities rather than creating a second imported schedule beside the manually entered one. Ambiguous matches are flagged for resolution in the app's admin area instead of being silently merged or duplicated. Subsequent imports use source identity mappings so that changes to titles, times, or round order update the existing records.
