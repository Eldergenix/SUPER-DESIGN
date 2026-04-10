import type { ReactNode } from 'react';

interface NavItemProps {
  icon: ReactNode;
  label: string;
  /** When true, the row gets the "selected" treatment (fg text on a
   *  raised surface). Used for the highlighted Projects row under
   *  Nexis Foundation-Deve… in the screenshot. */
  selected?: boolean;
  /** Indent depth in pixels. The team's Issues/Projects/Views children
   *  use 16px. Top-level items use 0. */
  indent?: number;
  /** Optional numeric badge (for Inbox counts, etc.). Not shown in the
   *  reference screenshot but kept here so the component is reusable. */
  count?: number;
}

export function NavItem({
  icon,
  label,
  selected = false,
  indent = 0,
  count,
}: NavItemProps) {
  // Button so keyboard focus + :focus-visible works naturally. The
  // semantic role is a nav link in a real app — wrapping in <a> would
  // also be valid. Using button here to keep this a pure visual demo.
  return (
    <button
      type="button"
      aria-current={selected ? 'page' : undefined}
      className={[
        'group flex h-7 w-full items-center gap-2 rounded-md pr-2 text-label transition-colors',
        selected
          ? 'bg-surface text-fg'
          : 'text-fg-muted hover:bg-surface hover:text-fg',
      ].join(' ')}
      style={{ paddingLeft: `calc(0.5rem + ${indent}px)` }}
    >
      <span className="flex h-4 w-4 shrink-0 items-center justify-center text-fg-faint group-hover:text-fg-muted">
        {icon}
      </span>
      <span className="truncate font-medium">{label}</span>
      {typeof count === 'number' && (
        <span className="ml-auto text-caption text-fg-faint tabular-nums">
          {count}
        </span>
      )}
    </button>
  );
}
