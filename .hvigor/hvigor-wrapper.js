#!/usr/bin/env node
const path = require('path');
const { spawn, execSync } = require('child_process');
const fs = require('fs');

function findHvigorCli() {
  // 1. Prefer pre-installed hvigor in PATH (CI image usually has this)
  try {
    const hvigorPath = execSync(
      process.platform === 'win32' ? 'where hvigor' : 'command -v hvigor',
      { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] }
    )
      .toString()
      .split(/\r?\n/)[0]
      .trim();
    if (hvigorPath && fs.existsSync(hvigorPath)) {
      return { bin: hvigorPath, args: [] };
    }
  } catch (e) {
    // ignore
  }

  // 2. local oh_modules (after ohpm install)
  const local = path.resolve(process.cwd(), 'oh_modules/@ohos/hvigor/bin/hvigor.js');
  if (fs.existsSync(local)) {
    return { bin: process.execPath, args: [local] };
  }

  // 3. local node_modules (fallback)
  const node = path.resolve(process.cwd(), 'node_modules/@ohos/hvigor/bin/hvigor.js');
  if (fs.existsSync(node)) {
    return { bin: process.execPath, args: [node] };
  }

  throw new Error('Cannot find hvigor. Please ensure HarmonyOS build tools are installed, or run "ohpm install" if dependencies exist.');
}

const cli = findHvigorCli();
const userArgs = process.argv.slice(2);
const child = spawn(cli.bin, [...cli.args, ...userArgs], {
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
