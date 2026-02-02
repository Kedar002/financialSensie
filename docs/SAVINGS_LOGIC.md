# Savings Logic Documentation

## Overview

The app handles two distinct savings operations with different impacts on budget cycles.

---

## Savings Operations

### 1. Add Money to Savings (Deposit)

**When:** User taps "Add Money" on a savings goal

**What happens:**
- Creates an expense record with type `'savings'`
- Decreases cycle's remaining balance
- Increases savings goal's `saved` amount
- Counts toward cycle's total spent
- Appears in transactions as an expense

**Database changes:**
```
expenses table:
  + New row: type='savings', amount=X

savings_goals table:
  - saved: decreased by X (goal progress increases)
```

**Impact on cycle:**
| Metric | Impact |
|--------|--------|
| Total Spent | +X |
| Remaining Balance | -X |
| Savings Added (cycle stats) | +X |

---

### 2. Withdraw from Savings (Withdrawal)

**When:** User withdraws money from a savings goal

**What happens:**
- Creates an expense record with type `'savings_withdrawal'`
- Does NOT affect cycle's remaining balance
- Does NOT count toward total spent
- Decreases savings goal's `saved` amount
- Appears in transactions as a record only

**Database changes:**
```
expenses table:
  + New row: type='savings_withdrawal', amount=X

savings_goals table:
  - saved: increased by X (goal progress decreases)
```

**Impact on cycle:**
| Metric | Impact |
|--------|--------|
| Total Spent | No change |
| Remaining Balance | No change |
| Savings Added (cycle stats) | No change |

---

## Rationale

### Why deposits are expenses:
- Money saved comes from current cycle's income
- It's an allocation decision (income → savings)
- Should reduce available spending money

### Why withdrawals don't affect budget:
- Money withdrawn was already saved in previous cycles
- It's not new income for the current cycle
- Recording it tracks when money was accessed
- Keeps budget cycle calculations accurate

---

## Transaction Display

| Type | Display Style | Amount Prefix | Label |
|------|---------------|---------------|-------|
| `savings` | Expense (normal) | `-₹` | "Savings" |
| `savings_withdrawal` | Withdrawal (green) | `+₹` | "Withdrawal" |

---

## Expense Types Reference

| Type | Description | Affects Spent? | Affects Balance? |
|------|-------------|----------------|------------------|
| `needs` | Essential expenses | ✓ Yes | ✓ Yes |
| `wants` | Discretionary expenses | ✓ Yes | ✓ Yes |
| `savings` | Money added to savings | ✓ Yes | ✓ Yes |
| `savings_withdrawal` | Money withdrawn from savings | ✗ No | ✗ No |
| `income` | Income transactions | ✗ No (adds) | ✗ No (adds) |

---

## Code Locations

- **ExpenseRepository:** `lib/core/repositories/expense_repository.dart`
  - `getTotalSpent()` - excludes `savings_withdrawal`
  - `getSpentByType()` - excludes `savings_withdrawal`

- **Savings Tab:** `lib/features/budget/tabs/savings_tab.dart`
  - Add money flow (deposit)
  - Withdraw money flow (withdrawal)

- **Transaction Display:** Various screens
  - Shows withdrawal with distinct styling

---

## Example Flow

### User saves ₹5,000:
1. Income: ₹50,000
2. User adds ₹5,000 to "Emergency Fund"
3. Expense created: type='savings', amount=500000 (paise)
4. Remaining balance: ₹50,000 - ₹5,000 = ₹45,000
5. Emergency Fund saved: +₹5,000

### User withdraws ₹2,000:
1. Current remaining: ₹45,000
2. User withdraws ₹2,000 from "Emergency Fund"
3. Expense created: type='savings_withdrawal', amount=200000 (paise)
4. Remaining balance: ₹45,000 (unchanged)
5. Emergency Fund saved: -₹2,000
6. Transaction recorded for history
