# FinanceSensei - Database Schema (Production-Ready)

> **Version**: 2.1.0
> **Last Updated**: January 2026
> **Database**: SQLite (via sqflite package)
> **Status**: Production-Ready, All Critical Issues Resolved

---

## Design Philosophy

> "Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away." - Antoine de Saint-Exupéry

This schema is designed to be:
- **Minimal** - Only tables the app actually uses
- **Practical** - Matches current app code, not hypothetical features
- **Scalable** - Easy to extend when needed
- **Offline-First** - All data local, no network dependencies

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Core Conventions](#2-core-conventions)
3. [Schema Overview](#3-schema-overview)
4. [Table Definitions](#4-table-definitions)
5. [Indexes](#5-indexes)
6. [Triggers](#6-triggers)
7. [Queries by Screen](#7-queries-by-screen)
8. [Migration Strategy](#8-migration-strategy)
9. [Dart Models](#9-dart-models)

---

## 1. Quick Start

### 1.1 Tables Summary

| Table | Purpose | Records |
|-------|---------|---------|
| `app_settings` | User preferences (income, cycle, etc.) | ~15 key-value pairs |
| `expenses` | All transactions | Grows daily |
| `goals` | Savings goals | 5-20 typical |
| `goal_contributions` | Goal transaction history | Grows with savings |
| `emergency_fund` | Single safety fund | 1 row |
| `fund_contributions` | Emergency fund history | Grows with savings |
| `debts` | Debt tracking | 0-10 typical |
| `debt_payments` | Debt payment history | Grows with payments |
| `monthly_snapshots` | Pre-computed monthly summaries | 24 (2 years rolling) |

### 1.2 Initial Setup SQL

```sql
-- Run once on first app launch
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- Create all tables
-- (See Section 4 for full definitions)
```

---

## 2. Core Conventions

### 2.1 Naming

```
Tables:       snake_case, plural (expenses, goals)
Columns:      snake_case (created_at, target_amount)
Primary Keys: id (TEXT, UUID format)
Foreign Keys: {table}_id (goal_id, debt_id)
Booleans:     is_{name} (is_completed, is_active)
Timestamps:   {action}_at (created_at, completed_at)
```

### 2.2 Amount Storage

**CRITICAL: All amounts stored as INTEGER (paise/cents)**

```dart
// Why: Avoids floating-point precision errors
// ₹1,234.56 → stored as 123456 (paise)

// Dart conversion helpers
int toPaise(double amount) => (amount * 100).round();
double toRupees(int paise) => paise / 100.0;
```

### 2.3 Timestamps

All timestamps stored as ISO 8601 TEXT:
```
'2026-01-30T14:30:00.000Z'
```

### 2.4 IDs

UUIDs as TEXT (not auto-increment integers):
```dart
String generateId() => const Uuid().v4();
// Example: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
```

---

## 3. Schema Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    FINANCESENSEI DATABASE                    │
│                     (Single User, Offline)                   │
└─────────────────────────────────────────────────────────────┘

                         ┌──────────────┐
                         │ app_settings │
                         │──────────────│
                         │ key (PK)     │
                         │ value (JSON) │
                         └──────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   expenses   │         │    goals     │         │emergency_fund│
│──────────────│         │──────────────│         │──────────────│
│ id (PK)      │    ┌───→│ id (PK)      │         │ id (PK)      │
│ amount       │    │    │ name         │         │ current_amt  │
│ category     │    │    │ target_amt   │         │ target_months│
│ subcategory  │    │    │ current_amt  │         │ monthly_needs│
│ date         │    │    │ target_date  │         └──────┬───────┘
│ goal_id (FK)─┼────┘    │ instrument   │                │
│ fund_contrib │         └──────┬───────┘                │
└──────────────┘                │                        │
                                │                        │
                         ┌──────┴───────┐         ┌──────┴───────┐
                         │    goal_     │         │    fund_     │
                         │contributions │         │contributions │
                         │──────────────│         │──────────────│
                         │ id (PK)      │         │ id (PK)      │
                         │ goal_id (FK) │         │ fund_id (FK) │
                         │ amount       │         │ amount       │
                         │ date         │         │ date         │
                         └──────────────┘         └──────────────┘

┌──────────────┐         ┌──────────────┐
│    debts     │         │monthly_snap- │
│──────────────│         │    shots     │
│ id (PK)      │         │──────────────│
│ name         │         │ id (PK)      │
│ total_amt    │         │ year         │
│ remaining    │         │ month        │
│ interest_rate│         │ budget       │
└──────┬───────┘         │ spent        │
       │                 │ needs_spent  │
┌──────┴───────┐         │ wants_spent  │
│debt_payments │         │ savings_spent│
│──────────────│         └──────────────┘
│ id (PK)      │
│ debt_id (FK) │
│ amount       │
│ date         │
└──────────────┘
```

---

## 4. Table Definitions

### 4.1 app_settings

Key-value store for all user preferences. Simple and flexible.

```sql
CREATE TABLE app_settings (
    key             TEXT PRIMARY KEY,
    value           TEXT NOT NULL,  -- JSON encoded
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Default settings (inserted on first launch)
-- IMPORTANT: All values are stored as plain TEXT (not JSON-encoded)
-- Parse as int/bool/string in Dart based on key type
INSERT INTO app_settings (key, value) VALUES
    ('monthly_income', '0'),              -- int (paise)
    ('fixed_expenses_rent', '0'),         -- int (paise)
    ('fixed_expenses_utilities', '0'),    -- int (paise)
    ('fixed_expenses_other', '0'),        -- int (paise)
    ('needs_percent', '50'),              -- int (0-100)
    ('wants_percent', '30'),              -- int (0-100)
    ('savings_percent', '20'),            -- int (0-100)
    ('cycle_type', 'calendar'),           -- string: 'calendar' or 'custom'
    ('cycle_start_day', '1'),             -- int (1-28)
    ('onboarding_complete', 'false'),     -- bool: 'true' or 'false'
    ('app_first_launch', ''),             -- string: ISO date or empty
    ('schema_version', '1');              -- int
```

**Settings Reference:**

| Key | Type | Dart Parse | Description | Example |
|-----|------|------------|-------------|---------|
| monthly_income | int (paise) | `int.parse(value)` | Take-home salary | '5000000' (₹50,000) |
| fixed_expenses_rent | int (paise) | `int.parse(value)` | Rent/EMI | '1500000' |
| fixed_expenses_utilities | int (paise) | `int.parse(value)` | Bills | '300000' |
| fixed_expenses_other | int (paise) | `int.parse(value)` | Other fixed | '200000' |
| needs_percent | int | `int.parse(value)` | Needs allocation | '50' |
| wants_percent | int | `int.parse(value)` | Wants allocation | '30' |
| savings_percent | int | `int.parse(value)` | Savings allocation | '20' |
| cycle_type | string | `value` | Budget cycle type | 'calendar' |
| cycle_start_day | int | `int.parse(value)` | Custom cycle day | '1' |
| onboarding_complete | bool | `value == 'true'` | Setup finished | 'true' |
| app_first_launch | string | `value` | First launch date | '2026-01-30' |
| schema_version | int | `int.parse(value)` | DB schema version | '1' |

---

### 4.2 expenses

All expense transactions. The most frequently accessed table.

```sql
CREATE TABLE expenses (
    id              TEXT PRIMARY KEY,

    -- Amount (always positive, in paise)
    amount          INTEGER NOT NULL CHECK (amount > 0),

    -- Category: 'needs', 'wants', 'savings'
    category        TEXT NOT NULL CHECK (category IN ('needs', 'wants', 'savings')),

    -- Subcategory (depends on category)
    -- Needs: 'rent_emi', 'utilities', 'other_fixed', 'food', 'transport', 'health'
    -- Wants: 'shopping', 'entertainment', 'other'
    -- Savings: 'emergency_fund', 'goal'
    subcategory     TEXT NOT NULL,

    -- For savings to goal: which goal
    goal_id         TEXT,

    -- For savings to emergency fund: mark as fund contribution
    is_fund_contribution INTEGER NOT NULL DEFAULT 0,

    -- Transaction date (YYYY-MM-DD)
    date            TEXT NOT NULL,

    -- Optional note
    note            TEXT,

    -- Audit
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at      TEXT,  -- Soft delete

    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE SET NULL
);
```

**Category & Subcategory Values:**

| Category | Subcategory | Maps to App Enum |
|----------|-------------|------------------|
| needs | rent_emi | ExpenseSubcategory.rentEmi |
| needs | utilities | ExpenseSubcategory.utilitiesBills |
| needs | other_fixed | ExpenseSubcategory.otherFixed |
| needs | food | ExpenseSubcategory.foodDining |
| needs | transport | ExpenseSubcategory.transport |
| needs | health | ExpenseSubcategory.healthWellness |
| wants | shopping | ExpenseSubcategory.shopping |
| wants | entertainment | ExpenseSubcategory.entertainment |
| wants | other | ExpenseSubcategory.otherVariable |
| savings | emergency_fund | SavingsDestination.emergencyFund |
| savings | goal | SavingsDestination.goal |

---

### 4.3 goals

Savings goals with timeline tracking.

```sql
CREATE TABLE goals (
    id              TEXT PRIMARY KEY,

    name            TEXT NOT NULL,

    -- Amounts in paise
    target_amount   INTEGER NOT NULL CHECK (target_amount > 0),
    current_amount  INTEGER NOT NULL DEFAULT 0 CHECK (current_amount >= 0),

    -- Target date (YYYY-MM-DD)
    target_date     TEXT NOT NULL,

    -- Instrument: 'savings_account', 'piggy_bank', 'fixed_deposit',
    --             'mutual_funds', 'recurring_deposit', 'stocks', 'index_funds', 'bonds'
    instrument      TEXT NOT NULL,

    -- Status: 'active', 'completed', 'paused'
    status          TEXT NOT NULL DEFAULT 'active',
    completed_at    TEXT,

    -- Audit
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at      TEXT
);
```

**Computed Properties (in Dart, not DB):**

```dart
// Timeline calculation
GoalTimeline get timeline {
  final years = targetDate.difference(DateTime.now()).inDays / 365;
  if (years < 1) return GoalTimeline.shortTerm;
  if (years <= 5) return GoalTimeline.midTerm;
  return GoalTimeline.longTerm;
}

// Progress
double get progress => (currentAmount / targetAmount * 100).clamp(0, 100);
double get remaining => max(0, targetAmount - currentAmount);
bool get isCompleted => currentAmount >= targetAmount;
```

---

### 4.4 goal_contributions

Audit trail for goal savings. Created automatically when savings expense targets a goal.

```sql
CREATE TABLE goal_contributions (
    id              TEXT PRIMARY KEY,
    goal_id         TEXT NOT NULL,
    expense_id      TEXT,  -- NULL if manual adjustment

    -- Amount in paise (positive = add, negative = withdraw)
    amount          INTEGER NOT NULL,

    -- Type: 'contribution', 'withdrawal', 'adjustment'
    type            TEXT NOT NULL DEFAULT 'contribution',

    date            TEXT NOT NULL,
    note            TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);
```

**Expense Edit/Delete Semantics:**

When an expense linked to a goal contribution is modified or deleted:

```dart
/// SCENARIO 1: User deletes a savings expense
/// Action: Soft delete the expense, create a reversal contribution
Future<void> deleteSavingsExpense(String expenseId) async {
  final expense = await getExpense(expenseId);
  if (expense.goalId != null) {
    // 1. Mark expense as deleted
    await softDeleteExpense(expenseId);

    // 2. Create reversal contribution (negative amount)
    await insertGoalContribution(GoalContribution(
      id: generateId(),
      goalId: expense.goalId!,
      expenseId: expenseId,  // Link to deleted expense for audit
      amount: -expense.amount,  // Negative to reverse
      type: 'withdrawal',
      date: DateTime.now().toIso8601String().split('T')[0],
      note: 'Reversed: expense deleted',
    ));
    // Trigger auto-updates goal.current_amount
  }
}

/// SCENARIO 2: User edits a savings expense amount
/// Action: Create adjustment contribution for the difference
Future<void> updateSavingsExpense(String expenseId, int newAmount) async {
  final oldExpense = await getExpense(expenseId);
  if (oldExpense.goalId != null) {
    final difference = newAmount - oldExpense.amount;
    if (difference != 0) {
      // Create adjustment contribution
      await insertGoalContribution(GoalContribution(
        id: generateId(),
        goalId: oldExpense.goalId!,
        expenseId: expenseId,
        amount: difference,  // Can be positive or negative
        type: 'adjustment',
        date: DateTime.now().toIso8601String().split('T')[0],
        note: 'Adjusted: expense modified',
      ));
    }
  }
  await updateExpense(expenseId, amount: newAmount);
}

/// SCENARIO 3: User changes goal on expense (rare)
/// Action: Reverse from old goal, contribute to new goal
```

---

### 4.5 emergency_fund

Single emergency fund per user. Always exactly 1 row.

```sql
CREATE TABLE emergency_fund (
    id                  TEXT PRIMARY KEY DEFAULT 'default_fund',

    -- Current saved amount (paise)
    current_amount      INTEGER NOT NULL DEFAULT 0,

    -- Target: X months of essentials
    target_months       INTEGER NOT NULL DEFAULT 6,

    -- Monthly essential expenses (paise) - from needs budget
    monthly_essentials  INTEGER NOT NULL DEFAULT 0,

    -- Where it's stored
    instrument          TEXT NOT NULL DEFAULT 'savings_account',

    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Initialize single fund on first launch
INSERT INTO emergency_fund (id) VALUES ('default_fund');
```

**monthly_essentials Calculation:**

This field represents the user's monthly essential expenses (needs). It is calculated from app_settings:

```dart
// How monthly_essentials is derived
int calculateMonthlyEssentials(Map<String, String> settings) {
  final income = int.parse(settings['monthly_income'] ?? '0');
  final needsPercent = int.parse(settings['needs_percent'] ?? '50');

  // Monthly essentials = income allocated to needs
  return (income * needsPercent / 100).round();
}

// When to update:
// 1. When user changes monthly_income
// 2. When user changes needs_percent
// 3. During onboarding setup completion
```

**Computed Properties (in Dart):**

```dart
int get targetAmount => monthlyEssentials * targetMonths;
double get runwayMonths => monthlyEssentials > 0
    ? currentAmount / monthlyEssentials
    : 0;
double get progress => targetAmount > 0
    ? (currentAmount / targetAmount * 100).clamp(0, 100)
    : 0;
```

---

### 4.6 fund_contributions

Audit trail for emergency fund. Created when savings expense targets emergency fund.

```sql
CREATE TABLE fund_contributions (
    id              TEXT PRIMARY KEY,
    fund_id         TEXT NOT NULL DEFAULT 'default_fund',
    expense_id      TEXT,

    amount          INTEGER NOT NULL,
    type            TEXT NOT NULL DEFAULT 'contribution',

    date            TEXT NOT NULL,
    note            TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (fund_id) REFERENCES emergency_fund(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);
```

---

### 4.7 debts

Debt tracking with automatic priority based on interest rate.

```sql
CREATE TABLE debts (
    id              TEXT PRIMARY KEY,

    name            TEXT NOT NULL,
    lender          TEXT,  -- Bank/person name

    -- Amounts in paise
    total_amount    INTEGER NOT NULL CHECK (total_amount > 0),
    remaining_amount INTEGER NOT NULL CHECK (remaining_amount >= 0),

    -- Interest rate (annual %, e.g., 15.5)
    interest_rate   REAL NOT NULL CHECK (interest_rate >= 0),

    -- Minimum monthly payment (paise)
    minimum_payment INTEGER NOT NULL DEFAULT 0,

    -- Status: 'active', 'paid_off'
    status          TEXT NOT NULL DEFAULT 'active',
    paid_off_at     TEXT,

    -- Audit
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at      TEXT
);
```

**Priority Calculation (in Dart):**

```dart
DebtPriority get priority {
  if (interestRate > 15) return DebtPriority.high;
  if (interestRate >= 8) return DebtPriority.medium;
  return DebtPriority.low;
}
```

---

### 4.8 debt_payments

Payment history for debts.

```sql
CREATE TABLE debt_payments (
    id              TEXT PRIMARY KEY,
    debt_id         TEXT NOT NULL,
    expense_id      TEXT,

    amount          INTEGER NOT NULL CHECK (amount > 0),

    date            TEXT NOT NULL,
    note            TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);
```

---

### 4.9 monthly_snapshots

Pre-computed monthly summaries for Budget History. Updated at end of each month or on-demand.

```sql
CREATE TABLE monthly_snapshots (
    id              TEXT PRIMARY KEY,  -- Format: 'YYYY-MM'

    year            INTEGER NOT NULL,
    month           INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),

    -- Budget for that month (paise)
    total_budget    INTEGER NOT NULL DEFAULT 0,
    needs_budget    INTEGER NOT NULL DEFAULT 0,
    wants_budget    INTEGER NOT NULL DEFAULT 0,
    savings_budget  INTEGER NOT NULL DEFAULT 0,

    -- Actual spending (paise)
    total_spent     INTEGER NOT NULL DEFAULT 0,
    needs_spent     INTEGER NOT NULL DEFAULT 0,
    wants_spent     INTEGER NOT NULL DEFAULT 0,
    savings_spent   INTEGER NOT NULL DEFAULT 0,

    -- Result
    remaining       INTEGER NOT NULL DEFAULT 0,  -- budget - spent

    -- Expense count
    transaction_count INTEGER NOT NULL DEFAULT 0,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    UNIQUE(year, month)
);
```

**Monthly Snapshot Generation Strategy:**

Snapshots are generated/updated at specific trigger points, not in real-time:

```dart
/// WHEN to generate/update snapshots:
/// 1. When app opens and current month has no snapshot
/// 2. When navigating to Budget History screen
/// 3. When previous month ends (detected on app open)
/// 4. Manual refresh from Budget History

class SnapshotService {
  /// Generate snapshot for a specific month
  Future<MonthlySnapshot> generateSnapshot(int year, int month) async {
    // Get cycle boundaries for this month
    final cycleStart = _getCycleStart(year, month);
    final cycleEnd = _getCycleEnd(year, month);

    // Get settings AS THEY WERE for that month
    // (For historical accuracy, consider storing settings in snapshot)
    final income = await getSetting('monthly_income');
    final needsPct = await getSetting('needs_percent');
    final wantsPct = await getSetting('wants_percent');
    final savingsPct = await getSetting('savings_percent');

    // Calculate budgets
    final totalBudget = income;
    final needsBudget = (income * needsPct / 100).round();
    final wantsBudget = (income * wantsPct / 100).round();
    final savingsBudget = (income * savingsPct / 100).round();

    // Get actual spending from expenses table
    final expenses = await getExpensesForPeriod(cycleStart, cycleEnd);
    final needsSpent = expenses
        .where((e) => e.category == 'needs')
        .fold(0, (sum, e) => sum + e.amount);
    final wantsSpent = expenses
        .where((e) => e.category == 'wants')
        .fold(0, (sum, e) => sum + e.amount);
    final savingsSpent = expenses
        .where((e) => e.category == 'savings')
        .fold(0, (sum, e) => sum + e.amount);

    return MonthlySnapshot(
      id: '$year-${month.toString().padLeft(2, '0')}',
      year: year,
      month: month,
      totalBudget: totalBudget,
      needsBudget: needsBudget,
      wantsBudget: wantsBudget,
      savingsBudget: savingsBudget,
      totalSpent: needsSpent + wantsSpent + savingsSpent,
      needsSpent: needsSpent,
      wantsSpent: wantsSpent,
      savingsSpent: savingsSpent,
      remaining: totalBudget - (needsSpent + wantsSpent + savingsSpent),
      transactionCount: expenses.length,
    );
  }

  /// Called on app open - ensure current and past month snapshots exist
  Future<void> ensureSnapshots() async {
    final now = DateTime.now();

    // Current month (may need updates as expenses are added)
    await generateOrUpdateSnapshot(now.year, now.month);

    // Previous month (finalize if not exists)
    final prev = DateTime(now.year, now.month - 1);
    await generateOrUpdateSnapshot(prev.year, prev.month);
  }

  /// Cleanup: Keep only last 24 months
  Future<void> pruneOldSnapshots() async {
    final cutoff = DateTime.now().subtract(Duration(days: 730)); // ~2 years
    await db.delete('monthly_snapshots',
        where: 'year < ? OR (year = ? AND month < ?)',
        whereArgs: [cutoff.year, cutoff.year, cutoff.month]);
  }
}
```

**Important Considerations:**

1. **Current Month Snapshot**: Always recalculated (not cached) since expenses change
2. **Past Month Snapshots**: Can be cached, only regenerate if expenses for that month are edited
3. **Settings at Snapshot Time**: Consider storing budget settings in snapshot for historical accuracy (if user changes income, old snapshots should reflect old budget)

---

## 5. Indexes

Strategic indexes for common query patterns:

```sql
-- Expenses: Most queried table
CREATE INDEX idx_expenses_date ON expenses(date) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_category ON expenses(category) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_date_category ON expenses(date, category) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_goal ON expenses(goal_id) WHERE goal_id IS NOT NULL;

-- Goals: Active goals query
CREATE INDEX idx_goals_status ON goals(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_goals_target_date ON goals(target_date) WHERE status = 'active';

-- Contributions: By goal/fund
CREATE INDEX idx_goal_contributions_goal ON goal_contributions(goal_id);
CREATE INDEX idx_fund_contributions_fund ON fund_contributions(fund_id);

-- Debts: Active debts by priority
CREATE INDEX idx_debts_status ON debts(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_debts_interest ON debts(interest_rate DESC) WHERE status = 'active';

-- Monthly snapshots: Date range queries
CREATE INDEX idx_snapshots_date ON monthly_snapshots(year DESC, month DESC);
```

---

## 6. Triggers

Automatic data maintenance:

```sql
-- Update goal.current_amount when contribution added
CREATE TRIGGER trg_goal_contribution_insert
AFTER INSERT ON goal_contributions
BEGIN
    UPDATE goals
    SET current_amount = current_amount + NEW.amount,
        updated_at = datetime('now'),
        status = CASE
            WHEN current_amount + NEW.amount >= target_amount THEN 'completed'
            ELSE status
        END,
        completed_at = CASE
            WHEN current_amount + NEW.amount >= target_amount AND completed_at IS NULL
            THEN datetime('now')
            ELSE completed_at
        END
    WHERE id = NEW.goal_id;
END;

-- Update emergency_fund.current_amount when contribution added
CREATE TRIGGER trg_fund_contribution_insert
AFTER INSERT ON fund_contributions
BEGIN
    UPDATE emergency_fund
    SET current_amount = current_amount + NEW.amount,
        updated_at = datetime('now')
    WHERE id = NEW.fund_id;
END;

-- Update debt.remaining_amount when payment made
CREATE TRIGGER trg_debt_payment_insert
AFTER INSERT ON debt_payments
BEGIN
    UPDATE debts
    SET remaining_amount = remaining_amount - NEW.amount,
        updated_at = datetime('now'),
        status = CASE
            WHEN remaining_amount - NEW.amount <= 0 THEN 'paid_off'
            ELSE status
        END,
        paid_off_at = CASE
            WHEN remaining_amount - NEW.amount <= 0 THEN datetime('now')
            ELSE paid_off_at
        END
    WHERE id = NEW.debt_id;
END;

-- Update timestamps on settings change
CREATE TRIGGER trg_settings_update
AFTER UPDATE ON app_settings
BEGIN
    UPDATE app_settings SET updated_at = datetime('now') WHERE key = NEW.key;
END;
```

---

## 7. Queries by Screen

### 7.1 Home Screen

```sql
-- Get current cycle budget (from settings)
SELECT
    CAST(json_extract(
        (SELECT value FROM app_settings WHERE key = 'monthly_income'), '$'
    ) AS INTEGER) as income,
    CAST((SELECT value FROM app_settings WHERE key = 'needs_percent') AS INTEGER) as needs_pct,
    CAST((SELECT value FROM app_settings WHERE key = 'wants_percent') AS INTEGER) as wants_pct,
    CAST((SELECT value FROM app_settings WHERE key = 'savings_percent') AS INTEGER) as savings_pct;

-- Get expenses for current cycle
SELECT * FROM expenses
WHERE date BETWEEN :cycle_start AND :cycle_end
AND deleted_at IS NULL
ORDER BY date DESC, created_at DESC;

-- Get spending by category for current cycle
SELECT
    category,
    SUM(amount) as total_spent,
    COUNT(*) as count
FROM expenses
WHERE date BETWEEN :cycle_start AND :cycle_end
AND deleted_at IS NULL
GROUP BY category;

-- Get recent expenses (last 5)
SELECT * FROM expenses
WHERE deleted_at IS NULL
ORDER BY created_at DESC
LIMIT 5;
```

### 7.2 Monthly Budget Screen

```sql
-- Get 50-30-20 breakdown for current cycle
SELECT
    category,
    subcategory,
    SUM(amount) as spent
FROM expenses
WHERE date BETWEEN :cycle_start AND :cycle_end
AND deleted_at IS NULL
GROUP BY category, subcategory;
```

### 7.3 Budget History Screen

```sql
-- Get last 24 months of snapshots
SELECT
    year,
    month,
    total_budget,
    total_spent,
    remaining,
    needs_spent,
    wants_spent,
    savings_spent
FROM monthly_snapshots
ORDER BY year DESC, month DESC
LIMIT 24;

-- Get or create snapshot for specific month (done in Dart)
SELECT * FROM monthly_snapshots WHERE year = :year AND month = :month;
```

### 7.4 Goals Screen

```sql
-- Get all active goals
SELECT * FROM goals
WHERE status = 'active'
AND deleted_at IS NULL
ORDER BY target_date ASC;

-- Get total across all goals
SELECT
    SUM(current_amount) as total_saved,
    SUM(target_amount) as total_target,
    COUNT(*) as goal_count
FROM goals
WHERE status = 'active'
AND deleted_at IS NULL;
```

### 7.5 Goal Detail Screen

```sql
-- Get single goal
SELECT * FROM goals WHERE id = :goal_id;

-- Get contribution history
SELECT * FROM goal_contributions
WHERE goal_id = :goal_id
ORDER BY date DESC;
```

### 7.6 Emergency Fund Screen

```sql
-- Get fund status
SELECT * FROM emergency_fund WHERE id = 'default_fund';

-- Get contribution history
SELECT * FROM fund_contributions
WHERE fund_id = 'default_fund'
ORDER BY date DESC;
```

### 7.7 Debt Screen

```sql
-- Get all active debts by priority
SELECT *,
    CASE
        WHEN interest_rate > 15 THEN 'high'
        WHEN interest_rate >= 8 THEN 'medium'
        ELSE 'low'
    END as priority
FROM debts
WHERE status = 'active'
AND deleted_at IS NULL
ORDER BY interest_rate DESC;

-- Get debt payment history
SELECT * FROM debt_payments
WHERE debt_id = :debt_id
ORDER BY date DESC;
```

### 7.8 Profile Screen

```sql
-- Get all settings
SELECT key, value FROM app_settings;

-- Update setting
UPDATE app_settings SET value = :value WHERE key = :key;
```

---

## 8. Migration Strategy

### 8.1 Version Tracking

Version stored in `app_settings`:

```sql
SELECT value FROM app_settings WHERE key = 'schema_version';
```

### 8.2 Migration Files

```
lib/core/database/
├── database_service.dart      # Main DB wrapper
├── migrations/
│   ├── migration_v1.dart      # Initial schema
│   ├── migration_v2.dart      # Future changes
│   └── migration_runner.dart  # Runs migrations
└── repositories/
    ├── expense_repository.dart
    ├── goal_repository.dart
    ├── settings_repository.dart
    └── ...
```

### 8.3 Migration Pattern

```dart
abstract class Migration {
  int get version;
  Future<void> up(Database db);
  Future<void> down(Database db);  // For rollback
}

class MigrationV1 implements Migration {
  @override
  int get version => 1;

  @override
  Future<void> up(Database db) async {
    // Create all tables from Section 4
  }

  @override
  Future<void> down(Database db) async {
    // Drop all tables
  }
}
```

---

## 9. Dart Models

### 9.1 Model Conventions

All models should have:

```dart
class MyModel {
  // Properties
  final String id;
  // ...

  // Constructor
  const MyModel({required this.id, ...});

  // From database
  factory MyModel.fromMap(Map<String, dynamic> map);

  // To database
  Map<String, dynamic> toMap();

  // Copy with
  MyModel copyWith({...});
}
```

### 9.2 Amount Conversion Mixin

```dart
mixin AmountConversion {
  // Display (double) to Storage (int paise)
  static int toPaise(double amount) => (amount * 100).round();

  // Storage (int paise) to Display (double)
  static double toRupees(int paise) => paise / 100.0;
}
```

### 9.3 Expense Model (Updated)

```dart
class Expense with AmountConversion {
  final String id;
  final int amount;  // In paise
  final ExpenseCategory category;
  final String subcategory;
  final String? goalId;
  final bool isFundContribution;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime? deletedAt;

  // Display amount in rupees
  double get displayAmount => AmountConversion.toRupees(amount);

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: ExpenseCategory.values.byName(map['category']),
      subcategory: map['subcategory'],
      goalId: map['goal_id'],
      isFundContribution: map['is_fund_contribution'] == 1,
      date: DateTime.parse(map['date']),
      note: map['note'],
      createdAt: DateTime.parse(map['created_at']),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name,
      'subcategory': subcategory,
      'goal_id': goalId,
      'is_fund_contribution': isFundContribution ? 1 : 0,
      'date': date.toIso8601String().split('T')[0],
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
```

### 9.4 Subcategory Mapping

```dart
extension SubcategoryMapping on ExpenseSubcategory {
  String get dbValue {
    switch (this) {
      case ExpenseSubcategory.rentEmi: return 'rent_emi';
      case ExpenseSubcategory.utilitiesBills: return 'utilities';
      case ExpenseSubcategory.otherFixed: return 'other_fixed';
      case ExpenseSubcategory.foodDining: return 'food';
      case ExpenseSubcategory.transport: return 'transport';
      case ExpenseSubcategory.healthWellness: return 'health';
      case ExpenseSubcategory.shopping: return 'shopping';
      case ExpenseSubcategory.entertainment: return 'entertainment';
      case ExpenseSubcategory.otherVariable: return 'other';
    }
  }

  static ExpenseSubcategory fromDbValue(String value) {
    switch (value) {
      case 'rent_emi': return ExpenseSubcategory.rentEmi;
      case 'utilities': return ExpenseSubcategory.utilitiesBills;
      case 'other_fixed': return ExpenseSubcategory.otherFixed;
      case 'food': return ExpenseSubcategory.foodDining;
      case 'transport': return ExpenseSubcategory.transport;
      case 'health': return ExpenseSubcategory.healthWellness;
      case 'shopping': return ExpenseSubcategory.shopping;
      case 'entertainment': return ExpenseSubcategory.entertainment;
      case 'other': return ExpenseSubcategory.otherVariable;
      default: throw ArgumentError('Unknown subcategory: $value');
    }
  }
}
```

---

## Appendix A: Full Schema SQL

```sql
-- ============================================
-- FINANCESENSEI DATABASE SCHEMA v1
-- Run this to create all tables
-- ============================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- Settings
CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Expenses
CREATE TABLE IF NOT EXISTS expenses (
    id TEXT PRIMARY KEY,
    amount INTEGER NOT NULL CHECK (amount > 0),
    category TEXT NOT NULL CHECK (category IN ('needs', 'wants', 'savings')),
    subcategory TEXT NOT NULL,
    goal_id TEXT,
    is_fund_contribution INTEGER NOT NULL DEFAULT 0,
    date TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at TEXT,
    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE SET NULL
);

-- Goals
CREATE TABLE IF NOT EXISTS goals (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    target_amount INTEGER NOT NULL CHECK (target_amount > 0),
    current_amount INTEGER NOT NULL DEFAULT 0,
    target_date TEXT NOT NULL,
    instrument TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    completed_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at TEXT
);

-- Goal Contributions
CREATE TABLE IF NOT EXISTS goal_contributions (
    id TEXT PRIMARY KEY,
    goal_id TEXT NOT NULL,
    expense_id TEXT,
    amount INTEGER NOT NULL,
    type TEXT NOT NULL DEFAULT 'contribution',
    date TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);

-- Emergency Fund
CREATE TABLE IF NOT EXISTS emergency_fund (
    id TEXT PRIMARY KEY DEFAULT 'default_fund',
    current_amount INTEGER NOT NULL DEFAULT 0,
    target_months INTEGER NOT NULL DEFAULT 6,
    monthly_essentials INTEGER NOT NULL DEFAULT 0,
    instrument TEXT NOT NULL DEFAULT 'savings_account',
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Fund Contributions
CREATE TABLE IF NOT EXISTS fund_contributions (
    id TEXT PRIMARY KEY,
    fund_id TEXT NOT NULL DEFAULT 'default_fund',
    expense_id TEXT,
    amount INTEGER NOT NULL,
    type TEXT NOT NULL DEFAULT 'contribution',
    date TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (fund_id) REFERENCES emergency_fund(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);

-- Debts
CREATE TABLE IF NOT EXISTS debts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    lender TEXT,
    total_amount INTEGER NOT NULL CHECK (total_amount > 0),
    remaining_amount INTEGER NOT NULL CHECK (remaining_amount >= 0),
    interest_rate REAL NOT NULL CHECK (interest_rate >= 0),
    minimum_payment INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    paid_off_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at TEXT
);

-- Debt Payments
CREATE TABLE IF NOT EXISTS debt_payments (
    id TEXT PRIMARY KEY,
    debt_id TEXT NOT NULL,
    expense_id TEXT,
    amount INTEGER NOT NULL CHECK (amount > 0),
    date TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);

-- Monthly Snapshots
CREATE TABLE IF NOT EXISTS monthly_snapshots (
    id TEXT PRIMARY KEY,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    total_budget INTEGER NOT NULL DEFAULT 0,
    needs_budget INTEGER NOT NULL DEFAULT 0,
    wants_budget INTEGER NOT NULL DEFAULT 0,
    savings_budget INTEGER NOT NULL DEFAULT 0,
    total_spent INTEGER NOT NULL DEFAULT 0,
    needs_spent INTEGER NOT NULL DEFAULT 0,
    wants_spent INTEGER NOT NULL DEFAULT 0,
    savings_spent INTEGER NOT NULL DEFAULT 0,
    remaining INTEGER NOT NULL DEFAULT 0,
    transaction_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(year, month)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_debts_status ON debts(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_snapshots_date ON monthly_snapshots(year DESC, month DESC);

-- Default data (all values as plain TEXT, not JSON)
INSERT OR IGNORE INTO app_settings (key, value) VALUES
    ('monthly_income', '0'),
    ('fixed_expenses_rent', '0'),
    ('fixed_expenses_utilities', '0'),
    ('fixed_expenses_other', '0'),
    ('needs_percent', '50'),
    ('wants_percent', '30'),
    ('savings_percent', '20'),
    ('cycle_type', 'calendar'),
    ('cycle_start_day', '1'),
    ('onboarding_complete', 'false'),
    ('app_first_launch', ''),
    ('schema_version', '1');

INSERT OR IGNORE INTO emergency_fund (id) VALUES ('default_fund');
```

---

## Appendix B: Features Not Requiring Database

| Feature | Storage | Reason |
|---------|---------|--------|
| Financial Literacy (Learn) | Hardcoded in `lessons_data.dart` | Static educational content |
| How It Works (Knowledge) | Hardcoded in widget | Static app explanation |
| Theme/UI preferences | SharedPreferences | Simple key-value, not relational |

---

## Appendix C: Future Enhancements (Not in v1)

When needed, these can be added:

| Feature | Table(s) Needed |
|---------|-----------------|
| Multi-account | accounts, expense.account_id |
| Recurring transactions | recurring_rules |
| SMS auto-import | sms_patterns, expense.sms_hash |
| Custom categories | categories (replace enums) |
| Tags | tags, expense_tags |
| Attachments/receipts | attachments |
| Multiple users | users, all tables get user_id |

---

*This document is the source of truth for database design. Update when schema changes.*
