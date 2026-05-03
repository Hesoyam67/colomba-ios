import Foundation

public final class ReservationService: ReservationServiceProtocol, @unchecked Sendable {
    private let client: ReservationHTTPClientProtocol
    private let keychain: KeychainStoring
    private let refreshTokenOverride: String?

    public init(
        client: ReservationHTTPClientProtocol = HTTPReservationClient(),
        keychain: KeychainStoring = DefaultKeychain(),
        refreshToken: String? = nil
    ) {
        self.client = client
        self.keychain = keychain
        self.refreshTokenOverride = refreshToken
    }

    public func listRestaurants() async throws -> [Restaurant] {
        let token = try refreshToken()
        return try await mapTransportErrors {
            try await client.listRestaurants(refreshToken: token)
        }
    }

    public func availability(restaurantId: String, date: Date) async throws -> [TimeSlot] {
        let token = try refreshToken()
        return try await mapTransportErrors {
            try await client.availability(
                restaurantId: restaurantId,
                date: date,
                refreshToken: token
            )
        }
    }

    public func createReservation(_ request: ReservationRequest) async throws -> ReservationConfirmation {
        let token = try refreshToken()
        return try await mapTransportErrors {
            try await client.createReservation(request, refreshToken: token)
        }
    }

    public func listMyReservations() async throws -> [Reservation] {
        let token = try refreshToken()
        return try await mapTransportErrors {
            try await client.listMyReservations(refreshToken: token)
        }
    }

    public func cancelReservation(id: String) async throws {
        let token = try refreshToken()
        return try await mapTransportErrors {
            try await client.cancelReservation(id: id, refreshToken: token)
        }
    }

    public func modifyReservation(
        id: String,
        slotId: String,
        partySize: Int,
        specialRequests: String?
    ) async throws -> ReservationConfirmation {
        let token = try refreshToken()
        return try await mapTransportErrors {
            try await client.modifyReservation(
                id: id,
                slotId: slotId,
                partySize: partySize,
                specialRequests: specialRequests,
                refreshToken: token
            )
        }
    }

    private func refreshToken() throws -> String {
        if let refreshTokenOverride, refreshTokenOverride.isEmpty == false {
            return refreshTokenOverride
        }
        guard let token = try keychain.string(forKey: SMSVerifyService.refreshTokenKey), token.isEmpty == false else {
            throw ReservationError.notAuthenticated
        }
        return token
    }

    private func mapTransportErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as ReservationError {
            throw error
        } catch {
            throw ReservationError.network(underlying: error)
        }
    }
}
