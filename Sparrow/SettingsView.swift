import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SparrowSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 8) {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))

                Text("Choose which mouse side buttons switch Spaces. macOS reports extra mouse buttons as numbered inputs, so try a button and adjust the mapping if it moves in the wrong direction.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Form {
                Section {
                    Picker("Move Space Left", selection: $settings.moveSpaceLeftButton) {
                        ForEach(0...20, id: \.self) { number in
                            Text("Button \(number)").tag(number)
                        }
                    }

                    Picker("Move Space Right", selection: $settings.moveSpaceRightButton) {
                        ForEach(0...20, id: \.self) { number in
                            Text("Button \(number)").tag(number)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520)
    }
}

#Preview {
    SettingsView(settings: .shared)
}
