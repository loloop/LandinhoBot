# Run category imports in Vapor

The existing Vapor backend will own schedule ingestion, with category-specific providers feeding one import pipeline shared by scheduled runs and the admin refresh action. This reuses the application's server and database instead of introducing a separate ingestion service. Valid rounds can publish even when another round is rejected; rejected rounds are flagged and retain their last good data, while failed downloads or unrecognisable documents publish no changes.
