# Progress tracker

Live status of the Cairn build toward v1.0 App Store submission. Updated each session.

> **Now:** Week 1 — architecture & data layer (in progress)
> **Submission target:** end of week 8

## Where we are

| Week | Theme | Status |
|---|---|---|
| 1 | Architecture, data, design system | 🟡 In progress |
| 2 | Habit engine + home (real templates, drag-reorder, healing streaks) | ⚪ Not started |
| 3 | Onboarding, settings, polish | ⚪ Not started |
| 4 | Widgets + Live Activities scaffolding | ⚪ Not started |
| 5 | AI coach integration (Anthropic) | ⚪ Not started |
| 6 | Monetization + paywall (RevenueCat + AdMob) | ⚪ Not started |
| 7 | Polish, beta, App Store assets | ⚪ Not started |
| 8 | Review, fix, launch | ⚪ Not started |

## Week 1 — detailed checklist

- [x] Strategic frame, version roadmap, design tokens spec, architecture decisions
- [x] Xcode project created (Cairn, SwiftUI, SwiftData, CloudKit, Sign in with Apple, Push, Background Modes)
- [x] iOS 17 minimum deployment, Swift Testing target
- [x] GitHub repo connected (`IzbassarO/Cairn`)
- [x] SwiftData @Model classes — `Habit`, `HabitLog`, `CoachMessage`, `UserProfile` (CloudKit-safe schema)
- [x] `StreakCalculator` with healing-streak math (5 unit tests passing)
- [x] Design system: 11 named colors in asset catalog (light + dark), Spacing/Radius tokens, `CairnCard`, `PrimaryButton` components
- [x] First runnable home screen on simulator (greeting, cairn card, empty state, + button)
- [x] + button persistence (CloudKit-safe schema fix)
- [ ] SwiftLint + SwiftFormat configuration
- [ ] Sentry SDK
- [ ] TelemetryDeck SDK
- [ ] Secrets.xcconfig pattern set up
- [ ] CloudKit sync verified across two devices (deferred to week 3)

**Week 1 acceptance:** all checked above.

## Week 2 — preview

- [ ] HabitService (insert, update, archive, reorder)
- [ ] 12 ADHD habit templates with sensible defaults
- [ ] Real CairnView animated stone visualization (lifetime stones, not just count)
- [ ] Drag-to-reorder habits on home
- [ ] Habit detail view with calendar heatmap
- [ ] Local notifications via UserNotifications + per-habit times
- [ ] Time-Sensitive entitlement applied to medication habits
- [ ] Healing-streak UI: copy that never shows "0", warm "welcome back" after misses

## Versions on the runway

- **v1.0** (week 8): Public launch. See `ROADMAP.md` for full scope.
- **v1.1** (~week 10-11): Voice logging, Lock Screen control, Live Activity, Siri Shortcuts
- **v1.2** (~week 13-14): Apple Watch app + complications
- **v1.3** (~week 16-17): Body-double focus sessions (the killer feature for r/ADHD)
- **v1.4** (~week 20): Pattern intelligence (AI-generated insights from user data)
- **v1.5** (~week 22): Multiple coach personalities + crisis-aware language

## Decisions log

| # | Decision | When |
|---|---|---|
| 1 | Niche: ADHD-specific habit + focus coach | session 1 |
| 2 | Working name: Cairn | session 1 |
| 3 | iOS 17 minimum | session 1 |
| 4 | Stack: SwiftUI + SwiftData + CloudKit + Anthropic + RevenueCat + AdMob | session 1 |
| 5 | Healing streaks (no resets), not traditional streaks | session 1 |
| 6 | Free tier: 3 habits + ads. Pro: $4.99/mo, $29.99/yr, $49.99 lifetime | session 1 |
| 7 | Build first, market after launch | session 1 |
| 8 | CloudKit-safe SwiftData: defaults on every prop, no `.unique`, raw-Int enum storage | session 3 |

## Open questions / decisions deferred

- (v1.0) Final app name + trademark check + .app domain registration
- (v1.0) Privacy policy + Terms host (cairn.app or alternative)
- (v1.0) Anthropic API key spend limit set in console
- (v1.5) Lawyer review of crisis-content disclaimers before public scale
