import Foundation
import Combine

@MainActor
final class BrightnessStore: ObservableObject {

    @Published private var values: [String: Double] = [:]

    private let defaultsKey = "displayBrightnessValues"

    init() {
        load()
    }

    func brightness(for display: DisplayInfo) -> Double {
        let value = values[display.persistentID] ?? 1.0
        return min(max(value, 0.20), 1.0)
    }

    func setBrightness(
        _ brightness: Double,
        for display: DisplayInfo
    ) {
        let safeBrightness = min(
            max(brightness, 0.20),
            1.0
        )

        values[display.persistentID] = safeBrightness
        save()
    }

    func reset(for display: DisplayInfo) {
        values[display.persistentID] = 1.0
        save()
    }

    private func load() {
        guard let stored =
                UserDefaults.standard.dictionary(
                    forKey: defaultsKey
                )
        else {
            return
        }

        values = stored.reduce(into: [:]) { result, item in
            if let number = item.value as? NSNumber {
                result[item.key] = number.doubleValue
            }
        }
    }

    private func save() {
        UserDefaults.standard.set(
            values,
            forKey: defaultsKey
        )
    }
}
