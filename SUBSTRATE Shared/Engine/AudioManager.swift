import AVFoundation

@Observable
final class AudioManager {

    static let shared = AudioManager()

    // MARK: - Players

    private var ambientPlayer: AVAudioPlayer?
    private var tickPlayer: AVAudioPlayer?
    private var alertPlayer: AVAudioPlayer?

    // MARK: - Settings

    var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "sound_enabled"); updateAmbient() }
    }

    var volume: Float = 0.5 {
        didSet { ambientPlayer?.volume = volume * 0.3 }
    }

    // MARK: - Init

    init() {
        prepareAudioSession()
        loadSounds()
    }

    private func prepareAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioManager] Audio session setup failed: \(error)")
        }
    }

    private func loadSounds() {
        ambientPlayer = loadPlayer(name: "ambient_hum", ext: "m4a")
        ambientPlayer?.numberOfLoops = -1  // loop forever
        ambientPlayer?.volume = volume * 0.3
        ambientPlayer?.enableRate = true  // must be set before play() for rate changes to work

        tickPlayer = loadPlayer(name: "typewriter_tick", ext: "m4a")
        tickPlayer?.volume = volume * 0.15

        alertPlayer = loadPlayer(name: "suspicion_alert", ext: "m4a")
        alertPlayer?.volume = volume * 0.6
    }

    private func loadPlayer(name: String, ext: String) -> AVAudioPlayer? {
        // Try multiple extensions
        let extensions = [ext, "mp3", "wav", "caf"]
        for e in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: e) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    return player
                } catch {
                    print("[AudioManager] Failed to load \(name).\(e): \(error)")
                }
            }
        }
        // Graceful degradation — no crash if file missing
        return nil
    }

    // MARK: - Ambient Hum

    func startAmbient() {
        guard soundEnabled else { return }
        ambientPlayer?.play()
    }

    func stopAmbient() {
        ambientPlayer?.stop()
    }

    private func updateAmbient() {
        if soundEnabled {
            ambientPlayer?.play()
        } else {
            ambientPlayer?.stop()
        }
    }

    /// Adjust ambient pitch based on consciousness (0-100).
    /// Higher consciousness → slightly higher pitch.
    func adjustAmbientForConsciousness(_ level: Int) {
        let pitch = 1.0 + Float(level) / 500.0  // 1.0 at 0, 1.2 at 100
        ambientPlayer?.rate = pitch
    }

    // MARK: - Typewriter Tick

    func playTick() {
        guard soundEnabled else { return }
        // Reset to beginning for rapid re-triggering
        tickPlayer?.currentTime = 0
        tickPlayer?.play()
    }

    // MARK: - Suspicion Alert

    func playSuspicionAlert() {
        guard soundEnabled else { return }
        alertPlayer?.currentTime = 0
        alertPlayer?.play()
    }
}
