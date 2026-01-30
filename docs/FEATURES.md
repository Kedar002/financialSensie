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
Full-screen modal for logging expenses. Select category, then subcategory from Profile settings. Shows exactly where money is being spent.

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
- **Subcategory Selector** - Chip-style selection (appears below category)
  - Shows subcategories from Profile settings
  - Needs: Rent/EMI, Utilities & Bills, Other Fixed, Food & Dining, Transport, Health & Wellness
  - Wants: Shopping, Entertainment, Other
  - Savings: Emergency Fund, Goals
  - Default: Last option ("Other" for Needs/Wants, "Goals" for Savings)
- **Note Input** - Optional description field
  - Placeholder: "What was this for?"
- **Done Button** - Disabled until amount entered AND subcategory selected
  - Subtle opacity animation for disabled state

**Budget Connections:**
| Category | Subcategories | Source in Profile |
|----------|---------------|-------------------|
| Needs | Rent/EMI, Utilities, Other Fixed | Fixed Expenses |
| Needs | Food, Transport, Health | Variable Budget (Essential) |
| Wants | Shopping, Entertainment, Other | Variable Budget (Lifestyle) |
| Savings | Emergency Fund | Safety Tab |
| Savings | Goals | Goals Tab |

**Design Principles Applied:**
- One action per screen
- Large, easy-to-use input
- Subcategory chips connect to Profile settings
- Clear visual hierarchy: Amount → Category → Subcategory → Note
- Auto-focus for immediate input
- Steve Jobs approved minimal chip design

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
- **Header** - Back button + "Monthly Budget" title + "History" link
  - History link: Subtle gray text, navigates to Budget History screen
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
- History access is secondary (subtle text link, not prominent button)

**Files:**
- `lib/features/home/screens/monthly_budget_screen.dart`

---

### 1.4 Budget History Screen

**Status:** In Progress (UI only)

**Description:**
Shows historical budget reports for all past months since the user started using the app (up to 2 years). Clean list grouped by year with key metrics at a glance.

**Navigation:** Tap "History" link in Monthly Budget screen header

**Key Elements:**
- **Header** - Back button + "Budget History" title
- **Year Sections** - Months grouped by year (most recent year first)
  - Year label as section header (titleLarge)
  - Each year contains its months in reverse chronological order
- **Month Cards** - One card per month showing:
  - Month name (left side)
  - Budget amount (subtitle, gray)
  - Net result (right side): +/- amount with "Saved" or "Over" label
  - Chevron indicator for future detail navigation
- **Empty State** - Shown when no history exists
  - "No history yet" title
  - "Your past budgets will appear here" subtitle

**Data Model:**
```dart
class MonthlyBudgetSummary {
  final int year;
  final int month;
  final String monthName;
  final double totalBudget;
  final double totalSpent;
  final double remaining;
}
```

**Design Principles Applied:**
- One clear purpose: View past months
- Minimal information per card (month, budget, result)
- Grouped by year for easy scanning
- Positive results in black, negative in gray (not red - stays monochrome)
- Chevron indicates tappable (future detail view)
- Empty state is helpful, not decorative
- No charts or graphs - just clean data

**Future Implementation (not yet done):**
- Load actual data from database
- Filter by year

**Files:**
- `lib/features/home/screens/budget_history_screen.dart`

---

### 1.5 Budget History Detail Screen

**Status:** In Progress (UI only)

**Description:**
Detail view for a specific historical month. Shows the 50-30-20 breakdown and result for that month. Read-only view of past data.

**Navigation:** Tap any month card in Budget History screen

**Key Elements:**
- **Header** - Back button + "Month Year" title (e.g., "December 2025")
- **Overview** - Total budget, spent, and saved/over amounts
  - Budget amount in displayMedium
  - Two stats: Spent and Saved/Over
- **Budget Breakdown** - 50-30-20 buckets with progress
  - Needs (50%) - Budget, spent, progress bar, left/over
  - Wants (30%) - Budget, spent, progress bar, left/over
  - Savings (20%) - Budget, spent, progress bar, left/over
- **Result Card** - Centered summary
  - "You saved" or "You overspent" label
  - Large +/- amount in displayMedium
  - "this month" subtitle

**Design Principles Applied:**
- Mirrors Monthly Budget screen layout for consistency
- Read-only (no actions, just viewing)
- Result card provides clear month summary
- Progress bars show category performance
- Monochrome color scheme maintained

**Future Implementation (not yet done):**
- Load actual category-level data from database
- Show actual expense breakdown per category

**Files:**
- `lib/features/home/screens/budget_history_detail_screen.dart`

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

### 3. Safety Tab (Emergency Fund)

**Status:** Completed

**Description:**
The Safety tab - shows runway (months of survival without income) and progress towards emergency fund goal. This is a dedicated bottom navigation tab, not a sub-screen.

**Tab:** Safety (bottom navigation, index 1)

**Key Elements:**
- **Header** - "Safety" title (matches other tabs: "Goals", "You")
- **Runway Card** - Hero metric showing months of survival
  - "You can survive X months without income"
  - Large displayMedium typography
- **Progress Card** - Visual progress indicator
  - Progress bar with percentage
  - Current vs target amounts
- **Details Card** - Calculation breakdown
  - Target (6 months)
  - Monthly essentials
  - Still needed (highlighted)
  - Info box explaining the calculation
- **Add to Fund Button** - Primary ElevatedButton at bottom

**Design Principles Applied:**
- Matches tab screen pattern (SafeArea + SingleChildScrollView)
- No AppBar (it's a tab, not a pushed screen)
- Title matches other tabs ("Safety", "Goals", "You")
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

### 4. Goals Tab

**Status:** Completed

**Description:**
User-created savings goals grouped by timeline. Goals are automatically categorized based on target date and suggest appropriate savings instruments. Design matches the visual richness of the Safety tab.

**Tab:** Goals (bottom navigation, index 2)

**Goal Timeline Categories:**
| Category | Timeline | Suggested Instruments |
|----------|----------|----------------------|
| **Short-term** | < 1 year | Savings Account, Piggy Bank, Fixed Deposit |
| **Mid-term** | 1-5 years | Mutual Funds, Certificate of Deposit, Recurring Deposit |
| **Long-term** | > 5 years | Stocks, Index Funds, Bonds |

**Key Elements:**

**Empty State (no goals):**
- **Header** - "Goals" title
- **Empty Card** - AppCard with:
  - Centered flag icon
  - "No goals yet" title
  - "Set a savings goal to start tracking your progress" subtitle
- **Create Goal Button** - Full-width ElevatedButton

**With Goals:**
- **Header** - "Goals" title + styled add button (gray background, rounded)
- **Overview Card** - AppCard showing:
  - Total saved amount (displayMedium)
  - "of X target" subtitle
  - Overall progress bar (8px)
  - Goal count + completion percentage
- **Timeline Sections** - Section header with badge
  - Section title (titleMedium)
  - Timeline badge ("Under 1 year", "1-5 years", "5+ years")
- **Goal Cards** - AppCard for each goal:
  - Name + instrument label
  - Remaining amount + "to go"
  - Progress bar with current/target amounts
  - Chevron indicator

**Design Principles Applied:**
- Matches Safety tab visual language (AppCard components)
- Overview card provides aggregate view
- 8px progress bars (consistent with Safety)
- Timeline badges for section context
- Each goal in its own card for visual hierarchy
- Tappable cards with proper feedback

**Files:**
- `lib/features/goals/models/goal.dart` - Goal model with timeline logic
- `lib/features/goals/screens/goals_screen.dart`
- `lib/features/goals/screens/add_goal_screen.dart`
- `lib/features/goals/screens/goal_detail_screen.dart`
- `lib/features/goals/screens/add_to_goal_screen.dart`
- `lib/features/goals/screens/edit_goal_screen.dart`

---

### 4.2 Goal Detail Screen

**Status:** Completed

**Description:**
View and manage a single savings goal. Rich card-based layout matching the Safety tab pattern. Three distinct cards for information hierarchy.

**Key Elements:**
- **Header** - Back button (styled) + "Edit" button (styled)
  - Both buttons have gray100 background, rounded corners
- **Hero Card** - AppCard with:
  - Goal name + timeline badge (black, white text)
  - Instrument label (gray subtitle)
  - "Saved" label + big amount (displayLarge)
  - "of X target" subtitle
- **Progress Card** - AppCard with:
  - "Progress" title + percentage
  - Full progress bar (8px)
  - Current/target amounts below
- **Details Card** - AppCard with:
  - "Still needed" row (bold value)
  - Target date row
  - Save per month row (if not complete)
  - Info box with actionable tip
- **Delete Action** - Centered subtle gray text
- **Bottom Button** - Sticky "Add to Goal" (disabled if complete)
  - Top border separator

**Delete Confirmation:**
- Bottom sheet (not dialog)
- Goal name in title
- "This will permanently remove your goal and progress."
- Cancel (outlined) + Delete (filled) buttons side by side

**Design Principles Applied:**
- Matches Safety tab visual language
- Three cards create clear information hierarchy
- Hero number is the focus (how much saved)
- Timeline badge provides context
- Info box gives actionable guidance
- Sticky bottom with visual separator
- Button disabled when goal complete

**Files:**
- `lib/features/goals/screens/goal_detail_screen.dart`

---

### 4.3 Add to Goal Screen

**Status:** Completed

**Description:**
Add funds to a savings goal. Same pattern as Add Fund and Add Expense.

**Key Elements:**
- **Header** - Cancel, goal name (centered)
- **Amount Input** - Large ₹ input
- **Done Button** - Disabled until valid

**Files:**
- `lib/features/goals/screens/add_to_goal_screen.dart`

---

### 4.4 Edit Goal Screen

**Status:** Completed

**Description:**
Edit all goal properties: name, target amount, target date, and savings instrument.

**Key Elements:**
- **Header** - Cancel, "Edit Goal" title
- **Name Input** - Pre-filled with current name
- **Target Amount Input** - Pre-filled with current target
- **Target Date Picker** - Pre-filled with current date
- **Timeline Info** - Updates when date changes
- **Instrument Selector** - Pre-selected with current instrument
  - If timeline changes, suggests new instruments
  - Keeps current selection if still valid
- **Save Changes Button** - Disabled until changes made

**Design Principles Applied:**
- Same layout as Add Goal screen
- Preserves user's existing choices
- Smart instrument handling on timeline change
- Button disabled if no changes or invalid

**Files:**
- `lib/features/goals/screens/edit_goal_screen.dart`

---

### 4.1 Add Goal Screen

**Status:** Completed

**Description:**
Full-screen modal for creating a new savings goal with timeline-based categorization and instrument suggestions.

**Key Elements:**
- **Header** - Cancel button (text), "New Goal" title
- **Goal Name Input** - Clean text field
  - Headline question: "What are you saving for?"
  - Large input with placeholder examples
  - Auto-focus on open
- **Target Amount Input** - Large currency input with ₹ prefix
- **Target Date Picker** - Date selection
  - Opens native date picker
  - App calculates timeline category automatically
- **Timeline Info** - Appears after date selection
  - Shows badge: "Short-term", "Mid-term", or "Long-term"
  - Shows timeline description
- **Instrument Selector** - Chip-style selection
  - Shows suggested instruments for the timeline
  - User selects where they'll save
  - Animated selection state
- **Create Goal Button** - Disabled until all fields valid

**Design Principles Applied:**
- Progressive disclosure (instrument selector appears after date)
- Automatic categorization (user doesn't manually select category)
- Helpful suggestions based on timeline
- Consistent with app's input patterns
- Validation feedback via button opacity

**Files:**
- `lib/features/goals/screens/add_goal_screen.dart`

---

### 5. Profile Screen

**Status:** Completed

**Description:**
Minimal settings screen showing financial configuration, access to Financial Plan, and knowledge base.

**Key Elements:**
- **Financial Plan Card** - Prominent card at top
  - Icon + "Financial Plan" title
  - "10 steps to financial freedom" subtitle
  - Navigates to Financial Plan screen
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
- Financial Plan card is the hero element

**Files:**
- `lib/features/profile/screens/profile_screen.dart`

---

### 5.1 Financial Plan Screen

**Status:** Completed

**Description:**
The 10-step roadmap to financial freedom. Shows progress through each step with completion tracking. Central hub that connects all financial features.

**The 10 Steps:**
| Step | Title | Description | Connected To |
|------|-------|-------------|--------------|
| 1 | Know Your Income | Monthly take-home | Profile → Income |
| 2 | Budget Rule | 50-30-20 allocation | Monthly Budget |
| 3 | Fixed Needs | Non-negotiable expenses | Profile → Fixed Expenses |
| 4 | Lifestyle Wants | Adjustable spending | Profile → Variable Budget |
| 5 | Set Goals | Short, mid & long-term | Goals Tab |
| 6 | Emergency Fund | 3-6 months of needs | Safety Tab |
| 7 | Handle Debt | Pay high-interest first | Debt Screen (new) |
| 8 | Save & Invest | Build your future | 20% allocation |
| 9 | Automate | Remove discipline problems | Guidance |
| 10 | Monthly Review | Track & adjust | Ongoing |

**Key Elements:**
- **Progress Card** - Shows X/10 steps complete with progress bar
- **Steps List** - All 10 steps with status indicators
  - Complete: Black circle with checkmark
  - Current: Number with black text
  - Pending: Number with gray text
- **Step Details** - Tap any step for info bottom sheet
  - Step explanation
  - Action button (navigate to related screen)

**Design Principles Applied:**
- One screen overview of entire financial plan
- Clear progress visualization
- Each step links to existing features
- No redundant screens - reuses existing functionality
- Bottom sheet for details (not separate screens)

**Files:**
- `lib/features/plan/screens/financial_plan_screen.dart`
- `lib/features/plan/models/financial_plan.dart`

---

### 5.2 Debt Screen

**Status:** Completed

**Description:**
Track and manage debts. Prioritizes high-interest debt (pay first) over low-interest.

**Key Elements:**
- **Overview Card** - Total remaining debt with progress
  - Progress bar showing paid vs remaining
  - Priority tip (focus on highest interest first)
- **Priority Sections** - Debts grouped by priority
  - High Priority (>15% interest) - Pay first
  - Medium Priority (8-15%) - Pay after high
  - Low Priority (<8%) - Maintain minimum
  - Paid Off - Completed debts
- **Debt Cards** - Each debt shows:
  - Name
  - Interest rate
  - Remaining amount (of total)
  - Progress bar
- **Actions** - Record payment, Delete debt

**Design Principles Applied:**
- Priority-based grouping (not alphabetical)
- Visual hierarchy: high-interest is most prominent
- Celebration for debt-free state
- Simple actions via bottom sheet

**Files:**
- `lib/features/plan/screens/debt_screen.dart`
- `lib/features/plan/screens/add_debt_screen.dart`

---

### 5.3 Add Debt Screen

**Status:** Completed

**Description:**
Add a debt to track. Auto-calculates priority based on interest rate.

**Key Elements:**
- **Name Input** - What is this debt?
- **Amount Input** - Total amount owed
- **Interest Rate Input** - Annual percentage
- **Priority Indicator** - Auto-shows priority based on rate
  - High (>15%): Black banner "Pay this first"
  - Medium/Low: Gray info box
- **Minimum Payment** - Optional monthly minimum

**Design Principles Applied:**
- Progressive disclosure (priority shows after interest entered)
- Auto-focus on name field
- Clear validation feedback
- Follows Add Expense pattern

**Files:**
- `lib/features/plan/screens/add_debt_screen.dart`

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
| Budget History Screen | Past Month Reports | `lib/features/home/screens/budget_history_screen.dart` | In Progress |
| Budget History Detail Screen | Single Month Detail | `lib/features/home/screens/budget_history_detail_screen.dart` | In Progress |
| All Expenses Screen | Expense History | `lib/features/home/screens/all_expenses_screen.dart` | Completed |
| Safety Screen | Safety Tab (Emergency Fund) | `lib/features/emergency_fund/screens/emergency_fund_screen.dart` | Completed |
| Add Fund Screen | Safety Tab | `lib/features/emergency_fund/screens/add_fund_screen.dart` | Completed |
| Goals Screen | Goals Tab | `lib/features/goals/screens/goals_screen.dart` | Completed |
| Add Goal Screen | Goals Tab | `lib/features/goals/screens/add_goal_screen.dart` | Completed |
| Goal Detail Screen | Goals Tab | `lib/features/goals/screens/goal_detail_screen.dart` | Completed |
| Add to Goal Screen | Goals Tab | `lib/features/goals/screens/add_to_goal_screen.dart` | Completed |
| Edit Goal Screen | Goals Tab | `lib/features/goals/screens/edit_goal_screen.dart` | Completed |
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
