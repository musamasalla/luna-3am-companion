# Luna Voice Mode - Architecture & Costs

> How Luna provides high-quality voice conversations at minimal cost

## Architecture

```
┌─────────────────┐                    ┌──────────────────┐                    ┌─────────────────┐
│    Luna iOS     │       HTTPS        │  Railway Server  │     WebSocket      │  Microsoft Edge │
│       App       │  ───────────────▶  │    (Docker)      │  ───────────────▶  │    TTS API      │
│                 │  ◀───────────────  │                  │  ◀───────────────  │    (FREE)       │
└─────────────────┘      MP3 Audio     └──────────────────┘       Audio        └─────────────────┘
```

## Cost Breakdown

| Component | Technology | Cost |
|-----------|------------|------|
| Speech-to-Text | Apple Speech Framework | **FREE** (on-device) |
| AI Response | Firebase Gemini API | **FREE tier** |
| Text-to-Speech | Self-hosted Edge TTS | **$0-5/month** |

**Total: ~$5/month fixed** (or $0 with Render.com)

---

## Why It's Cheap

### 1. Speech-to-Text = $0
Uses Apple's native `SFSpeechRecognizer` which runs **on-device**. No API calls.

### 2. Text-to-Speech = $0-5/month
Instead of expensive per-character APIs:

| Provider | Cost |
|----------|------|
| ElevenLabs | $22+/month |
| OpenAI TTS | $15/1M chars |
| **Our Edge TTS** | **$0-5/month** |

**How?** Microsoft Edge TTS is free for browser users. We run a Docker proxy that uses the same free infrastructure.

### 3. Server Hosting Options

| Platform | Cost | Notes |
|----------|------|-------|
| Railway (current) | ~$5/mo | Always-on |
| Render.com | FREE | 15-min idle |
| Fly.io | FREE | 250 hrs/mo |

---

## iOS Implementation

| File | Purpose |
|------|---------|
| `SpeechService.swift` | Orchestrates STT/TTS with fallback |
| `EdgeTTSAPIService.swift` | Calls Railway server |
| `VoiceChatView.swift` | Voice UI with waveform |

---

## Voice Selection

Using `en-US-AnaNeural`: child-like, warm, expressive - matches Luna's personality.

Full voice list: https://tts.travisvn.com

---

## Server Details

- **Image**: `travisvn/openai-edge-tts:latest`
- **API**: OpenAI-compatible `/v1/audio/speech`
- **URL**: `https://openai-edge-tts-production-c3c6.up.railway.app`
- **Auth**: `luna_tts_key`
