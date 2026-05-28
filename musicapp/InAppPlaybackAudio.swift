import AVFoundation
import MediaPlayer

/// Apple Music playback scoped to this app — does not claim Dynamic Island / lock screen.
enum InAppPlaybackAudio {
    /// In-app queue only; does not hijack the Music app / system queue.
    static let player = MPMusicPlayerController.applicationMusicPlayer

    /// Single shared session for music + in-app UI SFX. Never downgrade to `.ambient`.
    static func activateSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            if session.category != .playback {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            }
            try session.setActive(true, options: [])
        } catch {
            // Non-fatal — MPMusicPlayerController may still play.
        }
    }

    /// Call before drawer / UI synth so we never steal the session from library playback.
    static func prepareForUISounds() {
        activateSession()
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

    /// Call on play/pause/queue changes — not on every progress tick.
    static func suppressSystemNowPlaying() {
        clearNowPlaying()
        disableSystemRemoteCommands()
    }
}
