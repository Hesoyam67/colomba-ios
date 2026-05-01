import ColombaCore
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            AuthRootHost()
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("tabs.home"))
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(LocalizedStringKey("tabs.home"))
                }

            NavigationStack {
                RestaurantListView(
                    viewModel: ReservationViewModel(
                        service: ReservationService(),
                        prefilledName: ""
                    )
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("tabs.reservations"))
            .tabItem {
                Image(systemName: "calendar")
                Text(LocalizedStringKey("tabs.reservations"))
            }

            NavigationStack {
                PlansListView()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("tabs.plans"))
            .tabItem {
                Image(systemName: "creditcard")
                Text(LocalizedStringKey("tabs.plans"))
            }

            SettingsView()
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("tabs.settings"))
                .tabItem {
                    Image(systemName: "gear")
                    Text(LocalizedStringKey("tabs.settings"))
                }
        }
        .background(.background)
        .onAppear {
            ColdStart.markRootViewAppeared()
        }
    }
}

#Preview {
    RootView()
}
