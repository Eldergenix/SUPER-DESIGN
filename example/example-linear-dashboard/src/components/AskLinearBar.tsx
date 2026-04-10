import { History, QuestionCircle } from '../icons';

/**
 * Floating cluster in the bottom-right corner: an "Ask Linear"
 * affordance (question mark + label) and a history icon. Positioned
 * absolute within the main content area so it stays pinned to the
 * viewport corner regardless of scroll.
 */
export function AskLinearBar() {
  return (
    <div className="pointer-events-none absolute bottom-4 right-4 flex items-center gap-2">
      <button
        type="button"
        className="pointer-events-auto flex h-7 items-center gap-1.5 rounded-md border border-border bg-bg-panel px-2 text-caption font-medium text-fg-subtle shadow-card transition-colors hover:text-fg-muted"
      >
        <QuestionCircle size={12} />
        <span>Ask Linear</span>
      </button>
      <button
        type="button"
        className="pointer-events-auto flex h-7 w-7 items-center justify-center rounded-md border border-border bg-bg-panel text-fg-subtle shadow-card transition-colors hover:text-fg-muted"
        aria-label="History"
      >
        <History size={12} />
      </button>
    </div>
  );
}
