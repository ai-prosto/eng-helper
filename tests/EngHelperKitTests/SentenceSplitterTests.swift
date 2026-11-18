import Foundation
import Testing
@testable import EngHelperKit

@Suite struct SentenceSplitterTests {

    // BEH-23: a four-sentence text splits into four non-empty pieces,
    // in reading order, covering the whole text; a single sentence
    // comes back as one piece.
    @Test func testSplitsUpToFourSentencesInOrder() {
        let text = """
        The quick brown fox jumps over the lazy dog. The dog was \
        not surprised at all! Did it even notice? It kept \
        sleeping in the sun.
        """

        let sentences = SentenceSplitter.split(text)

        #expect(sentences == [
            "The quick brown fox jumps over the lazy dog.",
            "The dog was not surprised at all!",
            "Did it even notice?",
            "It kept sleeping in the sun.",
        ])
        #expect(sentences.allSatisfy { !$0.isEmpty })

        // Nothing of the text is lost: stripped of whitespace, the
        // pieces joined equal the original.
        let strip = { (s: String) in
            s.filter { !$0.isWhitespace }
        }
        #expect(strip(sentences.joined()) == strip(text))

        #expect(SentenceSplitter.split("One lone sentence.")
            == ["One lone sentence."])
    }

    // Blank input yields no sentences — the "Read aloud" button has
    // nothing to enqueue.
    @Test func testBlankTextSplitsToNothing() {
        #expect(SentenceSplitter.split("") == [])
        #expect(SentenceSplitter.split("   \n\t ") == [])
    }
}
