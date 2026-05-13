//
//  CardRepository.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

public protocol CardRepository: Sendable {
    func fetchCards() async throws -> [Card]
}
