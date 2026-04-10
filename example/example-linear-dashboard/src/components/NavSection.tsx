import type { ReactNode } from 'react';
import { ChevronDown } from '../icons';

interface NavSectionProps {
  label: string;
  children: ReactNode;
}

/**
 * Collapsible section header used in the Sidebar for "Workspace",
 * "Your teams", and "Try". Only the header is rendered here — the
 * collapse state is presentational in this demo (the chevron always
 * points down). Wire real collapse state in a real app.
 */
export function NavSection({ label, children }: NavSectionProps) {
  return (
    <div className="mt-4 flex flex-col">
      <button
        type="button"
        className="mb-0.5 flex h-6 items-center gap-1 pl-2 pr-2 text-caption font-medium text-fg-faint transition-colors hover:text-fg-subtle"
        aria-expanded="true"
      >
        <ChevronDown size={12} />
        <span>{label}</span>
      </button>
      <div className="flex flex-col gap-px">{children}</div>
    </div>
  );
}
