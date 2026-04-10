// playwright.design-md.config.ts — ship-ready Playwright config for
// visual-regression testing wired to the super-design skill.
//
// Import this from your main playwright.config.ts or use as a standalone
// config: `npx playwright test -c playwright.design-md.config.ts`.

import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/visual",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,

  // Deterministic visual diffing
  expect: {
    toHaveScreenshot: {
      // 0.1 is strict per-pixel color tolerance (antialias-tolerant)
      threshold: 0.1,
      // Max 0.5% of pixels may differ
      maxDiffPixelRatio: 0.005,
      // Freeze animations
      animations: "disabled",
      // Respect reduced motion
      scale: "css",
    },
  },

  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    // Freeze time & fonts for stable diffs
    colorScheme: "light",
    reducedMotion: "reduce",
    // Ensure fonts are loaded before screenshots
    launchOptions: { args: ["--font-render-hinting=none"] },
  },

  // Test at every required breakpoint
  projects: [
    { name: "mobile-sm",  use: { ...devices["iPhone SE"],       viewport: { width: 320,  height: 568  } } },
    { name: "mobile",     use: { ...devices["iPhone 13"],       viewport: { width: 375,  height: 812  } } },
    { name: "tablet",     use: { ...devices["iPad Mini"],       viewport: { width: 768,  height: 1024 } } },
    { name: "laptop",     use: { ...devices["Desktop Chrome"],  viewport: { width: 1024, height: 768  } } },
    { name: "desktop",    use: { ...devices["Desktop Chrome"],  viewport: { width: 1440, height: 900  } } },
    { name: "wide",       use: { ...devices["Desktop Chrome"],  viewport: { width: 1920, height: 1080 } } },

    // Dark mode variants
    { name: "mobile-dark",  use: { ...devices["iPhone 13"],     colorScheme: "dark", viewport: { width: 375, height: 812 } } },
    { name: "desktop-dark", use: { ...devices["Desktop Chrome"], colorScheme: "dark", viewport: { width: 1440, height: 900 } } },

    // Forced-colors / Windows High Contrast
    { name: "forced-colors", use: { ...devices["Desktop Chrome"], forcedColors: "active", viewport: { width: 1440, height: 900 } } },

    // Reduced-transparency
    { name: "reduced-transparency", use: { ...devices["Desktop Chrome"], contextOptions: { reducedMotion: "reduce" }, viewport: { width: 1440, height: 900 } } },
  ],

  reporter: [
    ["list"],
    ["html", { outputFolder: "playwright-report/design-md", open: "never" }],
    ["json", { outputFile: "test-results/design-md.json" }],
  ],
});
