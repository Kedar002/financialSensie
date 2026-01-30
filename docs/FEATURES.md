# FinanceSensei - Features Documentation

## Budget Module

### Needs Tab
**Status:** Implemented (UI only, mock data)

The Needs tab displays essential monthly expenses that are non-negotiable.

**Components:**
- Header with menu and action icons
- Title card showing total needs amount
- Category grid (2 columns)

**Actions:**
- Template icon (`file_copy_outlined`) - Opens templates sheet
- Add icon (`add`) - Opens add category sheet
- Tap category - Opens edit category sheet

---

### Templates Feature
**Status:** Implemented (UI only, mock data)

Allows users to save and reuse recurring monthly expense patterns.

**Files:**
- `lib/features/budget/sheets/templates_sheet.dart` - Main templates list
- `lib/features/budget/sheets/template_detail_sheet.dart` - View/import template
- `lib/features/budget/sheets/template_edit_sheet.dart` - Create/edit template

**Flow:**
1. Tap template icon in Needs tab header
2. Templates sheet shows saved templates
3. Tap template to view details and import
4. "Create Template" to add new template

**Template Structure:**
```dart
{
  'name': 'Monthly Essentials',
  'items': [
    {'name': 'Rent', 'amount': 8000},
    {'name': 'Groceries', 'amount': 3000},
    ...
  ],
}
```

**Screens:**

1. **Templates Sheet**
   - List of saved templates
   - Each shows name and total amount
   - "Create Template" button

2. **Template Detail Sheet**
   - Template name as title
   - List of items with amounts
   - Total calculation
   - "Import to Needs" primary action
   - "Edit Template" secondary action

3. **Template Edit Sheet**
   - Template name input
   - Dynamic list of items (name + amount)
   - Add/remove items
   - Save button
   - Delete option (edit mode only)

---

### Wants Tab
**Status:** Implemented (UI only, mock data)

Displays discretionary spending categories.

---

### Savings Tab
**Status:** Implemented (UI only, mock data)

Displays savings goals with progress tracking.

---

### Expenses Tab
**Status:** Implemented (UI only, mock data)

Shows monthly summary and recent transactions.

---

### Statistics Tab
**Status:** Implemented (UI only, mock data)

Displays spending trends and comparisons.
