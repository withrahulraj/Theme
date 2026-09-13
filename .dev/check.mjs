import pkg from '@shopify/theme-check-node';
const { themeCheckRun } = pkg;
const root = new URL('..', import.meta.url).pathname.replace(/\/$/, '');
const res = await themeCheckRun(root);
const offenses = res.offenses || [];
const byFile = {};
for (const o of offenses) {
  const f = (o.uri || '').replace(`file://${root}/`, '');
  (byFile[f] ||= []).push(`${o.severity === 0 ? 'ERROR' : o.severity === 1 ? 'WARN' : 'INFO'} [${o.check}] line ${(o.start?.line ?? 0) + 1}: ${o.message}`);
}
let errs = 0;
for (const [f, list] of Object.entries(byFile)) {
  console.log('\n== ' + f);
  for (const l of list) { console.log('  ' + l); if (l.startsWith('ERROR')) errs++; }
}
console.log('\nTOTAL offenses:', offenses.length, 'errors:', errs);
