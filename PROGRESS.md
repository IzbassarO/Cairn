# Progress tracker

Live status of the Cairn build toward v1.0 App Store submission. Updated each session.

> **Now:** Week 2 — ✅ done. Week 3 starts next session.
> **Submission target:** end of week 8

## Where we are

| Week | Theme | Status |
|---|---|---|
| 1 | Architecture, data, design system | ✅ Done |
| 2 | Habit engine + home (templates, visual cairn, detail) + MVVM-lite refactor | ✅ Done |
| 3 | Onboarding, settings, polish, accessibility pass | ⚪ Next |
| 4 | Widgets + Live Activities scaffolding | ⚪ Not started |
| 5 | AI coach integration (Anthropic) | ⚪ Not started |
| 6 | Monetization + paywall (RevenueCat + AdMob) | ⚪ Not started |
| 7 | Polish, beta, App Store assets | ⚪ Not started |
| 8 | Review, fix, launch | ⚪ Not started |

## Architecture (locked-in)

Pragmatic clean architecture for SwiftUI. Strict MVVM is redundant in SwiftUI; this is the lighter pattern Apple recommends.
Cairn/Core/Models/ SwiftData @Model classes (no logic)
Cairn/Core/Services/ HabitService, NotificationService, StreakCalculator, HabitStatistics
Cairn/Features/<f>/ View + (optional) ViewModel
Cairn/App/ Tab navigation root

Rules:
- **Models** never import SwiftUI.
- **Services** are `@MainActor` structs that take `ModelContext`.
- **ViewModels** (`@Observable`) only when a view has complex multi-step state — currently just `HabitCreationViewModel`.
- **Statistics** live as extensions on `Habit` / `[Habit]`. Pure, testable, no observation.
- **Views** pull `ModelContext` from `@Environment`, construct services ad-hoc. Always thin.
## Week 1 — final checklist
- [x] Strategic frame, version roadmap, design tokens spec, architecture decisions
- [x] Xcode project (Cairn, SwiftUI, SwiftData, CloudKit, Sign in with Apple, Push, Background Modes)
- [x] iOS 17 minimum deployment, Swift Testing target
- [x] GitHub repo connected (`IzbassarO/Cairn`)
- [x] SwiftData @Model classes — `Habit`, `HabitLog`, `CoachMessage`, `UserProfile` (CloudKit-safe schema, optional to-many relationships)
- [x] `StreakCalculator` with healing-streak math (5 unit tests passing)
- [x] Design system: 11 named colors in asset catalog (light + dark), Spacing/Radius tokens, `CairnCard`, `PrimaryButton` components
- [x] First runnable home screen on simulator
- [x] + button persistence (CloudKit-safe schema fix)
- [ ] SwiftLint + SwiftFormat configuration *(deferred — not blocking)*
- [ ] Sentry SDK *(deferred to week 7 polish)*
- [ ] TelemetryDeck SDK *(deferred to week 7 polish)*
- [ ] Secrets.xcconfig pattern *(deferred to week 5 when Anthropic key lands)*
- [ ] CloudKit sync verified across two devices *(deferred to week 3)*
## Week 2 — checklist
- [x] 12 ADHD habit templates with sensible defaults (`HabitTemplate.swift`)
- [x] Real `CairnView` animated stone visualization (capsule shapes, organic tilts, spring animation)
- [x] Habit creation flow (template grid → customize → save)
- [x] Habit detail view with lifetime / days / current-run stats + recent log feed + delete
- [x] `HabitService` typed action wrapper around `ModelContext`
- [x] `HabitStatistics` extensions on `Habit` / `[Habit]`
- [x] `HabitCreationViewModel` (@Observable) for multi-step form state
- [x] Tab bar IA: Today / Coach / Settings (Coach + Settings stubbed with on-brand copy)
- [x] Healing-streak math wired into detail (current run)
- [x] Empty state with "Pick a habit" CTA
- [x] Cleanup: removed `CairnUITests/Cairn` accidental copy
- [x] Habit-delete crash fixed (dismiss-then-delete pattern, modelContext-nil guards)
- [x] `CairnAlert` reusable centered modal component (replaces action-sheet `confirmationDialog`)
- [x] Local notifications via `UserNotifications` per habit's `notificationTimes` *(next turn)*
- [x] Time-Sensitive entitlement applied to medication category *(next turn)*
- [x] Drag-to-reorder rows on home *(next turn)*
- [x] Calendar heatmap on habit detail *(next turn)*

## Week 2 — done ✅
- 12 ADHD habit templates with neuroaffirming blurbs
- Visual `CairnView` (capsule stones, organic tilt, spring animation)
- Habit creation flow (template grid → customize → save)
- Habit detail (header / stats / heatmap / recent logs)
- `HabitService`, `NotificationService`, `HabitStatistics` extensions
- `HabitCreationViewModel` for the multi-step form
- Tab IA: Today / Coach / Settings (Coach + Settings stubbed on-brand)
- Healing-streak math wired into detail
- "Pick a habit" empty state CTA
- `CairnAlert` reusable centered modal
- Habit-delete crash fixed (dismiss-then-delete + modelContext-nil guards)
- **Local notifications** (warm permission prompt at habit-creation, never cold)
- **Time-Sensitive interruption level** for medication category (entitlement deferred to week 7)
- **Drag-to-reorder** rows (`List` + `.onMove`)
- **Calendar heatmap** on detail (`HeatmapView`: 12w × 7d, sage gradient + legend)
## Week 3 — preview (next session)
- Onboarding flow (5 screens, ≤90 sec to first habit logged)
- Sign in with Apple
- Settings: real notifications status + iOS deeplink, sync status, appearance picker, data export, delete-all (using `cairnAlert`)
- Empty / loading / error states for every screen
- Full accessibility pass (VoiceOver, Dynamic Type AX5, Reduced Motion, contrast)
- Localizable.xcstrings scaffolding
- Habit edit flow (name / icon / time)
## Versions on the runway
- **v1.0** (week 8): Public launch
- **v1.1** (~week 10-11): Voice logging, Lock Screen control, Live Activity, Siri

## Week 3 — preview
- [ ] Onboarding flow (5 screens, ≤90 sec to first habit logged)
- [ ] Sign in with Apple
- [ ] Settings screen real implementations (notifications, sync, appearance, data export, delete-all)
- [ ] Empty / loading / error states for every screen
- [ ] Full accessibility pass (VoiceOver, Dynamic Type AX5, Reduced Motion, contrast)
- [ ] Localizable.xcstrings scaffolding (English only at v1.0)
## Versions on the runway
- **v1.0** (week 8): Public launch. See `ROADMAP.md` for full scope.
- **v1.1** (~week 10-11): Voice logging, Lock Screen control, Live Activity, Siri Shortcuts
- **v1.2** (~week 13-14): Apple Watch app + complications
- **v1.3** (~week 16-17): Body-double focus sessions
- **v1.4** (~week 20): Pattern intelligence (AI insights from user data)
- **v1.5** (~week 22): Multiple coach personalities + crisis-aware language
## Decisions log
| # | Decision | When |
|---|---|---|
| 1 | Niche: ADHD-specific habit + focus coach | session 1 |
| 2 | Working name: Cairn | session 1 |
| 3 | iOS 17 minimum | session 1 |
| 4 | Stack: SwiftUI + SwiftData + CloudKit + Anthropic + RevenueCat + AdMob | session 1 |
| 5 | Healing streaks (no resets) | session 1 |
| 6 | Free 3 habits + ads. Pro $4.99/mo, $29.99/yr, $49.99 lifetime | session 1 |
| 7 | Build first, market after launch | session 1 |
| 8 | CloudKit-safe SwiftData: defaults on every prop, no `.unique`, raw-Int enum storage | session 3 |
| 9 | All to-many relationships optional (`logs: [HabitLog]?`) | session 4 |
| 10 | Pragmatic clean architecture: services + statistics extensions + selective ViewModels | session 5 |
| 11 | v1.0 IA: 3 tabs (Today / Coach / Settings) | session 5 |
| 12 | Custom centered modal (`CairnAlert`) over action-sheet for destructive ops | session 6 |
## Open questions / decisions deferred
- (v1.0) Final app name + trademark check + .app domain registration
- (v1.0) Privacy policy + Terms host (cairn.app or alternative)
- (v1.0) Anthropic API key spend limit set in console
- (v1.5) Lawyer review of crisis-content disclaimers before public scale
## What changed in this session (session 6)
- Diagnosed and fixed habit-delete crash (SwiftData cascade-delete vs SwiftUI re-render race)
- Built reusable `CairnAlert` centered modal — branded, animated, dim backdrop with tap-to-dismiss
- Updated PROGRESS.md to reflect actual state (week 2 ~80% done, not "not started")
