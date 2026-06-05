import SwiftUI
import SwiftData

struct NameEntryStep: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""

    var body: some View {
        ZStack {
            HungiTheme.parchment.ignoresSafeArea()
            // Force light-mode appearance so text fields show dark text on iPhone
            Color.clear.colorScheme(.light)

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 16) {
                    Text("🌾")
                        .font(.system(size: 80))

                    Text("Welcome to\nHungi!")
                        .font(HungiTheme.largeTitle)
                        .foregroundStyle(HungiTheme.darkBrown)
                        .multilineTextAlignment(.center)

                    Text("Your weekly meal planner")
                        .font(HungiTheme.body)
                        .foregroundStyle(HungiTheme.woodBrown)
                }

                // Name field in parchment card
                VStack(alignment: .leading, spacing: 10) {
                    Text("What's your name?")
                        .font(HungiTheme.headline)
                        .foregroundStyle(HungiTheme.darkBrown)

                    TextField("e.g. Victoria", text: $name)
                        .font(HungiTheme.title2)
                        .foregroundStyle(HungiTheme.darkBrown)
                        .tint(HungiTheme.darkBrown)
                        .multilineTextAlignment(.center)
                        .padding(14)
                        .background(HungiTheme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: HungiTheme.buttonRadius))
                        .overlay(RoundedRectangle(cornerRadius: HungiTheme.buttonRadius)
                            .stroke(HungiTheme.darkBrown, lineWidth: 2.5))
                        .shadow(color: HungiTheme.darkBrown, radius: 0, x: 2, y: 3)
                        .submitLabel(.done)
                        .onSubmit(save)
                }
                .padding(20)
                .background(HungiTheme.tan.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: HungiTheme.cardRadius))
                .pixelBorder(color: HungiTheme.woodBrown)
                .padding(.horizontal, 28)

                Spacer()

                Button(action: save) {
                    Text("Let's Plan! 🍽")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PixelButtonStyle(background: name.trimmingCharacters(in: .whitespaces).isEmpty ? HungiTheme.tan : HungiTheme.harvest))
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(UserProfile(name: trimmed))
        try? modelContext.save()
        coordinator.step = .ingredients
    }
}
