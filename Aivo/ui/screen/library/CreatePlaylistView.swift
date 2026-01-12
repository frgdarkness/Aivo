import SwiftUI
import UIKit

struct CreatePlaylistView: View {
    @Environment(\.dismiss) var dismiss
    @State private var playlistName: String = ""
    @State private var playlistDescription: String = ""
    
    // Cover Selection States
    @State private var selectedColor: Color = AivoTheme.Primary.orange
    @State private var selectedImage: UIImage?
    @State private var usePhoto: Bool = false
    @State private var showImagePicker = false
    
    private let coverColors: [Color] = [
        AivoTheme.Primary.orange,
        Color.blue,
        Color.green,
        Color.purple,
        Color.pink,
        Color.red,
        Color.yellow,
        Color.teal,
        Color.indigo,
        Color.gray
    ]
    
    var onPlaylistCreated: ((Playlist) -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                AivoTheme.Background.primary.ignoresSafeArea()
                
                mainContent
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if newImage != nil {
                    usePhoto = true
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    playlistDetailsSection
                    coverSection
                }
                .padding(.vertical)
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("New Playlist")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: createPlaylist) {
                Text("Create")
                    .fontWeight(.bold)
                    .foregroundColor(playlistName.isEmpty ? .gray : AivoTheme.Primary.orange)
            }
            .disabled(playlistName.isEmpty)
        }
        .padding()
    }
    
    private var playlistDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playlist Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                CustomTextField(placeholder: "Name", text: $playlistName)
                Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
                CustomTextField(placeholder: "Description (Optional)", text: $playlistDescription)
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var coverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cover")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                coverPreview
                
                if !usePhoto {
                    colorPicker
                }
                
                photoPickerButton
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var coverPreview: some View {
        ZStack {
            if usePhoto, let uiImage = selectedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .cornerRadius(12)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [selectedColor.opacity(0.8), selectedColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .overlay(
                        Text(playlistName.isEmpty ? "" : String(playlistName.prefix(1)).uppercased())
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            if usePhoto {
                Button(action: {
                    usePhoto = false
                    selectedImage = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5).clipShape(Circle()))
                }
                .offset(x: 65, y: -65)
            }
        }
        .padding(.top)
    }
    
    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(coverColors, id: \.self) { color in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedColor == color ? 2.5 : 0)
                        )
                        .onTapGesture {
                            selectedColor = color
                        }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var photoPickerButton: some View {
        Button(action: { showImagePicker = true }) {
            HStack {
                Image(systemName: "photo.fill")
                Text("Select Photo from Library")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Actions
    
    private func createPlaylist() {
        var finalCoverData: Data? = nil
        var finalColorHex: String? = nil
        
        if usePhoto, let uiImage = selectedImage {
             // Resize image to save space
            if let resizedData = uiImage.jpegData(compressionQuality: 0.7) {
                 finalCoverData = resizedData
            }
        } else {
            finalColorHex = colorToHex(selectedColor)
        }
        
        // PlaylistManager already publishes changes, but we need the object to pass back
        // Create it manually or get it from manager if it returns it.
        // Assuming PlaylistManager.createPlaylist returns void but adds to list.
        // Let's modify manager to return it OR just construct one here locally to pass (less safe if ID differs).
        // Better: Update Manager to return the created playlist.
        
        let newPlaylist = PlaylistManager.shared.createPlaylistAndReturn(
            name: playlistName,
            description: playlistDescription,
            coverImageData: finalCoverData,
            coverColor: finalColorHex,
            isCustomCover: usePhoto
        )
        
        onPlaylistCreated?(newPlaylist)
        dismiss()
    }
    
    private func colorToHex(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return "#FFA500" }
        
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
    }
    
    // MARK: - Components
    
    private struct CustomTextField: View {
        let placeholder: String
        @Binding var text: String
        
        var body: some View {
            TextField(placeholder, text: $text)
                .padding(.horizontal)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .accentColor(AivoTheme.Primary.orange)
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
