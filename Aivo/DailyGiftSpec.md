# 💡 Spec: Daily Gift Gamification System

## 1. Goal
Increase DAU (Daily Active Users) by rewarding users for consecutive logins and creating a "Premium Taste" through a functional trial on Day 7.

## 2. UI / UX
- **Toolbar Icon**: A gift icon placed next to the Premium (Crown) icon.
    - `icon_gift_yes`: Available to claim.
    - `icon_gift_no`: Already claimed today or on cooldown.
- **Daily Gift Popup**: A modal showing 7 slots (Day 1 to 7).
    - Current day is highlighted.
    - Already claimed days are checked.

## 3. Reward Schedule
| Day | Credit Reward | Special Reward |
|-----|---------------|----------------|
| 1   | 5 Credits     | -              |
| 2   | 5 Credits     | -              |
| 3   | 10 Credits    | -              |
| 4   | 10 Credits    | -              |
| 5   | 15 Credits    | -              |
| 6   | 15 Credits    | -              |
| 7   | 20 Credits    | **4h Premium** |

## 4. Claim Logic
- **Basic Users**: Must watch a **Reward Ad** to claim the daily gift.
- **Premium Users**: Claim directly with one tap (no ads).
- **Day 7 Activation**: Automatically triggers a 4-hour Premium window. During this time, the user gets all Premium benefits (no ads, unlimited generation/exports depending on system limits).

## 5. Persistence (Streak Logic)
- **Streak Rule**:
    - Users must claim every day to maintain the streak.
    - If a user misses **one full calendar day** (beyond the 24-48h window depending on definition), the streak resets to Day 1.
    - *Definition*: If current date is `lastClaimDate + 1 day`, increment streak. If `lastClaimDate + 2 days`, reset to Day 1.
- **Storage**: Store `dailyGiftStreakCount` and `lastGiftClaimDate` in `UserDefaults`.

## 6. Notifications
- **Schedule**: 8:00, 12:00, 20:00.
- **Logic**:
    - Check if `giftReservedToday` is true. If yes, **do not fire**.
    - Since local notifications are scheduled in advance:
        - When the app is opened, check if claimed today.
        - If not claimed, schedule/ensure notifications for the remaining slots of the day.
        - If claimed, cancel all pending notifications for today.
- **Content**: Include emojis 🎁 and persuasive text to "Keep your streak alive!"

---

## 🛠️ Implementation Blocks

### Block A: Logic Layer
- `DailyGiftManager.swift`: Handles state, streak calculation, and credit granting.
- Extend `SubscriptionManager.swift`: Add `trialExpiryDate` to `isPremium` logic.

### Block B: Notification Layer
- `DailyGiftNotificationManager.swift`: Handles UNUserNotificationCenter scheduling and suppression.

### Block C: UI Layer
- `DailyGiftIcon`: Floating/Header icon with availability state.
- `DailyGiftDialog`: The 7-day grid view.
- Update `HomeView.swift` header.
