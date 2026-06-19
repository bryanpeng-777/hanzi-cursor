import { Color } from 'tvision-color';

const TENCENT_BLUE = '#0052D9';
const TENCENT_BLUE_DARK_PALETTE = [
  '#1b2f51',
  '#173463',
  '#143975',
  '#103d88',
  '#0d429a',
  '#054bbe',
  '#2667d4',
  '#4582e6',
  '#699ef5',
  '#96bbf8',
];

export function generateTheme(hex: string) {
  const lowCaseHex = hex.toLowerCase();
  const [{ colors }] = Color.getColorGradations({
    colors: [lowCaseHex],
    step: 10,
  });

  const isTencentBlue = lowCaseHex === TENCENT_BLUE.toLowerCase();
  const lightPalette = [...colors];
  const darkPalette = isTencentBlue ? TENCENT_BLUE_DARK_PALETTE : [...colors].reverse();

  const genVars = (palette: string[], mode?: string) =>
    `${mode ? `:root[theme-mode="${mode}"]` : ':root'} {\n` +
    palette
      .map((color, idx) => `  --td-brand-color-${idx + 1}: ${color};`)
      .join('\n') +
    '\n}';

  const lightVars = genVars(lightPalette);
  const darkVars = genVars(darkPalette, "dark");

  return `${lightVars}\n\n${darkVars}`;
}

const args = process.argv.slice(2);
const hex = args[0];

if (!hex) {
  console.error("Usage: tsx generate_theme.ts <color>");
  process.exit(1);
}

console.log(generateTheme(hex));
