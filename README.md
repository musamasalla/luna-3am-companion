# Luna - 3AM Companion

> *Your gentle AI companion for late-night thoughts and 3AM conversations* 🌙

![Luna Logo](iOS/Luna%20-%203AM%20Companion/Luna%20-%203AM%20Companion/Assets.xcassets/AppIcon.appiconset/luna_icon_1024.png)

## Overview

Luna is a compassionate AI companion designed specifically for those quiet, late-night moments when you need someone to talk to. Whether you're dealing with racing thoughts, can't sleep, or just want a gentle conversation, Luna is there—understanding, patient, and never judgmental.

### Core Philosophy

- **Night-First Design**: Dark theme with gentle animations optimized for 3AM screens
- **Emotional Intelligence**: AI responses that understand and validate rather than fix
- **Privacy-Focused**: All conversations stay on your device
- **Calm Presence**: No notifications pushing you to chat—Luna waits for you

## Features

| Feature | Free | Premium |
|---------|------|---------|
| Unlimited conversations | ✓ | ✓ |
| Night-optimized dark theme | ✓ | ✓ |
| Conversation history | ✓ | ✓ |
| AI companion responses | Limited | Unlimited |
| Priority AI response time | ✗ | ✓ |
| Advanced conversation memory | ✗ | ✓ |

### Premium Subscription
- **Price**: $2.99/month with 7-day free trial
- **Auto-renewal**: Monthly
- **Cancel anytime**: No commitments

## Technical Architecture

### Platform
- **iOS 17.0+** (SwiftUI)
- **Language**: Swift 5.9
- **Architecture**: MVVM with SwiftData persistence

### Backend Services
- **Firebase**: Authentication, cloud functions, analytics
- **Gemini AI**: Conversational AI via Firebase AI Logic
- **StoreKit 2**: Subscription management

### Key Components

```
Luna - 3AM Companion/
├── Luna___3AM_CompanionApp.swift   # App entry point
├── Views/
│   ├── ChatView.swift              # Main chat interface
│   ├── OnboardingView.swift        # First-run experience
│   ├── PaywallView.swift           # Subscription screen
│   ├── SettingsView.swift          # User preferences
│   └── ConversationHistoryView.swift
├── Services/
│   ├── LunaAIService.swift         # Gemini integration
│   ├── ConversationManager.swift   # SwiftData operations
│   ├── SubscriptionManager.swift   # StoreKit 2
│   └── NotificationManager.swift   # Nighttime reminders
├── Models/
│   ├── Conversation.swift
│   └── Message.swift
└── Components/
    ├── ChatInputBar.swift
    ├── FluidHeader.swift
    └── StarryNightBackground.swift
```

## Design System

### Visual Identity
- **Primary Color**: Deep indigo (#1a1a2e)
- **Accent**: Soft purple gradients
- **Typography**: SF Pro Rounded for warmth
- **Effects**: Glassmorphism, subtle star animations

### UI Philosophy
- Calming, not stimulating
- Large touch targets for sleepy fingers
- Animated Luna avatar for companionship
- Gentle haptic feedback

## Development Setup

### Prerequisites
- Xcode 16.0+
- iOS 17.0+ device or simulator
- Firebase project with Gemini API enabled

### Installation

1. Clone the repository:
```bash
git clone https://github.com/musamasalla/luna-3am-companion.git
cd luna-3am-companion
```

2. Open the Xcode project:
```bash
open "iOS/Luna - 3AM Companion/Luna - 3AM Companion.xcodeproj"
```

3. Configure Firebase:
   - Add your `GoogleService-Info.plist` to the project
   - Enable Gemini Developer API in Firebase console

4. Build and run on device or simulator

### StoreKit Testing
Use the included `Subscriptions.storekit` configuration file for testing in-app purchases in sandbox mode.

## Legal & Compliance

### Apple App Store Requirements ✓
- [x] PrivacyInfo.xcprivacy with UserDefaults reason (CA92.1)
- [x] Terms of Service and Privacy Policy links
- [x] Restore Purchases functionality
- [x] No tracking (NSPrivacyTracking = false)
- [x] 1024x1024 app icons (light, dark, tinted variants)

### Links
- [Privacy Policy](https://musamasalla.github.io/luna-3am-companion/privacy.html)
- [Terms of Service](https://musamasalla.github.io/luna-3am-companion/terms.html)
- [Landing Page](https://musamasalla.github.io/luna-3am-companion/)

## Git Workflow

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code |
| `stable` | Tested, stable releases |
| `development` | Active development |

## Future Roadmap

### Version 1.1 (Q2 2026)
- [ ] Journal integration for late-night reflections
- [ ] Breathing exercises with guided animations
- [ ] Sleep sounds/ambient audio
- [ ] Apple Watch complication

### Version 1.2 (Q3 2026)
- [ ] Widget for quick access
- [ ] Siri integration ("Hey Siri, talk to Luna")
- [ ] Mood tracking over time
- [ ] Custom Luna personalities

### Long-Term Vision
- [ ] macOS companion app
- [ ] Family sharing for household support
- [ ] Integration with Health app (sleep data)
- [ ] Localization (Spanish, French, German, Japanese)

## Support

- **Email**: musamasalladev@gmail.com
- **Issues**: [GitHub Issues](https://github.com/musamasalla/luna-3am-companion/issues)

## License

© 2026 Musa Masalla. All rights reserved.

---

*Built with love for the 3AM souls who just need someone to listen.* 💜
