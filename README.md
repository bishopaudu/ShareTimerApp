# ShareTime ⏱️

A beautiful, real-time shared countdown timer app built with Flutter. Create timers, share them with friends, and watch the countdown together in perfect sync!

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## ✨ Features

### 🎯 Core Features
- **Real-time Synchronization**: Timers stay perfectly synced across all devices using NTP time synchronization
- **Easy Sharing**: Share timers with a simple 6-character code
- **Custom Alarms**: Set multiple alarms within a timer to get notified at specific intervals
- **Live Participants**: See who's viewing the timer in real-time with emoji avatars
- **Beautiful UI**: Modern, vibrant design with smooth animations

### 👤 User Experience
- **Personalized Profiles**: Choose your display name and emoji avatar on first launch
- **Smart Notifications**: Get notified when timers end or alarms trigger
- **Offline Support**: View your timers even without internet (sync when reconnected)
- **Cross-Platform**: Works seamlessly on Android and iOS

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.1 or higher)
- Firebase project with Firestore enabled
- Android Studio / Xcode for mobile development

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/sharetime.git
   cd sharetime
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Firestore Database
   - Download and add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 How to Use

1. **First Launch**: Set up your profile with a name and emoji
2. **Create a Timer**: Tap the "+" button and set your timer duration
3. **Share**: Copy the 6-character code and share it with friends
4. **Join**: Enter a share code to join someone else's timer
5. **Add Alarms**: Set custom alarms to get notified at specific intervals
6. **Watch Together**: See everyone's emoji avatars as they join!

## 🏗️ Architecture

ShareTime follows the **MVVM (Model-View-ViewModel)** architecture pattern:

```
lib/
├── models/          # Data models (Timer, Participant, Alarm)
├── views/           # UI screens and widgets
├── viewmodels/      # Business logic and state management
├── services/        # Firebase, Notifications, Time sync
└── utils/           # Constants, validators, helpers
```

### Key Technologies
- **State Management**: Provider
- **Backend**: Firebase Firestore
- **Notifications**: flutter_local_notifications
- **Time Sync**: NTP (Network Time Protocol)
- **UI**: Material Design 3 with custom theming

## 🎨 Design Philosophy

ShareTime is designed to be:
- **Vibrant**: Eye-catching colors and smooth animations
- **Intuitive**: Clear navigation and familiar patterns
- **Responsive**: Smooth performance on all devices
- **Accessible**: Clear typography and good contrast

## 🔧 Configuration

### Firebase Firestore Structure
```
timers/
  {timerId}/
    - title: string
    - durationSeconds: number
    - startTime: timestamp
    - endTime: timestamp
    - status: string
    - creatorId: string
    - shareCode: string
    
    participants/
      {userId}/
        - displayName: string
        - emoji: string
        - joinedAt: timestamp
        - lastSeen: timestamp
    
    alarms/
      {alarmId}/
        - title: string
        - triggerSeconds: number
        - createdBy: string
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Backend powered by [Firebase](https://firebase.google.com/)
- Icons from [Material Design Icons](https://fonts.google.com/icons)
- Fonts from [Google Fonts](https://fonts.google.com/)

## 📧 Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter)

Project Link: [https://github.com/yourusername/sharetime](https://github.com/yourusername/sharetime)

---

Made with ❤️ and Flutter
