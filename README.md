# Cairn — Gentle Habit Coach

> Working name. Final App Store name and trademark check are still required before submission.

Cairn is a calm, shame-free habit app for people who struggle with consistency. Instead of pressuring users with rigid streaks, Cairn helps them place one small stone at a time, return after messy days, and build routines that feel easy to restart.

**Current product direction:** v1.0 is a polished local-first habit app. AI, subscriptions, ads, Cloud sync, and Sign in with Apple are intentionally deferred until the core habit loop proves useful.

**Status:** Week 3 — v1.0 scope cleanup, onboarding, custom habit flow, settings, accessibility, and App Store polish.

## v1.0 product promise

Cairn should do one thing extremely well:

> User opens the app → creates a tiny habit → gets a gentle reminder → places a stone → sees progress → wants to return tomorrow.

## v1.0 scope

The first public release should be beautiful, stable, and focused.

### Included in v1.0

- Onboarding
- Template habits
- Custom habit creation
- Reminder time
- Cue / note
- Place stone / log habit
- Habit detail
- Edit / delete habit
- Local notifications
- Basic Coach tips, rule-based only
- Settings
- Privacy Policy / Terms of Use links
- Accessibility polish
- Seeded App Store screenshots

### Explicitly deferred after v1.0

- CloudKit sync UI and cross-device sync validation
- Sign in with Apple
- Subscription / Cairn Plus
- Paywall
- Ads
- AI Coach with backend
- RAG rules
- Personalized weekly plans
- Smart reminder suggestions
- Advanced insights
- Widgets / Live Activities / Watch app

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
| Notifications | UserNotifications | Gentle local reminders |
| Sync | CloudKit capability may exist | Hidden from v1.0 UI until verified |
| Authentication | None in v1.0 | Sign in with Apple deferred |
| Coach | Rule-based tips | No external AI calls in v1.0 |
| Subscriptions | None in v1.0 | Cairn Plus deferred |
| Ads | None in v1.0 | Preserve premium first impression |
| Analytics | Deferred | Add after core UX is stable |
| Crash reporting | Deferred | Add during beta/polish if needed |

## Architecture

Pragmatic clean architecture for SwiftUI:

```text
Cairn/App/                 App entry, root navigation
Cairn/Core/Models/         SwiftData @Model classes, no SwiftUI imports
Cairn/Core/Services/       HabitService, NotificationService, etc.
Cairn/Core/DesignSystem/   Reusable colors, spacing, components
Cairn/Features/<Feature>/  Views + optional ViewModels
```

Rules:

- Models do not import SwiftUI.
- Services are small, testable, and work with `ModelContext`.
- ViewModels are used only for multi-step or complex state.
- Views stay thin and use services instead of owning persistence logic.
- Premium, sync, and AI code must be behind feature flags until enabled.

Recommended feature flags:

```swift
enum FeatureFlags {
    static let cloudSyncEnabled = false
    static let signInWithAppleEnabled = false
    static let subscriptionsEnabled = false
    static let aiCoachEnabled = false
}
```

## Roadmap

### v1.0 — Beautiful local MVP

Goal: ship a stable App Store-ready habit loop.

- Onboarding to first habit
- Template habit picker
- Custom habit form
- Reminder time + cue / note
- Local notifications permission pre-prompt
- Today screen with place-stone interaction
- Habit detail with stats, heatmap, recent stones
- Edit and delete flows
- Basic Coach tips
- Settings with legal links and local-data messaging
- Accessibility and screenshot polish

### v1.1 — Trust and sync

- CloudKit sync validation
- iCloud sync settings UI
- Sign in with Apple if needed
- Export / restore improvements
- Better notification controls

### v1.2 — Revenue foundation

- Cairn Plus
- Paywall
- Unlimited habits
- No ads option
- Basic weekly review / insights

### v1.3 — AI Coach

- Backend API
- Provider routing
- Safety / intent routing
- RAG rules
- Personalized weekly plans
- Smart reminder suggestions

### v1.4+

- Widgets
- Live Activities
- Apple Watch
- Advanced insights
- Optional ads for free users only if they do not damage the calm experience

## Claude Code workflow

Use Claude Code as implementation hands, not as product owner.

Good task format:

```text
Implement one feature only.
Do not add subscriptions, CloudKit UI, Sign in with Apple, ads, or AI.
Keep the v1.0 local-first scope.
Follow existing SwiftUI design system and architecture.
After changes, summarize files modified and manual test steps.
```

## Documents

- `PROGRESS.md` — live build tracker and session checklist
- `ROADMAP.md` — optional detailed roadmap if maintained separately
- `DESIGN.md` — design system, logo, copy, screenshots, UI references
- `ARCHITECTURE.md` — technical architecture and data model

## Revenue strategy

v1.0 does not monetize immediately. The purpose of v1.0 is to prove retention.

Revenue comes later only if users return:

1. Validate core loop.
2. Add trust layer: sync and account if needed.
3. Add Cairn Plus with real premium value.
4. Add AI Coach only when backend, safety, and cost controls are ready.

First success metric:

> Can 10 strangers install Cairn and keep using it for 7 days?
