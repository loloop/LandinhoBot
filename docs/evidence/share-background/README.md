# Sharing background

The bundled `SharingCircuit` image is an original AI-generated illustration created with the built-in imagegen tool on 2026-10-01. It depicts a generic circuit, rather than a specific track, team, category, or official photograph. The app icon is a separate asset.

The generated 941 × 1672 PNG was encoded as JPEG at quality 85 for the bundle. No remote image request is needed when previewing or sharing a schedule.

## Generation prompt

> Use case: stylized-concept. Asset type: bundled background illustration for a motorsport calendar app's shareable schedule image. Primary request: an original elegant dark aerial illustration of a race circuit corner. Portrait composition, approximately 9:16. An asphalt racing circuit sweeps diagonally from the upper left through a bend along the right edge, with precise red and cream striped curbs, subtle olive-green infield, a tiny generic open-wheel racing car near the upper right. Editorial textured gouache/print illustration, restrained and sophisticated, charcoal graphite and deep forest greens with small warm cream and racing red accents. The middle of the image should be visually quiet dark tarmac/infield to sit behind an opaque schedule card; enough circuit/curb detail around the top and bottom to remain recognizable when center-cropped to square. Calm late-evening mood, subdued colors, no bright glare. No lettering, numbers, brands, logos, flags, watermark, calendar, UI elements or app icon. This is a background asset only, not a mockup.

## Evidence method

Screenshots and exports were produced on an isolated iPhone 17 simulator running iOS 27.0. A temporary native SwiftUI harness launched the real `SharingView` with five fixed sample session times and selected each of its existing widget/aspect-ratio combinations. It used the real `SharingRenderableView` and `ImageRenderer` with the production proposed export sizes (360 × 360 and 360 × 640 points, scale 3) to save exported images. A separate temporary trigger exercised the actual `SharingView.render` action and system share sheet. The harness and triggers were removed before the final app build and are not included in the app.

The simulator screenshots show the interactive preview. Files named `export-*` show the actual rendered export, encoded as JPEG only to reduce review-artifact size. The asset and views in those exports are the same views used by the system share sheet. Light and dark appearance are included.

All eight layout/appearance combinations were visually inspected. Square exports now measure 1080 × 1080 pixels; portrait exports measure 1080 × 1920. Before this change the large card expanded the requested square export to 1188 × 1248 and overlapped the watermark. The actual system-share action was also checked with a dark square large card.
