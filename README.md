# Pulse (Post Reader & Favorites)

A social feed prototype. Posts, people and comments come from [JSONPlaceholder](https://jsonplaceholder.typicode.com); likes, follows, saved posts (with a personal note) and your own posts are stored on the device with Hive.

## Setup

This folder contains `lib/`, `test/` and `pubspec.yaml`. Generate the platform folders once, then fetch packages:

```
flutter create . --project-name post_reader_favorites
flutter pub get
flutter run
```

Android release builds need the internet permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

(macOS builds need the `com.apple.security.network.client` entitlement.)

## Checks

```
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## What it does

- **Feed** – posts from `GET /posts` with author names (`/users`) and comment counts (`/comments`); story-style people row; search over posts and people; pull to refresh; error and retry states.
- **Post details** – opened with `Navigator.pushNamed('/details', arguments: post.toMap())`, read via `ModalRoute.of(context)!.settings.arguments`; loads the post's comments (`GET /posts/{id}/comments`) and sends new ones (`POST /comments`, expects 201).
- **New post** (`/compose`) – `POST /posts` (expects 201). The post is then kept in Hive and shown at the top of your feed, and can be deleted.
- **Likes and saves** – heart and bookmark on every post; saved posts live on the **Saved** tab (`/favorites`) where you can edit a note, delete (icon or swipe) and undo an unsave.
- **Profiles** (`/profile`) – tap any avatar; follow/unfollow people (followed people get a gradient ring); your own profile shows Posts, Liked and Saved counts.
- Light and dark themes follow the system setting.

## Prototype notes

- The signed-in account is JSONPlaceholder user #1 (no real login).
- JSONPlaceholder acknowledges writes with 201 but never stores them, which is why your own posts are kept locally. New comments appear on the open post and in its count for this session only.
- JSONPlaceholder has no images or timestamps. Every other server post shows a deterministic photo from picsum.photos; no timestamps are shown.

## Structure

- `lib/main.dart` – `ensureInitialized`, `Hive.initFlutter`, opens the boxes, then `runApp`
- `lib/app.dart`, `lib/routes.dart`, `lib/theme.dart` – named routes and light/dark `ThemeData`
- `lib/screens/` – home shell, feed, details, compose, saved, profile
- `lib/widgets/` – post card, avatar, image, dialogs, message views
- `lib/services/` – `SocialApi` (HTTP), `FavoritesStore`, `IdSetStore`, `MyPostsStore` (Hive)
- `lib/controllers/feed_controller.dart` – feed state, search, merging server and local posts
- `lib/models/` – `Post`, `FavoritePost`, `User`, `Comment`
