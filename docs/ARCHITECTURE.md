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

---

## Folder Structure

```
lib/
├── main.dart                          # App entry point
│
├── core/                              # Shared core functionality
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   │
│   └── theme/
│       └── app_theme.dart             # App theme
│
├── features/                          # Feature modules
│   └── [feature_name]/
│       ├── screens/
│       └── widgets/
│
└── shared/                            # Shared UI components
    ├── widgets/
    └── utils/
```

---

## Notes for Developers

1. Build UI first, then add data layer
2. Keep components small and focused
3. Follow the Steve Jobs Design Standard from CLAUDE.md
