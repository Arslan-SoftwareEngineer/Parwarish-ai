# Parwarish.ai

Parwarish.ai is an AI-powered, adaptive learning and behavioral tracking platform designed specifically for autistic children and their parents/therapists. 

This repository contains the full stack of the platform:
* `/parwarish_ai`: The Flutter mobile frontend (Adaptive UI, TTS, STT, Camera integration)
* `/parwarish_backend`: The Python FastAPI backend (Data aggregation, parent routing, and analytics)

## 📱 Frontend Features (Flutter)
* **Adaptive Sensory Dashboard:** UI restructures based on Mild, Moderate, or Severe autism levels.
* **AI-Driven Lessons:** Video lessons that pause for real-time STT (Voice/Breathing) and Camera (Emotion) interaction.
* **Errant Tap Tracking:** Silently logs aimless tapping to Firebase to identify sensory overload or frustration.
* **Bilingual Accessibility:** Instant English/Urdu translation toggle with localized AI voice prompts.

## ⚙️ Backend Architecture (FastAPI)
* Connects to Firebase Firestore via Firebase Admin SDK.
* Handles secure Parent/Child profile linking.
* Aggregates behavioral streak data and struggle flags for the Parent Dashboard.

## 🚀 Getting Started

### 1. Flutter App
Navigate to `/parwarish_ai`, run `flutter pub get`, and launch via `flutter run`. Requires your own `firebase_options.dart`.

### 2. FastAPI Server
Navigate to `/parwarish_backend`, activate the environment (`source venv/bin/activate`), install requirements, and run `uvicorn main:app --reload`. Requires a valid `firebase_credentials.json` service account key.
