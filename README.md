# Farm OS

Farm OS is an AI-powered precision farming platform that helps farmers manage farms, plots, and crop health in one place.

It combines a Flutter frontend, a Spring Boot backend, and a Python sketch digitizer service for plot mapping and detection workflows.

## Features

- User authentication (Login & Registration)
- **Sign in with Amazon via AWS Cognito** (OAuth 2.0 / OpenID Connect, alongside traditional username/password login)
- Farm dashboard with farm overview
- Add, edit, and delete farms
- Plot management
- Sketch digitization and plot boundary detection
- AI-powered leaf disease detection workflow
- Notifications and farm activity summary
- Cross-platform support (Web, Android, iOS, Desktop)

## Tech Stack

### Frontend
- Flutter
- Dart
- Material 3
- `http`
- `flutter_appauth` (OAuth 2.0 / OIDC for Cognito Hosted UI)
- `url_launcher`
- `image_picker`
- `image_picker_web`
- `shared_preferences`
- `http_parser`

### Backend
- Java 17
- Spring Boot
- Spring Web MVC
- Spring Data JPA
- Jackson
- PostgreSQL
- Lombok
- `java-jwt` + `jwks-rsa` (Auth0) — validates Cognito-issued JWTs against AWS's public signing keys

### Authentication
- AWS Cognito (User Pool + Hosted UI / Managed Login)
- Amazon as a federated identity provider ("Login with Amazon")
- OAuth 2.0 Authorization Code Grant, no client secret (public mobile client)

### Sketch Digitizer Service
- Python 3
- FastAPI
- Uvicorn
- OpenCV
- NumPy
- python-multipart

## Project Structure

```
farm-os/
├── farmos/                 # Spring Boot backend
├── farmos_flutter/         # Flutter frontend
├── sketch-service/         # Python sketch digitizer service
└── README.md
```

## Prerequisites

Before running the project, install:

- Flutter SDK
- Dart SDK
- Java 17 or later
- Maven
- Python 3.10 or later
- PostgreSQL
- An AWS account with a configured Cognito User Pool (only needed if you want to test the Amazon login flow)

## Setup Instructions

### 1. Clone the Repository

```
git clone https://github.com/your-username/farm-os.git
cd farm-os
```

### 2. Configure local secrets (backend)

Copy the local settings template and fill in your own database password:

```
cd farmos/src/main/resources
copy application-local.properties.example application-local.properties
```

Add your database password to `application-local.properties`:

```properties
spring.datasource.password=<your-db-password>
```

This file is gitignored and never committed — `application.properties` reads the real value from it via Spring's `local` profile, so no secrets live in version control.

### 3. Start the Spring Boot Backend

Navigate to the backend directory:

```
cd farmos
```

Run the backend with the local profile:

Linux/macOS
```
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

Windows
```
mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=local
```

Ensure that the PostgreSQL database is running before starting the backend.

### 4. Start the Flutter Application

Navigate to the Flutter project:

```
cd ../farmos_flutter
```

Install dependencies:

```
flutter pub get
```

Run on Chrome (username/password login only — Amazon login requires a native Android/iOS target):

```
flutter run -d chrome
```

Or run on a connected Android device/emulator (required for testing Amazon login):

```
flutter run
```

**Note:** if testing on a physical device, update `API_BASE_URL` in `lib/api/api_service.dart` (or your `.env`) to your machine's local network IP rather than `localhost`, and ensure the device and machine are on the same network.

### 5. Start the Sketch Digitizer Service

Navigate to the Python service:

```
cd ../sketch-service
```

Install the required packages:

```
pip install -r requirements.txt
```

Run the FastAPI server:

```
uvicorn main:app --reload --port 8000
```

## How It Works

- The Flutter application communicates with the Spring Boot backend using HTTP APIs.
- The Spring Boot backend manages users, farms, plots, notifications, and application data.
- For Amazon login: the Flutter app opens AWS Cognito's Hosted UI via `flutter_appauth`, which federates to Amazon. On success, Cognito issues an ID token, which the app sends to a dedicated backend endpoint (`/api/auth/cognito`). The backend independently verifies the token's signature against Cognito's public JWKS keys, checks the issuer and expiry, then finds or creates a local user record — returning the same response shape as the standard login endpoint so the rest of the app doesn't need to know which method was used.
- Signing out clears both the local app session and the Cognito/Amazon browser session (via Cognito's `/logout` endpoint), and login can force a fresh credential prompt (`prompt=login`) so switching accounts doesn't silently reuse a cached session.
- The Sketch Digitizer Service processes uploaded survey sketches and extracts plot boundaries using OpenCV.
- The Leaf Disease Detection workflow integrates AI-based disease prediction into the application.

## Screens

- Login (username/password + Sign in with Amazon)
- Registration
- Home Dashboard
- Farm Management
- Plot Mapper
- Leaf Disease Detection

## API Layer

The Flutter application communicates with backend services using REST APIs over HTTP.

## Challenges & Learnings

Integrating AWS Cognito's Hosted UI with a native Flutter app surfaced a chain of real-world issues beyond the initial OAuth setup:

- **`flutter_appauth` has no Flutter Web support** — the redirect flow only works on native Android/iOS, which shaped the whole testing strategy (custom URI scheme redirects instead of `localhost`).
- **Android manifest + Gradle configuration** — the OAuth redirect required a `manifestPlaceholders["appAuthRedirectScheme"]` entry, a `compileSdk` bump to satisfy transitive dependency requirements, and removing a conflicting `taskAffinity` override that was silently breaking the redirect handoff between activities.
- **Session handling gaps** — Cognito's `/logout` endpoint only clears Cognito's own session, not Amazon's underlying one; a full "sign out and switch accounts" experience required combining Cognito logout with a `prompt=login` parameter on the next authorization request.
- **Backend-side verification** — rather than trusting the client-reported identity, the backend independently verifies each Cognito ID token's signature against AWS's live JWKS endpoint before creating or matching a local user record.
- **Local dev networking** — testing on a physical device (rather than an emulator) required switching from `10.0.2.2`/`localhost` conventions to the host machine's LAN IP, plus a Windows Firewall rule to allow inbound connections to the backend port.
- **Secrets hygiene** — before pushing to a shared repo, hardcoded database credentials were moved out of version control into a gitignored local properties file, loaded via a Spring profile.

## Notes

- Supports Web, Android, iOS, and Desktop platforms (Amazon login is native-only).
- PostgreSQL is used for persistent storage.
- The Sketch Digitizer Service is optional but recommended for plot mapping workflows.

## License

This project is licensed under the MIT License.