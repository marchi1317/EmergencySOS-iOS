import SwiftUI
import MessageUI

struct ContentView: View {

    // MARK: - Services

    @StateObject private var locationService = LocationService()
    @StateObject private var contactStorage = ContactStorage()

    // MARK: - State

    @State private var statusText = "آماده"
    @State private var counter = 30

    @State private var showingMessageComposer = false

    @State private var emergencyTimer: Timer?
    @State private var emergencyLocationTimeout: Timer?

    @State private var waitingForEmergencyLocation = false
    @State private var callAfterMessageSent = false

    // MARK: - Emergency Contacts

    private var emergencyRecipients: [String] {
        contactStorage.contacts
            .map {
                $0.phoneNumber.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { $0 }
    }

    private var firstEmergencyPhoneNumber: String? {
        emergencyRecipients.first
    }

    // MARK: - Emergency Message

    private var emergencyMessageBody: String {
        EmergencyMessage.makeBody(
            mapLink: locationService.mapLink
        )
    }

    // MARK: - Trigger Emergency

    private func triggerEmergency() {

        statusText = "وضعیت اضطراری فعال شد"

        guard !emergencyRecipients.isEmpty else {
            statusText = "شماره اضطراری وارد نشده است"
            return
        }

        waitingForEmergencyLocation = true
        callAfterMessageSent = true

        statusText =
            "در حال دریافت موقعیت اضطراری..."

        emergencyLocationTimeout?.invalidate()
        emergencyLocationTimeout = nil

        locationService.requestCurrentLocation()

        emergencyLocationTimeout = Timer.scheduledTimer(
            withTimeInterval: 10.0,
            repeats: false
        ) { _ in

            guard waitingForEmergencyLocation else {
                return
            }

            waitingForEmergencyLocation = false
            emergencyLocationTimeout = nil

            if EmergencyMessage.canSendText {

                statusText =
                    "موقعیت دریافت نشد؛ پیام اضطراری بدون موقعیت آماده شد"

                showingMessageComposer = true

            } else {

                callAfterMessageSent = false
                statusText =
                    "ارسال پیامک در این دستگاه در دسترس نیست"
            }
        }
    }

    // MARK: - Countdown

    private func startEmergencyCountdown() {

        emergencyTimer?.invalidate()
        emergencyTimer = nil

        emergencyLocationTimeout?.invalidate()
        emergencyLocationTimeout = nil

        waitingForEmergencyLocation = false

        counter = 30
        statusText = "حفاظت فعال شد"

        emergencyTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { timer in

            if counter > 1 {

                counter -= 1

            } else {

                counter = 0

                timer.invalidate()
                emergencyTimer = nil

                triggerEmergency()
            }
        }
    }

    // MARK: - Cancel

    private func cancelEmergency() {

        emergencyTimer?.invalidate()
        emergencyTimer = nil

        emergencyLocationTimeout?.invalidate()
        emergencyLocationTimeout = nil

        waitingForEmergencyLocation = false
        callAfterMessageSent = false

        statusText = "لغو شد"
        counter = 30
    }

    // MARK: - Emergency Call

    private func makeEmergencyCall() {

        guard let phoneNumber = firstEmergencyPhoneNumber else {

            statusText =
                "شماره اضطراری برای تماس وارد نشده است"

            return
        }

        EmergencyCallService.call(
            phoneNumber: phoneNumber
        ) { success in

            DispatchQueue.main.async {

                if success {

                    statusText =
                        "درخواست تماس اضطراری انجام شد"

                } else {

                    statusText =
                        "امکان شروع تماس اضطراری وجود ندارد"
                }
            }
        }
    }

    // MARK: - SMS Result

    private func handleMessageResult(
        _ result: MessageComposeResult
    ) {

        showingMessageComposer = false

        switch result {

        case .sent:

            if callAfterMessageSent {

                callAfterMessageSent = false

                statusText =
                    "پیام اضطراری ارسال شد؛ در حال آماده‌سازی تماس..."

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.7
                ) {
                    makeEmergencyCall()
                }

            } else {

                statusText =
                    "پیام اضطراری ارسال شد"
            }

        case .cancelled:

            callAfterMessageSent = false

            statusText =
                "ارسال پیام لغو شد"

        case .failed:

            callAfterMessageSent = false

            statusText =
                "ارسال پیام اضطراری ناموفق بود"

        @unknown default:

            callAfterMessageSent = false

            statusText =
                "وضعیت ارسال پیام مشخص نیست"
        }
    }


    // MARK: - User Interface

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                Text("Emergency SOS")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("امداد اضطراری")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(statusText)
                    .font(.title3)

                Text("\(counter)")
                    .font(
                        .system(
                            size: 80,
                            weight: .bold
                        )
                    )

                // MARK: Location

                if let latitude = locationService.latitude,
                   let longitude = locationService.longitude {

                    Text("موقعیت دریافت شد")
                        .fontWeight(.bold)

                    Text("\(latitude), \(longitude)")
                        .font(.footnote)
                }

                if let error =
                    locationService.locationError {

                    Text(error)
                        .font(.footnote)
                }

                Button {

                    locationService.requestCurrentLocation()

                    statusText =
                        "در حال دریافت موقعیت..."

                } label: {

                    Text("دریافت موقعیت")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)

                // MARK: Emergency Contacts

                VStack(spacing: 12) {

                    Text("شماره‌های اضطراری")
                        .font(.headline)

                    if contactStorage.contacts.count >= 3 {

                        TextField(
                            "شماره تلفن 1",
                            text:
                                $contactStorage
                                    .contacts[0]
                                    .phoneNumber
                        )
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)

                        TextField(
                            "شماره تلفن 2",
                            text:
                                $contactStorage
                                    .contacts[1]
                                    .phoneNumber
                        )
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)

                        TextField(
                            "شماره تلفن 3",
                            text:
                                $contactStorage
                                    .contacts[2]
                                    .phoneNumber
                        )
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)

                        Button {

                            contactStorage.save()

                            statusText =
                                "شماره‌ها ذخیره شدند"

                        } label: {

                            Text("ذخیره شماره‌ها")
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // MARK: Manual SMS

                Button {

                    guard !emergencyRecipients.isEmpty else {

                        statusText =
                            "شماره اضطراری وارد نشده است"

                        return
                    }

                    if EmergencyMessage.canSendText {


                        callAfterMessageSent = false
                        showingMessageComposer = true

                    } else {

                        statusText =
                            "ارسال پیامک در این دستگاه در دسترس نیست"
                    }

                } label: {

                    Text("ارسال پیام اضطراری")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)

                // MARK: Manual Call

                Button {

                    makeEmergencyCall()

                } label: {

                    Text("تماس اضطراری")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)

                // MARK: Start

                Button {

                    startEmergencyCountdown()

                } label: {

                    Text("شروع")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                // MARK: Cancel

                Button {

                    cancelEmergency()
                        

                } label: {

                    Text("لغو")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }

        .environment(
            \.layoutDirection,
            .rightToLeft
        )

        // MARK: - Location Success

        .onChange(
            of: locationService.lastLocationUpdate
        ) { newValue in

            guard waitingForEmergencyLocation,
            newValue != nil else {
                return
            }

            emergencyLocationTimeout?.invalidate()
            emergencyLocationTimeout = nil

            waitingForEmergencyLocation = false

            if EmergencyMessage.canSendText {

                statusText =
                    "موقعیت دریافت شد؛ پیام اضطراری آماده است"

                showingMessageComposer = true

            } else {
                callAfterMessageSent = false
                statusText =
                    "ارسال پیامک در این دستگاه در دسترس نیست"
            }
        }

        // MARK: - Location Error

        .onChange(
            of: locationService.locationError
        ) { newError in

            guard waitingForEmergencyLocation,
                  let newError,
                  !newError.isEmpty else {
                return
            }

            emergencyLocationTimeout?.invalidate()
            emergencyLocationTimeout = nil

            waitingForEmergencyLocation = false

            if EmergencyMessage.canSendText {

                statusText =
                    "موقعیت در دسترس نیست؛ پیام اضطراری بدون موقعیت آماده شد"

                showingMessageComposer = true

            } else {
                callAfterMessageSent = false
                statusText =
                    "ارسال پیامک در این دستگاه در دسترس نیست"
            }
        }

        // MARK: - Message Composer

        .sheet(
            isPresented: $showingMessageComposer
        ) {

            MessageComposerView(
                recipients: emergencyRecipients,
                body: emergencyMessageBody
            ) { result in

                handleMessageResult(result)
            }
        }
    }
}

#Preview {
    ContentView()
}
