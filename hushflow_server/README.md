# Hushflow Server

Serverpod backend for the Hushflow email subscription manager.

## Endpoints

| Endpoint | Description |
|----------|-------------|
| `AuthEndpoint` | Gmail OAuth2 authentication flow |
| `EmailEndpoint` | Email CRUD, tracking, and archiving |
| `SummaryEndpoint` | AI-powered email digest generation |
| `CleanupEndpoint` | Batch unsubscribe and cleanup actions |
| `VoiceEndpoint` | Voice command processing and TTS |

## Configuration

### passwords.yaml

Copy the example and configure:

```bash
cp config/passwords.yaml.example config/passwords.yaml
```

Required secrets:
- `database` - PostgreSQL password
- `gmailClientId` - Google OAuth client ID
- `gmailClientSecret` - Google OAuth client secret
- `openaiApiKey` - OpenAI API key (for summaries/TTS)

## Running

```bash
# Start PostgreSQL and Redis
docker compose up --build -d

# Apply database migrations
dart bin/main.dart --apply-migrations

# Run server
dart bin/main.dart
```

## Development

```bash
# Regenerate protocol after model changes
serverpod generate

# Run with hot reload
dart run bin/main.dart

# Run tests
dart test
```

## ML Service

The XGBoost-based priority ranking service runs separately:

```bash
cd ml_service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

## Project Structure

```
hushflow_server/
├── bin/main.dart           # Server entry point
├── config/                 # Environment configs
├── lib/
│   ├── server.dart         # Server setup
│   └── src/
│       ├── endpoints/      # API endpoints
│       ├── generated/      # Serverpod generated code
│       ├── models/         # Protocol definitions
│       ├── services/       # Business logic
│       └── web/            # Webhook handlers
├── migrations/             # Database migrations
└── ml_service/             # Python ML service
```
