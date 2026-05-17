import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings: SparrowSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 8) {
                if let icon = NSImage(named: "SettingsHeaderIcon") {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                } else {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(.secondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Text("Settings")
                    .font(.system(size: 22, weight: .bold))

                Text("Setup Sparrow to work with your mouse")
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
                } footer: {
                    Text("Button 0 is usually left click, Button 1 is right click, and Button 2 is middle click. Extra mouse buttons commonly start at 3.")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400)
    }
}

#Preview {
    SettingsView(settings: .shared)
}
