// Webpack cannot bundle a project inside a path containing "!".
// Stage a copy in a safe path, keeping editable source and outputs here.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const root = __dirname;
const hash = crypto.createHash('sha256').update(root).digest('hex').slice(0, 12);
const stage = path.join(os.tmpdir(), `remotion-kincir-${hash}`);
fs.mkdirSync(stage, {recursive:true});
for (const item of ['src','public','package.json','package-lock.json','tsconfig.json']) {
  fs.cpSync(path.join(root,item), path.join(stage,item), {recursive:true});
}
const lock = fs.readFileSync(path.join(root,'package-lock.json'),'utf8');
const marker = path.join(stage,'.dependencies');
if (!fs.existsSync(marker) || fs.readFileSync(marker,'utf8') !== lock) {
  console.log('Preparing Remotion runtime in a path supported by Webpack...');
  fs.rmSync(path.join(stage,'node_modules'),{recursive:true,force:true});
  fs.cpSync(path.join(root,'node_modules'),path.join(stage,'node_modules'),{recursive:true});
  fs.writeFileSync(marker,lock);
}
const args = process.argv.slice(2).map(arg => arg.startsWith('out/') ? path.join(root,arg) : arg);
const brave = '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser';
if (['render','still'].includes(args[0]) && fs.existsSync(brave) && !args.some(a=>a.startsWith('--browser-executable'))) {
  args.push(`--browser-executable=${brave}`);
}
console.log(`Runtime: ${stage}`);
const result = spawnSync(process.execPath,[path.join(stage,'node_modules/@remotion/cli/remotion-cli.js'),...args],{cwd:stage,stdio:'inherit'});
if (result.error) console.error(result.error);
process.exit(result.status ?? 1);
