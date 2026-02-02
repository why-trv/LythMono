<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/why-trv/LythMono/blob/assets/assets/lyth-mono-title-dark-mode.svg?raw=true">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/why-trv/LythMono/blob/assets/assets/lyth-mono-title-light-mode.svg?raw=true">
    <img alt="Lyth Mono" src="https://github.com/why-trv/LythMono/blob/assets/assets/lyth-mono-title-light-mode.svg?raw=true">
  </picture>
</h1>

**Lyth Mono** is an attempt at my 'dream' programming font. Technically, it's a custom build of [Iosevka](https://github.com/be5invis/Iosevka) with metric overrides and an opinionated selection of glyphs.

<img src="https://github.com/why-trv/LythMono/blob/assets/assets/lyth-mono.png?raw=true" alt="Lyth Mono sample" width="830"/>

## Why?

I have a soft spot for industrial neo-grotesque designs like DIN, but, to my surprise, I haven't seen many coding fonts in this style and none that would tick all the boxes for me.

In a nutshell:
- somewhat square-ish, but not too much,
- simple shapes, minimal usage of tails and serifs, but not too geometric-y,
- decently legible at 12–13 pt,
- all the usual programming font concerns like `O08`, `iIl1` etc.

There are a couple of notable fonts that caught my attention in recent years, namely [**JetBrains Mono**](https://github.com/JetBrains/JetBrainsMono) and [**Berkeley Mono**](https://usgraphics.com/products/berkeley-mono) (as well as its Iosevka-based lookalike, [**Ioskeley Mono**](https://github.com/ahatem/IoskeleyMono)). Those are gorgeous fonts, but still I've managed to find my gripes with them:
- JetBrains Mono is very legible and functional, but I wish it was less condensed and geometric-y.
- Berkeley Mono looks cool, especially in the larger sizes it's presented at, but I feel legibility is compromised at smaller sizes — all characters begin looking like squares.

Here is an animated GIF comparing **Lyth Mono** to **Ioskeley Mono** and **JetBrains Mono**:

<img src="https://github.com/why-trv/LythMono/blob/assets/assets/lyth-ioskeley-jetbrains-mono.gif?raw=true" alt="Lyth Mono vs Ioskeley Mono vs JetBrains Mono" width="830"/>

Lyth Mono is available at [programmingfonts.org](https://www.programmingfonts.org/#lyth-mono) for a quick test drive alongside your current favorite font.

## Variations

### Term

Lyth Mono comes in `normal` (no postfix) and `term` (Term) versions. The latter has narrow arrows and geometric symbols for use in terminal emulators.

### Square / Round

In addition to the default configuration, there are extra Square and Round versions that modify the arc curvature to appear more 'squared' or 'rounded'. This is mostly apparent with characters like `o`, `c`, `e` etc. The difference is rather subtle and, since proportions are otherwise the same, may be more of a 'feel' than a 'look' thing.

<img src="https://github.com/why-trv/LythMono/blob/assets/assets/lyth-mono-normal-round-square.gif?raw=true" alt="Lyth Mono vs Lyth Mono Round vs Lyth Mono Square" width="830"/>

## Installation

1. Head over to [**Releases**](../../releases).
2. Find the latest release and download the `.zip` file for the desired font variation, e.g. `LythMono.zip`.
3. Unzip the archive and install the font files on your OS.

## Building

If you want to tweak the font configurations (aka build plans) in some way (e.g. pick other glyph variants or adjust the metrics), there's a couple of ways to do it.

### Building with GitHub Actions

1. [**Fork**](../../fork) this repository.
2. Make desired changes to the build plans in the `/plans` directory.
3. Commit and push your changes. A push to the `main` branch will run a workflow to build the fonts.
4. Head over to [**Actions**](../../actions), wait for the workflow to complete and find the built fonts archive in the **Artifacts** section.

### Building from Source Locally

#### Prerequisites

Iosevka requires [**Node.js**](https://nodejs.org/en/download) 20+ and [**ttfautohint**](https://freetype.org/ttfautohint/#download) to build. The former provides a bunch of options to choose from on its website, while for the latter the easiest way is likely to use a package manager of your choice (e.g. `brew install ttfautohint` on macOS).
I guess you don't need `ttfautohint` if you're going to build only unhinted versions of the fonts.

#### TL;DR

```
git clone --recursive --shallow-submodules https://github.com/why-trv/LythMono.git
npm install
npm run build
```

The built fonts will be in `dist/`.

On macOS and Linux you can also run
```
npm run install-fonts
```
to automatically install TTFs to the user fonts directory.

#### Parametrized Build

##### 1. Clone this Repository

```
git clone --recursive --shallow-submodules https://github.com/why-trv/LythMono.git
```

Iosevka's full git history is very heavy (tens of GB), so it's strongly recommended to do a shallow clone of the Iosevka submodule (`--shallow-submodules`).

##### 2. Install Dependencies

```
npm install
```

##### 3. Build

```
npm run build [-- [format | target...] [--ts [--keep-old]]]
```
- `format` is the font format option to be forwarded to the Iosevka build system:
    - `contents` (all formats, default)
    - `ttf` (TTF, hinted + unhinted)
    - `ttf-unhinted` (TTF, unhinted)
    - `webfont` (CSS + WOFF2)
    - `webfont-unhinted`
    - `woff2` (WOFF2 only)
    - `woff2-unhinted`
- `target...` - space-separated pairs of format and font build plan names, e.g. `contents::LythMono ttf::LythMonoTerm`.

Use the latter to specify specific fonts (build plans) to build. Otherwise, if only `format`, or neither `format` nor `target...` is specified, the script will build all plans in the `plans/` directory.

- `--ts` automatically appends a timestamp to the font family name (and consequently, the directory and font file names). This can be handy when iterating on a design to bypass font cache issues on macOS, or just to keep multiple iterations installed (see `--keep-old`).
- `--keep-old` prevents the build script from automatically removing older timestamped versions of the font.

When the build finishes, font files will be available in `dist/` (symlinked to `Iosevka/dist/`)

###### Examples:
```
npm run build -- ttf --ts
```
builds a timestamp-versioned TTF and deletes the previously existing timestamped versions of the font.

```
npm run build -- contents::LythMono ttf::LythMonoTerm
```
builds a normal (non-timestamp-versioned) `LythMono` in all formats and `LythMonoTerm` in hinted and unhinted TTF.

##### 4. Install Font Files

You can install the built font files manually, or, for TTF, you also have the option of running this:
```
npm run install-fonts [-- [--unhinted] [--keep-old]]
```
to copy all font files from `dist/` to your user font directory (`~/Library/Fonts` on macOS, `~/.local/share/fonts` on Linux).

Options:
- `--unhinted` - copy the unhinted version of the fonts, otherwise defaults to hinted.
- `--keep-old` - for timestamped builds, don't delete existing timestamped files.
- `--clipboard` - copy family names to clipboard for recall via clipboard manager (macOS only, requires `fontconfig`, which should be already installed as a dependency of `ttfautohint`).

### Build Customization

You can tweak and add font configurations by modifying `.toml` files in `plans/`.

In general, please refer to Iosevka's [Customized Build](https://github.com/be5invis/Iosevka/blob/main/doc/custom-build.md#customized-build) section for details on available parameters, since the Lyth Mono build system is working on top of Iosevka's.

However, keep in mind the differences between Lyth Mono and vanilla Iosevka build systems. In Lyth Mono:
- Any single file in `plans/` defines one and only one build plan.
- `buildPlan.<plan-name>` prefixes are omitted and the plan name is derived from the file name.
- You should be able to use `inherits` keys of vanilla Iosevka where it allows, but this is somewhat limiting and verbose, so instead of defining the whole plan, you can define a base build plan (e.g. `basePlan = "LythMono"`) and the keys to override (see `LythMonoTerm.toml` for example).

The build script processes and gathers all build plans in `Iosevka/private-build-plans.toml` and hands it off to Iosevka to build.
