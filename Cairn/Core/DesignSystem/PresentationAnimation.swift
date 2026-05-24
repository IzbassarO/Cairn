import SwiftUI

@MainActor
func withoutPresentationAnimation(_ mutation: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, mutation)
}
