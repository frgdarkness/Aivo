# 🎮 Aivo Gamification & Retention Strategy

This document outlines strategic enhancements designed to increase Daily Active Users (DAU) and maximize Reward Ad performance through gamification and value-driven incentives.

---

## 🚀 Part 1: Increasing Daily User Retention (DAU/MAU)

Focus: Creating "habit icons" and "FOMO" mechanisms that make the app indispensable.

### 1. Daily "For You" AI Curation
*   **The Idea:** A dedicated "Daily Soundscape" playlist generated every 24 hours based on user flavor profile (genres they generated/played) + trending community hits.
*   **Engagement Loop:** Automatic push notification at peak hour (e.g., 9:00 AM) suggesting the fresh daily mix.
*   **Difficulty:** 🟡 Medium (Requires logic to blend personal data + Firestore trending).

### 2. Progressive Daily Streak (The "Chain" Bonus)
*   **The Idea:** Move from a flat 5-credit daily gift to a tiered streak bonus.
    *   Day 1: +5 Credits
    *   Day 3: +10 Credits + Unique Badge
    *   Day 7: Unlimited Pro Features for 24h (or +50 Credits)
*   **Engagement Loop:** Social proof tags like "🔥 7-Day Streaker" on profile. Breaking the chain resets progress.
*   **Difficulty:** 🟢 Easy (Update `UserDefaultsManager` and `GetFreeCreditDialog`).

### 3. Community Music Battle (Song of the Day)
*   **The Idea:** Two highly-rated community songs are pitted against each other. Users vote for their favorite.
*   **Engagement Loop:** Rewards of +1 or +2 credits for voting. Creates a sense of community influence.
*   **Difficulty:** 🟡 Medium (Requires a small "Battle" node in Firestore/RTDB).

### 4. Interactive Lyric Challenge
*   **The Idea:** A daily "Fill in the Blank" challenge where the app plays a 5-10s clip.
*   **Engagement Loop:** Succesfully completing the lyrics grants credits.
*   **Difficulty:** 🔴 Hard (Requires timestamp data for lyrics or manual curation).

---

## 💰 Part 2: Optimizing Reward Ad Performance

Focus: Linking ads directly to the user's "pain points" (status and resources).

### 1. Song Boosters (The "Viral" Mechanic)
*   **The Idea:** Add a "Boost View Count" button on the user's own song page.
*   **Utility:** Watching 1 Reward Ad triggers a `ServerValue.increment(random(50, 200))` on the play count.
*   **Psychology:** Satisfies the desire for fame/validation with a simple 30s ad.
*   **Difficulty:** 🟢 Easy (Uses existing `PlayCountManager` logic with higher limits).

### 2. Time-Limited Pro Unlock
*   **The Idea:** Users can "Rent" premium features (Equalizer advanced settings, HD Export, No Watermark) by watching 3 consecutive ads.
*   **Utility:** Grants a 1-hour or 2-hour Pro window.
*   **Psychology:** Lowers the barrier to entry for users who aren't ready to pay for a subscription but need the high-end output.
*   **Difficulty:** 🟡 Medium (Requires tracking "Pro Expiration" in local storage).

### 3. The "Lucky Spin" Wheel
*   **The Idea:** A visual wheel in the "Get Free Credit" dialog.
*   **Utility:** 1 free spin/day. Extra spins require 1 Reward Ad each.
*   **Rewards:** 5, 10, 20 credits, or "Jackpot" (1 free song generation).
*   **Difficulty:** 🟡 Medium (UI + Spin logic).

### 4. "Generate" Rescue (Low Credit Fallback)
*   **The Idea:** If a user tries to generate a song with < 30 credits, instead of a "Insufficient Balance" error, show a "Generate for Free" button.
*   **Utility:** Watching 1-2 ads grants the remaining credits needed.
*   **Difficulty:** 🟢 Easy (UI update to `GenerateSongViewModel`).

---

## 🛠️ Phase 1 Implementation (Priority Stack)

1.  **Quick Win 1:** Implement **Song Boosters** (Uses existing RTDB infra).
2.  **Quick Win 2:** Update `GetFreeCreditDialog` to support **Progressive Streaks**.
3.  **Revenue Add:** Implement **Generate Rescue** to prevent bounce-rate at the core action point.
