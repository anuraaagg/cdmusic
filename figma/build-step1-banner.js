// Step 1: LA/Banner playing variant near node 360:2854
await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
await figma.loadFontAsync({ family: 'Roboto Mono', style: 'Medium' });

const C = {
  surface: { r: 248/255, g: 247/255, b: 244/255 },
  text: { r: 13/255, g: 12/255, b: 10/255 },
  accent: { r: 234/255, g: 43/255, b: 7/255 },
  track: { r: 215/255, g: 217/255, b: 217/255 },
  hairline: { r: 34/255, g: 34/255, b: 32/255 },
  white: { r: 1, g: 1, b: 1 },
};

function solid(color, opacity = 1) {
  return [{ type: 'SOLID', color, opacity }];
}

function txt(chars, size, style, opacity = 1, mono = false) {
  const t = figma.createText();
  t.fontName = { family: mono ? 'Roboto Mono' : 'Inter', style: mono ? 'Medium' : style };
  t.characters = chars;
  t.fontSize = size;
  t.fills = solid(C.text, opacity);
  if (mono) t.textCase = 'UPPER';
  return t;
}

const ref = await figma.getNodeByIdAsync('360:2854');
const startX = ref && 'x' in ref ? ref.x + ref.width + 120 : 2400;
const startY = ref && 'y' in ref ? ref.y : 0;

const section = figma.createSection();
section.name = 'Live Activity & Widgets';
section.x = startX;
section.y = startY;
section.resizeWithoutConstraints(900, 1100);
figma.currentPage.appendChild(section);

const banner = figma.createFrame();
banner.name = 'LA/Banner — playing';
banner.resize(361, 84);
banner.cornerRadius = 22;
banner.fills = solid(C.surface);
banner.layoutMode = 'VERTICAL';
banner.paddingLeft = 12;
banner.paddingRight = 12;
banner.paddingTop = 10;
banner.paddingBottom = 10;
banner.itemSpacing = 6;
banner.x = startX + 40;
banner.y = startY + 40;
figma.currentPage.appendChild(banner);

const header = figma.createFrame();
header.name = 'Header';
header.layoutMode = 'HORIZONTAL';
header.itemSpacing = 8;
header.counterAxisAlignItems = 'CENTER';
header.layoutSizingHorizontal = 'FILL';
header.fills = [];

const logo = figma.createFrame();
logo.resize(28, 28);
logo.cornerRadius = 4;
logo.fills = solid(C.hairline, 0.15);
const logoT = txt('CR', 9, 'Semi Bold', 0.6);
logo.appendChild(logoT);
logoT.x = 8; logoT.y = 8;
header.appendChild(logo);

const status = figma.createFrame();
status.layoutMode = 'HORIZONTAL';
status.paddingLeft = 12; status.paddingRight = 12;
status.paddingTop = 4; status.paddingBottom = 4;
status.cornerRadius = 11;
status.fills = solid(C.surface);
status.strokes = solid(C.hairline, 0.2);
status.strokeWeight = 1;
status.appendChild(txt('PLAYING', 11, 'Semi Bold'));
header.appendChild(status);

const counter = figma.createFrame();
counter.layoutMode = 'HORIZONTAL';
counter.paddingLeft = 10; counter.paddingRight = 10;
counter.paddingTop = 4; counter.paddingBottom = 4;
counter.cornerRadius = 11;
counter.fills = solid(C.surface);
counter.strokes = solid(C.hairline, 0.2);
counter.strokeWeight = 1;
counter.appendChild(txt('03/12', 11, 'Semi Bold', 1, true));
header.appendChild(counter);

banner.appendChild(header);

const main = figma.createFrame();
main.name = 'Main';
main.layoutMode = 'HORIZONTAL';
main.itemSpacing = 8;
main.counterAxisAlignItems = 'CENTER';
main.layoutSizingHorizontal = 'FILL';
main.fills = [];

const disc = figma.createEllipse();
disc.resize(52, 52);
disc.fills = solid(C.track);
disc.strokes = solid(C.hairline, 0.25);
disc.strokeWeight = 1;
main.appendChild(disc);

const textCol = figma.createFrame();
textCol.layoutMode = 'VERTICAL';
textCol.itemSpacing = 2;
textCol.layoutSizingHorizontal = 'FILL';
textCol.fills = [];
textCol.appendChild(txt('Snoopy for President', 15, 'Semi Bold'));
textCol.appendChild(txt('Vince Guaraldi Trio', 13, 'Regular', 0.55));
main.appendChild(textCol);

const transport = figma.createFrame();
transport.layoutMode = 'HORIZONTAL';
transport.itemSpacing = 0;
transport.fills = [];
for (const label of ['⏮', '▶', '⏭']) {
  const b = figma.createFrame();
  b.resize(44, 44);
  b.fills = [];
  const ic = txt(label, label === '▶' ? 12 : 16, label === '▶' ? 'Semi Bold' : 'Regular', label === '▶' ? 1 : 0.7);
  if (label === '▶') ic.fills = solid(C.white);
  b.appendChild(ic);
  ic.x = 16; ic.y = 14;
  if (label === '▶') {
    const circle = figma.createEllipse();
    circle.resize(28, 28);
    circle.fills = solid(C.accent);
    b.insertChild(0, circle);
    circle.x = 8; circle.y = 8;
    ic.x = 17; ic.y = 14;
  }
  transport.appendChild(b);
}
main.appendChild(transport);
banner.appendChild(main);

const progressRow = figma.createFrame();
progressRow.layoutMode = 'HORIZONTAL';
progressRow.itemSpacing = 8;
progressRow.counterAxisAlignItems = 'CENTER';
progressRow.layoutSizingHorizontal = 'FILL';
progressRow.fills = [];

const bar = figma.createFrame();
bar.resize(180, 6);
bar.cornerRadius = 3;
bar.fills = solid(C.track);
bar.clipsContent = true;
const fill = figma.createRectangle();
fill.resize(76, 6);
fill.fills = solid(C.accent);
fill.cornerRadius = 3;
bar.appendChild(fill);
progressRow.appendChild(bar);
progressRow.appendChild(txt('1:42 / 3:58', 11, 'Medium', 0.55, true));
banner.appendChild(progressRow);

return {
  success: true,
  createdNodeIds: [section.id, banner.id],
  page: figma.currentPage.name,
  file: figma.root.name,
  startX,
  startY,
  refFound: !!ref,
};
