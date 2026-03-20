# NodecastTV

An android app wrapping the [nodecast-tv](https://github.com/technomancer702/nodecast-tv) project.

[nodecast-tv](https://github.com/technomancer702/nodecast-tv) is a web app for viewing IPTV in a browser.

As browser support is limited in Google TV / Android TV, this app is designed to work on a TV, allowing you to navigate the app using a standard TV remote control.

## Latest release

Get [latest release](https://github.com/jackduckworth2/nodecast_tv_android/releases/latest)

## Building it yourself

### Getting Started with flutter

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### Building

```
git clone https://github.com/jackduckworth2/nodecast_tv_android.git
cd nodecast_tv_android
flutter pub get
flutter build apk --debug
```

## Running nodecast

Unless and until these nodecast-tv changes are merged into the main branch, you will have to use the forked version

1.  Docker
    ```
    nodecast-tv:
      build: https://github.com/jackduckworth2/nodecast-tv
    ```

2.  Manual install
    ```
    git clone https://github.com/jackduckworth2/nodecast-tv
    cd nodecast-tv
    npm install
    npm run dev
    ```

## Implementation

1.  Updated nodecast-tv code to [respond to d-pad presses](https://github.com/jackduckworth2/nodecast-tv)

2.  Not done:
    - Settings (it didn't seem worth the effort, when navigating Settings on a TV would be pretty unpleasant) 

3.   Created simple android app with
     - login screen allowing you to enter the nodecast-tv url
     - single WebView component with browser output

4.  Tips
    - hit the __Back__ button if you cant find focus - it should take you back to __Home__
    - hit the __Back__ button when on __Home__ to go back the Connection screen
