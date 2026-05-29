import SwiftUI
import SwiftData

struct NameEntryStep: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Text("Welcome to MealPrep!")
                    .font(.largeTitle.bold())
                Text("What's your name?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            TextField("Your name", text: $name)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)
                .submitLabel(.done)
                .onSubmit { save() }

            Spacer()

            Button(action: save) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(UserProfile(name: trimmed))
        try? modelContext.save()
        coordinator.step = .pantry
    }
}
