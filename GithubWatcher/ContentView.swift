import SwiftUI
import SwiftData

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
                    WatchedPullRequestsView()
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
