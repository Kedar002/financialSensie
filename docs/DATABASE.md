# FinanceSensei - Database Schema Design

> **Version**: 1.0.0
> **Last Updated**: January 2026
> **Database**: SQLite (via sqflite package)
> **Status**: Production-Ready Schema

---

## Table of Contents

1. [Design Principles](#1-design-principles)
2. [Entity Relationship Diagram](#2-entity-relationship-diagram)
3. [Core Tables](#3-core-tables)
4. [Transaction Tables](#4-transaction-tables)
5. [Settings Tables](#5-settings-tables)
6. [Financial Plan Tables](#6-financial-plan-tables)
7. [Analytics & History Tables](#7-analytics--history-tables)
8. [Future-Ready Tables](#8-future-ready-tables)
9. [Indexes](#9-indexes)
10. [Migrations Strategy](#10-migrations-strategy)
11. [Data Validation Rules](#11-data-validation-rules)
12. [Query Patterns](#12-query-patterns)
13. [Backup & Recovery](#13-backup--recovery)

---

## 1. Design Principles

### 1.1 Core Principles

| Principle | Implementation |
|-----------|----------------|
| **Offline-First** | All data stored locally in SQLite |
| **No Data Loss** | Soft deletes with `deleted_at` timestamps |
| **Auditability** | `created_at`, `updated_at` on all tables |
| **Scalability** | UUID primary keys, normalized structure |
| **Flexibility** | JSON columns for extensible metadata |
| **Performance** | Strategic indexes on query patterns |
| **Integrity** | Foreign keys with proper cascades |

### 1.2 Naming Conventions

```
Tables:       snake_case, plural (expenses, goals)
Columns:      snake_case (created_at, target_amount)
Primary Keys: id (UUID string)
Foreign Keys: {table_singular}_id (goal_id, user_id)
Booleans:     is_{name} or has_{name} (is_active, has_reminder)
Timestamps:   {action}_at (created_at, deleted_at)
Amounts:      Store as INTEGER (paise/cents), display as decimal
```

### 1.3 Amount Storage Strategy

```
CRITICAL: Store all amounts as INTEGER (smallest currency unit)

₹1,234.56 → stored as 123456 (paise)
₹50,000   → stored as 5000000 (paise)

Why:
- Avoids floating-point precision errors
- SQLite doesn't have DECIMAL type
- Simple integer math for calculations
- Convert to display: amount / 100
```

---

## 2. Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FINANCESENSEI DATABASE                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    users     │       │   accounts   │       │  categories  │
│──────────────│       │──────────────│       │──────────────│
│ id (PK)      │──┐    │ id (PK)      │       │ id (PK)      │
│ name         │  │    │ user_id (FK) │←──┐   │ name         │
│ email        │  │    │ name         │   │   │ type         │
│ created_at   │  │    │ type         │   │   │ parent_id    │
└──────────────┘  │    │ balance      │   │   │ icon         │
                  │    └──────────────┘   │   │ color        │
                  │                       │   └──────────────┘
                  │    ┌──────────────────┘          │
                  │    │                             │
                  ▼    ▼                             ▼
            ┌─────────────────┐              ┌──────────────┐
            │    expenses     │              │   budgets    │
            │─────────────────│              │──────────────│
            │ id (PK)         │              │ id (PK)      │
            │ user_id (FK)    │              │ user_id (FK) │
            │ account_id (FK) │              │ category_id  │
            │ category_id(FK) │              │ amount       │
            │ amount          │              │ period_type  │
            │ date            │              └──────────────┘
            │ type            │
            └─────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌──────────────┐       ┌──────────────────┐
│    goals     │       │  emergency_fund  │
│──────────────│       │──────────────────│
│ id (PK)      │       │ id (PK)          │
│ user_id (FK) │       │ user_id (FK)     │
│ name         │       │ current_amount   │
│ target       │       │ target_months    │
│ current      │       │ monthly_essential│
│ deadline     │       └──────────────────┘
└──────────────┘
        │
        ▼
┌──────────────────┐       ┌──────────────┐
│ goal_transactions│       │    debts     │
│──────────────────│       │──────────────│
│ id (PK)          │       │ id (PK)      │
│ goal_id (FK)     │       │ user_id (FK) │
│ expense_id (FK)  │       │ name         │
│ amount           │       │ total        │
│ date             │       │ remaining    │
└──────────────────┘       │ interest_rate│
                           └──────────────┘
```

---

## 3. Core Tables

### 3.1 users

Primary user table. Supports multi-user future expansion.

```sql
CREATE TABLE users (
    id                  TEXT PRIMARY KEY,
    name                TEXT NOT NULL,
    email               TEXT,
    phone               TEXT,
    currency_code       TEXT NOT NULL DEFAULT 'INR',
    locale              TEXT NOT NULL DEFAULT 'en_IN',
    profile_image_path  TEXT,
    onboarding_complete INTEGER NOT NULL DEFAULT 0,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at          TEXT,
    metadata            TEXT  -- JSON for extensibility
);

-- Default user for single-user mode
INSERT INTO users (id, name, currency_code)
VALUES ('default', 'User', 'INR');
```

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (UUID) | Primary key |
| name | TEXT | User's display name |
| email | TEXT | Optional email |
| phone | TEXT | Optional phone (for SMS parsing) |
| currency_code | TEXT | ISO currency code (INR, USD) |
| locale | TEXT | Locale for formatting |
| onboarding_complete | INTEGER | 0=false, 1=true |
| metadata | TEXT | JSON for future fields |

---

### 3.2 accounts

Bank accounts, wallets, cash. Enables multi-account tracking.

```sql
CREATE TABLE accounts (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    name            TEXT NOT NULL,
    type            TEXT NOT NULL,  -- 'bank', 'wallet', 'cash', 'credit_card'
    bank_name       TEXT,
    account_number  TEXT,           -- Last 4 digits only (security)
    current_balance INTEGER NOT NULL DEFAULT 0,  -- in paise
    is_default      INTEGER NOT NULL DEFAULT 0,
    is_active       INTEGER NOT NULL DEFAULT 1,
    icon            TEXT,
    color           TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at      TEXT,
    metadata        TEXT,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Default cash account
INSERT INTO accounts (id, user_id, name, type, is_default)
VALUES ('default_cash', 'default', 'Cash', 'cash', 1);
```

| Column | Type | Description |
|--------|------|-------------|
| type | TEXT | bank, wallet, cash, credit_card |
| current_balance | INTEGER | Balance in paise |
| is_default | INTEGER | Default account for transactions |
| sort_order | INTEGER | Display order |

---

### 3.3 categories

Hierarchical categories for expenses. Supports custom user categories.

```sql
CREATE TABLE categories (
    id              TEXT PRIMARY KEY,
    user_id         TEXT,           -- NULL = system default
    parent_id       TEXT,           -- For subcategories
    name            TEXT NOT NULL,
    type            TEXT NOT NULL,  -- 'expense', 'income', 'transfer'
    budget_type     TEXT,           -- 'needs', 'wants', 'savings', NULL
    icon            TEXT NOT NULL DEFAULT 'category',
    color           TEXT NOT NULL DEFAULT '#757575',
    is_system       INTEGER NOT NULL DEFAULT 0,
    is_active       INTEGER NOT NULL DEFAULT 1,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at      TEXT,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- System default categories (Needs)
INSERT INTO categories (id, name, type, budget_type, icon, is_system, sort_order) VALUES
('cat_rent', 'Rent / EMI', 'expense', 'needs', 'home', 1, 1),
('cat_utilities', 'Utilities & Bills', 'expense', 'needs', 'bolt', 1, 2),
('cat_other_fixed', 'Other Fixed', 'expense', 'needs', 'receipt', 1, 3),
('cat_food', 'Food & Dining', 'expense', 'needs', 'restaurant', 1, 4),
('cat_transport', 'Transport', 'expense', 'needs', 'directions_car', 1, 5),
('cat_health', 'Health & Wellness', 'expense', 'needs', 'medical_services', 1, 6);

-- System default categories (Wants)
INSERT INTO categories (id, name, type, budget_type, icon, is_system, sort_order) VALUES
('cat_shopping', 'Shopping', 'expense', 'wants', 'shopping_bag', 1, 7),
('cat_entertainment', 'Entertainment', 'expense', 'wants', 'movie', 1, 8),
('cat_other_variable', 'Other', 'expense', 'wants', 'more_horiz', 1, 9);

-- System default categories (Savings)
INSERT INTO categories (id, name, type, budget_type, icon, is_system, sort_order) VALUES
('cat_emergency_fund', 'Emergency Fund', 'expense', 'savings', 'lock', 1, 10),
('cat_goal', 'Goal Savings', 'expense', 'savings', 'flag', 1, 11);

-- Income categories
INSERT INTO categories (id, name, type, icon, is_system, sort_order) VALUES
('cat_salary', 'Salary', 'income', 'payments', 1, 1),
('cat_bonus', 'Bonus', 'income', 'card_giftcard', 1, 2),
('cat_investment_returns', 'Investment Returns', 'income', 'trending_up', 1, 3),
('cat_other_income', 'Other Income', 'income', 'attach_money', 1, 4);
```

| Column | Type | Description |
|--------|------|-------------|
| parent_id | TEXT | For hierarchical categories |
| type | TEXT | expense, income, transfer |
| budget_type | TEXT | needs, wants, savings (for 50-30-20) |
| is_system | INTEGER | 1=default category, can't delete |

---

## 4. Transaction Tables

### 4.1 expenses

All financial transactions (expenses, income, transfers).

```sql
CREATE TABLE expenses (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL,
    account_id          TEXT NOT NULL,
    category_id         TEXT NOT NULL,
    goal_id             TEXT,               -- If savings to specific goal
    debt_id             TEXT,               -- If debt payment

    amount              INTEGER NOT NULL,   -- in paise (positive value)
    type                TEXT NOT NULL,      -- 'expense', 'income', 'transfer'

    date                TEXT NOT NULL,      -- YYYY-MM-DD
    time                TEXT,               -- HH:MM:SS (optional)

    note                TEXT,
    payee               TEXT,               -- Merchant/person name

    -- For recurring transactions
    is_recurring        INTEGER NOT NULL DEFAULT 0,
    recurring_id        TEXT,               -- Links to recurring_transactions

    -- For SMS auto-import
    source              TEXT NOT NULL DEFAULT 'manual',  -- 'manual', 'sms', 'import'
    sms_hash            TEXT,               -- To prevent duplicate SMS imports

    -- For splits/shared expenses
    is_split            INTEGER NOT NULL DEFAULT 0,
    split_group_id      TEXT,

    -- Location (optional)
    latitude            REAL,
    longitude           REAL,
    location_name       TEXT,

    -- Attachments
    receipt_path        TEXT,

    -- Audit
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at          TEXT,
    metadata            TEXT,               -- JSON for extensibility

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE SET NULL,
    FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE SET NULL,
    FOREIGN KEY (recurring_id) REFERENCES recurring_transactions(id) ON DELETE SET NULL
);
```

| Column | Type | Description |
|--------|------|-------------|
| amount | INTEGER | Amount in paise (always positive) |
| type | TEXT | expense, income, transfer |
| date | TEXT | ISO date YYYY-MM-DD |
| goal_id | TEXT | If this is a savings contribution to a goal |
| debt_id | TEXT | If this is a debt payment |
| source | TEXT | How this was created (manual, sms, import) |
| sms_hash | TEXT | Hash of SMS content to prevent duplicates |

---

### 4.2 goals

Savings goals with timeline tracking.

```sql
CREATE TABLE goals (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL,

    name                TEXT NOT NULL,
    description         TEXT,

    target_amount       INTEGER NOT NULL,   -- in paise
    current_amount      INTEGER NOT NULL DEFAULT 0,  -- in paise

    target_date         TEXT NOT NULL,      -- YYYY-MM-DD

    -- Savings instrument
    instrument          TEXT NOT NULL,      -- 'savings_account', 'mutual_fund', etc.
    instrument_details  TEXT,               -- JSON: account number, fund name, etc.

    -- Visual
    icon                TEXT NOT NULL DEFAULT 'flag',
    color               TEXT NOT NULL DEFAULT '#000000',
    image_path          TEXT,               -- Custom goal image

    -- Status
    status              TEXT NOT NULL DEFAULT 'active',  -- 'active', 'completed', 'paused', 'cancelled'
    completed_at        TEXT,

    -- Priority
    priority            INTEGER NOT NULL DEFAULT 0,  -- Higher = more important

    -- Reminders
    has_reminder        INTEGER NOT NULL DEFAULT 0,
    reminder_day        INTEGER,            -- Day of month (1-28)

    -- Audit
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at          TEXT,
    metadata            TEXT,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

| Column | Type | Description |
|--------|------|-------------|
| target_amount | INTEGER | Goal target in paise |
| current_amount | INTEGER | Amount saved so far |
| instrument | TEXT | savings_account, fixed_deposit, mutual_fund, etc. |
| status | TEXT | active, completed, paused, cancelled |
| priority | INTEGER | For sorting (higher = more important) |

---

### 4.3 goal_transactions

Tracks all contributions to goals (linked to expenses).

```sql
CREATE TABLE goal_transactions (
    id              TEXT PRIMARY KEY,
    goal_id         TEXT NOT NULL,
    expense_id      TEXT,               -- NULL if manual adjustment

    amount          INTEGER NOT NULL,   -- in paise (positive=add, negative=withdraw)
    type            TEXT NOT NULL,      -- 'contribution', 'withdrawal', 'adjustment', 'interest'

    date            TEXT NOT NULL,
    note            TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);

-- Trigger to update goal.current_amount
CREATE TRIGGER update_goal_amount_after_insert
AFTER INSERT ON goal_transactions
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
```

---

### 4.4 emergency_fund

Emergency fund tracking (separate from goals).

```sql
CREATE TABLE emergency_fund (
    id                      TEXT PRIMARY KEY,
    user_id                 TEXT NOT NULL UNIQUE,  -- One per user

    current_amount          INTEGER NOT NULL DEFAULT 0,  -- in paise
    target_months           INTEGER NOT NULL DEFAULT 6,  -- Target runway

    -- Calculated from user's budget settings
    monthly_essentials      INTEGER NOT NULL DEFAULT 0,  -- in paise

    -- Where the money is kept
    instrument              TEXT NOT NULL DEFAULT 'savings_account',
    instrument_details      TEXT,

    created_at              TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at              TEXT NOT NULL DEFAULT (datetime('now')),
    metadata                TEXT,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Computed columns (handled in app logic):
-- target_amount = monthly_essentials * target_months
-- runway_months = current_amount / monthly_essentials
-- progress = (current_amount / target_amount) * 100
```

---

### 4.5 emergency_fund_transactions

```sql
CREATE TABLE emergency_fund_transactions (
    id              TEXT PRIMARY KEY,
    fund_id         TEXT NOT NULL,
    expense_id      TEXT,

    amount          INTEGER NOT NULL,   -- positive=add, negative=withdraw
    type            TEXT NOT NULL,      -- 'contribution', 'withdrawal', 'interest'

    date            TEXT NOT NULL,
    note            TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (fund_id) REFERENCES emergency_fund(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);

-- Trigger to update fund amount
CREATE TRIGGER update_emergency_fund_after_insert
AFTER INSERT ON emergency_fund_transactions
BEGIN
    UPDATE emergency_fund
    SET current_amount = current_amount + NEW.amount,
        updated_at = datetime('now')
    WHERE id = NEW.fund_id;
END;
```

---

## 5. Settings Tables

### 5.1 user_settings

All user preferences in key-value format.

```sql
CREATE TABLE user_settings (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    key             TEXT NOT NULL,
    value           TEXT NOT NULL,      -- JSON encoded
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, key)
);

-- Default settings
INSERT INTO user_settings (id, user_id, key, value) VALUES
('setting_1', 'default', 'monthly_income', '0'),
('setting_2', 'default', 'fixed_expenses', '{"rent": 0, "utilities": 0, "other": 0}'),
('setting_3', 'default', 'budget_rule', '"50-30-20"'),
('setting_4', 'default', 'needs_percentage', '50'),
('setting_5', 'default', 'wants_percentage', '30'),
('setting_6', 'default', 'savings_percentage', '20'),
('setting_7', 'default', 'cycle_type', '"calendar_month"'),
('setting_8', 'default', 'cycle_start_day', '1'),
('setting_9', 'default', 'theme_mode', '"system"'),
('setting_10', 'default', 'notifications_enabled', 'true'),
('setting_11', 'default', 'sms_parsing_enabled', 'false'),
('setting_12', 'default', 'biometric_lock', 'false');
```

| Key | Value Type | Description |
|-----|------------|-------------|
| monthly_income | INTEGER | Monthly take-home in paise |
| fixed_expenses | JSON | {rent, utilities, other} in paise |
| budget_rule | STRING | "50-30-20" or custom |
| needs_percentage | INTEGER | 0-100 |
| wants_percentage | INTEGER | 0-100 |
| savings_percentage | INTEGER | 0-100 |
| cycle_type | STRING | "calendar_month" or "custom_day" |
| cycle_start_day | INTEGER | 1-28 |
| theme_mode | STRING | "light", "dark", "system" |

---

### 5.2 budget_cycles

Track each budget cycle period.

```sql
CREATE TABLE budget_cycles (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL,

    start_date          TEXT NOT NULL,      -- YYYY-MM-DD
    end_date            TEXT NOT NULL,      -- YYYY-MM-DD

    -- Budget amounts for this cycle (in paise)
    total_budget        INTEGER NOT NULL,
    needs_budget        INTEGER NOT NULL,
    wants_budget        INTEGER NOT NULL,
    savings_budget      INTEGER NOT NULL,

    -- Actual spending (updated via triggers or app logic)
    total_spent         INTEGER NOT NULL DEFAULT 0,
    needs_spent         INTEGER NOT NULL DEFAULT 0,
    wants_spent         INTEGER NOT NULL DEFAULT 0,
    savings_spent       INTEGER NOT NULL DEFAULT 0,

    status              TEXT NOT NULL DEFAULT 'active',  -- 'active', 'completed'

    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

### 5.3 category_budgets

Per-category budget limits (optional, for detailed budgeting).

```sql
CREATE TABLE category_budgets (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    category_id     TEXT NOT NULL,

    amount          INTEGER NOT NULL,   -- Monthly budget in paise
    period_type     TEXT NOT NULL DEFAULT 'monthly',  -- 'weekly', 'monthly', 'yearly'

    alert_threshold INTEGER NOT NULL DEFAULT 80,  -- Alert at 80% spent

    is_active       INTEGER NOT NULL DEFAULT 1,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    UNIQUE(user_id, category_id)
);
```

---

## 6. Financial Plan Tables

### 6.1 debts

Debt tracking with priority system.

```sql
CREATE TABLE debts (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL,

    name                TEXT NOT NULL,
    description         TEXT,
    lender              TEXT,               -- Bank/person name

    total_amount        INTEGER NOT NULL,   -- Original debt in paise
    remaining_amount    INTEGER NOT NULL,   -- Current balance in paise

    interest_rate       REAL NOT NULL,      -- Annual percentage (15.5 = 15.5%)
    interest_type       TEXT NOT NULL DEFAULT 'fixed',  -- 'fixed', 'variable'

    minimum_payment     INTEGER NOT NULL DEFAULT 0,  -- Monthly minimum in paise

    start_date          TEXT NOT NULL,      -- When debt was taken
    due_date            TEXT,               -- When it should be paid off

    -- Priority (calculated from interest_rate, can be overridden)
    priority            TEXT NOT NULL,      -- 'high', 'medium', 'low'
    priority_override   INTEGER NOT NULL DEFAULT 0,  -- User manually set priority

    -- Status
    status              TEXT NOT NULL DEFAULT 'active',  -- 'active', 'paid_off'
    paid_off_at         TEXT,

    -- Account linked (optional)
    account_id          TEXT,               -- Credit card account, etc.

    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at          TEXT,
    metadata            TEXT,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL
);

-- Priority calculation helper view
CREATE VIEW debt_priorities AS
SELECT
    id,
    name,
    interest_rate,
    CASE
        WHEN priority_override = 1 THEN priority
        WHEN interest_rate > 15 THEN 'high'
        WHEN interest_rate >= 8 THEN 'medium'
        ELSE 'low'
    END as calculated_priority
FROM debts
WHERE deleted_at IS NULL AND status = 'active';
```

---

### 6.2 debt_payments

Track all debt payments.

```sql
CREATE TABLE debt_payments (
    id              TEXT PRIMARY KEY,
    debt_id         TEXT NOT NULL,
    expense_id      TEXT,

    amount          INTEGER NOT NULL,   -- Payment amount in paise
    principal       INTEGER NOT NULL,   -- Principal portion
    interest        INTEGER NOT NULL,   -- Interest portion

    date            TEXT NOT NULL,
    note            TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE SET NULL
);

-- Trigger to update debt remaining amount
CREATE TRIGGER update_debt_after_payment
AFTER INSERT ON debt_payments
BEGIN
    UPDATE debts
    SET remaining_amount = remaining_amount - NEW.principal,
        updated_at = datetime('now'),
        status = CASE
            WHEN remaining_amount - NEW.principal <= 0 THEN 'paid_off'
            ELSE status
        END,
        paid_off_at = CASE
            WHEN remaining_amount - NEW.principal <= 0 THEN datetime('now')
            ELSE paid_off_at
        END
    WHERE id = NEW.debt_id;
END;
```

---

### 6.3 financial_plan_progress

Track user progress through 10-step financial plan.

```sql
CREATE TABLE financial_plan_progress (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,

    step            TEXT NOT NULL,      -- 'income', 'budget_rule', 'needs', etc.
    status          TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'in_progress', 'completed'

    completed_at    TEXT,
    notes           TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, step)
);

-- Initialize all steps for a user
INSERT INTO financial_plan_progress (id, user_id, step, status) VALUES
('plan_1', 'default', 'income', 'pending'),
('plan_2', 'default', 'budget_rule', 'pending'),
('plan_3', 'default', 'needs', 'pending'),
('plan_4', 'default', 'wants', 'pending'),
('plan_5', 'default', 'goals', 'pending'),
('plan_6', 'default', 'emergency_fund', 'pending'),
('plan_7', 'default', 'debt', 'pending'),
('plan_8', 'default', 'savings', 'pending'),
('plan_9', 'default', 'automate', 'pending'),
('plan_10', 'default', 'review', 'pending');
```

---

## 7. Analytics & History Tables

### 7.1 daily_summaries

Pre-aggregated daily data for fast analytics.

```sql
CREATE TABLE daily_summaries (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    date            TEXT NOT NULL,      -- YYYY-MM-DD

    total_income    INTEGER NOT NULL DEFAULT 0,
    total_expense   INTEGER NOT NULL DEFAULT 0,

    needs_spent     INTEGER NOT NULL DEFAULT 0,
    wants_spent     INTEGER NOT NULL DEFAULT 0,
    savings_spent   INTEGER NOT NULL DEFAULT 0,

    transaction_count INTEGER NOT NULL DEFAULT 0,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, date)
);
```

---

### 7.2 monthly_summaries

Pre-aggregated monthly data.

```sql
CREATE TABLE monthly_summaries (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    year            INTEGER NOT NULL,
    month           INTEGER NOT NULL,   -- 1-12

    total_income    INTEGER NOT NULL DEFAULT 0,
    total_expense   INTEGER NOT NULL DEFAULT 0,
    total_savings   INTEGER NOT NULL DEFAULT 0,

    needs_budget    INTEGER NOT NULL DEFAULT 0,
    needs_spent     INTEGER NOT NULL DEFAULT 0,

    wants_budget    INTEGER NOT NULL DEFAULT 0,
    wants_spent     INTEGER NOT NULL DEFAULT 0,

    savings_budget  INTEGER NOT NULL DEFAULT 0,
    savings_spent   INTEGER NOT NULL DEFAULT 0,

    -- Goals
    goals_contributed INTEGER NOT NULL DEFAULT 0,
    emergency_contributed INTEGER NOT NULL DEFAULT 0,

    -- Debt
    debt_paid       INTEGER NOT NULL DEFAULT 0,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, year, month)
);
```

---

### 7.3 category_summaries

Per-category monthly spending.

```sql
CREATE TABLE category_summaries (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    category_id     TEXT NOT NULL,
    year            INTEGER NOT NULL,
    month           INTEGER NOT NULL,

    total_amount    INTEGER NOT NULL DEFAULT 0,
    transaction_count INTEGER NOT NULL DEFAULT 0,

    budget_amount   INTEGER,            -- NULL if no budget set

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    UNIQUE(user_id, category_id, year, month)
);
```

---

## 8. Future-Ready Tables

### 8.1 recurring_transactions

For auto-logging recurring expenses/income.

```sql
CREATE TABLE recurring_transactions (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL,

    name                TEXT NOT NULL,
    amount              INTEGER NOT NULL,
    type                TEXT NOT NULL,      -- 'expense', 'income'

    account_id          TEXT NOT NULL,
    category_id         TEXT NOT NULL,

    -- Recurrence pattern
    frequency           TEXT NOT NULL,      -- 'daily', 'weekly', 'monthly', 'yearly'
    interval            INTEGER NOT NULL DEFAULT 1,  -- Every X days/weeks/months
    day_of_week         INTEGER,            -- 0-6 for weekly
    day_of_month        INTEGER,            -- 1-28 for monthly

    -- Duration
    start_date          TEXT NOT NULL,
    end_date            TEXT,               -- NULL = indefinite

    -- Tracking
    last_generated      TEXT,               -- Last date transaction was auto-created
    next_due            TEXT,               -- Next expected date

    is_active           INTEGER NOT NULL DEFAULT 1,

    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at          TEXT,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
);
```

---

### 8.2 sms_patterns

For SMS auto-parsing (Android only).

```sql
CREATE TABLE sms_patterns (
    id              TEXT PRIMARY KEY,

    bank_name       TEXT NOT NULL,
    sender_pattern  TEXT NOT NULL,      -- Regex for sender (e.g., 'HDFCBK', 'SBIINB')
    message_pattern TEXT NOT NULL,      -- Regex to extract amount, type, merchant

    is_active       INTEGER NOT NULL DEFAULT 1,
    priority        INTEGER NOT NULL DEFAULT 0,  -- Higher = check first

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Example patterns for Indian banks
INSERT INTO sms_patterns (id, bank_name, sender_pattern, message_pattern, priority) VALUES
('sms_hdfc', 'HDFC Bank', 'HDFCBK|HDFCBN', 'Rs\.?(\d+(?:\.\d{2})?).*(?:debited|credited)', 10),
('sms_sbi', 'SBI', 'SBIINB|SBIPSG', 'Rs\.?(\d+(?:\.\d{2})?).*(?:debited|credited)', 10),
('sms_icici', 'ICICI Bank', 'ICICIB', 'Rs\.?(\d+(?:\.\d{2})?).*(?:debited|credited)', 10),
('sms_axis', 'Axis Bank', 'AXISBK', 'Rs\.?(\d+(?:\.\d{2})?).*(?:debited|credited)', 10);
```

---

### 8.3 notifications

For reminders and alerts.

```sql
CREATE TABLE notifications (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,

    type            TEXT NOT NULL,      -- 'reminder', 'alert', 'insight', 'goal_reached'
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,

    -- Related entity
    entity_type     TEXT,               -- 'goal', 'debt', 'budget', 'expense'
    entity_id       TEXT,

    -- Scheduling
    scheduled_at    TEXT,
    sent_at         TEXT,

    -- Status
    is_read         INTEGER NOT NULL DEFAULT 0,
    read_at         TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

### 8.4 tags

User-defined tags for transactions.

```sql
CREATE TABLE tags (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    name            TEXT NOT NULL,
    color           TEXT NOT NULL DEFAULT '#757575',

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, name)
);

CREATE TABLE expense_tags (
    expense_id      TEXT NOT NULL,
    tag_id          TEXT NOT NULL,

    PRIMARY KEY (expense_id, tag_id),
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
```

---

### 8.5 attachments

For receipt images and documents.

```sql
CREATE TABLE attachments (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,

    entity_type     TEXT NOT NULL,      -- 'expense', 'goal', 'debt'
    entity_id       TEXT NOT NULL,

    file_path       TEXT NOT NULL,      -- Local path
    file_name       TEXT NOT NULL,
    file_type       TEXT NOT NULL,      -- 'image/jpeg', 'application/pdf'
    file_size       INTEGER NOT NULL,   -- bytes

    thumbnail_path  TEXT,

    created_at      TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## 9. Indexes

Strategic indexes for common query patterns.

```sql
-- Expenses (most queried table)
CREATE INDEX idx_expenses_user_date ON expenses(user_id, date);
CREATE INDEX idx_expenses_user_category ON expenses(user_id, category_id);
CREATE INDEX idx_expenses_user_date_type ON expenses(user_id, date, type);
CREATE INDEX idx_expenses_user_account ON expenses(user_id, account_id);
CREATE INDEX idx_expenses_deleted ON expenses(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_recurring ON expenses(recurring_id) WHERE recurring_id IS NOT NULL;
CREATE INDEX idx_expenses_sms_hash ON expenses(sms_hash) WHERE sms_hash IS NOT NULL;

-- Goals
CREATE INDEX idx_goals_user_status ON goals(user_id, status);
CREATE INDEX idx_goals_user_target_date ON goals(user_id, target_date);

-- Goal transactions
CREATE INDEX idx_goal_transactions_goal ON goal_transactions(goal_id);
CREATE INDEX idx_goal_transactions_date ON goal_transactions(date);

-- Debts
CREATE INDEX idx_debts_user_status ON debts(user_id, status);
CREATE INDEX idx_debts_priority ON debts(priority) WHERE status = 'active';

-- Categories
CREATE INDEX idx_categories_type ON categories(type);
CREATE INDEX idx_categories_budget_type ON categories(budget_type);

-- Budget cycles
CREATE INDEX idx_budget_cycles_user_dates ON budget_cycles(user_id, start_date, end_date);
CREATE INDEX idx_budget_cycles_active ON budget_cycles(user_id, status) WHERE status = 'active';

-- Daily summaries
CREATE INDEX idx_daily_summaries_user_date ON daily_summaries(user_id, date);

-- Monthly summaries
CREATE INDEX idx_monthly_summaries_user_period ON monthly_summaries(user_id, year, month);

-- Recurring transactions
CREATE INDEX idx_recurring_next_due ON recurring_transactions(next_due) WHERE is_active = 1;

-- Notifications
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = 0;
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_at) WHERE sent_at IS NULL;
```

---

## 10. Migrations Strategy

### 10.1 Version Table

```sql
CREATE TABLE schema_migrations (
    version         INTEGER PRIMARY KEY,
    name            TEXT NOT NULL,
    applied_at      TEXT NOT NULL DEFAULT (datetime('now'))
);
```

### 10.2 Migration Pattern

```dart
// lib/core/database/migrations/migration_v1.dart
class MigrationV1 implements Migration {
  @override
  int get version => 1;

  @override
  String get name => 'initial_schema';

  @override
  Future<void> up(Database db) async {
    // Create tables
  }

  @override
  Future<void> down(Database db) async {
    // Drop tables (for rollback)
  }
}
```

### 10.3 Migration Checklist

When adding new features:

- [ ] Create new migration file with incremented version
- [ ] Add new tables/columns in `up()` method
- [ ] Add rollback logic in `down()` method
- [ ] Test migration on existing data
- [ ] Update DATABASE.md with new schema
- [ ] Update APP_OVERVIEW.md

---

## 11. Data Validation Rules

### 11.1 Constraints

| Table | Column | Rule |
|-------|--------|------|
| expenses | amount | Must be > 0 |
| expenses | date | Must be valid ISO date |
| goals | target_amount | Must be > 0 |
| goals | target_date | Must be in future |
| debts | interest_rate | Must be >= 0 and <= 100 |
| user_settings | needs + wants + savings | Must equal 100 |
| budget_cycles | end_date | Must be > start_date |

### 11.2 Application-Level Validation

```dart
// lib/core/validators/expense_validator.dart
class ExpenseValidator {
  static ValidationResult validate(Expense expense) {
    final errors = <String>[];

    if (expense.amount <= 0) {
      errors.add('Amount must be greater than 0');
    }

    if (expense.date.isAfter(DateTime.now().add(Duration(days: 1)))) {
      errors.add('Cannot add expense for future dates');
    }

    if (expense.category == ExpenseCategory.savings &&
        expense.goalId == null &&
        expense.savingsDestination != SavingsDestination.emergencyFund) {
      errors.add('Savings must have a destination');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
```

---

## 12. Query Patterns

### 12.1 Common Queries

**Get daily budget status:**
```sql
SELECT
    bc.total_budget,
    bc.total_spent,
    (bc.total_budget - bc.total_spent) as remaining,
    (julianday(bc.end_date) - julianday('now') + 1) as days_left,
    CASE
        WHEN days_left > 0 THEN (bc.total_budget - bc.total_spent) / days_left
        ELSE 0
    END as daily_allowance
FROM budget_cycles bc
WHERE bc.user_id = ?
AND bc.status = 'active'
AND date('now') BETWEEN bc.start_date AND bc.end_date;
```

**Get expenses for date range with category:**
```sql
SELECT
    e.*,
    c.name as category_name,
    c.budget_type
FROM expenses e
JOIN categories c ON e.category_id = c.id
WHERE e.user_id = ?
AND e.date BETWEEN ? AND ?
AND e.deleted_at IS NULL
ORDER BY e.date DESC, e.created_at DESC;
```

**Get goal progress:**
```sql
SELECT
    g.*,
    (g.current_amount * 100.0 / g.target_amount) as progress_percent,
    (g.target_amount - g.current_amount) as remaining,
    CASE
        WHEN julianday(g.target_date) > julianday('now')
        THEN (g.target_amount - g.current_amount) /
             ((julianday(g.target_date) - julianday('now')) / 30.0)
        ELSE g.target_amount - g.current_amount
    END as monthly_needed
FROM goals g
WHERE g.user_id = ?
AND g.status = 'active'
AND g.deleted_at IS NULL
ORDER BY g.priority DESC, g.target_date ASC;
```

**Get 50-30-20 breakdown for current cycle:**
```sql
SELECT
    c.budget_type,
    SUM(e.amount) as total_spent,
    bc.needs_budget as needs_budget,
    bc.wants_budget as wants_budget,
    bc.savings_budget as savings_budget
FROM expenses e
JOIN categories c ON e.category_id = c.id
JOIN budget_cycles bc ON e.user_id = bc.user_id
    AND e.date BETWEEN bc.start_date AND bc.end_date
WHERE e.user_id = ?
AND bc.status = 'active'
AND e.type = 'expense'
AND e.deleted_at IS NULL
GROUP BY c.budget_type;
```

---

## 13. Backup & Recovery

### 13.1 Backup Strategy

```dart
// lib/core/services/backup_service.dart
class BackupService {
  // Export all data to JSON
  Future<String> exportToJson() async {
    final data = {
      'version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'users': await _exportTable('users'),
      'accounts': await _exportTable('accounts'),
      'categories': await _exportTable('categories'),
      'expenses': await _exportTable('expenses'),
      'goals': await _exportTable('goals'),
      'debts': await _exportTable('debts'),
      // ... all tables
    };
    return jsonEncode(data);
  }

  // Import from JSON backup
  Future<void> importFromJson(String json) async {
    final data = jsonDecode(json);
    // Validate version compatibility
    // Import in correct order (respecting foreign keys)
  }
}
```

### 13.2 Data Recovery

```sql
-- Recover soft-deleted expenses from last 30 days
UPDATE expenses
SET deleted_at = NULL
WHERE deleted_at > datetime('now', '-30 days');

-- Recalculate goal amounts from transactions
UPDATE goals
SET current_amount = (
    SELECT COALESCE(SUM(amount), 0)
    FROM goal_transactions
    WHERE goal_id = goals.id
);

-- Recalculate emergency fund from transactions
UPDATE emergency_fund
SET current_amount = (
    SELECT COALESCE(SUM(amount), 0)
    FROM emergency_fund_transactions
    WHERE fund_id = emergency_fund.id
);
```

---

## Appendix A: Quick Reference

### Tables Overview

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| users | User profiles | id, name, currency_code |
| accounts | Bank/wallet accounts | id, user_id, type, balance |
| categories | Expense categories | id, name, type, budget_type |
| expenses | All transactions | id, amount, category_id, date |
| goals | Savings goals | id, target_amount, current_amount |
| goal_transactions | Goal contributions | id, goal_id, amount |
| emergency_fund | Safety net | id, current_amount, target_months |
| debts | Debt tracking | id, remaining_amount, interest_rate |
| user_settings | Preferences | user_id, key, value |
| budget_cycles | Budget periods | start_date, end_date, budgets |

### Amount Conversion

```dart
// To database (display → storage)
int toPaise(double amount) => (amount * 100).round();

// From database (storage → display)
double fromPaise(int paise) => paise / 100.0;
```

### Common Types

```dart
enum ExpenseType { expense, income, transfer }
enum BudgetType { needs, wants, savings }
enum GoalStatus { active, completed, paused, cancelled }
enum DebtPriority { high, medium, low }
enum CycleType { calendarMonth, customDay }
```

---

## Appendix B: Schema Version History

| Version | Date | Changes |
|---------|------|---------|
| 1 | Jan 2026 | Initial schema |

---

*This document must be updated whenever database schema changes are made.*
