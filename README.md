# Hushflow - Email Subscription Manager

An intelligent email subscription manager that acts as your personal "Gatekeeper" - providing smart summaries, filtering noise, and managing unsubscriptions.

## Features

- 🤖 **AI Summaries** - GPT-powered digest of your newsletters
- 📊 **Smart Ranking** - XGBoost ML model for personalized priority
- 🎧 **Audio Briefings** - Listen to your email summary on the go
- 🗣️ **Voice Control** - Natural language commands
- 🧹 **Cleanup Butler** - Batch unsubscribe from stale senders
- ⚡ **Real-time Sync** - Gmail webhook integration

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter + Riverpod + FlexColorScheme |
| Backend | Serverpod (Dart) |
| Database | PostgreSQL |
| Cache | Redis |
| ML | XGBoost (Python/FastAPI) |
| AI | OpenAI GPT-4 + Vision + TTS |
| Auth | Gmail OAuth2 |

## Project Structure

```
Hushflow/
├── hushflow_server/      # Serverpod backend
├── hushflow_client/      # Generated Dart client
├── hushflow_flutter/     # Flutter mobile/web app
└── .github/              # CI/CD workflows
```

## Getting Started

### Prerequisites

- Dart SDK >= 3.0.0
- Flutter >= 3.10.0
- Docker & Docker Compose
- Python 3.11+ (for ML service)

### Setup

1. **Start backend services:**
   ```bash
   cd hushflow_server
   docker compose up --build -d
   dart bin/main.dart --apply-migrations
   ```

2. **Configure secrets:**
   
   Copy the example file and fill in your values:
   ```bash
   cp hushflow_server/config/passwords.yaml.example hushflow_server/config/passwords.yaml
   ```
   
   Edit `hushflow_server/config/passwords.yaml`:
   ```yaml
   development:
     database: 'your-db-password'
     gmailClientId: your-client-id.apps.googleusercontent.com
     gmailClientSecret: your-client-secret
     openaiApiKey: sk-...
   ```

3. **Run Flutter app:**
   ```bash
   cd hushflow_flutter
   flutter pub get
   flutter run
   ```

### Google Cloud Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable the **Gmail API** (APIs & Services → Library)
4. Configure **OAuth consent screen** (APIs & Services → OAuth consent screen)
5. Create **OAuth 2.0 credentials** (APIs & Services → Credentials → Create Credentials → OAuth client ID)
6. Copy the Client ID and Client Secret to your `passwords.yaml`
7. (Optional) Setup **Pub/Sub** for real-time Gmail webhooks

## Development

```bash
# Generate Serverpod code
cd hushflow_server
serverpod generate

# Run tests
dart test

# Start ML service
cd hushflow_server/ml_service
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  Serverpod      │────▶│  PostgreSQL     │
│  (hushflow_     │     │  (hushflow_     │     │                 │
│   flutter)      │     │   server)       │     └─────────────────┘
└─────────────────┘     └────────┬────────┘
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
            ┌───────────┐ ┌───────────┐ ┌───────────┐
            │  Gmail    │ │  OpenAI   │ │  XGBoost  │
            │  API      │ │  API      │ │  ML Svc   │
            └───────────┘ └───────────┘ └───────────┘
```

## License

MIT
