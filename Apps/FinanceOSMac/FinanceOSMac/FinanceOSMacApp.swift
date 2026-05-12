//
//  FinanceOSMacApp.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import SwiftUI

@main
struct FinanceOSMacApp: App {
    init() {
        _ = DatabaseManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
