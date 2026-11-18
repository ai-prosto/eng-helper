/// Pronunciation abstraction (design D-12, D-13). The app provides the
/// `AVSpeechSynthesizer`-backed implementation; the kit and its tests
/// only know this protocol, so speech behaviour stays unit-testable.
/// Speech is always requested from UI transitions, hence main-actor.
@MainActor
public protocol Speaking: AnyObject {
    /// Speaks one piece of text once.
    func speak(_ text: String)

    /// Speaks the given sentences one after another, to the end.
    func speakSequence(_ sentences: [String])
}
