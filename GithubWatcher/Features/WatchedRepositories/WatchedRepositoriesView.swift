import SwiftUI
import SwiftData

struct WatchedRepositoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SwiftDataWatchedRepositoriesRepository.self) private var watchedRepositoriesRepository

    @Query private var watchedRepositories: [WatchedRepository]

    var body: some View {
        WatchedRepositoriesContentView(viewModel: WatchedRepositoriesContentViewModel(repositories: watchedRepositories.map { RepositoryItemData.init($0) }, addWatchedRepository: watchedRepositoriesRepository.insertWatchedRepository, deleteAll: watchedRepositoriesRepository.clearAll))
    }
}
