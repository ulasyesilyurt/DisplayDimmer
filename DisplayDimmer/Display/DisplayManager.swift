import AppKit
import CoreGraphics
import Combine

struct DisplayInfo: Identifiable {
    let id: CGDirectDisplayID
    let name: String
    let isBuiltIn: Bool
    let persistentID: String
}

@MainActor
final class DisplayManager: ObservableObject {

    @Published private(set) var displays: [DisplayInfo] = []

    init() {
        refreshDisplays()
    }

    func refreshDisplays() {
        displays = NSScreen.screens.compactMap { screen in

            guard let screenNumber =
                    screen.deviceDescription[
                        NSDeviceDescriptionKey("NSScreenNumber")
                    ] as? NSNumber
            else {
                return nil
            }

            let displayID = CGDirectDisplayID(
                screenNumber.uint32Value
            )

            let vendor = CGDisplayVendorNumber(displayID)
            let model = CGDisplayModelNumber(displayID)
            let serial = CGDisplaySerialNumber(displayID)
            let unit = CGDisplayUnitNumber(displayID)

            let persistentID = "\(vendor)-\(model)-\(serial)-\(unit)"

            return DisplayInfo(
                id: displayID,
                name: screen.localizedName,
                isBuiltIn: CGDisplayIsBuiltin(displayID) != 0,
                persistentID: persistentID
            )
        }
    }
}
