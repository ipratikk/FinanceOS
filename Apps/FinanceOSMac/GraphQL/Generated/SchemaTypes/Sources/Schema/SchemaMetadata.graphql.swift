// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public nonisolated protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
    where Schema == FinanceOSAPI.SchemaMetadata {}

public nonisolated protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
    where Schema == FinanceOSAPI.SchemaMetadata {}

public nonisolated protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
    where Schema == FinanceOSAPI.SchemaMetadata {}

public nonisolated protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
    where Schema == FinanceOSAPI.SchemaMetadata {}

public nonisolated enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
        "Bank": FinanceOSAPI.Objects.Bank,
        "CategoryBreakdown": FinanceOSAPI.Objects.CategoryBreakdown,
        "ImportResult": FinanceOSAPI.Objects.ImportResult,
        "Ledger": FinanceOSAPI.Objects.Ledger,
        "Money": FinanceOSAPI.Objects.Money,
        "MonthlyBreakdown": FinanceOSAPI.Objects.MonthlyBreakdown,
        "Mutation": FinanceOSAPI.Objects.Mutation,
        "Query": FinanceOSAPI.Objects.Query,
        "SpendingSummary": FinanceOSAPI.Objects.SpendingSummary,
        "Transaction": FinanceOSAPI.Objects.Transaction
    ]

    @_spi(Execution)
    public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
        objectTypeMap[typename]
    }
}

public nonisolated enum Objects {}
public nonisolated enum Interfaces {}
public nonisolated enum Unions {}
