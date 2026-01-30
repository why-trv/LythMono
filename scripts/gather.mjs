#!/usr/bin/env node
import { readFileSync, writeFileSync, readdirSync, statSync } from 'fs';
import { join, basename, dirname } from 'path';
import { parse, stringify } from 'smol-toml';
import { fileURLToPath } from 'url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const PLANS_DIR = join(ROOT, 'plans');
const OUTPUT = join(ROOT, 'Iosevka', 'private-build-plans.toml');

// Deep merge two objects. Source values override target values.
// Arrays are replaced entirely (not concatenated).
function deepMerge(target, source) {
  const result = { ...target };
  for (const [key, value] of Object.entries(source)) {
    if (value !== null && typeof value === 'object' && !Array.isArray(value) &&
        key in result && typeof result[key] === 'object' && !Array.isArray(result[key])) {
      result[key] = deepMerge(result[key], value);
    } else {
      result[key] = value;
    }
  }
  return result;
}

// Recursively collect all .toml files
function collectTomlFiles(dir) {
  const files = [];
  for (const f of readdirSync(dir)) {
    if (f.startsWith('.')) continue;
    const path = join(dir, f);
    if (statSync(path).isDirectory()) {
      files.push(...collectTomlFiles(path));
    } else if (f.endsWith('.toml')) {
      files.push(path);
    }
  }
  return files;
}

const planFiles = collectTomlFiles(PLANS_DIR);

// First pass: parse all plans (without resolving basePlan)
const rawPlans = {};
for (const file of planFiles) {
  const name = basename(file, '.toml');
  rawPlans[name] = parse(readFileSync(file, 'utf-8'));
}

// Resolve a plan by merging with its basePlan (recursively).
// Caches resolved plans to avoid re-processing.
const resolvedPlans = {};
function resolvePlan(name) {
  if (resolvedPlans[name]) return resolvedPlans[name];

  const raw = rawPlans[name];
  if (!raw) {
    throw new Error(`Plan not found: ${name}`);
  }

  let plan;
  if (raw.basePlan) {
    const baseName = raw.basePlan;
    if (!rawPlans[baseName]) {
      throw new Error(`Base plan "${baseName}" not found for plan "${name}"`);
    }
    // Resolve base recursively, then merge
    const base = resolvePlan(baseName);
    const { basePlan: _, ...overrides } = raw;
    plan = deepMerge(base, overrides);
  } else {
    plan = { ...raw };
  }

  resolvedPlans[name] = plan;
  return plan;
}

// Resolve all plans
const buildPlans = {};
const ts = process.env.BUILD_TS;

for (const name of Object.keys(rawPlans)) {
  const resolved = resolvePlan(name);
  const plan = JSON.parse(JSON.stringify(resolved)); // Deep clone to avoid mutating cache
  const outputName = ts ? `${name}-${ts}` : name;

  if (ts && plan.family) {
    plan.family = `${plan.family} ${ts}`;
  }

  buildPlans[outputName] = plan;
}

writeFileSync(OUTPUT, stringify({ buildPlans }));

// Output plan names for build.sh
console.log(Object.keys(buildPlans).join(' '));
