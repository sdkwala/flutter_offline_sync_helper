# 📡 offline_sync_helper

[![Pub Version](https://img.shields.io/pub/v/offline_sync_helper.svg?style=for-the-badge)](https://pub.dev/packages/offline_sync_helper)
[![Pub Likes](https://img.shields.io/pub/likes/offline_sync_helper?style=for-the-badge)](https://pub.dev/packages/offline_sync_helper/score)
[![Pub Points](https://img.shields.io/pub/points/offline_sync_helper?style=for-the-badge)](https://pub.dev/packages/offline_sync_helper/score)
[![Pub Popularity](https://img.shields.io/pub/popularity/offline_sync_helper?style=for-the-badge)](https://pub.dev/packages/offline_sync_helper/score)
[![GitHub Stars](https://img.shields.io/github/stars/sdkwala/flutter_offline_sync_helper?style=for-the-badge)](https://github.com/sdkwala/flutter_offline_sync_helper/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/sdkwala/flutter_offline_sync_helper?style=for-the-badge)](https://github.com/sdkwala/flutter_offline_sync_helper/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/sdkwala/flutter_offline_sync_helper?style=for-the-badge)](https://github.com/sdkwala/flutter_offline_sync_helper/issues)
[![License](https://img.shields.io/github/license/sdkwala/flutter_offline_sync_helper?style=for-the-badge)](https://github.com/sdkwala/flutter_offline_sync_helper/blob/main/LICENSE)
![Platform](https://img.shields.io/badge/platform-Flutter-blue?logo=flutter&style=for-the-badge)
![Null Safety](https://img.shields.io/badge/null%20safety-sound-success?style=for-the-badge)

A fully customizable **offline-first sync engine** for Flutter apps.

`offline_sync_helper` simplifies the process of working with local data, tracking changes, and syncing them with a remote backend. It offers built-in support for Hive, Drift, Firebase, and is extensible to any local storage system or API format.

---

## 🧩 Why offline_sync_helper?

Building apps that **work offline** and **sync intelligently** when online is a pain for most developers.

This package provides:
- ✅ Easy offline storage integration
- ✅ Automatic background sync when connectivity is restored
- ✅ Customizable conflict resolution strategies
- ✅ Full control over local/remote adapters and sync flows

---

## 🚀 Features

- 🌐 **Offline-first architecture**
- 🔄 **Automatic sync** on app launch, connectivity change, or manual trigger
- 🧠 **Change tracking** for inserts, updates, deletes
- 🛠️ **Pluggable adapters** for local and remote storage
- 🧩 **Conflict resolution strategies**: client wins, server wins, timestamp, or custom
- 🔒 **Encrypted local storage support** (via Hive)
- 📶 **Connectivity-aware retry mechanism**
- 🧪 **Testable architecture with mock support**
- 🔤 **Arabic & RTL support**

---

## 📦 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  offline_sync_helper: ^1.0.0
  connectivity_plus: ^5.0.2
  hive: ^2.2.3
  http: ^1.2.1
  path_provider: ^2.1.2
```

> You can replace Hive with Drift, Firebase, or other local storage plugins based on your adapter implementation.

---

## 🛠️ Getting Started

### 1. Initialize the Sync Engine

```dart
import 'package:offline_sync_helper/offline_sync_helper.dart';

await OfflineSyncHelper.initialize(
  localAdapter: HiveAdapter<Task>(),
  remoteSyncService: ApiSyncService(),
  conflictResolver: TimestampResolver(),
);
```

### 2. Save Data Locally

```dart
await OfflineSyncHelper.save(
  model: Task(id: 1, name: 'Collect Feedback'),
);
```

The change is stored locally and synced automatically when the device goes online.

---

## 🧱 Architecture Overview

```
+-------------------+
| LocalAdapter      |<------- Hive / Drift / Firebase
+-------------------+
         |
         ▼
+-------------------+           +---------------------+
| SyncManager       |<--------->| RemoteSyncService   |
+-------------------+           +---------------------+
         |
         ▼
+-------------------+
| ConflictResolver  |<--- Custom, Timestamp, Client, Server
+-------------------+
```

---

## 🔌 Adapter Interfaces

### Local Adapter

```dart
abstract class LocalAdapter<T> {
  Future<void> saveLocally(T model);
  Future<List<T>> getPendingChanges();
  Future<void> markAsSynced(List<T> models);
}
```

### Remote Sync Service

```dart
abstract class RemoteSyncService<T> {
  Future<SyncResult> sync(List<T> models);
}
```

---

## ⚔️ Conflict Resolution

Built-in options:
- `ClientWinsResolver` – local data always overwrites remote
- `ServerWinsResolver` – remote data always overwrites local
- `TimestampResolver` – newer data (based on timestamp) wins

Create your own:

```dart
class CustomResolver implements ConflictResolver<Task> {
  @override
  Task resolve(Task local, Task remote) {
    return local.priority > remote.priority ? local : remote;
  }
}
```

---

## 🔁 Sync Triggers

- App launch
- Internet reconnect
- Manual `syncNow()` method
- Periodic background task (coming soon)

---

## 🔒 Secure Local Storage

Hive supports AES encryption. To enable:

```dart
var box = await Hive.openBox(
  'tasks',
  encryptionCipher: HiveAesCipher(my32ByteKey),
);
```

## 🛠 Configuration Options

```dart
OfflineSyncHelperConfig(
  retryPolicy: RetryPolicy.maxAttempts(3),
  batchSize: 20,
  syncInterval: Duration(minutes: 5),
  enableConnectivityWatcher: true,
  autoSyncOnConnectivityChange: true,
);
```

---

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS

---

## 🌐 Internationalization

Supports:
- RTL layouts
- Arabic and multi-language labels
- `intl` package compatibility

---

## 📚 Example Use Cases

| Use Case                 | Description                                                                 |
|--------------------------|-----------------------------------------------------------------------------|
| Field Agent App          | Collect data in remote areas, sync later                                    |
| Delivery Tracker         | Update delivery statuses offline                                            |
| E-Commerce Cart          | Allow cart actions without internet                                         |
| CRM / Lead Tracker       | Sales staff update records offline                                          |

---

📂 Full Example  
For a complete working example with multiple field types, custom themes, and step-by-step forms, check out:  
👉 [Full Example on GitHub](https://github.com/sdkwala/flutter_offline_sync_helper/tree/main/example)


### License
MIT

### Author
sdkwala.com