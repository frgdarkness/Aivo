//
//  EqualizerView.swift
//  Aivo
//
//  Adapted from Sona_ref
//

import SwiftUI

struct EqualizerView: View {
    @ObservedObject var musicPlayer = MusicPlayer.shared
    @Environment(\.dismiss) private var dismiss
    
    // Frequencies
    let frequencies = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"] // Updated to match likely Aivo config or standard 10-band
    // Note: Sona_ref had specific strings, I'll match standard 10-band or Sona_ref's if valid.
    // Sona_ref had: "25", "50", "100", "150", "300", "500", "1k", "2k", "3k", "4k" - kinda weird distribution?
    // Let's stick to standard octave layout for 10 bands if MusicPlayer uses it, OR match Sona_ref accurately if that's the goal.
    // MusicPlayer stub has 10 bands.
    // I'll stick to Sona_ref's labels for visual consistency unless standard is better.
    // Actually, Sona_ref's labels ["25", "50", "100", "150", "300", "500", "1k", "2k", "3k", "4k"] seem low-end focused.
    // I'll stick to standard ISO center frequencies for 10-band EQ: 31, 63, 125, 250, 500, 1k, 2k, 4k, 8k, 16k.
    // Labels:
    
    // Local State for Preset Management
    @State private var showingSaveDialog = false
    @State private var newPresetName = ""
    @State private var isModified = false
    
    // Computed property to get current preset object from ID
    private var currentSelectedPreset: MusicPlayer.EQPreset? {
        guard let id = musicPlayer.selectedPresetId else { return nil }
        let all = musicPlayer.customPresets + MusicPlayer.EQPreset.systemPresets
        return all.first(where: { $0.id == id })
    }
    
    var body: some View {
        ZStack {
            Color.black // Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text("EQUALIZER")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 12)
                    
                    Spacer()
                    
                    // On/Off Toggle
                    Toggle("", isOn: $musicPlayer.isEqEnabled)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: AivoTheme.Primary.orange))
                }
                .padding(20)
                
                // MARK: - Main Content (Disabled if EQ OFF)
                VStack(spacing: 0) {
                    // MARK: - Chart (Sliders)
                    GeometryReader { geometry in
                         let width = geometry.size.width
                         let height = geometry.size.height
                         let sliderHeight = height - 40
                         // Calculate width per slider dynamically
                         let sliderWidth = (width - 20) / 10
                         
                        HStack(spacing: 0) {
                            ForEach(0..<10) { index in
                                EqualizerSlider(
                                    value: Binding(
                                        get: { 
                                            // Safety check index
                                            if index < musicPlayer.eqBands.count {
                                                return musicPlayer.eqBands[index]
                                            }
                                            return 0
                                        },
                                        set: { newValue in
                                            if index < musicPlayer.eqBands.count {
                                                musicPlayer.eqBands[index] = newValue
                                            }
                                        }
                                    ),
                                    frequency: getFrequencyLabel(at: index),
                                    sliderHeight: sliderHeight,
                                    sliderWidth: sliderWidth,
                                    onValueChange: {
                                        handleSliderChange()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .padding(.vertical, 10)
                    .layoutPriority(1)
                    
                    // MARK: - Actions (Reset & Save)
                    HStack(spacing: 20) {
                        Button(action: resetToFlat) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Button(action: handleSaveButton) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Preset")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(isSaveButtonEnabled() ? Color.white : Color.white.opacity(0.3))
                            )
                        }
                        .disabled(!isSaveButtonEnabled())
                    }
                    .padding(.vertical, 10)
                    
                    // MARK: - Presets List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHOOSE YOUR STYLE")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                let customPresets = musicPlayer.customPresets
                                let systemPresets = MusicPlayer.EQPreset.systemPresets
                                let allPresets = customPresets + systemPresets
                                
                                ForEach(allPresets) { preset in
                                    ZStack(alignment: .topTrailing) {
                                        Button(action: {
                                            applyPreset(preset)
                                        }) {
                                            Text(preset.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    isPresetSelected(preset) ? AivoTheme.Primary.orange : Color.clear
                                                )
                                                .foregroundColor(
                                                    isPresetSelected(preset) ? .black : .white
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.white.opacity(0.2), lineWidth: isPresetSelected(preset) ? 0 : 1)
                                                )
                                                .clipShape(Capsule())
                                        }
                                        
                                        // Delete Button (Custom Only)
                                        if !preset.isSystem {
                                            Button(action: {
                                                deletePreset(preset)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.red)
                                                    .background(Circle().fill(Color.white))
                                            }
                                            .offset(x: 4, y: -4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.bottom, 14)
                    
                    // MARK: - Booster (Bass & Treble)
                    VStack(spacing: 12) {
                        Text("BOOSTER")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        
                        // Bass
                        HStack {
                            Text("BASS")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 60, alignment: .leading)
                            
                            Slider(value: Binding(
                                get: { musicPlayer.bassLevel },
                                set: { newValue in musicPlayer.bassLevel = newValue }
                            ), in: -10...10)
                            .accentColor(AivoTheme.Primary.orange)
                            
                            Text("\(Int(musicPlayer.bassLevel))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 30, alignment: .trailing)
                        }
                        .padding(.horizontal, 24)
                        
                        // Treble
                        HStack {
                            Text("TREBLE")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 60, alignment: .leading)
                            
                            Slider(value: Binding(
                                get: { musicPlayer.trebleLevel },
                                set: { newValue in musicPlayer.trebleLevel = newValue }
                            ), in: -10...10)
                            .accentColor(AivoTheme.Primary.orange)
                            
                            Text("\(Int(musicPlayer.trebleLevel))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 30, alignment: .trailing)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 10)
                }
                .opacity(musicPlayer.isEqEnabled ? 1.0 : 0.5)
                .disabled(!musicPlayer.isEqEnabled)
            }
        }
        .alert("New Preset", isPresented: $showingSaveDialog) {
            TextField("Preset Name", text: $newPresetName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveNewPreset()
            }
        } message: {
            Text("Enter a name for your custom preset.")
        }
    }
    
    // MARK: - Helper Logic
    
    private func getFrequencyLabel(at index: Int) -> String {
        let labels = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
        guard index < labels.count else { return "" }
        return labels[index]
    }
    
    private func formatValue(_ val: Double) -> String {
        let intVal = Int(val)
        return intVal > 0 ? "+\(intVal)" : "\(intVal)"
    }
    
    private func isPresetSelected(_ preset: MusicPlayer.EQPreset) -> Bool {
        return musicPlayer.selectedPresetId == preset.id
    }
    
    private func isSaveButtonEnabled() -> Bool {
        return isModified
    }
    
    private func applyPreset(_ preset: MusicPlayer.EQPreset) {
        withAnimation {
            musicPlayer.eqBands = preset.bands
            musicPlayer.selectedPresetId = preset.id
            // Also apply bass/treble from preset?
            musicPlayer.bassLevel = preset.bass
            musicPlayer.trebleLevel = preset.treble
            
            isModified = false
        }
    }
    
    private func handleSliderChange() {
        if let current = currentSelectedPreset, current.isSystem {
            musicPlayer.selectedPresetId = nil // Drift from system preset
        }
        isModified = true
    }
    
    private func resetToFlat() {
        if let flatPreset = MusicPlayer.EQPreset.systemPresets.first(where: { $0.name == "Flat" }) {
            applyPreset(flatPreset)
        } else {
            withAnimation {
                musicPlayer.eqBands = Array(repeating: 0.0, count: 10)
                musicPlayer.bassLevel = 0
                musicPlayer.trebleLevel = 0
                musicPlayer.selectedPresetId = nil
                isModified = false
            }
        }
    }
    
    private func handleSaveButton() {
        if let current = currentSelectedPreset, !current.isSystem {
            overwriteCustomPreset(current)
        } else {
            newPresetName = ""
            showingSaveDialog = true
        }
    }
    
    private func saveNewPreset() {
        guard !newPresetName.isEmpty else { return }
        
        let newPreset = MusicPlayer.EQPreset(
            name: newPresetName,
            bands: musicPlayer.eqBands,
            bass: musicPlayer.bassLevel,
            treble: musicPlayer.trebleLevel,
            isSystem: false
        )
        musicPlayer.customPresets.insert(newPreset, at: 0)
        
        musicPlayer.selectedPresetId = newPreset.id
        isModified = false
    }
    
    private func overwriteCustomPreset(_ preset: MusicPlayer.EQPreset) {
        if let index = musicPlayer.customPresets.firstIndex(where: { $0.id == preset.id }) {
            var updated = preset
            updated.bands = musicPlayer.eqBands
            updated.bass = musicPlayer.bassLevel
            updated.treble = musicPlayer.trebleLevel
            
            musicPlayer.customPresets[index] = updated
            musicPlayer.selectedPresetId = updated.id
            isModified = false
        }
    }
    
    private func deletePreset(_ preset: MusicPlayer.EQPreset) {
        if let index = musicPlayer.customPresets.firstIndex(where: { $0.id == preset.id }) {
            musicPlayer.customPresets.remove(at: index)
            if musicPlayer.selectedPresetId == preset.id {
                musicPlayer.selectedPresetId = nil
            }
        }
    }
}

// MARK: - Equalizer Slider Component
struct EqualizerSlider: View {
    @Binding var value: Double
    let frequency: String
    let sliderHeight: CGFloat
    let sliderWidth: CGFloat
    let onValueChange: () -> Void
    
    @State private var localValue: Double = 0
    @State private var isDragging: Bool = false
    @State private var debounceTask: DispatchWorkItem?
    
    var body: some View {
        VStack(spacing: 0) {
            Text(formatValue(localValue / 10.0))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(height: 20)
            
            ZStack {
                Slider(
                    value: $localValue,
                    in: -100...100,
                    onEditingChanged: { editing in
                        isDragging = editing
                        if !editing {
                            flushUpdate()
                        }
                    }
                )
                .accentColor(AivoTheme.Primary.orange)
                .rotationEffect(.degrees(-90))
                .frame(width: sliderHeight)
                .fixedSize()
                .onChange(of: localValue) { _ in
                    if isDragging {
                         scheduleDebouncedUpdate()
                    }
                }
            }
            .frame(width: sliderWidth, height: sliderHeight)
            
            Text(frequency)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
                .frame(height: 20)
        }
        .frame(width: sliderWidth)
        .onAppear {
            localValue = value * 10
        }
        .onChange(of: value) { newValue in
            if !isDragging {
                localValue = newValue * 10
            }
        }
    }
    
    private func scheduleDebouncedUpdate() {
        debounceTask?.cancel()
        
        let task = DispatchWorkItem {
             let realValue = localValue / 10.0
             value = realValue
             onValueChange()
        }
        
        debounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: task) // Fast debounce
    }
    
    private func flushUpdate() {
        debounceTask?.cancel()
        let realValue = localValue / 10.0
        value = realValue
        onValueChange()
    }
    
    private func formatValue(_ val: Double) -> String {
        let intVal = Int(round(val))
        return intVal > 0 ? "+\(intVal)" : "\(intVal)"
    }
}
