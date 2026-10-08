import SwiftUI
import MessageUI

struct MessageComposerView: UIViewControllerRepresentable {

    // MARK: - Properties

    let recipients: [String]
    let body: String
    let onFinish: (MessageComposeResult) -> Void

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    // MARK: - Create Message Composer

    func makeUIViewController(
        context: Context
    ) -> MFMessageComposeViewController {

        let controller = MFMessageComposeViewController()

        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body

        return controller
    }

    // MARK: - Update Message Composer

    func updateUIViewController(
        _ uiViewController: MFMessageComposeViewController,
        context: Context
    ) {
        // No update required.
    }

    // MARK: - Coordinator

           @MainActor
        final class Coordinator:
            NSObject,
            MFMessageComposeViewControllerDelegate {

        private let onFinish: (MessageComposeResult) -> Void

        init(
            onFinish: @escaping (MessageComposeResult) -> Void
        ) {
            self.onFinish = onFinish
        }

        // MARK: - Message Result
            
        @MainActor
        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {

            controller.dismiss(animated: true) {
                self.onFinish(result)
            }
        }
    }
}
