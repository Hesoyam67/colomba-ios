import SwiftUI

public struct ReservationFormView: View {
    @ObservedObject private var viewModel: ReservationViewModel
    private let restaurant: Restaurant
    @State private var confirmationRoute: ConfirmationRoute?

    public init(viewModel: ReservationViewModel, restaurant: Restaurant) {
        self.viewModel = viewModel
        self.restaurant = restaurant
    }

    public var body: some View {
        Form {
            Section("When") {
                DatePicker(
                    "Date",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                Picker("Time", selection: $viewModel.selectedSlot) {
                    Text("Choose a time").tag(TimeSlot?.none)
                    ForEach(viewModel.availableSlots) { slot in
                        Text(slot.startsAt, format: .dateTime.hour().minute())
                            .tag(Optional(slot))
                    }
                }
            }
            Section("Party") {
                Stepper("\(viewModel.partySize) guests", value: $viewModel.partySize, in: 1...12)
                TextField("Full name", text: $viewModel.fullName)
                    .textContentType(.name)
            }
            Section {
                TextEditor(text: $viewModel.specialRequests)
                    .frame(minHeight: 96)
                Text("\(viewModel.specialRequests.utf8.count)/500")
                    .font(.caption)
                    .foregroundStyle(viewModel.specialRequests.utf8.count <= 500 ? .secondary : .red)
            } header: {
                Text("Special requests")
            } footer: {
                Text("Optional. Keep it under 500 characters.")
            }
            if case let .failed(reason) = viewModel.phase {
                Section {
                    Text(reason)
                        .foregroundStyle(.red)
                }
            }
            Section {
                Button {
                    Task { await viewModel.submit(restaurant: restaurant) }
                } label: {
                    if viewModel.phase == .submitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Confirm")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.canConfirm == false || viewModel.phase == .submitting)
            }
        }
        .navigationTitle("Reserve \(restaurant.name)")
        .navigationDestination(item: $confirmationRoute) { route in
            ReservationConfirmView(confirmation: route.confirmation)
        }
        .task {
            await viewModel.loadAvailability(for: restaurant, on: viewModel.selectedDate)
        }
        .onChange(of: viewModel.selectedDate) { _, newDate in
            Task { await viewModel.loadAvailability(for: restaurant, on: newDate) }
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if case let .confirmed(confirmation) = newPhase {
                confirmationRoute = ConfirmationRoute(confirmation: confirmation)
            }
        }
    }
}

private struct ConfirmationRoute: Identifiable, Equatable {
    let id: String
    let confirmation: ReservationConfirmation

    init(confirmation: ReservationConfirmation) {
        self.id = confirmation.reservationId
        self.confirmation = confirmation
    }
}
