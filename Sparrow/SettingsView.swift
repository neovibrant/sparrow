import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SparrowSettings

    var body: some View {
        Form {
            Section("Mouse Buttons") {
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
        .frame(width: 360)
    }
}

#Preview {
    SettingsView(settings: .shared)
}
