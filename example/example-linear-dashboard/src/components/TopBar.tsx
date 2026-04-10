/**
 * The top header strip of the main content area. Just "Projects" as a
 * heading in the reference screenshot — no breadcrumbs, no user menu
 * on this view. Bordered bottom so it visually separates from the
 * TabBar below it.
 */
export function TopBar() {
  return (
    <header className="flex h-11 shrink-0 items-center border-b border-border px-4">
      <h1 className="text-label font-medium text-fg">Projects</h1>
    </header>
  );
}
