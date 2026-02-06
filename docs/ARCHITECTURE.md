# Luna iOS Architecture Guide

## Overview

Luna follows the MVVM (Model-View-ViewModel) pattern with SwiftData for persistence and SwiftUI for the UI layer.

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI                             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐ │
│  │ ChatView│  │Settings │  │Onboard  │  │ConversationHist │ │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────────┬────────┘ │
└───────┼────────────┼────────────┼────────────────┼──────────┘
        │            │            │                │
        ▼            ▼            ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Service Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐ │
│  │LunaAIService │  │Subscription  │  │ConversationManager │ │
│  │  (Gemini)    │  │Manager       │  │   (SwiftData)      │ │
│  └──────────────┘  └──────────────┘  └────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────────┐
│  Firebase    │    │   StoreKit   │    │    SwiftData     │
│  Gemini API  │    │      2       │    │   ModelContext   │
└──────────────┘    └──────────────┘    └──────────────────┘
```

## Data Flow

### Chat Message Flow
```
User Input → ChatView → LunaAIService → Gemini API
                 ↓                           ↓
    ConversationManager ← AI Response Processing
                 ↓
          SwiftData (persist)
                 ↓
         ChatView (update UI)
```

### Subscription Flow
```
PaywallView → SubscriptionManager → StoreKit 2
      ↓                                  ↓
   Purchase/Restore        ← Transaction Verification
      ↓
   @AppStorage (isPremium)
      ↓
   Feature Gates Throughout App
```

## Key Files

### Entry Point
- **`Luna___3AM_CompanionApp.swift`**: App lifecycle, model container, onboarding state

### Views
| File | Purpose |
|------|---------|
| `ChatView.swift` | Main conversation interface |
| `OnboardingView.swift` | First-run experience with paywall |
| `PaywallView.swift` | Subscription screen |
| `SettingsView.swift` | User preferences |
| `ConversationHistoryView.swift` | Past conversations list |
| `MainTabView.swift` | Tab bar navigation |

### Services
| File | Purpose |
|------|---------|
| `LunaAIService.swift` | Gemini AI integration with fallback responses |
| `ConversationManager.swift` | SwiftData CRUD operations |
| `SubscriptionManager.swift` | StoreKit 2 purchases and restoration |
| `NotificationManager.swift` | Nighttime reminder scheduling |
| `Config.swift` | App-wide constants and URLs |

### Models
| File | Purpose |
|------|---------|
| `Conversation.swift` | SwiftData model for chat sessions |
| `Message.swift` | SwiftData model for individual messages |

### Components
| File | Purpose |
|------|---------|
| `ChatInputBar.swift` | Text input with send button |
| `FluidHeader.swift` | Animated header with Luna avatar |
| `StarryNightBackground.swift` | Animated star particles |
| `MessageBubble.swift` | Chat bubble styling |

## State Management

### @AppStorage (UserDefaults)
```swift
@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
@AppStorage("isPremium") var isPremium = false
@AppStorage("notificationsEnabled") var notificationsEnabled = true
```

### @StateObject (View Lifecycle)
```swift
@StateObject private var subscriptionManager = SubscriptionManager()
@StateObject private var conversationManager: ConversationManager
```

### @State (Local View State)
```swift
@State private var messageText = ""
@State private var isLoading = false
```

## SwiftData Models

### Conversation
```swift
@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var messages: [Message]
}
```

### Message
```swift
@Model
final class Message {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var conversation: Conversation?
}
```

## AI Integration

### Gemini Configuration
```swift
let generativeModel = FirebaseAI.firebaseAI().generativeModel(
    modelName: "gemini-2.0-flash"
)

let config = GenerationConfig(
    temperature: 0.7,
    maxOutputTokens: 256
)
```

### System Prompt
Luna's personality is defined by a system prompt emphasizing:
- Gentle, understanding tone
- No medical advice (defer to professionals)
- Focus on presence, not problem-solving
- Night-aware responses

### Fallback Responses
If Gemini is unavailable, the app provides pre-written compassionate responses stored in `LunaAIService.fallbackResponses`.

## Subscription Architecture

### Product IDs
```swift
static let monthlyProductId = "com.musamasalla.luna.premium.monthly"
```

### Transaction Verification
```swift
case .success(let verification):
    switch verification {
    case .verified(let transaction):
        await transaction.finish()
        updatePremiumStatus(to: true)
    case .unverified:
        throw StoreError.failedVerification
    }
```

## Error Handling

- **Network Errors**: Show user-friendly message, use fallback AI responses
- **StoreKit Errors**: Display specific error, allow retry
- **SwiftData Errors**: Log internally, maintain graceful degradation

## Testing

### StoreKit Testing
1. Use `Subscriptions.storekit` configuration
2. Edit scheme → Run → Use StoreKit Configuration File
3. Test sandbox purchases without real payments

### Simulator Limitations
- Push notifications require device
- StoreKit works in simulator with .storekit file

---

*Last updated: February 2026*
