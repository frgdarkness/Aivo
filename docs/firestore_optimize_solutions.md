# 🔧 Giải pháp tối ưu Firestore Reads cho Explore

> Ngày tạo: 2026-03-18
> Mục tiêu: Giảm chi phí Firestore reads khi user mở Explore tab

---

## 📌 Tình trạng hiện tại

### Mỗi lần mở Explore (cache miss):
```
fetchHottestSongs(limit: 10)  →  10 reads
fetchNewSongs(limit: 50)      →  50 reads
─────────────────────────────────────────
Tổng                          =  60 reads / user / lần
```

### Với 1,000 DAU, mỗi user mở app 2 lần/ngày:
```
60 reads × 1,000 users × 2 lần = 120,000 reads/ngày
Free tier Firestore = 50,000 reads/ngày
→ VƯỢT free tier ngay lập tức
```

---

## 🔴 Solution 1: Xoá debug code (ĐÃ HOÀN THÀNH ✅)

**File:** `FirestoreService.swift` dòng 206-213

Đoạn debug `allDocsS` đã được comment out, tiết kiệm 5 reads/lần fetch.

---

## 🔴 Solution 2: Thêm `.limit()` cho `fetchWeeklyBoardHistory()`

**File:** `FirestoreService.swift`

### Trước:
```swift
let query = db.collection(leaderboardsCollection)
    .order(by: "timestamp", descending: true)
    // KHÔNG CÓ LIMIT → đọc TẤT CẢ leaderboard docs
```

### Sau:
```swift
let query = db.collection(leaderboardsCollection)
    .order(by: "timestamp", descending: true)
    .limit(to: 12) // Chỉ hiển thị 12 tuần gần nhất
```

**Tác động:** Sau 1 năm, giảm từ 52 reads → 12 reads mỗi lần mở history.

---

## 🟡 Solution 3: Giảm `fetchNewSongs` từ 50 → 30

**File:** `ExploreTabViewNew.swift` dòng 185

### Trước:
```swift
let newest = try await FirestoreService.shared.fetchNewSongs(limit: 50)
```

### Sau:
```swift
let newest = try await FirestoreService.shared.fetchNewSongs(limit: 30)
```

**Lý do:** 50 bài khá nhiều, 30 bài đủ cho genre filter (mỗi genre chỉ match 3-5 bài). Giảm 20 reads/lần fetch.

---

## 🟡 Solution 4: Tăng cache time từ 12h → 24h

**File:** `ExploreTabViewNew.swift` dòng 167

### Trước:
```swift
let expirationTime: TimeInterval = 12 * 60 * 60 // 12 hours
```

### Sau:
```swift
let expirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
```

**Lý do:** Community songs không thay đổi quá nhanh. Với 24h cache + force reload button, user vẫn có thể refresh khi cần.

---

## 🟢 Solution 5: Cloud Function tổng hợp 1 doc `community_feed` ⭐ KHUYẾN NGHỊ

### Ý tưởng
Thay vì mỗi client tự query 60 docs từ Firestore, tạo **1 Cloud Function** chạy định kỳ (mỗi 30 phút) để tổng hợp community songs vào **1 document duy nhất**. Client chỉ cần đọc **1 document** = **1 read**.

### Cấu trúc document

**Collection:** `app_cache`
**Document ID:** `community_feed`

```json
{
  "lastUpdated": 1710770400,
  "hottest": [
    {
      "id": "song_abc123",
      "title": "My Love Song",
      "audioUrl": "https://...",
      "imageUrl": "https://...",
      "tags": "pop, love",
      "modelName": "chirp-v4",
      "username": "musiclover",
      "playCount": 150,
      "createTime": 1710720000,
      "duration": 180.5,
      "weekTag": "2026-w12",
      "isPublic": true,
      "profileID": "profile_xyz"
    }
    // ... 10 bài hottest
  ],
  "newest": [
    // ... 30 bài newest
  ]
}
```

> ⚠️ Firestore document size limit = 1 MB.
> 1 bài ≈ 500 bytes → 40 bài ≈ 20 KB → **rất an toàn**.

### Cloud Function code

```javascript
// Chạy mỗi 30 phút
exports.updateCommunityFeed = onSchedule("every 30 minutes", async (event) => {
    const db = admin.firestore();
    
    // 1. Lấy hottest songs tuần này
    const currentWeek = getCurrentWeekTag();
    const hottestSnap = await db.collection("shared_songs")
        .where("isPublic", "==", true)
        .where("weekTag", "==", currentWeek)
        .orderBy("playCount", "desc")
        .limit(10)
        .get();
    
    const hottest = hottestSnap.docs.map(doc => {
        const data = doc.data();
        // Convert Timestamps to epoch seconds
        if (data.createTime && data.createTime._seconds) {
            data.createTime = data.createTime._seconds;
        }
        return data;
    });
    
    // 2. Lấy newest songs
    const newestSnap = await db.collection("shared_songs")
        .where("isPublic", "==", true)
        .orderBy("createTime", "desc")
        .limit(30)
        .get();
    
    const newest = newestSnap.docs.map(doc => {
        const data = doc.data();
        if (data.createTime && data.createTime._seconds) {
            data.createTime = data.createTime._seconds;
        }
        return data;
    });
    
    // 3. Ghi vào 1 document duy nhất
    await db.collection("app_cache").doc("community_feed").set({
        lastUpdated: Math.floor(Date.now() / 1000),
        hottest: hottest,
        newest: newest
    });
    
    console.log(`✅ Community feed updated: ${hottest.length} hot, ${newest.length} new`);
});

// Force update cho testing
exports.updateCommunityFeedForce = onRequest({ invoker: "public" }, async (req, res) => {
    // ... logic giống trên ...
    res.send("Community feed updated!");
});
```

### iOS Client code thay đổi

**FirestoreService.swift** — thêm hàm mới:
```swift
/// Fetch community feed từ 1 document tổng hợp
func fetchCommunityFeed() async throws -> (hottest: [SunoData], newest: [SunoData]) {
    ensureFirebaseConfigured()
    Logger.d("🔥 Firestore: Fetching community feed (1 read)")
    
    let doc = try await db.collection("app_cache").document("community_feed").getDocument()
    guard doc.exists, let data = doc.data() else {
        Logger.d("🔥 Firestore: No community feed found")
        return ([], [])
    }
    
    var hottest: [SunoData] = []
    var newest: [SunoData] = []
    
    if let hottestArray = data["hottest"] as? [[String: Any]] {
        hottest = hottestArray.compactMap { try? mapToSunoData(data: $0) }
    }
    
    if let newestArray = data["newest"] as? [[String: Any]] {
        newest = newestArray.compactMap { try? mapToSunoData(data: $0) }
    }
    
    Logger.d("✅ Firestore: Community feed loaded: \(hottest.count) hot, \(newest.count) new")
    return (hottest, newest)
}
```

**ExploreTabViewNew.swift** — thay đổi `fetchCommunitySongs`:
```swift
// TRƯỚC: 2 queries = 60 reads
let hottest = try await FirestoreService.shared.fetchHottestSongs(limit: 10)
let newest = try await FirestoreService.shared.fetchNewSongs(limit: 50)

// SAU: 1 query = 1 read
let feed = try await FirestoreService.shared.fetchCommunityFeed()
let hottest = feed.hottest
let newest = feed.newest
```

### So sánh chi phí

| Metric | Hiện tại | Sau tối ưu |
|--------|----------|------------|
| Reads / user / fetch | 60 | **1** |
| 1,000 DAU × 2 lần/ngày | 120,000 | **2,000** |
| Chi phí / ngày | ~$0.07 | **~$0.001** |
| Cloud Function writes | 0 | 48/ngày (rất nhỏ) |

### Ưu điểm
- ✅ Giảm **98% reads** trên client
- ✅ Response nhanh hơn (1 doc vs 2 queries)
- ✅ Không cần composite index
- ✅ Data luôn nhất quán (cùng snapshot time)

### Nhược điểm
- ⚠️ Data delay tối đa 30 phút (chấp nhận được cho community songs)
- ⚠️ Thêm 1 Cloud Function cần maintain
- ⚠️ Cloud Function writes: 48 writes/ngày = không đáng kể

---

## 🟢 Solution 6: Dùng RTDB cho community reads

### Ý tưởng
Thay vì lưu `community_feed` trong Firestore, lưu trong **Realtime Database (RTDB)**. RTDB **không tính theo reads** mà tính theo **bandwidth** (data downloaded). Với 40 bài × 500 bytes ≈ 20 KB, bandwidth rất thấp.

### Cấu trúc RTDB

```
decoraIOS/
├── play_counts/          ← Đã có sẵn (play count tracking)
└── community_feed/       ← MỚI
    ├── lastUpdated: 1710770400
    ├── hottest/
    │   ├── 0/
    │   │   ├── id: "song_abc123"
    │   │   ├── title: "My Love Song"
    │   │   ├── audioUrl: "https://..."
    │   │   ├── imageUrl: "https://..."
    │   │   ├── tags: "pop, love"
    │   │   ├── username: "musiclover"
    │   │   ├── playCount: 150
    │   │   ├── createTime: 1710720000
    │   │   └── duration: 180.5
    │   ├── 1/
    │   │   └── ...
    │   └── ... (10 bài)
    └── newest/
        ├── 0/
        │   └── ...
        └── ... (30 bài)
```

### Cloud Function code

```javascript
// Sync community feed lên RTDB (chạy mỗi 30 phút)
exports.syncCommunityFeedToRTDB = onSchedule("every 30 minutes", async (event) => {
    const db = admin.firestore();
    const rtdb = admin.database();
    
    const currentWeek = getCurrentWeekTag();
    
    // 1. Fetch hottest từ Firestore
    const hottestSnap = await db.collection("shared_songs")
        .where("isPublic", "==", true)
        .where("weekTag", "==", currentWeek)
        .orderBy("playCount", "desc")
        .limit(10)
        .get();
    
    const hottest = hottestSnap.docs.map(doc => {
        const data = doc.data();
        if (data.createTime && data.createTime._seconds) {
            data.createTime = data.createTime._seconds;
        }
        return data;
    });
    
    // 2. Fetch newest từ Firestore
    const newestSnap = await db.collection("shared_songs")
        .where("isPublic", "==", true)
        .orderBy("createTime", "desc")
        .limit(30)
        .get();
    
    const newest = newestSnap.docs.map(doc => {
        const data = doc.data();
        if (data.createTime && data.createTime._seconds) {
            data.createTime = data.createTime._seconds;
        }
        return data;
    });
    
    // 3. Ghi vào RTDB (thay thế toàn bộ node)
    await rtdb.ref("decoraIOS/community_feed").set({
        lastUpdated: Math.floor(Date.now() / 1000),
        hottest: hottest,
        newest: newest
    });
    
    console.log(`✅ RTDB community feed updated: ${hottest.length} hot, ${newest.length} new`);
});
```

### iOS Client code

```swift
import FirebaseDatabase

/// Fetch community feed từ RTDB (0 Firestore reads)
func fetchCommunityFeedFromRTDB() async throws -> (hottest: [SunoData], newest: [SunoData]) {
    let ref = Database.database().reference().child("decoraIOS/community_feed")
    
    let snapshot = try await ref.getData()
    guard let value = snapshot.value as? [String: Any] else {
        Logger.d("📡 RTDB: No community feed found")
        return ([], [])
    }
    
    var hottest: [SunoData] = []
    var newest: [SunoData] = []
    
    if let hottestArray = value["hottest"] as? [[String: Any]] {
        hottest = hottestArray.compactMap { dict in
            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return try? JSONDecoder().decode(SunoData.self, from: jsonData)
        }
    }
    
    if let newestArray = value["newest"] as? [[String: Any]] {
        newest = newestArray.compactMap { dict in
            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return try? JSONDecoder().decode(SunoData.self, from: jsonData)
        }
    }
    
    Logger.d("📡 RTDB: Community feed loaded: \(hottest.count) hot, \(newest.count) new")
    return (hottest, newest)
}
```

### RTDB Pricing vs Firestore Pricing

| Metric | Firestore (hiện tại) | RTDB |
|--------|---------------------|------|
| **Pricing model** | Per read | Per bandwidth |
| **1,000 DAU × 2/ngày** | 120,000 reads | 40 MB bandwidth |
| **Free tier** | 50,000 reads/ngày | 10 GB/tháng |
| **Chi phí nếu vượt** | $0.06/100K reads | $1/GB |
| **1,000 DAU/tháng** | ~$1.26 | **$0.12** |

### Bandwidth tính toán:
```
1 feed ≈ 20 KB (40 bài × ~500 bytes)
1,000 users × 2 fetches/ngày = 2,000 fetches
2,000 × 20 KB = 40 MB/ngày = 1.2 GB/tháng
Free tier RTDB = 10 GB/tháng
→ Dư rất nhiều, KHÔNG MẤT TIỀN
```

### Ưu điểm so với Solution 5 (Firestore doc)
- ✅ **0 Firestore reads** — hoàn toàn miễn phí cho client reads
- ✅ RTDB free tier 10 GB/tháng (dư sức cho community feed)
- ✅ Tốc độ response nhanh hơn Firestore
- ✅ Đã có setup RTDB sẵn (play_counts)

### Nhược điểm so với Solution 5
- ⚠️ RTDB data structure phẳng hơn (không nested objects tốt)
- ⚠️ Cần serialize/deserialize thủ công
- ⚠️ Query phức tạp trên RTDB khó hơn (nhưng ở đây chỉ đọc 1 node nên OK)

---

## 🏆 So sánh tổng hợp

| Solution | Reads/fetch | Effort | Tiết kiệm |
|----------|------------|--------|-----------|
| 1. Xoá debug ✅ | 55 → 60 | 1 phút | 5 reads |
| 2. Limit history | N → 12 | 1 phút | ~40 reads |
| 3. Newest 50→30 | 60 → 40 | 1 phút | 20 reads |
| 4. Cache 12h→24h | Giảm miss | 1 phút | ~30% miss |
| **5. CF → Firestore doc** | 60 → **1** | 30 phút | **98%** |
| **6. CF → RTDB** | 60 → **0** | 30 phút | **100%** |

## 💡 Khuyến nghị

**Nếu muốn tối ưu tối đa:** Chọn **Solution 6 (RTDB)** vì:
1. 0 Firestore reads cho community
2. Đã có RTDB setup sẵn (play_counts)
3. Free tier dư sức
4. Kết hợp với local cache = gần như 0 cost

**Nếu muốn đơn giản nhất:** Chọn **Solution 5 (Firestore doc)** vì:
1. Cùng hệ sinh thái Firestore, dễ debug
2. 1 read/fetch đã đủ tối ưu
3. Không cần xử lý RTDB data format

**Cả 2 solution đều cần 1 Cloud Function chạy định kỳ** (mỗi 30 phút) để tổng hợp data.
