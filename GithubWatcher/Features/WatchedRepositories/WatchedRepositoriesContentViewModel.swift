struct RepositoryItemData {
    let owner: String
    let name: String
    let canonicalName: String

    init(owner: String, name: String) {
        self.owner = owner
        self.name = name
        self.canonicalName = "\(owner)/\(name)"
    }

    static func fromModel(_ model: WatchedRepository) -> Self {
        .init(owner: model.owner, name: model.name)
    }
}

struct WatchedRepositoriesContentViewModel {
    let repositories: [RepositoryItemData]
    let addWatchedRepository: (_ owner: String, _ name: String) -> Void
}
