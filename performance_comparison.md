# Architectural & Performance Analysis: KITO vs. Focus Fox

This document compares the architecture of **KITO** (Kotlin Multiplatform) and **Focus Fox** (Flutter) to understand why KITO works extremely fast under low-bandwidth networks, and defines a roadmap to implement these optimizations in Focus Fox.

---

## 📊 Summary of Architectural Differences

| Feature | 📱 KITO (Kotlin Multiplatform) | 🦊 Focus Fox (Flutter) |
| :--- | :--- | :--- |
| **Data Architecture** | **Offline-First** (Room DB Caching) | **Online-First** (Network-First) |
| **Database Library** | Room Database (SQLite) | None (Only `shared_preferences` for settings) |
| **UI Data Loading** | Instant (Reads from local Kotlin Flows) | Delayed (Waits on Supabase network responses) |
| **Sync Strategy** | Background sync on startup + lazy database writes | Direct query during screen transition |
| **Supabase Integration** | Direct raw HTTP via lightweight **Ktor Client** | Heavyweight **`supabase_flutter` SDK** |
| **Query Complexity** | Single-table queries + simple joins synced locally | Multi-step queries and potential N+1 fallbacks |

---

## 🔍 Detailed Analysis

### 1. Offline-First Caching (The Core Secret)
* **KITO:** 
  In KITO, files like `HomeViewModel.kt` never query Supabase to render the UI on launch. Instead, the UI subscribes directly to reactive streams (`Flow`) from a local Room database (`attendance`, `schedule`). On app startup, a background coroutine (`AppSyncUseCase.syncAll`) pulls fresh data from Supabase and writes it to Room in a transaction. When the write succeeds, the local Flow emits the new data and the UI updates in-place. If the user has a poor connection, they see their existing schedule immediately.
* **Focus Fox:**
  In Focus Fox, providers like `branchesProvider`, `yearsProvider`, and `subjectsProvider` are `FutureProvider`s that fetch data directly from the network on demand. If the network is slow, the screen displays a loading spinner. If it times out, it displays an error.

### 2. Raw REST Calls vs. Full SDK Client
* **KITO:**
  KITO uses **Ktor Client** directly with custom interceptors to hit the Supabase REST/Postgrest endpoints (e.g. `rest/v1/students`). By avoiding the official SDK, it eliminates massive dependency overhead, connection pooling, and heavy SDK initialization routines. Payloads are minimal JSON arrays.
* **Focus Fox:**
  Focus Fox utilizes the `supabase_flutter` package. While highly convenient for auth and realtime, it carries heavier client-side code and performs complex network handshakes on initialization.

### 3. Avoiding Network Roundtrips (N+1 Queries)
* **Focus Fox:**
  In `PyqRepository`, if the RPC `get_topic_pdf_data` fails, it falls back to a legacy sequential query strategy:
  1. Call `getQuestionsByTopic`
  2. For each question, call `getPyqSourcesForQuestion`
  3. For each question, call `getImagesForQuestion`
  
  Under low connectivity, doing multiple sequential HTTP requests causes extreme latency. Even with `Future.wait`, the overhead of multiple concurrent TCP connections on a slow connection can saturate the device's bandwidth.

---

## 🌐 Replacing Ktor: Flutter HTTP Clients & Direct Endpoints

If you want to replicate KITO's lightweight REST queries in Flutter/Dart instead of using the heavy `supabase_flutter` SDK, you have two primary options:

### 1. Dio (`package:dio`) — *Feature-Rich & Closest to Ktor*
**Dio** is the most powerful and popular HTTP client for Dart/Flutter. It is the best equivalent to Ktor because it supports:
* **Interceptors:** Great for automatically adding your Supabase API keys and authorization headers to every request.
* **Global Configurations:** Configure timeouts and base URLs globally.
* **Caching & Retries:** Easily extensible with interceptors for request retries and cache controls.

### 2. HTTP (`package:http`) — *Lightweight & Simple*
Dart's official **http** package is already loaded in your `pubspec.yaml` (dependency: `http: ^1.2.0`). It is simple, tiny, and fast.

### 💻 Implementation Example (Direct Supabase REST Calls)
Supabase automatically generates a RESTful API for all your tables via **Postgrest**. You can query it directly using HTTP clients:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseRestClient {
  final String _baseUrl = dotenv.env['SUPABASE_URL']!;
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  // Raw HTTP GET request (equivalent to Kito's student check)
  Future<List<dynamic>> getBranches() async {
    final url = Uri.parse('$_baseUrl/rest/v1/branches?select=*');
    
    final response = await http.get(
      url,
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load branches: ${response.body}');
    }
  }

  // Example of querying with a filter (equivalent to: .eq('semester', 2))
  Future<List<dynamic>> getSubjects({required String branchId, required int semester}) async {
    // Postgrest query parameters: key=eq.value
    final url = Uri.parse(
      '$_baseUrl/rest/v1/branch_subjects'
      '?branch_id=eq.$branchId'
      '&semester=eq.$semester'
      '&select=subjects(id,name,code)'
    );

    final response = await http.get(
      url,
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load subjects: ${response.body}');
    }
  }
}
```

---

## 🛠️ Actionable Roadmap for Focus Fox

To make Focus Fox load instantly and function seamlessly in low-connectivity/offline scenarios, we recommend the following changes:

### Phase 1: Integrate a Local SQLite / NoSQL Cache
Introduce a fast, lightweight local storage solution. **Isar** or **Hive** are excellent NoSQL choices for Flutter, while **Sqflite** offers SQLite support. 
* **Recommendation:** Use **Isar** (highly performant object database) or **Hive** for fast document caching.
* **Implementation:**
  Create models for local cache corresponding to:
  * `Branch`
  * `Year`
  * `Subject`
  * `Topic`

### Phase 2: Implement a Cache-Aside (Stale-While-Revalidate) Repository Pattern
Rewrite your repositories to return cached values immediately, while triggering a background sync:

```dart
class SubjectsRepository {
  final SupabaseClient _supabase;
  final LocalDatabase _localDb; // Isar / Hive / Sqflite

  // Returns a stream of local data + executes network update in background
  Stream<List<Subject>> watchSubjects({required String branchId, required int semester}) async* {
    // 1. Yield local database contents immediately
    yield await _localDb.getSubjects(branchId, semester);

    try {
      // 2. Fetch fresh data from Supabase
      final freshSubjects = await _fetchSubjectsFromNetwork(branchId, semester);

      // 3. Update the local database
      await _localDb.saveSubjects(freshSubjects);

      // 4. Yield the fresh data (if local database doesn't auto-emit)
      yield freshSubjects;
    } catch (e) {
      // Log error silently, keeping local cached data visible to user
      log("Background sync failed: $e");
    }
  }
}
```

### Phase 3: Move to Raw REST Endpoints (Dio / HTTP)
Swap out the official `supabase_flutter` SDK database queries with direct REST requests (using **Dio** with interceptors, or package **http**):
* Build a `SupabaseRestClient` class or setup a Dio provider (`supabaseRestProvider`) configured with base URLs and default headers.
* Set up global timeouts (e.g. 5–10 seconds) on Dio request configuration, allowing fast fallback responses when connectivity fails instead of hanging indefinitely.
* Write custom interceptors that auto-inject the `apikey` and `Bearer <token>` headers on every outgoing call.

### Phase 4: Optimizing Network Payloads & Requests
1. **Never Fall Back to N+1 Queries:**
   Remove sequential queries or replace them with unified RPCs that return all questions, images, and sources in a single payload. If the RPC fails, fail immediately or display a cached version instead of executing multiple requests.
2. **Compress Cache Storage:**
   Only fetch the columns you actually need. Focus Fox currently queries `'*'` or broad selects like `'subjects(id, name, code, ...)'`. Optimize the query select strings to retrieve only the required identifiers.
