import SwiftUI

struct WatchedRepositoriesContentView: View {
    let viewModel: WatchedRepositoriesContentViewModel

    var body: some View {
        Button(action: viewModel.addWatchedRepository) {
            Text("Add")
        }
        List {
            ForEach(viewModel.watchedRepositories, id: \.canonicalName) { watchedRepo in
                WatchedRepositoryListRowContentView(watchedRepository: watchedRepo)
            }
        }
    }
}

struct WatchedRepositoryListRowContentView: View {
    let watchedRepository: RepositoryItemData

    var body: some View {
        Text(watchedRepository.canonicalName).bold().padding(4)
    }
}

#Preview {
    WatchedRepositoriesContentView(watchedRepositories: [
        RepositoryItemData(owner: "issy", name: "my-app"),
        RepositoryItemData(owner: "issy", name: "foobar"),
        RepositoryItemData(owner: "issy", name: "platform"),
    ], addWatchedRepository: {})
}
