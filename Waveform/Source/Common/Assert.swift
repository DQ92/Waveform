import Foundation
import UIKit

class Assert {

    static func checkRepresentation(_ condition: @autoclosure () -> Bool,
                                    _ message: String? = "") {
        #if DEBUG
        if condition() {
            let assertMessage = message ?? ""
            print("🆘 ASSERT FAILED! \(assertMessage)")
            Assert.showAlert(message: assertMessage)
        }
        #endif
    }

    static func showAlert(message: String) {
        let alert = UIAlertController(title: "ERROR", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(alert, animated: true)
        }
    }
}
