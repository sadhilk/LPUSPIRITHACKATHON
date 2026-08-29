---
name: Lumina Nexus
colors:
  surface: '#121317'
  surface-dim: '#121317'
  surface-bright: '#38393d'
  surface-container-lowest: '#0d0e12'
  surface-container-low: '#1a1b1f'
  surface-container: '#1e1f23'
  surface-container-high: '#292a2e'
  surface-container-highest: '#343539'
  on-surface: '#e3e2e7'
  on-surface-variant: '#c6c6ca'
  inverse-surface: '#e3e2e7'
  inverse-on-surface: '#2f3034'
  outline: '#8f9094'
  outline-variant: '#45474a'
  surface-tint: '#c6c6ca'
  primary: '#c6c6ca'
  on-primary: '#2f3034'
  primary-container: '#121417'
  on-primary-container: '#7d7e82'
  inverse-primary: '#5d5e62'
  secondary: '#c4c6cb'
  on-secondary: '#2e3135'
  secondary-container: '#46494d'
  on-secondary-container: '#b6b8bd'
  tertiary: '#c3c7cd'
  on-tertiary: '#2d3136'
  tertiary-container: '#101418'
  on-tertiary-container: '#7b7f84'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e2e2e6'
  primary-fixed-dim: '#c6c6ca'
  on-primary-fixed: '#1a1c1f'
  on-primary-fixed-variant: '#45474a'
  secondary-fixed: '#e1e2e7'
  secondary-fixed-dim: '#c4c6cb'
  on-secondary-fixed: '#191c20'
  on-secondary-fixed-variant: '#44474b'
  tertiary-fixed: '#e0e3e9'
  tertiary-fixed-dim: '#c3c7cd'
  on-tertiary-fixed: '#181c20'
  on-tertiary-fixed-variant: '#43474c'
  background: '#121317'
  on-background: '#e3e2e7'
  surface-variant: '#343539'
  crimson-muted: '#B22222'
  solar-muted: '#D4AF37'
  slate-gradient-stop: '#3E444B'
typography:
  display-lg:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Montserrat
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 48px
---

## Brand & Style

The design system embodies a high-precision, "Pro-Tech" aesthetic that prioritizes clarity, sophistication, and a hardware-inspired tactile feel. The brand personality is **authoritative, sleek, and high-performance**, catering to power users who value both aesthetics and functional depth.

The visual style is a fusion of **Corporate Minimalism** and **Tactile Depth**. It moves away from heavy glassmorphism toward a more structured, solid environment using charcoal surfaces and slate-toned gradients. This "hardware-like" approach creates a sense of reliability and physical presence. Subtle linear gradients are used to define surface transitions, simulating the way light catches the edges of refined industrial materials. The emotional response is one of calm control—a professional-grade instrument panel for the digital age.

## Colors

The palette is anchored in a professional **Charcoal & Gradient Grey** scheme, designed to provide a low-fatigue environment while emphasizing structural depth.

- **Foundations:** The primary surface uses `primary_color_hex` (#121417) to provide a deep, non-pure-black base. Secondary containers and elevated panels use `secondary_color_hex` (#2C2F33).
- **Gradients:** Depth is achieved through linear gradients rather than shadows. Apply a subtle top-to-bottom gradient on primary cards moving from `secondary_color_hex` to `slate-gradient-stop`.
- **Accents:** The legacy kinetic colors are evolved for dark mode. **Crimson Red** is muted to a deep oxblood tone for critical alerts and high-priority actions, while **Solar Yellow** is shifted to a metallic gold tone for active states and highlights, ensuring they stand out without causing visual glare.
- **Interactive States:** Use `tertiary_color_hex` for hover states and `neutral_color_hex` for secondary text and disabled borders.

## Typography

This design system uses a dual-font strategy to balance geometric character with utility.

- **Montserrat (Headlines):** Used for all display and heading levels. Its geometric structure reinforces the tech-focused, professional aesthetic. High-level headers should utilize the tighter letter spacing specified for a more "locked-in" appearance.
- **Inter (Body & Labels):** Used for all functional copy, data readouts, and UI controls. Inter provides the necessary legibility for complex information architecture.
- **Scaling:** On mobile devices, use the `-mobile` variants for large display text to maintain vertical rhythm. Labels should always be in Inter and can use `uppercase` for category headers to enhance the instrument-panel feel.

## Layout & Spacing

The layout philosophy follows a **Fixed-Fluid Hybrid** model to ensure precision across desktop and mobile.

- **Grid:** A 12-column grid is standard for desktop (max-width 1440px), transitioning to a 4-column grid for mobile.
- **Rhythm:** An 8px base unit (1rem = 16px) governs all spatial relationships. Card internal padding should prioritize the `md` (24px) unit to maintain a premium, spacious feel.
- **Density:** In professional dashboard views, spacing can be compressed to the `sm` (12px) unit to allow for higher data density without sacrificing alignment.
- **Reflow:** On tablet devices, the side margins reduce to 32px, and 12-column layouts reflow into 2-column stacks for primary content cards.

## Elevation & Depth

Elevation is conveyed through **Tonal Layers** and **Subtle Outlines** rather than traditional drop shadows, mimicking high-end hardware interfaces.

1.  **Base (Level 0):** `primary_color_hex`. No gradient.
2.  **Container (Level 1):** `secondary_color_hex`. Features a subtle 1px border using `tertiary_color_hex` at 50% opacity.
3.  **Active Surface (Level 2):** Uses the linear gradient from `secondary_color_hex` to `slate-gradient-stop`. 
4.  **Edge Highlights:** To simulate physical depth, use a 1px "light-leak" inner stroke on the top edge of primary containers using white at 5% opacity. 
5.  **Shadows:** Shadows are used sparingly and should be crisp. If required for modals, use a high-spread, low-opacity (40%) black shadow with 0 offset to create a "floating" effect without a visible light source.

## Shapes

The shape language is defined by **ROUND_TWELVE**, creating a premium, machined-tool aesthetic.

- **Standard Radius (0.5rem / 8px):** Used for buttons, inputs, and small utility chips.
- **Container Radius (1rem / 16px):** Used for all primary content cards, dashboard modules, and secondary sections.
- **Large Radius (1.5rem / 24px):** Reserved for main layout wrappers or high-level decorative containers.
- **Iconography:** Use solid, 2px stroke icons with slightly rounded terminals to match the container radius. Icons should be centered in square containers with a radius of 8px.

## Components

- **Buttons:** 
    - *Primary:* Solid `secondary_color_hex` with a 1px border of `neutral_color_hex`. Text is white.
    - *Action:* Uses `crimson-muted` or `solar-muted` for critical or highlighted actions.
- **Cards:** The core container. Must use the `secondary_color_hex` background with the 1px top-edge highlight and 16px corner radius.
- **Input Fields:** Deep charcoal background (`primary_color_hex`), 1px `tertiary_color_hex` border. On focus, the border shifts to `solar-muted`.
- **Chips & Tags:** Use a solid `tertiary_color_hex` background with `body-sm` typography. For status-specific chips, use a 10% opacity fill of the status color with a 100% opacity text label.
- **Lists:** Items are separated by a 1px line of `tertiary_color_hex`. Use `md` spacing between the icon and the text label.
- **Checkboxes & Radios:** Should feel mechanical. Use a thick `secondary_color_hex` border. When checked, the inner fill is `solar-muted` with no shadow.
- **Sliders:** High-contrast tracks. The inactive track is `primary_color_hex`, and the active "fill" is `solar-muted` with a matte finish.