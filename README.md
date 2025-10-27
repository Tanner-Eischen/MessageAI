# MessageAI

A modern, cross-platform messaging application built with Flutter and Supabase, featuring real-time messaging, typing indicators, image sharing, offline support, and AI-powered message analysis.

## ✨ Features

### Core Messaging
- 🔐 **Secure Authentication** - Email/password authentication with Supabase
- 💬 **Real-time Messaging** - Instant message delivery with Supabase Realtime
- 👥 **Smart Conversation Creation** - Guided flow for single or group chats with contact roster selection
- ⌨️ **Typing Indicators** - See when others are typing with animated indicators
- 😊 **Message Reactions** - React to messages with emojis via intuitive long-press menu
- 📷 **Image Sharing** - Upload and share images in conversations
- 👤 **Profile Pictures** - Custom avatar support with image upload
- 📧 **Add by Email** - Add participants to conversations using email addresses
- 📱 **Offline Support** - Queue messages when offline, auto-sync when back online
- 🎨 **Modern UI** - Dark/light mode support with thoughtful design and polished animations
- 📖 **Message Previews** - See the last message in each conversation
- ✓ **Read Receipts** - Track message delivery and read status
- 🔍 **AI Analysis Icons** - Visual indicators for detected RSD triggers, boundary violations, and action items

### 🤖 AI Features

#### Smart Message Interpreter
- **Tone Analysis** - Automatically detect message tone, urgency level, and intent
- **RSD Trigger Detection** - Identify Rejection Sensitive Dysphoria triggers with reassurance and alternative interpretations
- **Boundary Detection** - Recognize boundary violations (time-based, work/personal, communication style) with suggested responses
- **Alternative Interpretations** - See multiple ways to interpret ambiguous messages
- **Anxiety Assessment** - Understand response anxiety levels and mitigation strategies
- **Evidence-Based Analysis** - See exactly what phrases support each analysis
- **Per-Message Analysis** - On-demand RSD and boundary analysis via long-press menu

#### Adaptive Response Assistant (Draft Analysis)
- **Message Feedback** - Get real-time feedback on your drafted messages
- **Confidence Scoring** - See how confident the AI is in its analysis
- **Social Scripts** - Get suggested templates and social scripts for various situations
- **Situation Detection** - Automatically detect message context (declining, boundary-setting, etc.)
- **Formatting Options** - Get suggestions for formatting and rephrasing

#### Smart Action Items & Context
- **Auto-Extraction** - Automatically extract action items from incoming messages in real-time
- **Multi-Action Detection** - Parse multiple distinct tasks from compound messages (e.g., "send X, schedule Y, and update Z")
- **Action Types** - Categorize actions (follow-up, meeting request, task assignment, etc.)
- **Live Context Panel** - Auto-updating conversation context as messages arrive
- **Follow-up Tracking** - Track commitments and pending questions with priority levels

#### Interactive AI Insights Panel
- **Smooth Dragging** - Fluid, momentum-based panel dragging with intelligent snapping
- **Four View Modes** - Hidden, Split (50/50), and Full screen modes
- **Real-time Updates** - Context and Actions panels update automatically as messages arrive
- **On-Demand Analysis** - RSD and Boundary panels analyze specific messages when requested
- **Polished UI** - Beautiful gradients, shadows, and animations throughout

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

7. **OpenAI API Key** (for AI features)
   - Get key from [OpenAI Platform](https://platform.openai.com/api-keys)
   - Set as `OPENAI_API_KEY` environment variable in Supabase

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
   - `OPENAI_API_KEY` - Your OpenAI API key for AI features


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

## 🎯 Using the AI Insights Panel

The interactive AI Insights Panel provides real-time analysis and context for your conversations:

### Panel Modes
- **Hidden** - Panel collapsed, full screen for messages
- **Split** - 50/50 view of messages and AI insights
- **Full** - AI insights take full screen

### Dragging & Navigation
- **Drag Handle** - Pull the top bar up or down to resize the panel
- **Momentum** - Flick quickly to snap to the next mode
- **Smooth Animation** - Panel smoothly animates between positions
- **Always Accessible** - Drag handle visible even when panel is fully extended

### Panel Categories

#### 🟣 RSD (Rejection Sensitive Dysphoria)
- **On-Demand Analysis** - Long-press a message → "Analyze with AI" to check for RSD triggers
- **Alternative Interpretations** - See multiple ways to interpret potentially triggering messages
- **Reassurance** - Get calming perspectives and evidence-based analysis
- **Visual Indicator** - Purple icon appears on messages with detected RSD triggers

#### 🔴 Boundary Violations
- **On-Demand Analysis** - Long-press a message → "Analyze with AI" to check for boundary crossings
- **Violation Types** - Detects time-based (after-hours), work/personal, and communication style boundaries
- **Why It Matters** - Understand the impact of the boundary violation
- **Response Suggestions** - Get appropriate ways to address the boundary
- **Visual Indicator** - Red icon appears on messages with detected boundary violations

#### 🟢 Context
- **Auto-Updates** - Automatically refreshes as new messages arrive
- **Conversation Summary** - Key themes and ongoing topics
- **Relationship Insights** - Important details about your relationship with the sender
- **Safe Topics** - Subjects that have been positive in the past

#### 🟠 Actions
- **Auto-Updates** - Automatically extracts action items from new messages
- **Multi-Action Detection** - Separates compound requests (e.g., "send X, schedule Y, update Z" → 3 items)
- **Action Types** - Categorizes as follow-up, meeting request, task assignment, etc.
- **Priority Levels** - Helps you focus on urgent tasks
- **Visual Indicator** - Orange icon appears on messages with detected action items

### Message Interactions
- **Long-Press** - Opens context menu with Copy, React, Analyze with AI, and Delete options
- **React** - Select from emoji reactions to respond quickly
- **Analysis Icons** - Tap icons to open the relevant AI insights panel

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

### Load Showcase Data

```bash
cd backend
supabase db reset
```

This loads demonstration conversations and messages showcasing all AI features.

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

#### 2. "API key required" Error for AI Features

**Solution:** Ensure `OPENAI_API_KEY` is set in your Supabase Edge Functions environment:
```bash
supabase secrets set OPENAI_API_KEY=your-key-here
```

#### 3. Flutter Doctor Issues

**Run:**
```bash
flutter doctor
```

Follow the instructions to fix any issues (Android licenses, Xcode setup, etc.)

#### 4. Android License Not Accepted

**Run:**
```bash
flutter doctor --android-licenses
```

Accept all licenses when prompted.

#### 5. Gradle Build Errors

**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 6. iOS Pod Installation Errors

**Solution:**
```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### 7. Image Picker Not Working

Make sure you have the required permissions in:
- **Android:** `android/app/src/main/AndroidManifest.xml`
- **iOS:** `ios/Runner/Info.plist`

#### 8. Emulator Not Detected

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
│   │   ├── functions/
│   │   │   ├── _shared/
│   │   │   │   └── prompts/
│   │   │   │       └── commitment-extraction.ts  # AI prompts for action items
│   │   │   ├── extract-commitments/  # Action item extraction
│   │   │   ├── detect-boundaries/    # Boundary violation detection
│   │   │   ├── detect-rsd/          # RSD trigger detection
│   │   │   └── interpret-message/    # Message tone analysis
│   │   ├── migrations/        # Database migrations
│   │   ├── policies/          # RLS policies
│   │   └── seed_showcase_data.sql  # Demo data
│   └── package.json
├── frontend/
│   ├── lib/
│   │   ├── core/              # Core configurations
│   │   ├── data/              # Data layer (Drift, repos)
│   │   ├── features/
│   │   │   ├── conversations/
│   │   │   │   ├── screens/
│   │   │   │   │   └── conversations_list_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── create_conversation_dialog.dart  # NEW: Conversation creation UI
│   │   │   └── messages/
│   │   │       ├── screens/
│   │   │       │   └── messages_screen.dart
│   │   │       └── widgets/
│   │   │           ├── message_bubble.dart      # Enhanced with reactions
│   │   │           └── peek_zone/
│   │   │               ├── dynamic_peek_zone.dart         # Enhanced drag system
│   │   │               └── ai_insights_background.dart    # Auto-updating panels
│   │   ├── services/
│   │   │   ├── contact_service.dart             # NEW: Contact management
│   │   │   ├── conversation_service.dart        # Enhanced with multi-participant
│   │   │   ├── peek_zone_service.dart          # Enhanced RSD/boundary logic
│   │   │   ├── action_item_service.dart
│   │   │   ├── boundary_violation_service.dart
│   │   │   └── realtime_message_service.dart
│   │   ├── state/             # State management
│   │   ├── models/
│   │   │   ├── contact.dart   # NEW: Contact model
│   │   │   └── peek_content.dart
│   │   ├── widgets/
│   │   │   └── user_avatar.dart
│   │   ├── app.dart           # Main app widget
│   │   └── main.dart          # Entry point
│   ├── android/               # Android platform code
│   ├── ios/                   # iOS platform code
│   └── pubspec.yaml           # Flutter dependencies
├── docs/
│   ├── Architecture.puml
│   └── ERD.puml
├── .gitignore
├── BACKEND_INTEGRATION_GUIDE.md
├── QUICK_START.md
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
- **OpenAI GPT-4** - AI analysis and interpretation

## 📝 Environment Variables

Create `.env.dev.json` in the `frontend` directory:

```json
{
  "SUPABASE_URL": "https://your-project-id.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

For backend Edge Functions, set in Supabase:
```bash
supabase secrets set OPENAI_API_KEY=sk-...
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
- **Backend Integration**: See `BACKEND_INTEGRATION_GUIDE.md`
- **Quick Start**: See `QUICK_START.md`

## 🚀 Recent Improvements (v2.0)

### Enhanced AI Insights Panel (January 2024)
- ✨ **Smooth Dragging** - Completely redesigned drag system with momentum-based snapping and fluid animations
- 🎨 **Visual Polish** - Beautiful gradients, improved shadows, larger rounded corners, and professional styling
- 🔄 **Auto-Updating Panels** - Context and Actions panels now refresh automatically as messages arrive
- 📍 **Repositioned Icons** - AI analysis icons now appear closer to their associated messages for better context
- 🎯 **Always Accessible** - Added dedicated drag area at top of panel to ensure it can always be pulled down

### Smarter AI Analysis
- 🧠 **Fixed RSD Detection** - RSD analysis now only triggers when actual RSD patterns are detected, not for all messages
- 🎯 **Multi-Action Extraction** - AI now correctly separates compound requests into individual action items
  - Example: "send report, schedule meeting, update timeline" → 3 separate action items
- 🔄 **New Action Types** - Added support for "update" requests and more nuanced action categorization
- 📊 **Improved Boundary Detection** - Better detection of time-based (after-hours), work/personal, and communication style boundaries

### Conversation & Message Improvements
- 👥 **Smart Conversation Creation** - New guided flow for creating single or group chats with contact roster
- 😊 **Intuitive Reactions** - Moved reactions to long-press menu for cleaner UI
- 📱 **Contact Service** - New contact management system for easy participant selection
- 🎨 **Enhanced Message Bubbles** - Improved styling and better icon positioning

### Backend Enhancements
- 🤖 **Improved AI Prompts** - Enhanced commitment extraction prompts for better multi-action detection
- 🔧 **Better Validation** - Stricter RSD and boundary trigger validation
- 📦 **Updated Edge Functions** - Deployed latest AI analysis improvements

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

## 🎨 Color Scheme & AI Feature Colors

**Core Theme:**
- **Primary**: Burnt orange with transparency (`#C77506` at 60% opacity)
- **Secondary**: Same burnt orange
- **Accent**: Slate grey (`#475569`)
- **Background**: Adaptive (light/dark mode)

**AI Feature Colors:**
- **Smart Message Interpreter**: Purple (`#7C3AED`)
- **Adaptive Response Assistant**: Blue (`#06B6D4`)
- **Smart Inbox Filters**: Indigo (`#6366F1`)
- **RAG Context Panel**: Green (`#22C55E`)

## 🔮 Roadmap

### AI Features (In Progress)
- [x] Smart Message Interpreter with tone analysis
- [x] RSD trigger detection with alternative interpretations
- [x] Boundary violation detection (time-based, work/personal, communication style)
- [x] Multi-action item extraction from compound messages
- [x] Adaptive Response Assistant
- [x] Smart Inbox Filters
- [x] RAG Context Panel with auto-updates
- [x] Interactive AI insights panel with smooth dragging
- [x] Real-time action item and context extraction
- [ ] Voice message analysis
- [ ] Emotion detection from images
- [ ] Personalized suggestion learning
- [ ] AI-powered message search

### Messaging
- [x] Message reactions via long-press
- [x] Smart conversation creation (single/group with contact selection)
- [ ] Voice messages
- [ ] Voice/video calls
- [ ] Message editing
- [ ] Message search
- [ ] File sharing (PDFs, documents)
- [ ] Location sharing
- [ ] Message pinning

### Security & Privacy
- [ ] End-to-end encryption
- [ ] Message disappearing timers
- [ ] Device management
- [ ] Login activity

### Platform & Scale
- [ ] Desktop apps (Windows, macOS, Linux)
- [ ] Web app
- [ ] Message syncing across devices
- [ ] Performance optimization for large conversations

## 👥 Authors

- Your Name - Initial work

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- OpenAI for AI capabilities
- Community contributors

---

Made with ❤️ using Flutter, Supabase, and AI

