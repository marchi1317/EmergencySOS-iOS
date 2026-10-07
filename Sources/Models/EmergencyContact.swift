import Foundation

struct EmergencyContact: Identifiable, Codable, Equatable {

    let id: UUID
    var name: String
    var phoneNumber: String

    init(
        id: UUID = UUID(),
        name: String = "",
        phoneNumber: String = ""
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
    }
}
