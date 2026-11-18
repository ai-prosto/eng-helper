import Foundation
import NaturalLanguage

/// Splits pasted text into its sentences, in reading order, covering
/// the whole text (BEH-23, design D-13). Whitespace around a sentence
/// is trimmed; blank pieces are dropped.
public enum SentenceSplitter {
    public static func split(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }
        return sentences
    }
}
