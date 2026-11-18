import EngHelperKit
import SwiftUI

/// Read-only saved list, newest first; a tap reopens the stored card
/// offline. No edit, delete or search affordance in this version
/// (BEH-19, design D-17).
struct VocabularyListView: View {
    let entries: [VocabularyEntry]
    let onSelect: (VocabularyEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Saved words")
                .font(.headline)
            if entries.isEmpty {
                Text("Nothing saved yet")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                            row(entry)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
    }

    private func row(_ entry: VocabularyEntry) -> some View {
        Button {
            onSelect(entry)
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.word)
                    .fontWeight(.medium)
                Text(entry.gloss)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
