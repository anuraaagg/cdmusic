/**
 * cdmusic Live Activity & Widget — Figma build script
 *
 * Run via Cursor Figma MCP `use_figma` when rate limit resets, OR paste into
 * Figma → Plugins → Development → Run last script (if using a dev plugin).
 *
 * Target files:
 *   NEW (editable):  https://www.figma.com/design/b4jAcSoQhOTsL3s92yuTcW
 *   ORIGINAL:        https://www.figma.com/design/SuMsVkITTi0ZVnpJGHC5U7  (needs Edit seat)
 *
 * Split into 3 MCP calls if one script is too large.
 */

// ─── Tokens (FigmaTheme) ───────────────────────────────────────────
const C = {
  surface: { r: 248 / 255, g: 247 / 255, b: 244 / 255 },
  text: { r: 13 / 255, g: 12 / 255, b: 10 / 255 },
  accent: { r: 234 / 255, g: 43 / 255, b: 7 / 255 },
  track: { r: 215 / 255, g: 217 / 255, b: 217 / 255 },
  hairline: { r: 34 / 255, g: 34 / 255, b: 32 / 255 },
  black: { r: 0, g: 0, b: 0 },
  white: { r: 1, g: 1, b: 1 },
};

function solid(color, opacity = 1) {
  return [{ type: "SOLID", color, opacity }];
}

async function loadFonts() {
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Medium" });
  await figma.loadFontAsync({ family: "Roboto Mono", style: "Medium" });
}

function makeText(chars, size, weight, opacity = 1, mono = false) {
  const t = figma.createText();
  const style =
    weight === "semibold"
      ? "Semi Bold"
      : weight === "medium"
        ? "Medium"
        : "Regular";
  const family = mono ? "Roboto Mono" : "Inter";
  t.fontName = { family, style: mono ? "Medium" : style };
  t.characters = chars;
  t.fontSize = size;
  t.fills = solid(C.text, opacity);
  if (mono) t.textCase = "UPPER";
  return t;
}

function makePill(label, minW = 72) {
  const pill = figma.createAutoLayout();
  pill.name = "LA/Pill/" + label;
  pill.cornerRadius = 11;
  pill.paddingLeft = 12;
  pill.paddingRight = 12;
  pill.paddingTop = 4;
  pill.paddingBottom = 4;
  pill.fills = solid(C.surface);
  pill.strokes = solid(C.hairline, 0.2);
  pill.strokeWeight = 1;
  pill.appendChild(makeText(label, 11, "semibold", 1, label.includes("/")));
  pill.layoutSizingHorizontal = "HUG";
  pill.layoutSizingVertical = "HUG";
  pill.minWidth = minW;
  return pill;
}

function makePlayButton(pause = false, size = 28, hit = 44) {
  const wrap = figma.createFrame();
  wrap.name = pause ? "LA/PauseButton" : "LA/PlayButton";
  wrap.resize(hit, hit);
  wrap.fills = [];
  const circle = figma.createEllipse();
  circle.resize(size, size);
  circle.fills = solid(C.accent);
  circle.x = (hit - size) / 2;
  circle.y = (hit - size) / 2;
  wrap.appendChild(circle);
  const icon = makeText(pause ? "❚❚" : "▶", pause ? 10 : 12, "semibold", 1);
  icon.fills = solid(C.white);
  icon.x = (hit - icon.width) / 2 + (pause ? 0 : 1);
  icon.y = (hit - icon.height) / 2;
  wrap.appendChild(icon);
  return wrap;
}

function makeSkip(label) {
  const btn = figma.createFrame();
  btn.name = "LA/Skip/" + label;
  btn.resize(44, 44);
  btn.fills = [];
  const t = makeText(label, 16, "regular", 0.7);
  t.x = (44 - t.width) / 2;
  t.y = (44 - t.height) / 2;
  btn.appendChild(t);
  return btn;
}

function makeProgress(fraction = 0.42) {
  const row = figma.createFrame();
  row.name = "LA/ProgressBar";
  row.resize(180, 6);
  row.cornerRadius = 3;
  row.fills = solid(C.track);
  row.clipsContent = true;
  const fill = figma.createRectangle();
  fill.name = "Fill";
  fill.resize(Math.max(6, 180 * fraction), 6);
  fill.fills = solid(C.accent);
  fill.cornerRadius = 3;
  row.appendChild(fill);
  return row;
}

function makeDisc(size = 52) {
  const disc = figma.createEllipse();
  disc.name = "LA/DiscThumb";
  disc.resize(size, size);
  disc.fills = solid(C.track);
  disc.strokes = solid(C.hairline, 0.25);
  disc.strokeWeight = 1;
  return disc;
}

function makeLogoPlaceholder(size = 28) {
  const f = figma.createFrame();
  f.name = "LA/Logo";
  f.resize(size, size);
  f.cornerRadius = 4;
  f.fills = solid(C.hairline, 0.15);
  const t = makeText("CR", 9, "semibold", 0.6);
  t.x = (size - t.width) / 2;
  t.y = (size - t.height) / 2;
  f.appendChild(t);
  return f;
}

/** Build LA/Banner component (361×84) */
function buildBanner(state = "playing") {
  const isPaused = state === "paused";
  const isLong = state === "longTitle";

  const banner = figma.createComponent();
  banner.name = "State=" + state;
  banner.resize(361, 84);
  banner.cornerRadius = 22;
  banner.fills = solid(C.surface);
  banner.layoutMode = "VERTICAL";
  banner.paddingLeft = 12;
  banner.paddingRight = 12;
  banner.paddingTop = 10;
  banner.paddingBottom = 10;
  banner.itemSpacing = 6;
  banner.primaryAxisSizingMode = "FIXED";
  banner.counterAxisSizingMode = "FIXED";

  // Header row
  const header = figma.createAutoLayout("HORIZONTAL", {
    name: "Header",
    itemSpacing: 8,
    counterAxisAlignItems: "CENTER",
  });
  header.appendChild(makeLogoPlaceholder(28));
  const pills = figma.createAutoLayout("HORIZONTAL", {
    name: "Pills",
    itemSpacing: -16,
    counterAxisAlignItems: "CENTER",
  });
  pills.appendChild(makePill(isPaused ? "PAUSED" : "PLAYING", 72));
  pills.appendChild(makePill("03/12", 56));
  header.appendChild(pills);
  header.layoutSizingHorizontal = "FILL";
  banner.appendChild(header);

  // Main row
  const main = figma.createAutoLayout("HORIZONTAL", {
    name: "Main",
    itemSpacing: 8,
    counterAxisAlignItems: "CENTER",
  });
  main.appendChild(makeDisc(52));
  const textCol = figma.createAutoLayout("VERTICAL", { name: "TextColumn", itemSpacing: 2 });
  const title = isLong
    ? "Song Name That Keeps Going And Going…"
    : "Snoopy for President";
  textCol.appendChild(makeText(title, 15, "semibold"));
  textCol.appendChild(makeText("Vince Guaraldi Trio", 13, "regular", 0.55));
  textCol.layoutSizingHorizontal = "FILL";
  main.appendChild(textCol);
  const transport = figma.createAutoLayout("HORIZONTAL", {
    name: "Transport",
    itemSpacing: 0,
    counterAxisAlignItems: "CENTER",
  });
  transport.appendChild(makeSkip("⏮"));
  transport.appendChild(makePlayButton(!isPaused));
  transport.appendChild(makeSkip("⏭"));
  main.appendChild(transport);
  main.layoutSizingHorizontal = "FILL";
  banner.appendChild(main);

  // Progress row
  const progressRow = figma.createAutoLayout("HORIZONTAL", {
    name: "ProgressRow",
    itemSpacing: 8,
    counterAxisAlignItems: "CENTER",
  });
  progressRow.appendChild(makeProgress(isPaused ? 0.18 : 0.42));
  progressRow.appendChild(makeText("1:42 / 3:58", 11, "medium", 0.55, true));
  progressRow.layoutSizingHorizontal = "FILL";
  banner.appendChild(progressRow);

  return banner;
}

/** Lock screen context frame */
function buildLockScreen(bannerInstance, yOffset = 0) {
  const screen = figma.createFrame();
  screen.name = "Lock Screen — iPhone 15 Pro";
  screen.resize(393, 852);
  screen.fills = solid(C.black);
  screen.x = yOffset;
  screen.y = 0;

  const time = makeText("9:41", 15, "semibold", 1);
  time.fills = solid(C.white);
  time.x = 24;
  time.y = 16;
  screen.appendChild(time);

  const date = makeText("Tuesday, May 26", 16, "regular", 0.8);
  date.fills = solid(C.white);
  date.x = (393 - date.width) / 2;
  date.y = 72;
  screen.appendChild(date);

  const inst = bannerInstance.createInstance();
  inst.x = 16;
  inst.y = 120;
  screen.appendChild(inst);

  const clock = makeText("12:45", 96, "regular", 0.9);
  clock.fills = solid(C.white);
  clock.fontSize = 80;
  clock.x = (393 - clock.width) / 2;
  clock.y = 320;
  screen.appendChild(clock);

  return screen;
}

// ─── Main (use_figma entry) ────────────────────────────────────────
await loadFonts();
figma.currentPage.name = "Live Activity & Widgets";

let maxX = 0;
for (const child of figma.currentPage.children) {
  maxX = Math.max(maxX, child.x + child.width);
}
const startX = maxX + 200;

const playing = buildBanner("playing");
playing.x = startX;
playing.y = 0;
figma.currentPage.appendChild(playing);

const paused = buildBanner("paused");
paused.x = startX + 400;
paused.y = 0;
figma.currentPage.appendChild(paused);

const longTitle = buildBanner("longTitle");
longTitle.x = startX + 800;
longTitle.y = 0;
figma.currentPage.appendChild(longTitle);

const set = figma.combineAsVariants([playing, paused, longTitle], figma.currentPage);
set.name = "LA/Banner";
set.x = startX;
set.y = 0;

const playingInst = set.defaultVariant.createInstance();
const lock = buildLockScreen(playingInst, startX);
lock.y = 120;
figma.currentPage.appendChild(lock);

// Dynamic Island expanded
const di = figma.createFrame();
di.name = "LA/DynamicIsland — Expanded";
di.resize(360, 80);
di.cornerRadius = 44;
di.fills = solid(C.black);
di.x = startX;
di.y = lock.y + lock.height + 48;
figma.currentPage.appendChild(di);

const diMain = figma.createAutoLayout("HORIZONTAL", {
  itemSpacing: 8,
  counterAxisAlignItems: "CENTER",
});
diMain.x = 16;
diMain.y = 12;
diMain.resize(328, 56);
di.appendChild(makeDisc(28));
const diText = figma.createAutoLayout("VERTICAL", { itemSpacing: 2 });
diText.appendChild(makeText("Snoopy for President", 14, "semibold"));
diText.appendChild(makeText("Vince Guaraldi Trio", 12, "regular", 0.55));
diMain.appendChild(diText);
const diTransport = figma.createAutoLayout("HORIZONTAL", { itemSpacing: 0 });
diTransport.appendChild(makeSkip("⏮"));
diTransport.appendChild(makePlayButton(true, 24, 36));
diTransport.appendChild(makeSkip("⏭"));
diMain.appendChild(diTransport);
di.appendChild(diMain);

const createdNodeIds = [set.id, lock.id, di.id];
return {
  success: true,
  createdNodeIds,
  componentSetId: set.id,
  message: "Built LA/Banner variants + Lock Screen + Dynamic Island expanded",
};
