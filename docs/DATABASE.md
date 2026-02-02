# FinanceSensei - Database Documentation

## Overview

Local SQLite database for offline-first data storage.

**Database file:** `financesensei.db`

---

## Tables

### needs_categories

Stores budget categories for essential expenses (Needs).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL | Category name (e.g., "Rent", "Groceries") |
| amount | INTEGER | DEFAULT 0 | Budget amount in smallest currency unit |
| icon | TEXT | NOT NULL | Icon identifier (e.g., "home_outlined") |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Example:**
```sql
INSERT INTO needs_categories (name, amount, icon, created_at)
VALUES ('Rent', 8000, 'home_outlined', '2025-01-31T10:00:00.000Z');
```

---

### needs_templates

Stores template definitions for recurring expense patterns.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL | Template name (e.g., "Monthly Essentials") |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

---

### needs_template_items

Stores individual items within a template.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| template_id | INTEGER | NOT NULL, FK | Reference to needs_templates |
| name | TEXT | NOT NULL | Item name (e.g., "Rent") |
| amount | INTEGER | DEFAULT 0 | Item amount |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Key:** `template_id` → `needs_templates(id)` ON DELETE CASCADE

---

## Icon Reference

Available icons for categories:

| Icon Name | Display | Use Case |
|-----------|---------|----------|
| home_outlined | 🏠 | Rent, Mortgage |
| shopping_cart_outlined | 🛒 | Groceries |
| bolt_outlined | ⚡ | Utilities, Electricity |
| security_outlined | 🛡️ | Insurance |
| directions_car_outlined | 🚗 | Transport, Car |
| medical_services_outlined | 🏥 | Healthcare |
| school_outlined | 🎓 | Education |
| phone_outlined | 📱 | Phone, Mobile |
| savings_outlined | 🐷 | Buffer, Savings |
| category_outlined | 📁 | Default/Other |

---

## Migrations

### Version 1 (Initial)

```sql
CREATE TABLE needs_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount INTEGER DEFAULT 0,
  icon TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

### Version 3 (Templates)

```sql
CREATE TABLE needs_templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE needs_template_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  template_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  amount INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  FOREIGN KEY (template_id) REFERENCES needs_templates (id) ON DELETE CASCADE
);
```

---

## Repository Methods

### NeedsRepository

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all categories ordered by created_at |
| `getById(int id)` | Returns single category by ID |
| `insert(NeedsCategory)` | Creates new category, returns ID |
| `update(NeedsCategory)` | Updates existing category |
| `delete(int id)` | Deletes category by ID |

### NeedsTemplateRepository

**Template Methods:**

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all templates with their items |
| `getById(int id)` | Returns single template with items |
| `insert(NeedsTemplate)` | Creates new template, returns ID |
| `update(NeedsTemplate)` | Updates template name |
| `delete(int id)` | Deletes template and all items (CASCADE) |

**Item Methods:**

| Method | Description |
|--------|-------------|
| `getItemsByTemplateId(int)` | Returns all items for a template |
| `insertItem(NeedsTemplateItem)` | Adds single item |
| `updateItem(NeedsTemplateItem)` | Updates single item |
| `deleteItem(int id)` | Deletes single item |
| `insertItems(int, List)` | Batch insert items |
| `deleteAllItems(int)` | Deletes all items for template |
| `replaceItems(int, List)` | Replaces all items (delete + insert) |

---

## Wants Tables

### wants_categories

Stores budget categories for lifestyle expenses (Wants).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL | Category name (e.g., "Dining Out", "Entertainment") |
| amount | INTEGER | DEFAULT 0 | Budget amount in smallest currency unit |
| icon | TEXT | NOT NULL | Icon identifier (e.g., "restaurant_outlined") |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Example:**
```sql
INSERT INTO wants_categories (name, amount, icon, created_at)
VALUES ('Dining Out', 2000, 'restaurant_outlined', '2025-01-31T10:00:00.000Z');
```

---

### wants_templates

Stores template definitions for recurring wants expense patterns.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL | Template name (e.g., "Monthly Fun") |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

---

### wants_template_items

Stores individual items within a wants template.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| template_id | INTEGER | NOT NULL, FK | Reference to wants_templates |
| name | TEXT | NOT NULL | Item name (e.g., "Dining Out") |
| amount | INTEGER | DEFAULT 0 | Item amount |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Key:** `template_id` → `wants_templates(id)` ON DELETE CASCADE

---

## Wants Icon Reference

Available icons for wants categories:

| Icon Name | Display | Use Case |
|-----------|---------|----------|
| restaurant_outlined | 🍽️ | Dining Out |
| movie_outlined | 🎬 | Entertainment, Movies |
| shopping_bag_outlined | 🛍️ | Shopping |
| subscriptions_outlined | 📺 | Subscriptions |
| spa_outlined | 💆 | Personal Care |
| palette_outlined | 🎨 | Hobbies |
| sports_esports_outlined | 🎮 | Gaming |
| flight_outlined | ✈️ | Travel |
| local_gas_station_outlined | ⛽ | Petrol, Fuel |
| breakfast_dining_outlined | 🥣 | Oats, Breakfast |
| medication_outlined | 💊 | Supplements |
| set_meal_outlined | 🍗 | Chicken, Meat |
| fitness_center_outlined | 🏋️ | Protein Powder, Gym |
| eco_outlined | 🥬 | Veggies, Vegetables |
| savings_outlined | 🐷 | Buffer, Savings |
| category_outlined | 📁 | Default/Other |

---

## Wants Repository Methods

### WantsRepository

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all categories ordered by created_at |
| `getById(int id)` | Returns single category by ID |
| `insert(WantsCategory)` | Creates new category, returns ID |
| `update(WantsCategory)` | Updates existing category |
| `delete(int id)` | Deletes category by ID |

### WantsTemplateRepository

**Template Methods:**

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all templates with their items |
| `getById(int id)` | Returns single template with items |
| `insert(WantsTemplate)` | Creates new template, returns ID |
| `update(WantsTemplate)` | Updates template name |
| `delete(int id)` | Deletes template and all items (CASCADE) |

**Item Methods:**

| Method | Description |
|--------|-------------|
| `getItemsByTemplateId(int)` | Returns all items for a template |
| `insertItem(WantsTemplateItem)` | Adds single item |
| `updateItem(WantsTemplateItem)` | Updates single item |
| `deleteItem(int id)` | Deletes single item |
| `insertItems(int, List)` | Batch insert items |
| `deleteAllItems(int)` | Deletes all items for template |
| `replaceItems(int, List)` | Replaces all items (delete + insert) |

---

## Savings Tables

### savings_goals

Stores savings goals with progress tracking.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL | Goal name (e.g., "Emergency Fund") |
| target | INTEGER | DEFAULT 0 | Target amount to save |
| saved | INTEGER | DEFAULT 0 | Amount saved so far |
| monthly | INTEGER | DEFAULT 0 | Monthly contribution amount |
| target_date | TEXT | NOT NULL | ISO 8601 target date |
| icon | TEXT | NOT NULL | Icon identifier |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Example:**
```sql
INSERT INTO savings_goals (name, target, saved, monthly, target_date, icon, created_at)
VALUES ('Emergency Fund', 50000, 10000, 5000, '2025-12-31T00:00:00.000Z', 'shield_outlined', '2025-01-31T10:00:00.000Z');
```

---

## Savings Icon Reference

Available icons for savings goals:

| Icon Name | Display | Use Case |
|-----------|---------|----------|
| shield_outlined | 🛡️ | Emergency Fund |
| flight_outlined | ✈️ | Travel, Vacation |
| trending_up_outlined | 📈 | Investments, Retirement |
| directions_car_outlined | 🚗 | Car, Vehicle |
| home_outlined | 🏠 | Home, Down Payment |
| school_outlined | 🎓 | Education |
| phone_iphone_outlined | 📱 | Gadgets, Electronics |
| celebration_outlined | 🎉 | Events, Wedding |
| medical_services_outlined | 🏥 | Medical, Health |
| shopping_bag_outlined | 🛍️ | Large Purchase |
| savings_outlined | 🐷 | Default/Other |

---

## Savings Repository Methods

### SavingsRepository

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all goals ordered by created_at |
| `getById(int id)` | Returns single goal by ID |
| `insert(SavingsGoal)` | Creates new goal, returns ID |
| `update(SavingsGoal)` | Updates existing goal |
| `delete(int id)` | Deletes goal by ID |
| `addMoney(int id, int amount)` | Adds amount to goal's saved value |
| `getTotalSaved()` | Returns sum of all saved amounts |

---

## Migrations

### Version 5 (Savings)

```sql
CREATE TABLE savings_goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  target INTEGER DEFAULT 0,
  saved INTEGER DEFAULT 0,
  monthly INTEGER DEFAULT 0,
  target_date TEXT NOT NULL,
  icon TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

### Version 4 (Wants)

```sql
CREATE TABLE wants_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount INTEGER DEFAULT 0,
  icon TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE wants_templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE wants_template_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  template_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  amount INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  FOREIGN KEY (template_id) REFERENCES wants_templates (id) ON DELETE CASCADE
);
```

---

## Expenses Tables

### expenses

Stores all expense and income transactions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| amount | INTEGER | NOT NULL | Amount in smallest currency unit (paise) |
| type | TEXT | NOT NULL | Type: 'needs', 'wants', 'savings', or 'income' |
| category_id | INTEGER | NULLABLE | Reference to category table (based on type) |
| category_name | TEXT | NOT NULL | Category name for display |
| note | TEXT | NULLABLE | Optional note for the transaction |
| date | TEXT | NOT NULL | ISO 8601 transaction date |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Example:**
```sql
INSERT INTO expenses (amount, type, category_id, category_name, note, date, created_at)
VALUES (45000, 'needs', 1, 'Groceries', 'Weekly shopping', '2025-01-31T10:00:00.000Z', '2025-01-31T10:00:00.000Z');
```

---

## Expense Repository Methods

### ExpenseRepository

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all expenses ordered by date DESC |
| `getById(int id)` | Returns single expense by ID |
| `getByDateRange(DateTime start, DateTime end)` | Returns expenses within date range |
| `getByMonth(int year, int month)` | Returns expenses for a specific month |
| `getRecent({int limit})` | Returns most recent expenses (default 5) |
| `insert(Expense)` | Creates new expense, returns ID |
| `update(Expense)` | Updates existing expense |
| `delete(int id)` | Deletes expense by ID |
| `getTotalIncome({DateTime? start, DateTime? end})` | Returns sum of income |
| `getTotalSpent({DateTime? start, DateTime? end})` | Returns sum of expenses |
| `getSpentByType({DateTime? start, DateTime? end})` | Returns spending breakdown by type |

---

### Version 6 (Expenses)

```sql
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,
  category_id INTEGER,
  category_name TEXT NOT NULL,
  note TEXT,
  date TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

---

## Income Tables

### income_categories

Stores income sources with recurring amounts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL | Income source name (e.g., "Salary", "Freelance") |
| amount | INTEGER | DEFAULT 0 | Expected amount in rupees |
| frequency | TEXT | DEFAULT 'monthly' | Frequency: 'monthly', 'biweekly', or 'variable' |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Example:**
```sql
INSERT INTO income_categories (name, amount, frequency, created_at)
VALUES ('Salary', 50000, 'monthly', '2025-01-31T10:00:00.000Z');
```

---

## Income Repository Methods

### IncomeRepository

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all income sources ordered by created_at |
| `getById(int id)` | Returns single income source by ID |
| `insert(IncomeCategory)` | Creates new income source, returns ID |
| `update(IncomeCategory)` | Updates existing income source |
| `delete(int id)` | Deletes income source by ID |

---

### Version 8 (Income Categories)

```sql
CREATE TABLE income_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount INTEGER DEFAULT 0,
  frequency TEXT DEFAULT 'monthly',
  created_at TEXT NOT NULL
);
```

---

## Cycle History Tables

### cycle_history

Stores archived budget cycles for historical tracking and analytics.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| cycle_name | TEXT | NOT NULL | Month name (e.g., "January") |
| cycle_start | TEXT | NOT NULL | ISO 8601 cycle start date |
| cycle_end | TEXT | NOT NULL | ISO 8601 cycle end date |
| total_income | INTEGER | NOT NULL | Total income for the cycle (paise) |
| total_spent | INTEGER | NOT NULL | Total spent for the cycle (paise) |
| needs_spent | INTEGER | NOT NULL | Amount spent on needs (paise) |
| wants_spent | INTEGER | NOT NULL | Amount spent on wants (paise) |
| savings_added | INTEGER | NOT NULL | Amount added to savings (paise) |
| remaining | INTEGER | NOT NULL | Unspent/overspent amount (paise) |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Example:**
```sql
INSERT INTO cycle_history (cycle_name, cycle_start, cycle_end, total_income, total_spent, needs_spent, wants_spent, savings_added, remaining, created_at)
VALUES ('January', '2025-01-01T00:00:00.000Z', '2025-01-31T23:59:59.000Z', 5000000, 3500000, 2000000, 1000000, 500000, 1000000, '2025-02-01T00:00:00.000Z');
```

---

## Cycle Repository Methods

### CycleRepository

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all archived cycles ordered by end date DESC |
| `getById(int id)` | Returns single cycle by ID |
| `archiveCycle(CycleHistory)` | Archives a cycle to history |
| `resetBudgetCategories()` | Resets needs/wants category amounts to 0 |
| `completeCycle(...)` | Archives cycle and resets for new cycle |
| `delete(int id)` | Deletes archived cycle by ID |

---

### Version 9 (Cycle History)

```sql
CREATE TABLE cycle_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cycle_name TEXT NOT NULL,
  cycle_start TEXT NOT NULL,
  cycle_end TEXT NOT NULL,
  total_income INTEGER NOT NULL,
  total_spent INTEGER NOT NULL,
  needs_spent INTEGER NOT NULL,
  wants_spent INTEGER NOT NULL,
  savings_added INTEGER NOT NULL,
  remaining INTEGER NOT NULL,
  created_at TEXT NOT NULL
);
```

---

## Cycle Settings Table

### cycle_settings

Stores the current cycle configuration. Single row table (id=1).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY | Always 1 (single row) |
| cycle_start | TEXT | NOT NULL | ISO 8601 current cycle start date |
| cycle_end | TEXT | NOT NULL | ISO 8601 current cycle end date |
| pay_cycle_day | INTEGER | DEFAULT 1 | Day of month when pay cycle starts (1-28) |

**Note:** Cycle dates are stored and managed manually. They do NOT auto-advance based on current date. User must tap "Start New Cycle" to move to the next cycle.

---

## Cycle Settings Repository Methods

### CycleSettingsRepository

| Method | Description |
|--------|-------------|
| `get()` | Returns current settings (creates default if none) |
| `update(CycleSettings)` | Updates cycle settings |
| `updatePayCycleDay(int)` | Updates pay day and recalculates dates |
| `startNextCycle()` | Advances to next cycle dates |

---

### Version 10 (Cycle Settings)

```sql
CREATE TABLE cycle_settings (
  id INTEGER PRIMARY KEY,
  cycle_start TEXT NOT NULL,
  cycle_end TEXT NOT NULL,
  pay_cycle_day INTEGER DEFAULT 1
);
```
