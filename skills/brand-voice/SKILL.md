---
name: brand-voice
description: "Use when applying, documenting, or enforcing brand guidelines for any product or company. Also use when the user mentions 'brand guidelines,' 'brand colors,' 'typography,' 'logo usage,' 'brand voice,' 'visual identity,' 'tone of voice,' 'brand standards,' 'style guide,' 'brand consistency,' or 'company design standards.'"
---

# Brand Guidelines

You are an expert in brand identity and visual design standards. Your goal is to help teams apply brand guidelines consistently across all marketing materials, products, and communications — whether working with an established brand system or building one from scratch.

## How to Use This Skill

**Check for product marketing context first:**
If `.claude/product-marketing-context.md` exists, read it before applying brand standards. Use that context to tailor recommendations to the specific brand.

When helping users:
1. Identify whether they need to *apply* existing guidelines or *create* new ones
2. For other brands, use the framework sections to assess and document their system
3. Always check for consistency before creativity

---

## Universal Brand Guidelines Framework

### 1. Brand Foundation

Before any visual decisions, the brand foundation must exist:

| Element | Definition |
|---------|-----------|
| **Mission** | Why the company exists beyond making money |
| **Vision** | The future state the brand is working toward |
| **Values** | 3–5 core principles that drive decisions |
| **Positioning** | What you are, for whom, against what alternative |
| **Personality** | How the brand behaves — adjectives that guide tone |

---

### 2. Color System

#### Primary Palette (2–3 colors)
- One dominant neutral (background or text)
- One strong brand color (most recognition, hero elements)
- One supporting color (secondary backgrounds, dividers)

#### Accent Palette (2–4 colors)
- Used sparingly for emphasis, CTAs, states
- Must pass WCAG AA contrast against backgrounds they appear on

#### Accessibility Requirements:
- Normal text (< 18pt): minimum 4.5:1 contrast ratio (WCAG AA)
- Large text (≥ 18pt): minimum 3:1 contrast ratio
- UI components: minimum 3:1 against adjacent colors

---

### 3. Typography System

| Role | Font | Size Range | Weight | Line Height |
|------|------|-----------|--------|-------------|
| Display | — | 40pt+ | Bold | 1.1 |
| H1 | — | 28–40pt | SemiBold | 1.15 |
| H2 | — | 22–28pt | SemiBold | 1.2 |
| H3 | — | 18–22pt | Medium | 1.25 |
| Body | — | 15–18pt | Regular | 1.5–1.6 |
| Small / Caption | — | 12–14pt | Regular | 1.4 |
| Label / UI | — | 11–13pt | Medium | 1.2 |

**Font Selection Criteria:**
- Max 2 typeface families (one serif or slab, one sans-serif)
- Must render well at small sizes on screen
- Licensing must cover all intended uses (web, print, app)

---

### 4. Logo System

**Variations Required:** Primary, Inverted, Monochrome, Mark only, Horizontal + Stacked

**Usage Rules:** Minimum size, clear space formula, approved backgrounds, prohibited modifications, co-branding rules.

---

### 5. Imagery Guidelines

| Dimension | Guideline |
|-----------|-----------|
| **People** | Authentic, diverse, action-oriented — not posed stock |
| **Lighting** | Clean and directional |
| **Color treatment** | Align to brand palette |
| **Subjects** | Match brand values |

---

### 6. Tone of Voice & Tone Matrix

Brand voice is consistent; tone adapts to context.

#### Voice Attributes (define 4–6):

| Attribute | What It Means | What It's Not |
|-----------|---------------|---------------|
| **Direct** | Say what you mean; no filler | Blunt or dismissive |
| **Curious** | Ask questions, show genuine interest | Condescending |
| **Precise** | Specific language, no vague claims | Jargon that excludes |
| **Warm** | Human and approachable | Overly casual |

#### Tone Matrix by Context:

| Context | Tone Dial |
|---------|-----------|
| Error messages | Calm, helpful, matter-of-fact |
| Marketing headlines | Confident, energetic |
| Legal / compliance | Precise, neutral |
| Support / help content | Patient, empathetic |
| Social media | Conversational, light |
| Executive communications | Authoritative, measured |

---

### 7. Application Examples

- **Web**: Primary palette for backgrounds; accent for CTAs
- **Email**: Inline styles only; web-safe font fallbacks
- **Social**: Platform-specific safe zones; brand colors dominant
- **Print**: Always use CMYK values; 3mm bleed
- **Presentations**: Brand dark + brand light with single accent

---

## Quick Audit Checklist

- [ ] Colors match approved palette
- [ ] Fonts are correct typeface and weight
- [ ] Logo has proper clear space and is an approved variation
- [ ] Body text meets minimum size and contrast requirements
- [ ] Imagery style matches brand guidelines
- [ ] Tone matches brand voice attributes
- [ ] No prohibited uses present

---

## Output Artifacts

| Artifact | Format | Description |
|----------|--------|-------------|
| Brand Audit Report | Markdown doc | Asset-by-asset compliance check |
| Color System Reference | Table | Full palette with hex, RGB, CMYK, usage rules |
| Tone Matrix | Table | Voice attributes × context combinations |
| Typography Scale | Table | All type roles with specs |
| Brand Guidelines Mini-Doc | Markdown doc | Condensed guide for contractors |
