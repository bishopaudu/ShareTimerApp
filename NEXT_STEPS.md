# Next Steps to Run Your App

Here is your checklist to get the app running:

## 1. Move the Project (Optional)
If you want to move the project out of the `ourtime` folder as requested, run this command in your terminal:

```bash
mv /Users/johnaudu/Documents/ourtime/shared_timer_app /Users/johnaudu/Documents/
```

This will move the entire `shared_timer_app` folder to your Documents folder.

## 2. Setting up Firebase (Required)
The app needs Firebase to function (for the database).

1.  **Create a Project**: Go to [console.firebase.google.com](https://console.firebase.google.com) and create a new project.
2.  **Enable Database**: 
    *   Go to **Firestore Database** in the left menu.
    *   Click **Create Database**.
    *   Choose **Start in Test Mode** (easiest for now).
    *   Choose a location and create.
3.  **Download Config Files**:
    *   **Android**: click the Android icon in Project Overview. Register package `com.ourtime.shared_timer_app`. Download `google-services.json` and put it in `android/app/`.
    *   **iOS**: click the iOS icon. Register bundle ID `com.ourtime.sharedTimerApp`. Download `GoogleService-Info.plist` and put it in `ios/Runner/`.

*(See `FIREBASE_SETUP.md` in the project folder for detailed screenshots/steps)*

## 3. Run the App
Once you have moved the folder and added the Firebase files:

1.  Open your terminal.
2.  Navigate to the new folder:
    ```bash
    cd /Users/johnaudu/Documents/shared_timer_app
    ```
    *(Or keep using the old path if you didn't move it)*
3.  Get dependencies:
    ```bash
    flutter pub get
    ```
4.  Run on your simulator or device:
    ```bash
    flutter run
    ```
