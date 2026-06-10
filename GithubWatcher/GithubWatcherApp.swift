import SwiftUI
import SwiftData

@MainActor
@Observable
class AppDependencies {
    let modelContainer: ModelContainer
    let githubClient: any GithubClientProtocol
    let watchedRepositoriesRepository: SwiftDataWatchedRepositoriesRepository
    let watchedPullRequestsRepository: SwiftDataWatchedPullRequestsRepository
    let syncService: SyncService

    init() throws {
        let container: ModelContainer = {
            let schema = Schema([
                WatchedRepository.self,
                WatchedPullRequest.self,
                PullRequestCheck.self,
                AuthSession.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
        self.modelContainer = container
        let modelContext = container.mainContext

        self.githubClient = GithubClient()
        self.watchedRepositoriesRepository = SwiftDataWatchedRepositoriesRepository(githubClient: githubClient, modelContext: modelContext)
        self.watchedPullRequestsRepository = SwiftDataWatchedPullRequestsRepository(watchedRepositoriesRepository: watchedRepositoriesRepository, githubClient: githubClient, modelContext: modelContext)
        self.syncService = SyncService(watchedRepositoriesRepository: watchedRepositoriesRepository, watchedPullRequestsRepository: watchedPullRequestsRepository, modelContext: modelContext)
    }
}

@main
struct GithubWatcherApp: App {
    @State
    var dependencies: AppDependencies = try! AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentView().navigationTitle("GithubWatcher")
        }
        .modelContainer(dependencies.modelContainer)
        .environment(dependencies.syncService)
        .environment(dependencies.watchedRepositoriesRepository)
        .environment(dependencies.watchedPullRequestsRepository)
    }
}
