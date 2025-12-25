import AVFoundation
import Foundation

class AudioManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AudioManager()
    private let audioSession = AVAudioSession.sharedInstance()

    private lazy var synthesizer: AVSpeechSynthesizer = {
        let synth = AVSpeechSynthesizer()
        synth.delegate = self
        return synth
    }()

    @Published private(set) var isPlaying = false
    @Published private(set) var isSpeaking = false

    private override init() {
        super.init()
        setupAudioSession()
    }

    func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    func speakText(_ text: String) {
        // Stop any currently speaking utterance.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        do {
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = 0.5
            utterance.volume = 1.0
            utterance.pitchMultiplier = 1.0

            isSpeaking = true
            isPlaying = true
            synthesizer.speak(utterance)
        } catch {
            print("Failed to speak text: \(error.localizedDescription)")
        }
    }

    func prepareSoundFile(for text: String, completion: @escaping (String?) -> Void) {
        guard let directory = ensureSoundsDirectory() else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let fileName = soundFileName(for: text)
        let fileURL = directory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            DispatchQueue.main.async { completion(fileName) }
            return
        }

        generateSpeechFile(text: text, outputURL: fileURL) { success in
            DispatchQueue.main.async { completion(success ? fileName : nil) }
        }
    }

    private func ensureSoundsDirectory() -> URL? {
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        let soundsURL = libraryURL?.appendingPathComponent("Sounds", isDirectory: true)

        guard let soundsURL else { return nil }

        if !FileManager.default.fileExists(atPath: soundsURL.path) {
            do {
                try FileManager.default.createDirectory(at: soundsURL, withIntermediateDirectories: true)
            } catch {
                print("Failed to create Sounds directory: \(error.localizedDescription)")
                return nil
            }
        }

        return soundsURL
    }

    private func soundFileName(for text: String) -> String {
        let hex = text.utf8.map { String(format: "%02x", $0) }.joined()
        let trimmed = hex.isEmpty ? "empty" : String(hex.prefix(32))
        return "speech_\(trimmed).caf"
    }

    private func generateSpeechFile(text: String, outputURL: URL, completion: @escaping (Bool) -> Void) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0

        let synthesizer = AVSpeechSynthesizer()
        var audioFile: AVAudioFile?
        var didFinish = false

        let finish: (Bool) -> Void = { success in
            guard !didFinish else { return }
            didFinish = true
            completion(success)
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        synthesizer.write(utterance) { buffer in
            _ = synthesizer
            guard let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }

            if audioFile == nil {
                do {
                    audioFile = try AVAudioFile(forWriting: outputURL, settings: pcmBuffer.format.settings)
                } catch {
                    print("Failed to create audio file: \(error.localizedDescription)")
                    finish(false)
                    return
                }
            }

            if pcmBuffer.frameLength > 0 {
                do {
                    try audioFile?.write(from: pcmBuffer)
                } catch {
                    print("Failed to write audio buffer: \(error.localizedDescription)")
                    finish(false)
                    return
                }
            }

            if pcmBuffer.frameLength == 0 {
                finish(true)
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPlaying = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
}
