import ColombaDesign
import SwiftUI

@MainActor
struct HeidiChatView: View {
    @StateObject private var viewModel: HeidiChatViewModel
    @StateObject private var reservationsViewModel: MyReservationsViewModel
    @State private var route: HeidiCardRoute?
    @State private var cancelCandidate: HeidiBookingConfirmation?

    private let reservationService: ReservationServiceProtocol
    private let prefilledName: String
    private let onGoHome: (() -> Void)?

    init() {
        let service = ReservationService()
        _viewModel = StateObject(wrappedValue: HeidiChatViewModel())
        _reservationsViewModel = StateObject(wrappedValue: MyReservationsViewModel(service: service))
        self.reservationService = service
        self.prefilledName = ""
        self.onGoHome = nil
    }

    init(
        viewModel: HeidiChatViewModel,
        reservationService: ReservationServiceProtocol = ReservationService(),
        prefilledName: String = "",
        onGoHome: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _reservationsViewModel = StateObject(wrappedValue: MyReservationsViewModel(service: reservationService))
        self.reservationService = reservationService
        self.prefilledName = prefilledName
        self.onGoHome = onGoHome
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                onRestaurantDetails: { route = .restaurantDetails($0) },
                                onConfirmBooking: { confirmation in
                                    Task { await viewModel.confirmBooking(confirmation) }
                                },
                                onModifyBooking: { route = .modifyBooking($0) },
                                onCancelBooking: { cancelCandidate = $0 }
                            )
                            .id(message.id)
                        }
                        if viewModel.phase == .sending {
                            HStack {
                                Label(LocalizedStringKey("heidi.thinking"), systemImage: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(Color.colomba.text.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            if case let .failed(message) = viewModel.phase {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.colomba.error)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            ChatInputBar(text: $viewModel.draft, canSend: viewModel.canSend) {
                Task { await viewModel.sendDraft() }
            }
        }
        .background(Color.colomba.bg.base)
        .navigationTitle(Text("heidi.nav_title"))
        .navigationDestination(item: $route) { route in
            destination(for: route)
        }
        .confirmationDialog(
            String(localized: "heidi.confirmation.cancel.confirm.title"),
            isPresented: Binding(
                get: { cancelCandidate != nil },
                set: { if $0 == false { cancelCandidate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "heidi.confirmation.cancel.confirm.cta"), role: .destructive) {
                if let cancelCandidate {
                    Task { await reservationsViewModel.cancel(cancelCandidate.reservationForAction) }
                }
            }
            Button(String(localized: "heidi.confirmation.cancel.dismiss"), role: .cancel) {}
        } message: {
            Text("heidi.confirmation.cancel.confirm.message")
        }
        .toolbar {
            if let onGoHome {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onGoHome()
                    } label: {
                        Label(LocalizedStringKey("tabs.home"), systemImage: "house.fill")
                    }
                    .accessibilityLabel(Text("tabs.home"))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(LocalizedStringKey("heidi.reset")) {
                    viewModel.reset()
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: HeidiCardRoute) -> some View {
        switch route {
        case let .restaurantDetails(card):
            let restaurant = card.restaurantForDeepLink
            RestaurantDetailView(
                viewModel: ReservationViewModel(service: reservationService, prefilledName: prefilledName),
                restaurant: restaurant
            )
        case let .modifyBooking(confirmation):
            let reservation = confirmation.reservationForAction
            ReservationFormView(
                viewModel: ReservationViewModel(service: reservationService, prefilledName: prefilledName),
                restaurant: confirmation.restaurantForAction,
                mode: .modify(existing: reservation),
                onModified: { updatedConfirmation, specialRequests in
                    reservationsViewModel.applyModifiedReservation(
                        reservation,
                        confirmation: updatedConfirmation,
                        specialRequests: specialRequests
                    )
                }
            )
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

#Preview {
    NavigationStack {
        HeidiChatView()
    }
}
