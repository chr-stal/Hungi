import SwiftUI

struct MealCountStep: View {
    @Environment(FlowCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coord = coordinator

        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange)
                    Text("How many meals\nwould you like to make?")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 0) {
                    MealCountRow(
                        label: "Breakfast",
                        icon: MealType.icon(for: MealType.breakfast),
                        color: MealType.color(for: MealType.breakfast),
                        count: $coord.targetBreakfast
                    )
                    Divider().padding(.leading, 56)
                    MealCountRow(
                        label: "Lunch",
                        icon: MealType.icon(for: MealType.lunch),
                        color: MealType.color(for: MealType.lunch),
                        count: $coord.targetLunch
                    )
                    Divider().padding(.leading, 56)
                    MealCountRow(
                        label: "Dinner",
                        icon: MealType.icon(for: MealType.dinner),
                        color: MealType.color(for: MealType.dinner),
                        count: $coord.targetDinner
                    )
                }
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

                Text("Total: \(coordinator.targetTotal) meals this week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: { coordinator.step = .swiping }) {
                    Text("Start Swiping →")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle("Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { coordinator.step = .pantry }
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - Stepper row

private struct MealCountRow: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var count: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 32)
                .padding(.leading, 16)

            Text(label)
                .font(.body)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    if count > 0 { count -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(count > 0 ? color : .gray)
                }

                Text("\(count)")
                    .font(.title3.bold())
                    .frame(width: 28, alignment: .center)

                Button {
                    count += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                }
            }
            .padding(.trailing, 16)
            .padding(.vertical, 14)
        }
    }
}
