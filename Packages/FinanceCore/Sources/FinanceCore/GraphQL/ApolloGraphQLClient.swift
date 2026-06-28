@preconcurrency import Apollo
@preconcurrency import ApolloAPI
import Foundation

public final class ApolloGraphQLClient: @unchecked Sendable {
    private let client: ApolloClient

    public init(url: URL = URL(string: "http://localhost:4000/graphql")!) {
        let store = ApolloStore()
        let provider = DefaultInterceptorProvider(store: store)
        let transport = RequestChainNetworkTransport(
            interceptorProvider: provider,
            endpointURL: url
        )
        client = ApolloClient(networkTransport: transport, store: store)
    }

    public func fetch<Query: GraphQLQuery>(query: Query) async throws -> Query.Data {
        try await withCheckedThrowingContinuation { continuation in
            client.fetch(query: query) { result in
                switch result {
                case let .success(response):
                    if let data = response.data {
                        continuation.resume(returning: data)
                    } else if let errors = response.errors {
                        let messages = errors.compactMap(\.message)
                        continuation.resume(throwing: GraphQLClientError.graphqlErrors(messages))
                    } else {
                        continuation.resume(throwing: GraphQLClientError.noData)
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func upload<Mutation: GraphQLMutation>(
        mutation: Mutation,
        files: [GraphQLFile]
    ) async throws -> Mutation.Data {
        try await withCheckedThrowingContinuation { continuation in
            client.upload(operation: mutation, files: files) { result in
                switch result {
                case let .success(response):
                    if let data = response.data {
                        continuation.resume(returning: data)
                    } else if let errors = response.errors {
                        let messages = errors.compactMap(\.message)
                        continuation.resume(throwing: GraphQLClientError.graphqlErrors(messages))
                    } else {
                        continuation.resume(throwing: GraphQLClientError.noData)
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func perform<Mutation: GraphQLMutation>(mutation: Mutation) async throws -> Mutation.Data {
        try await withCheckedThrowingContinuation { continuation in
            client.perform(mutation: mutation) { result in
                switch result {
                case let .success(response):
                    if let data = response.data {
                        continuation.resume(returning: data)
                    } else if let errors = response.errors {
                        let messages = errors.compactMap(\.message)
                        continuation.resume(throwing: GraphQLClientError.graphqlErrors(messages))
                    } else {
                        continuation.resume(throwing: GraphQLClientError.noData)
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
