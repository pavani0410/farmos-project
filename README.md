# Farm OS

Farm OS is an AI-powered precision farming platform that helps farmers manage farms, plots, and crop health in one place.

It combines a Flutter frontend, a Spring Boot backend, and a Python sketch digitizer service for plot mapping and detection workflows.

---

## Features

- User authentication (Login & Registration)
- Farm dashboard with farm overview
- Add, edit, and delete farms
- Plot management
- Sketch digitization and plot boundary detection
- AI-powered leaf disease detection workflow
- Notifications and farm activity summary
- Cross-platform support (Web, Android, iOS, Desktop)

---

## Tech Stack

### Frontend
- Flutter
- Dart
- Material 3
- http
- image_picker
- image_picker_web
- shared_preferences
- http_parser

### Backend
- Java 17
- Spring Boot
- Spring Web MVC
- Spring Data JPA
- Jackson
- PostgreSQL
- Lombok

### Sketch Digitizer Service
- Python 3
- FastAPI
- Uvicorn
- OpenCV
- NumPy
- python-multipart

---

## Project Structure

```text
farm-os/
├── farmos/                 # Spring Boot backend
├── farmos_flutter/         # Flutter frontend
├── sketch-service/         # Python sketch digitizer service
└── README.md
```

---

## Prerequisites

Before running the project, install:

- Flutter SDK
- Dart SDK
- Java 17 or later
- Maven
- Python 3.10 or later
- PostgreSQL

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/farm-os.git
cd farm-os
```

---

### 2. Start the Spring Boot Backend

Navigate to the backend directory:

```bash
cd farmos
```

Run the backend:

**Linux/macOS**

```bash
./mvnw spring-boot:run
```

**Windows**

```bash
mvnw.cmd spring-boot:run
```

Ensure that the PostgreSQL database is running and the database configuration is correctly set in the Spring Boot configuration files.

---

### 3. Start the Flutter Application

Navigate to the Flutter project:

```bash
cd ../farmos_flutter
```

Install dependencies:

```bash
flutter pub get
```

Run on Chrome:

```bash
flutter run -d chrome
```

Or run on another connected device:

```bash
flutter run
```

---

### 4. Start the Sketch Digitizer Service

Navigate to the Python service:

```bash
cd ../sketch-service
```

Install the required packages:

```bash
pip install -r requirements.txt
```

Run the FastAPI server:

```bash
uvicorn main:app --reload --port 8000
```

---

## How It Works

- The Flutter application communicates with the Spring Boot backend using HTTP APIs.
- The Spring Boot backend manages users, farms, plots, notifications, and application data.
- The Sketch Digitizer Service processes uploaded survey sketches and extracts plot boundaries using OpenCV.
- The Leaf Disease Detection workflow integrates AI-based disease prediction into the application.

---

## Screens

- Login
- Registration
- Home Dashboard
- Farm Management
- Plot Mapper
- Leaf Disease Detection

---

## API Layer

The Flutter application communicates with backend services using REST APIs over HTTP.

---

## Notes

- Supports Web, Android, iOS, and Desktop platforms.
- PostgreSQL is used for persistent storage.
- The Sketch Digitizer Service is optional but recommended for plot mapping workflows.

---

## License

This project is licensed under the MIT License.
