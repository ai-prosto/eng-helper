import SwiftUI

/// The speech-only sentences zone (design D-13). Its text never
/// reaches storage; "Read aloud" speaks it sentence after sentence
/// (BEH-26).
struct SentencesView: View {
    @Binding var text: String
    var onReadAloud: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Sentences")
                    .font(.headline)
                Spacer()
                Button("Read aloud", action: onReadAloud)
                    .controlSize(.small)
                    .disabled(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
            }
            TextEditor(text: $text)
                .font(.body)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(nsColor: .separatorColor))
                )
        }
    }
}
