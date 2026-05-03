import SwiftUI

public struct MyReservationDetailView: View {
    @ObservedObject var viewModel: MyReservationsViewModel
    let reservation: Reservation
    @State private var showsCancelConfirmation = false

    public init(viewModel: MyReservationsViewModel, reservation: Reservation) {
        self.viewModel = viewModel
        self.reservation = reservation
    }

    public var body: some View {
        List {
            headerSection
            cancelledSection
            completedSection
            actionsSection
            errorSection
        }
        .navigationTitle(Text("reservation.list.title"))
        .confirmationDialog(
            String(localized: "reservation.detail.cancel.confirm.title"),
            isPresented: $showsCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "reservation.detail.cancel.confirm.confirmCta"), role: .destructive) {
                Task { await viewModel.cancel(currentReservation) }
            }
            Button(String(localized: "reservation.detail.cancel.confirm.dismissCta"), role: .cancel) {}
        } message: {
            Text("reservation.detail.cancel.confirm.message")
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(currentReservation.restaurantName)
                    .font(.title2.bold())
                Text(currentReservation.startsAt, format: .dateTime.weekday().day().month().hour().minute())
                Text(
                    String(
                        format: NSLocalizedString("reservation.party_of_format", comment: ""),
                        currentReservation.partySize
                    )
                )
                Text(currentReservation.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            statusBadge
        }
    }

    private var cancelledSection: some View {
        Group {
            if let cancelledAt = currentReservation.cancelledAt, currentReservation.status == .cancelled {
                Section {
                    Text(
                        String(
                            format: NSLocalizedString("reservation.detail.cancelledAt", comment: ""),
                            cancelledAt.formatted()
                        )
                    )
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var completedSection: some View {
        Group {
            if currentReservation.status == .completed {
                Section { Text("reservation.detail.status.completed") }
            }
        }
    }

    private var actionsSection: some View {
        Group {
            if currentReservation.canModify {
                Section {
                    NavigationLink(String(localized: "reservation.detail.modify.cta")) {
                        ReservationFormView(
                            viewModel: ReservationViewModel(service: ReservationService(), prefilledName: ""),
                            restaurant: Restaurant(
                                id: currentReservation.restaurantId,
                                name: currentReservation.restaurantName,
                                cuisine: "",
                                address: ""
                            ),
                            mode: .modify(existing: currentReservation),
                            onModified: { confirmation, specialRequests in
                                viewModel.applyModifiedReservation(
                                    currentReservation,
                                    confirmation: confirmation,
                                    specialRequests: specialRequests
                                )
                            }
                        )
                    }
                    Button(role: .destructive) {
                        showsCancelConfirmation = true
                    } label: {
                        Text("reservation.detail.cancel.cta")
                    }
                    .disabled(viewModel.phase == .cancelling(reservationId: currentReservation.id))
                }
            }
        }
    }

    private var errorSection: some View {
        Group {
            if case let .failed(reason) = viewModel.phase {
                Section { Text(reason).foregroundStyle(.red) }
            }
        }
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }

    private var currentReservation: Reservation {
        viewModel.reservations.first { $0.id == reservation.id } ?? reservation
    }

    private var statusText: LocalizedStringKey {
        switch currentReservation.status {
        case .active:
            return "reservation.detail.status.active"
        case .cancelled:
            return "reservation.detail.status.cancelled"
        case .completed:
            return "reservation.detail.status.completed"
        }
    }
}
