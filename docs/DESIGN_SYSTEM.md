# FrostParts — Design System & UI Handoff

**Audience:** Flutter developers extending this app (e.g. owner/admin dashboards, system status, monitoring screens).

**Product:** FrostParts (`erd_rezzer`) — Windows desktop ERP for ERB-Frezzer.

**Rule of thumb:** Reuse `Theme.of(context)`, `AppColors`, and shared widgets. Do not invent parallel colors or radii unless design explicitly asks for it.

---

## 1. Where the theme lives

| File | Purpose |
|------|---------|
| `lib/core/theme/app_colors.dart` | Color tokens + radius constants |
| `lib/core/theme/app_theme.dart` | `ThemeData` (Material 3, component themes) |
| `lib/app.dart` | Applies `AppTheme.light(locale: _locale)` on `MaterialApp.router` |

```dart
// Always prefer theme tokens over hard-coded colors
import '../../core/theme/app_colors.dart';

Theme.of(context).colorScheme.primary;
AppColors.borderRadius;
```

---

## 2. Framework & mode

- **Material 3:** `useMaterial3: true`
- **Theme:** Light only (no dark theme yet)
- **Density:** `VisualDensity.standard`
- **Scaffold background:** `AppColors.surface` (`#F8FAFC`)

---

## 3. Color palette

All colors are defined in `AppColors`. Use semantic names, not raw hex, in UI code.

### 3.1 Brand & surfaces

| Token | Hex | Usage |
|-------|-----|--------|
| `primary` | `#3730A3` | App bar, primary actions, info status |
| `onPrimary` | `#FFFFFF` | Text/icons on primary |
| `primaryContainer` | `#E0E7FF` | Table headers, chips, info backgrounds |
| `onPrimaryContainer` | `#1E1B4B` | Text on primary container |
| `secondary` | `#7C3AED` | Focus rings, accents, nav indicator |
| `onSecondary` | `#FFFFFF` | Text on secondary |
| `secondaryContainer` | `#EDE9FE` | Secondary tinted areas |
| `onSecondaryContainer` | `#4C1D95` | Text on secondary container |
| `tertiary` | `#0D9488` | Teal accent (charts, highlights) |
| `tertiaryContainer` | `#CCFBF1` | Tertiary backgrounds |
| `onTertiaryContainer` | `#134E4A` | Text on tertiary container |
| `surface` | `#F8FAFC` | Page background (shell content area) |
| `onSurface` | `#0F172A` | Primary body text |
| `onSurfaceVariant` | `#64748B` | Labels, hints, secondary text |
| `surfaceContainerHighest` | `#FFFFFF` | Cards, inputs, panels |
| `outline` | `#E2E8F0` | Borders, dividers |
| `outlineVariant` | `#CBD5E1` | Outlined button borders |

### 3.2 Feedback (status / alerts)

| Token | Hex | Usage |
|-------|-----|--------|
| `success` | `#059669` | Online, OK, completed |
| `successContainer` | `#D1FAE5` | Success chip/card background |
| `onSuccessContainer` | `#064E3B` | Success text |
| `warning` | `#D97706` | Offline, caution |
| `warningContainer` | `#FEF3C7` | Warning banners/chips |
| `onWarningContainer` | `#78350F` | Warning text |
| `error` | `#DC2626` | Errors, validation |
| `onError` | `#FFFFFF` | Text on error buttons |
| `errorContainer` | `#FEE2E2` | Inline error boxes |
| `onErrorContainer` | `#7F1D1D` | Error message text |

### 3.3 Navigation rail

| Token | Hex |
|-------|-----|
| `navRailBackground` | `#1E293B` |
| `navRailForeground` | `#94A3B8` (unselected) |
| `navRailSelected` | `#FFFFFF` |
| `navRailIndicator` | `#7C3AED` at ~35% alpha |

### 3.4 Gradients (login / marketing only)

Login hero uses:

```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primary, AppColors.secondary],
)
```

Do not use this gradient on standard in-app admin screens; use `surface` + cards instead.

---

## 4. Border radius & shape tokens

Defined in `AppColors`:

| Constant | Value (px) | Apply to |
|----------|------------|----------|
| `borderRadius` | **12** | Cards, dialogs, data tables, shell content panel, entity profile header |
| `inputRadius` | **10** | Text fields, buttons, snackbars, stat highlight cards, list entity rows |
| *(chip / status)* | **20** | `StatusChip`, theme `ChipTheme`, top-bar info chips |
| *(list tile)* | **8** | `ListTileTheme`, `EntityListTile` ink splash |

**Card shape (default):**

- Radius: `12`
- Border: `1px` `AppColors.outline`
- Elevation: `0` (flat; separation via border + optional light shadow on shell panel)

**Input shape:**

- Radius: `10`
- Filled background: white (`surfaceContainerHighest`)
- Default border: `outline`
- Focused border: `secondary`, **width 2**
- Error border: `error`, width 2 when focused

---

## 5. Typography

- **English:** Material 2021 black text theme (system/Roboto stack via Flutter).
- **Arabic (`locale.languageCode == 'ar'`):** `GoogleFonts.cairoTextTheme(...)`.

### Text styles (overrides in `AppTheme.light`)

| Style | Weight | Color notes |
|-------|--------|-------------|
| `headlineLarge` | w700 | `onSurface`, letterSpacing -0.5 |
| `headlineMedium` | w700 | `onSurface` |
| `headlineSmall` | w600 | `onSurface` — KPI values |
| `titleLarge` | w600 | `onSurface` — screen titles in content |
| `titleMedium` | w600 | `onSurface` |
| `titleSmall` | w700 | Section headers in detail cards |
| `bodyLarge` / `bodyMedium` | default | `onSurface` |
| `bodySmall` | default | `onSurfaceVariant` — labels, captions |
| `labelLarge` | w600 | Buttons |
| `labelMedium` | w600 | Chips, status labels |

**App bar title:** `titleLarge`, w600, `onPrimary`.

**Do not** set random `fontSize` in feature screens unless matching login hero (36 / 16) for a dedicated marketing layout.

---

## 6. Component themes (from `AppTheme`)

### App bar

- Background: `primary`
- Foreground: `onPrimary`
- Elevation: `0`

### Cards

- Fill: white
- Border: `outline`, radius `12`
- No elevation; `surfaceTintColor: transparent`

### Buttons

| Type | Background | Foreground | Padding | Radius |
|------|------------|------------|---------|--------|
| `FilledButton` | `primary` | `onPrimary` | H20 V14 | `inputRadius` (10) |
| `OutlinedButton` | transparent | `primary` | H20 V14 | 10, border `outlineVariant` |

Use `FilledButton.icon` / `OutlinedButton.icon` for toolbar actions (existing pattern).

### Text fields (`InputDecorationTheme`)

- `filled: true`, fill white
- Content padding: **16 × 14**
- Spacing between fields in forms: **16** (`SizedBox`)
- Section gap before primary CTA: **28–32**
- Prefix/suffix icons: standard Material outlined icons (`Icons.email_outlined`, etc.)

### Data tables

- Header row: `primaryContainer` / `onPrimaryContainer`
- Outer border + radius **12**

### Dialogs

- Background: white
- Radius: **12**

### Snackbars

- Floating, radius **10**, background `onSurface` (dark bar)

### Dividers

- Color `outline`, thickness **1**

### Material banner (offline)

- Background: `warningContainer`
- Text: `onWarningContainer`

---

## 7. Forms — patterns to copy

### 7.1 Standard field

```dart
TextField(
  decoration: InputDecoration(
    labelText: l10n.someLabel,
    prefixIcon: const Icon(Icons.person_outline),
  ),
),
const SizedBox(height: 16),
```

Theme supplies borders and focus; only add `InputDecoration` extras (icons, `labelText`, validators).

### 7.2 Dropdown

Use `DropdownButtonFormField` inside the same column layout; it inherits `inputDecorationTheme` when wrapped with `InputDecoration` or placed in themed form (see `customers_screen.dart`, `reports_screen.dart`).

### 7.3 Validation / API errors

Match login screen error box:

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.errorContainer,
    borderRadius: BorderRadius.circular(AppColors.inputRadius),
  ),
  child: Row(
    children: [
      const Icon(Icons.error_outline, size: 20, color: AppColors.onErrorContainer),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: ... onErrorContainer)),
    ],
  ),
)
```

### 7.4 Submit button

- `FilledButton` full width in narrow forms (`CrossAxisAlignment.stretch`)
- Loading: replace label with `CircularProgressIndicator` (22×22, `onPrimary`, strokeWidth 2)

### 7.5 Form width (login reference)

- `ConstrainedBox(maxWidth: 400)` for centered auth forms
- Padding: **48** on auth panel

---

## 8. Layout & shell (desktop)

Authenticated screens use `AppShell`:

```
┌─────────────────────────────────────────────────────────────┐
│ Top bar (primary #3730A3) — logo, StatusChip, user, sync   │
├──────────┬──────────────────────────────────────────────────┤
│ Nav rail │ ShellContentPanel (card, radius 12, pad 16)      │
│ 272px    │   ← your screen content                          │
│ #1E293B  │                                                  │
└──────────┴──────────────────────────────────────────────────┘
```

### Spacing conventions

| Context | Value |
|---------|--------|
| Shell content panel padding | **16** (default) |
| Nav rail header padding | 20, 24, 20, 16 |
| Top bar padding | H20 V10 |
| Card inner padding | **16** |
| KPI card inner padding | **16** |
| Entity list tile padding | H14 V12, outer H12 V4 |
| Empty / error state padding | **32** |
| Wrap spacing in toolbars | **12** / runSpacing **8** |

### New owner/admin status screens

1. Register route under existing shell (same as Dashboard, Reports).
2. Wrap body in `ShellContentPanel` or use `Card` + internal padding **16**.
3. Page title: `headlineSmall` or `titleLarge` at top of column.
4. Use `Wrap` or `GridView` for KPI/status tiles on wide windows.

---

## 9. Shared widgets — reuse these

| Widget | Path | Use for |
|--------|------|---------|
| `ShellContentPanel` | `lib/features/shared/shell_content_panel.dart` | Main content frame |
| `StatusChip` | `lib/features/shared/status_chip.dart` | Online/offline, job state, health |
| `KpiCard` | `lib/features/shared/kpi_card.dart` | Metric tiles (200px min width) |
| `StatHighlightCard` | `lib/features/shared/entity_detail_widgets.dart` | Compact stat blocks |
| `EntityProfileHeader` | same | Entity title + subtitle + chips |
| `DetailSectionCard` | same | Grouped read-only fields |
| `DetailField` | same | Label/value rows |
| `EntityListTile` / `EntityListView` | `entity_list_tile.dart` | Lists |
| `LoadingView` / `ErrorView` | `loading_error.dart` | Async states |

### StatusChip variants

```dart
StatusChip(label: 'Online', variant: StatusChipVariant.success);
StatusChip(label: 'Sync pending', variant: StatusChipVariant.warning);
StatusChip(label: 'API v1', variant: StatusChipVariant.info);
StatusChip(label: 'Unknown', variant: StatusChipVariant.neutral);
```

- Padding: H10 V4
- Radius: **20**
- Optional dot: 8px circle icon

---

## 10. Status & monitoring UI (owner/admin)

Recommended patterns already in the app:

1. **Connectivity / system state** → `StatusChip` in top bar (`AppShell` — success vs warning).
2. **Branch / user context** → `_InfoChip` pattern (semi-transparent white on primary, radius 20).
3. **KPI grid** → `KpiCard` with optional `accentColor` (defaults to `colorScheme.secondary`).
4. **Warning banners** → `MaterialBanner` (theme: warning container).
5. **Charts / tables** → follow Dashboard & Reports screens; table uses themed `DataTable`.

For a dedicated **system health** or **app status** screen:

- Background: inherit shell (`surface`).
- Group sections in `DetailSectionCard` or `Card` with `titleSmall` section headers.
- Use `success` / `warning` / `error` containers for row-level health, not raw red/green hex.
- Align metrics in a `Wrap` with `spacing: 12`, `runSpacing: 12`.

---

## 11. Icons & elevation

- Standard icon size in lists/KPIs: **20–24**
- Small meta icons (info chips): **14**
- Error state hero icon: **48**
- Shadows: minimal — shell panel uses `black @ 4%`, blur 8, offset (0, 2); top bar uses `black @ 10%`, blur 4.

---

## 12. Localization & RTL

- App supports **English** and **Arabic**; default locale `ar` (`AppConstants.defaultLocaleCode`).
- Use `context.l10n` for all user-visible strings.
- Respect `Directionality.of(context)` on rows (see `EntityListTile`, `AppShell`).
- Use `EdgeInsetsDirectional` / `BorderRadiusDirectional` where horizontal start/end matters (e.g. `KpiCard` accent bar).

---

## 13. Checklist for new Flutter work

- [ ] Import `app_colors.dart`; avoid duplicate hex values.
- [ ] Use `Theme.of(context).textTheme` for text styles.
- [ ] Cards: radius **12**, outline border, zero elevation.
- [ ] Inputs & buttons: radius **10**.
- [ ] Status indicators: `StatusChip` or semantic container colors.
- [ ] Place screen inside `AppShell` + `ShellContentPanel` unless full-screen (login).
- [ ] Add strings to ARB l10n files, not hard-coded Arabic/English in widgets.
- [ ] Test with locale `ar` and `en`.

---

## 14. Quick reference — radius map

```
12px  → Card, Dialog, DataTable, ShellContentPanel, EntityProfileHeader
10px  → TextField, FilledButton, OutlinedButton, SnackBar, StatHighlightCard, EntityListTile, error boxes
20px  → StatusChip, ChipTheme, top-bar info chips
8px   → ListTile, EntityListTile InkWell
```

---

## 15. Contact & codebase

- Repo: **erd-frezzer-windows-app** (FrostParts Windows client).
- API: ERB-Frezzer `/api/v1` — business rules live server-side; UI reflects status via existing cubits/blocs (`ConnectivityCubit`, `SyncBloc`, etc.).

When in doubt, open **Dashboard**, **Settings**, or **Purchases** screens and match spacing, cards, and chips before introducing new visual patterns.
