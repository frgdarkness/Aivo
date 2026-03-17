import SwiftUI
import Kingfisher

// MARK: - Select Model Screen
struct SelectModelScreen: View {
    let availableModels: [CoverSongModel]
    let initialSelected: CoverSongModel?
    let onDone: (CoverSongModel?) -> Void
    let onCancel: () -> Void

    @State private var selectedModel: CoverSongModel?
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss

    init(availableModels: [CoverSongModel], initialSelected: CoverSongModel?, onDone: @escaping (CoverSongModel?) -> Void, onCancel: @escaping () -> Void) {
        self.availableModels = availableModels
        self.initialSelected = initialSelected
        self.onDone = onDone
        self.onCancel = onCancel
        _selectedModel = State(initialValue: initialSelected)
    }

    private var filteredModels: [CoverSongModel] {
        guard !searchText.isEmpty else { return availableModels }
        return availableModels.filter { model in
            model.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AivoSunsetBackground()

            VStack(spacing: 0) {
                headerView
                searchBar

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(filteredModels) { model in
                            modelItem(model)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }

                bottomButtons
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                onCancel()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: iPadScale(22)))
                    .foregroundColor(.white)
            }

            Spacer()

            Text("Select Model")
                .font(.system(size: iPadScale(20), weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear
                .frame(width: iPadScale(24), height: iPadScale(24))
        }
        .padding(.horizontal, 20)
        .padding(.top, iPadScaleSmall(10))
        .padding(.bottom, iPadScaleSmall(16))
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: iPadScale(16)))
                .foregroundColor(.gray)
                .padding(.leading, iPadScaleSmall(12))

            TextField("", text: $searchText, prompt: Text("Search model").foregroundColor(.white.opacity(0.45)))
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: iPadScale(16)))
                .foregroundColor(.white)
                .padding(.vertical, iPadScaleSmall(12))

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: iPadScale(16)))
                        .foregroundColor(.gray)
                }
                .padding(.trailing, iPadScaleSmall(12))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: iPadScale(8))
                .fill(Color.gray.opacity(0.2))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, iPadScaleSmall(16))
    }

    // MARK: - Model Item
    private func modelItem(_ model: CoverSongModel) -> some View {
        let imgSize: CGFloat = DeviceScale.isIPad ? 180 : 90
        let itemW: CGFloat = DeviceScale.isIPad ? 200 : 100
        let itemH: CGFloat = DeviceScale.isIPad ? 240 : 128
        
        return Button(action: {
            selectedModel = (selectedModel?.id == model.id) ? nil : model
        }) {
            VStack(spacing: iPadScaleSmall(6)) {
                KFImage(URL(string: model.thumbUrl))
                    .placeholder { ProgressView().frame(width: imgSize * 0.78, height: imgSize * 0.78) }
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 240, height: 240)))
                    .loadDiskFileSynchronously()
                    .resizable()
                    .scaledToFill()
                    .frame(width: imgSize, height: imgSize)
                    .clipShape(RoundedRectangle(cornerRadius: iPadScale(12)))

                Text(model.displayName)
                    .font(.system(size: iPadScale(12), weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: itemW, height: itemH)
            .background(
                RoundedRectangle(cornerRadius: iPadScale(12))
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: iPadScale(12))
                    .stroke(selectedModel?.id == model.id ? AivoTheme.Primary.orange : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                onDone(selectedModel)
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: iPadScale(16), weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: iPadScale(50))
                    .background(
                        RoundedRectangle(cornerRadius: iPadScale(12))
                            .fill(AivoTheme.Primary.orange)
                    )
            }
            .disabled(selectedModel == nil)
            .opacity(selectedModel == nil ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, iPadScaleSmall(14))
        .background(
            Rectangle()
                .fill(AivoTheme.Background.primary)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
    }
}

// MARK: - Preview
struct SelectModelScreen_Previews: PreviewProvider {
    static var previews: some View {
        SelectModelScreen(
            availableModels: [
                CoverSongModel(id: 1, modelName: "model_a", displayName: "Model A", thumbUrl: "https://picsum.photos/seed/a/200"),
                CoverSongModel(id: 2, modelName: "model_b", displayName: "Model B", thumbUrl: "https://picsum.photos/seed/b/200")
            ],
            initialSelected: nil,
            onDone: { _ in },
            onCancel: {}
        )
    }
}


