# iOS-activity
iOS activity app to show how CMMotionActivityManager works

The app tracks motion activities (stationary, walking, running, cycling, automotive) with
`CMMotionActivityManager`, saves them and displays them in a list grouped by day with the
date, time, duration and confidence of each activity.

## How background tracking works

The motion coprocessor records activities continuously, even when the app is suspended or
not running, and keeps the last 7 days of history. The app:

- listens to live updates with `startActivityUpdates(to:withHandler:)` while it is in the foreground,
- queries the activities recorded in the background with
  `queryActivityStarting(from:to:to:withHandler:)` every time it becomes active, on pull to refresh
  and from a background app refresh task (`BGAppRefreshTask`),
- saves only activity changes in `Documents/activities.json`.

## Project structure

- `iOSActivity/ActivityRecord.swift` – saved activity model
- `iOSActivity/ActivityLog.swift` – ordered list of activities and merge rules (no duplicates)
- `iOSActivity/ActivityStore.swift` – JSON persistence
- `iOSActivity/ActivityTracker.swift` – `CMMotionActivityManager` wrapper
- `iOSActivity/iOSActivityApp.swift` – app entry point and background refresh task
- `iOSActivity/ContentView.swift` – activity list
- `Info.plist` – background modes (`fetch`) and permitted background task identifier
- `iOSActivityTests` – unit tests

## Requirements

- Xcode 16+
- iOS 17+
- A real device with a motion coprocessor (motion activity is not available in the simulator)

Open `iOSActivity.xcodeproj`, select your development team and run on a device. Accept the
*Motion & Fitness* permission when prompted.

Run the tests with:

```sh
xcodebuild test -project iOSActivity.xcodeproj -scheme iOSActivity -destination 'platform=iOS Simulator,name=iPhone 16'
```
