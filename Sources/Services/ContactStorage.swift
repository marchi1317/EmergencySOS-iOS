import Foundation
import Combine

final class ContactStorage: ObservableObject {

    // MARK: - Storage Key

    private let storageKey = "emergency_contacts"

    // MARK: - Contacts

    @Published var contacts: [EmergencyContact] = []

    // MARK: - Initialization

    init() {
        load()
    }

    // MARK: - Load Contacts

    func load() {

        guard
            let data = UserDefaults.standard.data(
                forKey: storageKey
            ),
            let savedContacts = try? JSONDecoder().decode(
                [EmergencyContact].self,
                from: data
            )
        else {

            contacts = [
                EmergencyContact(name: "مخاطب 1"),
                EmergencyContact(name: "مخاطب 2"),
                EmergencyContact(name: "مخاطب 3")
            ]

            return
        }

        contacts = Array(
            savedContacts.prefix(3)
        )

        while contacts.count < 3 {

            contacts.append(
                EmergencyContact(
                    name: "مخاطب \(contacts.count + 1)"
                )
            )
        }
    }

    // MARK: - Save Contacts

    func save() {

        let threeContacts = Array(
            contacts.prefix(3)
        )

        guard
            let data = try? JSONEncoder().encode(
                threeContacts
            )
        else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: storageKey
        )
    }
}