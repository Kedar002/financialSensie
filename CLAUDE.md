# FinanceSensei - Project Guidelines

## The Steve Jobs Design Standard

Every UI element, screen, and interaction in this application must pass the **Steve Jobs Approval Test**. Before implementing ANY screen or UI component, verify it meets these non-negotiable principles:

### The Core Philosophy

> "Design is not just what it looks like and feels like. Design is how it works." - Steve Jobs

> "Simple can be harder than complex: You have to work hard to get your thinking clean to make it simple." - Steve Jobs

---

## UI Design Checklist (MANDATORY)

Before creating ANY screen, component, or visual element, answer these questions. If ANY answer is "no", redesign before implementing.

### 1. Simplicity Test
- [ ] Can a 5-year-old understand how to use this?
- [ ] Have I removed everything that isn't absolutely necessary?
- [ ] Is there any element I can remove without losing functionality?
- [ ] Does every pixel serve a purpose?

### 2. Focus Test
- [ ] Is there ONE clear primary action on this screen?
- [ ] Does the design guide the user's eye naturally?
- [ ] Are secondary actions clearly subordinate?
- [ ] Is the hierarchy immediately obvious?

### 3. Elegance Test
- [ ] Does this feel premium and refined?
- [ ] Is the whitespace generous and intentional?
- [ ] Are the proportions harmonious?
- [ ] Would I be proud to show this in a keynote?

### 4. Consistency Test
- [ ] Does this match the visual language of the rest of the app?
- [ ] Are spacing, colors, and typography consistent?
- [ ] Do similar actions look similar across the app?

---

## Design Principles

### 1. Less is More
- Remove features, not add them
- When in doubt, leave it out
- Every element must justify its existence
- White space is not empty space - it's breathing room

### 2. Typography
- Use ONE font family (system font preferred for performance)
- Maximum 2-3 font sizes per screen
- Font weights: Regular for body, Medium/Semibold for emphasis only
- Never use ALL CAPS except for very short labels
- Line height: 1.4-1.6 for readability

### 3. Color Palette
- Primary: Black (#000000) or near-black (#1A1A1A)
- Background: White (#FFFFFF) or off-white (#FAFAFA)
- Accent: ONE single accent color used sparingly
- Text: Black on white, white on black
- Never use more than 3 colors on any screen
- Gradients: Avoid unless absolutely necessary

### 4. Spacing
- Use consistent spacing multiples (8px base unit)
- Generous padding (minimum 16px from edges)
- Group related items with proximity
- Separate unrelated items with whitespace, not lines

### 5. Icons
- Use outline icons, not filled (unless selected state)
- Consistent stroke width
- Simple, recognizable shapes
- No decorative icons - only functional ones

### 6. Buttons
- Primary: Filled, prominent
- Secondary: Outlined or text-only
- One primary action per screen
- Touch targets: minimum 44x44 points
- Rounded corners: subtle (8-12px), never pill-shaped unless intentional

### 7. Cards and Containers
- Minimal shadows (if any)
- Subtle borders or no borders at all
- Consistent corner radius (8-12px)
- Never nest cards within cards

### 8. Animations
- Quick and subtle (200-300ms)
- Purposeful - guide attention or provide feedback
- Never decorative
- Ease-out for entering, ease-in for exiting

---

## Forbidden Elements

These are BANNED from this project:

- Gradients (unless absolutely essential)
- Drop shadows heavier than 0.1 opacity
- Borders thicker than 1px
- More than 2 font weights on one screen
- Decorative icons or illustrations
- Bright, saturated colors
- Cluttered layouts with more than 5-7 elements
- Carousels or sliders (find a better solution)
- Excessive loading states or skeleton screens
- Toast notifications that aren't critical
- Bottom sheets for simple actions (use inline)
- Nested scrolling containers
- Horizontal scrolling lists (except for specific use cases like date pickers)

---

## Screen Implementation Process

### Before Writing Code:

1. **Sketch the screen on paper** - Can you draw it in 30 seconds?
2. **List every element** - Can you justify each one?
3. **Identify the ONE goal** - What should the user accomplish?
4. **Remove 50% of elements** - Seriously, try it
5. **Review against checklist above**

### During Implementation:

1. Build the minimal version first
2. Add elements only when absence causes confusion
3. Test on actual device, not just emulator
4. Ask: "Would Steve approve?"

### After Implementation:

1. Show to someone unfamiliar with the app
2. Watch them use it without explanation
3. Note any confusion or hesitation
4. Simplify based on observations

---

## File Structure

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   └── constants/
│       └── app_constants.dart
├── features/
│   └── [feature_name]/
│       ├── screens/
│       ├── widgets/
│       └── models/
└── shared/
    └── widgets/
```

---

## Code Style for UI

```dart
// GOOD: Clean, minimal widget
class BalanceCard extends StatelessWidget {
  final double balance;

  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// BAD: Over-decorated widget
// - Unnecessary Container
// - Decorative BoxDecoration
// - Too many nested widgets
// - Gradient background
// - Multiple shadows
```

---

## Final Reminder

Before every commit that includes UI changes, ask yourself:

**"If Steve Jobs saw this screen, would he ship it or throw it across the room?"**

If there's ANY doubt, simplify further.

The goal is not to build a feature-rich app. The goal is to build an app that does a few things **perfectly**.
