# Database Schema Documentation

This document tracks all database tables, their schemas, and relationships. **This file MUST be updated whenever a table is created, modified, or deleted.**

---

## Database Overview

- **Database Type:** SQLite (via sqflite)
- **Database Name:** `financesensei.db`
- **Version:** 1
- **Design Philosophy:** Event-based with snapshots for scalability

---

## Entity Relationship Diagram

```
┌─────────────────┐       ┌──────────────────┐
│  user_profile   │       │  income_sources  │
│─────────────────│       │──────────────────│
│ id (PK)         │───┐   │ id (PK)          │
│ name            │   │   │ user_id (FK)     │──┐
│ currency        │   │   │ name             │  │
│ risk_level      │   │   │ amount           │  │
│ dependents      │   │   │ frequency        │  │
│ created_at      │   │   │ pay_day          │  │
│ updated_at      │   │   │ is_active        │  │
└─────────────────┘   │   └──────────────────┘  │
                      │                          │
┌─────────────────┐   │   ┌──────────────────┐  │
│ fixed_expenses  │   │   │ variable_expenses│  │
│─────────────────│   │   │──────────────────│  │
│ id (PK)         │   │   │ id (PK)          │  │
│ user_id (FK)    │───┤   │ user_id (FK)     │──┤
│ name            │   │   │ category         │  │
│ amount          │   │   │ estimated_amount │  │
│ category        │   │   │ is_essential     │  │
│ is_essential    │   │   │ created_at       │  │
│ due_day         │   │   └──────────────────┘  │
│ is_active       │   │                          │
└─────────────────┘   │   ┌──────────────────┐  │
                      │   │  emergency_fund  │  │
┌─────────────────┐   │   │──────────────────│  │
│ planned_expenses│   │   │ id (PK)          │  │
│─────────────────│   │   │ user_id (FK)     │──┤
│ id (PK)         │   │   │ target_amount    │  │
│ user_id (FK)    │───┤   │ current_amount   │  │
│ name            │   │   │ target_months    │  │
│ target_amount   │   │   │ updated_at       │  │
│ current_amount  │   │   └──────────────────┘  │
│ target_date     │   │                          │
│ monthly_required│   │   ┌──────────────────┐  │
│ priority        │   │   │   allocations    │  │
│ status          │   │   │──────────────────│  │
└─────────────────┘   │   │ id (PK)          │  │
                      │   │ user_id (FK)     │──┤
┌─────────────────┐   │   │ type             │  │
│  transactions   │   │   │ percentage       │  │
│─────────────────│   │   │ fixed_amount     │  │
│ id (PK)         │   │   │ priority         │  │
│ user_id (FK)    │───┘   └──────────────────┘  │
│ amount          │                              │
│ category        │       ┌──────────────────┐  │
│ description     │       │ financial_snapshot│  │
│ date            │       │──────────────────│  │
│ is_planned      │       │ id (PK)          │  │
└─────────────────┘       │ user_id (FK)     │──┘
                          │ month            │
                          │ total_income     │
                          │ total_fixed      │
                          │ total_variable   │
                          │ safe_to_spend    │
                          │ savings          │
                          │ created_at       │
                          └──────────────────┘
```

---

## Tables

### user_profile
**Created:** 2026-01-24
**Purpose:** Stores core user information and financial preferences

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL | User's name |
| currency | TEXT | NOT NULL, DEFAULT 'INR' | Preferred currency |
| risk_level | TEXT | NOT NULL, DEFAULT 'moderate' | low/moderate/high |
| dependents | INTEGER | NOT NULL, DEFAULT 0 | Number of dependents |
| created_at | INTEGER | NOT NULL | Unix timestamp |
| updated_at | INTEGER | NOT NULL | Unix timestamp |

**Notes:**
- Single user app (V1), but designed for multi-user future
- risk_level affects emergency fund calculations

---

### income_sources
**Created:** 2026-01-24
**Purpose:** Tracks all income sources (salary, freelance, etc.)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| user_id | INTEGER | FK → user_profile.id | Owner |
| name | TEXT | NOT NULL | e.g., "Primary Salary", "Freelance" |
| amount | REAL | NOT NULL | Monthly amount |
| frequency | TEXT | NOT NULL, DEFAULT 'monthly' | monthly/weekly/biweekly |
| pay_day | INTEGER | NULL | Day of month (1-31) for salary |
| is_active | INTEGER | NOT NULL, DEFAULT 1 | Boolean: 1=active, 0=inactive |
| created_at | INTEGER | NOT NULL | Unix timestamp |
| updated_at | INTEGER | NOT NULL | Unix timestamp |

**Notes:**
- Multiple income sources supported
- pay_day used for Pay-Yourself-First automation timing

---

### fixed_expenses
**Created:** 2026-01-24
**Purpose:** Recurring fixed expenses (rent, EMIs, subscriptions)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| user_id | INTEGER | FK → user_profile.id | Owner |
| name | TEXT | NOT NULL | e.g., "Rent", "Netflix" |
| amount | REAL | NOT NULL | Monthly amount |
| category | TEXT | NOT NULL | housing/utilities/insurance/subscriptions/loans/other |
| is_essential | INTEGER | NOT NULL, DEFAULT 1 | Boolean: used for emergency fund calc |
| due_day | INTEGER | NULL | Day of month when due |
| is_active | INTEGER | NOT NULL, DEFAULT 1 | Boolean |
| created_at | INTEGER | NOT NULL | Unix timestamp |
| updated_at | INTEGER | NOT NULL | Unix timestamp |

**Notes:**
- is_essential determines inclusion in emergency fund calculation
- Essential expenses × 6 = Emergency Fund Target

---

### variable_expenses
**Created:** 2026-01-24
**Purpose:** Estimated variable monthly expenses

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| user_id | INTEGER | FK → user_profile.id | Owner |
| category | TEXT | NOT NULL | food/transport/entertainment/shopping/health/other |
| estimated_amount | REAL | NOT NULL | Monthly estimated amount |
| is_essential | INTEGER | NOT NULL, DEFAULT 0 | Boolean: essential variable expenses |
| created_at | INTEGER | NOT NULL | Unix timestamp |
| updated_at | INTEGER | NOT NULL | Unix timestamp |

**Notes:**
- Categories are predefined for consistency
- Essential variable (food, transport) included in emergency fund calc

---

### emergency_fund
**Created:** 2026-01-24
**Purpose:** Tracks emergency fund status and targets

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| user_id | INTEGER | FK → user_profile.id, UNIQUE | One per user |
| target_amount | REAL | NOT NULL | Calculated target |
| current_amount | REAL | NOT NULL, DEFAULT 0 | Current savings |
| target_months | INTEGER | NOT NULL, DEFAULT 6 | Months of runway |
| monthly_essential | REAL | NOT NULL | Monthly essential expenses |
| updated_at | INTEGER | NOT NULL | Unix timestamp |

**Calculations:**
- `target_amount = monthly_essential × target_months`
- `percentage_complete = (current_amount / target_amount) × 100`
- `runway_months = current_amount / monthly_essential`

---

### allocations
**Created:** 2026-01-24
**Purpose:** Pay-Yourself-First allocation rules

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| user_id | INTEGER | FK → user_profile.id | Owner |
| type | TEXT | NOT NULL | emergency_fund/investment/goal/spending |
| name | TEXT | NOT NULL | Display name |
| percentage | REAL | NULL | Percentage of income (if percentage-based) |
| fixed_amount | REAL | NULL | Fixed amount (if amount-based) |
| priority | INTEGER | NOT NULL | Order of allocation (1 = first) |
| is_active | INTEGER | NOT NULL, DEFAULT 1 | Boolean |
| created_at | INTEGER | NOT NULL | Unix timestamp |

**Notes:**
- Either percentage OR fixed_amount, not both
- Priority determines order: emergency fund first, then investments, then goals
- Remaining after all allocations = safe-to-spend pool

---

### planned_expenses
**Created:** 2026-01-24
**Purpose:** Future planned expenses and goals

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| user_id | INTEGER | FK → user_profile.id | Owner |
| name | TEXT | NOT NULL | e.g., "Goa Trip", "New Laptop" |
| target_amount | REAL | NOT NULL | Total amount needed |
| current_amount | REAL | NOT NULL, DEFAULT 0 | Amount saved so far |
| target_date | INTEGER | NOT NULL | Unix timestamp of target date |
| monthly_required | REAL | NOT NULL | Auto-calculated monthly saving needed |
| priority | INTEGER | NOT NULL, DEFAULT 1 | 1=high, 2=medium, 3=low |
| status | TEXT | NOT NULL, DEFAULT 'active' | active/completed/cancelled |
| created_at | INTEGER | NOT NULL | Unix timestamp |
| updated_at | INTEGER | NOT NULL | Unix timestamp |

**Calculations:**
- `months_remaining = (target_date - now) / months`
- `monthly_required = (target_amount - current_amount) / months_remaining`

**Notes:**
- This is a KEY DIFFERENTIATOR - pre-declaring expenses
- Affects safe-to-spend calculation

---

### transactions
**Created:** 2026-01-24
**Purpose:** Actual spending transactions for safe-to-spend tracking

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| user_id | INTEGER | FK → user_profile.id | Owner |
| amount | REAL | NOT NULL | Transaction amount |
| category | TEXT | NOT NULL | Same categories as variable_expenses |
| description | TEXT | NULL | Optional note |
| date | INTEGER | NOT NULL | Unix timestamp |
| is_planned | INTEGER | NOT NULL, DEFAULT 0 | Boolean: linked to planned_expense |
| planned_expense_id | INTEGER | FK → planned_expenses.id, NULL | If is_planned |
| created_at | INTEGER | NOT NULL | Unix timestamp |

**Notes:**
- NOT a full expense tracker - only for safe-to-spend calculation
- Minimal friction logging

---

### financial_snapshot
**Created:** 2026-01-24
**Purpose:** Monthly snapshot for historical tracking and projections

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| user_id | INTEGER | FK → user_profile.id | Owner |
| month | TEXT | NOT NULL | Format: "2026-01" |
| total_income | REAL | NOT NULL | Total income for month |
| total_fixed_expenses | REAL | NOT NULL | Total fixed expenses |
| total_variable_expenses | REAL | NOT NULL | Total variable expenses |
| total_savings | REAL | NOT NULL | Amount saved |
| safe_to_spend_budget | REAL | NOT NULL | Calculated safe-to-spend |
| actual_spent | REAL | NOT NULL, DEFAULT 0 | What was actually spent |
| emergency_fund_balance | REAL | NOT NULL | EF balance at month end |
| created_at | INTEGER | NOT NULL | Unix timestamp |

**Notes:**
- Created at end of each month OR on-demand
- Enables future ML/predictions
- Event sourcing foundation

---

## Migration History

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-01-24 | Initial database creation with all V1 tables |

---

## Key Calculations Reference

### Safe-to-Spend (Daily)
```
monthly_income = SUM(income_sources.amount WHERE is_active)
monthly_fixed = SUM(fixed_expenses.amount WHERE is_active)
monthly_allocations = SUM(allocation amounts for emergency_fund, investments, goals)
monthly_safe_to_spend = monthly_income - monthly_fixed - monthly_allocations

days_in_month = days remaining in current month
spent_this_month = SUM(transactions.amount WHERE month = current)

daily_safe_to_spend = (monthly_safe_to_spend - spent_this_month) / days_remaining
```

### Emergency Fund Target
```
monthly_essential = SUM(fixed_expenses.amount WHERE is_essential)
                  + SUM(variable_expenses.estimated_amount WHERE is_essential)

target = monthly_essential × target_months (default 6)
```

### Planned Expense Monthly Required
```
months_remaining = CEIL((target_date - today) / 30 days)
monthly_required = (target_amount - current_amount) / months_remaining
```

---

## Indexes

| Table | Index Name | Columns | Purpose |
|-------|------------|---------|---------|
| income_sources | idx_income_user | user_id | Fast user lookup |
| fixed_expenses | idx_fixed_user | user_id | Fast user lookup |
| transactions | idx_trans_user_date | user_id, date | Monthly spending queries |
| planned_expenses | idx_planned_status | user_id, status | Active goals query |
| financial_snapshot | idx_snapshot_month | user_id, month | Historical lookups |

---

## Notes for Developers

1. **Always update this file** when modifying the database schema
2. Use migrations for schema changes - never modify tables directly
3. All timestamps stored as Unix timestamps (seconds since epoch)
4. Booleans stored as INTEGER (0/1)
5. Amounts stored as REAL (double precision)
6. Foreign keys enforced via application logic (SQLite FK support varies)
