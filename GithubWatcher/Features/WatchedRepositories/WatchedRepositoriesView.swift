import SwiftUI
import SwiftData

struct WatchedRepositoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var watchedRepositories: [WatchedRepository]
    
    var body: some View {
        WatchedRepositoriesContentView(watchedRepositories: watchedRepositories.map{RepositoryItemData.fromModel($0)}, addWatchedRepository: {})
    }

    private func addWatchedRepository() {
            modelContext.insert(WatchedRepository(owner: "issy", name: "app"))
    }
}
