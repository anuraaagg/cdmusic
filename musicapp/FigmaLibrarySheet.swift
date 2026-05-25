import SwiftUI
import MediaPlayer

struct LibraryRowModel: Identifiable {
    let id: Int
    let displayNumber: Int
    let title: String
    let isPlaying: Bool
    let mediaItem: MPMediaItem?
}

// MARK: - FigmaLibrarySheet
//
// Figma `301:2340` — library bottom sheet opened by the JAM dial plate.
// Track rows `301:2369` — scrollable list with Apple-style detents (peek / medium / large).

struct FigmaLibrarySheet: View {
    @ObservedObject var vm: MusicPlayerViewModel
    @FocusState private var searchFocused: Bool
    @State private var searchText = ""
    @State private var dragOffset: CGFloat = 0
    @State private var dragStartHeight: CGFloat = 0
    @State private var isDragging = false

    private var s: CGFloat { vm.figmaLayoutScale }
    private var lib: FigmaTheme.Library.Type { FigmaTheme.Library.self }

    var body: some View {
        GeometryReader { geo in
            let screenH = geo.size.height
            let bottomInset = geo.safeAreaInsets.bottom
            let baseHeight = vm.libraryDetent.height(screenHeight: screenH, scale: s)
            let sheetHeight = max(lib.minSheetHeight * s, baseHeight - dragOffset)

            ZStack(alignment: .bottom) {
                Color.black.opacity(scrimOpacity(for: sheetHeight, screenH: screenH))
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                sheetContent(bottomInset: bottomInset, screenHeight: screenH, baseHeight: baseHeight)
                    .frame(height: sheetHeight)
                    .frame(maxWidth: .infinity)
                    .background(FigmaTheme.panelGrey)
                    .clipShape(sheetShape)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("library.sheet")
        .onAppear { searchText = vm.searchQuery }
        .onChange(of: searchText) { _, value in
            if vm.searchQuery != value { vm.searchQuery = value }
        }
        .onChange(of: vm.searchQuery) { _, value in
            if searchText != value { searchText = value }
        }
    }

    // MARK: - Sheet body

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: lib.sheetCorner * s,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: lib.sheetCorner * s,
            style: .continuous
        )
    }

    private func sheetContent(bottomInset: CGFloat, screenHeight: CGFloat, baseHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                FigmaSheetTopGroove(scale: s)
                    .padding(.top, 12 * s)
                    .accessibilityIdentifier("library.groove")

                header
                    .padding(.top, 24 * s)

                searchStrip
                    .padding(.top, 24 * s)
            }
            .contentShape(Rectangle())
            .gesture(sheetDrag(screenHeight: screenHeight, baseHeight: baseHeight))

            listPanel
                .padding(.top, 8 * s)
                .padding(.bottom, 24 * s + bottomInset + FigmaTheme.homeIndicatorClearance)
        }
    }

    // MARK: - Detent drag

    private func sheetDrag(screenHeight: CGFloat, baseHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragStartHeight = baseHeight
                    vm.impact(.rigid)
                }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                isDragging = false
                let flick = value.predictedEndTranslation.height - value.translation.height
                let projected = dragStartHeight - value.translation.height - flick * 0.25
                let dismissThreshold = lib.minSheetHeight * s * 0.72

                if projected < dismissThreshold || (vm.libraryDetent == .peek && value.translation.height > 80) {
                    dismiss()
                } else {
                    let nearest = LibraryDetent.nearest(to: projected, screenHeight: screenHeight, scale: s)
                    vm.setLibraryDetent(nearest)
                }
                dragOffset = 0
            }
    }

    private func scrimOpacity(for sheetHeight: CGFloat, screenH: CGFloat) -> Double {
        let progress = min(1, sheetHeight / (screenH * 0.92))
        return 0.28 + 0.32 * progress
    }

    // MARK: - Header (`301:2343`)

    private var header: some View {
        VStack(spacing: 8 * s) {
            HStack {
                Image(FigmaImage.cratesLogo)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 48 * s, height: 20 * s)

                Spacer(minLength: 0)

                Button(action: dismiss) {
                    ZStack {
                        Rectangle()
                            .stroke(Color(red: 0.24, green: 0.24, blue: 0.24), lineWidth: 0.32 * s)
                            .frame(width: 24 * s, height: 24 * s)
                        Image(systemName: "xmark")
                            .font(.system(size: 9 * s, weight: .medium))
                            .foregroundStyle(FigmaTheme.textDark)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close library")
                .accessibilityIdentifier("library.close")
            }
            .overlay {
                Text("LIBRARY")
                    .font(FigmaFont.libraryTitle(18 * s))
                    .foregroundStyle(FigmaTheme.textDark)
            }
            .padding(.horizontal, lib.headerHPadding * s)

            Rectangle()
                .fill(FigmaTheme.textDark.opacity(0.75))
                .frame(height: 2 * s)
                .padding(.horizontal, lib.headerHPadding * s)
        }
    }

    // MARK: - Search strip (`301:2355`)

    private var searchStrip: some View {
        let border = FigmaTheme.hairlineBorder

        return HStack(spacing: 0) {
            Button {
                searchText = ""
                vm.searchQuery = ""
                searchFocused = false
                vm.impact(.light)
            } label: {
                FigmaAsterisk(color: .red)
                    .frame(width: 14 * s, height: 14 * s)
                    .padding(12 * s)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: 38 * s, height: lib.stripHeight * s)
            .accessibilityLabel("Clear search")
            .accessibilityIdentifier("library.searchClear")

            HStack(spacing: 0) {
                TextField("", text: $searchText, prompt: searchPrompt)
                    .font(.custom("Helvetica", size: 12 * s))
                    .tracking(-0.96 * s)
                    .foregroundStyle(.black)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .padding(.horizontal, 12 * s)
                    .accessibilityIdentifier("library.search")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .leading) {
                Rectangle().fill(border).frame(width: 1)
            }

            Button {
                searchFocused = false
                vm.impact(.light)
            } label: {
                Text("SEARCH")
                    .font(.custom("Helvetica", size: 12 * s))
                    .tracking(-0.96 * s)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12 * s)
            }
            .buttonStyle(.plain)
            .frame(height: lib.stripHeight * s)
            .overlay(alignment: .leading) {
                Rectangle().fill(border).frame(width: 1)
            }
            .accessibilityIdentifier("library.searchSubmit")
        }
        .frame(maxWidth: .infinity)
        .frame(height: lib.stripHeight * s)
        .background(Color.white)
        .overlay(Rectangle().stroke(border, lineWidth: 1))
    }

    private var searchPrompt: Text {
        Text(searchText.isEmpty ? "| search songs, artists, albums" : "|")
            .font(.custom("Helvetica", size: 12 * s))
            .foregroundStyle(.black.opacity(searchText.isEmpty ? 0.45 : 1))
    }

    // MARK: - List panel (`301:2363` + scrollable `301:2369`)

    private var listPanel: some View {
        VStack(spacing: 0) {
            listHeader
                .padding(.horizontal, lib.contentHPadding * s)
                .padding(.top, 24 * s)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if vm.libraryAllRows.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.libraryAllRows) { row in
                            FigmaLibraryTrackRow(row: row, scale: s) {
                                vm.playLibraryRow(at: row.id)
                                dismiss()
                            }
                            .accessibilityIdentifier("library.row.\(row.id)")
                        }
                    }
                }
                .id(vm.searchQuery)
            }
            .scrollIndicators(.visible)
            .accessibilityIdentifier("library.trackList")
            .padding(.top, 16 * s)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(FigmaTheme.jamPillFill)
    }

    private var listHeader: some View {
        VStack(spacing: 8 * s) {
            HStack(alignment: .firstTextBaseline) {
                Text("TRACK LIST // SETLIST")
                    .font(FigmaFont.mono(18 * s, weight: .heavy))
                    .foregroundStyle(FigmaTheme.textDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 8 * s)

                Text("\(vm.libraryTotalCount)")
                    .font(FigmaFont.mono(18 * s, weight: .heavy))
                    .foregroundStyle(FigmaTheme.textDark)
                    .accessibilityIdentifier("library.trackCount")
                    .accessibilityLabel("Track count")
                    .accessibilityValue("\(vm.libraryTotalCount)")
            }

            Rectangle()
                .fill(FigmaTheme.textDark.opacity(0.75))
                .frame(height: 2 * s)
        }
    }

    private var emptyState: some View {
        Text("No tracks match your search.")
            .font(FigmaFont.mono(14 * s))
            .foregroundStyle(FigmaTheme.textDark.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, lib.contentHPadding * s)
            .padding(.vertical, 24 * s)
            .accessibilityIdentifier("library.empty")
    }

    private func dismiss() {
        vm.impact(.light)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            vm.closeLibrary()
        }
    }
}

// MARK: - Track row (`301:2370`)

struct FigmaLibraryTrackRow: View {
    let row: LibraryRowModel
    var scale: CGFloat = 1
    let action: () -> Void

    private static let rowBorder = Color(red: 13 / 255, green: 12 / 255, blue: 10 / 255).opacity(0.13)
    private static let indexColor = Color(red: 13 / 255, green: 12 / 255, blue: 10 / 255)
    private static let titleColor = Color(red: 26 / 255, green: 24 / 255, blue: 22 / 255)

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                Text(String(format: "[ %02d ]", row.displayNumber))
                    .font(FigmaFont.mono(12 * scale))
                    .foregroundStyle(Self.indexColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.leading, FigmaTheme.Library.contentHPadding * scale)

                Text(row.title)
                    .font(FigmaFont.mono(14 * scale))
                    .foregroundStyle(Self.titleColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.leading, 16 * scale)
                    .frame(maxWidth: .infinity, alignment: .leading)

                T3MachineMark(size: 24 * scale)
                    .opacity(row.isPlaying ? 1 : 0.85)
                    .padding(.trailing, FigmaTheme.Library.contentHPadding * scale)
            }
            .padding(.vertical, 6 * scale)
            .frame(minHeight: FigmaTheme.Library.rowHeight * scale)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Self.rowBorder)
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(row.title)
        .accessibilityAddTraits(row.isPlaying ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview("Library sheet — scrollable") {
    FigmaLibrarySheet(vm: MusicPlayerViewModel())
}

#Preview("Track rows — 301:2369") {
    VStack(spacing: 0) {
        FigmaLibraryTrackRow(
            row: LibraryRowModel(id: 0, displayNumber: 2, title: "Wednesday afternoon, jazz serenade", isPlaying: true, mediaItem: nil),
            action: {}
        )
        FigmaLibraryTrackRow(
            row: LibraryRowModel(id: 1, displayNumber: 3, title: "Thursday evening, rock concert", isPlaying: false, mediaItem: nil),
            action: {}
        )
    }
    .padding(.horizontal, 20)
    .background(FigmaTheme.jamPillFill)
}
