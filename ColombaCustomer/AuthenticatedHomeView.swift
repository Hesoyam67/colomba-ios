// swiftlint:disable file_length
import ColombaAuth
import ColombaDesign
import SwiftUI

struct AuthenticatedHomeView: View {
    let authController: AuthController
    let session: AuthSession
    let reservationService: ReservationServiceProtocol

    @StateObject private var workspaceStore = WorkspaceStore()

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
            ForEach($workspaceStore.workspaces) { $workspace in
                NavigationLink {
                    WorkspaceDashboardView(workspace: $workspace, reservationService: reservationService)
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

            NavigationLink("Create workspace") {
                WorkspaceSetupView(workspace: .draft()) { workspace in
                    workspaceStore.upsert(workspace)
                }
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Choose or manage plan") {
                PlansListView()
            }
            .buttonStyle(.bordered)

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
    @Binding var workspace: Workspace
    let reservationService: ReservationServiceProtocol

    @State private var reservationSyncMessage = "Live reservation sync has not run yet."
    @State private var isRefreshingReservations = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ColombaSpacing.space6) {
                header
                todayGuestsButton
                reservationSyncStatus
                workspaceSetupLinks
                WorkspaceFloorPlanView(workspace: workspace)
            }
            .padding(ColombaSpacing.Screen.margin)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.colomba.bg.base)
        .navigationTitle(workspace.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: workspace.id) {
            await refreshTodayReservations()
        }
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

    private var reservationSyncStatus: some View {
        HStack(alignment: .top, spacing: ColombaSpacing.space3) {
            Image(systemName: isRefreshingReservations ? "arrow.triangle.2.circlepath" : "bolt.horizontal.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.colomba.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: ColombaSpacing.space1) {
                Text("Live reservations")
                    .font(.colomba.bodyMd.weight(.semibold))
                    .foregroundStyle(Color.colomba.text.primary)
                Text(reservationSyncMessage)
                    .font(.colomba.caption)
                    .foregroundStyle(Color.colomba.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button("Refresh") {
                Task { await refreshTodayReservations() }
            }
            .buttonStyle(.bordered)
            .disabled(isRefreshingReservations)
        }
        .padding(ColombaSpacing.space4)
        .background(Color.colomba.bg.card)
        .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous)
                .stroke(Color.colomba.border.hairline, lineWidth: 1)
        )
    }

    private var workspaceSetupLinks: some View {
        HStack(spacing: ColombaSpacing.space3) {
            NavigationLink("Edit workspace setup") {
                WorkspaceSetupView(workspace: workspace) { updated in
                    workspace = updated
                }
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Edit table layout") {
                TableLayoutEditorView(tables: $workspace.tables)
            }
            .buttonStyle(.bordered)
        }
    }

    @MainActor
    private func refreshTodayReservations() async {
        guard !isRefreshingReservations else { return }
        isRefreshingReservations = true
        defer { isRefreshingReservations = false }

        do {
            let reservations = try await reservationService.listMyReservations()
            let todayReservations = Self.workspaceReservations(from: reservations, workspace: workspace)
            workspace.reservations = todayReservations
            markReservedTables(for: todayReservations)
            reservationSyncMessage = syncSuccessMessage(count: todayReservations.count)
        } catch {
            reservationSyncMessage = "Live sync unavailable; showing the saved local reservation sheet."
        }
    }

    private func markReservedTables(for reservations: [WorkspaceReservation]) {
        let reservedTableNames = Set(reservations.filter { !$0.status.isPast }.map(\.tableName))
        workspace.tables = workspace.tables.map { table in
            var copy = table
            copy.isReserved = reservedTableNames.contains(copy.name)
            return copy
        }
    }

    private func syncSuccessMessage(count: Int) -> String {
        if count == 0 {
            return "Live sync complete: no reservations found for today."
        }
        if count == 1 {
            return "Live sync complete: 1 reservation loaded for today."
        }
        return "Live sync complete: \(count) reservations loaded for today."
    }

    private static func workspaceReservations(
        from reservations: [Reservation],
        workspace: Workspace
    ) -> [WorkspaceReservation] {
        let calendar = Calendar.current
        let today = Date()
        let tableNames = workspace.tables.map(\.name)

        return reservations
            .filter { calendar.isDate($0.startsAt, inSameDayAs: today) }
            .sorted { $0.startsAt < $1.startsAt }
            .enumerated()
            .map { index, reservation in
                WorkspaceReservation(
                    id: reservation.id,
                    time: reservationTimeFormatter.string(from: reservation.startsAt),
                    guestName: reservation.restaurantName,
                    guests: reservation.partySize,
                    tableName: tableNames.isEmpty ? "Unassigned" : tableNames[index % tableNames.count],
                    status: ReservationSheetStatus(reservationStatus: reservation.status)
                )
            }
    }

    private static let reservationTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private var todayGuestsButton: some View {
        NavigationLink {
            TodayReservationsView(workspace: $workspace)
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
    @Binding var workspace: Workspace

    var body: some View {
        List {
            Section("Open reservations") {
                if openReservationIDs.isEmpty {
                    Text("No open reservations for today yet.")
                        .foregroundStyle(Color.colomba.text.secondary)
                }

                reservationLinks(for: openReservationIDs)
            }

            Section("Past today") {
                if pastReservationIDs.isEmpty {
                    Text("No past reservations yet.")
                        .foregroundStyle(Color.colomba.text.secondary)
                }

                reservationLinks(for: pastReservationIDs)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.colomba.bg.base)
        .navigationTitle("Today's sheet")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityLabel("Today's reservation sheet")
        .onChange(of: workspace.reservations) { _, _ in
            refreshReservedTableStates()
        }
    }

    @ViewBuilder
    private func reservationLinks(for ids: [String]) -> some View {
        ForEach(ids, id: \.self) { id in
            if let reservation = reservationBinding(for: id) {
                NavigationLink {
                    ReservationDetailView(reservation: reservation, tableNames: workspace.tables.map(\.name))
                } label: {
                    ReservationSheetRow(reservation: reservation.wrappedValue)
                }
            }
        }
    }

    private var openReservationIDs: [String] {
        workspace.openReservations.map(\.id)
    }

    private var pastReservationIDs: [String] {
        workspace.pastReservations.map(\.id)
    }

    private func reservationBinding(for id: String) -> Binding<WorkspaceReservation>? {
        guard let index = workspace.reservations.firstIndex(where: { $0.id == id }) else { return nil }
        return $workspace.reservations[index]
    }

    private func refreshReservedTableStates() {
        let reservedTableNames = Set(workspace.openReservations.map(\.tableName))
        workspace.tables = workspace.tables.map { table in
            var copy = table
            copy.isReserved = reservedTableNames.contains(copy.name)
            return copy
        }
    }
}

private struct ReservationDetailView: View {
    @Binding var reservation: WorkspaceReservation
    let tableNames: [String]

    var body: some View {
        Form {
            Section("Guest") {
                LabeledContent("Name", value: reservation.guestName)
                LabeledContent("Time", value: reservation.time)
                Stepper(value: $reservation.guests, in: 1...20) {
                    Text("\(reservation.guests) guests")
                }
            }

            Section("Service") {
                Picker("Table", selection: $reservation.tableName) {
                    ForEach(tableChoices, id: \.self) { tableName in
                        Text(tableName).tag(tableName)
                    }
                }

                Picker("Status", selection: $reservation.status) {
                    ForEach(ReservationSheetStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.colomba.bg.base)
        .navigationTitle(reservation.guestName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tableChoices: [String] {
        var choices = tableNames
        if choices.isEmpty {
            choices = ["Unassigned"]
        }
        if !choices.contains(reservation.tableName) {
            choices.insert(reservation.tableName, at: 0)
        }
        return choices
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
                Text("Saved room setup. Reserved tables update after today’s live reservation sync.")
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

struct WorkspaceSetupView: View {
    @Environment(\.dismiss)
    private var dismiss
    @State private var draft: Workspace
    let onSave: (Workspace) -> Void

    init(workspace: Workspace, onSave: @escaping (Workspace) -> Void) {
        _draft = State(initialValue: workspace)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Business") {
                TextField("Workspace name", text: $draft.name)
                    .textContentType(.organizationName)
                TextField("Location", text: $draft.location)
                    .textContentType(.fullStreetAddress)
                Picker("Type", selection: $draft.businessKind) {
                    Text("Restaurant workspace").tag("Restaurant workspace")
                    Text("Bar workspace").tag("Bar workspace")
                    Text("Salon workspace").tag("Salon workspace")
                    Text("Hotel workspace").tag("Hotel workspace")
                }
            }

            Section("Room setup") {
                NavigationLink("Edit table positions") {
                    TableLayoutEditorView(tables: $draft.tables)
                }
                LabeledContent("Tables", value: "\(draft.tables.count)")
                Button("Add table") {
                    draft.tables.append(.newTable(number: draft.tables.count + 1))
                }
            }

            Section("Preview") {
                WorkspaceFloorPlanView(workspace: draft)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, ColombaSpacing.space3)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.colomba.bg.base)
        .navigationTitle("Workspace setup")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(draft.normalized())
                    dismiss()
                }
                .disabled(!draft.canSave)
            }
        }
    }
}

private struct TableLayoutEditorView: View {
    @Binding var tables: [WorkspaceTable]
    @State private var selectedTableID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ColombaSpacing.space5) {
                Text("Move tables into the room position. Local setup for now; backend sync comes next.")
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                editablePlan
                tableControls
            }
            .padding(ColombaSpacing.Screen.margin)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.colomba.bg.base)
        .navigationTitle("Table layout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedTableID = selectedTableID ?? tables.first?.id
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                    let table = WorkspaceTable.newTable(number: tables.count + 1)
                    tables.append(table)
                    selectedTableID = table.id
                }
            }
        }
    }

    private var editablePlan: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.colomba.bg.raised)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.colomba.border.hairline, lineWidth: 2)

                ForEach(tables) { table in
                    Button {
                        selectedTableID = table.id
                    } label: {
                        editableTable(table, geometry: geometry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 380)
    }

    private var tableControls: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space4) {
            if let selectedTable {
                Text("Selected: \(selectedTable.name)")
                    .font(.colomba.titleMd)
                    .foregroundStyle(Color.colomba.text.primary)

                HStack(spacing: ColombaSpacing.space3) {
                    Button("←") { moveSelected(dx: -0.05, dy: 0) }
                    Button("↑") { moveSelected(dx: 0, dy: -0.05) }
                    Button("↓") { moveSelected(dx: 0, dy: 0.05) }
                    Button("→") { moveSelected(dx: 0.05, dy: 0) }
                }
                .buttonStyle(.borderedProminent)

                Stepper("Seats: \(selectedTable.seats)", value: selectedSeatsBinding, in: 1...12)

                Button("Remove selected table", role: .destructive) {
                    removeSelected()
                }
                .buttonStyle(.bordered)
            } else {
                Text("Add a table to start the room plan.")
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)
            }
        }
        .padding(ColombaSpacing.space4)
        .background(Color.colomba.bg.card)
        .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous)
                .stroke(Color.colomba.border.hairline, lineWidth: 1)
        )
    }

    private var selectedTable: WorkspaceTable? {
        guard let selectedTableID else { return nil }
        return tables.first { $0.id == selectedTableID }
    }

    private var selectedSeatsBinding: Binding<Int> {
        Binding(
            get: { selectedTable?.seats ?? 1 },
            set: { seats in
                guard let index = selectedIndex else { return }
                tables[index].seats = seats
            }
        )
    }

    private var selectedIndex: Int? {
        guard let selectedTableID else { return nil }
        return tables.firstIndex { $0.id == selectedTableID }
    }

    private func editableTable(_ table: WorkspaceTable, geometry: GeometryProxy) -> some View {
        let width = geometry.size.width * table.width
        let height = geometry.size.height * table.height
        let isSelected = table.id == selectedTableID
        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.colomba.primary.opacity(0.32) : Color.colomba.bg.card)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isSelected ? Color.colomba.primary : Color.colomba.border.hairline,
                    lineWidth: isSelected ? 3 : 2
                )
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

    private func moveSelected(dx: CGFloat, dy: CGFloat) {
        guard let index = selectedIndex else { return }
        tables[index].x = min(max(tables[index].x + dx, 0.12), 0.88)
        tables[index].y = min(max(tables[index].y + dy, 0.14), 0.88)
    }

    private func removeSelected() {
        guard let index = selectedIndex else { return }
        tables.remove(at: index)
        selectedTableID = tables.first?.id
    }
}

final class WorkspaceStore: ObservableObject {
    @Published var workspaces: [Workspace] {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private let key = "colomba.workspaces.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Workspace].self, from: data),
           decoded.isEmpty == false {
            workspaces = decoded
        } else {
            workspaces = Workspace.sampleWorkspaces
        }
    }

    func upsert(_ workspace: Workspace) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index] = workspace
        } else {
            workspaces.append(workspace)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(workspaces) else { return }
        defaults.set(data, forKey: key)
    }
}

struct Workspace: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var location: String
    var businessKind: String
    var symbolName: String
    var reservations: [WorkspaceReservation]
    var tables: [WorkspaceTable]

    var todayGuestCount: Int {
        reservations.reduce(0) { $0 + $1.guests }
    }

    var openReservations: [WorkspaceReservation] {
        reservations.filter { !$0.status.isPast }
    }

    var pastReservations: [WorkspaceReservation] {
        reservations.filter(\.status.isPast)
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !tables.isEmpty
    }

    func normalized() -> Self {
        var copy = self
        copy.name = copy.name.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.location = copy.location.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.symbolName = Self.symbolName(for: copy.businessKind)
        if copy.tables.isEmpty {
            copy.tables = [.newTable(number: 1)]
        }
        return copy
    }

    static func draft() -> Self {
        Self(
            id: UUID().uuidString,
            name: "",
            location: "Basel, Switzerland",
            businessKind: "Restaurant workspace",
            symbolName: symbolName(for: "Restaurant workspace"),
            reservations: [],
            tables: WorkspaceTable.sampleRestaurant.map { $0.availableForSetup }
        )
    }

    static func symbolName(for businessKind: String) -> String {
        switch businessKind {
        case "Bar workspace":
            "wineglass.fill"
        case "Salon workspace":
            "scissors.circle.fill"
        case "Hotel workspace":
            "bed.double.circle.fill"
        default:
            "fork.knife.circle.fill"
        }
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

struct WorkspaceReservation: Identifiable, Codable, Equatable {
    var id: String
    var time: String
    var guestName: String
    var guests: Int
    var tableName: String
    var status: ReservationSheetStatus

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

enum ReservationSheetStatus: String, Codable, Equatable, CaseIterable, Identifiable {
    case open
    case completed
    case cancelled

    init(reservationStatus: Reservation.Status) {
        switch reservationStatus {
        case .active:
            self = .open
        case .completed:
            self = .completed
        case .cancelled:
            self = .cancelled
        }
    }

    var id: String { rawValue }

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

struct WorkspaceTable: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var seats: Int
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var isReserved: Bool

    var availableForSetup: Self {
        var copy = self
        copy.isReserved = false
        return copy
    }

    static func newTable(number: Int) -> Self {
        Self(
            id: UUID().uuidString,
            name: "T\(number)",
            seats: 2,
            x: min(0.25 + CGFloat(number % 4) * 0.18, 0.82),
            y: min(0.30 + CGFloat(number / 4) * 0.20, 0.78),
            width: 0.18,
            height: 0.14,
            isReserved: false
        )
    }

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
