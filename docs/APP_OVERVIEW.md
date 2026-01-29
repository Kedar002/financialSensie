# FinanceSensei - Application Overview

> **Last Updated**: January 2026
> **Version**: 1.0.0
> **Status**: UI Complete, Database Pending

---

## Quick Summary

FinanceSensei is an **offline-first Personal Financial Operating System** built with Flutter. It helps salaried individuals automatically build wealth without daily money tracking.

**Core Philosophy**: *"I don't track money. My system does."*

---

## Table of Contents

1. [Application Structure](#1-application-structure)
2. [Features Overview](#2-features-overview)
3. [Data Models](#3-data-models)
4. [Navigation Map](#4-navigation-map)
5. [Core Services](#5-core-services)
6. [Shared Components](#6-shared-components)
7. [Design System](#7-design-system)
8. [Budget Logic](#8-budget-logic)
9. [File Structure](#9-file-structure)
10. [Update Log](#10-update-log)
11. [Adding New Features](#11-adding-new-features)

---

## 1. Application Structure

### Architecture Type
- **Pattern**: Four-tab bottom navigation (IndexedStack)
- **State Management**: StatefulWidget-based with state lifting
- **Data Layer**: In-memory (database layer planned)
- **Design Philosophy**: Steve Jobs minimalism (black/white/gray only)

### Entry Point
```
main.dart → WelcomeScreen (onboarding) → HomeScreen (main app)
```

### Four Main Tabs
| Tab | Name | Purpose | Icon |
|-----|------|---------|------|
| 0 | Today | Daily spending tracker | `circle` |
| 1 | Safety | Emergency fund tracking | `lock` |
| 2 | Goals | Savings goals management | `adjust` |
| 3 | You | Profile & settings | `person` |

---

## 2. Features Overview

### Status Legend
- Completed = UI and logic complete
- Pending = Planned but not implemented
- Partial = Some functionality missing

### Feature Matrix

| Feature | Tab | Status | Description |
|---------|-----|--------|-------------|
| **Daily Budget Display** | Today | Completed | Shows how much user can spend today |
| **Expense Logging** | Today | Completed | Log expenses with category/subcategory |
| **Monthly Budget View** | Today | Completed | 50-30-20 breakdown visualization |
| **Expense History** | Today | Completed | Full history with filters |
| **Emergency Fund Tracker** | Safety | Completed | Runway months, progress, contributions |
| **Goals Management** | Goals | Completed | Create/track goals by timeline |
| **Goal Contributions** | Goals | Completed | Add money to specific goals |
| **Financial Plan** | You | Completed | 10-step roadmap to financial freedom |
| **Debt Management** | You | Completed | Track debts with priority system |
| **Budget Cycle Settings** | You | Completed | Calendar month or custom start day |
| **Onboarding Flow** | - | Completed | 5-step initial setup |
| **Database Persistence** | - | Pending | SQLite storage for all data |
| **Settings Persistence** | - | Pending | Save user preferences |

### Key Connections

```
SAVINGS CATEGORY (Add Expense)
        │
        ├──→ Emergency Fund (Safety Tab)
        │
        └──→ User Goals (Goals Tab)
             └── Goal progress auto-updates when expense logged
```

---

## 3. Data Models

### Core Models

#### Expense (`lib/features/home/models/expense.dart`)
```dart
class Expense {
  String id;
  double amount;
  ExpenseCategory category;        // needs, wants, savings
  ExpenseSubcategory? subcategory; // For needs/wants
  SavingsDestination? savingsDestination; // For savings
  String? note;
  DateTime date;
  DateTime createdAt;
}
```

#### Goal (`lib/features/goals/models/goal.dart`)
```dart
class Goal {
  String id;
  String name;
  double targetAmount;
  double currentAmount;
  DateTime targetDate;
  SavingsInstrument instrument;
  DateTime createdAt;

  // Computed
  GoalTimeline timeline;  // short/mid/long based on targetDate
  double progress;
  double monthlySavingsNeeded;
}
```

#### Debt (`lib/features/plan/models/financial_plan.dart`)
```dart
class Debt {
  String id;
  String name;
  double totalAmount;
  double remainingAmount;
  double interestRate;
  double minimumPayment;
  DebtPriority priority;  // Auto-calculated from interest rate
  DateTime createdAt;
}
```

#### BudgetCycle (`lib/core/models/budget_cycle.dart`)
```dart
class BudgetCycle {
  DateTime startDate;
  DateTime endDate;
  double monthlyVariableBudget;
}
```

### Enums

| Enum | Values | Location |
|------|--------|----------|
| `ExpenseCategory` | needs, wants, savings | expense.dart |
| `ExpenseSubcategory` | rentEmi, utilitiesBills, otherFixed, foodDining, transport, healthWellness, shopping, entertainment, otherVariable | expense.dart |
| `SavingsDestinationType` | emergencyFund, goal | expense.dart |
| `GoalTimeline` | shortTerm, midTerm, longTerm | goal.dart |
| `SavingsInstrument` | savingsAccount, piggyBank, fixedDeposit, mutualFunds, stocks, bonds, etc. | goal.dart |
| `DebtPriority` | high (>15%), medium (8-15%), low (<8%) | financial_plan.dart |
| `PlanStep` | income, budgetRule, needs, wants, goals, emergencyFund, debt, savings, automate, review | financial_plan.dart |
| `CycleType` | calendarMonth, customDay | cycle_settings.dart |

---

## 4. Navigation Map

```
FinanceSenseiApp
│
├── [Tab 0] TODAY ─────────────────────────────────────────────
│   └── HomeScreen
│       ├── MinimalCalendar (date selection)
│       ├── Budget hero display (rolling daily allowance)
│       ├── Cycle progress bar
│       ├── Recent expenses list
│       ├── FAB (+) → AddExpenseScreen (modal)
│       │   └── Category → Subcategory/Destination selection
│       ├── "This month" → MonthlyBudgetScreen (push)
│       │   └── 50-30-20 breakdown with progress bars
│       └── "View all" → AllExpensesScreen (push)
│           └── Filters, date picker, grouped history
│
├── [Tab 1] SAFETY ────────────────────────────────────────────
│   └── EmergencyFundScreen
│       ├── Runway display (X.X months)
│       ├── Progress card (current vs target)
│       ├── Details card (metrics)
│       └── "Add Fund" button → AddFundScreen (modal)
│
├── [Tab 2] GOALS ─────────────────────────────────────────────
│   └── GoalsScreen
│       ├── Empty state (no goals)
│       ├── Overview card (total saved)
│       ├── Sections by timeline
│       │   ├── Short-term (<1 year)
│       │   ├── Mid-term (1-5 years)
│       │   └── Long-term (>5 years)
│       ├── Goal cards → GoalDetailScreen (push)
│       │   ├── Hero card (saved amount)
│       │   ├── Progress card
│       │   ├── Details card
│       │   ├── "Edit" → EditGoalScreen (modal)
│       │   ├── "Add to Goal" → AddToGoalScreen (modal)
│       │   └── "Delete goal" (confirmation sheet)
│       └── "Add Goal" → AddGoalScreen (modal)
│
└── [Tab 3] YOU ───────────────────────────────────────────────
    └── ProfileScreen
        ├── Financial Plan card → FinancialPlanScreen (push)
        │   ├── 10-step progress grid
        │   ├── Step details (bottom sheet)
        │   └── Debt Management → DebtScreen (push)
        │       ├── Priority sections (High/Medium/Low)
        │       └── "Add Debt" → AddDebtScreen (modal)
        ├── Setup section
        │   ├── Income → IncomeSetupScreen
        │   ├── Expenses → ExpensesSetupScreen
        │   ├── Variable Budget → VariableBudgetSetupScreen
        │   ├── Savings → SavingsSetupScreen
        │   └── Budget Cycle → CycleSettingsScreen
        └── Learn section
            └── Knowledge → KnowledgeScreen
```

---

## 5. Core Services

### BudgetCalculator (`lib/core/services/budget_calculator.dart`)

Main service for all budget calculations.

```dart
class BudgetCalculator {
  // Calculate complete budget snapshot
  static BudgetSnapshot calculate({
    required BudgetCycle cycle,
    required List<Expense> expenses,
    DateTime? asOfDate,
  });

  // Get expenses for specific date
  static List<Expense> getExpensesForDate(List<Expense> expenses, DateTime date);

  // Get total spent on date
  static double getTotalForDate(List<Expense> expenses, DateTime date);

  // Get 50-30-20 breakdown
  static Map<ExpenseCategory, double> getCategoryBreakdown(
    List<Expense> expenses,
    BudgetCycle cycle,
  );
}
```

### Formatters (`lib/shared/utils/formatters.dart`)

Formatting utilities for display.

```dart
class Formatters {
  static String currency(double amount);        // ₹1,234.56
  static String currencyCompact(double amount); // ₹1.2K
  static String percentage(double value);       // 45%
  static String months(double value);           // 2.3 months
  static String date(DateTime date);            // 15 Jan 2026
  static String dateShort(DateTime date);       // 15/1
  static String daysRemaining(int days);        // 15 days left
}
```

---

## 6. Shared Components

All reusable widgets in `lib/shared/widgets/`:

| Widget | Purpose | Props |
|--------|---------|-------|
| `AppCard` | Minimal card container | `child`, `padding`, `onTap` |
| `ProgressBar` | Fill-style progress indicator | `progress` (0-100) |
| `MinimalCalendar` | Week/month calendar toggle | `selectedDate`, `onDateSelected` |
| `AdvancedDatePicker` | Multi-mode date picker | `mode`, `onDateSelected` |
| `AmountDisplay` | Large currency display | `amount`, `label` |
| `SectionHeader` | Section title with optional action | `title`, `action` |
| `MetricRow` | Label-value horizontal row | `label`, `value` |

---

## 7. Design System

### Colors (Steve Jobs Palette)
```dart
black     = #000000  // Primary, text, buttons
white     = #FFFFFF  // Background
gray100   = #F5F5F5  // Light backgrounds
gray200   = #E5E5E5  // Borders, dividers
gray300   = #D4D4D4  // Disabled states
gray400   = #9E9E9E  // Placeholder text
gray500   = #757575  // Secondary text
gray600   = #616161  // Labels
```

### Spacing (8px base unit)
```dart
spacing4  = 4    spacing24 = 24
spacing6  = 6    spacing32 = 32
spacing8  = 8    spacing48 = 48
spacing12 = 12   spacing64 = 64
spacing16 = 16   spacing20 = 20
```

### Typography
| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| displayLarge | 48 | 600 | Main amounts |
| displayMedium | 32 | 600 | Large headers |
| headlineMedium | 20 | 600 | Screen titles |
| titleLarge | 16 | 600 | Card titles |
| titleMedium | 14 | 600 | Small titles |
| bodyLarge | 16 | 400 | Body text |
| bodyMedium | 14 | 400 | Secondary text |
| bodySmall | 12 | 400 | Captions |
| labelMedium | 12 | 500 | Labels |

### Design Rules
1. **No gradients** - Solid colors only
2. **No heavy shadows** - Max 0.1 opacity
3. **No bright colors** - Black/white/gray only
4. **Generous whitespace** - Min 16px from edges
5. **One primary action** - Per screen
6. **Consistent radius** - 8px (small), 12px (medium)

---

## 8. Budget Logic

### The Money Flow
```
MONTHLY INCOME
      │
      ▼
FIXED EXPENSES (auto-deducted)
├── Rent/EMI
├── Utilities
└── Other Fixed
      │
      ▼
VARIABLE BUDGET (what you track)
├── Needs (50%)     → Food, Transport, Health
├── Wants (30%)     → Shopping, Entertainment
└── Savings (20%)   → Emergency Fund + Goals
```

### Daily Budget Calculation
```
Planned Daily = Variable Budget / Days in Cycle

Rolling Daily = Remaining Budget / Days Left
```

### Example
```
Budget: ₹25,000 for 30 days
Day 5: Spent ₹3,000

Planned Daily = ₹25,000 / 30 = ₹833/day (constant)
Rolling Daily = (₹25,000 - ₹3,000) / 25 = ₹880/day (dynamic)
```

### Goal Timeline Classification
| Timeline | Duration | Suggested Instruments |
|----------|----------|----------------------|
| Short-term | < 1 year | Savings Account, FD, Piggy Bank |
| Mid-term | 1-5 years | Mutual Funds, RD, CD |
| Long-term | > 5 years | Stocks, Index Funds, Bonds |

### Debt Priority
| Priority | Interest Rate | Action |
|----------|---------------|--------|
| High | > 15% | Pay first (credit cards) |
| Medium | 8-15% | Pay after high priority |
| Low | < 8% | Maintain minimum (home loan) |

---

## 9. File Structure

```
lib/
├── main.dart
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── models/
│   │   ├── budget_cycle.dart
│   │   └── cycle_settings.dart
│   ├── services/
│   │   └── budget_calculator.dart
│   └── theme/
│       └── app_theme.dart
│
├── features/
│   ├── home/
│   │   ├── models/
│   │   │   └── expense.dart
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       ├── add_expense_screen.dart
│   │       ├── monthly_budget_screen.dart
│   │       └── all_expenses_screen.dart
│   │
│   ├── emergency_fund/
│   │   └── screens/
│   │       ├── emergency_fund_screen.dart
│   │       └── add_fund_screen.dart
│   │
│   ├── goals/
│   │   ├── models/
│   │   │   └── goal.dart
│   │   └── screens/
│   │       ├── goals_screen.dart
│   │       ├── add_goal_screen.dart
│   │       ├── goal_detail_screen.dart
│   │       ├── add_to_goal_screen.dart
│   │       └── edit_goal_screen.dart
│   │
│   ├── profile/
│   │   └── screens/
│   │       ├── profile_screen.dart
│   │       ├── cycle_settings_screen.dart
│   │       └── knowledge_screen.dart
│   │
│   ├── plan/
│   │   ├── models/
│   │   │   └── financial_plan.dart
│   │   └── screens/
│   │       ├── financial_plan_screen.dart
│   │       ├── debt_screen.dart
│   │       └── add_debt_screen.dart
│   │
│   └── onboarding/
│       └── screens/
│           ├── welcome_screen.dart
│           ├── income_setup_screen.dart
│           ├── expenses_setup_screen.dart
│           ├── variable_budget_setup_screen.dart
│           └── savings_setup_screen.dart
│
└── shared/
    ├── widgets/
    │   ├── app_card.dart
    │   ├── progress_bar.dart
    │   ├── minimal_calendar.dart
    │   ├── advanced_date_picker.dart
    │   ├── amount_display.dart
    │   ├── section_header.dart
    │   └── metric_row.dart
    └── utils/
        └── formatters.dart
```

---

## 10. Update Log

Track all major feature additions here.

### Version 1.0.0 (January 2026)

| Date | Feature | Description | Files Changed |
|------|---------|-------------|---------------|
| Jan 2026 | Initial Release | Complete UI implementation | All files |
| Jan 2026 | Goals = Savings | Connected Goals tab as savings destination | expense.dart, add_expense_screen.dart, home_screen.dart, goals_screen.dart |
| Jan 2026 | Financial Plan | Added 10-step financial roadmap | plan/* |
| Jan 2026 | Debt Management | Added debt tracking with priority | debt_screen.dart, add_debt_screen.dart |

### Version 1.1.0 (Planned)

| Date | Feature | Description | Files to Change |
|------|---------|-------------|-----------------|
| TBD | Database Layer | SQLite persistence | Add database/, repositories/ |
| TBD | Settings Persistence | Save user preferences | cycle_settings.dart |

---

## 11. Adding New Features

### Pre-Implementation Checklist

Before adding any new feature:

- [ ] **Does it pass the Steve Jobs test?** (Simple, focused, elegant)
- [ ] **Is it truly necessary?** (Remove features, don't add)
- [ ] **Does it fit the offline-first model?** (No network dependency)
- [ ] **Have you checked existing patterns?** (Follow established conventions)

### Implementation Steps

1. **Plan the Feature**
   - Define the purpose (one sentence)
   - List affected screens
   - Identify new models needed
   - Check connections to existing features

2. **Create/Update Models** (if needed)
   ```
   lib/features/[feature]/models/[model].dart
   ```
   - Include `toMap()` and `fromMap()` for future database

3. **Create Screens**
   ```
   lib/features/[feature]/screens/[screen].dart
   ```
   - Follow existing screen patterns
   - Use shared widgets (AppCard, ProgressBar, etc.)
   - Apply AppTheme consistently

4. **Update Navigation**
   - Add to appropriate tab or navigation flow
   - Update home_screen.dart if state needs lifting

5. **Update Documentation**
   - [ ] Update this file (APP_OVERVIEW.md)
   - [ ] Update docs/FEATURES.md
   - [ ] Update docs/ARCHITECTURE.md if navigation changes
   - [ ] Update docs/DATABASE.md if new models added
   - [ ] Add entry to Update Log above

### Documentation Template for New Features

When adding a feature, add this entry to the Update Log:

```markdown
| Date | Feature Name | Brief description | list, of, files, changed |
```

And update the Feature Matrix in Section 2:

```markdown
| **Feature Name** | Tab | Status | One-line description |
```

### Example: Adding Recurring Transactions

```markdown
## Update Log Entry
| Feb 2026 | Recurring Transactions | Auto-log monthly bills | recurring.dart, add_recurring_screen.dart, home_screen.dart |

## Feature Matrix Entry
| **Recurring Transactions** | Today | Completed | Auto-log fixed monthly expenses |

## Files Created
- lib/features/home/models/recurring.dart
- lib/features/home/screens/add_recurring_screen.dart
- lib/features/home/screens/recurring_list_screen.dart

## Files Modified
- lib/features/home/screens/home_screen.dart (add navigation)
- lib/features/profile/screens/profile_screen.dart (add settings link)
```

---

## Quick Reference

### Key Files to Know
- **Main navigation**: `lib/features/home/screens/home_screen.dart`
- **Theme**: `lib/core/theme/app_theme.dart`
- **Budget logic**: `lib/core/services/budget_calculator.dart`
- **Expense model**: `lib/features/home/models/expense.dart`
- **Goal model**: `lib/features/goals/models/goal.dart`

### Common Patterns
- State is held in `HomeScreen` and passed via callbacks
- All cards use `AppCard` widget
- All progress bars use `ProgressBar` widget
- All currency displays use `Formatters.currency()`
- All modal screens use `fullscreenDialog: true`

### Design Tokens
- Spacing: multiples of 4 (4, 8, 12, 16, 24, 32, 48, 64)
- Radius: 8 (small), 12 (medium)
- Colors: black, white, gray100-600 only
- Font weights: 400 (body), 500 (label), 600 (title)

---

*This document should be updated whenever a major feature is added to the application.*
