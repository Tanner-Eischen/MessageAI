/**
 * Central export for all response templates
 */

import { DECLINING_TEMPLATES } from './declining-templates.ts';
import { BOUNDARY_TEMPLATES } from './boundary-templates.ts';
import { INFO_DUMP_TEMPLATES } from './info-dump-templates.ts';
import { APOLOGIZING_TEMPLATES } from './apologizing-templates.ts';
import { CLARIFYING_TEMPLATES } from './clarifying-templates.ts';

export type { ResponseTemplate } from './declining-templates.ts';
export { DECLINING_TEMPLATES } from './declining-templates.ts';
export { BOUNDARY_TEMPLATES } from './boundary-templates.ts';
export { INFO_DUMP_TEMPLATES } from './info-dump-templates.ts';
export { APOLOGIZING_TEMPLATES } from './apologizing-templates.ts';
export { CLARIFYING_TEMPLATES } from './clarifying-templates.ts';

// Re-export all templates as a single array
export const ALL_TEMPLATES = [
  ...DECLINING_TEMPLATES,
  ...BOUNDARY_TEMPLATES,
  ...INFO_DUMP_TEMPLATES,
  ...APOLOGIZING_TEMPLATES,
  ...CLARIFYING_TEMPLATES,
];

