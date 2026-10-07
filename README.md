# MindScribe

MindScribe is an empathetic, offline-first personal journaling app built with Flutter. It combines a distraction-free writing experience with an AI-powered reflection companion that extracts sentiment, generates summaries, provides actionable takeaways, and prompts deeper self-discovery.

---

## Demo

https://github.com/user-attachments/assets/ae4f16a4-e343-4f60-9bd5-295d96da8b0a


---

## Key Features

- **Rich Journaling**: Capture daily thoughts with mood selectors (Happy, Anxious, Calm, Motivated, Tired), customizable titles, and auto-saving fallback.
- **AI Reflection Engine**: Automatically analyze entries for sentiment, 2-sentence summaries, 3 key takeaways, and personalized follow-up reflection questions.
- **Offline-First & Secure**: All journal entries are stored locally using SQLite (`sqflite`), and API keys are encrypted via `flutter_secure_storage`.
- **Adaptive Theming**: Light, Dark, and System modes with seamless custom splash screens and native launch theme parity.
- **Danger Zone**: Full data wipe capability that securely clears both local database records and secure storage settings.

---

## Architecture & Tech Stack

- **UI & Framework**: Flutter (Material 3), Google Fonts (`Space Grotesk`), SpinKit indicators.
- **State Management**: `flutter_riverpod` (`NotifierProvider` pattern).
- **Local Persistence**: `sqflite` (relational database), `flutter_secure_storage` (encrypted key-value store).
- **Networking**: `dio` HTTP client communicating with OpenAI-compatible endpoints.

---

## Self-Hosted AI Proxy (Docker & ngrok Integration)

MindScribe supports both standard cloud OpenAI APIs and **locally self-hosted OpenAI-compatible LLM proxies** (such as Ollama, LocalAI, Freellmapi or vLLM) exposed securely via **Docker** and **ngrok**.

### Setup Instructions

1. **Host Your Local LLM**: Run your model locally via Docker (e.g., Ollama or LocalAI serving an OpenAI-compatible `/v1/chat/completions` endpoint).
2. **Expose via ngrok**: Tunnel your local proxy port using ngrok:
   ```bash
   ngrok http 11434
   ```
   Copy the generated public HTTPS URL (e.g., `https://xxxx.ngrok-free.app`).
3. **Configure Environment Variables**:
   Create or update the `.env` file at the root of the project:
   ```env
   OPENAI_API_KEY=your_local_or_proxy_token_here
   OPENAI_BASE_URL=https://xxxx.ngrok-free.app/v1
   OPENAI_MODEL=llama3
   ```
4. **App Integration**:
   The `OpenAIService` automatically detects local/proxy endpoints containing `"free"` or ngrok domains, injecting the necessary headers (`ngrok-skip-browser-warning: true`) to bypass browser/client warning interstitial pages and route analysis directly to your local model.

---

## Getting Started

### Prerequisites
- Flutter SDK (`^3.13.4`)
- Dart SDK
- Android Studio / Xcode (for emulator or physical device testing)

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/mindscribe.git
   cd mindscribe
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure `.env`**:
   Add your `.env` file containing your API credentials or local proxy ngrok URL.

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## App Icons & Splash Setup
- **Launcher Icons**: Generated via `flutter_launcher_icons` using `assets/Logo_dark.png`.
- **Splash Screen**: Seamless native launch screens backed by `values-night` resources and `Logo_splashscreen_light.png` / `Logo_splashscreen_dark.png`.

---