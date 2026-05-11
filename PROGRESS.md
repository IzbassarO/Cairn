# Cairn Progress Tracker

Live status of the Cairn build toward v1.0 App Store submission. Updated each session.

> **Now:** Week 3 — v1.0 scope cleanup, onboarding, custom habit flow, settings, accessibility, and App Store polish.
> **Submission target:** after the local-first v1.0 loop is stable, beautiful, and review-ready.

## Current strategic decision

v1.0 is now **local-first and focused**.

The first public release should not include subscriptions, ads, external AI, visible CloudKit sync, or Sign in with Apple. Those are still important, but they move to later versions so the first release can be stable, polished, and easy to understand.

### v1.0 core loop

```text
Onboard → choose/create habit → set reminder + cue → place stone → see progress → return tomorrow
```

## v1.0 scope

### Must ship in v1.0

- [ ] Onboarding
- [ ] Template habits
- [ ] Custom habit
- [ ] Reminder time
- [ ] Cue / note
- [ ] Place stone
- [ ] Habit detail
- [ ] Edit habit
- [ ] Delete habit
- [ ] Local notifications
- [ ] Basic Coach tips, rule-based only
- [ ] Settings
- [ ] Privacy Policy / Terms of Use links
- [ ] Accessibility polish
- [ ] Great App Store screenshots with seeded data

### Explicitly out of v1.0

- [ ] CloudKit sync UI
- [ ] Cross-device sync promise
- [ ] Sign in with Apple
- [ ] Subscription / Cairn Plus
- [ ] Paywall
- [ ] Ads
- [ ] AI Coach with backend
- [ ] RAG rules
- [ ] Personalized weekly plans
- [ ] Smart reminder suggestions
- [ ] Advanced insights
- [ ] Widgets / Live Activities
- [ ] Apple Watch

## Where we are

| Phase | Theme | Status |
|---|---|---|
| 1 | Architecture, data, design system | ✅ Done |
| 2 | Habit engine, templates, visual cairn, detail, notifications | ✅ Done |
| 3 | v1.0 scope cleanup + onboarding + custom habit + settings | 🟡 Current |
| 4 | Accessibility, localizable strings, screenshots, beta polish | ⚪ Next |
| 5 | App Store metadata, privacy, final QA, TestFlight | ⚪ Not started |
| 6 | Launch v1.0 | ⚪ Not started |

## Architecture

Pragmatic clean architecture for SwiftUI.

```text
Cairn/App/                 Tab navigation root and app entry
Cairn/Core/Models/         SwiftData @Model classes, no SwiftUI imports
Cairn/Core/Services/       HabitService, NotificationService, StreakCalculator, HabitStatistics
Cairn/Core/DesignSystem/   Colors, typography, spacing, reusable UI components
Cairn/Features/<Feature>/  View + optional ViewModel
```

Rules:

- **Models** never import SwiftUI.
- **Services** are `@MainActor` structs/classes that work with `ModelContext`.
- **ViewModels** use `@Observable` only when a view has complex multi-step state.
- **Statistics** stay pure and testable.
- **Views** should stay thin and delegate persistence to services.
- **CloudKit, Sign in, subscriptions, ads, and AI** must remain behind feature flags until the target version.

Recommended feature flags:

```swift
enum FeatureFlags {
    static let cloudSyncEnabled = false
    static let signInWithAppleEnabled = false
    static let subscriptionsEnabled = false
    static let aiCoachEnabled = false
}
```

## Week 1 — done ✅

- [x] Strategic frame, version roadmap, design tokens spec, architecture decisions
- [x] Xcode project: Cairn, SwiftUI, SwiftData
- [x] iOS 17 minimum deployment
- [x] Swift Testing target
- [x] GitHub repo connected: `IzbassarO/Cairn`
- [x] SwiftData models: `Habit`, `HabitLog`, `CoachMessage`, `UserProfile`
- [x] `StreakCalculator` with healing-streak math
- [x] Design system: named colors, spacing/radius tokens, reusable card/button components
- [x] First runnable home screen on simulator
- [x] Persistence fixes for + button / habit creation

Deferred from Week 1:

- [ ] SwiftLint + SwiftFormat configuration
- [ ] Sentry SDK
- [ ] TelemetryDeck SDK
- [ ] Secrets.xcconfig pattern
- [ ] CloudKit sync verification

## Week 2 — done ✅

- [x] 12 habit templates with supportive blurbs
- [x] Visual `CairnView` with stone stack animation
- [x] Habit creation flow: template grid → customize → save
- [x] Habit detail: header, stats, heatmap, recent logs
- [x] `HabitService` wrapper around `ModelContext`
- [x] `NotificationService` for local notifications
- [x] `HabitStatistics` extensions
- [x] `HabitCreationViewModel` for multi-step form state
- [x] Tab IA: Today / Coach / Settings
- [x] Healing-streak/current-run math wired into detail
- [x] Empty state with Pick a habit CTA
- [x] `CairnAlert` reusable centered modal
- [x] Habit-delete crash fixed with dismiss-then-delete and `modelContext` guards
- [x] Local notifications from habit `notificationTimes`
- [x] Drag-to-reorder rows on home
- [x] Calendar heatmap on detail

## Week 3 — current plan

Goal: clean the app into the new v1.0 scope and remove premature revenue/sync/AI promises from the user-facing UI.

### 3.1 Scope cleanup

- [ ] Add `FeatureFlags`
- [ ] Hide Sign in with Apple UI
- [ ] Hide iCloud Sync UI
- [ ] Hide subscription / Cairn Plus UI
- [ ] Hide ads-related UI
- [ ] Rename AI Coach copy to basic Coach / Gentle tips
- [ ] Add Settings footer: “Your data stays on this device in v1.0.”

### 3.2 Onboarding

- [ ] Build onboarding pages
- [ ] Explain Cairn concept: stones, no pressure, gentle reminders
- [ ] Let user choose first habit during onboarding
- [ ] Ask notification permission only after habit/reminder setup
- [ ] Finish onboarding by landing on Today with one habit ready

### 3.3 Template + custom habit flow

- [ ] Polish template picker UI
- [ ] Add/confirm Custom habit entry point
- [ ] Add icon picker row
- [ ] Add Name field
- [ ] Add Category picker
- [ ] Add Reminder time
- [ ] Add Add another reminder
- [ ] Add Repeat
- [ ] Add Cue / note
- [ ] Add Notifications toggle
- [ ] Add validation and disabled create state

### 3.4 Today / place stone

- [ ] Make Place stone the main emotional action
- [ ] Add stone placement success state/toast
- [ ] Show reminder time and cue on habit card
- [ ] Avoid streak-shaming language
- [ ] Make empty state lead to habit creation

### 3.5 Habit detail / edit / delete

- [ ] Polish detail page layout
- [ ] Confirm stat cards: lifetime, days active, current run
- [ ] Confirm heatmap card
- [ ] Confirm Today’s rhythm card
- [ ] Confirm Recent stones list
- [ ] Present edit as high-detent sheet
- [ ] Present delete with branded confirmation modal

### 3.6 Basic Coach tips

- [ ] Build Coach screen as curated tips, not chatbot-first
- [ ] Add Today’s gentle tip
- [ ] Add quick actions: Make it smaller, Move reminder, Reset after missed day, Build tiny routine
- [ ] Keep all tips rule-based in v1.0
- [ ] No external AI calls

### 3.7 Settings + legal

- [ ] Preferences: Notifications, Appearance, Habit defaults, Haptic feedback
- [ ] Data: Export data, Clear data
- [ ] Legal: Privacy Policy, Terms of Use
- [ ] About: version, acknowledgements, support
- [ ] Footer: local-first v1.0 data message

## Week 4 — next

Goal: make v1.0 feel App Store ready.

- [ ] Accessibility labels for all custom controls
- [ ] Dynamic Type pass
- [ ] VoiceOver pass
- [ ] Reduced Motion support for stone animations
- [ ] Contrast check in light/dark mode
- [ ] Localizable.xcstrings scaffold, English only for v1.0
- [ ] Empty/loading/error states
- [ ] App icon and launch screen polish
- [ ] Seeded demo data for screenshots
- [ ] App Store screenshot set

## Week 5 — beta and App Store prep

- [ ] TestFlight build
- [ ] Privacy Policy hosted URL
- [ ] Terms of Use hosted URL
- [ ] App Store description
- [ ] Keywords and subtitle
- [ ] Support URL
- [ ] Review all App Privacy answers
- [ ] Manual QA checklist
- [ ] Fix critical bugs

## Post-v1.0 roadmap

### v1.1 — Trust and sync

- [ ] CloudKit sync validation across devices
- [ ] iCloud sync settings UI
- [ ] Sign in with Apple if needed
- [ ] Better notification controls
- [ ] Export/import improvements

### v1.2 — Revenue foundation

- [ ] Cairn Plus
- [ ] Paywall
- [ ] Unlimited habits
- [ ] No ads option
- [ ] Weekly review / basic insights
- [ ] StoreKit or RevenueCat decision

### v1.3 — AI Coach

- [ ] Backend API
- [ ] LLM provider decision
- [ ] Rate limits and cost controls
- [ ] Intent/safety routing
- [ ] RAG rules
- [ ] Personalized weekly plans
- [ ] Smart reminder suggestions

### v1.4+

- [ ] Widgets
- [ ] Live Activities
- [ ] Apple Watch app
- [ ] Advanced insights
- [ ] Optional ads for free tier only if they do not harm the calm experience

## Decisions log

| # | Decision | When |
|---|---|---|
| 1 | Working name: Cairn | session 1 |
| 2 | iOS-first, SwiftUI + SwiftData | session 1 |
| 3 | Healing/current-run model instead of shame-based streaks | session 1 |
| 4 | Pragmatic clean architecture with services + selective ViewModels | session 5 |
| 5 | v1.0 IA: Today / Coach / Settings | session 5 |
| 6 | Custom centered modal for destructive actions | session 6 |
| 7 | v1.0 is local-first: no visible CloudKit sync, Sign in, subscriptions, ads, or external AI | current session |
| 8 | Coach in v1.0 is rule-based tips, not AI chat | current session |
| 9 | CloudKit capability can remain in Xcode, but user-facing sync is deferred | current session |

## Open questions

- [ ] Final App Store name and trademark check
- [ ] Privacy Policy / Terms host
- [ ] Final app icon export sizes
- [ ] Final screenshot copy
- [ ] Whether v1.1 needs Sign in with Apple or only iCloud sync
- [ ] StoreKit vs RevenueCat for v1.2 monetization
- [ ] OpenAI vs Anthropic vs Gemini provider routing for v1.3 AI Coach

## Claude Code prompt template

Use this for each implementation task:

```text
You are working on the Cairn iOS app.

Important scope rule:
This is v1.0 local-first MVP. Do not add or expose CloudKit sync UI, Sign in with Apple, subscriptions, paywall, ads, or external AI. Keep those behind feature flags if related code already exists.

Task:
[describe one small feature only]

Requirements:
- Follow existing SwiftUI design system.
- Keep views thin.
- Use services for persistence/notification logic.
- Do not rewrite unrelated files.
- Preserve iOS 17 compatibility.
- Add accessibility labels where relevant.
- After changes, summarize modified files and manual test steps.
```

## What changed in this session

- Re-scoped v1.0 to a local-first polished habit app.
- Deferred CloudKit UI, Sign in with Apple, subscriptions, ads, and external AI.
- Added clear Week 3 cleanup plan.
- Added post-v1.0 roadmap for sync, revenue, and AI.
- Added Claude Code prompt template for controlled implementation.
