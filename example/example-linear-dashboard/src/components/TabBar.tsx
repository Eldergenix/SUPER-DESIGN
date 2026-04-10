import { Columns, Plus, Sliders, SplitView, Stack } from '../icons';

/**
 * Tab/filter strip immediately below the TopBar. Left side has the
 * "All projects" selected pill with a small stack icon next to it
 * (representing "view group" I think — Linear shows this throughout
 * its filtered views). Right side has three small utility icons:
 * filter (sliders), column adjuster, split view toggle, and a Plus.
 */
export function TabBar() {
  return (
    <div className="flex h-11 shrink-0 items-center gap-1 border-b border-border px-4">
      {/* Selected pill */}
      <button
        type="button"
        className="flex h-7 items-center gap-1.5 rounded-md border border-border bg-surface px-2.5 text-label font-medium text-fg transition-colors hover:bg-surface-raised"
        aria-pressed="true"
      >
        All projects
      </button>
      <button
        type="button"
        className="flex h-7 w-7 items-center justify-center rounded-md text-fg-faint transition-colors hover:bg-surface hover:text-fg-muted"
        aria-label="Group view"
      >
        <Stack size={14} />
      </button>

      <div className="flex-1" />

      {/* Right-side utility icons */}
      <button
        type="button"
        className="flex h-7 w-7 items-center justify-center rounded-md text-fg-faint transition-colors hover:bg-surface hover:text-fg-muted"
        aria-label="Filter"
      >
        <Sliders size={14} />
      </button>
      <button
        type="button"
        className="flex h-7 w-7 items-center justify-center rounded-md text-fg-faint transition-colors hover:bg-surface hover:text-fg-muted"
        aria-label="Adjust columns"
      >
        <Columns size={14} />
      </button>
      <button
        type="button"
        className="flex h-7 w-7 items-center justify-center rounded-md text-fg-faint transition-colors hover:bg-surface hover:text-fg-muted"
        aria-label="Toggle split view"
      >
        <SplitView size={14} />
      </button>
      <button
        type="button"
        className="flex h-7 w-7 items-center justify-center rounded-md text-fg-faint transition-colors hover:bg-surface hover:text-fg-muted"
        aria-label="New project"
      >
        <Plus size={14} />
      </button>
    </div>
  );
}
