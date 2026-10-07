import Foundation
import UIKit

struct EmergencyCallService {

    static func call(
        phoneNumber: String,
        completion: @escaping (Bool) -> Void
    ) {

        let cleanedNumber = phoneNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedNumber.isEmpty else {
            completion(false)
            return
        }

        let allowedCharacters = CharacterSet(
            charactersIn: "+0123456789"
        )

        let safeNumber = cleanedNumber
            .unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .map(String.init)
            .joined()

        guard
            !safeNumber.isEmpty,
            let url = URL(string: "tel:\(safeNumber)"),
            UIApplication.shared.canOpenURL(url)
        else {
            completion(false)
            return
        }

        UIApplication.shared.open(
            url,
            options: [:],
            completionHandler: completion
        )
    }
}
