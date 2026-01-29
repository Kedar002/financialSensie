# Budget Calculation Logic

This document explains the "Planned Daily Budget + Rolling Allowance" model used in FinanceSensei.

---

## Overview

The system provides two key numbers:

| Value | Type | Description |
|-------|------|-------------|
| **Planned Daily Budget** | Fixed | Your target daily spending (constant for entire cycle) |
| **Rolling Daily Allowance** | Dynamic | What you can actually spend today (adjusts based on spending) |

---

## Core Formulas

### 1. Planned Daily Budget (Fixed)

```
plannedDailyBudget = monthlyVariableBudget / totalDaysInCycle
```

This value is calculated ONCE at cycle start and remains constant.

### 2. Rolling Daily Allowance (Dynamic)

```
totalSpentInCycle = SUM(all expenses from cycleStart to today)
remainingBudget = monthlyVariableBudget - totalSpentInCycle
remainingDays = cycleEndDate - today + 1

rollingDailyAllowance = remainingBudget / remainingDays
```

This value is recalculated every time the user views the app.

---

## Example Walkthrough

### Setup

- **Monthly Variable Budget:** ₹30,000
- **Cycle:** January 1-31 (31 days)
- **Planned Daily Budget:** ₹30,000 ÷ 31 = **₹968/day**

### Day-by-Day Scenario

| Day | Spent Today | Total Spent | Remaining Budget | Days Left | Rolling Allowance | Status |
|-----|-------------|-------------|------------------|-----------|-------------------|--------|
| 1   | ₹500        | ₹500        | ₹29,500          | 31        | ₹952              | Under budget |
| 2   | ₹1,500      | ₹2,000      | ₹28,000          | 30        | ₹933              | Slightly over daily |
| 3   | ₹0          | ₹2,000      | ₹28,000          | 29        | ₹966              | Recovery day |
| 4   | ₹2,000      | ₹4,000      | ₹26,000          | 28        | ₹929              | Over again |
| 5   | ₹800        | ₹4,800      | ₹25,200          | 27        | ₹933              | Under daily |

### Analysis

- **Day 1:** Spent ₹500 vs planned ₹968 → Saved ₹468
- **Day 2:** Spent ₹1,500 vs planned ₹968 → Overspent ₹532
- **Day 3:** Spent ₹0 → Full recovery, allowance back near planned
- **Day 4:** Big expense drops allowance
- **Day 5:** Spending under allowance helps recovery

---

## Edge Cases

### 1. No Expenses Today

```
totalSpent = same as yesterday
remainingBudget = same as yesterday
remainingDays = yesterday - 1
rollingDailyAllowance = remainingBudget / remainingDays
```

**Result:** Allowance increases slightly (fewer days to spread same budget).

### 2. Over Budget (remainingBudget < 0)

```
if (remainingBudget < 0) {
    rollingDailyAllowance = 0
    isOverBudget = true
    overBudgetAmount = |remainingBudget|
}
```

**Display:** "You can spend ₹0 today" + "Over budget by ₹X"

### 3. Cycle Complete (remainingDays <= 0)

```
if (remainingDays <= 0) {
    rollingDailyAllowance = remainingBudget  // What's left (or owed)
    timeProgress = 1.0
}
```

**Display:** Shows final remaining balance (positive = saved, negative = overspent).

### 4. User Joins Mid-Cycle

Two options (configurable):

| Option | Behavior |
|--------|----------|
| **Full Budget** | User gets entire monthly budget for remaining days |
| **Prorated** | `budget = monthlyBudget × (remainingDays / totalDays)` |

**Current implementation:** Full budget (user can configure cycle start day).

---

## Budget Cycle Configuration

### Default: Calendar Month

```dart
BudgetCycle.currentMonth(budget: 25000)
// Start: 1st of current month
// End: Last day of current month
```

### Custom: Salary Day Cycle

```dart
BudgetCycle.fromCycleDay(cycleDay: 25, budget: 25000)
// If today is Jan 28:
//   Start: Dec 25
//   End: Jan 24
// If today is Jan 20:
//   Start: Dec 25
//   End: Jan 24
```

---

## Data Flow

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   BudgetCycle   │────▶│ BudgetCalculator │────▶│ BudgetSnapshot  │
│                 │     │                  │     │                 │
│ • startDate     │     │   calculate()    │     │ • plannedDaily  │
│ • endDate       │     │                  │     │ • rollingDaily  │
│ • budget        │     │                  │     │ • totalSpent    │
└─────────────────┘     └──────────────────┘     │ • remaining     │
                               ▲                 │ • isOverBudget  │
                               │                 └─────────────────┘
                        ┌──────┴───────┐
                        │   Expenses   │
                        │   (List)     │
                        └──────────────┘
```

---

## Code Structure

### Files

| File | Purpose |
|------|---------|
| `lib/core/models/budget_cycle.dart` | Cycle configuration |
| `lib/core/services/budget_calculator.dart` | Calculation logic |
| `lib/features/home/screens/home_screen.dart` | UI integration |

### Key Classes

```dart
// Cycle configuration
class BudgetCycle {
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyVariableBudget;
  int get totalDays;
  bool containsDate(DateTime date);
}

// Calculation result
class BudgetSnapshot {
  final double plannedDailyBudget;    // Fixed
  final double rollingDailyAllowance; // Dynamic
  final double totalBudget;
  final double totalSpent;
  final double remainingBudget;
  final int remainingDays;
  final bool isOverBudget;
  final double overBudgetAmount;
}

// Calculator (stateless)
class BudgetCalculator {
  static BudgetSnapshot calculate({
    required BudgetCycle cycle,
    required List<Expense> expenses,
    DateTime? asOfDate,
  });
}
```

---

## UI Display

### Hero Section (Today)

```
You can spend
₹933                    ← rollingDailyAllowance (HERO)
today

Planned: ₹968/day · 27 days left
```

### Over Budget State

```
You can spend
₹0                      ← Gray, muted
today

Planned: ₹968/day · 27 days left

┌─────────────────────────────┐
│ Over budget by ₹2,500       │
└─────────────────────────────┘
```

### Cycle Progress Section

```
This month                    34%
━━━━━━━━━━░░░░░░░░░░░░░░░░░░░

Budget          Spent          Left
₹30,000        ₹10,200        ₹19,800
```

---

## Why Two Numbers?

| Number | Purpose |
|--------|---------|
| **Planned Daily** | Psychological anchor - "this is what I should spend" |
| **Rolling Allowance** | Reality check - "this is what I can actually spend" |

The planned daily budget provides consistency and goal-setting.
The rolling allowance provides honest, actionable guidance.

**Example:**
- Planned: ₹1,000/day
- Rolling: ₹800/day

User sees: "I planned for ₹1,000 but I've been overspending, so I can only spend ₹800 today to stay on track."

---

## Future Enhancements

1. **Carry-over:** Allow unused budget to roll to next cycle
2. **Category budgets:** Separate limits for Needs/Wants/Savings
3. **Forecasting:** "At this rate, you'll be ₹X over/under by month end"
4. **Alerts:** Notify when rolling allowance drops below planned
