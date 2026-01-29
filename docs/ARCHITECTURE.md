# Architecture Documentation

This document describes the overall architecture of FinanceSensei.

---

## Overview

FinanceSensei is an **offline-first Personal Financial Operating System (PF-OS)** built with Flutter.

**Core Philosophy:**
> "I don't track money. My system does."

---

## Architecture Principles

### 1. Offline-First
- ALL data stored in local SQLite database
- No network dependency for core functionality
- Instant performance - local queries only

### 2. UI-First Development
- Build UI components first
- Add data layer when UI is finalized
- Keep UI decoupled from data layer

### 3. Connected Data Flow
- All features are interconnected (see [DATA_FLOW.md](./DATA_FLOW.md))
- Changes in one area affect related areas
- Single source of truth for financial data

---

## Budget System Architecture

### The Money Flow

```
┌─────────────────────────────┐
│      MONTHLY INCOME         │  ← From Profile → Income
│        (Source)             │
└─────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│     FIXED EXPENSES          │  ← From Profile → Fixed Expenses
│   (Auto-deducted monthly)   │
│   Rent, Utilities, Bills    │
└─────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│     VARIABLE BUDGET         │  ← Shown in Today tab
│   (What you actively track) │
└─────────────────────────────┘
              │
     ┌────────┼────────┐
     ▼        ▼        ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ NEEDS   │ │ WANTS   │ │SAVINGS  │
│  50%    │ │  30%    │ │  20%    │
│         │ │         │ │         │
│Food,    │ │Shopping,│ │Emergency│
│Transport│ │Entertain│ │Fund +   │
│Health   │ │Lifestyle│ │Goals    │
└─────────┘ └─────────┘ └─────────┘
     │           │           │
     ▼           ▼           ▼
  Today       Today       Safety
  Screen      Screen      + Goals
```

### Component Connections

| Source (Profile) | Affects | Displayed In |
|------------------|---------|--------------|
| Income | Total available money | Profile |
| Fixed Expenses | Reduces variable budget | Profile |
| Variable Budget | Daily spending allowance | Today, Monthly Budget |
| Cycle Settings | Budget period boundaries | Home, All tabs |

| Expense Category | Budget Source | Destination |
|------------------|---------------|-------------|
| Needs | Variable Budget × 50% | Essentials tracking |
| Wants | Variable Budget × 30% | Lifestyle tracking |
| Savings | Variable Budget × 20% | Emergency Fund + Goals |

---

## Folder Structure

```
lib/
├── main.dart                          # App entry point
│
├── core/                              # Shared core functionality
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   ├── models/
│   │   ├── budget_cycle.dart          # Budget period logic
│   │   └── cycle_settings.dart        # User cycle preferences
│   ├── services/
│   │   └── budget_calculator.dart     # Budget calculations
│   └── theme/
│       └── app_theme.dart             # App theme
│
├── features/                          # Feature modules
│   ├── home/                          # Today tab
│   │   ├── models/
│   │   │   └── expense.dart           # Expense with category
│   │   └── screens/
│   │       ├── home_screen.dart       # Daily view
│   │       ├── add_expense_screen.dart
│   │       ├── monthly_budget_screen.dart
│   │       └── all_expenses_screen.dart
│   │
│   ├── emergency_fund/                # Safety tab
│   │   └── screens/
│   │       ├── emergency_fund_screen.dart
│   │       └── add_fund_screen.dart
│   │
│   ├── goals/                         # Goals tab
│   │   ├── models/
│   │   │   └── goal.dart              # Goal with timeline
│   │   └── screens/
│   │       ├── goals_screen.dart
│   │       ├── goal_detail_screen.dart
│   │       ├── add_goal_screen.dart
│   │       ├── edit_goal_screen.dart
│   │       └── add_to_goal_screen.dart
│   │
│   ├── profile/                       # You tab
│   │   └── screens/
│   │       ├── profile_screen.dart
│   │       ├── cycle_settings_screen.dart
│   │       └── knowledge_screen.dart
│   │
│   ├── plan/                          # Financial Plan feature
│   │   ├── models/
│   │   │   └── financial_plan.dart    # Debt, PlanStep, BudgetRule
│   │   └── screens/
│   │       ├── financial_plan_screen.dart  # 10-step overview
│   │       ├── debt_screen.dart       # Debt management
│   │       └── add_debt_screen.dart   # Add new debt
│   │
│   └── onboarding/                    # Initial setup
│       └── screens/
│           ├── welcome_screen.dart
│           ├── income_setup_screen.dart
│           ├── expenses_setup_screen.dart
│           ├── variable_budget_setup_screen.dart
│           └── savings_setup_screen.dart
│
└── shared/                            # Shared UI components
    ├── widgets/
    │   ├── app_card.dart
    │   ├── progress_bar.dart
    │   ├── minimal_calendar.dart
    │   └── ...
    └── utils/
        └── formatters.dart
```

---

## Navigation Structure

```
Bottom Navigation (4 tabs)
├── Today (index 0)
│   ├── Add Expense (modal)
│   ├── Monthly Budget (push)
│   └── All Expenses (push)
│
├── Safety (index 1)
│   └── Add Fund (modal)
│
├── Goals (index 2)
│   ├── Add Goal (modal)
│   └── Goal Detail (push)
│       ├── Add to Goal (modal)
│       └── Edit Goal (modal)
│
└── You (index 3)
    ├── Financial Plan (push)
    │   └── Debt (push)
    │       └── Add Debt (modal)
    ├── Income Setup (push)
    ├── Expenses Setup (push)
    ├── Variable Budget Setup (push)
    ├── Savings Setup (push)
    ├── Cycle Settings (push)
    └── Knowledge (push)
```

---

## Related Documentation

- **[APP_OVERVIEW.md](./APP_OVERVIEW.md)** - Master documentation (start here)
- **[DATA_FLOW.md](./DATA_FLOW.md)** - Detailed budget flow and connections
- **[FEATURES.md](./FEATURES.md)** - Feature specifications and status
- **[DATABASE.md](./DATABASE.md)** - Database schema (pending implementation)
- **[BUDGET_LOGIC.md](./BUDGET_LOGIC.md)** - Budget calculation algorithms

---

## Notes for Developers

1. Build UI first, then add data layer
2. Keep components small and focused
3. Follow the Steve Jobs Design Standard from CLAUDE.md
4. All features should show their data connections
5. Update DATA_FLOW.md when adding new connections
