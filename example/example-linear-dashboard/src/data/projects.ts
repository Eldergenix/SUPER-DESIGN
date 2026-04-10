/*
 * Mock project data. Matches the screenshot exactly — one project
 * ("Nexis Homebase") in the "All projects" view of the Nexis Foundation
 * workspace. Typed so the table cells can be rendered generically
 * instead of hardcoding the single row in JSX.
 */

export type Priority = 'none' | 'low' | 'medium' | 'high' | 'urgent';

export type HealthStatus = 'on_track' | 'at_risk' | 'off_track' | 'no_updates';

export interface Project {
  id: string;
  name: string;
  /** The subtitle line shown below the project name. Rendered with a
   *  yellow diamond marker on its left. */
  subtitle: string | null;
  health: HealthStatus;
  priority: Priority;
  lead: { name: string; avatarUrl: string | null } | null;
  targetDate: string | null;
  /** Percentage complete, 0–100. Renders as "0%" with a dashed circle
   *  when the project hasn't started. */
  progressPercent: number;
}

export const projects: Project[] = [
  {
    id: 'nexis-homebase',
    name: 'Nexis Homebase',
    subtitle: 'Integrate user onboarding to track user wallet connections',
    health: 'no_updates',
    priority: 'none',
    lead: null,
    targetDate: null,
    progressPercent: 0,
  },
];
