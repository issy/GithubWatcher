import SwiftData
import Foundation

@Model
final class WatchedRepository {
    var owner: String
    var name: String

    @Attribute(.unique)
    var canonicalName: String

    @Relationship(deleteRule: .cascade, inverse: \WatchedPullRequest.repository)
    var watchedPullRequests: [WatchedPullRequest] = []

    init(owner: String, name: String, watchedPullRequests: [WatchedPullRequest] = []) {
        self.owner = owner
        self.name = name
        self.watchedPullRequests = watchedPullRequests
        self.canonicalName = WatchedRepository.getCanonicalName(owner: owner, name: name)
    }

    static func getCanonicalName(owner: String, name: String) -> String {
        "\(owner)/\(name)"
    }

    func updatePullRequests(with newPullRequests: [GithubSimplePullRequest], ctx modelContext: ModelContext) {
        let newIds = newPullRequests.map(\.number)
        // FIXME: In future this should account for pull requests in the same repo that weren't created by the currently filtered-for author
        // Delete all pull requests not found anymore (closed/merged)
        removePullRequests(notIn: newIds, ctx: modelContext)
        // Insert new items
        newPullRequests.forEach { simplePullRequestData in
            if let existingPullRequestModel = watchedPullRequests.first(where: { $0.id == simplePullRequestData.number }) {
                existingPullRequestModel.updateModel(simplePullRequestData)
            } else {
                watchedPullRequests.append(WatchedPullRequest(author: simplePullRequestData.user.login, id: simplePullRequestData.number, title: simplePullRequestData.title, headCommitRef: simplePullRequestData.head.sha, currentChecks: [], repository: self))
            }
        }
    }

    private func removePullRequests(notIn idsToDelete: [Int], ctx modelContext: ModelContext) {
        let toDelete = watchedPullRequests.filter { idsToDelete.contains($0.id) }
        toDelete.forEach(modelContext.delete)
    }
}

protocol WatchedRepositoriesRepository {
    func insertWatchedRepository(owner: String, name: String) throws
    func fetchRepository(repoCanonicalName: String) -> WatchedRepository?
    func fetchRepository(owner: String, name: String) -> WatchedRepository?
    func fetchAllRepositories() -> [WatchedRepository]
}

@Observable
final class SwiftDataWatchedRepositoriesRepository: WatchedRepositoriesRepository {
    let githubClient: any GithubClientProtocol
    let modelContext: ModelContext
    
    init(githubClient: any GithubClientProtocol, modelContext: ModelContext) {
        self.githubClient = githubClient
        self.modelContext = modelContext
    }

    func insertWatchedRepository(owner: String, name: String) throws {
        if fetchRepository(owner: owner, name: name) == nil {
            let model = WatchedRepository(owner: owner, name: name)
            modelContext.insert(model)
        }
    }

    func fetchRepository(repoCanonicalName: String) -> WatchedRepository? {
        return try? modelContext.fetch(FetchDescriptor<WatchedRepository>(predicate: #Predicate { $0.canonicalName == repoCanonicalName })).first
    }

    func fetchRepository(owner: String, name: String) -> WatchedRepository? {
        let canonicalName = WatchedRepository.getCanonicalName(owner: owner, name: name)
        return fetchRepository(repoCanonicalName: canonicalName)
    }

    func fetchAllRepositories() -> [WatchedRepository] {
        if let repositories = try? modelContext.fetch(FetchDescriptor<WatchedRepository>()) {
            return repositories
        } else {
            return []
        }
    }
}
