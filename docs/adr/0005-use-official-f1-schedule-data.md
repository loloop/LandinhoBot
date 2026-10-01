# Use official F1 schedule data

The first provider will read the official Formula 1 schedule pages rather than depend on a third-party schedule API. The pages expose structured session data together with explicit unconfirmed-time status, allowing LandinhoBot to preserve pending times and link to the official publication. We accept maintaining the parser when the source format changes in exchange for retaining that distinction at the source.

The [official 2027 Bahrain schedule](https://www.formula1.com/en/racing/2027/bahrain) currently displays session dates with times marked TBC, an example the provider must represent without publishing placeholder numeric times as confirmed.

Coverage includes every meeting and session published in the official F1 calendar, including preseason testing. The provider must not restrict discovery to championship rounds or assume every meeting uses the same session format.
