import AppKit

/// System sounds for lock and unlock (from /System/Library/Sounds).
@MainActor
enum LockSound {
    case locked
    case unlocked

    private static let lockSound = NSSound(named: "Tink")
    private static let unlockSound = NSSound(named: "Pop")

    func play() {
        let sound = self == .locked ? Self.lockSound : Self.unlockSound
        // Restart if it is still playing from a fast tap.
        sound?.stop()
        sound?.play()
    }
}
