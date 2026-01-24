# Database Schema Documentation

This document tracks all database tables, their schemas, and relationships. **This file MUST be updated whenever a table is created, modified, or deleted.**

---

## Database Overview

- **Database Type:** SQLite (via sqflite)
- **Database Name:** `financesensei.db`
- **Version:** 1

---

## Tables

<!--
TEMPLATE FOR NEW TABLE:

### table_name
**Created:** YYYY-MM-DD
**Purpose:** Brief description of what this table stores

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Unique identifier |
| column_name | TYPE | CONSTRAINTS | Description |

**Relationships:**
- Related to `other_table` via `foreign_key`

**Indexes:**
- `idx_name` on `column_name`

---
-->

*No tables created yet. Tables will be documented here as they are implemented.*

---

## Migration History

| Version | Date | Changes |
|---------|------|---------|
| 1 | - | Initial database creation |

---

## Entity Relationship Diagram

```
[Will be updated as tables are added]
```

---

## Notes for Developers

1. **Always update this file** when modifying the database schema
2. Use migrations for schema changes - never modify tables directly
3. All tables must have an `id` column as PRIMARY KEY
4. Use `created_at` and `updated_at` timestamps where applicable
5. Foreign keys should follow naming convention: `{referenced_table}_id`
