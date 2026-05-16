import FinanceCore
import FinanceParsers
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel
    @Binding var targetChoice: TargetChoice?

    @State var showCreateSheet = false
    @State var newEntityName = ""
    @State var newEntityNickname = ""
    @State var newEntityLast4 = ""
    @State var newEntityBankID: UUID?
    @State var newEntityOwnerName = ""
    @State var detectedBank = ""
    @State var isCard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                fileListSection()
                Divider()
                aggregatedSummarySection()
                Divider()
                targetSelectionSection
                Divider()
                aggregatedTransactionListSection()
            }
            .padding()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateNewTargetSheet(
                name: $newEntityName,
                nickname: $newEntityNickname,
                last4: $newEntityLast4,
                bankID: $newEntityBankID,
                ownerName: $newEntityOwnerName,
                isCard: isCard,
                banks: viewModel.banks,
                detectedBank: detectedBank,
                onCancel: {
                    showCreateSheet = false
                    targetChoice = nil
                },
                onCreate: {
                    Task {
                        let metadata = viewModel.parsedStatements.first?.metadata
                        let accountType = AccountType.from(metadataAccountType: metadata?.accountType ?? "")
                        await viewModel.createTargetFromDetected(
                            customName: newEntityName,
                            nickname: newEntityNickname,
                            last4: newEntityLast4,
                            bankID: newEntityBankID,
                            ownerName: newEntityOwnerName,
                            accountType: accountType,
                            isCard: isCard
                        )
                        showCreateSheet = false
                        targetChoice = nil
                    }
                }
            )
        }
    }
}
