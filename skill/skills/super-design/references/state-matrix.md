# Component State Matrix + Accessibility Requirements

**Core principle:** A component is INCOMPLETE until every required state is defined, documented, and rendered in a visible preview. No component ships without a states gallery.

## Universal state vocabulary

`default` · `hover` · `focus` · `focus-visible` · `active / pressed` · `disabled` · `loading` · `error` · `success` · `readonly` · `selected` · `checked` · `indeterminate` · `dragging` · `dropping` · `placeholder-shown`

Per state, define the visual delta using these tokens (write "inherits default" if unchanged):
`bg` · `fg` · `border` · `shadow` · `outline` · `transform` · `opacity` · `cursor` · `transition`

## Per-component state requirements

| Component | Required states | Key visual deltas |
|---|---|---|
| **Button** | default, hover, focus-visible, active, disabled, loading | hover: bg +8% lum; active: `transform: scale(0.97)`; focus-visible: 3px outline 2px offset 3:1 contrast; disabled: opacity 0.5, `cursor: not-allowed`; loading: spinner replaces label, width locked, `aria-busy=true` |
| **IconButton** | default, hover, focus-visible, active, disabled | Same as Button minus loading; always 44×44 min |
| **Input** | default, hover, focus, filled, error, disabled, readonly | focus: 2px border accent + focus-ring shadow; error: `border-danger` + helper text; readonly: `bg-muted`; disabled: opacity 0.6 |
| **Textarea** | default, hover, focus, filled, error, disabled, readonly | Same as Input; min-height 4 rows; resize: vertical only |
| **Checkbox** | default, hover, checked, indeterminate, disabled, focus-visible | checked: bg-accent + check glyph; indeterminate: dash glyph; focus-visible: 3px ring offset 2px |
| **Radio** | default, hover, checked, disabled, focus-visible | checked: inner dot bg-accent; keyboard: arrow keys within group |
| **Switch** | off, on, disabled, focus-visible | on: bg-accent + thumb `translateX`; transition 150ms ease-out |
| **Select** | closed, open, selected-option, disabled, focus-visible | open: chevron `rotate(180deg)`, panel shadow-lg; selected: bg-accent-subtle + check icon |
| **Combobox** | closed, open, filtered, no-results, disabled, focus-visible | Same as Select plus filter state + empty message |
| **Slider** | default, hover, dragging, disabled, focus-visible | dragging: cursor grabbing, thumb shadow-md |
| **Tabs** | default, hover, active, disabled, focus-visible | active: 2px underline accent + fg-primary; focus-visible: outline on tab only |
| **Link** | default, hover, visited, focus-visible, active | hover: underline + color shift; visited: distinct hue; focus-visible: 3px outline |
| **Card (interactive)** | default, hover, selected, focus-within, disabled | hover: shadow-md + `translateY(-2px)`; selected: 2px border accent + bg tint |
| **Menu item** | default, hover, focused, selected, disabled | focused: bg-raised; selected: check icon + bg-accent-subtle |
| **Tooltip** | hidden, visible | enter: 75ms fade; 500ms delay before show, 0ms on hide |
| **Dialog** | closed, opening, open, closing | open: backdrop fade 200ms, dialog scale from 0.95, focus trap, return focus on close |
| **Toast** | enter, visible, exit | enter: slide+fade from edge 300ms; auto-dismiss 5s unless `role=alert` |

## Screen-level states (required for every data view)

`loading` (skeleton) · `empty` · `error` · `success` · `content`

**Never ship a data view without all five.** Empty states are first-class deliverables: illustration + headline + body + primary CTA.

## Skeleton loading rules

- Use ONLY on containers/data components (cards, tables, lists, media)
- **Do NOT** skeletonize buttons, inputs, checkboxes, toggles — use spinners or disabled state
- Skeleton dimensions MUST match final content (prevent Cumulative Layout Shift)
- Subtle shimmer at 1.5–2s cycle; remove progressively as data arrives
- Swap to content in < 1s → spinner; > 1s → skeleton

## Optimistic UI rules

- Apply only to low-risk, reversible, frequent actions (like, bookmark, toggle, reorder, mark done)
- Commit UI immediately; reconcile on server response
- On failure: revert + inline error toast + retry affordance
- Never optimistic for: payments, destructive actions, identity changes

## WCAG 2.2 focus gate (SC 2.4.11 AA / 2.4.13 AAA)

- Focus indicator area ≥ perimeter of 2 CSS px around the control
- **Standard: 3px outline + 2px offset** (safety margin over the 2px minimum)
- **3:1 contrast** between focused and unfocused pixels AND against adjacent colors
- Never `outline: none` without an equal or greater replacement
- Use `:focus-visible` (not `:focus`) to avoid mouse-click outlines

```css
:focus-visible {
  outline: 3px solid var(--color-focus-ring);
  outline-offset: 2px;
  border-radius: inherit;
}
```

## ARIA checklist

| Component | Role | Key ARIA | Keyboard |
|---|---|---|---|
| Button | `button` | `aria-pressed` (toggle), `aria-busy` (loading), `aria-disabled` | Enter, Space |
| Input | (native) | `aria-invalid`, `aria-describedby` (error/help), `aria-required` | Tab, Type |
| Checkbox | `checkbox` | `aria-checked` (true/false/mixed), `aria-labelledby` | Space toggles |
| Radio group | `radiogroup`/`radio` | `aria-checked`, `aria-labelledby` | Arrow keys move+select |
| Card (interactive) | `button`/`link` | `aria-label` if no text | Enter activates |
| Link | `link` (native) | `aria-current` (nav) | Enter |
| Select/Combobox | `combobox` + `listbox` | `aria-expanded`, `aria-controls`, `aria-activedescendant`, `aria-haspopup="listbox"` | Down opens, Arrows navigate, Enter selects, Esc closes, Type to filter |
| Tabs | `tablist`/`tab`/`tabpanel` | `aria-selected`, `aria-controls`, `aria-labelledby` | Arrow keys switch, Home/End, Tab exits |
| Switch | `switch` | `aria-checked` | Space toggles |
| Dialog | `dialog` | `aria-modal="true"`, `aria-labelledby` | Esc closes, focus trap, return focus on close |

**Global keyboard rules:**
- **Tab** moves forward between widgets
- **Shift+Tab** moves backward
- **Arrow keys** navigate WITHIN composite widgets (never Tab)
- **Escape** dismisses overlays / cancels
- **Home/End** jump to first/last in composites

## Quality gate (blocks merge / blocks edit)

A component is INCOMPLETE and CANNOT ship unless:

1. Every required state from the matrix is defined with all visual tokens
2. A states gallery renders every state visibly
3. Focus-visible meets 3px + 3:1 contrast, verified
4. ARIA roles/attrs present; axe-core reports 0 violations
5. Keyboard navigation matches the table (tested without mouse)
6. For data views: loading (skeleton), empty, error, success all designed
7. `prefers-reduced-motion` honored
8. Screenshots of all states exist
