import ColombaCore
import ColombaDesign
import SwiftUI

struct RootView: View {
    var body: some View {
        Text("Colomba")
            .font(.colomba.display)
            .foregroundStyle(Color.colomba.primary)
            .padding(ColombaSpacing.space5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.colomba.bg.base)
            .onAppear {
                ColdStart.markRootViewAppeared()
            }
    }
}

#Preview {
    RootView()
}
