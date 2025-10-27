import Foundation

// MARK: - Cover Song Model
struct CoverSongModel: Codable, Identifiable, Hashable {
    let id: Int
    let modelName: String
    let displayName: String
    let thumbUrl: String
    
    /// Load all cover song models - tries to load from bundle first, falls back to hardcoded data
    static func loadModels() -> [CoverSongModel] {
        // Try to load from bundle first
        if let url = Bundle.main.url(forResource: "cover_song_models", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let models = try? JSONDecoder().decode([CoverSongModel].self, from: data) {
            Logger.i("✅ [CoverSongModel] Loaded \(models.count) models from bundle")
            return models
        }
        
        // Fallback to hardcoded models if bundle file not found
        Logger.w("⚠️ [CoverSongModel] Could not load from bundle, using hardcoded models")
        return defaultModels()
    }
    
    /// Default hardcoded models as fallback
    private static func defaultModels() -> [CoverSongModel] {
        let jsonString = """
        [
          {"id": 0, "modelName": "vegeta", "displayName": "Veg3t4", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fcover_model_vegeta.jpg?alt=media&token=e1721869-ccee-4fae-8cbb-54a242ee6067"},
          {"id": 1, "modelName": "goku", "displayName": "G0kuuu~", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fmodel_cover_goku.jpg?alt=media&token=b80f09bb-f2f7-4f62-b535-90761b10eb96"},
          {"id": 2, "modelName": "zozo", "displayName": "Z0r0🔥", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fcover_model_zoro.png?alt=media&token=46e45fad-2433-4158-9732-7adfc47ad3e7"},
          {"id": 3, "modelName": "edsheeran", "displayName": "Ed 5heeran", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_ed_sheeran.jpg?alt=media&token=f9d984e3-91ee-4068-97d5-2bc1418a50db"},
          {"id": 4, "modelName": "trump", "displayName": "TruMp💸", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_trump.jpg?alt=media&token=8bacde4f-631c-4f1b-9a36-6f9498e1b66e"},
          {"id": 5, "modelName": "luffy-e", "displayName": "Luff¥☠️", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fcover_model_luffy.png?alt=media&token=e9dd3bf3-33d8-4e6d-900a-73f822fa523f"},
          {"id": 6, "modelName": "satorugojo-yuichinakamura", "displayName": "S4toru G0j0😎", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fcover_model_gojo%20(1).jpg?alt=media&token=b4b9c004-9214-47f9-86a3-f7736e2854bf"},
          {"id": 7, "modelName": "kanyev2-redux", "displayName": "K4nye W3$t", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_kayne_west.jpg?alt=media&token=8f23d1d0-3cb8-48a0-9f41-e868d1cd5045"},
          {"id": 8, "modelName": "taylorswift", "displayName": "T4yl0r 5w1ft💖", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fcover_model_taylor.jpg?alt=media&token=bcd20c8f-d9e5-44fb-a21d-3549c560a2d8"},
          {"id": 9, "modelName": "justinbieber", "displayName": "Ju$t1n B!3b3r✨", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_justin_bieber.jpg?alt=media&token=20205a23-0abf-48b3-b8bf-23b165a2540c"},
          {"id": 10, "modelName": "eminem-e", "displayName": "3m!n3m🔥", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_eminem.jpg?alt=media&token=972dbb22-2b07-4a82-a65b-bf865ad51e0c"},
          {"id": 11, "modelName": "drake", "displayName": "Dr4k3🐍", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_drake.jpg?alt=media&token=f1028ccc-f7f8-4464-b791-16c2140bc26b"},
          {"id": 12, "modelName": "arianagrande", "displayName": "4ri@na", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_ariana_grande.jpg?alt=media&token=b4842841-ed02-4468-89c3-e5a40451e649"},
          {"id": 13, "modelName": "srkmodel", "displayName": "Sh4h RuKh Kh4n", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fcover_model_shah_rukh_khan.jpg?alt=media&token=7866c01c-8a0b-416c-837c-cdc7b8d0d55a"},
          {"id": 14, "modelName": "modi", "displayName": "N4rendr4 M0d!", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fmodel_cover_narendra_modi.jpg?alt=media&token=adfb30e7-0373-4111-88f2-386262c48d71"},
          {"id": 15, "modelName": "biden", "displayName": "J0e B!d3n", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fnew%2Fcover_model_joe_biden.jpg?alt=media&token=8fdbc2b4-016d-4f91-9e9f-d3ab461b68f3"},
          {"id": 16, "modelName": "billie2019-e", "displayName": "B!llie E!l!5h", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_billie_eilish.jpg?alt=media&token=835bb2b9-15b4-4988-90e5-5452b0fd0753"},
          {"id": 17, "modelName": "jungkookv7-e", "displayName": "Jun9k00k", "thumbUrl": "https://firebasestorage.googleapis.com/v0/b/interior-ai---ai-home-design.firebasestorage.app/o/Aivo%2Fcover_model_jungkook.jpg?alt=media&token=d1c61259-650f-457a-ac8e-e9c78bb023af"}
        ]
        """
        
        guard let data = jsonString.data(using: .utf8),
              let models = try? JSONDecoder().decode([CoverSongModel].self, from: data) else {
            Logger.e("❌ [CoverSongModel] Failed to decode hardcoded models")
            return []
        }
        
        Logger.i("✅ [CoverSongModel] Loaded \(models.count) models from hardcoded data")
        return models
    }
}

