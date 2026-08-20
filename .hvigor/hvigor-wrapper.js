#!/usr/bin/env node
const path = require('path');
const { spawn } = require('child_process');
const fs = require('fs');

function findHvigorCli() {
  // 1. local oh_modules (after ohpm install)
  const local = path.resolve(process.cwd(), 'oh_modules/@ohos/hvigor/bin/hvigor.js');
  if (fs.existsSync(local)) {
    return local;
  }
  // 2. local node_modules (fallback)
  const node = path.resolve(process.cwd(), 'node_modules/@ohos/hvigor/bin/hvigor.js');
  if (fs.existsSync(node)) {
    return node;
  }
  // 3. global
  try {
    const globalDir = require('child_process').execSync('npm root -g', { encoding: 'utf8' }).trim();
    const global = path.join(globalDir, '@ohos/hvigor/bin/hvigor.js');
    if (fs.existsSync(global)) {
      return global;
    }
  } catch (e) {
    // ignore
  }
  throw new Error('Cannot find @ohos/hvigor. Please run "ohpm install" first.');
}

const cli = findHvigorCli();
const args = process.argv.slice(2);
const child = spawn(process.execPath, [cli, ...args], {
  stdio: 'inherit',
  cwd: process.cwd(),
});
child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exit(code ?? 0);
  }
});
