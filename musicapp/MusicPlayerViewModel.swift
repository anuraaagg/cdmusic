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

    /// Figma `360:2854` — 0 = tray closed (`305:2722`), 1 = slid left, disc exposed.
    @Published var caseSlideFraction: CGFloat = 0

    // Crate / panel slide
    @Published var crateIsOpen:       Bool = false
    @Published var panelDragOffset:   CGFloat = 0
    @Published var crateActiveIndex:  Int = 2
    @Published var trackDotIndex:     Int = 0

    let albums = AlbumCatalog.entries

    /// 0 = JAM strip only (CRATES visible); 1 = full control card (CRATES hidden behind panel).
    @Published var controlPanelRevealFraction: CGFloat = 1
    /// Tinted disc graphic for CD hero when library artwork is unavailable.
    @Published var heroDiscPlaceholder: UIImage? = UIImageFigma.tintedDisc(CrateCatalog.entry(for: 2).accentUIKit())

    @Published var figmaLayoutScale: CGFloat = 1

    // Volume (display only — actual change goes through VolumeManager)
    @Published var volume: Float = 0.5

    // UI sheets
    @Published var showSettings = false
    @Published var showLibrary  = false
    @Published var showSavedCrate = false
    @Published var savedCrateViewMode: SavedCrateViewMode = .web

    // Saved crate
    let savedCrateStore = SavedCrateStore.shared
    @Published var crateSavePhase: CrateSavePhase = .idle
    @Published var crateSaveDragIndex: Int?
    @Published var crateSaveFromHero = false
    @Published var saveToastMessage: String?

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
    /// Inner-joystick drag / release — keeps the hero CD spinning while paused.
    private var jogBurstUntil: Date?
    private var isJogDragging = false

    private var isJogSpinActive: Bool {
        isJogDragging || (jogBurstUntil.map { Date() < $0 } ?? false)
    }
    /// Guards against MPMusicPlayer briefly reporting `.paused` right after `play()`.
    private var userRequestedPlayback = false
    private var storeCancellable: AnyCancellable?

    private enum PlaybackStore {
        static let lastPersistentID = "figma.lastTrackPersistentID"
        static let wasPlaying = "figma.lastWasPlaying"
    }

    // MARK: Init

    init() {
        selectedSkin = CrateCatalog.entry(for: crateActiveIndex).skin
        storeCancellable = savedCrateStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
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
                self.bootstrapDefaultCratePresentationIfNeeded()
            }
        }
    }

    /// Called when the root player is on-screen (launch and after onboarding).
    func playerScreenDidAppear() {
        refreshLibraryIfAuthorized()
        bootstrapDefaultCratePresentationIfNeeded()
        showControlCentre(animated: false)
    }

    private func refreshLibraryIfAuthorized() {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
        guard tracks.isEmpty else { return }
        loadLibrary()
    }

    /// Demo crate metadata when the Music library is empty or nothing is queued yet.
    private func bootstrapDefaultCratePresentationIfNeeded() {
        guard player.nowPlayingItem == nil else { return }
        applyCratePresentation(at: crateActiveIndex)
        guard tracks.isEmpty else { return }
        let crate = CrateCatalog.entry(for: crateActiveIndex)
        let idle = trackTitle == "Not Playing" || artistName == "—"
        guard idle else { return }
        trackTitle = crate.title
        artistName = crate.artist
        albumTitle = ""
        duration = 237
        currentTime = 0
        isPlaying = false
        albumArtwork = nil
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
        guard crateActiveIndex != trackIdx else { return }
        crateActiveIndex = trackIdx
        applyCratePresentation(at: trackIdx)
    }

    /// Maps each crate slot to a library row.
    private func mediaItemForCrate(at index: Int) -> MPMediaItem? {
        guard tracks.indices.contains(index) else { return nil }
        return tracks[index]
    }

    /// One vinyl per library track; demo catalog when library is empty.
    var vinylCarouselCount: Int {
        !tracks.isEmpty ? tracks.count : CrateCatalog.count
    }

    private func syncPlaybackState() {
        let state = player.playbackState
        let playing = state == .playing

        if playing {
            userRequestedPlayback = false
            isPlaying = true
        } else if state == .stopped {
            userRequestedPlayback = false
            isPlaying = false
        } else if state == .paused {
            if !userRequestedPlayback {
                isPlaying = false
            }
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
        } else if !isJogSpinActive {
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
            crateActiveIndex = idx
            applyCratePresentation(at: idx)
        }
        syncNowPlaying()
        syncPlaybackState()
    }

    /// Builds a multi-item queue so skip next/previous work across the library.
    private func setQueue(startingAt item: MPMediaItem, autoplay: Bool = true) {
        if tracks.isEmpty {
            player.setQueue(with: MPMediaItemCollection(items: [item]))
        } else if let start = tracks.firstIndex(where: { $0.persistentID == item.persistentID }) {
            // Avoid copying the entire library into the queue — large collections can freeze or crash.
            let queueCapacity = 250
            let end = min(tracks.count, start + queueCapacity)
            var queue = Array(tracks[start..<end])
            if queue.count < queueCapacity, start > 0 {
                let headCount = min(start, queueCapacity - queue.count)
                queue.append(contentsOf: tracks[0..<headCount])
            }
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
            userRequestedPlayback = false
            player.pause()
            isPlaying = false
            stopTimers()
            InAppPlaybackAudio.suppressSystemNowPlaying()
        } else {
            userRequestedPlayback = true
            InAppPlaybackAudio.activateSession()
            if player.nowPlayingItem == nil, let first = tracks.first {
                setQueue(startingAt: first, autoplay: true)
                syncNowPlaying()
                isPlaying = true
                startTimers()
                InAppPlaybackAudio.suppressSystemNowPlaying()
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
        let count = max(1, vinylCarouselCount)
        if forward {
            loadCrateAsNowPlaying(at: (crateActiveIndex + 1) % count)
        } else {
            loadCrateAsNowPlaying(at: (crateActiveIndex - 1 + count) % count)
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

    /// Jog inner stick — nudge playback within the current track.
    func seek(bySeconds seconds: Double) {
        guard duration > 0 else { return }
        impact(.light)
        let t = max(0, min(duration, currentTime + seconds))
        seek(to: t / duration)
        beginJogSpinBurst(forward: seconds >= 0, intensity: min(1, abs(seconds) / 10))
    }

    /// Live hero CD spin while the inner joystick is held off-centre.
    func updateJogDragSpin(translation: CGSize, maxDeflection: CGFloat) {
        isJogDragging = true
        let mag = min(1, hypot(translation.width, translation.height) / max(maxDeflection, 1))
        guard mag > 0.04 else {
            rotationVelocity = 0
            return
        }

        let forward = abs(translation.height) >= abs(translation.width)
            ? translation.height < 0
            : translation.width > 0
        let sign: Double = forward ? 1 : -1
        rotationVelocity = sign * (2.5 + mag * 11.0)
        cdAngle += sign * mag * 2.2
        shimmerPhase += Double(mag) * 1.4
        startTimers()
    }

    func endJogDragSpin() {
        isJogDragging = false
        if !isPlaying, !isJogSpinActive {
            rotationVelocity = 0
            stopTimers()
        }
    }

    private func beginJogSpinBurst(forward: Bool, intensity: CGFloat = 1) {
        let sign: Double = forward ? 1 : -1
        rotationVelocity = sign * (8.0 + 4.0 * Double(intensity))
        jogBurstUntil = Date().addingTimeInterval(0.6)
        shimmerPhase += 18
        startTimers()
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

    var isHeroDiscInteractive: Bool {
        caseSlideFraction >= FigmaTheme.CD3052722.discInteractThreshold
    }

    func closeCaseTray(animated: Bool = true) {
        guard caseSlideFraction > 0.001 else { return }
        if animated {
            withAnimation(CaseTrayPhysics.snapAnimation) {
                caseSlideFraction = 0
            }
        } else {
            caseSlideFraction = 0
        }
        selectionChanged()
    }

    func openCaseTray(animated: Bool = true) {
        guard caseSlideFraction < 0.999 else { return }
        if animated {
            withAnimation(CaseTrayPhysics.snapAnimation) {
                caseSlideFraction = 1
            }
        } else {
            caseSlideFraction = 1
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
        userRequestedPlayback = true
        InAppPlaybackAudio.activateSession()
        setQueue(startingAt: item, autoplay: true)
        syncNowPlaying()
        isPlaying = true
        startTimers()
        InAppPlaybackAudio.suppressSystemNowPlaying()
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


    // MARK: - Saved crate

    func openSavedCrate(preferWeb: Bool = false) {
        impact(.light)
        showSettings = false
        showLibrary = false
        if preferWeb {
            savedCrateViewMode = .web
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showSavedCrate = true
        }
    }

    func closeSavedCrate() {
        showSavedCrate = false
    }

    func beginCrateDrop(at index: Int, fromHero: Bool = false) {
        guard crateSavePhase == .idle else { return }
        crateSaveDragIndex = index
        crateSaveFromHero = fromHero
        impact(.medium)
        crateSavePhase = .presenting
    }

    /// Called after the drop sheet springs from peek to the expanded detent.
    func crateDropSheetDidFinishExpanding() {
        guard crateSavePhase == .presenting else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            crateSavePhase = .expanded
        }
    }

    /// Cancels during pick-up phase (not during save animation / confirmation).
    func cancelCrateDrop() {
        guard crateSavePhase != .success && crateSavePhase != .settling else { return }
        crateSaveDragIndex = nil
        crateSaveFromHero = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            crateSavePhase = .idle
        }
    }

    /// Invoke after SwiftUI settles the disc into the crate (from `settling`).
    func finishCrateDropSettling() {
        guard crateSavePhase == .settling else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            crateSavePhase = .success
        }
    }

    /// User taps ✕ / scrim after a successful save.
    func dismissCrateDropSuccess() {
        guard crateSavePhase == .success else { return }
        crateSaveDragIndex = nil
        crateSaveFromHero = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
            crateSavePhase = .idle
        }
    }

    func commitCrateDrop(at index: Int) {
        /// Allow commit while the sheet is still in `.presenting` — drag was previously disabled until `crateDropSheetDidFinishExpanding()`, so early drags never registered.
        guard crateSavePhase == .presenting || crateSavePhase == .expanded else { return }
        crateSavePhase = .settling
        impact(.heavy)
        playDrawerLatchSound()

        let moment = makeSavedMoment(fromCrateIndex: index)
        savedCrateStore.save(moment)

        saveToastMessage = "Saved to My Crate"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.saveToastMessage = nil
        }

        crateSaveDragIndex = nil
    }

    func closeCrateDropSheetChrome() {
        switch crateSavePhase {
        case .success:
            dismissCrateDropSuccess()
        case .settling:
            break
        default:
            cancelCrateDrop()
        }
    }

    func makeSavedMoment(fromCrateIndex index: Int) -> SavedMoment {
        var title = crateStripTitle(for: index)
        var artist = artistName
        var genre = ""
        var trackID: UInt64?
        var art = crateDiscArtwork(for: index)

        if tracks.indices.contains(index) {
            let item = tracks[index]
            title = (item.title ?? title).uppercased()
            artist = item.artist ?? artist
            genre = (item.genre ?? "").uppercased()
            trackID = item.persistentID
            art = item.artwork?.image(at: CGSize(width: 512, height: 512)) ?? art
        } else {
            let crate = CrateCatalog.entry(for: index)
            title = crate.title.uppercased()
            artist = crate.artist
            genre = crate.genrePlaceholder.uppercased()
        }

        let accent = crateAccentColor(for: index)
        let hex = UInt32(accent.rgbaHex)

        return SavedMoment(
            trackPersistentID: trackID,
            title: title,
            artist: artist,
            genre: genre,
            skin: selectedSkin,
            accentHex: hex,
            artwork: art ?? albumArtwork
        )
    }

    func loadSavedMoment(_ moment: SavedMoment) {
        impact(.medium)
        applySkin(moment.skin)

        if let pid = moment.trackPersistentID,
           let item = tracks.first(where: { $0.persistentID == pid }) {
            if let idx = tracks.firstIndex(where: { $0.persistentID == pid }) {
                crateActiveIndex = idx
                applyCratePresentation(at: idx)
            }
            play(item: item)
            return
        }

        trackTitle = moment.title
        artistName = moment.artist
        albumArtwork = moment.artworkImage
        albumTitle = ""
        duration = 237
        currentTime = 0
        isPlaying = true
        startTimers()
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
        guard tracks.indices.contains(index) else { return nil }
        let side = FigmaTheme.Crate.vinylSide * figmaLayoutScale
        return tracks[index].artwork?.image(at: CGSize(width: side, height: side))
    }

    /// Disc fill for carousel vinyl — library artwork fills the full label (`356:2878`).
    func crateDiscArtwork(for index: Int) -> UIImage? {
        crateArtwork(for: index)
    }

    /// Saved web nodes — prefer live carousel / library artwork over persisted JPEG.
    func savedMomentDiscArtwork(for moment: SavedMoment) -> UIImage? {
        if let pid = moment.trackPersistentID,
           let idx = tracks.firstIndex(where: { $0.persistentID == pid }) {
            return crateDiscArtwork(for: idx)
        }
        if vinylCarouselCount > 0 {
            for idx in 0..<vinylCarouselCount where crateStripTitle(for: idx) == moment.title {
                if let art = crateDiscArtwork(for: idx) { return art }
            }
        }
        return moment.artworkImage
    }

    func crateSleeveIndex(for index: Int) -> Int {
        CrateCatalog.sleeveForIndex(index)
    }

    func crateAccentColor(for index: Int) -> UIColor {
        CrateCatalog.entry(for: index).accentUIKit()
    }

    /// Active crate strip title — live track title when library loaded.
    func crateStripTitle(for index: Int) -> String {
        if tracks.indices.contains(index),
           let title = tracks[index].title, !title.isEmpty {
            return title.uppercased()
        }
        return CrateCatalog.entry(for: index).title.uppercased()
    }

    func updateFigmaLayoutScale(for width: CGFloat) {
        figmaLayoutScale = FigmaTheme.layoutScale(for: width)
    }

    /// Brings the full control card back over CRATES (`305:3451` default state).
    func showControlCentre(animated: Bool = true) {
        guard controlPanelRevealFraction < 0.999 else { return }
        if animated {
            let v = (1 - controlPanelRevealFraction) * 4.5
            withAnimation(PanelDrawerPhysics.panelSlideAnimation(initialVelocity: v)) {
                controlPanelRevealFraction = 1
            }
            playDrawerLatchSound()
        } else {
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
        guard index >= 0, index < vinylCarouselCount else { return }
        impact(.medium)
        applyCratePresentation(at: index)

        if let item = mediaItemForCrate(at: index) {
            play(item: item)
            return
        }

        let crate = CrateCatalog.entry(for: index)
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
        guard index >= 0, index < vinylCarouselCount else { return }
        crateActiveIndex = index
        let crate = CrateCatalog.entry(for: index)
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
                    guard !self.isScratching else { return }

                    let jogBursting = self.jogBurstUntil.map { Date() < $0 } ?? false
                    guard self.isPlaying || self.isJogDragging || jogBursting else { return }

                    self.cdAngle += self.rotationVelocity
                    self.shimmerPhase += abs(self.rotationVelocity) * 0.22 + (self.isPlaying ? 0.70 : 0)

                    if self.isJogDragging {
                        return
                    }

                    if jogBursting {
                        self.rotationVelocity *= 0.88
                        if abs(self.rotationVelocity) < 0.35 {
                            self.jogBurstUntil = nil
                            self.rotationVelocity = self.isPlaying ? 0.75 : 0
                            if !self.isPlaying { self.stopTimers() }
                        }
                        return
                    }

                    guard self.isPlaying else { return }
                    let cruise = 0.75
                    if abs(self.rotationVelocity - cruise) > 0.005 {
                        self.rotationVelocity += (cruise - self.rotationVelocity) * 0.04
                    } else {
                        self.rotationVelocity = cruise
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
        guard crateActiveIndex >= 0, crateActiveIndex < vinylCarouselCount else { return nil }
        return CrateCatalog.entry(for: crateActiveIndex)
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
        let i = max(1, min(crateActiveIndex + 1, vinylCarouselCount))
        return "\(i)-\(vinylCarouselCount)"
    }

    /// Crate drawer counter — `1-N` while the panel reveals the carousel.
    var jamCratesCaption: String {
        let n = max(1, vinylCarouselCount)
        return "1-\(n)"
    }

    /// JAM strip crossfade: track metadata when closed, CRATES + count as the drawer opens.
    func jamToolbarForDrawer(revealFraction: CGFloat) -> (status: String, counter: String) {
        let openAmount = max(0, min(1, 1 - revealFraction))
        if openAmount < 0.12 {
            return (jamStatusLine, jamRangeCaption)
        }
        if openAmount > 0.42 {
            return ("crates", jamCratesCaption)
        }
        return openAmount > 0.26 ? ("crates", jamCratesCaption) : (jamStatusLine, jamRangeCaption)
    }

    func playDrawerSlideSound() {
        guard isSoundEnabled else { return }
        DrawerMechanicalSound.shared.playSlideOpen()
    }

    func playDrawerLatchSound() {
        guard isSoundEnabled else { return }
        DrawerMechanicalSound.shared.playLatchClose()
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

private extension UIColor {
    var rgbaHex: UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (UInt32(r * 255) << 16) | (UInt32(g * 255) << 8) | UInt32(b * 255)
    }
}
