import SwiftUI

/// The speech-only sentences zone (design D-13). Its text never
/// reaches storage; the "Read aloud" button arrives with TASK-005.
struct SentencesView: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sentences")
                .font(.headline)
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
