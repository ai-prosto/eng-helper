import AVFoundation
import EngHelperKit

/// Speech through `AVSpeechSynthesizer` with the built-in macOS voice
/// for the system's English locale — fully local and offline (design
/// D-12). A new request stops whatever is still being spoken, so each
/// press speaks once.
@MainActor
final class SystemSpeaker: Speaking {
    private let synthesizer = AVSpeechSynthesizer()
    private let voice = SystemSpeaker.englishVoice()

    func speak(_ text: String) {
        speakSequence([text])
    }

    func speakSequence(_ sentences: [String]) {
        synthesizer.stopSpeaking(at: .immediate)
        for sentence in sentences {
            let utterance = AVSpeechUtterance(string: sentence)
            utterance.voice = voice
            synthesizer.speak(utterance)
        }
    }

    /// The user's preferred English variant when they have one, else
    /// plain US English.
    private static func englishVoice() -> AVSpeechSynthesisVoice? {
        let preferredEnglish = Locale.preferredLanguages
            .first { $0.hasPrefix("en") }
            .flatMap(AVSpeechSynthesisVoice.init(language:))
        return preferredEnglish ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}
