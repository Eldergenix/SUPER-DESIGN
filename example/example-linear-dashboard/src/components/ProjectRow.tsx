import type { Project } from '../data/projects';
import {
  CalendarPlus,
  Cube,
  DashDashDash,
  DashedCircle,
  Diamond,
  Person,
} from '../icons';

interface ProjectRowProps {
  project: Project;
}

/**
 * Grid layout matches the column template set by ProjectsTable so the
 * header row and body rows stay in lockstep. Each cell is muted except
 * the Name column, which uses full `text-fg` for the primary line.
 *
 * Tailwind's arbitrary grid-template-columns value is intentionally
 * verbose — it expresses the exact column sizing Linear uses on this
 * view: flexible name column, then six fixed-width metadata columns.
 */
export function ProjectRow({ project }: ProjectRowProps) {
  return (
    <div
      role="row"
      className="grid h-11 items-center gap-4 border-b border-border-subtle px-4 text-caption text-fg-subtle transition-colors hover:bg-surface"
      style={{
        gridTemplateColumns: 'minmax(0, 1fr) 140px 80px 120px 140px 80px',
      }}
    >
      {/* Name + subtitle */}
      <div role="cell" className="flex min-w-0 items-center gap-2">
        <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-md text-accent">
          <Cube size={14} />
        </span>
        <span className="truncate text-label font-medium text-fg">
          {project.name}
        </span>
        {project.subtitle && (
          <span className="flex min-w-0 items-center gap-1.5 truncate">
            <Diamond size={10} style={{ color: 'var(--color-warning)' }} />
            <span className="truncate text-caption text-fg-subtle">
              {project.subtitle}
            </span>
          </span>
        )}
      </div>

      {/* Health */}
      <div role="cell" className="flex items-center gap-1.5">
        {project.health === 'no_updates' && (
          <>
            <DashedCircle size={14} className="text-fg-faint" />
            <span>No updates</span>
          </>
        )}
      </div>

      {/* Priority */}
      <div role="cell" className="flex items-center">
        {project.priority === 'none' ? (
          <DashDashDash size={14} className="text-fg-faint" />
        ) : (
          <span className="capitalize">{project.priority}</span>
        )}
      </div>

      {/* Lead */}
      <div role="cell" className="flex items-center gap-1.5">
        {project.lead === null ? (
          <>
            <Person size={14} className="text-fg-faint" />
            <span>No lead</span>
          </>
        ) : (
          <span className="truncate">{project.lead.name}</span>
        )}
      </div>

      {/* Target date */}
      <div role="cell" className="flex items-center">
        {project.targetDate === null ? (
          <CalendarPlus size={14} className="text-fg-faint" />
        ) : (
          <span className="tabular-nums">{project.targetDate}</span>
        )}
      </div>

      {/* Status / progress */}
      <div
        role="cell"
        className="flex items-center justify-start gap-1.5 tabular-nums"
      >
        <DashedCircle size={14} className="text-fg-faint" />
        <span>{project.progressPercent}%</span>
      </div>
    </div>
  );
}
