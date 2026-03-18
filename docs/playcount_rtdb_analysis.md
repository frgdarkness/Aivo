# Phân tích hệ thống PlayCount với RTDB

## 1. Vấn đề hiện tại

Mỗi lần user bấm play → **1 Firestore write** trực tiếp lên document của bài hát.

- 50K users × 15 bài/ngày = **750,000 writes/ngày**
- Chi phí: ~$1.35/ngày ≈ **$40/tháng** (chỉ riêng playCount)
- Khi scale lên 200K users → **$160/tháng**

---

## 2. Cấu trúc RTDB đề xuất

```
realtime-database/
└── play_counts/
    ├── {songID_1}: 157        ← Số lượt nghe chưa sync
    ├── {songID_2}: 43
    ├── {songID_3}: 891
    └── ...
```

### Giải thích:
- **`play_counts/`**: Node gốc chứa tất cả lượt nghe
- **Key**: `songID` (ID của bài hát)
- **Value**: Số lượt nghe **chưa được sync** lên Firestore (kiểu số nguyên)
- Dùng `ServerValue.increment(1)` để tăng atomic, tránh race condition

### Ví dụ thực tế:
```json
{
  "play_counts": {
    "abc123_suno_song": 157,
    "def456_suno_song": 43,
    "ghi789_suno_song": 891
  }
}
```

> [!NOTE]
> Cấu trúc cực kỳ đơn giản — chỉ 1 node, mỗi bài = 1 key-value. Không cần nested structure phức tạp.

---

## 3. Quy trình hoạt động

### 3.1. Client (iOS App) — Khi user nghe bài

```
User bấm Play
    ↓
Kiểm tra: đã nghe ≥ 30 giây chưa?
    ↓ (Có)
Gọi RTDB: play_counts/{songID} += 1
    ↓
Xong (1 RTDB write, gần như FREE)
```

**Chi tiết:**
1. User bấm play → **KHÔNG write ngay**
2. Timer theo dõi thời gian nghe
3. Khi nghe **≥ 30 giây** → gọi `RTDB.increment(1)` cho `songID`
4. Nếu user skip trước 30s → **KHÔNG count** (tiết kiệm + chính xác hơn)

### 3.2. Cloud Function (Scheduled) — Sync RTDB → Firestore

```
Cloud Function chạy mỗi 6 giờ (4 lần/ngày)
    ↓
Đọc toàn bộ node play_counts/ từ RTDB
    ↓
Với mỗi songID có count > 0:
    → Firestore: songs/{songID}.playCount += count
    ↓
Xóa (hoặc reset về 0) các songID đã sync trên RTDB
    ↓
Xong
```

**Chi tiết Cloud Function:**
1. Trigger: `pubsub.schedule('every 6 hours')`
2. Đọc snapshot của `play_counts/`
3. Tạo Firestore **batch write** (tối đa 500 docs/batch)
4. Mỗi doc: `FieldValue.increment(count)` — cộng dồn vào playCount hiện tại
5. Sau khi batch commit thành công → xóa các key đã sync trên RTDB
6. Log kết quả

---

## 4. So sánh chi phí

### Trước (hiện tại):
| Hạng mục | Số lượng/ngày | Chi phí |
|----------|-------------|---------|
| Firestore writes | 750,000 | ~$1.35/ngày |
| **Tổng/tháng** | | **~$40** |

### Sau (RTDB + Cloud Function):

| Hạng mục | Số lượng/ngày | Chi phí |
|----------|-------------|---------|
| RTDB writes | 750,000 | **$0** (free tier: 10GB transfer/tháng) |
| Cloud Function chạy | 4 lần | ~$0.001 |
| Firestore batch writes | ~5,000-10,000 docs × 4 lần = ~20,000-40,000 | ~$0.04-0.07/ngày |
| **Tổng/tháng** | | **~$1.5-2** |

> [!IMPORTANT]
> **Giảm từ ~$40/tháng → ~$2/tháng** (giảm **95%**) với 50K users.
> Khi scale lên 200K users: từ $160/tháng → ~$5/tháng.

---

## 5. Ưu/nhược điểm

### ✅ Ưu điểm:
- **Chi phí gần $0** cho phần write từ client
- **Atomic increment** trên RTDB = không bị race condition
- **Đơn giản** — chỉ cần thay 1 dòng code trên client
- **Filter 30s** giúp dữ liệu chính xác hơn (không count skip)
- RTDB có **free tier rộng rãi** (1GB storage, 10GB transfer/tháng)

### ⚠️ Nhược điểm:
- PlayCount trên Firestore **không realtime** (delay tối đa 6 giờ)
- Cần deploy **Cloud Function** để sync
- Nếu Cloud Function fail → mất data RTDB (giải pháp: dùng transaction, retry)

### Giải pháp cho nhược điểm delay:
- UI Explore/Community đọc playCount từ Firestore → delay 6h là **chấp nhận được**
- Nếu cần show realtime → đọc thêm từ RTDB cộng vào (optional, phức tạp hơn)

---

## 6. Tóm tắt thay đổi cần làm

### 📱 Client (iOS):
1. **Xóa** `FirestoreService.shared.incrementPlayCount()` khỏi `MusicPlayer` và `OnlineStreamPlayer`
2. **Thêm** logic đếm 30s trước khi ghi RTDB
3. **Thêm** function gọi RTDB increment: `play_counts/{songID} += 1`

### ☁️ Server (Cloud Functions):
1. **Tạo** scheduled function chạy mỗi 6h
2. **Đọc** tất cả `play_counts/` từ RTDB
3. **Batch write** `playCount += N` cho từng song trên Firestore
4. **Xóa** data đã sync trên RTDB

### 🗑️ Xóa:
1. `FirestoreService.incrementPlayCount()` — không cần nữa (hoặc giữ cho Cloud Function dùng)

---

## 7. Flow diagram

```
┌─────────────┐         ┌──────────┐         ┌──────────────┐
│  iOS App    │         │   RTDB   │         │  Firestore   │
│             │         │          │         │              │
│ User plays  │──30s──▸│ songID   │         │              │
│ a song      │  +1    │ += 1     │         │              │
│             │         │          │         │              │
│ User plays  │──30s──▸│ songID2  │         │              │
│ another     │  +1    │ += 1     │         │              │
└─────────────┘         └──────────┘         └──────────────┘
                              │
                    Cloud Function (mỗi 6h)
                              │
                              ▼
                    ┌──────────────────┐
                    │ Đọc play_counts  │
                    │ Batch update     │──────▸ Firestore
                    │ Xóa RTDB data    │       playCount += N
                    └──────────────────┘
```
