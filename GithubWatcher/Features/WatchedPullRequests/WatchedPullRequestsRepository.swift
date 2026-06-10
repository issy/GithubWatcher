import Foundation
import SwiftData

@Model
final class WatchedPullRequest {
    var author: String
    var id: Int
    var title: String

    var headCommitRef: String
    var currentMergeableStatus: Bool?

    @Relationship(deleteRule: .cascade, inverse: \PullRequestCheck.pullRequest)
    var currentChecks: [PullRequestCheck]

    var repository: WatchedRepository

    init(author: String, id: Int, title: String, headCommitRef: String, currentMergeableStatus: Bool? = nil, currentChecks: [PullRequestCheck], repository: WatchedRepository) {
        self.author = author
        self.id = id
        self.title = title
        self.headCommitRef = headCommitRef
        self.currentMergeableStatus = currentMergeableStatus
        self.currentChecks = currentChecks
        self.repository = repository
    }

    func link() -> String {
        return "https://github.com/\(repository.canonicalName)/pull/\(id)"
    }

    func updateModel(_ freshData: GithubSimplePullRequest) {
        self.title = freshData.title
    }

    func updateModel(_ freshData: GithubPullRequest) {
        self.title = freshData.title
        self.headCommitRef = freshData.head.sha
    }

    func updateChecks(with newChecks: [PullRequestCheck], in modelContext: ModelContext) {
        let oldChecks = self.currentChecks
        self.currentChecks = newChecks.map { $0.pullRequest = self; return $0 }
        oldChecks.forEach(modelContext.delete)
    }

    func updateChecks(with newChecks: [GithubCheckRunItem], in modelContext: ModelContext) {
        // No fancy logic here. Just replace everything
        self.currentChecks.forEach(modelContext.delete)
        self.currentChecks = newChecks.map { PullRequestCheck(id: $0.id, name: $0.name, status: .from(status: $0.status, conclusion: $0.conclusion), startedAt: $0.startedAt ?? Date(), completedAt: $0.completedAt, pullRequest: self) }
    }
}

@Model
final class PullRequestCheck {
    var id: Int
    var name: String
    var status: PullRequestCheckStatus
    var startedAt: Date
    var completedAt: Date?
    
    var pullRequest: WatchedPullRequest?
    
    init(id: Int, name: String, status: PullRequestCheckStatus, startedAt: Date, completedAt: Date? = nil, pullRequest: WatchedPullRequest?) {
        self.id = id
        self.name = name
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.pullRequest = pullRequest
    }
}

enum PullRequestCheckStatus: String, Codable {
    case success = "SUCCESS"
    case pending = "PENDING"
    case failure = "FAILURE"

    static func from(status: GithubCheckRunStatus, conclusion: GithubCheckRunConclusion?) -> Self {
        switch (status, conclusion) {
        case (.completed, .success):
            return .success
        // Completed with any status other than success
        case (.completed, _):
            return .failure
        // Hasn't completed yet
        default:
            return .pending
        }
    }
}

protocol WatchedPullRequestsRepository {
    func syncPullRequests(forRepository repoCanonicalName: String, by author: String) async throws
}

@Observable
final class SwiftDataWatchedPullRequestsRepository: WatchedPullRequestsRepository {
    let watchedRepositoriesRepository: any WatchedRepositoriesRepository
    let githubClient: any GithubClientProtocol
    let modelContext: ModelContext

    init(watchedRepositoriesRepository: any WatchedRepositoriesRepository, githubClient: any GithubClientProtocol, modelContext: ModelContext) {
        self.watchedRepositoriesRepository = watchedRepositoriesRepository
        self.githubClient = githubClient
        self.modelContext = modelContext
    }

    func syncPullRequests(forRepository repoCanonicalName: String, by author: String) async throws {
        guard let repository = watchedRepositoriesRepository.fetchRepository(repoCanonicalName: repoCanonicalName) else {
            // Repository not in store?
            return
        }
        let openPullRequests = try await self.githubClient.fetchAllOpenPullRequestsForRepoByUser(repoCanonicalName: repoCanonicalName, authoredBy: author)
        repository.updatePullRequests(with: openPullRequests, ctx: modelContext)
        for pullRequest in repository.watchedPullRequests {
            try await syncLatestStatusForPullRequest(for: pullRequest.id, of: repository.canonicalName)
        }
    }

    private func fetchPullRequest(forRepository repoCanonicalName: String, with id: Int) -> WatchedPullRequest? {
        return try? modelContext.fetch(FetchDescriptor<WatchedPullRequest>(predicate: #Predicate { $0.repository.canonicalName == repoCanonicalName && $0.id == id })).first
    }

    private func syncLatestStatusForPullRequest(for pullRequestId: Int, of repoCanonicalName: String) async throws {
        guard let pullRequest = fetchPullRequest(forRepository: repoCanonicalName, with: pullRequestId) else {
            // TODO: Throw not found?
            return
        }
        let headCommitRef = pullRequest.headCommitRef
        let statusChecks = try await githubClient.fetchStatusChecksForCommit(repoCanonicalName: repoCanonicalName, commitRef: headCommitRef)
        pullRequest.updateChecks(with: statusChecks, in: modelContext)
    }
}
