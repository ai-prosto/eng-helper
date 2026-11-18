import EngHelperKit
import SwiftUI

/// Word, IPA, gloss, then a section per part of speech with numbered
/// definitions; a definition without an example renders no empty line
/// (BEH-17, design D-11).
struct WordCardView: View {
    let card: WordCard
    var onReplay: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(card.word)
                        .font(.title2.bold())
                    // ↻ speaks the word again, once per press
                    // (BEH-25, design D-12).
                    Button(action: onReplay) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Replay pronunciation")
                    .help("Speak the word again")
                }
                if let ipa = card.ipa {
                    Text(ipa)
                        .foregroundStyle(.secondary)
                }
                Text(card.gloss)

                ForEach(Array(card.meanings.enumerated()), id: \.offset) { _, meaning in
                    meaningSection(meaning)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 240)
    }

    private func meaningSection(_ meaning: Meaning) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meaning.partOfSpeech)
                .font(.headline)
            ForEach(Array(meaning.definitions.enumerated()), id: \.offset) { index, definition in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(index + 1). \(definition.definition)")
                    if let example = definition.example {
                        Text("“\(example)”")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
