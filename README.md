# DisplayDimmer

A lightweight macOS menu bar utility for dimming external displays beyond their comfortable minimum brightness.

## Features

- Detects connected external displays
- Software-based display dimming
- Adjustable brightness directly from the menu bar
- Remembers your preferred brightness level
- Automatically reapplies dimming after wake or display reconnection
- Launch at Login support
- Quick reset to the original display state
- Native macOS app built with Swift and SwiftUI

## Privacy & Security

DisplayDimmer is designed to be minimal and privacy-focused.

- No internet connection
- No analytics or telemetry
- No account required
- No file access
- No camera or microphone access
- Runs inside the macOS App Sandbox
- No administrator privileges required

## How It Works

DisplayDimmer uses macOS display gamma tables to reduce the visible output of external displays.

This allows displays to appear darker than their normal minimum brightness setting.

> Note: DisplayDimmer performs software dimming. It does not reduce the monitor's physical backlight below its hardware minimum.

## Requirements

- macOS
- At least one external display

## Built With

- Swift
- SwiftUI
- AppKit
- CoreGraphics
- ServiceManagement

## Status

DisplayDimmer is currently in active development.

## License

A license will be added before the first public release.
