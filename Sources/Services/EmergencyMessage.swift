import Foundation
import MessageUI

struct EmergencyMessage {

    // MARK: - Emergency Message Body

    static func makeBody(
        mapLink: String?
    ) -> String {

        let location =
            mapLink ?? "موقعیت در دسترس نیست"

        return """
        🚨 هشدار اضطراری! لطفاً فوراً با من تماس بگیرید.
        موقعیت: \(location)
        """
    }

    // MARK: - SMS Availability

    static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }
}