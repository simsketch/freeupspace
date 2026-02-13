import SwiftUI
import SharedUtilities

struct SizeLabel: View {
    let bytes: Int64

    var body: some View {
        Text(ByteFormatter.shared.formatPrecise(bytes))
            .font(.callout)
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }
}
