import SwiftUI

public struct RestaurantListView: View {
    @StateObject private var viewModel: ReservationViewModel

    public init(viewModel: ReservationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.phase == .loadingRestaurants, viewModel.restaurants.isEmpty {
                ProgressView("Loading restaurants")
            } else if viewModel.restaurants.isEmpty {
                ContentUnavailableView(
                    "No restaurants yet",
                    systemImage: "fork.knife",
                    description: Text("Reservation partners will appear here.")
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
        .navigationTitle("Reserve")
        .task {
            await viewModel.loadRestaurants()
        }
        .alert("Reservation error", isPresented: failedBinding) {
            Button("OK", role: .cancel) {}
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
        return "Reservation failed"
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
