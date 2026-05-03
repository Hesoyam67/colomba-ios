// swiftlint:disable file_length
import ColombaAuth
import ColombaDesign
import SwiftUI

struct AuthenticatedHomeView: View {
    let authController: AuthController
    let session: AuthSession
    let reservationService: ReservationServiceProtocol

    private let workspaces = Workspace.sampleWorkspaces

    init(
        authController: AuthController,
        session: AuthSession,
        reservationService: ReservationServiceProtocol = ReservationService()
    ) {
        self.authController = authController
        self.session = session
        self.reservationService = reservationService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ColombaSpacing.space6) {
                    header
                    workspaceList
                    setupActions
                }
                .padding(ColombaSpacing.Screen.margin)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(Color.colomba.bg.base)
            .navigationTitle("Home")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Authenticated Colomba workspace home screen")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
            Text("Colomba")
                .font(.colomba.display)
                .foregroundStyle(Color.colomba.primary)
            Text("Your workspaces")
                .font(.colomba.titleLg)
                .foregroundStyle(Color.colomba.text.primary)
            Text("Choose the business you want to manage today.")
                .font(.colomba.bodyLg)
                .foregroundStyle(Color.colomba.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your Colomba workspaces")
    }

    private var workspaceList: some View {
        VStack(spacing: ColombaSpacing.space4) {
            ForEach(workspaces) { workspace in
                NavigationLink {
                    WorkspaceDashboardView(workspace: workspace)
                } label: {
                    WorkspaceCard(workspace: workspace)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open workspace \(workspace.name)")
            }
        }
    }

    private var setupActions: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
            Text("Setup & billing")
                .font(.colomba.titleMd)
                .foregroundStyle(Color.colomba.text.primary)

            NavigationLink("Choose or manage plan") {
                PlansListView()
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Usage minutes") {
                UsageView()
            }
            .buttonStyle(.bordered)

            Button(String(localized: "auth.refresh_session")) {
                Task {
                    await authController.refreshSession()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(ColombaSpacing.space4)
        .background(Color.colomba.bg.card)
        .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
        .overlay(cardBorder)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous)
            .stroke(Color.colomba.border.hairline, lineWidth: 1)
    }
}

private struct WorkspaceCard: View {
    let workspace: Workspace

    var body: some View {
        HStack(spacing: ColombaSpacing.space4) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.colomba.primary.opacity(0.14))
                Image(systemName: workspace.symbolName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.colomba.primary)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: ColombaSpacing.space1) {
                Text(workspace.name)
                    .font(.colomba.titleMd)
                    .foregroundStyle(Color.colomba.text.primary)
                Text(workspace.location)
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)
                Text("\(workspace.todayGuestCount) guests reserved today")
                    .font(.colomba.caption.weight(.semibold))
                    .foregroundStyle(Color.colomba.primary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.colomba.text.tertiary)
        }
        .padding(ColombaSpacing.space4)
        .background(Color.colomba.bg.card)
        .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous)
                .stroke(Color.colomba.border.hairline, lineWidth: 1)
        )
    }
}

private struct WorkspaceDashboardView: View {
    let workspace: Workspace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ColombaSpacing.space6) {
                header
                todayGuestsButton
                WorkspaceFloorPlanView(workspace: workspace)
            }
            .padding(ColombaSpacing.Screen.margin)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.colomba.bg.base)
        .navigationTitle(workspace.name)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workspace dashboard for \(workspace.name)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
            Text(workspace.businessKind)
                .font(.colomba.caption.weight(.semibold))
                .foregroundStyle(Color.colomba.primary)
            Text(workspace.name)
                .font(.colomba.display)
                .foregroundStyle(Color.colomba.text.primary)
            Text(workspace.location)
                .font(.colomba.bodyLg)
                .foregroundStyle(Color.colomba.text.secondary)
        }
    }

    private var todayGuestsButton: some View {
        NavigationLink {
            TodayReservationsView(workspace: workspace)
        } label: {
            HStack(spacing: ColombaSpacing.space4) {
                VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
                    Text("Today")
                        .font(.colomba.caption.weight(.semibold))
                        .foregroundStyle(Color.colomba.text.secondary)
                    Text("\(workspace.todayGuestCount) guests reserved")
                        .font(.colomba.titleLg)
                        .foregroundStyle(Color.colomba.text.primary)
                    Text("\(workspace.openReservations.count) open reservations")
                        .font(.colomba.bodyMd)
                        .foregroundStyle(Color.colomba.text.secondary)
                }
                Spacer()
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.largeTitle)
                    .foregroundStyle(Color.colomba.primary)
            }
            .padding(ColombaSpacing.space5)
            .background(Color.colomba.bg.card)
            .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous)
                    .stroke(Color.colomba.border.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open today's reservation sheet")
    }
}

private struct TodayReservationsView: View {
    let workspace: Workspace

    var body: some View {
        List {
            Section("Open reservations") {
                ForEach(workspace.openReservations) { reservation in
                    ReservationSheetRow(reservation: reservation)
                }
            }

            Section("Past today") {
                ForEach(workspace.pastReservations) { reservation in
                    ReservationSheetRow(reservation: reservation)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.colomba.bg.base)
        .navigationTitle("Today's sheet")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityLabel("Today's reservation sheet")
    }
}

private struct ReservationSheetRow: View {
    let reservation: WorkspaceReservation

    var body: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
            HStack {
                Text(reservation.time)
                    .font(.colomba.bodyMd.weight(.semibold))
                    .foregroundStyle(Color.colomba.text.primary)
                Spacer()
                Text(reservation.status.title)
                    .font(.colomba.caption.weight(.semibold))
                    .foregroundStyle(reservation.status.color)
            }

            Text(reservation.guestName)
                .font(.colomba.bodyLg)
                .foregroundStyle(Color.colomba.text.primary)

            HStack(spacing: ColombaSpacing.space3) {
                Label("\(reservation.guests) guests", systemImage: "person.2.fill")
                Label(reservation.tableName, systemImage: "table.furniture")
            }
            .font(.colomba.caption)
            .foregroundStyle(Color.colomba.text.secondary)
        }
        .padding(.vertical, ColombaSpacing.space2)
        .accessibilityElement(children: .combine)
    }
}

private struct WorkspaceFloorPlanView: View {
    let workspace: Workspace

    var body: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space4) {
            VStack(alignment: .leading, spacing: ColombaSpacing.space1) {
                Text("Room plan")
                    .font(.colomba.titleMd)
                    .foregroundStyle(Color.colomba.text.primary)
                Text("Early shell: later this becomes the custom table layout from workspace setup.")
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.colomba.bg.raised)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.colomba.border.hairline, lineWidth: 2)

                    roomLabel("Entrance", x: 0.08, y: 0.08, geometry: geometry)
                    roomLabel("Kitchen", x: 0.68, y: 0.08, geometry: geometry)
                    roomLabel("Bar", x: 0.08, y: 0.74, geometry: geometry)

                    ForEach(workspace.tables) { table in
                        tableView(table, geometry: geometry)
                    }
                }
            }
            .frame(height: 360)
        }
        .padding(ColombaSpacing.space5)
        .background(Color.colomba.bg.card)
        .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous)
                .stroke(Color.colomba.border.hairline, lineWidth: 1)
        )
    }

    private func roomLabel(_ text: String, x: CGFloat, y: CGFloat, geometry: GeometryProxy) -> some View {
        Text(text)
            .font(.colomba.caption.weight(.semibold))
            .foregroundStyle(Color.colomba.text.secondary)
            .padding(.horizontal, ColombaSpacing.space3)
            .padding(.vertical, ColombaSpacing.space2)
            .background(Color.colomba.bg.card.opacity(0.85))
            .clipShape(Capsule())
            .position(x: geometry.size.width * x + 44, y: geometry.size.height * y + 18)
    }

    private func tableView(_ table: WorkspaceTable, geometry: GeometryProxy) -> some View {
        let width = geometry.size.width * table.width
        let height = geometry.size.height * table.height
        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(table.isReserved ? Color.colomba.primary.opacity(0.24) : Color.colomba.bg.card)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(table.isReserved ? Color.colomba.primary : Color.colomba.border.hairline, lineWidth: 2)
            VStack(spacing: 2) {
                Text(table.name)
                    .font(.colomba.caption.weight(.bold))
                    .foregroundStyle(Color.colomba.text.primary)
                Text("\(table.seats) seats")
                    .font(.caption2)
                    .foregroundStyle(Color.colomba.text.secondary)
            }
        }
        .frame(width: width, height: height)
        .position(x: geometry.size.width * table.x, y: geometry.size.height * table.y)
    }
}

private struct Workspace: Identifiable {
    let id: String
    let name: String
    let location: String
    let businessKind: String
    let symbolName: String
    let reservations: [WorkspaceReservation]
    let tables: [WorkspaceTable]

    var todayGuestCount: Int {
        reservations.reduce(0) { $0 + $1.guests }
    }

    var openReservations: [WorkspaceReservation] {
        reservations.filter { !$0.status.isPast }
    }

    var pastReservations: [WorkspaceReservation] {
        reservations.filter(\.status.isPast)
    }

    static let sampleWorkspaces = [
        Self(
            id: "osteria-milano-basel",
            name: "Osteria Milano Basel",
            location: "Basel, Switzerland",
            businessKind: "Restaurant workspace",
            symbolName: "fork.knife.circle.fill",
            reservations: WorkspaceReservation.sampleToday,
            tables: WorkspaceTable.sampleRestaurant
        )
    ]
}

private struct WorkspaceReservation: Identifiable {
    let id: String
    let time: String
    let guestName: String
    let guests: Int
    let tableName: String
    let status: ReservationSheetStatus

    static let sampleToday = [
        Self(
            id: "res-1800",
            time: "18:00",
            guestName: "M. Keller",
            guests: 2,
            tableName: "T1",
            status: .open
        ),
        Self(
            id: "res-1830",
            time: "18:30",
            guestName: "Adrian Gercak",
            guests: 4,
            tableName: "T4",
            status: .open
        ),
        Self(
            id: "res-1930",
            time: "19:30",
            guestName: "Fam. Rossi",
            guests: 6,
            tableName: "T6",
            status: .open
        ),
        Self(
            id: "res-1230",
            time: "12:30",
            guestName: "S. Meier",
            guests: 3,
            tableName: "T2",
            status: .completed
        ),
        Self(
            id: "res-1300",
            time: "13:00",
            guestName: "L. Novak",
            guests: 2,
            tableName: "T3",
            status: .completed
        )
    ]
}

private enum ReservationSheetStatus {
    case open
    case completed
    case cancelled

    var title: String {
        switch self {
        case .open:
            "Open"
        case .completed:
            "Past"
        case .cancelled:
            "Cancelled"
        }
    }

    var isPast: Bool {
        switch self {
        case .open:
            false
        case .completed, .cancelled:
            true
        }
    }

    var color: Color {
        switch self {
        case .open:
            Color.colomba.primary
        case .completed:
            Color.colomba.success
        case .cancelled:
            Color.colomba.text.tertiary
        }
    }
}

private struct WorkspaceTable: Identifiable {
    let id: String
    let name: String
    let seats: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let isReserved: Bool

    static let sampleRestaurant = [
        Self(id: "t1", name: "T1", seats: 2, x: 0.25, y: 0.32, width: 0.20, height: 0.14, isReserved: true),
        Self(id: "t2", name: "T2", seats: 4, x: 0.55, y: 0.33, width: 0.22, height: 0.15, isReserved: false),
        Self(id: "t3", name: "T3", seats: 2, x: 0.78, y: 0.42, width: 0.18, height: 0.14, isReserved: false),
        Self(id: "t4", name: "T4", seats: 4, x: 0.33, y: 0.62, width: 0.24, height: 0.16, isReserved: true),
        Self(id: "t5", name: "T5", seats: 2, x: 0.60, y: 0.66, width: 0.18, height: 0.14, isReserved: false),
        Self(id: "t6", name: "T6", seats: 6, x: 0.79, y: 0.72, width: 0.26, height: 0.16, isReserved: true)
    ]
}

#Preview {
    AuthenticatedHomeView(
        authController: .productionMock(),
        session: AuthSession(
            customer: Customer(
                id: "preview",
                displayName: "Papu",
                billingEmail: "owner@example.ch",
                locale: .englishSwitzerland,
                authProvider: .google
            ),
            tokens: AuthTokens(
                accessToken: "access",
                refreshToken: "refresh",
                expiresAt: Date().addingTimeInterval(3600)
            ),
            onboardingRequired: false
        )
    )
}
