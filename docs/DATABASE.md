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
