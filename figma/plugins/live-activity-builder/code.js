// cdmusic Live Activity Builder — targets page "marginalia" (165:1393)
// Plugins → Development → Import plugin from manifest… → Run

(async () => {
  const TARGET_PAGE_ID = "165:1393";
  const C = {
    surface: { r: 248 / 255, g: 247 / 255, b: 244 / 255 },
    text: { r: 13 / 255, g: 12 / 255, b: 10 / 255 },
    accent: { r: 234 / 255, g: 43 / 255, b: 7 / 255 },
    track: { r: 215 / 255, g: 217 / 255, b: 217 / 255 },
    hairline: { r: 34 / 255, g: 34 / 255, b: 32 / 255 },
    black: { r: 0, g: 0, b: 0 },
    white: { r: 1, g: 1, b: 1 },
  };

  function solid(color, opacity) {
    if (opacity === undefined) opacity = 1;
    return [{ type: "SOLID", color: color, opacity: opacity }];
  }

  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Medium" });
  await figma.loadFontAsync({ family: "Roboto Mono", style: "Medium" });

  function makeText(chars, size, style, opacity, mono) {
    if (opacity === undefined) opacity = 1;
    var t = figma.createText();
    t.fontName = {
      family: mono ? "Roboto Mono" : "Inter",
      style: mono ? "Medium" : style,
    };
    t.characters = chars;
    t.fontSize = size;
    t.fills = solid(C.text, opacity);
    if (mono) t.textCase = "UPPER";
    return t;
  }

  function alFrame(name, dir) {
    var f = figma.createFrame();
    f.name = name;
    f.layoutMode = dir === "V" ? "VERTICAL" : "HORIZONTAL";
    f.primaryAxisSizingMode = "AUTO";
    f.counterAxisSizingMode = "AUTO";
    f.fills = [];
    return f;
  }

  function makePill(label, minW) {
    var pill = alFrame("LA/Pill/" + label, "H");
    pill.cornerRadius = 11;
    pill.paddingLeft = 12;
    pill.paddingRight = 12;
    pill.paddingTop = 4;
    pill.paddingBottom = 4;
    pill.fills = solid(C.surface);
    pill.strokes = solid(C.hairline, 0.2);
    pill.strokeWeight = 1;
    pill.appendChild(makeText(label, 11, "Semi Bold", 1, label.indexOf("/") >= 0));
    if (minW) pill.minWidth = minW;
    return pill;
  }

  function makePlayButton(pause, size, hit) {
    if (pause === undefined) pause = false;
    if (size === undefined) size = 28;
    if (hit === undefined) hit = 44;
    var wrap = figma.createFrame();
    wrap.name = pause ? "LA/PauseButton" : "LA/PlayButton";
    wrap.resize(hit, hit);
    wrap.fills = [];
    var circle = figma.createEllipse();
    circle.resize(size, size);
    circle.fills = solid(C.accent);
    circle.x = (hit - size) / 2;
    circle.y = (hit - size) / 2;
    wrap.appendChild(circle);
    var icon = makeText(pause ? "||" : ">", pause ? 10 : 12, "Semi Bold", 1, false);
    icon.fills = solid(C.white);
    icon.x = (hit - icon.width) / 2 + (pause ? 0 : 1);
    icon.y = (hit - icon.height) / 2;
    wrap.appendChild(icon);
    return wrap;
  }

  function makeSkip(label, hit) {
    if (hit === undefined) hit = 44;
    var btn = figma.createFrame();
    btn.name = "LA/Skip/" + label;
    btn.resize(hit, hit);
    btn.fills = [];
    var t = makeText(label, hit <= 36 ? 14 : 16, "Regular", 0.7, false);
    t.x = (hit - t.width) / 2;
    t.y = (hit - t.height) / 2;
    btn.appendChild(t);
    return btn;
  }

  function makeProgress(fraction, width) {
    if (width === undefined) width = 180;
    var row = figma.createFrame();
    row.name = "LA/ProgressBar";
    row.resize(width, 6);
    row.cornerRadius = 3;
    row.fills = solid(C.track);
    row.clipsContent = true;
    var fill = figma.createRectangle();
    fill.resize(Math.max(6, width * fraction), 6);
    fill.fills = solid(C.accent);
    fill.cornerRadius = 3;
    row.appendChild(fill);
    return row;
  }

  function makeDisc(size) {
    var disc = figma.createEllipse();
    disc.name = "LA/DiscThumb";
    disc.resize(size, size);
    disc.fills = solid(C.track);
    disc.strokes = solid(C.hairline, 0.25);
    disc.strokeWeight = 1;
    return disc;
  }

  function makeLogo(size) {
    var f = figma.createFrame();
    f.name = "LA/Logo";
    f.resize(size, size);
    f.cornerRadius = 4;
    f.fills = solid(C.hairline, 0.15);
    var t = makeText("CR", 9, "Semi Bold", 0.6, false);
    t.x = (size - t.width) / 2;
    t.y = (size - t.height) / 2;
    f.appendChild(t);
    return f;
  }

  function buildBanner(state) {
    var isPaused = state === "paused";
    var isLong = state === "longTitle";

    var banner = figma.createComponent();
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

    var header = alFrame("Header", "H");
    header.itemSpacing = 8;
    header.counterAxisAlignItems = "CENTER";
    header.appendChild(makeLogo(28));
    var pills = alFrame("Pills", "H");
    pills.itemSpacing = -16;
    pills.counterAxisAlignItems = "CENTER";
    pills.appendChild(makePill(isPaused ? "PAUSED" : "PLAYING", 72));
    pills.appendChild(makePill("03/12", 56));
    header.appendChild(pills);
    header.layoutSizingHorizontal = "FILL";
    banner.appendChild(header);

    var main = alFrame("Main", "H");
    main.itemSpacing = 8;
    main.counterAxisAlignItems = "CENTER";
    main.appendChild(makeDisc(52));
    var textCol = alFrame("TextColumn", "V");
    textCol.itemSpacing = 2;
    var title = isLong
      ? "Song Name That Keeps Going And Going…"
      : "Snoopy for President";
    textCol.appendChild(makeText(title, 15, "Semi Bold", 1, false));
    textCol.appendChild(makeText("Vince Guaraldi Trio", 13, "Regular", 0.55, false));
    textCol.layoutSizingHorizontal = "FILL";
    main.appendChild(textCol);
    var transport = alFrame("Transport", "H");
    transport.itemSpacing = 0;
    transport.appendChild(makeSkip("|<"));
    transport.appendChild(makePlayButton(!isPaused));
    transport.appendChild(makeSkip(">|"));
    main.appendChild(transport);
    main.layoutSizingHorizontal = "FILL";
    banner.appendChild(main);

    var progressRow = alFrame("ProgressRow", "H");
    progressRow.itemSpacing = 8;
    progressRow.counterAxisAlignItems = "CENTER";
    progressRow.appendChild(makeProgress(isPaused ? 0.18 : 0.42));
    progressRow.appendChild(makeText("1:42 / 3:58", 11, "Medium", 0.55, true));
    progressRow.layoutSizingHorizontal = "FILL";
    banner.appendChild(progressRow);

    return banner;
  }

  // ── Switch to marginalia page ──
  var page = await figma.getNodeByIdAsync(TARGET_PAGE_ID);
  if (!page || page.type !== "PAGE") {
    figma.closePlugin("Could not find page 165:1393");
    return;
  }
  await figma.setCurrentPageAsync(page);

  var startX = 200;
  var startY = 200;
  for (var i = 0; i < page.children.length; i++) {
    var c = page.children[i];
    if ("x" in c && "width" in c) {
      startX = Math.max(startX, c.x + c.width + 120);
    }
  }

  var section = figma.createSection();
  section.name = "Live Activity & Widgets";
  section.x = startX;
  section.y = startY;
  section.resizeWithoutConstraints(1300, 2000);
  page.appendChild(section);

  var playing = buildBanner("playing");
  var paused = buildBanner("paused");
  var longTitle = buildBanner("longTitle");
  page.appendChild(playing);
  page.appendChild(paused);
  page.appendChild(longTitle);

  var set = figma.combineAsVariants([playing, paused, longTitle], page);
  set.name = "LA/Banner";
  set.x = startX + 40;
  set.y = startY + 40;

  // Lock Screen context
  var lock = figma.createFrame();
  lock.name = "Lock Screen — iPhone 15 Pro";
  lock.resize(393, 852);
  lock.fills = solid(C.black);
  lock.x = startX + 40;
  lock.y = startY + 160;
  var t1 = makeText("9:41", 15, "Semi Bold", 1, false);
  t1.fills = solid(C.white);
  t1.x = 24;
  t1.y = 16;
  lock.appendChild(t1);
  var date = makeText("Tuesday, May 26", 16, "Regular", 0.8, false);
  date.fills = solid(C.white);
  date.x = 120;
  date.y = 72;
  lock.appendChild(date);
  var inst = set.defaultVariant.createInstance();
  inst.x = 16;
  inst.y = 120;
  lock.appendChild(inst);
  page.appendChild(lock);

  // Dynamic Island — expanded
  var diExp = figma.createFrame();
  diExp.name = "LA/DynamicIsland — Expanded";
  diExp.resize(360, 80);
  diExp.cornerRadius = 44;
  diExp.fills = solid(C.black);
  diExp.x = startX + 480;
  diExp.y = startY + 160;
  var diRow = alFrame("DIRow", "H");
  diRow.itemSpacing = 8;
  diRow.counterAxisAlignItems = "CENTER";
  diRow.appendChild(makeDisc(28));
  var diText = alFrame("DIText", "V");
  diText.itemSpacing = 2;
  diText.appendChild(makeText("Snoopy for President", 14, "Semi Bold", 1, false));
  diText.appendChild(makeText("Vince Guaraldi Trio", 12, "Regular", 0.55, false));
  diText.layoutSizingHorizontal = "FILL";
  diRow.appendChild(diText);
  var diTransport = alFrame("DITransport", "H");
  diTransport.appendChild(makeSkip("|<", 36));
  diTransport.appendChild(makePlayButton(true, 24, 36));
  diTransport.appendChild(makeSkip(">|", 36));
  diRow.appendChild(diTransport);
  diRow.x = 16;
  diRow.y = 12;
  diExp.appendChild(diRow);
  page.appendChild(diExp);

  // Dynamic Island — compact
  var diComp = figma.createFrame();
  diComp.name = "LA/DynamicIsland — Compact";
  diComp.resize(360, 37);
  diComp.cornerRadius = 20;
  diComp.fills = solid(C.black);
  diComp.x = startX + 480;
  diComp.y = startY + 260;
  var d1 = makeDisc(20);
  d1.x = 12;
  d1.y = 8;
  diComp.appendChild(d1);
  var playSmall = makePlayButton(true, 16, 20);
  playSmall.x = 328;
  playSmall.y = 8;
  diComp.appendChild(playSmall);
  page.appendChild(diComp);

  // Dynamic Island — minimal
  var diMin = figma.createFrame();
  diMin.name = "LA/DynamicIsland — Minimal";
  diMin.resize(126, 37);
  diMin.cornerRadius = 20;
  diMin.fills = solid(C.black);
  diMin.x = startX + 480;
  diMin.y = startY + 320;
  var dot = figma.createEllipse();
  dot.resize(10, 10);
  dot.fills = solid(C.accent);
  dot.x = 108;
  dot.y = 13;
  diMin.appendChild(dot);
  page.appendChild(diMin);

  // Home widgets row
  var wy = startY + 420;

  var widgetS = figma.createFrame();
  widgetS.name = "LA/Widget/Small";
  widgetS.resize(158, 158);
  widgetS.cornerRadius = 22;
  widgetS.fills = solid(C.surface);
  widgetS.x = startX + 40;
  widgetS.y = wy;
  var sLogo = makeLogo(24);
  sLogo.x = 12;
  sLogo.y = 12;
  widgetS.appendChild(sLogo);
  var sDisc = makeDisc(72);
  sDisc.x = 43;
  sDisc.y = 44;
  widgetS.appendChild(sDisc);
  var sTitle = makeText("Snoopy for President", 11, "Semi Bold", 1, false);
  sTitle.x = 12;
  sTitle.y = 122;
  sTitle.resize(134, 14);
  widgetS.appendChild(sTitle);
  page.appendChild(widgetS);

  var widgetM = figma.createFrame();
  widgetM.name = "LA/Widget/Medium";
  widgetM.resize(338, 158);
  widgetM.cornerRadius = 22;
  widgetM.fills = solid(C.surface);
  widgetM.x = startX + 220;
  widgetM.y = wy;
  var mInst = set.defaultVariant.createInstance();
  mInst.resize(314, 84);
  mInst.x = 12;
  mInst.y = 37;
  widgetM.appendChild(mInst);
  page.appendChild(widgetM);

  var widgetL = figma.createFrame();
  widgetL.name = "LA/Widget/Large";
  widgetL.resize(338, 354);
  widgetL.cornerRadius = 22;
  widgetL.fills = solid(C.surface);
  widgetL.x = startX + 580;
  widgetL.y = wy;
  var lDisc = makeDisc(140);
  lDisc.x = 99;
  lDisc.y = 48;
  widgetL.appendChild(lDisc);
  var lTitle = makeText("Snoopy for President", 18, "Semi Bold", 1, false);
  lTitle.x = 40;
  lTitle.y = 204;
  widgetL.appendChild(lTitle);
  var lArtist = makeText("Vince Guaraldi Trio", 14, "Regular", 0.55, false);
  lArtist.x = 40;
  lArtist.y = 228;
  widgetL.appendChild(lArtist);
  var lBar = makeProgress(0.42, 260);
  lBar.x = 40;
  lBar.y = 256;
  widgetL.appendChild(lBar);
  var lTransport = alFrame("LTransport", "H");
  lTransport.itemSpacing = 24;
  lTransport.x = 40;
  lTransport.y = 290;
  lTransport.appendChild(makeSkip("|<"));
  lTransport.appendChild(makePlayButton(true));
  lTransport.appendChild(makeSkip(">|"));
  widgetL.appendChild(lTransport);
  page.appendChild(widgetL);

  var label = makeText("Live Activity & Widgets — cdmusic", 24, "Semi Bold", 1, false);
  label.x = startX + 40;
  label.y = startY;
  page.appendChild(label);

  figma.viewport.scrollAndZoomIntoView([section, set, lock, widgetS, widgetM, widgetL]);
  figma.closePlugin("Built on marginalia page");
})();
