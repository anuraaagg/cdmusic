import SwiftUI
import UIKit
import MediaPlayer
import AVFoundation
import Combine

// MARK: - Types

enum CDSkin: String, CaseIterable {
    case normal = "NORMAL"
    case led    = "LED"
    case crt    = "CRT"
    case vinyl  = "VINYL"
}

/// Apple-style library sheet detents — peek → medium → large.
enum LibraryDetent: Int, CaseIterable, Comparable {
    case peek = 0
    case medium = 1
    case large = 2

    static func < (lhs: LibraryDetent, rhs: LibraryDetent) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    func height(screenHeight: CGFloat, scale: CGFloat) -> CGFloat {
        let safe = FigmaTheme.homeIndicatorClearance
        switch self {
        case .peek:   return min(screenHeight * 0.34, (248 + safe) * scale)
        case .medium: return screenHeight * 0.54
        case .large:  return screenHeight * 0.92
        }
    }

    func nextHigher() -> LibraryDetent? {
        LibraryDetent(rawValue: rawValue + 1)
    }

    func nextLower() -> LibraryDetent? {
        LibraryDetent(rawValue: rawValue - 1)
    }

    static func nearest(to height: CGFloat, screenHeight: CGFloat, scale: CGFloat) -> LibraryDetent {
        allCases.min {
            abs($0.height(screenHeight: screenHeight, scale: scale) - height)
                < abs($1.height(screenHeight: screenHeight, scale: scale) - height)
        } ?? .medium
    }
}

enum RepeatMode { case none, one, all }

// MARK: - Volume Manager
// Wraps MPVolumeView to allow programmatic volume changes (App Store safe)

final class VolumeManager {
    static let shared = VolumeManager()
    private let volumeView = MPVolumeView(frame: CGRect(x: -500, y: -500, width: 1, height: 1))

    private init() {}

    func attach(to window: UIWindow?) {
        window?.addSubview(volumeView)
    }

    /// Sets output volume directly (absolute 0–1).
    func setVolume(_ level: Float) {
        guard let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first else { return }
        let v = max(0, min(1, level))
        DispatchQueue.main.async { slider.setValue(v, animated: false) }
    }

    func change(by delta: Float) {
        guard let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first else { return }
        let v = max(0, min(1, slider.value + delta))
        DispatchQueue.main.async { slider.setValue(v, animated: false) }
    }
}

// MARK: - ViewModel

@MainActor
final class MusicPlayerViewModel: ObservableObject {

    // Playback
    @Published var isPlaying   = false
    @Published var isShuffle   = false
    @Published var repeatMode: RepeatMode = .none
    @Published var currentTime: Double = 0
    @Published var duration:    Double = 1

    // Now playing metadata
    @Published var trackTitle:   String    = "Not Playing"
    @Published var artistName:   String    = "—"
    @Published var albumTitle:   String    = ""
    @Published var albumArtwork: UIImage?  = nil

    // CD animation
    @Published var cdAngle:       Double = 0
    @Published var shimmerPhase:  Double = 0
    @Published var isScratching:  Bool   = false
    @Published var scratchVelocity: Double = 0
    @Published var showVolumeHUD: Bool   = false
    @Published var skinFlash:     Bool   = false

    // Crate / panel slide
    @Published var crateIsOpen:       Bool = false
    @Published var panelDragOffset:   CGFloat = 0
    @Published var crateActiveIndex:  Int = 2
    @Published var trackDotIndex:     Int = 0

    let albums = AlbumCatalog.entries

    /// 0 = JAM strip only (CRATES visible); 1 = full control card (CRATES hidden behind panel).
    @Published var controlPanelRevealFraction: CGFloat = 1
    /// Tinted disc graphic for CD hero when library artwork is unavailable.
    @Published var heroDiscPlaceholder: UIImage? = UIImageFigma.tintedDisc(CrateCatalog.entries[2].accentUIKit())

    @Published var figmaLayoutScale: CGFloat = 1

    // Volume (display only — actual change goes through VolumeManager)
    @Published var volume: Float = 0.5

    // UI sheets
    @Published var showSettings = false
    @Published var showLibrary  = false

    // Settings
    @Published var selectedSkin:         CDSkin = .normal
    @Published var isHapticEnabled:      Bool   = true
    @Published var isSoundEnabled:       Bool   = true

    // Library
    @Published var tracks:       [MPMediaItem] = []
    @Published var searchQuery:  String        = ""
    @Published var libraryDetent: LibraryDetent = .medium

    // MARK: Private
    private let player = InAppPlaybackAudio.player
    private var animTimer:     AnyCancellable?
    private var progressTimer: AnyCancellable?
    private var volumeObserver: NSKeyValueObservation?
    private var volumeHUDTimer: AnyCancellable?
    private var rotationVelocity: Double = 0.75

    private enum PlaybackStore {
        static let lastPersistentID = "figma.lastTrackPersistentID"
        static let wasPlaying = "figma.lastWasPlaying"
    }

    // MARK: Init

    init() {
        selectedSkin = CrateCatalog.entries[crateActiveIndex].skin
        requestAuthAndSetup()
    }

    private func requestAuthAndSetup() {
        setupPlayerBasics()
        MPMediaLibrary.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if status == .authorized {
                    self.loadLibrary()
                }
                self.syncNowPlaying()
                self.syncPlaybackState()
            }
        }
    }

    private func setupPlayerBasics() {
        InAppPlaybackAudio.activateSession()
        InAppPlaybackAudio.suppressSystemNowPlaying()

        NotificationCenter.default.addObserver(
            self, selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(playbackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player
        )
        player.beginGeneratingPlaybackNotifications()
        observeVolume()
    }

    @objc private func nowPlayingItemChanged() {
        Task { @MainActor in self.syncNowPlaying() }
    }

    @objc private func playbackStateChanged() {
        Task { @MainActor in self.syncPlaybackState() }
    }

    private func syncNowPlaying() {
        guard let item = player.nowPlayingItem else {
            trackTitle = "Not Playing"; artistName = "—"
            albumTitle = ""; albumArtwork = nil; duration = 1; return
        }
        trackTitle   = item.title        ?? "Unknown"
        artistName   = item.artist       ?? "Unknown Artist"
        albumTitle   = item.albumTitle   ?? ""
        duration     = max(1, item.playbackDuration)
        albumArtwork = item.artwork?.image(at: CGSize(width: 300, height: 300))
        syncCrateActiveIndex(for: item)
        persistPlaybackState()
    }

    /// Keep crate carousel + hero in sync with the track that is actually playing.
    private func syncCrateActiveIndex(for item: MPMediaItem) {
        guard let trackIdx = tracks.firstIndex(where: { $0.persistentID == item.persistentID }) else { return }
        let crateIdx = trackIdx % CrateCatalog.count
        guard crateActiveIndex != crateIdx else { return }
        crateActiveIndex = crateIdx
        let crate = CrateCatalog.entries[crateIdx]
        applySkin(crate.skin)
        heroDiscPlaceholder = UIImageFigma.tintedDisc(crate.accentUIKit())
    }

    /// Maps each crate slot to a library row (cycles when library > 5 tracks).
    private func mediaItemForCrate(at index: Int) -> MPMediaItem? {
        guard !tracks.isEmpty else { return nil }
        return tracks[index % tracks.count]
    }

    private func syncPlaybackState() {
        let playing = player.playbackState == .playing

        if player.nowPlayingItem != nil {
            isPlaying = playing
        } else if playing {
            isPlaying = true
        }

        isShuffle = player.shuffleMode != .off

        switch player.repeatMode {
        case .one:          repeatMode = .one
        case .all, .default: repeatMode = .all
        default:             repeatMode = .none
        }

        if isPlaying {
            startTimers()
            InAppPlaybackAudio.suppressSystemNowPlaying()
        } else {
            stopTimers()
            InAppPlaybackAudio.suppressSystemNowPlaying()
        }
        persistPlaybackState()
    }

    private func loadLibrary() {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
        if ProcessInfo.processInfo.arguments.contains("-UITestingLibraryDemo") {
            tracks = []
            return
        }
        tracks = MPMediaQuery.songs().items ?? []
        albumArtwork = crateArtwork(for: crateActiveIndex) ?? albumArtwork
        restoreLastPlayback()
    }

    private func persistPlaybackState() {
        if let item = player.nowPlayingItem {
            UserDefaults.standard.set(item.persistentID, forKey: PlaybackStore.lastPersistentID)
        }
        UserDefaults.standard.set(isPlaying, forKey: PlaybackStore.wasPlaying)
    }

    private func restoreLastPlayback() {
        guard !tracks.isEmpty else { return }
        let storedID = UserDefaults.standard.object(forKey: PlaybackStore.lastPersistentID) as? UInt64
        guard let storedID,
              let item = tracks.first(where: { $0.persistentID == storedID }) else { return }

        let shouldPlay = UserDefaults.standard.bool(forKey: PlaybackStore.wasPlaying)
        setQueue(startingAt: item, autoplay: shouldPlay)

        if let idx = tracks.firstIndex(where: { $0.persistentID == storedID }) {
            crateActiveIndex = idx % CrateCatalog.count
            applyCratePresentation(at: crateActiveIndex)
        }
        syncNowPlaying()
        syncPlaybackState()
    }

    /// Builds a multi-item queue so skip next/previous work across the library.
    private func setQueue(startingAt item: MPMediaItem, autoplay: Bool = true) {
        if tracks.isEmpty {
            player.setQueue(with: MPMediaItemCollection(items: [item]))
        } else if let start = tracks.firstIndex(where: { $0.persistentID == item.persistentID }) {
            let queue = Array(tracks[start...]) + Array(tracks[..<start])
            player.setQueue(with: MPMediaItemCollection(items: queue))
        } else {
            player.setQueue(with: MPMediaItemCollection(items: [item]))
        }

        if autoplay {
            player.play()
            InAppPlaybackAudio.suppressSystemNowPlaying()
        } else {
            player.pause()
            InAppPlaybackAudio.suppressSystemNowPlaying()
        }
    }

    private func observeVolume() {
        InAppPlaybackAudio.activateSession()
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        volume = session.outputVolume
        volumeObserver = session.observe(\.outputVolume, options: [.new]) { [weak self] s, _ in
            Task { @MainActor [weak self] in
                self?.volume = s.outputVolume
                self?.flashVolumeHUD()
            }
        }
    }

    // MARK: - Controls

    func togglePlay() {
        impact(.medium)
        if isPlaying {
            player.pause()
            isPlaying = false
            stopTimers()
            InAppPlaybackAudio.suppressSystemNowPlaying()
        } else {
            InAppPlaybackAudio.activateSession()
            if player.nowPlayingItem == nil, let first = tracks.first {
                setQueue(startingAt: first, autoplay: true)
                syncNowPlaying()
                syncPlaybackState()
                return
            }
            player.play()
            isPlaying = true
            startTimers()
            InAppPlaybackAudio.suppressSystemNowPlaying()
        }
    }

    func skipNext() {
        impact(.light)
        guard player.nowPlayingItem != nil else {
            demoSkip(forward: true)
            return
        }
        player.skipToNextItem()
        syncNowPlaying()
    }

    func skipPrevious() {
        impact(.light)
        guard player.nowPlayingItem != nil else {
            demoSkip(forward: false)
            return
        }
        if player.currentPlaybackTime > 3 {
            player.skipToBeginning()
        } else {
            player.skipToPreviousItem()
        }
        syncNowPlaying()
    }

    /// When no MPMediaLibrary item is loaded, cycle crates / nudge time for jog + keys.
    private func demoSkip(forward: Bool) {
        if forward {
            let next = (crateActiveIndex + 1) % max(1, CrateCatalog.entries.count)
            loadCrateAsNowPlaying(at: next)
        } else {
            let count = max(1, CrateCatalog.entries.count)
            let prev = (crateActiveIndex - 1 + count) % count
            loadCrateAsNowPlaying(at: prev)
        }
        cdAngle += forward ? 90 : -90
    }

    func toggleShuffle() {
        impact(.light)
        isShuffle.toggle()
        player.shuffleMode = isShuffle ? .songs : .off
    }

    func toggleRepeat() {
        impact(.light)
        switch repeatMode {
        case .none: repeatMode = .all;  player.repeatMode = .all
        case .all:  repeatMode = .one;  player.repeatMode = .one
        case .one:  repeatMode = .none; player.repeatMode = .none
        }
    }

    func seek(to fraction: Double) {
        let t = fraction * duration
        if player.nowPlayingItem != nil {
            player.currentPlaybackTime = t
        }
        currentTime = t
    }

    func volumeUp()   { impact(.light); VolumeManager.shared.change(by:  0.10); flashVolumeHUD() }
    func volumeDown() { impact(.light); VolumeManager.shared.change(by: -0.10); flashVolumeHUD() }

    func applySkin(_ skin: CDSkin) {
        guard selectedSkin != skin else { return }
        impact(.light)
        selectedSkin = skin
        shimmerPhase += 60
        skinFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.skinFlash = false
        }
    }

    func scratch(delta: Double, velocity: Double) {
        isScratching = true
        cdAngle += delta
        shimmerPhase += abs(delta) * 1.5
        scratchVelocity = velocity
        rotationVelocity = velocity
    }

    func endScratch() {
        isScratching = false
        if isPlaying {
            rotationVelocity = scratchVelocity
        }
    }

    func openCrate() {
        crateIsOpen = true
        panelDragOffset = 0
    }

    func closeCrate() {
        crateIsOpen = false
        panelDragOffset = 0
    }

    func updatePanelDrag(_ offset: CGFloat, panelHeight: CGFloat) {
        if crateIsOpen {
            panelDragOffset = min(panelHeight, max(0, offset))
        } else {
            panelDragOffset = min(panelHeight, max(0, offset))
        }
    }

    func setCrateActiveIndex(_ index: Int) {
        crateActiveIndex = index
    }

    func loadAlbum(at index: Int) {
        guard albums.indices.contains(index) else { return }
        let album = albums[index]
        impact(.medium)
        applySkin(album.skin)
        trackTitle = album.title
        artistName = album.artist
        albumTitle = "Album"
        trackDotIndex = index % 5

        if let item = tracks.first(where: { ($0.title ?? "").localizedCaseInsensitiveContains(album.title) }) {
            play(item: item)
        } else if let item = mediaItemForCrate(at: index) {
            play(item: item)
        } else {
            duration = 237
            currentTime = 0
            if !isPlaying {
                isPlaying = true
                startTimers()
            }
        }

        closeCrate()
    }

    func flashVolumeHUD() {
        showVolumeHUD = true
        volumeHUDTimer?.cancel()
        volumeHUDTimer = Just(())
            .delay(for: .seconds(1.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.showVolumeHUD = false }
    }

    func play(item: MPMediaItem) {
        InAppPlaybackAudio.activateSession()
        setQueue(startingAt: item, autoplay: true)
        syncNowPlaying()
        syncPlaybackState()
    }

    func pauseForBackground() {
        guard isPlaying else { return }
        player.pause()
        isPlaying = false
        stopTimers()
        InAppPlaybackAudio.suppressSystemNowPlaying()
    }

    func clearQueue() {
        impact(.medium)
        player.stop()
        currentTime = 0
        InAppPlaybackAudio.suppressSystemNowPlaying()
        syncNowPlaying()
        syncPlaybackState()
    }

    // MARK: - Library sheet (`301:2340`)

    func openLibrary() {
        impact(.light)
        searchQuery = ""
        libraryDetent = .large
        showSettings = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showControlCentre()
            showLibrary = true
        }
    }

    func closeLibrary() {
        showLibrary = false
        libraryDetent = .medium
        searchFocusedDismiss()
    }

    func setLibraryDetent(_ detent: LibraryDetent, animated: Bool = true) {
        guard libraryDetent != detent else { return }
        impact(.light)
        if animated {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                libraryDetent = detent
            }
        } else {
            libraryDetent = detent
        }
    }

    func playLibraryRow(at globalIndex: Int) {
        impact(.medium)
        let rows = libraryAllRows
        guard rows.indices.contains(globalIndex) else { return }
        let row = rows[globalIndex]
        if let item = row.mediaItem {
            play(item: item)
        } else {
            trackTitle = row.title
            artistName = "Library"
            duration = 237
            currentTime = 0
            if !isPlaying {
                isPlaying = true
                startTimers()
            }
        }
    }

    private func searchFocusedDismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private static let demoLibraryTitles: [String] = [
        "Wednesday afternoon, jazz serenade",
        "Thursday evening, rock concert",
        "Friday night, classical symphony",
        "Saturday sunset, indie vibes",
        "Sunday chill, ambient tunes",
        "Monday morning, acoustic blend",
        "Tuesday twilight, soul session",
    ]

    var libraryAllRows: [LibraryRowModel] {
        let items = filteredTracks
        if items.isEmpty {
            let demos = filteredDemoTitles
            return demos.enumerated().map { i, title in
                LibraryRowModel(
                    id: i,
                    displayNumber: i + 2,
                    title: title,
                    isPlaying: isPlaying && trackTitle == title,
                    mediaItem: nil
                )
            }
        }
        return items.enumerated().map { i, item in
            LibraryRowModel(
                id: i,
                displayNumber: i + 1,
                title: item.title ?? "Unknown",
                isPlaying: player.nowPlayingItem?.persistentID == item.persistentID,
                mediaItem: item
            )
        }
    }

    var libraryTotalCount: Int { libraryAllRows.count }

    private var filteredDemoTitles: [String] {
        guard !searchQuery.isEmpty else { return Self.demoLibraryTitles }
        return Self.demoLibraryTitles.filter {
            $0.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    // MARK: - Crate artwork (`305:3150` carousel)

    /// Album art for a crate slot — from Apple Music when authorized.
    func crateArtwork(for index: Int) -> UIImage? {
        guard !tracks.isEmpty else { return nil }
        let item = tracks[index % tracks.count]
        return item.artwork?.image(at: CGSize(width: 400, height: 400))
    }

    /// Disc fill for carousel vinyl — library artwork or accent-tinted placeholder.
    func crateDiscArtwork(for index: Int) -> UIImage? {
        crateArtwork(for: index)
    }

    /// Active crate strip title — live track title when library loaded.
    func crateStripTitle(for index: Int) -> String {
        guard CrateCatalog.entries.indices.contains(index) else { return "SONG NAME HERE" }
        if !tracks.isEmpty {
            let item = tracks[index % tracks.count]
            if let title = item.title, !title.isEmpty {
                return title.uppercased()
            }
        }
        return CrateCatalog.entries[index].title.uppercased()
    }

    func updateFigmaLayoutScale(for width: CGFloat) {
        figmaLayoutScale = FigmaTheme.layoutScale(for: width)
    }

    /// Brings the full control card back over CRATES (`305:3451` default state).
    func showControlCentre() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            controlPanelRevealFraction = 1
        }
    }

    func collapseControlPanelToJam() {
        showControlCentre()
    }

    func crateVinylTapped(at index: Int) {
        loadCrateAsNowPlaying(at: index)
    }

    func loadCrateAsNowPlaying(at index: Int) {
        guard CrateCatalog.entries.indices.contains(index) else { return }
        impact(.medium)
        applyCratePresentation(at: index)

        if let item = mediaItemForCrate(at: index) {
            play(item: item)
            return
        }

        let crate = CrateCatalog.entries[index]
        trackTitle = crate.title
        artistName = crate.artist
        albumTitle = ""
        duration = 237
        currentTime = 0
        isPlaying = true
        albumArtwork = nil
        startTimers()
    }

    private func applyCratePresentation(at index: Int) {
        guard CrateCatalog.entries.indices.contains(index) else { return }
        crateActiveIndex = index
        let crate = CrateCatalog.entries[index]
        applySkin(crate.skin)
        heroDiscPlaceholder = UIImageFigma.tintedDisc(crate.accentUIKit())
        albumArtwork = crateArtwork(for: index)
    }

    // MARK: - Animation timers

    private func startTimers() {
        if animTimer == nil {
            animTimer = Timer.publish(every: 1 / 60, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    if !self.isScratching && self.isPlaying {
                        self.cdAngle += self.rotationVelocity
                        self.shimmerPhase += 0.70
                        let cruise = 0.75
                        if abs(self.rotationVelocity - cruise) > 0.005 {
                            self.rotationVelocity += (cruise - self.rotationVelocity) * 0.04
                        } else {
                            self.rotationVelocity = cruise
                        }
                    }
                }
        }
        if progressTimer == nil {
            progressTimer = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    self.currentTime = self.player.currentPlaybackTime
                    if self.isPlaying {
                        InAppPlaybackAudio.suppressSystemNowPlaying()
                    }
                }
        }
    }

    private func stopTimers() {
        animTimer?.cancel();     animTimer = nil
        progressTimer?.cancel(); progressTimer = nil
    }

    // MARK: - Haptic

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Softer “tick” for snapped values, scrubbers, and sheet settle.
    func selectionChanged() {
        guard isHapticEnabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }

    /// Success / warning style — used sparingly for mechanical “clunk” moments.
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    // MARK: - Computed

    var progress: Double { min(1, max(0, duration > 0 ? currentTime / duration : 0)) }
    var currentTimeString: String { formatTime(currentTime) }
    var durationString:    String { formatTime(duration) }

    var effectiveHeroUIImage: UIImage? { albumArtwork ?? heroDiscPlaceholder }

    var currentCrateEntry: CrateCatalogEntry? {
        guard CrateCatalog.entries.indices.contains(crateActiveIndex) else { return nil }
        return CrateCatalog.entries[crateActiveIndex]
    }

    /// Figma `305:3124`–`305:3128` placeholders when idle; live metadata while playing.
    var heroStripTitle: String { isPlaying ? trackTitle.uppercased() : "SONG NAME XXXXXXXXXXXX" }

    var heroStripTime: String { isPlaying ? durationString : "22:00" }

    var heroStripGenre: String {
        if isPlaying {
            if let genre = currentCrateEntry?.genrePlaceholder {
                return genre.uppercased()
            }
            if !artistName.isEmpty, artistName != "—" {
                return artistName.uppercased()
            }
        }
        return "GENRE NAME"
    }

    var jamStatusLine: String { isPlaying ? trackTitle.lowercased() : "not playing" }

    var jamRangeCaption: String {
        if !tracks.isEmpty, let current = player.nowPlayingItem,
           let idx = tracks.firstIndex(where: { $0.persistentID == current.persistentID }) {
            return "\(idx + 1)-\(tracks.count)"
        }
        let i = max(1, min(crateActiveIndex + 1, CrateCatalog.count))
        return "\(i)-\(CrateCatalog.count)"
    }

    /// Aliases consumed by `FigmaCDHeroView`.
    var heroDiscArtwork: UIImage? { effectiveHeroUIImage }
    var heroTrackTitle: String { heroStripTitle }
    var heroTimeString: String { heroStripTime }
    var heroGenre: String { heroStripGenre }

    var filteredTracks: [MPMediaItem] {
        searchQuery.isEmpty ? tracks : tracks.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchQuery) ||
            ($0.artist ?? "").localizedCaseInsensitiveContains(searchQuery) ||
            ($0.albumTitle ?? "").localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private func formatTime(_ s: Double) -> String {
        let s = max(0, s)
        return String(format: "%d:%02d", Int(s) / 60, Int(s) % 60)
    }
}
