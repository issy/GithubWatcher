import SwiftData

@Observable
final class SyncService {
    let watchedRepositoriesRepository: WatchedRepositoriesRepository
    let watchedPullRequestsRepository: any WatchedPullRequestsRepository
    let modelContext: ModelContext

    init(watchedRepositoriesRepository: any WatchedRepositoriesRepository, watchedPullRequestsRepository: any WatchedPullRequestsRepository, modelContext: ModelContext) {
        self.watchedRepositoriesRepository = watchedRepositoriesRepository
        self.watchedPullRequestsRepository = watchedPullRequestsRepository
        self.modelContext = modelContext
    }

    func syncRepositories() async throws {
        let watchedRepositories = watchedRepositoriesRepository.fetchAllRepositories()
        for repository in watchedRepositories {
            try await watchedPullRequestsRepository.syncPullRequests(forRepository: repository.canonicalName, by: "issy")
        }
    }
}
