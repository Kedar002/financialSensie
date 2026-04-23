# FinanceSensei - Features Documentation

## Budget Module

### Needs Tab
**Status:** Implemented (UI only, mock data)

The Needs tab displays essential monthly expenses that are non-negotiable.

**Components:**
- Header with menu and action icons
- Title card showing total needs amount
- Category grid (2 columns)

**Actions:**
- Template icon (`file_copy_outlined`) - Opens templates sheet
- Add icon (`add`) - Opens add category sheet
- Tap category - Opens edit category sheet

---

### Templates Feature
**Status:** Implemented (UI only, mock data)

Allows users to save and reuse recurring monthly expense patterns.

**Files:**
- `lib/features/budget/sheets/templates_sheet.dart` - Main templates list
- `lib/features/budget/sheets/template_detail_sheet.dart` - View/import template
- `lib/features/budget/sheets/template_edit_sheet.dart` - Create/edit template

**Flow:**
1. Tap template icon in Needs tab header
2. Templates sheet shows saved templates
3. Tap template to view details and import
4. "Create Template" to add new template

**Template Structure:**
```dart
{
  'name': 'Monthly Essentials',
  'items': [
    {'name': 'Rent', 'amount': 8000},
    {'name': 'Groceries', 'amount': 3000},
    ...
  ],
}
```

**Screens:**

1. **Templates Sheet**
   - List of saved templates
   - Each shows name and total amount
   - "Create Template" button

2. **Template Detail Sheet**
   - Template name as title
   - List of items with amounts
   - Total calculation
   - "Import to Needs" primary action
   - "Edit Template" secondary action

3. **Template Edit Sheet**
   - Template name input
   - Dynamic list of items (name + amount)
   - Add/remove items
   - Save button
   - Delete option (edit mode only)

---

### Wants Tab
**Status:** Implemented (UI only, mock data)

Displays discretionary spending categories.

**Components:**
- Header with menu and action icons
- Title card showing total wants amount
- Category grid (2 columns)

**Actions:**
- Template icon (`file_copy_outlined`) - Opens templates sheet
- Add icon (`add`) - Opens add category sheet
- Tap category - Opens edit category sheet

---

### Wants Templates Feature
**Status:** Implemented (UI only, mock data)

Allows users to save and reuse recurring discretionary expense patterns.

**Files:**
- `lib/features/budget/sheets/wants_templates_sheet.dart` - Main templates list
- `lib/features/budget/sheets/wants_template_detail_sheet.dart` - View/import template
- `lib/features/budget/sheets/wants_template_edit_sheet.dart` - Create/edit template

**Flow:**
1. Tap template icon in Wants tab header
2. Templates sheet shows saved templates
3. Tap template to view details and import
4. "Create Template" to add new template

**Default Template:**
```dart
{
  'name': 'Monthly Fun',
  'items': [
    {'name': 'Dining Out', 'amount': 2000},
    {'name': 'Entertainment', 'amount': 1500},
    {'name': 'Subscriptions', 'amount': 500},
    {'name': 'Shopping', 'amount': 1000},
  ],
}
```

---

### Savings Tab
**Status:** Implemented (Fully functional)

Displays savings goals with progress tracking.

**Features:**
- Create savings goals with target amount, monthly contribution, target date
- Add money to goals (deposits) - creates expense record, affects budget
- Withdraw money from goals - creates record only, does NOT affect budget
- Investment suggestion based on goal timeline
- Progress tracking with percentage and visual bar

**Savings Operations:**

See `docs/SAVINGS_LOGIC.md` for detailed documentation on how deposits and withdrawals work.

| Operation | Type | Budget Impact |
|-----------|------|---------------|
| Add Money (Deposit) | `savings` | Counts as expense, reduces remaining balance |
| Withdraw | `savings_withdrawal` | Record only, no budget impact |

---

### Expenses Tab
**Status:** Implemented (UI only, mock data)

Shows monthly summary and recent transactions.

**Components:**
- Cycle indicator (tap to edit, long-press for cycle review)
- Remaining balance display
- Income/Spent summary cards
- Recent transactions list

**Payment Method Feature:**
- Each expense can be tagged as `cash` or `card` (default: cash)
- Add Expense sheet includes a subtle text toggle: "Paid with Cash / Credit Card"
- Spent card on dashboard shows cash/card breakdown when card expenses exist (e.g., "₹5,500 cash · ₹3,000 card")
- Transaction tiles append "Card" label for credit card expenses
- Expense detail sheet shows payment method (Cash or Card) in the subtitle line

---

### Cycle Complete Screen
**Status:** Implemented (Fully functional)

An elegant dark-themed screen that appears when a budget cycle ends, showing a comprehensive review of the completed cycle.

**File:** `lib/features/budget/screens/cycle_complete_screen.dart`

**Trigger:** Long-press on cycle indicator in Expenses tab

**Design:**
- Dark theme (black background, white text)
- Minimal, premium aesthetic
- No excessive decorations or animations

**Layout:**
1. **Completion Badge** - Circle with checkmark
2. **Cycle Name** - Large title (e.g., "January")
3. **Date Range** - Cycle period
4. **Summary Card:**
   - Unspent/overspent amount (hero number)
   - Spending bar (Needs vs Wants visualization)
   - Legend
5. **Stats Row:** Income, Spent, Saved
6. **Breakdown:** Needs, Wants, Savings with percentages
7. **Primary Action:** "Start New Cycle" button

**Props:**
```dart
CycleCompleteScreen(
  cycleName: 'January',
  cycleStart: DateTime(2025, 1, 15),
  cycleEnd: DateTime(2025, 2, 14),
  totalIncome: 50000,      // in paise
  totalSpent: 35000,       // in paise
  needsSpent: 20000,       // in paise
  wantsSpent: 10000,       // in paise
  savingsAdded: 5000,      // in paise
  onStartNewCycle: () => { /* archive and reset */ },
)
```

**Start New Cycle Behavior:**
When the user taps "Start New Cycle":
1. **Archives cycle to history** - Saves cycle summary to `cycle_history` table
2. **Resets budget categories** - Sets `needs_categories.amount` and `wants_categories.amount` to 0
3. **Preserves:**
   - Expenses (historical transactions, filtered by date range)
   - Savings goals progress (cumulative across cycles)
   - Income categories (recurring income sources)
   - Category structures (just amounts reset, not deleted)
4. **Navigates back** to expenses tab with refreshed data

---

### Statistics Tab
**Status:** Implemented (UI with mock data)

Displays spending trends and comparisons.

**File:** `lib/features/budget/tabs/statistics_tab.dart`

**Features:**
- Month selector to navigate between months
- Bar charts for Needs, Wants, and Savings trends (last 6 months)
- Shows amount and percentage of income for each category
- History button (top right) to access Past Cycles screen

**Design:**
- Minimal, clean cards for each category
- Animated bar charts with selection highlighting
- Color-coded categories (blue/orange/green)

---

### Cycle History Screen
**Status:** Implemented (Fully functional)

A dedicated screen for browsing all past budget cycles.

**File:** `lib/features/budget/screens/cycle_history_screen.dart`

**Navigation:** Statistics tab → History icon (top right)

**Data Source:** `cycle_history` table (up to 120 cycles / ~10 years)

**Features:**
- Cycles grouped by year
- Each cycle shows: name, date range, saved/overspent amount
- Color-coded status indicators (green = saved, red = overspent)
- Tap any cycle to view full report
- Empty state when no cycles exist

**Design:**
- Clean, minimal list design
- Large title "Past Cycles"
- Year section headers
- Generous whitespace
- Subtle separators between items

---

### Cycle Detail Screen
**Status:** Implemented (Fully functional)

A read-only view of a past cycle's complete report.

**File:** `lib/features/budget/screens/cycle_detail_screen.dart`

**Navigation:** Cycle History → Select cycle

**Design:**
- Dark theme (matches cycle complete screen)
- Back button for navigation
- Full breakdown: income, spent, saved, remaining
- Spending bar visualization (needs vs wants)
- Percentage breakdown by category

---

## Calculator Module

### Calculator Hub
**Status:** Implemented

A minimal hub screen listing all available calculators.

**File:** `lib/features/calculator/calculator_screen.dart`

**Navigation:** Drawer → Calculator

**Available Calculators:**
- EMI Calculator - Loan repayment planning
- Budget Planner - 50-30-20 rule allocation
- Time to Payoff - Loan payoff timeline

**Design Principles:**
- Clean list with subtle cards
- Each calculator shows title + short description
- Tap to navigate with fade transition
- Back button to return to hub

---

### EMI Calculator
**Status:** Implemented

A minimal EMI (Equated Monthly Installment) calculator for loan planning with two calculation methods.

**File:** `lib/features/calculator/emi_calculator_screen.dart`

**Navigation:** Drawer → Calculator

**Inputs:**
- Loan Amount (₹) - Principal amount in rupees (P)
- Interest Rate (%) - Annual interest rate (r)
- Loan Tenure (months) - Duration in months (n)

**Outputs:**
- Monthly EMI - Primary result, prominently displayed
- Total Payment - Principal + total interest
- Total Interest - Interest paid over loan tenure

**Calculation Methods:**

1. **Reducing Balance (Diminishing Interest)**
   - Interest calculated on outstanding principal each month
   - As principal reduces, interest decreases
   - EMI remains constant, but interest/principal components change

   ```
   i = r / (12 × 100)  (monthly interest rate)
   EMI = P × i × (1 + i)^n / ((1 + i)^n - 1)
   Total Payment = EMI × n
   Total Interest = Total Payment - P
   ```

2. **Flat / Fixed-on-Original Interest**
   - Interest calculated on original principal for entire tenure
   - Total interest computed upfront
   - EMI = total repayment divided evenly

   ```
   Total Interest (TI) = P × (r / 100) × (n / 12)
   Total Repayment (TR) = P + TI
   EMI = TR / n
   ```

**Why Total Interest Differs:**
- Reducing balance charges interest only on remaining principal
- Flat method charges interest on full original amount throughout
- Flat method always results in higher total interest paid

**Design Principles:**
- Toggle switch to select method (iOS-style segmented control)
- Real-time calculation (no Calculate button needed)
- Large, clear typography for results
- Minimal input fields with subtle underlines
- Currency formatting (K/L/Cr for large numbers)
- Clear button to reset all fields
- Subtle explanation text showing which method is active

**Features:**
- Handles zero interest rate edge case
- Input validation (positive numbers only)
- Smart currency formatting for Indian rupees

---

### Budget Planner (50-30-20 Rule)
**Status:** Implemented

A simple budget allocation calculator using the 50-30-20 rule.

**File:** `lib/features/calculator/budget_calculator_screen.dart`

**Navigation:** Calculator Hub → Budget Planner

**The 50-30-20 Rule:**
- **50% Needs** - Essential expenses (rent, groceries, utilities, insurance)
- **30% Wants** - Discretionary spending (dining, entertainment, shopping)
- **20% Savings** - Savings, investments, debt repayment

**Input:**
- Monthly Income (₹)

**Output:**
- Visual allocation bar showing the split
- Three allocation items with:
  - Category name and percentage
  - Brief description
  - Calculated amount

**Formula:**
```
Needs = Income × 0.50
Wants = Income × 0.30
Savings = Income × 0.20
```

**Design Principles:**
- Single input field (no clutter)
- Horizontal bar visualization of the split
- Color-coded categories (dark to light gradient)
- Vertical color indicator beside each allocation
- Real-time calculation as user types
- Clear button to reset

---

### Time to Payoff Calculator
**Status:** Implemented

Calculate how long it will take to pay off a loan given a fixed EMI.

**File:** `lib/features/calculator/payoff_calculator_screen.dart`

**Navigation:** Calculator Hub → Time to Payoff

**Inputs:**
- Loan Amount (₹) - Principal (P)
- Interest Rate (%) - Annual rate (r)
- Monthly EMI (₹) - Fixed payment amount

**Outputs:**
- Time to Payoff - Number of months/years
- Total Payment - Principal + total interest
- Total Interest - Interest paid over loan duration

**Calculation Methods:**

1. **Reducing Balance (Diminishing Interest)**
   - Interest calculated on outstanding principal each month
   - Iterative calculation until outstanding ≤ 0

   ```
   i = r / (12 × 100)
   Outstanding_0 = P

   For each month k:
     Interest_k = Outstanding_{k-1} × i
     Principal_k = EMI - Interest_k
     Outstanding_k = Outstanding_{k-1} - Principal_k

   Stop when Outstanding_k ≤ 0
   Total Interest = Σ Interest_k
   ```

   **Constraint:** EMI > P × i (first month's interest)

2. **Flat / Fixed-on-Original Interest**
   - Interest calculated on original principal only
   - Monthly interest is constant

   ```
   i = r / (12 × 100)
   Interest_monthly = P × i
   Principal_monthly = EMI - Interest_monthly
   n = ⌈P / Principal_monthly⌉
   Total Interest = Interest_monthly × n
   ```

   **Constraint:** EMI > Interest_monthly

**Error Handling:**
- Shows informative message if EMI is too low
- Caps calculation at 100 years (1200 months)

**Design Principles:**
- Toggle for interest method selection
- Human-readable duration format (e.g., "3 yrs 6 mos")
- Subtle error display (no harsh red colors)
- Real-time calculation as user types

---

## Location Tracker (Hidden Feature)

Hidden behind a 5-second long press on the FD Calculator screen. Typing "hdelete" in the confirmation dialog opens the tracker.

### Entry Point
**File:** `lib/features/calculator/fd_calculator_screen.dart`
- 5-second long press triggers confirmation popup
- Typing "delete" opens data deletion screen
- Typing "hdelete" opens location tracker

### Role Selection
**File:** `lib/features/tracker/screens/role_selection_screen.dart`
- Two roles: Tracker (sends GPS) and Viewer (views on map)
- Both share a hardcoded device ID (`financesensei_tracker_001`)
- No pairing code needed — designed for same-phone use

### Tracker Screen
**Status:** Implemented
**File:** `lib/features/tracker/screens/tracking_screen.dart`
- Toggle button to start/stop GPS tracking
- Background service with smart stationary detection (state machine)
- OEM battery optimization dialog for OnePlus/Oppo

### Smart Tracking Algorithm
**Status:** Implemented
**File:** `lib/features/tracker/core/services/stationary_detector.dart`
- State machine: MOVING → MAYBE_STATIONARY → STATIONARY → MAYBE_MOVING
- Detects visits (places where device stops for 3+ minutes)
- Adaptive GPS polling: 30s when moving/maybeMoving/maybeStationary, 120s when stationary
- MAYBE_MOVING uses fast 30s polling for quick exit detection and accurate geofence boundary crossing
- Per-zone custom intervals (only applied when confirmed stationary)
- GPS readings with accuracy >100m ignored for state transitions
- State persisted to SharedPreferences for crash recovery
- **Accurate timing:** Visit start = first near-anchor GPS timestamp; departure = first far-from-anchor GPS timestamp
- **Unknown placeholder on arrival:** When a visit starts and no zone matches, the visit is recorded immediately with `zone_name = "Unknown"` so the user sees it in History right away. The placeholder is upgraded to a real name when the visit ends (matched zone or auto-zone).
- **Auto-zone creation:** Unknown locations auto-create a 100m geofence zone with a timestamp-based name like `Place 14:32 13 Apr`. Created mid-visit once the visit has run past `minimumVisitDuration` (3 min) if no nearby zone exists, and also on visit end as a fallback. The timestamp format avoids collision with manual zones named `Location N`. Mid-visit creation ensures devices that stay at one place for a long time (including mock-location testing) still get a zone without waiting for departure.

### Viewer Home
**File:** `lib/features/tracker/screens/viewer_home_screen.dart`
- 5 tabs: Map, History, Calendar, Zones, Settings
- IndexedStack for tab switching

### Map Screen
**Status:** Implemented
**File:** `lib/features/tracker/screens/map_screen.dart`
- Real-time location on OpenStreetMap via flutter_map
- Zone circles displayed on map with labels
- Active visit banner ("At Home for 2h 15m")
- Live mode indicator and controls
- Settings-driven display: speed badge, battery badge, accuracy circle, pulsing marker
- Copy coordinates button, connection lost timer
- "Locate" FAB sends `locateNow` command — background service has a Firebase listener that immediately triggers a fresh GPS reading (bypasses timer interval)
- "Live" button to start real-time tracking at custom interval (10s/30s/60s)

### History Screen
**Status:** Implemented
**File:** `lib/features/tracker/screens/history_screen.dart`
- Visit timeline grouped by day
- Each visit shows: zone name (or coordinates), arrival → departure, duration
- Zone name is resolved live from the current geofences (`geofencesStream`) keyed by `visit.zoneId`, falling back to the denormalized `zoneName`. Renaming a zone updates every prior visit's label without rewriting records.
- Transit gaps shown between visits ("In transit — 23m") — tappable → `TransitDetailScreen`
- Daily summary: place count + total tracked time
- Streams visits from Firebase in real-time

### Calendar Screen
**Status:** Implemented
**File:** `lib/features/tracker/screens/calendar_screen.dart`
- Monthly calendar grid with day dots for days with visits
- Tap any day to see full timeline
- Day timeline: visits with arrival/departure/duration, transit gaps, summary
- Transit gaps tap through to `TransitDetailScreen` (same as History)

### Transit Detail Screen
**Status:** Implemented
**File:** `lib/features/tracker/screens/transit_detail_screen.dart`
- Opened by tapping an "In transit" row in History or Calendar
- Top half: `FlutterMap` with a blue polyline drawn from GPS samples between `from.departureTime` and `to.arrivalTime`. Start marker = black, end = blue. Camera auto-fits to the path bounds.
- Bottom: from → to labels, duration, depart/arrive times, sample count (or "No path recorded" if the transit predates continuous logging).
- Data source: `VisitFirebaseService.locationHistoryBetween(deviceId, from, to)` queries `location_history/{deviceId}/points` ordered by timestamp.
- Transits that predate the continuous-logging change show an empty map (only `from`/`to` endpoint dots) with "No path recorded".

### Settings Screen
**Status:** Implemented
**File:** `lib/features/tracker/screens/tracker_settings_screen.dart`
- Display toggles: speed, battery, accuracy circle, pulsing animation
- Units: km/miles, 24hr time
- Alerts: movement, low battery, connection lost (with configurable thresholds)
- Disconnect button
- All settings persisted to SharedPreferences as JSON
- **Dev Tools entry (debug builds only):** opens `TrackerDevToolsScreen` for bug-fix verification

### Dev Tools (Debug-Only)
**Status:** Implemented
**File:** `lib/features/tracker/screens/tracker_dev_tools_screen.dart`
- Hidden from release builds (`kDebugMode` guard)
- Live counts: offline queue size, recent visit count, zone count
- **Bug 1 verification:** "Simulate unknown-location visit" inserts a `Visit` with `zone_name = 'Unknown'` so History rendering can be checked without walking outside
- **Bug 2 verification:** "Queue 5 offline points" seeds `offline_location_queue`; toggle airplane mode and watch the count drop after the 60s drain or on reconnect
- **Bug 3 verification:** "Seed test zone" + "Show zone diagnostics" lists every local geofence with its id so duplicates / id drift are obvious after a create / edit / delete cycle

### Zones Screen
**Status:** Implemented
**File:** `lib/features/tracker/screens/zones_screen.dart`
- Unlimited zones (removed 3-zone limit)
- Each zone shows name, radius, settings summary
- Tap to edit, X to delete
- Zones synced to Firebase for tracker to read

### Add/Edit Zone Screen
**Status:** Implemented
**File:** `lib/features/tracker/screens/add_zone_screen.dart`
- Map picker for zone center (tap or paste coordinates)
- Radius slider (50m–1000m)
- Per-zone alert settings: enter, exit, alert-only-on-exit, suppress-while-inside
- Custom update interval (any number + min/hr unit picker)
- Minimum stay alert (any number + min/hr unit picker)
- Saves to local SQLite + syncs to Firebase
- **Edit flow uses `update()` by id** (not delete-then-insert) so the row identity is stable, no race against the Firebase listener, and no transient duplicate

### Firebase Geofence Sync
**Status:** Implemented
**File:** `lib/features/tracker/core/services/background_service.dart`
- Background service subscribes to `geofences/{deviceId}/zones` and reconciles into local SQLite via diff-based upsert
- **Empty Firestore snapshots are ignored** (treated as transient cache/error) — never wipes the local table
- Local rows missing from the snapshot are pruned only when the snapshot is non-empty
- Combined with the `update()` edit flow, this prevents the duplicate / disappearing zone bug

### Live Mode
- Viewer sends live mode command via Firebase `commands/{deviceId}`
- Tracker reads command and overrides smart algorithm with fixed interval
- Viewer can choose 10s, 30s, or 60s intervals
- Stopping live mode returns tracker to smart detection

### Offline Location Queue
**Status:** Implemented
- When network is off but GPS is on, locations are queued to local SQLite (`offline_location_queue`)
- Both ForegroundTracker and BackgroundService use the same queue table
- **Drain triggers (independent of current write success):**
  - 60-second periodic timer
  - Connectivity listener fires an immediate drain when the device transitions back online
  - Background service tick also drains after queue maintenance
- Each drain pulls the oldest 20 queued items and deletes them only after a successful Firebase write; on first error the drain stops so the remaining points stay queued
- Drained points are written to `location_history/{deviceId}/points` (append-only timeline) with `syncedFromQueue: true` — never to `locations/{deviceId}`, which would overwrite the current-position doc with stale data
- Queue capped at 1000 rows — oldest entries removed when cap is reached
- Viewer sees pending queue count in the "Updated X ago" badge and location detail sheet

### Viewer Device Status
**Status:** Implemented
- Firebase `locations` document includes: `isNetworkAvailable`, `isLocationServiceEnabled`, `pendingQueueCount`
- Map screen "Updated X ago" badge shows:
  - Red dot when tracker's location service is off
  - Orange dot when tracker's network is off
  - "· N queued" suffix when locations are pending sync
- Location detail sheet shows "Network: Connected/Offline" and "Queued: N locations" rows

### Data Storage
- **Firebase Firestore:** Real-time location (with device status), visits, active visit, zone settings, commands
- **Local SQLite:** Visits, zone settings, offline queue, geofences, saved locations (DB version 14)
- **SharedPreferences:** Tracker settings, role, device ID, detector state
