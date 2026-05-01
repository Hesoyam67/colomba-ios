import SwiftUI

public struct RestaurantDetailView: View {
    @ObservedObject private var viewModel: ReservationViewModel
    private let restaurant: Restaurant

    public init(viewModel: ReservationViewModel, restaurant: Restaurant) {
        self.viewModel = viewModel
        self.restaurant = restaurant
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                restaurantCopy
                availability
                NavigationLink {
                    ReservationFormView(viewModel: viewModel, restaurant: restaurant)
                } label: {
                    Text("reservation.reserve")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.availableSlots.isEmpty)
            }
            .padding()
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAvailability(for: restaurant, on: viewModel.selectedDate)
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = restaurant.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.18)
                }
            } else {
                Color.secondary.opacity(0.18)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.largeTitle.bold())
                Text(restaurant.cuisine)
                    .font(.headline)
            }
            .padding()
            .foregroundStyle(.white)
            .shadow(radius: 8)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var restaurantCopy: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(restaurant.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("reservation.book_copy")
                .font(.body)
        }
    }

    private var availability: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("reservation.available_times")
                .font(.headline)
            if viewModel.phase == .loadingAvailability {
                ProgressView(String(localized: "reservation.checking_availability"))
            } else if viewModel.availableSlots.isEmpty {
                ContentUnavailableView(
                    String(localized: "reservation.no_available_times"),
                    systemImage: "clock.badge.exclamationmark"
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(viewModel.availableSlots) { slot in
                        Text(slot.startsAt, format: .dateTime.hour().minute())
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
            }
        }
    }
}
