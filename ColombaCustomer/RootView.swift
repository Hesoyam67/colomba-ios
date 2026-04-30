import ColombaCore
import SwiftUI

struct RootView: View {
    @State private var authContent: AnyView?

    var body: some View {
        Group {
            if let authContent {
                authContent
            } else {
                Text("Colomba")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.background)
                    .accessibilityLabel("Colomba")
            }
        }
        .background(.background)
        .onAppear {
            ColdStart.markRootViewAppeared()
            guard authContent == nil else {
                return
            }
            Task { @MainActor in
                await Task.yield()
                authContent = AnyView(AuthRootHost())
            }
        }
    }
}

#Preview {
    RootView()
}
