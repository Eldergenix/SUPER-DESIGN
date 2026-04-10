import { AskLinearBar } from './components/AskLinearBar';
import { ProjectsTable } from './components/ProjectsTable';
import { Sidebar } from './components/Sidebar';
import { TabBar } from './components/TabBar';
import { TopBar } from './components/TopBar';

/**
 * Root layout. Two columns: fixed 232px sidebar + flex-1 main panel.
 * The main panel stacks vertically: TopBar, TabBar, then the scrollable
 * ProjectsTable. AskLinearBar is absolutely positioned over the main
 * panel so it stays pinned to the bottom-right corner.
 *
 * No hardcoded colors anywhere in this tree — every visual choice
 * goes through a semantic token declared in DESIGN.md and emitted into
 * src/index.css by the Super Design skill's generate-theme.mjs.
 */
function App() {
  return (
    <div className="flex h-full w-full bg-bg text-fg">
      <Sidebar />
      <main className="relative flex flex-1 flex-col overflow-hidden">
        <TopBar />
        <TabBar />
        <div className="flex-1 overflow-y-auto">
          <ProjectsTable />
        </div>
        <AskLinearBar />
      </main>
    </div>
  );
}

export default App;
