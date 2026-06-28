# Luna Development Changelog
七七七米特
## Version 1.1.0 (June 2026) - Stability & Performance

### Stability Fixes
- **LunaAIService**: Removed `@MainActor` to prevent UI freezing during AI calls. AI responses now render without blocking the main thread
- **EdgeTTSAPIService**: Fixed critical double-resume crash in voice playback. Added thread-safe `resumeContinuation()` guard to prevent race conditions when stopping audio
- **SpeechService**: Fixed memory leak in speech recognition. `stopListening()` now properly cancels `recognitionTask` and nils `recognitionRequest`, allowing multiple start/stop cycles
- **ChatView**: Replaced silent `try? modelContext.save()` with proper error handling and rollback. Unsaved messages are now deleted and users see an error instead of phantom messages

### Reliability Improvements
- **AmbientSoundService**: Fixed timer re-entrancy in `fadeOutAndStop()`. Replaced recursive `self.stop()` call with inline cleanup to prevent race conditions
- **SubscriptionManager**: Added error handling to `Transaction.updates` listener. Transaction monitoring now survives StoreKit errors

### Cleanup
- Removed dead code: `ContentView.swift` (legacy, replaced by `ChatView`)
- Removed dead code: `Persistence.swift` (legacy Core Data, superseded by SwiftData)

### Build
- **0 errors, 1 pre-existing warning**
- All warnings reduced from 24 to 1 (pre-existing `nonisolated(unsafe)` in StoreKit code)

---

## Version 1.0.0 (February 2026) - Initial Release

### App Foundation
- SwiftUI app with iOS 17.0+ target
- SwiftData for conversation persistence
- Firebase/Gemini AI integration
- StoreKit 2 subscription management

### Features Implemented
- **Chat Interface**: Full conversation flow with Luna
- **Onboarding**: Multi-screen onboarding with video backgrounds
- **Paywall**: Subscription screen with 7-day free trial
- **Settings**: Preferences, legal links, subscription management
- **Conversation History**: View and continue past conversations

### UI/UX
- Dark theme optimized for nighttime use
- Glassmorphism design effects
- Animated Luna avatar (LunaFace.gif)
- StarryNightBackground component
- Fluid header with animated face

### Compliance
- PrivacyInfo.xcprivacy with UserDefaults reason (CA92.1)
- Terms of Service and Privacy Policy pages (GitHub Pages)
- App Tracking Transparency: Not required (no tracking)
- Restore Purchases functionality

### Technical Debt Resolved
- Removed all fatalError() calls
- Fixed force unwrap crashes
- Unified paywall across onboarding and settings

---

## Development Phases

### Phase 1: Foundation ✅
- Project setup and architecture
- Firebase configuration
- Basic UI scaffolding

### Phase 2: Core Features ✅
- Gemini AI integration
- SwiftData models and persistence
- Chat interface

### Phase 3: Monetization ✅
- StoreKit 2 integration
- Subscription paywall
- Premium feature gates

### Phase 4: Polish ✅
- Onboarding flow
- Animations and effects
- App icons (light/dark/tinted)

### Phase 5: Compliance ✅
- Privacy manifest
- Legal pages
- Paywall compliance audit

### Phase 6: Documentation ✅
- README.md
- ASO documentation
- Architecture guide
- Changelog

---

## Known Issues

None currently tracked. Last stability audit: June 2026.

---

## Future Versions

### 1.1.0 (Planned)
- Journal integration
- Breathing exercises
- Sleep sounds

### 1.2.0 (Planned)
- Widget support
- Siri integration
- Mood tracking

---

*Last updated: June 2026*
