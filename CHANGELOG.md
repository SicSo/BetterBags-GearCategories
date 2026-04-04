## Unreleased

---


## Version 0.2.0 - [04-04-2026]

#### Added
- Added a popup window to inform users of the new gear categories and guide them to the config UI

### Changed
- Changed the design of the UI to make it feel more simplistic

---


## Version 0.1.0 - [28-03-2026]

### Added
- Initial release of BetterBags - Gear Categories
- BetterBags plugin integration for Midnight gear categorisation
- Support for gear category grouping for:
  - Crafted
  - S1 Crafted
  - Season 1
  - Adventurer
  - Veteran
  - Champion
  - Hero
  - Myth
- Dynamic Season 1 category generation based on enabled track categories
- Crafted gear categorisation for general Midnight crafted gear
- Crafted gear categorisation for Midnight Season 1 crafted gear

---

- Config window for managing gear categories
- BetterBags plugin entry with button to open the Gear Categories config
- Per-category enable/disable controls
- Per-category rename support
- Per-category text colour customisation
- Per-category BetterBags priority control
- Per-category pinning support for BetterBags pinned sections
- Per-category pinned-order input with apply button
- Main config toggles for:
  - Enforce order at creation/update
  - Enforce order permanently
- Apply and reset actions for pending category changes

---

- Bind filtering options:
  - Include BoE items
  - Include BoW items
- Default behaviour that excludes BoE and Warbound-style items unless enabled

---

- Per-category status feedback in the config UI:
  - Active
  - Inactive
  - Loading
  - Has unapplied changes

---

- BetterBags category creation and removal based on enabled state
- Automatic BetterBags refresh after category changes
- Automatic restoration of active categories on login
- Retry logic for delayed BetterBags category API availability
- Saved variable support through BBGT_DB
- Legacy saved-variable migration into the current expansion/season structure
- Pinning support for both backpack and bank custom section sort data
- Managed pinned-section ordering support for both backpack and bank
- Persistent category order storage in the database
- Default managed order values:
  - Myth = 1
  - Hero = 2
  - Champion = 3
  - Veteran = 4
  - Adventurer = 5
  - Season 1 = 6
  - S1 Crafted = 7
  - Crafted = 8

### Changed
- All categories now default to BetterBags priority `5`
- Priority is documented as category match priority, not pinned display order
- Category display order is now controlled through pinned-section order values instead of BetterBags priority
- Pinned-order controls are disabled when a category is not pinned
- Ordering can optionally be enforced only on creation/update or continuously while the addon is running

---


## Start of Development
