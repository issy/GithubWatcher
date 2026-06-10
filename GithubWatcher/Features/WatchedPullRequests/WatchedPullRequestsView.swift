import SwiftUI
import SwiftData

struct WatchedPullRequestsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SwiftDataWatchedPullRequestsRepository.self) private var watchedPullRequestsRepository

    @Query private var watchedPullRequests: [WatchedPullRequest]

    var body: some View {
        WatchedPullRequestsContentView(viewModel: WatchedPullRequestsContentViewModel(pullRequests: watchedPullRequests.map{PullRequestItemData($0)}))
    }
}
