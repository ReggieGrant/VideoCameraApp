//
//  VideoPlayerView.swift
//  VideoCameraApp
//
//  Created by Reginald Grant on 5/25/26.
//

//  VideoPlayerView.swift
//  VideoMemoRecorder
//
//  View: Video playback interface
//  Uses AVKit's VideoPlayer for simple video playback
//

import SwiftUI
import AVKit

// MARK: - VideoPlayerView

/// VideoPlayerView displays a video memo with playback controls
struct VideoPlayerView: View {
    
    // MARK: - Properties
    
    /// The video memo to display and play
    let memo: VideoMemo
    
    /// ViewModel for potential actions (like deleting)
    @ObservedObject var viewModel: VideoMemoViewModel
    
    /// Environment variable to dismiss this view
    @Environment(\.dismiss) var dismiss
    
    /// State for showing delete confirmation
    @State private var showingDeleteAlert = false
    
    /// State for editing mode
    @State private var isEditing = false
    
    /// State for edited title
    @State private var editedTitle: String
    
    /// State for edited notes
    @State private var editedNotes: String
    
    /// AVPlayer for video playback
    /// @State keeps the player instance alive while the view exists
    @State private var player: AVPlayer
    
    // MARK: - Initialization
    
    /// Initialize with a video memo
    init(memo: VideoMemo, viewModel: VideoMemoViewModel) {
        self.memo = memo
        self.viewModel = viewModel
        
        // Initialize the player with the video URL
        _player = State(initialValue: AVPlayer(url: memo.videoURL))
        
        // Initialize edit states with current values
        _editedTitle = State(initialValue: memo.title)
        _editedNotes = State(initialValue: memo.notes)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Video player
                VideoPlayer(player: player)
                    .frame(height: 300)
                    .onAppear {
                        // Prepare the player when view appears
                        player.seek(to: .zero)
                    }
                    .onDisappear {
                        // Pause when view disappears
                        player.pause()
                    }
                
                // Video information
                if isEditing {
                    editingForm
                } else {
                    infoSection
                }
                
                Spacer()
            }
            .navigationTitle("Video Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Close button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                // Edit/Save button
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveEdits()
                        }
                        .bold()
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
                
                // Delete button
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert("Delete Video Memo?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteMemo()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - View Components
    
    /// Information display section (non-editing mode)
    private var infoSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(memo.title)
                        .font(.title2)
                        .bold()
                }
                
                Divider()
                
                // Date created
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(memo.formattedDate)
                        .font(.body)
                }
                
                // Duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(memo.formattedDuration)
                        .font(.body)
                }
                
                Divider()
                
                // Notes
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(memo.notes.isEmpty ? "No notes" : memo.notes)
                        .font(.body)
                        .foregroundColor(memo.notes.isEmpty ? .secondary : .primary)
                }
            }
            .padding()
        }
    }
    
    /// Editing form
    private var editingForm: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Title", text: $editedTitle)
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $editedNotes)
                    .frame(height: 150)
            }
        }
    }
    
    // MARK: - Actions
    
    /// Saves the edited title and notes
    private func saveEdits() {
        viewModel.updateMemo(memo, title: editedTitle, notes: editedNotes)
        isEditing = false
    }
    
    /// Deletes the current memo
    private func deleteMemo() {
        viewModel.deleteMemo(memo)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    VideoPlayerView(
        memo: VideoMemo.samples[0],
        viewModel: VideoMemoViewModel()
    )
}
