import Apollo
import ApolloAPI
import Foundation

public enum GraphQLClientError: Error, LocalizedError {
    case noData
    case graphqlErrors([String])

    public var errorDescription: String? {
        switch self {
        case .noData:
            return "GraphQL response contained no data."
        case let .graphqlErrors(messages):
            return "GraphQL errors: \(messages.joined(separator: ", "))"
        }
    }
}
