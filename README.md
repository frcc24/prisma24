# prisma24

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## iOS setup

```
pod update --project-directory=ios/
pod install --project-directory=ios/
```

## Firestore indexes

Before running the app in production, deploy Firestore composite indexes:

```
firebase deploy --only firestore:indexes
```

The index definitions are stored in `firestore.indexes.json`.
Ensure your `firebase.json` references this file:

```json
{
  "firestore": {"indexes": "firestore.indexes.json"}
}
```

