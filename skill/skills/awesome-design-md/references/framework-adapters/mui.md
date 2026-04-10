# Framework Adapter: Material UI (MUI)

## Detection

- `package.json` contains `@mui/material`
- Imports from `@mui/material/styles`, `ThemeProvider`, or `createTheme`

## Strategy

Generate a `theme.ts` from DESIGN.md tokens, wrap the app in `<ThemeProvider theme={theme}>` with `<CssBaseline />`, and override per-component defaults via `components.MuiButton.styleOverrides` etc.

## Template — `theme.ts`

```ts
import { createTheme } from "@mui/material/styles";
import type { ThemeOptions } from "@mui/material/styles";

// -------- Tokens (from DESIGN.md) --------
const tokens = {
  color: {
    bg:            "#fafafa",
    surface:       "#ffffff",
    surfaceRaised: "#ffffff",
    fg:            "#171717",
    fgMuted:       "#737373",
    border:        "#e5e5e5",
    accent:        "#4f46e5",
    accentHover:   "#4338ca",
    accentFg:      "#ffffff",
    focusRing:     "#6366f1",
    danger:        "#ef4444",
    success:       "#10b981",
    warning:       "#f59e0b",
  },
  font: {
    sans: '"Inter Variable", system-ui, sans-serif',
    mono: '"JetBrains Mono", ui-monospace, Menlo',
  },
  radius: { sm: 4, md: 6, lg: 8, xl: 12 },
  duration: { fast: 150, base: 200, slow: 300 },
} as const;

// -------- Theme generator --------
const baseOptions = (mode: "light" | "dark"): ThemeOptions => ({
  palette: {
    mode,
    primary:   { main: tokens.color.accent, contrastText: tokens.color.accentFg },
    secondary: { main: tokens.color.fgMuted },
    error:     { main: tokens.color.danger },
    warning:   { main: tokens.color.warning },
    success:   { main: tokens.color.success },
    background: {
      default: mode === "light" ? tokens.color.bg      : "#0a0a0a",
      paper:   mode === "light" ? tokens.color.surface : "#171717",
    },
    text: {
      primary:   mode === "light" ? tokens.color.fg      : "#fafafa",
      secondary: mode === "light" ? tokens.color.fgMuted : "#a3a3a3",
    },
    divider: tokens.color.border,
  },
  shape: { borderRadius: tokens.radius.md },
  spacing: 4, // 4px base
  typography: {
    fontFamily: tokens.font.sans,
    fontWeightRegular: 400,
    fontWeightMedium:  500,
    fontWeightBold:    700,
    h1: { fontSize: "clamp(2.25rem, 1.60rem + 3.20vw, 3.75rem)", fontWeight: 700, lineHeight: 1.15, letterSpacing: "-0.025em" },
    h2: { fontSize: "clamp(1.75rem, 1.35rem + 2.00vw, 2.5rem)",  fontWeight: 600, lineHeight: 1.25, letterSpacing: "-0.02em"  },
    h3: { fontSize: "clamp(1.375rem, 1.15rem + 1.10vw, 1.75rem)",fontWeight: 600, lineHeight: 1.30, letterSpacing: "-0.015em" },
    body1: { fontSize: "clamp(1rem, 0.92rem + 0.40vw, 1.125rem)", lineHeight: 1.6 },
    body2: { fontSize: "clamp(0.875rem, 0.80rem + 0.30vw, 1rem)", lineHeight: 1.5 },
    button: { textTransform: "none", fontWeight: 500 },
  },
  transitions: {
    duration: {
      shortest: 75,
      shorter:  tokens.duration.fast,
      short:    tokens.duration.base,
      standard: tokens.duration.base,
      complex:  tokens.duration.slow,
    },
    easing: {
      easeOut: "cubic-bezier(0.2, 0, 0, 1)",
      easeIn:  "cubic-bezier(0.4, 0, 1, 1)",
      easeInOut: "cubic-bezier(0.4, 0, 0.2, 1)",
      sharp: "cubic-bezier(0.4, 0, 0.6, 1)",
    },
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        "@media (prefers-reduced-motion: reduce)": {
          "*, *::before, *::after": {
            animationDuration: "0.01ms !important",
            transitionDuration: "0.01ms !important",
          },
        },
        ":focus-visible": {
          outline: `3px solid ${tokens.color.focusRing}`,
          outlineOffset: "2px",
          borderRadius: "inherit",
        },
      },
    },
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: {
        root: {
          textTransform: "none",
          borderRadius: tokens.radius.md,
          fontWeight: 500,
          minHeight: 44,
          minWidth: 44,
          transition: `all ${tokens.duration.fast}ms cubic-bezier(0.2, 0, 0, 1)`,
          "&:active": { transform: "scale(0.98)" },
          "&:focus-visible": {
            outline: `3px solid ${tokens.color.focusRing}`,
            outlineOffset: "2px",
          },
        },
      },
    },
    MuiTextField: {
      defaultProps: { variant: "outlined", size: "medium" },
      styleOverrides: {
        root: {
          "& .MuiOutlinedInput-root": {
            borderRadius: tokens.radius.md,
            minHeight: 44,
          },
        },
      },
    },
    MuiCard: {
      defaultProps: { elevation: 0 },
      styleOverrides: {
        root: {
          borderRadius: tokens.radius.lg,
          border: `1px solid ${tokens.color.border}`,
        },
      },
    },
  },
});

export const lightTheme = createTheme(baseOptions("light"));
export const darkTheme  = createTheme(baseOptions("dark"));
```

## Template — `app.tsx` / `_app.tsx`

```tsx
import { ThemeProvider, CssBaseline, useMediaQuery } from "@mui/material";
import { useMemo, useState } from "react";
import { lightTheme, darkTheme } from "./theme";

export default function App({ children }: { children: React.ReactNode }) {
  const prefersDark = useMediaQuery("(prefers-color-scheme: dark)");
  const [mode] = useState<"light" | "dark" | "auto">("auto");
  const theme = useMemo(
    () => (mode === "dark" || (mode === "auto" && prefersDark) ? darkTheme : lightTheme),
    [mode, prefersDark]
  );

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      {children}
    </ThemeProvider>
  );
}
```

## Rules for MUI projects

- Use `theme.palette.*` tokens in `sx` prop — never literal colors
- Use `theme.spacing(n)` for spacing — never raw px
- Prefer `styled()` over `sx` for reusable components (perf)
- Never use `makeStyles` (legacy, being removed)
- Use `CssBaseline` once at the root
- Override per-component defaults via `components: { MuiX: { styleOverrides, defaultProps } }` rather than wrapping every instance
