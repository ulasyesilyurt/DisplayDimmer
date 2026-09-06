import CoreGraphics
import Combine

private struct GammaTable {
    let red: [CGGammaValue]
    let green: [CGGammaValue]
    let blue: [CGGammaValue]
}

final class DimmerController: ObservableObject {

    @Published private(set) var status = "Ready"

    private var originals: [CGDirectDisplayID: GammaTable] = [:]

    // Safety limit for software dimming.
    private let minimumBrightness: Double = 0.20

    private func isSafeExternalDisplay(
        _ displayID: CGDirectDisplayID
    ) -> Bool {

        guard CGDisplayIsActive(displayID) != 0 else {
            status = "Display is not active."
            return false
        }

        guard CGDisplayIsBuiltin(displayID) == 0 else {
            status = "Safety block: Built-in display was not modified."
            return false
        }

        return true
    }

    private func captureOriginalGamma(
        for displayID: CGDirectDisplayID
    ) -> Bool {

        if originals[displayID] != nil {
            return true
        }

        let capacity = CGDisplayGammaTableCapacity(displayID)

        guard capacity > 0 else {
            status = "Gamma table is not supported."
            return false
        }

        var red = [CGGammaValue](
            repeating: 0,
            count: Int(capacity)
        )

        var green = [CGGammaValue](
            repeating: 0,
            count: Int(capacity)
        )

        var blue = [CGGammaValue](
            repeating: 0,
            count: Int(capacity)
        )

        var sampleCount: UInt32 = 0

        let result = CGGetDisplayTransferByTable(
            displayID,
            capacity,
            &red,
            &green,
            &blue,
            &sampleCount
        )

        guard result == .success,
              sampleCount > 0
        else {
            status = "Failed to read gamma table: \(result)"
            return false
        }

        red = Array(red.prefix(Int(sampleCount)))
        green = Array(green.prefix(Int(sampleCount)))
        blue = Array(blue.prefix(Int(sampleCount)))

        originals[displayID] = GammaTable(
            red: red,
            green: green,
            blue: blue
        )

        return true
    }

    func setBrightness(
        _ requestedBrightness: Double,
        for displayID: CGDirectDisplayID
    ) {

        guard isSafeExternalDisplay(displayID) else {
            return
        }

        guard captureOriginalGamma(for: displayID),
              let original = originals[displayID]
        else {
            return
        }

        let brightness = min(
            max(requestedBrightness, minimumBrightness),
            1.0
        )

        // Perceptual curve for smoother dimming.
        let perceptualBrightness = pow(brightness, 0.7)
        let factor = CGGammaValue(perceptualBrightness)

        let red = original.red.map {
            min(max($0 * factor, 0), 1)
        }

        let green = original.green.map {
            min(max($0 * factor, 0), 1)
        }

        let blue = original.blue.map {
            min(max($0 * factor, 0), 1)
        }

        let count = UInt32(original.red.count)

        let result = red.withUnsafeBufferPointer { redBuffer in
            green.withUnsafeBufferPointer { greenBuffer in
                blue.withUnsafeBufferPointer { blueBuffer in

                    CGSetDisplayTransferByTable(
                        displayID,
                        count,
                        redBuffer.baseAddress,
                        greenBuffer.baseAddress,
                        blueBuffer.baseAddress
                    )
                }
            }
        }

        if result == .success {
            status = "Software brightness: \(Int(brightness * 100))%"
        } else {
            status = "Failed to apply dimming: \(result)"
        }
    }

    func reset(
        displayID: CGDirectDisplayID
    ) {

        guard isSafeExternalDisplay(displayID) else {
            return
        }

        guard let original = originals[displayID] else {
            status = "No reset needed."
            return
        }

        let count = UInt32(original.red.count)

        let result =
            original.red.withUnsafeBufferPointer { redBuffer in
                original.green.withUnsafeBufferPointer { greenBuffer in
                    original.blue.withUnsafeBufferPointer { blueBuffer in

                        CGSetDisplayTransferByTable(
                            displayID,
                            count,
                            redBuffer.baseAddress,
                            greenBuffer.baseAddress,
                            blueBuffer.baseAddress
                        )
                    }
                }
            }

        if result == .success {
            originals.removeValue(forKey: displayID)
            status = "Display restored."
        } else {
            status = "Failed to reset display: \(result)"
        }
    }

    func resetAll() {
        let ids = Array(originals.keys)

        for id in ids {
            reset(displayID: id)
        }
    }
}
