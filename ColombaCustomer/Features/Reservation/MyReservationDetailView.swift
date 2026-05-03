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
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(reservation.restaurantName)
                        .font(.title2.bold())
                    Text(reservation.startsAt, format: .dateTime.weekday().day().month().hour().minute())
                    Text(
                        String(
                            format: NSLocalizedString("reservation.party_of_format", comment: ""),
                            reservation.partySize
                        )
                    )
                    Text(reservation.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                statusBadge
            }

            if let cancelledAt = reservation.cancelledAt, reservation.status == .cancelled {
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

            if reservation.status == .completed {
                Section { Text("reservation.detail.status.completed") }
            }

            if reservation.canModify {
                Section {
                    NavigationLink(String(localized: "reservation.detail.modify.cta")) {
                        ReservationFormView(
                            viewModel: ReservationViewModel(service: ReservationService(), prefilledName: ""),
                            restaurant: Restaurant(
                                id: reservation.restaurantId,
                                name: reservation.restaurantName,
                                cuisine: "",
                                address: ""
                            ),
                            mode: .modify(existing: reservation),
                            onModified: { _ in
                                Task { await viewModel.refresh() }
                            }
                        )
                    }
                    Button(role: .destructive) {
                        showsCancelConfirmation = true
                    } label: {
                        Text("reservation.detail.cancel.cta")
                    }
                    .disabled(viewModel.phase == .cancelling(reservationId: reservation.id))
                }
            }

            if case let .failed(reason) = viewModel.phase {
                Section { Text(reason).foregroundStyle(.red) }
            }
        }
        .navigationTitle(Text("reservation.list.title"))
        .confirmationDialog(
            String(localized: "reservation.detail.cancel.confirm.title"),
            isPresented: $showsCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "reservation.detail.cancel.confirm.confirmCta"), role: .destructive) {
                Task { await viewModel.cancel(reservation) }
            }
            Button(String(localized: "reservation.detail.cancel.confirm.dismissCta"), role: .cancel) {}
        } message: {
            Text("reservation.detail.cancel.confirm.message")
        }
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }

    private var statusText: LocalizedStringKey {
        switch reservation.status {
        case .active:
            return "reservation.detail.status.active"
        case .cancelled:
            return "reservation.detail.status.cancelled"
        case .completed:
            return "reservation.detail.status.completed"
        }
    }
}
