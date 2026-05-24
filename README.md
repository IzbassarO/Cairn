# Cairn — Gentle Habit Coach

> Working name. Final App Store name and trademark check are still required before submission.

Cairn is a calm, shame-free habit app for people who struggle with consistency. Instead of pressuring users with rigid streaks, Cairn helps them place one small stone at a time, return after messy days, and build routines that feel easy to restart.

**Current product direction:** v1.0 is a polished, local-first habit app. AI, subscriptions, ads, Cloud sync, and Sign in with Apple are intentionally deferred until the core habit loop proves useful.

**Status:** v1.0 build well underway. Core loop, onboarding, habit creation (template + custom), habit detail/edit, the home/garden/schedule surfaces, and most of Settings are built. Remaining v1.0 work is the Coach screen, the rest of the Settings detail screens, and final UI/accessibility polish.

## v1.0 product promise

Cairn should do one thing extremely well:

> User opens the app → creates a tiny habit → gets a gentle reminder → places a stone → sees progress → wants to return tomorrow.

## v1.0 scope

The first public release should be beautiful, stable, and focused.

### Included in v1.0

- Onboarding to first habit
- Template habits
- Custom habit creation
- Reminder time + cue / note
- Place stone / log habit
- Habit detail, edit, delete
- Local notifications, with gentle reminder styles and a real-time pause
- Quiet hours
- Basic Coach tips (rule-based only)
- Settings (profile, notifications, appearance, data, about)
- Privacy Policy / Terms of Use links
- Accessibility polish
- Seeded App Store screenshots

### Explicitly deferred after v1.0

- CloudKit sync UI and cross-device sync validation
- Sign in with Apple
- Subscription / Cairn Plus, paywall, ads
- AI Coach with backend, RAG rules, personalized weekly plans
- Smart reminder suggestions
- Advanced insights
- Widgets / Live Activities / Watch app

These are real future directions, but none of their UI or scaffolding ships in v1.0. The first release stays free, local, and focused.

## Positioning

Cairn is not just a habit tracker.

**Core angle:**

> Build habits without shame, streak pressure, or overwhelm.

**Tone:** calm, supportive, premium, direct, never guilt-based.

**Do say:**

- Place the next stone.
- One small step counts.
- Tiny consistency, no pressure.
- Missed a day? You can return gently.

**Avoid saying:**

- You failed.
- Your streak is broken.
- You must complete this.
- AI therapist / medical advice / ADHD treatment.

## Stack

| Layer | v1.0 choice | Notes |
|---|---|---|
| UI | SwiftUI, iOS 17+ | Premium calm visual system |
| Persistence | SwiftData | Local-first for v1.0 |
| Settings state | `AppSettings` (`ObservableObject`) | One source of truth, asked behavioral questions |
| Notifications | UserNotifications | Gentle local reminders, real-time pause |
| Navigation | System sheets + custom `SlideCover` | Bottom-up for modals, horizontal push for drill-in |
| Sync | None in v1.0 | CloudKit deferred until verified |
| Authentication | None in v1.0 | Sign in with Apple deferred |
| Coach | Rule-based tips | No external AI calls in v1.0 |
| Subscriptions / Ads | None in v1.0 | Preserve free, premium first impression |
| Analytics / Crash reporting | Deferred | Add after core UX is stable |

## Architecture

Pragmatic clean architecture for SwiftUI:

```text
Cairn/App/                 App entry, root navigation, global appearance
Cairn/Core/Models/         SwiftData @Model classes, no SwiftUI imports
Cairn/Core/Services/       HabitService, NotificationService, statistics
Cairn/Core/DesignSystem/   Colors, spacing, reusable components, navigation helpers
Cairn/Core/AppSettings     Central settings layer (notifications, quiet hours, appearance)
Cairn/Features/<Feature>/  Views + optional drafts/ViewModels
```

Rules:

- Models do not import SwiftUI.
- Services are small, testable, and work with `ModelContext`.
- Drafts / ViewModels are used only for multi-step or complex state.
- Views stay thin and ask services or `AppSettings` instead of owning logic.
- Settings behavior lives in `AppSettings`, not scattered across screens.

### AppSettings — the settings cascade

`AppSettings` is the single place that owns user preferences and answers
*behavioral questions* rather than handing out raw values:

- `notificationsActive(at:)` — honors the master switch and any active pause
- `isWithinQuietHours(_:)` / `quietHoursWarning(for:)` — for create-habit warnings
- `notificationTitle/Body(for:)` — reminder copy in the chosen tone
- theme + text size applied app-wide from the root

This keeps one setting (quiet hours, pause, reminder style) able to affect many
screens without duplicating logic. As Settings grows, new behavior lands here.

### Navigation

Two intentional motions:

- **Bottom-up (system `fullScreenCover` / sheets)** — modal actions: create a
  habit, pickers, View Garden, the habit list.
- **Horizontal push (`SlideCover`)** — drilling deeper: Settings detail screens,
  Profile → Edit, Add another, calendar, reminders inbox. Button-driven only,
  no edge-swipe, opens and closes horizontally as one unit.

## Roadmap

### v1.0 — Beautiful local MVP (current)

Goal: ship a stable, App Store-ready habit loop. Free and local.

- Onboarding to first habit — built
- Template + custom habit creation — built
- Today / place-stone, garden, schedule — built
- Habit detail, edit, delete — built
- Local notifications, reminder styles, real-time pause, quiet hours — built
- Settings (profile, notifications, appearance scaffolding, data, about) — in progress
- Basic Coach tips — not started (placeholder screen)
- Accessibility + screenshot polish — not started

### v1.1 — Trust and sync

- CloudKit sync validation and iCloud sync settings UI
- Sign in with Apple if needed
- Export / restore improvements
- Richer notification controls

### v1.2 and beyond

Deferred until retention is proven. Possible directions: a paid tier, weekly
review / insights, an AI Coach with a backend, widgets, Live Activities, and an
Apple Watch app. None of these are committed, and none ship in v1.0.

## Claude Code workflow

Use Claude Code as implementation hands, not as product owner.

Good task format:

```text
Implement one feature only.
Do not add subscriptions, CloudKit UI, Sign in with Apple, ads, or AI.
Keep the v1.0 local-first scope.
Follow the existing SwiftUI design system, AppSettings, and navigation helpers.
After changes, summarize files modified and manual test steps.
```

## Documents

- `PROGRESS.md` — live build tracker and session checklist
- `README.md` — product direction, scope, architecture (this file)

## Why free in v1.0

v1.0 does not monetize. The purpose of the first release is to prove that the
core loop earns a return visit. Revenue questions are deferred entirely until
that is true.
