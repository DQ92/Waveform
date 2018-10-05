//
// Created by Michał Kos on 2018-10-04.
// Copyright (c) 2018 Daniel Kuta. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    // Nie wrzucac do projektu tylko przerobic na wyswietlanie alertow w apce
    func showAlert(with title: String, and message: String, and actionTitle: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: nil))
        present(alertController, animated: true)
    }
}
