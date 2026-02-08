# Voice Mode Roadmap

> Future enhancements for Luna's voice experience

## Version Candidates

### v1.0.1 (Quick Wins)

| Feature | Description | Effort |
|---------|-------------|--------|
| **Interrupt support** | Tap to stop Luna mid-sentence | Low |
| **Local TTS fallback** | Use Apple's voice if server is down | Low |
| **Haptic feedback** | Gentle vibrations when Luna responds | Low |

---

### v1.1 (Medium Enhancements)

| Feature | Description | Effort |
|---------|-------------|--------|
| **Voice variety** | Different voices based on mood/time of night | Low |
| **Speed slider** | Let users pick their preferred speech pace | Medium |
| **Voice activity detection** | Auto-stop listening when user stops talking | Medium |
| **Ambient sounds** | Soft rain/white noise during pauses | Medium |
| **Guided breathing** | Voice-led relaxation with audio cues | Medium |
| **Bedtime stories** | Luna tells calming stories to help sleep | Medium |

---

### Future (Premium Features)

| Feature | Description | Effort |
|---------|-------------|--------|
| **Wake word** | "Hey Luna" to start listening | Medium |
| **Streaming TTS** | Start playing audio before full response | High |
| **Lower latency** | Reduce time between speaking and response | Medium |
| **Voice memory** | Luna remembers how you like to talk | High |
| **Emotional detection** | Adjust tone based on user's voice | High |

---

## Implementation Notes

### Interrupt Support
```swift
// Add tap gesture to VoiceChatView that calls:
ttsService.stop()
```

### Local TTS Fallback
```swift
// Use AVSpeechSynthesizer when Edge TTS fails
let utterance = AVSpeechUtterance(string: text)
utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
synthesizer.speak(utterance)
```

### Haptic Feedback
```swift
// When Luna starts speaking:
UIImpactFeedbackGenerator(style: .soft).impactOccurred()
```

---

## Voice Options Reference

| Voice | Description |
|-------|-------------|
| `en-US-AnaNeural` | Child-like, warm (current) |
| `en-US-AriaNeural` | Young adult, expressive |
| `en-US-JennyNeural` | Adult, conversational |
| `en-US-SaraNeural` | Young, friendly |

Full list: https://tts.travisvn.com
