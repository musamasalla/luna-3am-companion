# Edge TTS Server Integration

Luna uses a self-hosted Edge TTS server for high-quality neural text-to-speech voices.

## Architecture

```
┌─────────────┐       HTTPS        ┌──────────────────┐       WebSocket      ┌─────────────────┐
│  Luna iOS   │  ───────────────▶  │  Railway Server  │  ───────────────▶   │  Microsoft Edge │
│     App     │  ◀───────────────  │  (Docker)        │  ◀───────────────   │    TTS API      │
└─────────────┘       MP3 Audio    └──────────────────┘       Audio         └─────────────────┘
```

## Server Details

- **Image**: `travisvn/openai-edge-tts:latest`
- **Host**: Railway (or any Docker host)
- **API**: OpenAI-compatible `/v1/audio/speech` endpoint
- **Voice**: `en-US-AnaNeural` (child-like, warm, expressive)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `API_KEY` | Required for authentication | `luna_tts_key` |
| `DEFAULT_VOICE` | Default TTS voice | `en-US-AnaNeural` |
| `PORT` | Server port | `5050` |

## iOS Integration

The app uses two services:
1. **`EdgeTTSAPIService.swift`** - Calls the Railway server
2. **`SpeechService.swift`** - Orchestrates TTS with Native fallback

## Deployment Options

### Railway (Current)
- URL: `https://openai-edge-tts-production-c3c6.up.railway.app`
- Cost: Free $5 credit, then ~$5/month

### Render.com (Free Alternative)
- Completely free forever
- 15-min idle timeout (cold starts ~30s)

## API Usage

```bash
curl -X POST https://YOUR-SERVER/v1/audio/speech \
  -H "Authorization: Bearer luna_tts_key" \
  -H "Content-Type: application/json" \
  -d '{"input": "Hello!", "voice": "en-US-AnaNeural"}'
```

## Voice Options

| Voice | Description |
|-------|-------------|
| `en-US-AnaNeural` | Child-like, warm (default) |
| `en-US-AvaNeural` | Adult female, natural |
| `en-US-JennyNeural` | Adult female, professional |
| `en-US-GuyNeural` | Adult male, casual |

Full list: https://tts.travisvn.com
