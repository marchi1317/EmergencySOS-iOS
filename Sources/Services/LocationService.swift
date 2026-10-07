import Foundation
import Combine
import CoreLocation

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var locationError: String?
    @Published var lastLocationUpdate: Date?

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestCurrentLocation() {

        locationError = nil

        switch manager.authorizationStatus {

        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

        case .denied:
            locationError = "دسترسی به موقعیت مکانی رد شده است."

        case .restricted:
            locationError = "دسترسی به موقعیت مکانی محدود شده است."

        @unknown default:
            locationError = "وضعیت مجوز موقعیت مکانی مشخص نیست."
        }
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        switch manager.authorizationStatus {

        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

        case .denied:
            locationError = "دسترسی به موقعیت مکانی رد شده است."

        case .restricted:
            locationError = "دسترسی به موقعیت مکانی محدود شده است."

        case .notDetermined:
            break

        @unknown default:
            locationError = "وضعیت مجوز موقعیت مکانی مشخص نیست."
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.last else {
            return
        }

        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        lastLocationUpdate = Date()
        locationError = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        locationError = error.localizedDescription
    }

    var mapLink: String? {

        guard let latitude, let longitude else {
            return nil
        }

        return "https://maps.google.com/?q=\(latitude),\(longitude)"
    }
}

