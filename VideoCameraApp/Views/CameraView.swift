//
//  CameraView.swift
//  VideoCameraApp
//
//  Created by Reginald Grant on 5/25/26.
//


//  CameraView.swift
//  VideoMemoRecorder
//
//  View: Camera recording interface
//  This view allows users to record video memos
//

import SwiftUI

// MARK: - CameraView

/// CameraView provides the recording interface with camera preview and controls
struct CameraView: View {
    
    // MARK: - Environment and State
    
    /// ViewModel containing all app logic and state
    /// @ObservedObject means this view will update when the ViewModel changes
    @ObservedObject var viewModel: VideoMemoViewModel
    
    /// Environment variable to dismiss this view
    @Environment(\.dismiss) var dismiss
    
    /// State to control showing the save sheet after recording
    @State private var showingSaveSheet = false
    
    /// Temporary storage for title input
    @State private var recordingTitle = ""
    
    /// Temporary storage for notes input
    @State private var recordingNotes = ""
    
    /// Timer to track recording duration
    @State private var recordingDuration: TimeInterval = 0
    
    /// Timer object for updating duration
    @State private var timer: Timer?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Camera preview layer
            if viewModel.cameraService.isSessionRunning {
                CameraPreviewView(session: viewModel.cameraService.getCaptureSession())
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Overlay with controls
            VStack {
                // Top bar with close button
                topBar
                
                Spacer()
                
                // Recording indicator and duration
                if viewModel.cameraService.isRecording {
                    recordingIndicator
                }
                
                Spacer()
                
                // Bottom controls
                controlsBar
            }
        }
        .onAppear {
            // Start the camera session when view appears
            viewModel.cameraService.startSession()
        }
        .onDisappear {
            // Stop the camera session when view disappears to save battery
            viewModel.cameraService.stopSession()
            
            // Stop any ongoing recording
            if viewModel.cameraService.isRecording {
                viewModel.stopRecording()
            }
        }
        // Sheet to save recording with title and notes
        .sheet(isPresented: $showingSaveSheet) {
            SaveRecordingView(
                title: $recordingTitle,
                notes: $recordingNotes,
                onSave: {
                    // Save the recording with the entered title and notes
                    viewModel.saveRecording(title: recordingTitle, notes: recordingNotes)
                    
                    // Reset input fields
                    recordingTitle = ""
                    recordingNotes = ""
                    
                    // Close the camera view
                    dismiss()
                },
                onCancel: {
                    // Cancel without saving
                    viewModel.cancelRecording()
                }
            )
        }
    }
    
    // MARK: - View Components
    
    /// Top bar with close button
    private var topBar: some View {
        HStack {
            // Close button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding()
            
            Spacer()
        }
    }
    
    /// Recording indicator showing red dot and duration
    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            // Pulsing red circle
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .opacity(0.8)
            
            // Duration text
            Text(formatDuration(recordingDuration))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }
    
    /// Bottom controls bar with record button
    private var controlsBar: some View {
        VStack(spacing: 20) {
            // Information text
            if !viewModel.cameraService.isRecording {
                Text("Tap to record")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            // Record button
            Button(action: {
                toggleRecording()
            }) {
                ZStack {
                    // Outer circle
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    // Inner circle (changes when recording)
                    if viewModel.cameraService.isRecording {
                        // Square for stop
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 40, height: 40)
                    } else {
                        // Circle for record
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Toggles between recording and stopping
    private func toggleRecording() {
        if viewModel.cameraService.isRecording {
            // Stop recording
            stopRecording()
        } else {
            // Start recording
            startRecording()
        }
    }
    
    /// Starts video recording
    private func startRecording() {
        // Reset duration
        recordingDuration = 0
        
        // Start the recording via ViewModel
        viewModel.startRecording()
        
        // Start timer to update duration display
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
    }
    
    /// Stops video recording
    private func stopRecording() {
        // Stop the recording via ViewModel
        viewModel.stopRecording()
        
        // Stop the timer
        timer?.invalidate()
        timer = nil
        
        // Show the save sheet after a brief delay
        // The delay ensures the video file is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingSaveSheet = true
        }
    }
    
    /// Formats duration in seconds to MM:SS format
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - SaveRecordingView

/// Sheet view for adding title and notes to a recording
struct SaveRecordingView: View {
    
    // MARK: - Properties
    
    /// Binding to the title text field
    @Binding var title: String
    
    /// Binding to the notes text field
    @Binding var notes: String
    
    /// Closure to call when user taps save
    let onSave: () -> Void
    
    /// Closure to call when user cancels
    let onCancel: () -> Void
    
    /// Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Title section
                Section(header: Text("Title")) {
                    TextField("Enter title", text: $title)
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Save Video Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                // Save button
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CameraView(viewModel: VideoMemoViewModel())
}
