import ArgumentParser

@main
struct FinanceCLIApp: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "FinanceCLI",
        abstract: "FinanceOS headless pipeline — parse, import, and analyze bank statements",
        subcommands: [
            ParseCommand.self,
            ImportCommand.self,
            AnalyzeCommand.self,
            PipelineCommand.self
        ]
    )
}
