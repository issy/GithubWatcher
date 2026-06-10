import SwiftUI
import SwiftData

struct WatchedRepositoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies

    @Query private var watchedRepositories: [WatchedRepository]

    var body: some View {
        WatchedRepositoriesContentView(viewModel: WatchedRepositoriesContentViewModel(repositories: watchedRepositories.map{RepositoryItemData.fromModel($0)}, addWatchedRepository: dependencies.watchedRepositoriesRepository.insertWatchedRepository, deleteAll: dependencies.watchedRepositoriesRepository.clearAll))
    }
}
