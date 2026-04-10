# Framework Adapter: ShadCN UI

## Detection

- `components.json` at repo root (authoritative)
- `lib/utils.ts` exporting `cn()`
- `components/ui/` folder
- `package.json` deps: `class-variance-authority` + `tailwind-merge` + `clsx`

## Strategy

ShadCN components are COPIED into the user's repo — the user owns each file. Theming happens via:
1. HSL triplets in `globals.css` (`:root` + `.dark`)
2. Colors exposed to Tailwind via `hsl(var(--x) / <alpha-value>)` bridge
3. `components.json` `baseColor` + `cssVariables: true`

## Template — `components.json`

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
```

## Template — `globals.css` with full ShadCN variables

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background:             0 0% 100%;
    --foreground:             222.2 47.4% 11.2%;
    --card:                   0 0% 100%;
    --card-foreground:        222.2 47.4% 11.2%;
    --popover:                0 0% 100%;
    --popover-foreground:     222.2 47.4% 11.2%;
    --primary:                222.2 47.4% 11.2%;
    --primary-foreground:     210 40% 98%;
    --secondary:              210 40% 96.1%;
    --secondary-foreground:   222.2 47.4% 11.2%;
    --muted:                  210 40% 96.1%;
    --muted-foreground:       215.4 16.3% 46.9%;
    --accent:                 210 40% 96.1%;
    --accent-foreground:      222.2 47.4% 11.2%;
    --destructive:            0 84% 60%;
    --destructive-foreground: 210 40% 98%;
    --border:                 214.3 31.8% 91.4%;
    --input:                  214.3 31.8% 91.4%;
    --ring:                   215 20.2% 65.1%;
    --radius:                 0.5rem;
  }

  .dark {
    --background:             224 71% 4%;
    --foreground:             213 31% 91%;
    --card:                   224 71% 4%;
    --card-foreground:        213 31% 91%;
    --popover:                224 71% 4%;
    --popover-foreground:     215 20.2% 65.1%;
    --primary:                210 40% 98%;
    --primary-foreground:     222.2 47.4% 1.2%;
    --secondary:              222.2 47.4% 11.2%;
    --secondary-foreground:   210 40% 98%;
    --muted:                  223 47% 11%;
    --muted-foreground:       215.4 16.3% 56.9%;
    --accent:                 216 34% 17%;
    --accent-foreground:      210 40% 98%;
    --destructive:            0 63% 31%;
    --destructive-foreground: 210 40% 98%;
    --border:                 216 34% 17%;
    --input:                  216 34% 17%;
    --ring:                   216 34% 17%;
  }

  * { @apply border-border; }
  body { @apply bg-background text-foreground antialiased; }
}
```

## Template — `tailwind.config.ts` bridge

```ts
import type { Config } from "tailwindcss";

export default {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
  ],
  theme: {
    container: { center: true, padding: "2rem", screens: { "2xl": "1400px" } },
    extend: {
      colors: {
        border:      "hsl(var(--border))",
        input:       "hsl(var(--input))",
        ring:        "hsl(var(--ring))",
        background:  "hsl(var(--background))",
        foreground:  "hsl(var(--foreground))",
        primary: {
          DEFAULT:    "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT:    "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT:    "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT:    "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT:    "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT:    "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT:    "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      fontFamily: {
        sans: ["var(--font-sans)", "system-ui", "sans-serif"],
      },
      keyframes: {
        "accordion-down": { from: { height: "0" }, to: { height: "var(--radix-accordion-content-height)" } },
        "accordion-up":   { from: { height: "var(--radix-accordion-content-height)" }, to: { height: "0" } },
        "fade-in":  { "0%": { opacity: "0" }, "100%": { opacity: "1" } },
        "slide-up": { "0%": { opacity: "0", transform: "translateY(8px)" }, "100%": { opacity: "1", transform: "none" } },
      },
      animation: {
        "accordion-down": "accordion-down 200ms ease-out",
        "accordion-up":   "accordion-up 200ms ease-out",
        "fade-in":        "fade-in 200ms cubic-bezier(0.2,0,0,1)",
        "slide-up":       "slide-up 300ms cubic-bezier(0.2,0,0,1)",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config;
```

## Mapping DESIGN.md → ShadCN semantic tokens

| DESIGN.md token | ShadCN variable |
|---|---|
| `--color-bg` | `--background` |
| `--color-surface` | `--card`, `--popover` |
| `--color-fg` | `--foreground`, `--card-foreground`, `--popover-foreground` |
| `--color-fg-muted` | `--muted-foreground` |
| `--color-surface-raised` | `--muted` |
| `--color-accent` | `--primary` |
| `--color-accent-fg` | `--primary-foreground` |
| (secondary surface) | `--secondary` + `--secondary-foreground` |
| `--color-danger` | `--destructive` |
| `--color-border` | `--border`, `--input` |
| `--color-focus-ring` | `--ring` |
| `--radius-lg` (base) | `--radius` |

## Component anatomy rule

Every ShadCN component under `components/ui/` uses:
- `React.forwardRef`
- `cva()` from `class-variance-authority` for variants
- `cn()` from `lib/utils` for className composition
- `@radix-ui/react-slot` `<Slot>` for `asChild` pattern
- Max 200 LOC per file (ShadCN's own components average 80–150)

Example canonical Button skeleton:

```tsx
import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 min-h-11 min-w-11",
  {
    variants: {
      variant: {
        default:     "bg-primary text-primary-foreground hover:bg-primary/90 active:scale-[0.98]",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline:     "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary:   "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost:       "hover:bg-accent hover:text-accent-foreground",
        link:        "text-primary underline-offset-4 hover:underline",
      },
      size: {
        sm: "h-9 px-3 text-xs",
        md: "h-11 px-4 py-2",
        lg: "h-12 px-6 text-base",
        icon: "h-11 w-11",
      },
    },
    defaultVariants: { variant: "default", size: "md" },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return <Comp className={cn(buttonVariants({ variant, size, className }))} ref={ref} {...props} />;
  }
);
Button.displayName = "Button";
export { buttonVariants };
```
