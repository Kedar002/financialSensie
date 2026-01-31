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
