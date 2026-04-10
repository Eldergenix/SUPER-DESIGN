import {
  ChevronDown,
  Cube,
  GitHub,
  Home,
  Import,
  Inbox,
  MoreHorizontal,
  QuestionCircle,
  Stack,
  Target,
  UserPlus,
} from '../icons';
import { NavItem } from './NavItem';
import { NavSection } from './NavSection';
import { WorkspaceHeader } from './WorkspaceHeader';

/**
 * The full left rail. 232px fixed width, panel-dark background with
 * a thin right border. Structure mirrors the reference screenshot
 * exactly:
 *   Workspace header (NF avatar + name + search + compose)
 *   Inbox
 *   My issues
 *   Workspace ▼
 *     Projects · Views · More
 *   Your teams ▼
 *     Nexis Foundation-Deve… ▼  (indented children)
 *       Issues · Projects (selected) · Views
 *   Try ▼
 *     Import issues · Invite people · Connect GitHub
 *   (flex-grow spacer)
 *   ? Help (bottom-left)
 */
export function Sidebar() {
  return (
    <aside
      className="flex h-full w-[232px] shrink-0 flex-col border-r border-border bg-bg-panel"
      aria-label="Workspace navigation"
    >
      <WorkspaceHeader name="Nexis Founda…" initials="NF" />

      <nav className="flex flex-1 flex-col overflow-y-auto px-2 pb-2">
        {/* Top-level links */}
        <div className="flex flex-col gap-px">
          <NavItem icon={<Inbox />} label="Inbox" />
          <NavItem icon={<Target />} label="My issues" />
        </div>

        {/* Workspace */}
        <NavSection label="Workspace">
          <NavItem icon={<Cube />} label="Projects" />
          <NavItem icon={<Stack />} label="Views" />
          <NavItem icon={<MoreHorizontal />} label="More" />
        </NavSection>

        {/* Your teams */}
        <NavSection label="Your teams">
          {/* Team row with its own chevron — rendered as a NavItem with a
              custom icon wrapper so the home icon can be tinted pink to
              match the team color in the screenshot. */}
          <button
            type="button"
            className="group flex h-7 w-full items-center gap-2 rounded-md pl-2 pr-2 text-label font-medium text-fg transition-colors hover:bg-surface"
            aria-expanded="true"
          >
            <span
              className="flex h-4 w-4 shrink-0 items-center justify-center"
              style={{ color: 'var(--color-danger)' }}
              aria-hidden
            >
              <Home />
            </span>
            <span className="truncate">Nexis Foundation-Deve…</span>
            <ChevronDown size={14} className="ml-auto shrink-0 text-fg-faint" />
          </button>

          {/* Team children — 16px indent, Projects is selected */}
          <div className="flex flex-col gap-px">
            <NavItem icon={null} label="Issues" indent={16} />
            <NavItem icon={null} label="Projects" indent={16} selected />
            <NavItem icon={null} label="Views" indent={16} />
          </div>
        </NavSection>

        {/* Try */}
        <NavSection label="Try">
          <NavItem icon={<Import />} label="Import issues" />
          <NavItem icon={<UserPlus />} label="Invite people" />
          <NavItem icon={<GitHub />} label="Connect GitHub" />
        </NavSection>

        <div className="flex-1" />
      </nav>

      {/* Bottom-left help button */}
      <div className="flex items-center justify-start border-t border-border-subtle px-3 py-2">
        <button
          type="button"
          className="flex h-6 w-6 items-center justify-center rounded-md text-fg-faint transition-colors hover:bg-surface hover:text-fg-muted"
          aria-label="Help"
        >
          <QuestionCircle size={14} />
        </button>
      </div>
    </aside>
  );
}
