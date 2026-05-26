# SH Malik Mobile — Design Kit & Restyle Spec

Goal: every staff/customer screen speaks ONE visual language. Compose the shared
components in `lib/core/ui/ui_kit.dart` instead of hand-rolling card chrome.
Import once: `import '../../../core/ui/ui_kit.dart';`

## Design language
- **Header:** every home/detail screen opens with `AppGradientHeader` (curved navy→blue,
  white title w800 + optional muted subtitle). Put refresh/actions in `actions:` as
  `HeaderIconButton`. The screen body sits in an `Expanded` below it (Column layout),
  NOT inside the gradient.
- **Module accent colors** (`ModuleAccent`): `ops` (blue), `finance` (green), `hr` (violet),
  `brand` (navy, default), `danger` (red/orange). Use your feature's accent consistently:
  Ops→`ModuleAccent.ops`, Finance→`ModuleAccent.finance`, HR→`ModuleAccent.hr`,
  Customer→`ModuleAccent.brand`.
- **Stat tiles:** `StatCard(label, value, icon, accent, danger)`. Lay out as a responsive
  2-col grid: `Wrap(spacing:12, runSpacing:12, children:[SizedBox(width:(W-40-12)/2, child: StatCard(...))])`
  where `W = MediaQuery.sizeOf(context).width`. Set `danger:true` for counts that are bad
  when non-zero (overdue, alerts, pending) — the card auto-turns red only when value != "0".
- **Section titles:** `SectionHeader(title, icon, accent)`.
- **Content rows / list items:** `AppCard(child:, accentColor: statusColor(...), onTap:)`.
  The `accentColor` draws a 5px colored left bar (use it for status: trip status, invoice
  paid/overdue, approval type, etc.). Reuse `statusColor()` from `core/utils/colors.dart`
  where it fits; otherwise your feature's existing status-color helper.
- **Status badges:** `StatusPill(label, color, icon?)`.
- **States:** loading → `AppSkeleton` wrapping `AppSkeleton.box(context, height:, width:, radius:)`
  skeletons that match the real layout; empty → `AppEmpty(icon, message)`; error → `AppError(message, onRetry)`.
- **Type:** `GoogleFonts.inter`. Numbers w800, titles w700, labels w500/600, muted = `kMuted`.
- **Surfaces:** cards use `AppColors.surface(context)`; page background `AppColors.surfaceVariant(context)`.
  Everything is dark-mode aware via `AppColors.*` — never hardcode white/black backgrounds.
- **Tap targets** wrapped in `Material`+`InkWell` (AppCard/StatCard already do this).

## What to restyle (per agent)
Replace ad-hoc Containers/cards/headers in YOUR feature's screens with the kit components.
Keep ALL existing behavior, data loading, navigation, permission gating, and class/constructor
signatures EXACTLY as-is — this is a visual refresh only. Don't touch services, models, or APIs.
Tabs/segmented controls inside a feature: keep them, but render the bar cleanly under the
gradient header (a `TabBar`/chip row), and give each tab its own loading/empty/error via the
kit states. Detail screens also get an `AppGradientHeader` + `AppCard` sections.

## Reference implementation
`lib/core/widgets/app_shell.dart` `_OverviewTab` and `_AccountTab` already use the kit — match
that level of polish. The driver dashboard (`features/dashboard/screens/dashboard_screen.dart`)
is the prior visual benchmark; aim to meet or exceed it.

## v2 — "Operations Command" upgrades (USE THESE)
The kit now carries a stronger aesthetic. Adopt all of it:
- **Typography:** import `core/ui/typography.dart` and use `AppType` for any text you style by
  hand — `AppType.display(size)` (Archivo, headings), `AppType.number(size)` (Archivo tabular,
  for stats/money/counts), `AppType.body(size)` (Manrope), `AppType.eyebrow()` (uppercase tracked).
  Do NOT write `GoogleFonts.inter(...)` anymore. Prefer `AppType` over raw `GoogleFonts.manrope`.
- **`AppGradientHeader` now supports `eyebrow:`** (an uppercase tracked label above the title) and
  renders a blueprint-grid + radar texture automatically. Give every header a short `eyebrow:`
  (e.g. Ops "Fleet & dispatch", Finance "Billing & cash", HR "People & approvals", a driver trip
  "Trip detail", login none). Keep `subtitle:` for context lines.
- **`SectionHeader` now supports `eyebrow:`** — add a 1–2 word eyebrow per section.
- **`RevealOnLoad(delayMs:, child:)`** — wrap the main content blocks/cards of each screen so they
  fade + lift in on load. Stagger lists/sections with increasing `delayMs` (e.g. `index * 60`,
  capped around 300ms). Use it for the hero sections, not every tiny element.
- **`StatCard`** auto-uses Archivo tabular numerals and shows a red dot when a `danger` value is
  non-zero — just pass `accent:` + `danger:`.
- Reference: `core/widgets/app_shell.dart` `_OverviewTab` (eyebrow header + section eyebrows +
  staggered `RevealOnLoad`). Match that level.

## DRIVER & AUTH screens (this round)
Driver screens (`features/dashboard`, `trips`, `check_in`, `inspection`, `profile`) and
`features/auth` previously had bespoke styling and only got a body-font swap. Bring them fully
into the kit: replace hand-rolled gradient headers with `AppGradientHeader`, cards with `AppCard`
(status rail via `statusColor(...)`), badges with `StatusPill`, states with `AppEmpty`/`AppError`/
`AppSkeleton`, and add `RevealOnLoad`. KEEP the driver bottom nav (`AppBottomNav`) exactly as-is —
do not edit `core/widgets/app_bottom_nav.dart`. Keep all routes, GPS/check-in/inspection logic,
and form behavior identical.

## Rules
- Edit ONLY files inside your assigned `features/<x>/` folder. Do not edit the kit, the shell,
  other features, services/models (unless purely cosmetic helpers you already own).
- Do NOT change navigation routes, the home-screen class names, or constructors.
- Do NOT run `flutter pub get`/builds. Match conventions; keep it production-grade.
- The kit is already verified to compile — assume `core/ui/ui_kit.dart` exists.
