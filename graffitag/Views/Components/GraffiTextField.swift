import SwiftUI

struct GraffiTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var isValid: Bool? = nil

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isSecure && !isRevealed {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(contentType)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.white)

            if isSecure {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(.gray)
                        .frame(width: 24)
                }
            }

            if let isValid {
                Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isValid ? .green : .red)
                    .opacity(text.isEmpty ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isValid)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        )
    }

    private var borderColor: Color {
        guard let isValid, !text.isEmpty else { return Color.white.opacity(0.15) }
        return isValid ? Color.green.opacity(0.6) : Color.red.opacity(0.6)
    }
}
