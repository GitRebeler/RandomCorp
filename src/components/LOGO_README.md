# Random Corp Logo

This directory contains the logo components for Random Corp.

## Components

### RandomCorpLogo
The main logo component with multiple variants:

```tsx
import RandomCorpLogo from './components/RandomCorpLogo';

// Default full logo with text
<RandomCorpLogo size={40} variant="default" onClick={handleClick} />

// Compact version with "RC" text
<RandomCorpLogo size={32} variant="compact" />

// Icon only version
<RandomCorpLogo size={80} variant="icon-only" />
```

### FaviconLogo
Simplified version for favicons and small sizes:

```tsx
import FaviconLogo from './components/FaviconLogo';

<FaviconLogo size={32} />
```

## Design Features

### Color Scheme
- Primary: Blue gradient (#2196F3 to #1976D2)
- Secondary: Light blue (#21CBF3)
- Accent: White with transparency

### Typography
- Font: Segoe UI family
- Weight: 700 (Bold)
- Gradient text effect

### Visual Effects
- Drop shadows
- Gradient backgrounds
- Hover animations
- Responsive sizing

## Usage Guidelines

1. **Navigation**: Use `variant="default"` for main navigation
2. **Mobile**: Use `variant="compact"` for mobile navigation
3. **Hero sections**: Use `variant="icon-only"` with larger sizes
4. **Favicons**: Use `FaviconLogo` component

## Brand Colors

```css
Primary Blue: #2196F3
Dark Blue: #1976D2
Light Blue: #21CBF3
White: #FFFFFF
```

The logo represents the initials "R" and "C" for Random Corp in a modern, professional circular design.
