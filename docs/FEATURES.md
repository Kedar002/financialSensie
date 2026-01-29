# Features & Functionality Documentation

This document tracks all features, their status, and implementation details.

---

## Product Vision

> **"A decision-making system for salaried people to automatically build wealth without thinking daily"**

Core Promise: *"I don't track money. My system does."*

---

## Feature Status Legend

- **Planned** - Feature is defined but not started
- **In Progress** - Currently being implemented
- **Completed** - Feature is fully implemented and tested

---

## Features

### 1. Home Screen - Daily Spending View

**Status:** Completed

**Description:**
The core screen of the app. Shows how much the user can safely spend today with a minimal calendar for date navigation, expense logging, and recent expense history.

**Key Elements:**
- **Minimal Calendar** - Week strip view by default, expands to full month on tap
  - Selected day: Filled black circle
  - Today indicator: Small dot below date (when not selected)
  - Month navigation: Previous/Next arrows, "Today" quick-jump
  - Clean 7-column grid for month view
- **Hero Section** - Large display of spendable amount
  - Context-aware label: "You can spend" (today) / "Spent on X" (past) / "Planned" (future)
  - Dynamic calculation based on remaining budget and days left
- **Cycle Progress** - Monthly budget overview
  - Thin progress bar (4px)
  - Three stats in order: Budget, Spent, Left
  - "Left" is highlighted as the key metric
- **Recent Expenses** - List of last 5 expenses
  - Shows note (or "Expense" if none), date, and amount
  - Clean row layout with minimal information
- **FAB (Floating Action Button)** - Quick expense logging
  - Opens full-screen Add Expense screen

**Design Principles Applied:**
- One primary focus: The spending amount
- Minimal UI elements
- Clean typography hierarchy
- Generous whitespace
- No decorative elements

**Files:**
- `lib/features/home/screens/home_screen.dart`
- `lib/features/home/screens/add_expense_screen.dart`
- `lib/features/home/models/expense.dart`
- `lib/shared/widgets/minimal_calendar.dart`

---

### 1.1 Add Expense Screen

**Status:** Completed

**Description:**
Full-screen modal for logging expenses. Minimal, focused on one action: enter what you spent.

**Key Elements:**
- **Header** - Cancel button (text), date label, clean layout
- **Amount Input** - Large currency input with ₹ prefix
  - Auto-focus on open
  - Supports decimals (2 decimal places)
- **Category Selector** - Segmented control with three options
  - Needs, Wants, Savings
  - Selected: Black background, white text
  - Unselected: Gray text, transparent background
  - Smooth 200ms animation on selection
  - Default: "Needs" (most common)
- **Note Input** - Optional description field
  - Placeholder: "What was this for?"
- **Done Button** - Disabled until valid amount entered
  - Subtle opacity animation for disabled state

**Design Principles Applied:**
- One action per screen
- Large, easy-to-use input
- Three category buckets (Needs/Wants/Savings - aligned with 50/30/20 rule)
- Clean segmented control - no icons, just text
- Auto-focus for immediate input

**Files:**
- `lib/features/home/screens/add_expense_screen.dart`
- `lib/features/home/models/expense.dart`

---

### 2. Onboarding Flow

**Status:** Completed

**Description:**
Simple step-by-step setup flow for new users.

**Screens:**
1. Welcome Screen - Introduction
2. Income Setup - Monthly income input
3. Expenses Setup - Fixed costs input
4. Variable Budget Setup - Category-wise spending estimates
5. Savings Setup - Emergency fund input

**Files:**
- `lib/features/onboarding/screens/welcome_screen.dart`
- `lib/features/onboarding/screens/income_setup_screen.dart`
- `lib/features/onboarding/screens/expenses_setup_screen.dart`
- `lib/features/onboarding/screens/variable_budget_setup_screen.dart`
- `lib/features/onboarding/screens/savings_setup_screen.dart`

---

### 3. Emergency Fund Tracker

**Status:** Completed

**Description:**
Shows runway (months of survival without income) and progress towards emergency fund goal.

**Key Elements:**
- Runway display in months
- Progress bar with percentage
- Target calculation details
- "Add to Fund" action

**Files:**
- `lib/features/emergency_fund/screens/emergency_fund_screen.dart`

---

### 4. Goals Screen

**Status:** Completed

**Description:**
List of planned expenses/savings goals including emergency fund.

**Key Elements:**
- Emergency fund card with progress
- Add goal functionality (placeholder)

**Files:**
- `lib/features/goals/screens/goals_screen.dart`
- `lib/features/goals/screens/add_goal_screen.dart`

---

### 5. Profile Screen

**Status:** In Progress

**Description:**
User settings and configuration editing.

**Files:**
- `lib/features/profile/screens/profile_screen.dart`

---

## Screen Inventory

| Screen Name | Feature | File Path | Status |
|-------------|---------|-----------|--------|
| Home Screen | Daily Spending View | `lib/features/home/screens/home_screen.dart` | Completed |
| Add Expense Screen | Expense Logging | `lib/features/home/screens/add_expense_screen.dart` | Completed |
| Emergency Fund Screen | Emergency Fund Tracker | `lib/features/emergency_fund/screens/emergency_fund_screen.dart` | Completed |
| Goals Screen | Goals Tracker | `lib/features/goals/screens/goals_screen.dart` | Completed |
| Add Goal Screen | Goals Tracker | `lib/features/goals/screens/add_goal_screen.dart` | Completed |
| Profile Screen | Settings | `lib/features/profile/screens/profile_screen.dart` | In Progress |
| Welcome Screen | Onboarding | `lib/features/onboarding/screens/welcome_screen.dart` | Completed |
| Income Setup Screen | Onboarding | `lib/features/onboarding/screens/income_setup_screen.dart` | Completed |
| Expenses Setup Screen | Onboarding | `lib/features/onboarding/screens/expenses_setup_screen.dart` | Completed |
| Variable Budget Setup Screen | Onboarding | `lib/features/onboarding/screens/variable_budget_setup_screen.dart` | Completed |
| Savings Setup Screen | Onboarding | `lib/features/onboarding/screens/savings_setup_screen.dart` | Completed |

---

## Models

| Model | Purpose | File Path |
|-------|---------|-----------|
| Expense | Represents a single expense entry | `lib/features/home/models/expense.dart` |
| ExpenseCategory | Enum: needs, wants, savings | `lib/features/home/models/expense.dart` |

---

## Shared Widgets

| Widget | Purpose | File Path |
|--------|---------|-----------|
| MinimalCalendar | Date selection with week/month views | `lib/shared/widgets/minimal_calendar.dart` |
| AppCard | Clean card container with subtle border | `lib/shared/widgets/app_card.dart` |
| ProgressBar | Simple progress indicator | `lib/shared/widgets/progress_bar.dart` |
| AmountDisplay | Formatted currency display | `lib/shared/widgets/amount_display.dart` |
| SectionHeader | Consistent section headers | `lib/shared/widgets/section_header.dart` |
| MetricRow | Label-value row display | `lib/shared/widgets/metric_row.dart` |

---

## Notes for Developers

1. **Always update this file** when adding or modifying features
2. Each feature should have its own folder under `lib/features/`
3. All screens must pass the Steve Jobs Design Checklist before implementation
