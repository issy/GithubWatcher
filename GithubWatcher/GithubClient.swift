import Foundation
import Observation

struct GithubUser: Decodable {
    let login: String
    let id: Int
}

enum GithubPullRequestState: String, Decodable {
    case open = "open"
    case closed = "closed"
}

struct GithubPullRequestHead: Decodable {
    let sha: String
}

struct GithubSimplePullRequest: Decodable {
    let number: Int
    let title: String
    let state: GithubPullRequestState
    let user: GithubUser
    let head: GithubPullRequestHead
//    let createdAt: Date
//    let mergedAt: Date?
}

struct GithubPullRequest: Decodable {
    let number: Int
    let title: String
    let state: GithubPullRequestState
    let user: GithubUser
    let createdAt: Date
    let mergedAt: Date?
    let mergeable: PullRequestMergeableStatus
    let head: GithubPullRequestHead
}

struct GithubCheckRunItem: Decodable {
    let id: Int
    let name: String
    let status: GithubCheckRunStatus
    let conclusion: GithubCheckRunConclusion?
    let startedAt: Date?
    let completedAt: Date?
}

struct GithubCheckRunResponse: Decodable {
    let totalCount: Int
    let checkRuns: [GithubCheckRunItem]
}

enum GithubCheckRunStatus: String, Decodable {
    case queued = "queued"
    case in_progress = "in_progress"
    case waiting = "waiting"
    case requested = "requested"
    case pending = "pending"
    case completed = "completed"
}

enum GithubCheckRunConclusion: String, Decodable {
    case success = "success"
     case failure = "failure"
     case neutral = "neutral"
     case cancelled = "cancelled"
     case skipped = "skipped"
     case timedOut = "timed_out"
     case actionRequired = "action_required"
}

enum PullRequestMergeableStatus: Decodable {
    case yes
    case no
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            // nil means a background job has been started to determine mergeable status
            self = .unknown
        } else {
            self = try container.decode(Bool.self) ? .yes : .no
        }
    }
}

protocol GithubClientProtocol {
    func fetchAuthenticatedUser() async throws -> GithubUser
    func fetchAllOpenPullRequestsForRepoByUser(repoCanonicalName: String, authoredBy: String) async throws -> [GithubSimplePullRequest]
    func fetchPullRequest(repoCanonicalName: String, pullRequestNumber: Int) async throws -> GithubPullRequest
    func fetchPullRequestHasBeenMerged(repoCanonicalName: String, pullRequestNumber: Int) async throws -> Bool
    func fetchStatusChecksForCommit(repoCanonicalName: String, commitRef: String) async throws -> [GithubCheckRunItem]
}

@Observable
class MockGithubClient: GithubClientProtocol {
    private static let mockUser = GithubUser(login: "issy", id: 12)
    
    func fetchAuthenticatedUser() async throws -> GithubUser {
        return MockGithubClient.mockUser
    }
    
    func fetchAllOpenPullRequestsForRepoByUser(repoCanonicalName: String, authoredBy: String) async throws -> [GithubSimplePullRequest] {
        return []
    }
    
    func fetchPullRequest(repoCanonicalName: String, pullRequestNumber: Int) async throws -> GithubPullRequest {
        return GithubPullRequest(number: 4, title: "Implement foobar", state: .open, user: MockGithubClient.mockUser, createdAt: .distantPast, mergedAt: nil, mergeable: .yes, head: GithubPullRequestHead(sha: "github-head-sha"))
    }

    func fetchPullRequestHasBeenMerged(repoCanonicalName: String, pullRequestNumber: Int) async throws -> Bool {
        return false
    }
    
    func fetchStatusChecksForCommit(repoCanonicalName: String, commitRef: String) async throws -> [GithubCheckRunItem] {
        return []
    }
}

@Observable
class GithubClient: GithubClientProtocol {
    let session: URLSession
    let username: String

    init(authToken: String, username: String) {
        self.session = GithubClient.makeSession(authToken: authToken)
        self.username = username
    }
    
    init() {
        self.session = GithubClient.makeSession(authToken: "")
        self.username = "issy"
    }
    
    private static func makeSession(authToken: String) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            //            "Authorization": "Bearer \(authToken)",
            "X-GitHub-Api-Version": "2026-03-10",
            "Accept": "application/vnd.github+json"
        ]
        let session = URLSession(configuration: configuration)
        return session
    }
    
    private func getDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    public func fetchAuthenticatedUser() async throws -> GithubUser {
        let url = URL(string: "https://api.github.com/user")!
        let (data, _) = try await session.data(from: url)
        return try self.getDecoder().decode(GithubUser.self, from: data)
    }
    
    private func fetchPullRequestsPageForRepo(repoCanonicalName: String, state: GithubPullRequestState? = nil, page: Int = 1) async throws -> [GithubSimplePullRequest] {
        let url = URL(string: "https://api.github.com/repos/\(repoCanonicalName)/pulls")!
            .appending(queryItems: [URLQueryItem(name: "state", value: state == nil ? state!.rawValue : "all"), URLQueryItem(name: "per_page", value: "100"), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "sort", value: "created"), URLQueryItem(name: "direction", value: "desc")])
        let (data, _) = try await session.data(from: url)
        return try self.getDecoder().decode([GithubSimplePullRequest].self, from: data)
    }
    
    public func fetchAllOpenPullRequestsForRepoByUser(repoCanonicalName: String, authoredBy: String) async throws -> [GithubSimplePullRequest] {
        var pullRequests: [GithubSimplePullRequest] = []
        var page = 1
        while true {
            let pullRequestsPage = try await self.fetchPullRequestsPageForRepo(repoCanonicalName: repoCanonicalName, state: .open, page: page)
            pullRequests.append(contentsOf: pullRequestsPage.filter { pr in pr.user.login == authoredBy && !pullRequests.contains { innerPr in innerPr.number == pr.number} })
            if pullRequestsPage.count < 100 {
                return pullRequests
            }
            page += 1
        }
    }
    
    public func fetchPullRequest(repoCanonicalName: String, pullRequestNumber: Int) async throws -> GithubPullRequest {
        let url = URL(string: "https://api.github.com/repos/\(repoCanonicalName)/pulls/\(pullRequestNumber)")!
        let (data, _) = try await session.data(from: url)
        return try self.getDecoder().decode(GithubPullRequest.self, from: data)
    }

    func fetchPullRequestHasBeenMerged(repoCanonicalName: String, pullRequestNumber: Int) async throws -> Bool {
        let url = URL(string: "https://api.github.com/repos/\(repoCanonicalName)/pulls/\(pullRequestNumber)/merge")!
        let (_, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            return false
        }
        // 204 -> true, 404 -> false
        return response.statusCode == 204
    }

    func fetchStatusChecksForCommit(repoCanonicalName: String, commitRef: String) async throws -> [GithubCheckRunItem] {
        // TODO: Handle pagination
        let url = URL(string: "https://api.github.com/repos/\(repoCanonicalName)/commits/\(commitRef)/check-runs")!
        let (data, _) = try await session.data(from: url)
        return try self.getDecoder().decode(GithubCheckRunResponse.self, from: data).checkRuns
    }
}
