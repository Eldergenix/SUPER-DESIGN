/*
 * Inline SVG icon set. No dependency on lucide-react, heroicons, or
 * anything else — every icon is ~15 lines of JSX, strokes use currentColor,
 * sizes accept a `size` prop. Keeping icons in-repo means one fewer package
 * to audit and a guaranteed single visual language.
 *
 * Style: 1.5px strokes, round line caps, 16px default box. Matches Linear's
 * outlined-icon aesthetic. Icons are presentational by default — parent
 * components add aria-label when the icon conveys meaning on its own.
 */

import type { SVGProps } from 'react';

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

const base = (size: number): SVGProps<SVGSVGElement> => ({
  width: size,
  height: size,
  viewBox: '0 0 16 16',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.5,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
  'aria-hidden': true,
  focusable: false,
});

export function ChevronDown({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M4 6l4 4 4-4" />
    </svg>
  );
}

export function ChevronRight({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M6 4l4 4-4 4" />
    </svg>
  );
}

export function Search({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <circle cx="7" cy="7" r="4" />
      <path d="M10 10l3 3" />
    </svg>
  );
}

export function Compose({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M11.5 2.5l2 2L6 12l-3 1 1-3 7.5-7.5z" />
      <path d="M10 4l2 2" />
    </svg>
  );
}

export function Inbox({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M2 3h12v7a1 1 0 0 1-1 1h-2l-1 2H6l-1-2H3a1 1 0 0 1-1-1V3z" />
      <path d="M2 8h3l1 1h4l1-1h3" />
    </svg>
  );
}

export function Target({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <circle cx="8" cy="8" r="6" />
      <circle cx="8" cy="8" r="3" />
      <circle cx="8" cy="8" r="0.5" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function Cube({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M8 2L2.5 5v6L8 14l5.5-3V5L8 2z" />
      <path d="M2.5 5L8 8l5.5-3" />
      <path d="M8 8v6" />
    </svg>
  );
}

export function Stack({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M8 2L2 5l6 3 6-3-6-3z" />
      <path d="M2 8l6 3 6-3" />
      <path d="M2 11l6 3 6-3" />
    </svg>
  );
}

export function MoreHorizontal({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <circle cx="4" cy="8" r="0.75" fill="currentColor" />
      <circle cx="8" cy="8" r="0.75" fill="currentColor" />
      <circle cx="12" cy="8" r="0.75" fill="currentColor" />
    </svg>
  );
}

export function Home({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M2.5 7L8 2.5 13.5 7v6a1 1 0 0 1-1 1h-9a1 1 0 0 1-1-1V7z" />
      <path d="M6.5 14V9h3v5" />
    </svg>
  );
}

export function DashedCircle({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <circle cx="8" cy="8" r="6" strokeDasharray="2 2" />
    </svg>
  );
}

export function Person({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <circle cx="8" cy="6" r="3" strokeDasharray="2 1.5" />
      <path d="M3 14c.5-2.5 2.5-4 5-4s4.5 1.5 5 4" strokeDasharray="2 1.5" />
    </svg>
  );
}

export function CalendarPlus({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <rect x="2.5" y="3" width="11" height="10.5" rx="1" strokeDasharray="2 1.5" />
      <path d="M2.5 6.5h11" strokeDasharray="2 1.5" />
      <path d="M5.5 1.5v3M10.5 1.5v3" />
      <path d="M8 8.5v3M6.5 10h3" />
    </svg>
  );
}

export function DashDashDash({ size = 16, ...rest }: IconProps) {
  // Priority "—" indicator (three short horizontal dashes)
  return (
    <svg {...base(size)} {...rest}>
      <path d="M2 5h3M2 8h3M2 11h3" />
      <path d="M7 8h7" opacity="0.5" />
    </svg>
  );
}

export function Sliders({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M2 4h8M12 4h2" />
      <circle cx="11" cy="4" r="1.25" />
      <path d="M2 8h2M6 8h8" />
      <circle cx="5" cy="8" r="1.25" />
      <path d="M2 12h6M10 12h4" />
      <circle cx="9" cy="12" r="1.25" />
    </svg>
  );
}

export function Columns({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <rect x="2" y="3" width="5" height="10" rx="1" />
      <rect x="9" y="3" width="5" height="10" rx="1" />
    </svg>
  );
}

export function SplitView({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <rect x="2" y="3" width="12" height="10" rx="1" />
      <path d="M8 3v10" />
    </svg>
  );
}

export function Plus({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M8 3v10M3 8h10" />
    </svg>
  );
}

export function QuestionCircle({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <circle cx="8" cy="8" r="6" />
      <path d="M6.5 6.5a1.5 1.5 0 1 1 2.25 1.3c-.5.28-.75.7-.75 1.2v0.5" />
      <circle cx="8" cy="11.5" r="0.4" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function History({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M2 8a6 6 0 1 0 1.76-4.24" />
      <path d="M2 2v3h3" />
      <path d="M8 5v3l2 1.5" />
    </svg>
  );
}

export function Diamond({ size = 16, ...rest }: IconProps) {
  // Filled diamond — used for the yellow milestone/issue indicator on the
  // Nexis Homebase row. Unlike the other outlined icons, this one is a
  // solid fill since it acts as a status marker, not a UI control.
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" aria-hidden="true" focusable="false">
      <path d="M8 2l6 6-6 6-6-6 6-6z" fill="currentColor" />
    </svg>
  );
}

export function GitHub({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M8 1.5a6.5 6.5 0 0 0-2.05 12.67c.32.06.44-.14.44-.3v-1.17c-1.8.39-2.18-.77-2.18-.77-.3-.75-.72-.95-.72-.95-.6-.4.04-.4.04-.4.65.05.99.67.99.67.58.98 1.51.7 1.88.54.06-.42.23-.7.41-.87-1.44-.16-2.95-.72-2.95-3.2 0-.71.25-1.29.67-1.74-.07-.16-.29-.82.06-1.71 0 0 .55-.18 1.8.67a6.29 6.29 0 0 1 3.28 0c1.24-.85 1.79-.67 1.79-.67.36.89.14 1.55.07 1.71.42.45.67 1.03.67 1.74 0 2.49-1.52 3.04-2.96 3.2.23.2.44.59.44 1.19v1.77c0 .17.12.37.44.3A6.5 6.5 0 0 0 8 1.5z" />
    </svg>
  );
}

export function UserPlus({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <circle cx="6" cy="5.5" r="2.5" />
      <path d="M1.5 13c.5-2 2.2-3.5 4.5-3.5s4 1.5 4.5 3.5" />
      <path d="M12 5v3M10.5 6.5h3" />
    </svg>
  );
}

export function Import({ size = 16, ...rest }: IconProps) {
  return (
    <svg {...base(size)} {...rest}>
      <path d="M8 2v8" />
      <path d="M5 7l3 3 3-3" />
      <path d="M2.5 13h11" />
    </svg>
  );
}
