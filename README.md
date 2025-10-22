# MessageAI

A modern, cross-platform messaging application built with Flutter and Supabase, featuring real-time messaging, typing indicators, image sharing, and offline support.

## ✨ Features

- 🔐 **Secure Authentication** - Email/password authentication with Supabase
- 💬 **Real-time Messaging** - Instant message delivery with Supabase Realtime
- ⌨️ **Typing Indicators** - See when others are typing with animated indicators
- 📷 **Image Sharing** - Upload and share images in conversations
- 👤 **Profile Pictures** - Custom avatar support with image upload
- 📧 **Add by Email** - Add participants to conversations using email addresses
- 📱 **Offline Support** - Queue messages when offline, auto-sync when back online
- 🎨 **Modern UI** - Burnt orange theme 
- 📖 **Message Previews** - See the last message in each conversation
- ✓ **Read Receipts** - Track message delivery and read status

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Flutter SDK** (3.10.0 or higher)
   - [Download Flutter](https://docs.flutter.dev/get-started/install)
   - Verify installation: `flutter doctor`

2. **Android Studio** (for Android development)
   - [Download Android Studio](https://developer.android.com/studio)
   - Install Android SDK and emulator

3. **Xcode** (for iOS development - macOS only)
   - Install from Mac App Store
   - Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

4. **Git**
   - [Download Git](https://git-scm.com/downloads)

5. **Node.js** (16.x or higher) - for backend
   - [Download Node.js](https://nodejs.org/)

6. **Supabase CLI** (optional, for local development)
   - Install: `npm install -g supabase`

## 🚀 Getting Started

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/MessageAI.git
cd MessageAI
```

### Step 2: Set Up the Backend

#### Option A: Use Supabase Cloud (Recommended for Quick Start)

Create .env in backend folder and add 
   - Project URL (e.g., `https://abcdefghijk.supabase.co`)
   - `anon/public` API key



### Step 3: Configure the Frontend

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Create a configuration file:
   ```bash
   # Create .env.dev.json in the frontend directory
   cat > .env.dev.json << EOF
   {
     "SUPABASE_URL": "https://your-project-id.supabase.co",
     "SUPABASE_ANON_KEY": "your-anon-key-here"
   }
   EOF
   ```

3. Replace the placeholder values with your actual Supabase credentials

4. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

## 📱 Running the App

### Android Emulator Setup

1. **Open Android Studio**
2. Go to **Tools** → **Device Manager**
3. Click **Create Device**
4. Select a device (e.g., Pixel 7) and click **Next**
5. Select a system image (e.g., Android 13) and click **Next**
6. Click **Finish** to create the emulator
7. Click the **Play** button to start the emulator

### iOS Simulator Setup (macOS only)

1. **Open Xcode**
2. Go to **Xcode** → **Open Developer Tool** → **Simulator**
3. The simulator will launch with a default device

### Run the App

1. **Check available devices:**
   ```bash
   flutter devices
   ```

2. **Run the app:**

   **Option A: Without configuration file** (if you hardcoded credentials)
   ```bash
   flutter run
   ```

   **Option B: With configuration file** (recommended)
   ```bash
   flutter run --dart-define-from-file=.env.dev.json
   ```

   **Option C: On a specific device**
   ```bash
   flutter run -d <device-id> --dart-define-from-file=.env.dev.json
   ```

3. **Hot Reload during development:**
   - Press `r` in the terminal to hot reload
   - Press `R` to hot restart
   - Press `q` to quit

### Build for Production

**Android APK:**
```bash
flutter build apk --release --dart-define-from-file=.env.dev.json
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle:**
```bash
flutter build appbundle --release --dart-define-from-file=.env.dev.json
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS (macOS only):**
```bash
cd ios
pod install
cd ..
flutter build ios --release --dart-define-from-file=.env.dev.json
```

## 🔧 Troubleshooting

### Common Issues

#### 1. "SUPABASE_URL not configured" Error

**Solution:** Make sure you created `.env.dev.json` with your Supabase credentials and run with:
```bash
flutter run --dart-define-from-file=.env.dev.json
```

#### 2. Flutter Doctor Issues

**Run:**
```bash
flutter doctor
```

Follow the instructions to fix any issues (Android licenses, Xcode setup, etc.)

#### 3. Android License Not Accepted

**Run:**
```bash
flutter doctor --android-licenses
```
Accept all licenses when prompted.

#### 4. Gradle Build Errors

**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 5. iOS Pod Installation Errors

**Solution:**
```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### 6. Image Picker Not Working

Make sure you have the required permissions in:
- **Android:** `android/app/src/main/AndroidManifest.xml`
- **iOS:** `ios/Runner/Info.plist`

#### 7. Emulator Not Detected

**Android:**
```bash
# List Android Virtual Devices
emulator -list-avds

# Start a specific AVD
emulator -avd <avd-name>
```

**iOS:**
```bash
# List simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot <device-id>
```

## 🏗️ Project Structure

```
MessageAI/
├── backend/
│   ├── supabase/
│   │   ├── functions/         # Edge Functions
│   │   ├── migrations/        # Database migrations
│   │   ├── policies/          # RLS policies
│   │   └── storage/           # Storage bucket configs
│   └── package.json
├── frontend/
│   ├── lib/
│   │   ├── core/              # Core configurations
│   │   ├── data/              # Data layer (Drift, repos)
│   │   ├── features/          # Feature modules
│   │   ├── services/          # Business logic services
│   │   ├── state/             # State management
│   │   ├── app.dart           # Main app widget
│   │   └── main.dart          # Entry point
│   ├── android/               # Android platform code
│   ├── ios/                   # iOS platform code
│   └── pubspec.yaml           # Flutter dependencies
├── .gitignore
└── README.md
```

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management
- **Drift** - Local SQLite database
- **Supabase Flutter** - Backend client
- **Image Picker** - Image selection

### Backend
- **Supabase** - Backend as a Service
  - PostgreSQL database
  - Real-time subscriptions
  - Authentication
  - Storage
  - Edge Functions (Deno)

## 📝 Environment Variables

Create `.env.dev.json` in the `frontend` directory:

```json
{
  "SUPABASE_URL": "https://your-project-id.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

For production, create `.env.prod.json` with production credentials.

## 🧪 Testing

### Run Tests
```bash
cd frontend
flutter test
```

### Run Specific Test
```bash
flutter test test/offline_queue_test.dart
```

### Test Offline Message Queueing

See `frontend/OFFLINE_QUEUE_TEST.md` for detailed testing instructions.

## 📚 Additional Documentation

- **Architecture**: See `docs/Architecture.puml`
- **ERD**: See `docs/ERD.puml`
- **Offline Queueing**: See `frontend/OFFLINE_QUEUE_TEST.md`
- **API Contracts**: See `contracts/openapi.yaml`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter any issues:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review closed issues on GitHub
3. Open a new issue with:
   - Your environment details (`flutter doctor -v`)
   - Steps to reproduce
   - Error messages/screenshots

## 🎨 Color Scheme

- **Primary**: Burnt orange with transparency (`#C77506` at 60% opacity)
- **Secondary**: Same burnt orange
- **Accent**: Slate grey (`#475569`)
- **Background**: Adaptive (light/dark mode)

## 🔮 Roadmap

- [ ] Voice messages
- [ ] Video calls
- [ ] End-to-end encryption
- [ ] Message reactions
- [ ] Group admin controls
- [ ] Message search
- [ ] File sharing (PDFs, documents)
- [ ] Location sharing
- [ ] Desktop apps (Windows, macOS, Linux)

## 👥 Authors

- Your Name - Initial work

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Community contributors

---

Made with ❤️ using Flutter and Supabase

