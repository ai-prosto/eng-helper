import EngHelperKit
import SwiftUI

/// The popover's stacked zones (design D-04): the word field with the
/// card or error under it, the sentences zone, the saved-words list.
struct PopoverRootView: View {
    @ObservedObject var model: PopoverModel
    @FocusState private var wordFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Type a word and press Enter", text: $model.input)
                .textFieldStyle(.roundedBorder)
                .focused($wordFieldFocused)
                .onSubmit {
                    Task { await model.submit() }
                }

            if model.showAccessibilityHint {
                accessibilityHint
            }

            lookupZone

            Divider()
            SentencesView(text: $model.sentencesText)
            Divider()
            VocabularyListView(entries: model.entries) { entry in
                model.show(entry)
            }
        }
        .padding(12)
        .frame(width: 360)
        .onAppear {
            // Ready for typing on every open (BEH-15, design D-05).
            wordFieldFocused = true
        }
    }

    /// One line with the Privacy pane button, shown while the
    /// Accessibility grant is missing (design D-08). Typed lookups
    /// keep working underneath it.
    private var accessibilityHint: some View {
        HStack(spacing: 6) {
            Text("Selection capture needs Accessibility access.")
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Button("Open Settings") {
                if let url = URL(
                    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                ) {
                    NSWorkspace.shared.open(url)
                }
            }
            .controlSize(.small)
        }
        .font(.callout)
    }

    @ViewBuilder
    private var lookupZone: some View {
        switch model.phase {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, alignment: .center)
        case let .card(card):
            WordCardView(card: card)
        case let .error(message):
            // One short line; nothing else changes (BEH-18, design D-18).
            Text(message)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
