import SwiftUI
import SwiftData

struct WatchedPullRequestsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDependencies.self) private var dependencies

    @Query private var watchedPullRequests: [WatchedPullRequest]

    var body: some View {
        WatchedPullRequestsContentView(viewModel: WatchedPullRequestsContentViewModel(pullRequests: watchedPullRequests.map{PullRequestItemData($0)}))
    }
}
