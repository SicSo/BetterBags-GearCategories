## Unreleased

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
