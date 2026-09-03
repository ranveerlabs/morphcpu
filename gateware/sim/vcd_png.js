// node vcd_png.js out/tb_grid.vcd ../../docs/img/foo.png
const fs = require('fs'), zlib = require('zlib');

const [vcdPath, outPath] = process.argv.slice(2);
if (!vcdPath || !outPath) { console.error('need <in.vcd> <out.png>'); process.exit(1); }

const txt = fs.readFileSync(vcdPath, 'utf8');
const ids = {};
for (const m of txt.matchAll(/\$var\s+\S+\s+(\d+)\s+(\S+)\s+([^\s$]+)/g)) {
  if (!ids[m[2]]) ids[m[2]] = m[3];
}
const idOf = n => Object.keys(ids).find(k => ids[k] === n);
const idActive = idOf('active') || idOf('led');
const idTick = idOf('tick');
if (!idActive) { console.error('no active/led in this vcd'); process.exit(1); }

const body = txt.slice(txt.indexOf('$enddefinitions'));
let active = 0, tick = 0, prevTick = 0;
const frames = [];

for (const line of body.split('\n')) {
  const s = line.trim();
  if (!s || s[0] === '$') continue;
  if (s[0] === '#') continue;
  if (s[0] === 'b' || s[0] === 'B') {
    const sp = s.indexOf(' ');
    const bits = s.slice(1, sp), id = s.slice(sp + 1).trim();
    if (id === idActive) {
      const v = parseInt(bits.replace(/[xzXZ]/g, '0'), 2) || 0;
      const changed = v !== active;
      active = v;
      if (!idTick && changed) frames.push(active);
    }
  } else {
    const v = s[0], id = s.slice(1).trim();
    if (idTick && id === idTick) {
      tick = (v === '1') ? 1 : 0;
      if (tick === 1 && prevTick === 0) frames.push(active);
      prevTick = tick;
    }
  }
}
const MAXF = 40;
if (frames.length > MAXF) frames.length = MAXF;
if (!frames.length) { console.error('no tick edges found'); process.exit(1); }

const CELLS = 16, SC = 2;
const cw = 18, ch = 18, gap = 2;
const padL = 34, padT = 26, padB = 14, padR = 10;
const W = padL + frames.length * (cw + gap) + padR;
const H = padT + CELLS * (ch + gap) + padB;
const buf = Buffer.alloc(W * H * 3);

const BG = [14, 16, 20], GRID = [34, 38, 46], ON = [232, 72, 60], OFF = [30, 34, 42], TXT = [150, 158, 172];
for (let i = 0; i < W * H; i++) { buf[i*3] = BG[0]; buf[i*3+1] = BG[1]; buf[i*3+2] = BG[2]; }
const px = (x, y, c) => {
  if (x < 0 || y < 0 || x >= W || y >= H) return;
  const o = (y * W + x) * 3; buf[o] = c[0]; buf[o+1] = c[1]; buf[o+2] = c[2];
};
const rect = (x, y, w, h, c) => { for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) px(x+i, y+j, c); };

const FONT = {
  '0':['111','101','101','101','111'], '1':['010','110','010','010','111'],
  '2':['111','001','111','100','111'], '3':['111','001','111','001','111'],
  '4':['101','101','111','001','001'], '5':['111','100','111','001','111'],
  '6':['111','100','111','101','111'], '7':['111','001','001','001','001'],
  '8':['111','101','111','101','111'], '9':['111','101','111','001','111'],
};
const glyph = (ch_, x, y, c) => {
  const g = FONT[ch_]; if (!g) return;
  for (let r = 0; r < 5; r++) for (let col = 0; col < 3; col++)
    if (g[r][col] === '1') rect(x + col*SC, y + r*SC, SC, SC, c);
};
const text = (s, x, y, c) => { let cx = x; for (const k of s) { glyph(k, cx, y, c); cx += 3*SC + SC; } };

for (let f = 0; f < frames.length; f++) {
  if (f % 5) continue;
  text(String(f), padL + f*(cw+gap) + 1, 8, TXT);
}
for (let c = 0; c < CELLS; c++) text(String(c), 4, padT + c*(ch+gap) + 4, TXT);

for (let f = 0; f < frames.length; f++) {
  for (let c = 0; c < CELLS; c++) {
    const on = (frames[f] >> c) & 1;
    const x = padL + f*(cw+gap), y = padT + c*(ch+gap);
    rect(x, y, cw, ch, on ? ON : OFF);
    rect(x, y, cw, 1, GRID); rect(x, y+ch-1, cw, 1, GRID);
    rect(x, y, 1, ch, GRID); rect(x+cw-1, y, 1, ch, GRID);
  }
}

const raw = Buffer.alloc((W * 3 + 1) * H);
for (let y = 0; y < H; y++) {
  raw[y * (W*3+1)] = 0;
  buf.copy(raw, y*(W*3+1)+1, y*W*3, (y+1)*W*3);
}
const T = (() => { const t = []; for (let n = 0; n < 256; n++) { let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
const crc32 = b => { let c = 0xFFFFFFFF; for (const x of b) c = T[(c ^ x) & 0xFF] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; };
const chunk = (type, data) => {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
};
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4);
ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
fs.writeFileSync(outPath, Buffer.concat([
  Buffer.from([137,80,78,71,13,10,26,10]),
  chunk('IHDR', ihdr),
  chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
  chunk('IEND', Buffer.alloc(0)),
]));
console.log(`${outPath}  ${W}x${H}  ${frames.length} ticks`);
