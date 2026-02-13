# Firebase Setup Guide

Follow these steps to configure Firebase for your Shared Timer App.

## Prerequisites

- Flutter project created ✅
- Firebase account (free tier is sufficient)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `shared-timer-app` (or your choice)
4. Disable Google Analytics (optional for MVP)
5. Click **"Create project"**

## Step 2: Enable Firestore Database

1. In Firebase Console, click **"Firestore Database"** in the left menu
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select a location (choose closest to you)
5. Click **"Enable"**

## Step 3: Register Your Apps

### For Android:

1. In Firebase Console, click the **Android icon** to add an Android app
2. Enter package name: `com.ourtime.shared_timer_app`
3. App nickname: `Shared Timer Android` (optional)
4. Click **"Register app"**
5. **Download `google-services.json`**
6. Place it in: `android/app/google-services.json`

### For iOS:

1. In Firebase Console, click the **iOS icon** to add an iOS app
2. Enter bundle ID: `com.ourtime.sharedTimerApp`
3. App nickname: `Shared Timer iOS` (optional)
4. Click **"Register app"**
5. **Download `GoogleService-Info.plist`**
6. Place it in: `ios/Runner/GoogleService-Info.plist`

## Step 4: Configure Firestore Security Rules

1. In Firebase Console, go to **"Firestore Database"** → **"Rules"**
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Timers collection
    match /timers/{timerId} {
      // Allow anyone to read and write timers (for MVP)
      allow read, write: if true;
      
      // Participants subcollection
      match /participants/{participantId} {
        allow read, write: if true;
      }
      
      // Alarms subcollection
      match /alarms/{alarmId} {
        allow read, write: if true;
      }
    }
  }
}
```

3. Click **"Publish"**

> ⚠️ **Important**: These rules allow anyone to read/write. This is fine for MVP testing, but for production, you should implement proper authentication and authorization.

## Step 5: Verify File Placement

Ensure these files are in the correct locations:

```
shared_timer_app/
├── android/
│   └── app/
│       └── google-services.json  ← Android config
└── ios/
    └── Runner/
        └── GoogleService-Info.plist  ← iOS config
```

## Step 6: Run the App

```bash
cd /Users/johnaudu/Documents/ourtime/shared_timer_app

# For iOS
flutter run -d ios

# For Android  
flutter run -d android
```

## Troubleshooting

### "Firebase not initialized" error
- Ensure config files are in the correct locations
- Run `flutter clean` then `flutter pub get`
- Restart your IDE

### "Permission denied" in Firestore
- Check that security rules are published
- Verify rules match the structure above

### Notifications not working
- Grant notification permissions when prompted
- Test on a physical device (simulators may not support notifications)

## Verify Setup

1. Create a timer in the app
2. Go to Firebase Console → Firestore Database
3. You should see a `timers` collection with your timer document

## Next Steps

Once Firebase is configured:
- Test creating timers
- Test joining timers from multiple devices
- Test alarms and notifications
- Monitor Firestore usage in Firebase Console

---

**Need Help?**
- [Firebase Documentation](https://firebase.google.com/docs/flutter/setup)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
