# Contributing to Luna

## Getting Started

### Prerequisites
- Xcode 16.0+
- iOS 17.0+ device or simulator
- Firebase project access
- GitHub access to repository

### Setup
1. Clone: `git clone https://github.com/musamasalla/luna-3am-companion.git`
2. Open: `open "iOS/Luna - 3AM Companion/Luna - 3AM Companion.xcodeproj"`
3. Build: ⌘B

## Git Workflow

### Branches
| Branch | Purpose |
|--------|---------|
| `main` | Production-ready, App Store releases |
| `stable` | Tested, ready for QA |
| `development` | Active development |

### Process
1. Create feature branch from `development`
2. Make changes, test locally
3. PR to `development`
4. After testing: PR `development` → `stable`
5. Release: PR `stable` → `main`

### Commit Messages
```
<type>: <description>

Types: feat, fix, docs, style, refactor, test, chore
```

## Code Standards

### SwiftUI
- Use `@State` for view-local state
- Use `@StateObject` for owned objects
- Use `@EnvironmentObject` for shared state

### Naming
- Views: `*View.swift`
- Services: `*Service.swift` or `*Manager.swift`
- Models: No suffix

### Testing
- Test on device for full functionality
- Use `Subscriptions.storekit` for purchase testing

## Questions?

Contact: musamasalladev@gmail.com
