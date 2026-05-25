import AVFoundation
import MediaPlayer

/// Apple Music playback scoped to this app — does not claim Dynamic Island / lock screen.
enum InAppPlaybackAudio {
    /// In-app queue only; does not hijack the Music app / system queue.
    static let player = MPMusicPlayerController.applicationMusicPlayer

    static func activateSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.playback` keeps library audio audible; we suppress system Now Playing separately.
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Non-fatal — MPMusicPlayerController may still play.
        }
    }

    /// Removes metadata from Control Center, lock screen, and Dynamic Island.
    static func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Prevent the OS from routing transport controls to this app.
    static func disableSystemRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = false
        center.pauseCommand.isEnabled = false
        center.stopCommand.isEnabled = false
        center.togglePlayPauseCommand.isEnabled = false
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = false
        center.changeRepeatModeCommand.isEnabled = false
        center.changeShuffleModeCommand.isEnabled = false
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false
    }

    /// Call after every play/pause/state sync — MPMusicPlayerController may republish metadata.
    static func suppressSystemNowPlaying() {
        clearNowPlaying()
        disableSystemRemoteCommands()
    }
}
