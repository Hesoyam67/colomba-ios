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
            Section(String(localized: "reservation.when")) {
                DatePicker(
                    String(localized: "reservation.date"),
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                Picker(String(localized: "reservation.time"), selection: $viewModel.selectedSlot) {
                    Text("reservation.choose_time").tag(TimeSlot?.none)
                    ForEach(viewModel.availableSlots) { slot in
                        Text(verbatim: timeText(for: slot))
                            .tag(TimeSlot?.some(slot))
                    }
                }
            }
            Section(String(localized: "reservation.party")) {
                Stepper(guestsText, value: $viewModel.partySize, in: 1...12)
                TextField(String(localized: "reservation.full_name"), text: $viewModel.fullName)
                    .textContentType(.name)
            }
            Section {
                TextEditor(text: $viewModel.specialRequests)
                    .frame(minHeight: 96)
                Text(characterCounterText)
                    .font(.caption)
                    .foregroundStyle(viewModel.specialRequests.utf8.count <= 500 ? Color.secondary : Color.red)
            } header: {
                Text("reservation.special_requests")
            } footer: {
                Text("reservation.optional_hint")
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
                        Text("reservation.confirm")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.canConfirm == false || viewModel.phase == .submitting)
            }
        }
        .navigationTitle(navigationTitle)
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

    private func timeText(for slot: TimeSlot) -> String {
        slot.startsAt.formatted(date: .omitted, time: .shortened)
    }

    /// Format: reservation.guests_format contains one integer guest count.
    private var guestsText: String {
        String(format: NSLocalizedString("reservation.guests_format", comment: ""), viewModel.partySize)
    }

    /// Format: reservation.counter_format contains one integer byte count.
    private var characterCounterText: String {
        String(
            format: NSLocalizedString("reservation.counter_format", comment: ""),
            viewModel.specialRequests.utf8.count
        )
    }

    /// Format: reservation.nav_title_format contains one restaurant name.
    private var navigationTitle: String {
        String(format: NSLocalizedString("reservation.nav_title_format", comment: ""), restaurant.name)
    }
}

private struct ConfirmationRoute: Identifiable, Equatable, Hashable {
    let id: String
    let confirmation: ReservationConfirmation

    init(confirmation: ReservationConfirmation) {
        self.id = confirmation.reservationId
        self.confirmation = confirmation
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
