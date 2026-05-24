# Cairn Progress Tracker

Live status of the Cairn build toward v1.0 App Store submission. Updated each session.

> **Now:** Settings build-out and Coach screen remain before feature-complete v1.0, then accessibility and App Store polish.
> **Submission target:** after the local-first v1.0 loop is stable, beautiful, and review-ready.

## Current strategic decision

v1.0 is **local-first, free, and focused**.

The first public release does not include subscriptions, ads, external AI, visible CloudKit sync, or Sign in with Apple. Those remain important but move to later versions so the first release can be stable, polished, and easy to understand. No monetization scaffolding ships in v1.0.

### v1.0 core loop

```text
Onboard → choose/create habit → set reminder + cue → place stone → see progress → return tomorrow
```

## v1.0 scope

### Must ship in v1.0

- [x] Onboarding
- [x] Template habits
- [x] Custom habit
- [x] Reminder time
- [x] Cue / note
- [x] Place stone
- [x] Habit detail
- [x] Edit habit
- [x] Delete habit
- [x] Local notifications
- [ ] Basic Coach tips, rule-based only
- [ ] Settings (most screens built; some detail screens remain)
- [ ] Privacy Policy / Terms of Use links
- [ ] Accessibility polish
- [ ] Great App Store screenshots with seeded data

### Explicitly out of v1.0

- [ ] CloudKit sync UI
- [ ] Cross-device sync promise
- [ ] Sign in with Apple
- [ ] Subscription / Cairn Plus / paywall / ads
- [ ] AI Coach with backend
- [ ] RAG rules / personalized weekly plans / smart reminder suggestions
- [ ] Advanced insights
- [ ] Widgets / Live Activities / Apple Watch

## Where we are

| Phase | Theme | Status |
|---|---|---|
| 1 | Architecture, data, design system | ✅ Done |
| 2 | Habit engine, templates, visual cairn, detail, notifications | ✅ Done |
| 3 | Onboarding + custom habit + first-habit flow | ✅ Done |
| 4 | Home surfaces (today, garden, schedule), navigation system | ✅ Done |
| 5 | Settings build-out + AppSettings + notification pause | 🟡 Current |
| 6 | Coach screen (rule-based tips) | ⚪ Next |
| 7 | Accessibility, localizable strings, screenshots, beta polish | ⚪ Not started |
| 8 | App Store metadata, privacy, final QA, TestFlight, launch | ⚪ Not started |

## Architecture

Pragmatic clean architecture for SwiftUI.

```text
Cairn/App/                 Tab navigation root, app entry, global appearance
Cairn/Core/Models/         SwiftData @Model classes, no SwiftUI imports
Cairn/Core/Services/       HabitService, NotificationService, StreakCalculator, HabitStatistics
Cairn/Core/DesignSystem/   Colors, typography, spacing, components, SlideCover navigation
Cairn/Core/AppSettings     Central settings layer
Cairn/Features/<Feature>/  View + optional draft/ViewModel
```

Rules:

- **Models** never import SwiftUI.
- **Services** are `@MainActor` types that work with `ModelContext`.
- **AppSettings** owns preferences and answers behavioral questions.
- **Statistics** stay pure and testable.
- **Views** stay thin and delegate to services or `AppSettings`.
- **CloudKit, Sign in, subscriptions, ads, and AI** are not present in v1.0.

## Week 1 — done ✅

- [x] Strategic frame, version roadmap, design tokens spec, architecture decisions
- [x] Xcode project: Cairn, SwiftUI, SwiftData, iOS 17 minimum
- [x] Swift Testing target, GitHub repo `IzbassarO/Cairn`
- [x] SwiftData models: `Habit`, `HabitLog`, `CoachMessage`, `UserProfile`, `MoodLog`
- [x] `StreakCalculator` with healing-streak math
- [x] Design system: named colors, spacing/radius tokens, reusable components
- [x] First runnable home screen, persistence fixes for habit creation

## Week 2 — done ✅

- [x] 12 habit templates with supportive blurbs
- [x] Visual `CairnView` / `StoneView` with stone-stack animation
- [x] Habit creation flow: template grid → customize → save
- [x] Habit detail: header, stats, heatmap, recent logs
- [x] `HabitService`, `NotificationService`, `HabitStatistics`
- [x] `HabitCreationViewModel` for multi-step form state
- [x] Tab IA: Today / Coach / Settings
- [x] `CairnAlert` reusable centered modal
- [x] Habit-delete crash fixed, drag-to-reorder, calendar heatmap

## Week 3 — done ✅

- [x] Onboarding pages explaining the Cairn concept
- [x] First-habit flow: pick → reminder time → days → pre-permission → planted
- [x] Custom habit flow: name, icon, category, days, multiple reminder times, cue
- [x] Notification permission asked only after habit/reminder setup
- [x] Habit detail / edit / delete polished (edit as sheet, branded delete confirm)
- [x] Today place-stone interaction, mood selector, up-next, coach card slots

## Week 4 — done ✅

- [x] Home surfaces: Today schedule, Garden (calendar grid, stats hero, day card), reminders inbox
- [x] Navigation system: `SlideCover` for horizontal push (button-driven, no swipe)
- [x] Bottom-up vs horizontal split applied across Settings, Home, Profile
- [x] Whole-cover single-offset transition so headers/back buttons move as one unit

## Week 5 — current 🟡

Goal: finish the Settings area and centralize settings behavior.

### 5.1 AppSettings layer — done ✅

- [x] `AppSettings` ObservableObject over the existing UserDefaults keys
- [x] Behavioral methods: `notificationsActive`, `isWithinQuietHours`, reminder copy
- [x] Injected at app root; theme + text size applied app-wide

### 5.2 Notifications — done ✅

- [x] Master toggle (turns notifications off indefinitely)
- [x] Real-time pause presets: 1 hour / 1 day / 1 week / 1 month
- [x] Live red countdown with resume-at label and Resume now
- [x] Pause stored as an absolute date (survives relaunch, ticks in real time)
- [x] `NotificationService` honors pause + master switch and uses styled copy

### 5.3 Profile — done ✅

- [x] Profile redesign: hero, why card, garden stats, closing note
- [x] Edit profile (display name + why) with horizontal slide
- [x] Display name and why stored globally for reuse across the app

### 5.4 Remaining Settings work — to do

- [ ] App icon picker screen (currently placeholder)
- [ ] Theme picker screen (preference applied; dedicated screen still placeholder)
- [ ] Text size picker screen (preference applied; dedicated screen still placeholder)
- [ ] Export data screen
- [ ] About / Privacy / Terms screens with legal links
- [ ] Delete all data — wire the real wipe
- [ ] Settings footer: "Your data stays on this device in v1.0."
- [ ] Migrate remaining settings screens to read/write through `AppSettings`

### 5.5 Cascade settings into the app — to do

- [ ] Quiet-hours warning when a reminder time falls in rest hours (create/edit habit)
- [ ] Reminder-style tone reflected in scheduled notification copy end to end
- [ ] Haptic feedback setting respected at haptic call sites
- [ ] Display name used in the Home greeting

## Week 6 — next ⚪

Goal: build the Coach screen as curated, rule-based tips (no chatbot, no AI).

- [ ] Replace the Coach placeholder with a real tips screen
- [ ] Today's gentle tip
- [ ] Quick actions: make it smaller, move reminder, reset after a missed day, build a tiny routine
- [ ] Keep all tips rule-based; no external AI calls in v1.0

## Week 7+ — polish and submission ⚪

- [ ] Accessibility pass (Dynamic Type, VoiceOver labels, contrast)
- [ ] Localizable strings extraction
- [ ] Seeded data for App Store screenshots
- [ ] App Store metadata, privacy nutrition labels
- [ ] Final QA, TestFlight beta
- [ ] Launch v1.0
