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
| `withdrawMoney(int id, int amount)` | Withdraws amount from goal's saved value (clamps to 0) |
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
| type | TEXT | NOT NULL | Type: 'needs', 'wants', 'savings', 'savings_withdrawal', or 'income' |
| category_id | INTEGER | NULLABLE | Reference to category table (based on type) |
| category_name | TEXT | NOT NULL | Category name for display |
| note | TEXT | NULLABLE | Optional note for the transaction |
| payment_method | TEXT | DEFAULT 'cash' | Payment method: 'cash' or 'card' |
| date | TEXT | NOT NULL | ISO 8601 transaction date |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Expense Types:**
| Type | Description | Affects Spent? | Affects Balance? |
|------|-------------|----------------|------------------|
| `needs` | Essential expenses | Yes | Yes |
| `wants` | Discretionary expenses | Yes | Yes |
| `savings` | Money deposited to savings goals | Yes | Yes |
| `savings_withdrawal` | Money withdrawn from savings | No | No |
| `income` | Income transactions | No (adds) | No (adds) |

**Note:** `savings_withdrawal` is recorded for historical tracking but does NOT affect budget calculations. When calculating `getTotalSpent()` or `getSpentByType()`, withdrawals are excluded.

**Example:**
```sql
INSERT INTO expenses (amount, type, category_id, category_name, note, payment_method, date, created_at)
VALUES (45000, 'needs', 1, 'Groceries', 'Weekly shopping', 'cash', '2025-01-31T10:00:00.000Z', '2025-01-31T10:00:00.000Z');
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
| `getTotalSpent({DateTime? start, DateTime? end})` | Returns sum of expenses (excludes savings_withdrawal) |
| `getSpentByType({DateTime? start, DateTime? end})` | Returns spending breakdown by type (excludes savings_withdrawal) |
| `getSpentByPaymentMethod({DateTime? start, DateTime? end})` | Returns spending breakdown by payment method {'cash': amount, 'card': amount} |

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

### Version 12 (Payment Method)

```sql
ALTER TABLE expenses ADD COLUMN payment_method TEXT DEFAULT 'cash';
```

Adds payment method tracking to expenses. Existing rows default to `'cash'`. Values: `'cash'` or `'card'`.

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

---

## Notes Tables

### notes

Stores user notes (like Apple Notes).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| title | TEXT | NOT NULL | Note title |
| content | TEXT | NULLABLE | Note content |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Example:**
```sql
INSERT INTO notes (title, content, created_at, updated_at)
VALUES ('Shopping List', 'Milk, Eggs, Bread', '2025-01-31T10:00:00.000Z', '2025-01-31T10:00:00.000Z');
```

---

### people

Stores people for money tracking.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL UNIQUE | Person's name |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Example:**
```sql
INSERT INTO people (name, created_at)
VALUES ('Rahul', '2025-01-31T10:00:00.000Z');
```

---

### money_transactions

Stores money given/received records with people.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| person_id | INTEGER | NOT NULL, FK | Reference to people table |
| amount | INTEGER | NOT NULL | Amount in paise |
| type | TEXT | NOT NULL | Type: 'given' or 'received' |
| note | TEXT | NULLABLE | Optional note for transaction |
| date | TEXT | NOT NULL | ISO 8601 transaction date |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Key:** `person_id` → `people(id)` ON DELETE CASCADE

**Transaction Types:**
| Type | Description | Balance Effect |
|------|-------------|----------------|
| `given` | Money I gave to person | Positive (they owe me) |
| `received` | Money I received from person | Negative (I owe them) |

**Balance Calculation:**
- Balance = SUM(given) - SUM(received)
- Positive balance = They owe me
- Negative balance = I owe them
- Zero = Settled

**Example:**
```sql
INSERT INTO money_transactions (person_id, amount, type, note, date, created_at)
VALUES (1, 50000, 'given', 'Lunch money', '2025-01-31T10:00:00.000Z', '2025-01-31T10:00:00.000Z');
```

---

## Notes Repository Methods

### NoteRepository

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all notes ordered by updated_at DESC |
| `getById(int id)` | Returns single note by ID |
| `insert(Note)` | Creates new note, returns ID |
| `update(Note)` | Updates existing note |
| `delete(int id)` | Deletes note by ID |
| `search(String query)` | Searches notes by title or content |

### PersonRepository

| Method | Description |
|--------|-------------|
| `getAll()` | Returns all people ordered by name |
| `getById(int id)` | Returns single person by ID |
| `getByName(String name)` | Returns person by name |
| `insert(Person)` | Creates new person, returns ID |
| `update(Person)` | Updates existing person |
| `delete(int id)` | Deletes person and all transactions (CASCADE) |
| `getOrCreate(String name)` | Gets existing or creates new person |
| `getBalance(int personId)` | Returns balance (positive = they owe me) |
| `getTotalCommerce(int personId)` | Returns total money exchanged |
| `getTransactions(int personId)` | Returns all transactions for person |
| `addTransaction(MoneyTransaction)` | Adds new transaction |
| `deleteTransaction(int id)` | Deletes single transaction |
| `getAllWithBalances()` | Returns all people with their balances |

---

### Version 11 (Notes & Money Tracking)

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE people (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
);

CREATE TABLE money_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  person_id INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,
  note TEXT,
  date TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (person_id) REFERENCES people (id) ON DELETE CASCADE
);
```

---

## Tracker Tables (Hidden Feature)

### saved_locations

Stores location points bookmarked by the viewer from Firebase history to local SQLite.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| latitude | REAL | NOT NULL | Latitude coordinate |
| longitude | REAL | NOT NULL | Longitude coordinate |
| accuracy | REAL | NOT NULL | GPS accuracy in meters |
| speed | REAL | NOT NULL | Speed in m/s |
| heading | REAL | NOT NULL | Heading in degrees |
| battery_level | INTEGER | NOT NULL | Battery percentage (0-100) |
| is_charging | INTEGER | NOT NULL | 1 = charging, 0 = not |
| timestamp | TEXT | NOT NULL | ISO 8601 original location timestamp |
| saved_at | TEXT | NOT NULL | ISO 8601 when user bookmarked it |

---

### offline_location_queue

Queues location updates when device is offline. Used by both the ForegroundTracker and BackgroundService — both write to the same table when Firebase is unreachable. Drain triggers are independent of any current write: a 60s periodic timer, a connectivity listener that fires on reconnect, and the BG service tick all call `syncPending()`, which writes oldest 20 rows to `location_history/{deviceId}/points` (append-only timeline, NOT `locations/{deviceId}`) and deletes them only after each successful Firebase write — on first error the drain stops so remaining rows stay queued. Queue is capped at 1000 rows by the ForegroundTracker.

**Firestore `location_history/{deviceId}/points` now also receives a live append on every successful online GPS write (see `background_service.dart` in the `shouldSendFirebase` branch), in addition to the offline-drain path. This ensures a continuous trail exists regardless of connectivity, so `TransitDetailScreen` can draw the polyline between two visits. The `locations/{deviceId}` single-doc overwrite is unchanged.**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| latitude | REAL | NOT NULL | Latitude coordinate |
| longitude | REAL | NOT NULL | Longitude coordinate |
| accuracy | REAL | NOT NULL | GPS accuracy in meters |
| speed | REAL | NOT NULL | Speed in m/s |
| heading | REAL | NOT NULL | Heading in degrees |
| battery_level | INTEGER | NOT NULL | Battery percentage |
| is_charging | INTEGER | NOT NULL | 1 = charging, 0 = not |
| timestamp | TEXT | NOT NULL | ISO 8601 when GPS fix was taken |
| created_at | TEXT | NOT NULL | ISO 8601 when queued |

---

### geofences

Stores geofence zones for enter/exit notifications.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| name | TEXT | NOT NULL | Zone name (e.g., "Home", "Office") |
| latitude | REAL | NOT NULL | Center latitude |
| longitude | REAL | NOT NULL | Center longitude |
| radius_meters | REAL | NOT NULL | Radius in meters |
| notify_on_enter | INTEGER | NOT NULL DEFAULT 1 | 1 = notify on enter |
| notify_on_exit | INTEGER | NOT NULL DEFAULT 1 | 1 = notify on exit |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Auto-zone creation:** When a visit ends at a location not matching any existing geofence, the background service auto-creates a geofence (name "Location N", radius 100m) so the location is recognized on future visits. Auto-zones are also synced to Firebase.

---

### Version 13 (Tracker Tables)

```sql
CREATE TABLE saved_locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  accuracy REAL NOT NULL,
  speed REAL NOT NULL,
  heading REAL NOT NULL,
  battery_level INTEGER NOT NULL,
  is_charging INTEGER NOT NULL,
  timestamp TEXT NOT NULL,
  saved_at TEXT NOT NULL
);

CREATE TABLE offline_location_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  accuracy REAL NOT NULL,
  speed REAL NOT NULL,
  heading REAL NOT NULL,
  battery_level INTEGER NOT NULL,
  is_charging INTEGER NOT NULL,
  timestamp TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE geofences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  radius_meters REAL NOT NULL,
  notify_on_enter INTEGER NOT NULL DEFAULT 1,
  notify_on_exit INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);
```

---

### Version 14 (Smart Tracking — Visits & Zone Settings)

```sql
CREATE TABLE visits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  arrival_time TEXT NOT NULL,
  departure_time TEXT,
  duration_minutes INTEGER,
  zone_name TEXT,
  zone_id INTEGER,
  battery_on_arrival INTEGER NOT NULL DEFAULT -1,
  battery_on_departure INTEGER
);

CREATE TABLE zone_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  geofence_id INTEGER NOT NULL,
  zone_name TEXT NOT NULL,
  alert_on_enter INTEGER NOT NULL DEFAULT 1,
  alert_on_exit INTEGER NOT NULL DEFAULT 1,
  minimum_stay_minutes INTEGER NOT NULL DEFAULT 0,
  suppress_while_inside INTEGER NOT NULL DEFAULT 0,
  alert_only_on_exit INTEGER NOT NULL DEFAULT 0,
  update_interval_minutes INTEGER NOT NULL DEFAULT 0
);
```

#### visits

Records stationary visits detected by the smart tracking algorithm.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| latitude | REAL | NOT NULL | Anchor point latitude |
| longitude | REAL | NOT NULL | Anchor point longitude |
| arrival_time | TEXT | NOT NULL | ISO 8601 — when device arrived |
| departure_time | TEXT | | ISO 8601 — when device left (NULL = still there) |
| duration_minutes | INTEGER | | Visit duration in minutes |
| zone_name | TEXT | | Matched geofence name. `"Unknown"` is a placeholder written on arrival when no zone matches; it is upgraded at departure to the matched zone or auto-created `Place HH:MM dd MMM` zone. NULL is allowed for legacy rows. |
| zone_id | INTEGER | | Matched geofence id (nullable) |
| battery_on_arrival | INTEGER | NOT NULL DEFAULT -1 | Battery % on arrival |
| battery_on_departure | INTEGER | | Battery % on departure |

#### zone_settings

Per-zone settings controlled by the Viewer and synced to the tracker via Firebase.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| geofence_id | INTEGER | NOT NULL | FK to geofences.id |
| zone_name | TEXT | NOT NULL | Zone name (denormalized) |
| alert_on_enter | INTEGER | NOT NULL DEFAULT 1 | Notify on zone entry |
| alert_on_exit | INTEGER | NOT NULL DEFAULT 1 | Notify on zone exit |
| minimum_stay_minutes | INTEGER | NOT NULL DEFAULT 0 | Min stay before alerting (0 = immediate) |
| suppress_while_inside | INTEGER | NOT NULL DEFAULT 0 | Suppress all updates in zone |
| alert_only_on_exit | INTEGER | NOT NULL DEFAULT 0 | No entry alert, alert only on exit |
| update_interval_minutes | INTEGER | NOT NULL DEFAULT 0 | Custom GPS interval in zone (0 = default) |
