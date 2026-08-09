import SwiftUI

@MainActor
struct LaunchView: View {
    let store: LaunchStore

    var body: some View {
        VStack(spacing: Constants.spacing) {
            Image(systemName: Constants.iconName)
                .font(.system(size: Constants.iconSize))
                .foregroundStyle(.tint)
            Text(Constants.title)
                .font(.largeTitle.bold())
            ProgressView()
        }
        .task {
            store.send(.appeared)
        }
    }

    private enum Constants {
        static let spacing: CGFloat = 16
        static let iconName = "pawprint.fill"
        static let iconSize: CGFloat = 56
        static let title = "HappyPaw"
    }
}

#Preview {
    LaunchView(store: LaunchStore())
}
