import Foundation
import SwiftData
import Observation

@Model
final class AuthSession {
    var token: String
    var username: String

    init(token: String, username: String) {
        self.token = token
        self.username = username
    }
}

enum GithubAuthenticationState {
    case unauthenticated
    case authenticated(AuthSession)
}

extension GithubAuthenticationState {
    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }

    var username: String? {
        if case .authenticated(let session) = self {
            return session.username
        }
        return nil
    }
}
