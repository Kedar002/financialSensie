# Data Flow & Budget Connections

This document explains how money flows through the app and how different components connect.

---

## The Money Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MONTHLY INCOME                               │
│                           ₹50,000                                    │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      FIXED EXPENSES (Auto-deducted)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  Rent/EMI    │  │  Utilities   │  │    Other     │               │
│  │   ₹12,000    │  │    ₹4,000    │  │   ₹2,000     │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                        Total: ₹18,000                                │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    VARIABLE BUDGET (₹32,000)                         │
│         This is what you actively manage day-to-day                  │
│                                                                      │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐        │
│  │     NEEDS       │ │     WANTS       │ │    SAVINGS      │        │
│  │      50%        │ │      30%        │ │      20%        │        │
│  │    ₹16,000      │ │    ₹9,600       │ │    ₹6,400       │        │
│  │                 │ │                 │ │                 │        │
│  │  Food, Health   │ │  Shopping,      │ │  Emergency Fund │        │
│  │  Transport      │ │  Entertainment  │ │  + Goals        │        │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Budget Categories Explained

### 1. Fixed Expenses (Recurring Monthly)
These are **automatic deductions** from your income. They happen whether you track them or not.

| Category | Examples | Typical Range |
|----------|----------|---------------|
| Rent/EMI | House rent, Home loan EMI, Car EMI | 30-40% of income |
| Utilities | Electricity, Water, Internet, Phone | 5-10% of income |
| Other Fixed | Insurance premiums, Subscriptions | 5-10% of income |

**Key Point:** Fixed expenses are NOT tracked in daily spending. They're pre-committed money.

---

### 2. Variable Budget (The 50-30-20 Split)
After fixed expenses, the remaining money is your **Variable Budget**. This follows the 50-30-20 rule:

#### NEEDS (50% of Variable Budget)
**What it is:** Essential variable expenses you can't avoid but can control.

| Subcategory | Examples |
|-------------|----------|
| Food & Groceries | Daily meals, groceries, household supplies |
| Transport | Fuel, metro, auto, cab for work |
| Health | Medicines, doctor visits, gym |

**Connection:** When you log an expense as "Needs" on the Today screen, it deducts from this budget.

---

#### WANTS (30% of Variable Budget)
**What it is:** Lifestyle spending that improves quality of life but isn't essential.

| Subcategory | Examples |
|-------------|----------|
| Shopping | Clothes, electronics, home decor |
| Entertainment | Movies, games, hobbies |
| Dining Out | Restaurants, cafes, food delivery |
| Personal Care | Salon, spa, cosmetics |

**Connection:** When you log an expense as "Wants" on the Today screen, it deducts from this budget.

---

#### SAVINGS (20% of Variable Budget)
**What it is:** Money you set aside for the future.

| Destination | Purpose |
|-------------|---------|
| Emergency Fund | 6-month survival buffer (Safety tab) |
| Short-term Goals | Goals under 1 year |
| Mid-term Goals | Goals 1-5 years |
| Long-term Goals | Goals 5+ years |

**Connection:** When you log an expense as "Savings" on the Today screen, it goes to your Emergency Fund or Goals.

---

## How Expense Categories Connect

When adding an expense, you select both a **category** and a **subcategory**:

```
ADD EXPENSE SCREEN
─────────────────────────────────────────────────────────

┌─────────────┐     ┌───────────────────────────────────┐
│   NEEDS     │ ──> │ Subcategories (from Profile):     │
│  (select)   │     │  • Rent / EMI        (Fixed)      │
└─────────────┘     │  • Utilities & Bills (Fixed)      │
                    │  • Other Fixed       (Fixed)      │
                    │  • Food & Dining     (Variable)   │
                    │  • Transport         (Variable)   │
                    │  • Health & Wellness (Variable)   │
                    └───────────────────────────────────┘

┌─────────────┐     ┌───────────────────────────────────┐
│   WANTS     │ ──> │ Subcategories (from Profile):     │
│  (select)   │     │  • Shopping          (Variable)   │
└─────────────┘     │  • Entertainment     (Variable)   │
                    │  • Other             (Variable)   │
                    └───────────────────────────────────┘

┌─────────────┐     ┌───────────────────────────────────┐
│  SAVINGS    │ ──> │ Destinations:                     │
│  (select)   │     │  • Emergency Fund    (Safety tab) │
└─────────────┘     │  • Goals             (Goals tab)  │
                    └───────────────────────────────────┘
```

### Subcategory Sources

| Category | Subcategory | Defined In | Type |
|----------|-------------|------------|------|
| Needs | Rent / EMI | Profile → Fixed Expenses | Fixed |
| Needs | Utilities & Bills | Profile → Fixed Expenses | Fixed |
| Needs | Other Fixed | Profile → Fixed Expenses | Fixed |
| Needs | Food & Dining | Profile → Variable Budget | Essential |
| Needs | Transport | Profile → Variable Budget | Essential |
| Needs | Health & Wellness | Profile → Variable Budget | Essential |
| Wants | Shopping | Profile → Variable Budget | Lifestyle |
| Wants | Entertainment | Profile → Variable Budget | Lifestyle |
| Wants | Other | Profile → Variable Budget | Lifestyle |
| Savings | Emergency Fund | Safety Tab | Savings |
| Savings | Goals | Goals Tab | Savings |

---

## The Savings Flow

**IMPORTANT: Goals ARE Savings Destinations**

The Goals tab is not a separate feature - it IS the savings category. When you log a "Savings" expense, you choose WHERE it goes:

1. **Emergency Fund** (Safety tab) - Your financial safety net
2. **A Specific Goal** (Goals tab) - Your savings targets

```
SAVINGS EXPENSE (Add Expense Screen)
      │
      │ User selects "Savings" category
      │ Then chooses destination:
      │
      ├──> Emergency Fund ──> Safety Tab (tracks total)
      │
      └──> Goal (e.g., "Goa Trip") ──> Goals Tab (updates goal progress)
```

### How It Works in Code

```dart
// When adding expense, Savings category shows:
// - Emergency Fund (always available)
// - All user-created goals from Goals tab

class SavingsDestination {
  SavingsDestinationType type;  // emergencyFund or goal
  String? goalId;               // ID if it's a goal
  String? goalName;             // Name if it's a goal
}
```

### Example Flow

1. User creates a goal "Goa Trip" (₹30,000) in Goals tab
2. User logs a Savings expense of ₹5,000
3. User selects "Goa Trip" as destination
4. Goal progress updates: ₹5,000 of ₹30,000 (16.7%)
5. The expense appears in spending history as "Savings → Goa Trip"

### Savings Priority

```
┌─────────────────────────────────────────┐
│         SAVINGS DESTINATIONS            │
│                                         │
│   Priority 1: Emergency Fund            │
│   ┌─────────────────────────────────┐   │
│   │  Target: 6 months of essentials │   │
│   │  Current: ₹75,000               │   │
│   │  Goal: ₹200,000                 │   │
│   │  Status: 38% complete           │   │
│   └─────────────────────────────────┘   │
│                                         │
│   User-Created Goals:                   │
│   ┌─────────────────────────────────┐   │
│   │  • Goa Trip (₹5K of ₹30K)       │   │
│   │  • New Laptop (₹20K of ₹80K)    │   │
│   │  • House Down Payment (₹2L/₹20L)│   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## Profile Settings → Budget Connections

| Profile Section | What it Sets | Affects |
|-----------------|--------------|---------|
| **Income** | Monthly take-home salary | Total available money |
| **Fixed Expenses** | Rent, Utilities, Other | Deducted before variable budget |
| **Variable Budget** | Category-wise estimates | Daily spending targets |
| **Savings** | Emergency fund baseline | Safety tab progress |
| **Budget Cycle** | Start day of month | When budget resets |

---

## Calculation Example

**User Setup:**
- Income: ₹50,000
- Rent/EMI: ₹12,000
- Utilities: ₹4,000
- Other Fixed: ₹2,000

**Automatic Calculation:**
```
Total Fixed Expenses = ₹12,000 + ₹4,000 + ₹2,000 = ₹18,000

Variable Budget = Income - Fixed = ₹50,000 - ₹18,000 = ₹32,000

Needs Budget (50%)   = ₹32,000 × 0.50 = ₹16,000
Wants Budget (30%)   = ₹32,000 × 0.30 = ₹9,600
Savings Budget (20%) = ₹32,000 × 0.20 = ₹6,400

Daily Budget (30-day month):
  Total Daily    = ₹32,000 / 30 = ₹1,067/day
  Needs Daily    = ₹16,000 / 30 = ₹533/day
  Wants Daily    = ₹9,600 / 30  = ₹320/day
  Savings Daily  = ₹6,400 / 30  = ₹213/day
```

---

---

## The 10-Step Financial Plan

The Financial Plan ties all features together into a coherent journey:

```
THE 10 STEPS TO FINANCIAL FREEDOM
─────────────────────────────────────────────────────────

Step 1: Know Your Income
        └── Profile → Income Setup

Step 2: Choose Budget Rule (50-30-20)
        └── Automatic allocation

Step 3: List Fixed Needs
        └── Profile → Fixed Expenses

Step 4: Decide Wants
        └── Profile → Variable Budget

Step 5: Set SMART Goals
        └── Goals Tab

Step 6: Build Emergency Fund FIRST
        └── Safety Tab (3-6 months of needs)

Step 7: Handle Debt Smartly
        └── Financial Plan → Debt Screen
        └── Priority: High interest > Medium > Low

Step 8: Start Saving & Investing
        └── 20% of Variable Budget

Step 9: Automate Everything
        └── Auto-debit, Auto-pay, Auto-invest

Step 10: Track Monthly & Adjust
         └── Review spending, adjust goals
```

### Debt Priority System

| Priority | Interest Rate | Action |
|----------|---------------|--------|
| High | >15% | Pay first (credit cards, personal loans) |
| Medium | 8-15% | Pay after high priority |
| Low | <8% | Maintain minimum payments (home loan) |

### Golden Rules
- ❌ Don't invest without emergency fund
- ❌ Don't ignore high-interest debt
- ✅ Increase savings when income rises
- ✅ Keep lifestyle inflation under control
- ✅ Review plan every 3-6 months

---

## Key Principles

### 1. Fixed Expenses are Invisible
- They're deducted automatically at month start
- You don't track them daily
- They reduce your "available" money before you see it

### 2. Variable Budget is What You Control
- This is your daily decision-making money
- The app helps you stay within each category
- Overspending in one category affects others

### 3. Savings is an "Expense" You Pay Yourself
- Treat savings like a bill you must pay
- 20% goes to your future self
- Emergency fund first, then goals

### 4. Goals Have Priority
- Emergency Fund (6 months) = Safety net
- Short-term Goals = Things you need soon
- Long-term Goals = Future wealth building

---

## Data Persistence Requirements

For the connections to work, these must be stored:

| Data | Storage | Used By |
|------|---------|---------|
| Monthly Income | Database | Budget calculations |
| Fixed Expenses (3 types) | Database | Variable budget calculation |
| Expense Records | Database | Spending tracking |
| Goals | Database | Savings allocation |
| Emergency Fund Progress | Database | Safety tab |
| Cycle Settings | Database | Budget period |

---

## UI Connection Points

### Today Screen
- Shows daily budget from Variable Budget
- Category selector (Needs/Wants/Savings) links to respective budgets
- Expense logged deducts from correct category

### Monthly Budget Screen
- Shows 50-30-20 breakdown
- Each category shows: Budget → Spent → Remaining
- Visualizes spending vs plan

### Safety Tab
- Shows Emergency Fund progress
- Connected to Savings category contributions
- Target = 6 months × monthly essentials

### Goals Tab
- Individual savings goals
- Can receive Savings category contributions
- Shows required monthly savings rate

### Profile
- Source of truth for all budget numbers
- Changes here ripple through entire app
