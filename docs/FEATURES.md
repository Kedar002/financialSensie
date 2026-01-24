# Features & Functionality Documentation

This document tracks all features, their status, and implementation details. **This file MUST be updated whenever a new feature is added or modified.**

---

## Product Vision

> **"A decision-making system for salaried people to automatically build wealth without thinking daily"**

Core Promise: *"I don't track money. My system does."*

---

## Feature Status Legend

- **Planned** - Feature is defined but not started
- **In Progress** - Currently being implemented
- **Completed** - Feature is fully implemented and tested
- **Deprecated** - Feature is no longer supported

---

## V1 Features (MVP)

---

### 1. Financial Profile Engine
**Status:** Planned
**Priority:** P0 (Foundation)
**Added:** 2026-01-24

**Description:**
The brain of the app. Collects and processes all financial inputs to calculate safe-to-spend, emergency fund targets, and allocation recommendations.

**User Story:**
As a user, I want to input my financial details once so that the app can automatically manage my money decisions.

**Inputs:**
- Monthly income(s) with pay dates
- Fixed expenses (rent, EMIs, subscriptions)
- Variable expense estimates
- Risk tolerance level
- Number of dependents
- Current savings/investments

**Outputs:**
- Monthly safe-to-spend amount
- Emergency fund target
- Mandatory savings amount
- Investment capacity

**Screens:**
| Screen | Purpose | Status |
|--------|---------|--------|
| Onboarding - Income | Add income sources | Planned |
| Onboarding - Fixed Expenses | Add recurring expenses | Planned |
| Onboarding - Variable Expenses | Estimate variable spending | Planned |
| Onboarding - Profile | Risk level, dependents | Planned |
| Profile Summary | View/edit all profile data | Planned |

**Database Tables Used:**
- `user_profile` - Core user settings
- `income_sources` - All income streams
- `fixed_expenses` - Recurring fixed costs
- `variable_expenses` - Estimated variable costs

**Key Files:**
- `lib/features/profile/` - Feature folder
- `lib/core/services/profile_calculation_service.dart`

---

### 2. Emergency Fund Engine
**Status:** Planned
**Priority:** P0 (Critical)
**Added:** 2026-01-24

**Description:**
Tracks emergency fund status with dynamic target calculation based on essential expenses. Shows runway months and progress.

**User Story:**
As a user, I want to see how many months of expenses I can survive without income so that I feel financially secure.

**Core Logic:**
```
Emergency Fund Target = Monthly Essential Expenses × 6 months

Monthly Essential = Fixed Essential Expenses + Variable Essential Expenses

Runway Months = Current Amount / Monthly Essential
Progress % = (Current Amount / Target Amount) × 100
```

**Smart Behaviors:**
- Auto-recalculate if expenses change
- Adjust target based on risk level (low=8mo, moderate=6mo, high=4mo)
- Alert if runway drops below 3 months

**Screens:**
| Screen | Purpose | Status |
|--------|---------|--------|
| Emergency Fund Dashboard | Show status, progress, runway | Planned |
| Add to Emergency Fund | Log deposits | Planned |

**Database Tables Used:**
- `emergency_fund` - Fund status
- `fixed_expenses` - Essential fixed costs
- `variable_expenses` - Essential variable costs

**Key Files:**
- `lib/features/emergency_fund/`
- `lib/core/services/emergency_fund_service.dart`

---

### 3. Pay-Yourself-First Allocation System
**Status:** Planned
**Priority:** P0 (Core)
**Added:** 2026-01-24

**Description:**
On salary day, automatically calculates how much to allocate to emergency fund, investments, and goals. Remaining becomes the spending pool.

**User Story:**
As a user, I want my savings to be automatically "hidden" on payday so that I only see what I can actually spend.

**Allocation Order (by priority):**
1. Emergency Fund (until target reached)
2. Fixed Expenses (auto-reserved)
3. Investments (% or fixed amount)
4. Planned Expense Goals
5. **Remaining = Safe-to-Spend Pool**

**Screens:**
| Screen | Purpose | Status |
|--------|---------|--------|
| Allocation Setup | Configure allocation rules | Planned |
| Payday Summary | Show where money went | Planned |

**Database Tables Used:**
- `allocations` - Allocation rules
- `income_sources` - Salary amounts and pay dates

**Key Files:**
- `lib/features/allocations/`
- `lib/core/services/allocation_service.dart`

---

### 4. Planned Expense System (KEY DIFFERENTIATOR)
**Status:** Planned
**Priority:** P0 (Differentiator)
**Added:** 2026-01-24

**Description:**
Users pre-declare future expenses (trips, gadgets, courses). The app calculates monthly savings required and adjusts safe-to-spend accordingly.

**User Story:**
As a user, I want to plan for a future expense so that I save for it automatically without affecting my daily spending decisions.

**Example:**
```
Goal: Goa Trip
Amount: ₹60,000
Target Date: 6 months from now
Monthly Required: ₹10,000

→ Safe-to-spend reduces by ₹10,000/month automatically
```

**Smart Behaviors:**
- Warn if goal is unrealistic (requires >50% of disposable income)
- Suggest timeline adjustments
- Track progress toward each goal
- Mark as completed when funded

**Screens:**
| Screen | Purpose | Status |
|--------|---------|--------|
| Goals List | View all planned expenses | Planned |
| Add Goal | Create new planned expense | Planned |
| Goal Detail | Progress, edit, contribute | Planned |

**Database Tables Used:**
- `planned_expenses` - All goals/planned expenses
- `transactions` - Contributions to goals

**Key Files:**
- `lib/features/goals/`
- `lib/core/services/goal_service.dart`

---

### 5. Safe-to-Spend Tracker (CORE UX)
**Status:** Planned
**Priority:** P0 (Core UX)
**Added:** 2026-01-24

**Description:**
The main screen users see. Shows exactly how much they can safely spend TODAY without affecting savings goals.

**User Story:**
As a user, I want to know "Can I spend ₹2,000 today safely?" without mental math so that I never accidentally overspend.

**Core Calculation:**
```
Monthly Safe-to-Spend = Income - Fixed Expenses - All Allocations
Spent This Month = Sum of transactions
Remaining = Monthly Safe-to-Spend - Spent This Month
Days Left = Days remaining in month

Today's Safe Spend = Remaining / Days Left
Weekly Buffer = Today's Safe Spend × 7
```

**Display:**
- **Primary:** Today's safe-to-spend (BIG number)
- **Secondary:** Weekly buffer
- **Tertiary:** Overspend impact preview

**Screens:**
| Screen | Purpose | Status |
|--------|---------|--------|
| Home (Safe-to-Spend) | Main dashboard | Planned |
| Log Spending | Quick transaction entry | Planned |
| Spending History | View recent transactions | Planned |

**Database Tables Used:**
- `transactions` - Spending records
- `allocations` - To calculate budget
- `income_sources` - Total income

**Key Files:**
- `lib/features/home/`
- `lib/core/services/safe_to_spend_service.dart`

---

### 6. Monthly Overview Dashboard
**Status:** Planned
**Priority:** P1
**Added:** 2026-01-24

**Description:**
End-of-month summary showing income vs expenses, savings rate, and month-over-month trends.

**User Story:**
As a user, I want to see a monthly summary so that I understand my financial health at a glance.

**Displays:**
- Total income
- Total expenses (fixed + variable)
- Savings rate %
- Emergency fund progress
- Goal progress
- Month-over-month comparison

**Screens:**
| Screen | Purpose | Status |
|--------|---------|--------|
| Monthly Overview | Summary dashboard | Planned |

**Database Tables Used:**
- `financial_snapshot` - Historical data
- All other tables for calculations

**Key Files:**
- `lib/features/overview/`

---

## Screen Inventory

| Screen Name | Feature | File Path | Status | Steve Jobs Approved |
|-------------|---------|-----------|--------|---------------------|
| Home (Safe-to-Spend) | Safe-to-Spend | `lib/features/home/screens/home_screen.dart` | Planned | Pending |
| Log Spending | Safe-to-Spend | `lib/features/home/screens/log_spending_screen.dart` | Planned | Pending |
| Emergency Fund | Emergency Fund | `lib/features/emergency_fund/screens/ef_screen.dart` | Planned | Pending |
| Goals List | Planned Expenses | `lib/features/goals/screens/goals_screen.dart` | Planned | Pending |
| Add Goal | Planned Expenses | `lib/features/goals/screens/add_goal_screen.dart` | Planned | Pending |
| Onboarding - Income | Profile | `lib/features/onboarding/screens/income_screen.dart` | Planned | Pending |
| Onboarding - Expenses | Profile | `lib/features/onboarding/screens/expenses_screen.dart` | Planned | Pending |
| Profile | Profile | `lib/features/profile/screens/profile_screen.dart` | Planned | Pending |
| Monthly Overview | Overview | `lib/features/overview/screens/overview_screen.dart` | Planned | Pending |

---

## User Flow

```
┌─────────────────┐
│   First Launch  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Onboarding    │
│  (Profile Setup)│
│                 │
│ 1. Add Income   │
│ 2. Add Fixed    │
│ 3. Add Variable │
│ 4. Set Profile  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│      HOME       │◄──────────────────────┐
│  Safe-to-Spend  │                       │
│                 │                       │
│  "₹847 today"   │                       │
└────────┬────────┘                       │
         │                                │
    ┌────┴────┬──────────┐               │
    ▼         ▼          ▼               │
┌───────┐ ┌───────┐ ┌─────────┐          │
│ Log   │ │ Goals │ │Emergency│          │
│Spend  │ │       │ │  Fund   │          │
└───┬───┘ └───────┘ └─────────┘          │
    │                                     │
    └─────────────────────────────────────┘
```

---

## Feature Roadmap

| Priority | Feature | Status | Notes |
|----------|---------|--------|-------|
| P0 | Financial Profile Engine | Planned | Foundation - build first |
| P0 | Emergency Fund Engine | Planned | Critical for value prop |
| P0 | Pay-Yourself-First System | Planned | Core automation |
| P0 | Planned Expense System | Planned | Key differentiator |
| P0 | Safe-to-Spend Tracker | Planned | Main UX - build early |
| P1 | Monthly Overview | Planned | Nice to have for V1 |

---

## V2+ Features (Future)

These are NOT in MVP scope but designed for:

| Feature | Description | Complexity |
|---------|-------------|------------|
| Financial Copilot | Rule-based Q&A → LLM later | Medium |
| Expense Forecasting | ML-based predictions | High |
| Bank Sync | UPI/Bank API integration | High |
| Net Worth Tracking | Assets + Liabilities | Medium |
| Investment Tracking | Link to investment accounts | High |
| Autonomous Agent | Auto-adjust allocations | Very High |

---

## Notes for Developers

1. **Always update this file** when adding or modifying features
2. Each feature should have its own folder under `lib/features/`
3. All screens must pass the Steve Jobs Design Checklist before implementation
4. Update "Steve Jobs Approved" column after UI review
5. Follow the user flow - don't create orphan screens
