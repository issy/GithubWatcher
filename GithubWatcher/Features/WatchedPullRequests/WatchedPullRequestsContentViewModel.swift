struct PullRequestItemData {
    let id: Int
    let title: String
    let repoCanonicalName: String

    init(id: Int, title: String, repoCanonicalName: String) {
        self.id = id
        self.title = title
        self.repoCanonicalName = repoCanonicalName
    }

    init(_ model: WatchedPullRequest) {
        self.init(id: model.id, title: model.title, repoCanonicalName: model.repository.canonicalName)
    }
}

struct WatchedPullRequestsContentViewModel {
    let pullRequests: [PullRequestItemData]
}
