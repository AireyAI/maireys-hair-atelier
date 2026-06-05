# Welcome Video Brief — [CLIENT NAME]

Generated via the **Remotion studio** at `~/AireyAi_projects/_remotion-studio/` (free at margin — costs only Codex chat time for AI stills + local render time). Save final to `brand_assets/videos/welcome.mp4`. Wire into hero as muted autoplay loop, 5-8 seconds.

## Spec (lock before rendering)
- **Composition:** `WebsiteHero` (1920×1080) for desktop-first hero, or scale to 9:16 if mobile-first
- **Duration:** 6 seconds default (180 frames @ 30fps) — Remotion picks composition duration from Root.tsx, override in props if needed
- **Audio:** Hero loops are muted (`<video muted>`). Don't generate audio; if Remotion adds music track, strip with `-an` during compression.
- **Style anchor:** Match `brand_assets/` palette. Use client primary hex as the `accent` prop. Layered radial gradients + grain are already baked into the `WebsiteHero` composition's visual system.

## Step 1 — Generate hero stills via Codex.app

Open Codex.app. Paste a brief along these lines (fill brackets from `client_intake.md`):

```
Generate a 1920x1080 hero still for [BUSINESS TYPE — e.g. "a high-end window cleaning service in West London"].

Scene: [PRIMARY VISUAL — e.g. "early morning sunlight catching the glass facade of a Victorian terrace, a single cleaner's squeegee mid-stroke leaving a streak of perfect clarity"]

Mood: [TONE FROM INTAKE — premium / friendly-trade / sharp-tech / etc.]

Camera framing: Wide hero composition with negative space at top-left for headline overlay. Soft natural lighting, shallow depth of field.

Color palette: Dominant [PRIMARY HEX from intake] with [ACCENT HEX] highlights. Low contrast in shadows. 35mm film grain.

Photorealistic. No on-screen text — text will be overlaid in Remotion.
```

Codex auto-saves to `~/.codex/generated_images/<session-uuid>/ig_<hash>.png`. Verify the result is hero-grade (read the PNG with the Read tool, evaluate composition + negative space + brand fit). Generate 2-3 variants, pick the strongest.

Copy the chosen still to `~/AireyAi_projects/_remotion-studio/public/[CLIENT-SLUG]/hero-still.png`.

## Step 2 — Write props JSON

File: `~/AireyAi_projects/_remotion-studio/data/[CLIENT-SLUG]-website-hero.json`

Shape (matches the `WebsiteHero` Zod schema in `_remotion-studio/src/Composition.tsx`):
```json
{
  "brand": "[CLIENT NAME from intake]",
  "headline": "[HERO HEADLINE from intake — client's own words]",
  "subhead": "[HERO SUBHEADLINE from intake]",
  "cta": "[CTA TEXT from intake — short, action verb]",
  "accent": "[CLIENT PRIMARY HEX]",
  "heroStill": "[CLIENT-SLUG]/hero-still.png"
}
```

(Note: confirm `heroStill` field exists in the actual schema — Root.tsx defaults don't show it. If not present, the composition uses procedural gradient; add the field to the schema in Composition.tsx if you want a still backdrop.)

## Step 3 — Render

```bash
cd ~/AireyAi_projects/_remotion-studio
npx remotion render WebsiteHero --props=./data/[CLIENT-SLUG]-website-hero.json out/[CLIENT-SLUG]-website-hero.mp4
```

Render time: ~30-45 seconds on M-series.

## Step 4 — Compress + wire into hero

```bash
ffmpeg -i ~/AireyAi_projects/_remotion-studio/out/[CLIENT-SLUG]-website-hero.mp4 \
  -vcodec libx264 -crf 28 -preset slow -an \
  ~/AireyAi_projects/[CLIENT-SLUG]/brand_assets/videos/welcome.mp4
```

Compressed result should land under ~2MB (CLAUDE.md performance budget). If still over, drop CRF to 32 or generate a separate mobile variant.

Wire into hero HTML:
```html
<video autoplay muted loop playsinline poster="brand_assets/images/hero-poster.jpg">
  <source src="brand_assets/videos/welcome.mp4" type="video/mp4">
</video>
```

Always include `poster` (a Codex-generated still of the first frame) — shows instantly while video loads, prevents flash of empty hero on slow connections.

## Pre-render checklist
- [ ] Confirmed client primary hex (don't guess)
- [ ] Generated hero still in Codex, picked best variant
- [ ] Confirmed aspect (1920×1080 desktop-first, or 1080×1920 if mobile-first hero)
- [ ] Copy in intake.md matches what's in the props JSON

## Fallback — when Remotion isn't enough

`WebsiteHero` produces a motion-graphics hero (text reveal + brand color + image transitions). If the client genuinely needs filmed footage (e.g. a tradesman actually working on-site, a chef actually cooking), Remotion will look wrong. Options:

1. **Use real client footage** if they can supply it — drop into `_remotion-studio/public/[CLIENT-SLUG]/` and reference in props as a `sourceVideo` field (add to schema if not present).
2. **Restore Fal.ai credits** for LTX/Kling automation ($0.12-$0.50/clip).
3. **Skip the hero video** entirely — use a Codex-generated hero still with CSS parallax + Lottie micro-animations. Often better for LCP anyway.

Do NOT try to fake filmed footage by over-animating stills. It always reads as Canva-tier and undermines the rest of the site's polish.

## Cost / quota notes
- Codex.app image gen: free at margin on ChatGPT Plus quota. Budget ~5 still attempts per client.
- Remotion render: free (local ffmpeg). Re-render as many times as you want while iterating props.
- No Sora 2 / Fal calls in this pipeline as of 2026-05-14 (Fal depleted, Sora not on Plus tier).
