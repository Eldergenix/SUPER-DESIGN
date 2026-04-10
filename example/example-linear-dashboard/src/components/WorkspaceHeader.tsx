import { ChevronDown, Compose, Search } from '../icons';

interface WorkspaceHeaderProps {
  name: string;
  /** Two-letter abbreviation shown in the avatar. "NF" for Nexis Foundation. */
  initials: string;
}

export function WorkspaceHeader({ name, initials }: WorkspaceHeaderProps) {
  return (
    <div className="flex h-12 items-center gap-1 px-2">
      {/* Workspace switcher */}
      <button
        type="button"
        className="group flex min-w-0 flex-1 items-center gap-2 rounded-md pl-1 pr-1.5 py-1 text-label text-fg transition-colors hover:bg-surface"
        aria-label={`Switch workspace (current: ${name})`}
      >
        <span
          className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md text-[10px] font-semibold tracking-tight text-fg"
          style={{
            background:
              'linear-gradient(135deg, var(--color-brand-500), var(--color-success-500))',
          }}
          aria-hidden
        >
          {initials}
        </span>
        <span className="truncate font-medium">{name}</span>
        <ChevronDown size={14} className="shrink-0 text-fg-faint" />
      </button>

      {/* Action icons on the right side of the header */}
      <button
        type="button"
        className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md text-fg-muted transition-colors hover:bg-surface hover:text-fg"
        aria-label="Search"
      >
        <Search />
      </button>
      <button
        type="button"
        className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md text-fg-muted transition-colors hover:bg-surface hover:text-fg"
        aria-label="Create new"
      >
        <Compose />
      </button>
    </div>
  );
}
