const { execSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const distDir = path.join(__dirname, '..', 'dist');
fs.mkdirSync(distDir, { recursive: true });

const run = (cmd) => {
  console.log(`\n> ${cmd}`);
  execSync(cmd, { stdio: 'inherit' });
};

run('pnpm run build:css');
run('pnpm run build:content');
run('pnpm run prerender');
run('pnpm exec spago bundle');
