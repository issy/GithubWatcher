import SwiftUI
import SwiftData


struct PullRequestListItemView: View {
    let id: Int
    let title: String
    let url: URL

    var body: some View {
        HStack {
            Text("\(id)")
            Spacer()
            Link("Open", destination: url)
        }
    }
}

struct PullRequestsListView: View {
    let isLoading: Bool

    @Query private var watchedPullRequests: [WatchedPullRequest]

    var body: some View {
        List {
            ForEach(watchedPullRequests) { pr in
                PullRequestListItemView(id: pr.id, title: "PR Title", url: URL(string: pr.link())!)
                HStack {
                    Text("#\(pr.id)")
                    Spacer()
                    Link("Open", destination: URL(string: "https://google.com")!)
                }
            }.padding(4)
        }
    }
}

#Preview {
    PullRequestListItemView(id: 12, title: "PR Title", url: URL(string: "https://google.com")!)
}

struct PullRequestsView: View {
    @Environment(GithubClient.self) private var githubClient
    @Environment(\.modelContext) private var modelContext

    @Query private var watchedPullRequests: [WatchedPullRequest]

    @State var isRequesting: Bool = false

    var body: some View {
        PullRequestsListView(isLoading: isRequesting && watchedPullRequests.isEmpty).task {
            Task {
                try await fetch()
            }
        }
    }

    private func fetch() async throws {
        isRequesting = true
        let data = try! await githubClient.fetchAllOpenPullRequestsForRepoByUser(repoCanonicalName: "issy/midi-footcontroller", authoredBy: "issy").map { WatchedPullRequest(author: $0.user.login, id: $0.number, title: "Title", headCommitRef: "abc123", currentChecks: [], repository: WatchedRepository(owner: "issy", name: "midi-footcontroller")) }
        watchedPullRequests.forEach {
            modelContext.delete($0)
        }
        data.forEach {
            modelContext.insert($0)
        }
        isRequesting = false
    }
}

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    WatchedRepositoriesView()
                } label: {
                    Image(systemName: "eye")
                    Text("Watched Repos")
                }
                Divider()
                NavigationLink {
                    PullRequestsView()
                } label: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Ready")
                }
                NavigationLink {
                    ProgressView()
                } label: {
                    Image(systemName: "circle.fill").foregroundStyle(.orange)
                    Text("Running")
                }
                NavigationLink {
                    Text("Baz")
                } label: {
                        Image(systemName: "x.circle.fill").foregroundStyle(.red)
                        Text("Checks Failed")
                }.badge(3)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    let sharedModelContainer: ModelContainer = {
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

    ContentView()
        .modelContainer(sharedModelContainer)
        .environment(GithubClient())
        .navigationTitle("GithubWatcher")
}
