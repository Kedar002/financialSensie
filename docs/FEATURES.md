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
  - Shows `rollingDailyAllowance` as the hero number
  - Context line shows `plannedDailyBudget` and days remaining
  - Over-budget warning when applicable
  - See [BUDGET_LOGIC.md](./BUDGET_LOGIC.md) for calculation details
- **Cycle Progress** - Monthly budget overview
  - Thin progress bar (4px)
  - Three stats in order: Budget, Spent, Left
  - "Left" is highlighted as the key metric
  - Negative values shown in muted gray
- **Recent Expenses** - List of last 5 expenses
  - Shows note (or "Expense" if none), date, and amount
  - Clean row layout with minimal information
  - "View all" link to see all expenses
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
- `lib/core/models/budget_cycle.dart`
- `lib/core/services/budget_calculator.dart`
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

### 1.2 Monthly Budget Screen

**Status:** Completed

**Description:**
Shows the 50-30-20 budget breakdown with spending progress for each category.

**Navigation:** Tap "This month" section on Home screen (indicated by chevron)

**Key Elements:**
- **Overview** - Total budget, spent, and remaining
- **The 50-30-20 Rule** - Three budget buckets
  - Needs (50%) - Essentials like food, transport, bills
  - Wants (30%) - Lifestyle like dining, entertainment
  - Savings (20%) - Future like investments, emergency fund
  - Each shows: Budget amount, progress bar, spent vs left
- **Your Spending** - Actual spending visualization
  - Horizontal stacked bar (black/gray/light)
  - Legend with percentages

**Design Principles Applied:**
- Clean section headers
- Progress bars for each category
- No pie charts (too decorative)
- Stacked bar for actual spending (simple, clear)
- Gray tones only (black, gray400, gray200)

**Files:**
- `lib/features/home/screens/monthly_budget_screen.dart`

---

### 1.3 All Expenses Screen

**Status:** Completed

**Description:**
Full list of all expenses with advanced filtering by category and dates. Supports single date, multiple dates, and date range selection.

**Navigation:** Tap "View all" link in Recent section on Home screen

**Key Elements:**
- **Category Filter** - Four chips (All, Needs, Wants, Savings)
  - Selected: Black fill, white text
  - Unselected: Gray100 fill, gray text
- **Date Filter** - Expandable calendar with selection modes
  - Single date selection
  - Multiple date selection (tap to toggle)
  - Date range selection (start to end)
  - Month/year quick picker
- **Summary** - Shows count and total for current filters
- **Grouped List** - Expenses grouped by date
  - Date headers with daily total (Today, Yesterday, or weekday + date)
  - Color-coded left border (black for Needs, gray400 for Wants, gray200 for Savings)
  - Note, category label, and amount

**Design Principles Applied:**
- Simple filter chips (not dropdowns)
- Calendar hides by default, expands on tap
- Three selection modes with clear toggle
- Grouped by day (not a flat list)
- Color coding via left border only
- Empty state with context-aware message

**Files:**
- `lib/features/home/screens/all_expenses_screen.dart`
- `lib/shared/widgets/advanced_date_picker.dart`

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

**Navigation:** Tap Emergency Fund card on Goals screen

**Key Elements:**
- **AppBar** - Back button, title, "Add" text button (quick access)
- **Runway Card** - Hero metric showing months of survival
  - "You can survive X months without income"
- **Progress Card** - Visual progress indicator
  - Progress bar with percentage
  - Current vs target amounts
- **Details Card** - Calculation breakdown
  - Target (6 months)
  - Monthly essentials
  - Still needed (highlighted)
  - Info box explaining the calculation
- **Bottom Button** - Primary "Add to Fund" action (sticky)

**Design Principles Applied:**
- Primary action in two places: AppBar (quick) and bottom (prominent)
- Bottom button uses `ElevatedButton` (primary style)
- Information flows top to bottom: status → progress → details → action
- No decorative elements

**Files:**
- `lib/features/emergency_fund/screens/emergency_fund_screen.dart`
- `lib/features/emergency_fund/screens/add_fund_screen.dart`

---

### 3.1 Add Fund Screen

**Status:** Completed

**Description:**
Full-screen modal for recording contributions to the emergency fund. Follows the same pattern as Add Expense screen.

**Key Elements:**
- **Header** - Cancel button (text), "Add to Fund" title
- **Amount Input** - Large currency input with ₹ prefix
  - Auto-focus on open
  - Supports decimals (2 decimal places)
- **Note Input** - Optional description field
  - Placeholder: "e.g., Bonus, Tax refund"
- **Done Button** - Disabled until valid amount entered
  - Subtle opacity animation for disabled state

**Design Principles Applied:**
- One action per screen
- Large, easy-to-use input
- Mirrors Add Expense pattern for consistency
- Auto-focus for immediate input

**Files:**
- `lib/features/emergency_fund/screens/add_fund_screen.dart`

---

### 4. Goals Screen (Safety Tab)

**Status:** Completed

**Description:**
List of planned expenses/savings goals including emergency fund.

**Key Elements:**
- **Header** - "Goals" title with add button (IconButton)
- **Emergency Fund Card** - Tappable card showing:
  - Lock icon in gray container
  - "Emergency Fund" label
  - Runway in months (subtitle)
  - Progress percentage
  - Chevron indicator (shows it's tappable)
  - Progress bar
  - Current vs target amounts
  - Navigates to Emergency Fund screen on tap
- **Add More Goals** - Call-to-action section
  - Title and description
  - "Add Goal" button (placeholder)

**Design Principles Applied:**
- Emergency Fund is prominently featured (most important goal)
- Chevron indicator follows iOS navigation patterns
- Single card focus (not a cluttered list)
- Clear visual hierarchy

**Files:**
- `lib/features/goals/screens/goals_screen.dart`
- `lib/features/goals/screens/add_goal_screen.dart`

---

### 5. Profile Screen

**Status:** Completed

**Description:**
Minimal settings screen showing financial configuration and access to knowledge base.

**Key Elements:**
- **Setup Section** - Five tappable rows (iOS Settings style)
  - Income → Edit income screen
  - Fixed Expenses → Edit expenses screen
  - Variable Budget → Edit budget screen
  - Savings → Edit savings screen
  - Budget Cycle → Edit cycle settings
- **Learn Section** - Link to Knowledge screen
  - "How it works" with subtitle

**Design Principles Applied:**
- iOS Settings-style rows (tap anywhere to navigate)
- Chevron indicators for navigation
- Values shown inline (no cards)
- Minimal vertical dividers
- No summary cards or calculated values
- No danger zone / delete options

**Files:**
- `lib/features/profile/screens/profile_screen.dart`

---

### 6. Cycle Settings Screen

**Status:** Completed

**Description:**
Configure when your budget cycle starts. Two options: calendar month or custom paycheck cycle.

**Key Elements:**
- **Cycle Type Selection** - Two options
  - Calendar month (1st to end of month)
  - Paycheck cycle (custom start day)
- **Day Selector** - Appears when custom cycle selected
  - +/- buttons to select day (1-28)
  - Restricted to 28 to avoid short month issues
- **Preview** - Shows current cycle dates and duration

**Design Principles Applied:**
- Two clear options (not a long list)
- Selected state: Black fill with white text
- Unselected state: White with border
- Day selector is simple +/- (no complex picker)
- Live preview updates as you change settings

**Files:**
- `lib/features/profile/screens/cycle_settings_screen.dart`
- `lib/core/models/cycle_settings.dart`

---

### 7. Knowledge Screen

**Status:** Completed

**Description:**
Explains the app philosophy and budget calculation logic in simple, human terms.

**Key Sections:**
- **The Philosophy** - Why the app exists
- **The Math** - Four-step breakdown of calculations
- **Two Numbers** - Explains Planned vs Available
- **Example** - Real calculation walkthrough
- **Three Buckets** - Needs, Wants, Savings categories

**Design Principles Applied:**
- Clean typography hierarchy
- Numbered steps with black circles
- Card-style explanations for key numbers
- No jargon, conversational tone
- Generous whitespace

**Files:**
- `lib/features/profile/screens/knowledge_screen.dart`

---

## Screen Inventory

| Screen Name | Feature | File Path | Status |
|-------------|---------|-----------|--------|
| Home Screen | Daily Spending View | `lib/features/home/screens/home_screen.dart` | Completed |
| Add Expense Screen | Expense Logging | `lib/features/home/screens/add_expense_screen.dart` | Completed |
| Monthly Budget Screen | 50-30-20 Breakdown | `lib/features/home/screens/monthly_budget_screen.dart` | Completed |
| All Expenses Screen | Expense History | `lib/features/home/screens/all_expenses_screen.dart` | Completed |
| Emergency Fund Screen | Emergency Fund Tracker | `lib/features/emergency_fund/screens/emergency_fund_screen.dart` | Completed |
| Add Fund Screen | Emergency Fund Tracker | `lib/features/emergency_fund/screens/add_fund_screen.dart` | Completed |
| Goals Screen | Goals Tracker | `lib/features/goals/screens/goals_screen.dart` | Completed |
| Add Goal Screen | Goals Tracker | `lib/features/goals/screens/add_goal_screen.dart` | Completed |
| Profile Screen | Settings | `lib/features/profile/screens/profile_screen.dart` | Completed |
| Cycle Settings Screen | Budget Cycle | `lib/features/profile/screens/cycle_settings_screen.dart` | Completed |
| Knowledge Screen | How It Works | `lib/features/profile/screens/knowledge_screen.dart` | Completed |
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
| BudgetCycle | Budget cycle configuration (start/end dates, budget amount) | `lib/core/models/budget_cycle.dart` |
| BudgetSnapshot | Calculated budget state (planned, rolling, spent, remaining) | `lib/core/services/budget_calculator.dart` |
| CycleSettings | User's cycle preference (calendar month or custom day) | `lib/core/models/cycle_settings.dart` |
| CycleType | Enum: calendarMonth, customDay | `lib/core/models/cycle_settings.dart` |

## Services

| Service | Purpose | File Path |
|---------|---------|-----------|
| BudgetCalculator | Stateless calculator for budget metrics | `lib/core/services/budget_calculator.dart` |

---

## Shared Widgets

| Widget | Purpose | File Path |
|--------|---------|-----------|
| MinimalCalendar | Date selection with week/month views | `lib/shared/widgets/minimal_calendar.dart` |
| AdvancedDatePicker | Multi-mode date picker (single/multiple/range) | `lib/shared/widgets/advanced_date_picker.dart` |
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
