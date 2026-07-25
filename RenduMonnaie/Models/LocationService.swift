//
//  LocationService.swift
//  Comptoir de change
//
//  Position ponctuelle relevée au moment d'enregistrer un achat, pour pouvoir
//  la retrouver ensuite sur une carte dans le journal de voyage.
//

import CoreLocation
import Observation

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Position actuelle, si l'utilisateur a autorisé la localisation — `nil` après
    /// quelques secondes si aucune position n'a pu être obtenue à temps (refus,
    /// position indisponible…), pour ne jamais bloquer l'enregistrement d'un achat.
    func currentLocation() async -> CLLocation? {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return nil
        }

        return await withTaskGroup(of: CLLocation?.self) { group in
            group.addTask { await self.requestLocation() }
            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    private func requestLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    /// Nom de lieu lisible (ville, pays) pour des coordonnées données — `nil` si le
    /// service de géocodage échoue ou ne répond pas assez vite.
    func placeName(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
                return [placemark?.locality, placemark?.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                    .nilIfEmpty
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(8))
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(returning: nil)
            continuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
        }
    }
}
