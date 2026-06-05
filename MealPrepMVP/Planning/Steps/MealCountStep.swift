import SwiftUI

struct MealCountStep: View {
    @Environment(FlowCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coord = coordinator

        ZStack {
            HungiTheme.parchment.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 10) {
                    Text("🗓️")
                        .font(.system(size: 56))
                    Text("How many meals\nthis week?")
                        .font(HungiTheme.title)
                        .foregroundStyle(HungiTheme.darkBrown)
                        .multilineTextAlignment(.center)
                }

                // Stepper card
                VStack(spacing: 0) {
                    PixelStepperRow(
                        label: "Breakfast",
                        icon: MealType.icon(for: MealType.breakfast),
                        color: MealType.color(for: MealType.breakfast),
                        count: $coord.targetBreakfast
                    )
                    Divider().background(HungiTheme.tan).padding(.leading, 56)
                    PixelStepperRow(
                        label: "Lunch",
                        icon: MealType.icon(for: MealType.lunch),
                        color: MealType.color(for: MealType.lunch),
                        count: $coord.targetLunch
                    )
                    Divider().background(HungiTheme.tan).padding(.leading, 56)
                    PixelStepperRow(
                        label: "Dinner",
                        icon: MealType.icon(for: MealType.dinner),
                        color: MealType.color(for: MealType.dinner),
                        count: $coord.targetDinner
                    )
                }
                .background(HungiTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: HungiTheme.cardRadius))
                .pixelBorder()
                .pixelShadow()
                .padding(.horizontal, 24)

                Text("Total: \(coordinator.targetTotal) meals")
                    .font(HungiTheme.body)
                    .foregroundStyle(HungiTheme.woodBrown)

                Spacer()

                Button(action: { coordinator.step = .swiping }) {
                    Text("Start Swiping 🃏")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PixelButtonStyle(background: HungiTheme.harvest))
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("← Back") { coordinator.step = .pantry }
                    .font(HungiTheme.caption)
                    .foregroundStyle(HungiTheme.wheat)
            }
        }
    }
}
