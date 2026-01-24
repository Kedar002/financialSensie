# Architecture Documentation

This document describes the overall architecture of FinanceSensei.

---

## Overview

FinanceSensei is an **offline-first** application built with Flutter. All data is stored locally using SQLite, ensuring the app works without internet connectivity.

---

## Folder Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Core functionality (shared across features)
│   ├── constants/               # App-wide constants
│   │   └── app_constants.dart
│   ├── database/                # Database layer
│   │   ├── database_service.dart    # Main database service
│   │   └── tables/              # Table definitions
│   ├── models/                  # Data models (DTOs)
│   ├── repositories/            # Data access layer
│   ├── services/                # Business logic services
│   └── theme/                   # App theming
│       └── app_theme.dart
├── features/                    # Feature modules
│   └── [feature_name]/
│       ├── screens/             # UI screens
│       ├── widgets/             # Feature-specific widgets
│       ├── models/              # Feature-specific models
│       └── services/            # Feature-specific services
└── shared/                      # Shared components
    ├── widgets/                 # Reusable widgets
    └── utils/                   # Utility functions
```

---

## Architecture Pattern

### Repository Pattern

```
UI (Screens/Widgets)
        ↓
    Services (Business Logic)
        ↓
    Repositories (Data Access)
        ↓
    Database Service (SQLite)
```

**Flow:**
1. **UI** calls **Service** methods
2. **Service** contains business logic, calls **Repository**
3. **Repository** handles data operations, calls **Database Service**
4. **Database Service** executes SQL queries

---

## Data Layer

### Database Service
- Single instance (singleton)
- Handles database initialization
- Manages migrations
- Provides raw query access

### Repositories
- One repository per entity/table
- CRUD operations
- Returns model objects

### Models
- Plain Dart objects
- `fromMap()` and `toMap()` for database conversion
- Immutable where possible

---

## Offline-First Principles

1. **All data stored locally** - SQLite database
2. **No network dependency** - App fully functional offline
3. **Fast performance** - Local queries are instant
4. **Data persistence** - Survives app restarts

---

## State Management

*To be decided based on app complexity. Options:*
- Provider (simple)
- Riverpod (recommended)
- Bloc (complex)

---

## Key Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| - | SQLite for local storage | Mature, reliable, good Flutter support |
| - | Offline-first architecture | User requirement, better UX |
| - | Repository pattern | Clean separation, testable |

---

## Notes for Developers

1. Keep features isolated in their own folders
2. Shared code goes in `core/` or `shared/`
3. Document architectural decisions in the table above
4. Follow the data flow pattern consistently
