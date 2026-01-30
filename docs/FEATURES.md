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
**Status:** Implemented (UI only, mock data)

Displays savings goals with progress tracking.

---

### Expenses Tab
**Status:** Implemented (UI only, mock data)

Shows monthly summary and recent transactions.

**Components:**
- Cycle indicator (tap to edit, long-press for cycle review)
- Remaining balance display
- Income/Spent summary cards
- Recent transactions list

---

### Cycle Complete Screen
**Status:** Implemented (UI only, mock data)

An elegant dark-themed screen that appears when a budget cycle ends, showing a comprehensive review of the completed cycle.

**File:** `lib/features/budget/screens/cycle_complete_screen.dart`

**Trigger:** Long-press on cycle indicator in Expenses tab (for demo)

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
  totalIncome: 50000,
  totalSpent: 35000,
  needsSpent: 20000,
  wantsSpent: 10000,
  savingsAdded: 5000,
  onStartNewCycle: () => Navigator.pop(context),
)
```

---

### Statistics Tab
**Status:** Implemented (UI only, mock data)

Displays spending trends and comparisons.
