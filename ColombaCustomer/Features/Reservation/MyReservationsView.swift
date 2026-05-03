import SwiftUI

public struct MyReservationsView: View {
    @StateObject private var viewModel: MyReservationsViewModel
    private let reservationService: ReservationServiceProtocol
    private let prefilledName: String

    public init(
        viewModel: MyReservationsViewModel,
        reservationService: ReservationServiceProtocol = ReservationService(),
        prefilledName: String = ""
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.reservationService = reservationService
        self.prefilledName = prefilledName
    }

    public var body: some View {
        List {
            Picker(String(localized: "reservation.list.title"), selection: $viewModel.filter) {
                Text("reservation.list.filter.upcoming").tag(MyReservationsViewModel.Filter.upcoming)
                Text("reservation.list.filter.past").tag(MyReservationsViewModel.Filter.past)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)

            if viewModel.phase == .loading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.filteredReservations.isEmpty {
                VStack(spacing: 12) {
                    Text(emptyText)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    NavigationLink {
                        RestaurantListView(
                            viewModel: ReservationViewModel(service: reservationService, prefilledName: prefilledName)
                        )
                    } label: {
                        Label(String(localized: "reservation.list.book.cta"), systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.filteredReservations) { reservation in
                    NavigationLink {
                        MyReservationDetailView(
                            viewModel: viewModel,
                            reservation: reservation,
                            reservationService: reservationService,
                            prefilledName: prefilledName
                        )
                    } label: {
                        ReservationRow(reservation: reservation)
                    }
                }
            }
        }
        .navigationTitle(Text("reservation.list.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    RestaurantListView(
                        viewModel: ReservationViewModel(service: reservationService, prefilledName: prefilledName)
                    )
                } label: {
                    Label(String(localized: "reservation.list.book.cta"), systemImage: "plus")
                }
                .accessibilityLabel(Text("reservation.list.book.cta"))
            }
        }
        .refreshable { await viewModel.refresh() }
        .task {
            if viewModel.phase == .idle {
                await viewModel.loadReservations()
            }
        }
    }

    private var emptyText: LocalizedStringKey {
        switch viewModel.filter {
        case .upcoming:
            return "reservation.list.empty.upcoming"
        case .past:
            return "reservation.list.empty.past"
        }
    }
}

private struct ReservationRow: View {
    let reservation: Reservation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reservation.restaurantName)
                .font(.headline)
            Text(reservation.startsAt, format: .dateTime.weekday().day().month().hour().minute())
                .foregroundStyle(.secondary)
            Text(String(format: NSLocalizedString("reservation.party_of_format", comment: ""), reservation.partySize))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
