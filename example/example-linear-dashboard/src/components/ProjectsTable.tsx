import { projects } from '../data/projects';
import { ProjectRow } from './ProjectRow';

/**
 * Table container. Uses role="table" instead of a literal <table>
 * element so the grid layout from ProjectRow can span the whole row
 * correctly — this is the same pattern Linear uses, and it keeps
 * screen readers happy while letting us use CSS grid for column
 * alignment across the header and body.
 */
export function ProjectsTable() {
  return (
    <div role="table" className="flex flex-col">
      {/* Header row — same grid template as ProjectRow */}
      <div
        role="row"
        className="grid h-8 items-center gap-4 border-b border-border px-4 text-caption font-medium text-fg-faint"
        style={{
          gridTemplateColumns: 'minmax(0, 1fr) 140px 80px 120px 140px 80px',
        }}
      >
        <div role="columnheader">Name</div>
        <div role="columnheader">Health</div>
        <div role="columnheader">Priority</div>
        <div role="columnheader">Lead</div>
        <div role="columnheader">Target date</div>
        <div role="columnheader">Status</div>
      </div>

      {/* Body rows */}
      <div role="rowgroup">
        {projects.map((project) => (
          <ProjectRow key={project.id} project={project} />
        ))}
      </div>
    </div>
  );
}
