import SwiftUI

struct RepositoryItemData {
    let owner: String
    let name: String
    let canonicalName: String
    
    init(owner: String, name: String) {
        self.owner = owner
        self.name = name
        self.canonicalName = "\(owner)/\(name)"
    }
    
    static func fromModel(_ model: WatchedRepository) -> Self {
        .init(owner: model.owner, name: model.name)
    }
}

struct WatchedRepositoriesContentView: View {
    let watchedRepositories: [RepositoryItemData]
    let addWatchedRepository: () -> Void

    var body: some View {
        Button(action: addWatchedRepository) {
            Text("Add")
        }
        List {
            ForEach(watchedRepositories, id: \.canonicalName) { watchedRepo in
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
