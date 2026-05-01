import SwiftUI

public struct RestaurantListView: View {
    @StateObject private var viewModel: ReservationViewModel

    public init(viewModel: ReservationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.phase == .loadingRestaurants, viewModel.restaurants.isEmpty {
                ProgressView(String(localized: "reservation.loading_restaurants"))
            } else if viewModel.restaurants.isEmpty {
                ContentUnavailableView(
                    String(localized: "reservation.empty_title"),
                    systemImage: "fork.knife",
                    description: Text("reservation.empty_desc")
                )
            } else {
                List(viewModel.restaurants) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(viewModel: viewModel, restaurant: restaurant)
                    } label: {
                        RestaurantRow(restaurant: restaurant)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "reservation.nav_title"))
        .task {
            await viewModel.loadRestaurants()
        }
        .alert(String(localized: "reservation.error_title"), isPresented: failedBinding) {
            Button(String(localized: "reservation.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var failedBinding: Binding<Bool> {
        Binding(
            get: {
                if case .failed = viewModel.phase { return true }
                return false
            },
            set: { _ in }
        )
    }

    private var errorMessage: String {
        if case let .failed(reason) = viewModel.phase {
            return reason
        }
        return String(localized: "reservation.failed_default")
    }
}

private struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            RestaurantImage(url: restaurant.imageURL)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                Text(restaurant.cuisine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(restaurant.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct RestaurantImage: View {
    let url: URL?

    var body: some View {
        if let url {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.15)
            }
        } else {
            ZStack {
                Color.secondary.opacity(0.15)
                Image(systemName: "fork.knife")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
