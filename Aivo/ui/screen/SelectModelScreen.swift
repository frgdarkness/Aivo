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
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Spacer()

            Text("Select Model")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 12)

            TextField("Search model", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .padding(.vertical, 12)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Model Item
    private func modelItem(_ model: CoverSongModel) -> some View {
        Button(action: {
            selectedModel = (selectedModel?.id == model.id) ? nil : model
        }) {
            VStack(spacing: 6) {
                KFImage(URL(string: model.thumbUrl))
                    .placeholder { ProgressView().frame(width: 70, height: 70) }
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 120, height: 120)))
                    .loadDiskFileSynchronously()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(model.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 100, height: 128)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AivoTheme.Primary.orange)
                    )
            }
            .disabled(selectedModel == nil)
            .opacity(selectedModel == nil ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
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


