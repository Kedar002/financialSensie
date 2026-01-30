# Budget Module — Design Specification

## UX Philosophy

### Navigation Mental Model

**Drawer (Module Level)**
- Switches context entirely
- User leaves one "app" and enters another
- Infrequent action — once per session typically
- Hidden by default, accessed intentionally

**Bottom Navigation (Section Level)**
- Stays within the Budget module
- Quick switching between related views
- Always visible, always accessible
- Visually quiet — supports, not dominates

### The Needs / Wants / Savings Mental Model

This is not arbitrary. It reflects how money actually works:

```
INCOME (what comes in)
    ↓
EXPENSES (what goes out)
    ↓
┌─────────────┬─────────────┬─────────────┐
│   NEEDS     │   WANTS     │   SAVINGS   │
│             │             │             │
│ Essentials  │ Lifestyle   │ Future self │
│ Non-negotia │ Negotiable  │ Intentional │
│             │             │             │
│ Rent        │ Dining out  │ Emergency   │
│ Groceries   │ Netflix     │ Retirement  │
│ Insurance   │ Shopping    │ Vacation    │
└─────────────┴─────────────┴─────────────┘
```

**Why separate tabs?**
- Forces conscious categorization at entry time
- Makes spending patterns visible without charts
- Each tab has different emotional weight
- Savings gets equal billing — not an afterthought

---

## Design System

### Colors
```
Background:         #FFFFFF
Surface:            #F9F9F9
Text Primary:       #000000
Text Secondary:     #6B6B6B
Text Tertiary:      #999999
Divider:            #E5E5E5
Accent (minimal):   #007AFF (iOS blue, used sparingly)
Destructive:        #FF3B30
Positive:           #34C759
```

### Typography
```
Large Title:    28pt Semibold   (screen titles)
Title:          20pt Semibold   (section headers)
Headline:       17pt Semibold   (list item primary)
Body:           17pt Regular    (list item secondary)
Subhead:        15pt Regular    (supporting text)
Caption:        13pt Regular    (tertiary info)
Amount Large:   34pt Semibold   (hero numbers)
Amount Medium:  22pt Semibold   (card amounts)
```

### Spacing
```
Screen horizontal padding:  16pt
Section vertical spacing:   32pt
List item height:          60pt minimum
Touch target:              44pt minimum
```

### Bottom Navigation Bar
- Height: 49pt (iOS standard)
- Background: White with hairline top border
- Icons: SF Symbols, 24pt, outline style
- Labels: 10pt, always visible
- Selected: Black icon + label
- Unselected: #999999 icon + label
- No background color on selection — just color change

---

## Screen Designs

---

### Screen 1: Expenses Tab (Budget Home)

**Purpose:** Show where you stand this month — money in, money out, what remains.

**Visual Hierarchy:**
1. FIRST: Remaining amount (the number you care about)
2. SECOND: Income vs Spent comparison
3. THIRD: Recent transactions

**Layout:**
```
┌─────────────────────────────────────┐
│ ≡                          [+ Add]  │ ← Drawer + Add button
├─────────────────────────────────────┤
│                                     │
│  January 2025                       │ ← Month (tappable to change)
│                                     │
│  $2,450                             │ ← REMAINING (largest)
│  remaining this month               │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Income          $5,000             │
│  Spent           $2,550             │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Recent                             │
│                                     │
│  Today                              │
│  ┌─────────────────────────────────┐│
│  │ Groceries          -$45.20      ││
│  │ Needs                           ││
│  ├─────────────────────────────────┤│
│  │ Coffee              -$4.50      ││
│  │ Wants                           ││
│  └─────────────────────────────────┘│
│                                     │
│  Yesterday                          │
│  ┌─────────────────────────────────┐│
│  │ Salary           +$5,000        ││
│  │ Income                          ││
│  └─────────────────────────────────┘│
│                                     │
├─────────────────────────────────────┤
│  Expenses   Needs   Wants   Savings │ ← Bottom nav
└─────────────────────────────────────┘
```

**Interactions:**
- Tap month → month picker
- Tap [+ Add] → action sheet (Add Income / Add Expense)
- Tap transaction → detail/edit view
- Swipe transaction left → delete with undo
- Pull down → refresh

**What's NOT shown:**
- Charts or graphs (the numbers are enough)
- Category breakdowns (that's in Needs/Wants/Savings tabs)
- Budget progress bars (too gamified)
- Tips or suggestions (patronizing)

---

### Screen 2: Income Management

**Purpose:** Manage multiple income sources. See what's coming in.

**Access:** Tap "Income" row on Expenses tab, or via settings

**Layout:**
```
┌─────────────────────────────────────┐
│ ←  Income Sources          [+ Add]  │
├─────────────────────────────────────┤
│                                     │
│  Total This Month                   │
│  $5,850                             │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Salary                          ││
│  │ $5,000 · Monthly                ││ ← Primary income
│  ├─────────────────────────────────┤│
│  │ Freelance                       ││
│  │ $850 · Variable                 ││ ← Secondary
│  └─────────────────────────────────┘│
│                                     │
│                                     │
└─────────────────────────────────────┘
```

**Add/Edit Income Source (Sheet):**
```
┌─────────────────────────────────────┐
│  ─────                              │
│                                     │
│  Add Income Source                  │
│                                     │
│  Name                               │
│  ┌─────────────────────────────────┐│
│  │ Salary                          ││
│  └─────────────────────────────────┘│
│                                     │
│  Amount                             │
│  ┌─────────────────────────────────┐│
│  │ $ 5,000                         ││
│  └─────────────────────────────────┘│
│                                     │
│  Frequency                          │
│  ○ Monthly  ○ Bi-weekly  ○ Variable │
│                                     │
│  ┌─────────────────────────────────┐│
│  │            Save                 ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

**Interactions:**
- Tap source → edit sheet
- Swipe left → delete with confirmation
- Tap + Add → new source sheet

---

### Screen 3: Needs Tab

**Purpose:** Track essential spending. Things you can't skip.

**Mental Model:** These are non-negotiable expenses — rent, utilities, groceries, insurance.

**Layout:**
```
┌─────────────────────────────────────┐
│ ≡                     January 2025  │
├─────────────────────────────────────┤
│                                     │
│  Needs                              │
│  $1,200 spent                       │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Categories                [Edit]   │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Rent                   $800     ││
│  │ 1 transaction                   ││
│  ├─────────────────────────────────┤│
│  │ Groceries              $245     ││
│  │ 8 transactions                  ││
│  ├─────────────────────────────────┤│
│  │ Utilities              $155     ││
│  │ 3 transactions                  ││
│  └─────────────────────────────────┘│
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Recent in Needs                    │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Whole Foods           -$52.30   ││
│  │ Groceries · Today               ││
│  └─────────────────────────────────┘│
│                                     │
│                           [+ Add]   │
├─────────────────────────────────────┤
│  Expenses   Needs   Wants   Savings │
└─────────────────────────────────────┘
```

**Interactions:**
- Tap category row → drill into category transactions
- Tap [Edit] → manage categories
- Tap [+ Add] → add expense (pre-selected as "Needs")
- Tap transaction → edit

**Default Categories (Needs):**
- Rent/Mortgage
- Groceries
- Utilities
- Insurance
- Transport
- Healthcare

---

### Screen 4: Wants Tab

**Purpose:** Track discretionary spending. Things you choose.

**Mental Model:** These are lifestyle choices — dining out, entertainment, subscriptions.

**Layout:** Same structure as Needs tab.

**Default Categories (Wants):**
- Dining Out
- Entertainment
- Shopping
- Subscriptions
- Personal Care
- Hobbies

**Key Difference:** The "spent" amount here is money you could redirect elsewhere. The UI doesn't judge, but the separation creates awareness.

---

### Screen 5: Savings Tab

**Purpose:** Track money set aside for future goals. Intentional, not accidental.

**Mental Model:** This is not leftover money. This is committed money.

**Layout:**
```
┌─────────────────────────────────────┐
│ ≡                     January 2025  │
├─────────────────────────────────────┤
│                                     │
│  Savings                            │
│  $650 this month                    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Goals                     [Edit]   │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Emergency Fund                  ││
│  │ $400 this month                 ││
│  │ $4,800 total                    ││
│  ├─────────────────────────────────┤│
│  │ Vacation                        ││
│  │ $150 this month                 ││
│  │ $900 total                      ││
│  ├─────────────────────────────────┤│
│  │ Retirement                      ││
│  │ $100 this month                 ││
│  │ $2,400 total                    ││
│  └─────────────────────────────────┘│
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Contributions                      │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Emergency Fund        +$400     ││
│  │ Jan 5                           ││
│  └─────────────────────────────────┘│
│                                     │
│                           [+ Add]   │
├─────────────────────────────────────┤
│  Expenses   Needs   Wants   Savings │
└─────────────────────────────────────┘
```

**Key Difference:**
- Shows cumulative totals (not just this month)
- Uses "this month" language, not "spent"
- Feels like progress, not depletion

**Default Categories (Savings):**
- Emergency Fund
- Retirement
- Vacation
- Large Purchase
- Education
- Investments

---

### Screen 6: Add Expense Flow

**Purpose:** Log a transaction quickly. Under 10 seconds.

**Access:** [+ Add] button or FAB

**Step 1: Amount**
```
┌─────────────────────────────────────┐
│  Cancel                        Next │
├─────────────────────────────────────┤
│                                     │
│                                     │
│            $0.00                    │ ← Large, centered
│                                     │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  1  │  2  │  3  │              ││
│  │  4  │  5  │  6  │   Keypad     ││
│  │  7  │  8  │  9  │              ││
│  │  .  │  0  │  ⌫  │              ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

**Step 2: Categorize**
```
┌─────────────────────────────────────┐
│  Back                         Save  │
├─────────────────────────────────────┤
│                                     │
│  $45.20                             │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Type                               │
│  ┌─────────┐ ┌─────────┐ ┌────────┐│
│  │  Needs  │ │  Wants  │ │ Saving ││
│  └─────────┘ └─────────┘ └────────┘│
│                                     │
│  Category                           │
│  ┌─────────────────────────────────┐│
│  │ Groceries                     > ││
│  └─────────────────────────────────┘│
│                                     │
│  Note (optional)                    │
│  ┌─────────────────────────────────┐│
│  │ Whole Foods run                 ││
│  └─────────────────────────────────┘│
│                                     │
│  Date                      Today >  │
│                                     │
└─────────────────────────────────────┘
```

**Flow Logic:**
- Amount → Type (Needs/Wants/Savings) → Category → Save
- Type selection filters available categories
- Most recent category pre-selected for speed
- Date defaults to today

---

### Screen 7: Category Management

**Purpose:** Customize categories to match your life.

**Access:** [Edit] button on Needs/Wants/Savings screens

**Layout:**
```
┌─────────────────────────────────────┐
│ ←  Edit Needs Categories    [+ Add] │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │ ≡ Rent/Mortgage               > ││
│  ├─────────────────────────────────┤│
│  │ ≡ Groceries                   > ││
│  ├─────────────────────────────────┤│
│  │ ≡ Utilities                   > ││
│  ├─────────────────────────────────┤│
│  │ ≡ Insurance                   > ││
│  └─────────────────────────────────┘│
│                                     │
│  Drag to reorder                    │
│                                     │
└─────────────────────────────────────┘
```

**Add/Edit Category (Sheet):**
```
┌─────────────────────────────────────┐
│  ─────                              │
│                                     │
│  Add Category                       │
│                                     │
│  Name                               │
│  ┌─────────────────────────────────┐│
│  │ Pet Supplies                    ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │            Save                 ││
│  └─────────────────────────────────┘│
│                                     │
│      Delete Category                │ ← Red text, only for edit
│                                     │
└─────────────────────────────────────┘
```

**Rules:**
- Categories are just names — no icons, no colors
- Deleting category moves transactions to "Other"
- Reorder via drag handles
- Default categories can be hidden, not deleted

---

### Screen 8: Empty States

**First Launch (No Data):**
```
┌─────────────────────────────────────┐
│ ≡                                   │
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
│                                     │
│         Set up your income          │
│                                     │
│   Add your income sources to start  │
│   tracking where your money goes.   │
│                                     │
│      ┌───────────────────────┐      │
│      │     Add Income        │      │
│      └───────────────────────┘      │
│                                     │
│                                     │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  Expenses   Needs   Wants   Savings │
└─────────────────────────────────────┘
```

**No Transactions Yet (After Income Setup):**
```
│                                     │
│       No expenses this month        │
│                                     │
│   Tap + to add your first expense   │
│                                     │
```

**Empty Category:**
```
│                                     │
│     No groceries expenses yet       │
│                                     │
│     Transactions you categorize     │
│     as Groceries will appear here   │
│                                     │
```

**Empty Savings:**
```
│                                     │
│      Start building your future     │
│                                     │
│    Add a savings goal to begin      │
│    tracking what you set aside.     │
│                                     │
│      ┌───────────────────────┐      │
│      │    Add Savings Goal   │      │
│      └───────────────────────┘      │
│                                     │
```

---

### Screen 9: Error States

**Network Error (if ever needed):**
- Subtle banner at top: "Unable to sync. Changes saved locally."
- Auto-dismiss when connection restored

**Save Failed:**
- Inline under save button: "Couldn't save. Tap to try again."
- Red text, but not alarming

**Validation Errors:**
- Inline, below the field
- "Enter an amount" / "Enter a name"
- Field does NOT turn red

**Delete Confirmation:**
```
┌─────────────────────────────────────┐
│                                     │
│      Delete "Pet Supplies"?         │
│                                     │
│  2 transactions will be moved to    │
│  "Other" category.                  │
│                                     │
│  ┌────────────┐ ┌────────────┐     │
│  │   Cancel   │ │   Delete   │     │
│  └────────────┘ └────────────┘     │
│                   (red text)        │
└─────────────────────────────────────┘
```

---

## Interaction Summary

| Action | Gesture | Feedback |
|--------|---------|----------|
| Open drawer | Tap menu icon | Drawer slides in |
| Switch tab | Tap bottom nav | Instant switch |
| Add item | Tap + button | Sheet slides up |
| Edit item | Tap row | Sheet slides up |
| Delete item | Swipe left | Red delete button |
| Confirm delete | Tap delete | Toast with undo |
| Reorder | Long press + drag | Haptic feedback |
| Pull refresh | Pull down | Subtle spinner |

---

## Data Model Summary

```
Income
  - id
  - name (e.g., "Salary")
  - amount
  - frequency (monthly, bi-weekly, variable)

Category
  - id
  - name
  - type (needs, wants, savings)
  - sortOrder
  - isDefault
  - isHidden

Transaction
  - id
  - amount
  - note
  - categoryId
  - date
  - type (income, expense, savings)

SavingsGoal
  - id
  - name
  - totalSaved (cumulative)
```

---

## What This Design Intentionally Avoids

1. **No budgets/limits per category** — Too complex for v1, creates guilt
2. **No charts** — Numbers tell the story
3. **No percentage breakdowns** — Mental math is fine
4. **No badges or streaks** — Finance is not a game
5. **No AI insights** — Patronizing
6. **No social features** — Finance is private
7. **No recurring transaction automation** — Too much magic
8. **No currency conversion** — Scope creep
9. **No multi-account support** — Complexity bomb

---

## Summary

The Budget module answers three questions:
1. **How much do I have?** (Expenses tab → Remaining)
2. **Where did it go?** (Needs/Wants tabs → Categories)
3. **What am I building?** (Savings tab → Goals)

Every screen serves one of these questions. Nothing more.
