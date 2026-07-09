import Apollo
import ApolloAPI
import Foundation

/// Cache policy for `ApolloGraphQLClient.fetch`, decoupled from Apollo's own `CachePolicy` type
/// so callers outside this package never need to import Apollo directly.
public enum GraphQLFetchCachePolicy: Sendable {
    /// Return data from the cache if available, else fetch results from the server.
    case cacheFirst
    /// Fetch results from the server, do not attempt to read data from the cache.
    case networkOnly

    fileprivate var apolloPolicy: CachePolicy.Query.SingleResponse {
        switch self {
        case .cacheFirst: return .cacheFirst
        case .networkOnly: return .networkOnly
        }
    }
}

public final class ApolloGraphQLClient: @unchecked Sendable {
    private let client: ApolloClient

    public init(url: URL = URL(string: "http://localhost:4000/graphql") ?? URL(fileURLWithPath: "/")) {
        client = ApolloClient(url: url)
    }

    public func fetch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: GraphQLFetchCachePolicy = .cacheFirst
    ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
        let response = try await client.fetch(query: query, cachePolicy: cachePolicy.apolloPolicy)
        return try Self.unwrap(response)
    }

    public func upload<Mutation: GraphQLMutation>(
        mutation: Mutation,
        files: [GraphQLFile]
    ) async throws -> Mutation.Data where Mutation.ResponseFormat == SingleResponseFormat {
        let response = try await client.upload(operation: mutation, files: files)
        return try Self.unwrap(response)
    }

    public func perform<Mutation: GraphQLMutation>(
        mutation: Mutation
    ) async throws -> Mutation.Data where Mutation.ResponseFormat == SingleResponseFormat {
        let response = try await client.perform(mutation: mutation)
        return try Self.unwrap(response)
    }

    private static func unwrap<Operation: GraphQLOperation>(
        _ response: GraphQLResponse<Operation>
    ) throws -> Operation.Data {
        if let data = response.data {
            return data
        } else if let errors = response.errors {
            throw GraphQLClientError.graphqlErrors(errors.compactMap(\.message))
        } else {
            throw GraphQLClientError.noData
        }
    }
}
