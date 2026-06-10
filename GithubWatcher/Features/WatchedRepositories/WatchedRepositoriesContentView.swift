import SwiftUI

struct WatchedRepositoriesContentView: View {
    let viewModel: WatchedRepositoriesContentViewModel

    var body: some View {
        Button(action: { viewModel.addWatchedRepository("issy", "foo") }) {
            Text("Add")
        }
        Button(action: viewModel.deleteAll) {
            Text("Clear")
        }
        List {
            ForEach(viewModel.repositories, id: \.canonicalName) { watchedRepo in
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
    WatchedRepositoriesContentView(viewModel: WatchedRepositoriesContentViewModel(repositories: [
        RepositoryItemData(owner: "issy", name: "my-app"),
        RepositoryItemData(owner: "issy", name: "foobar"),
        RepositoryItemData(owner: "issy", name: "platform"),
    ], addWatchedRepository: {_, _ in}, deleteAll: {}))
}
