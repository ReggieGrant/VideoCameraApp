//
//  MemoListView.swift
//  VideoCameraApp
//
//  Created by Reginald Grant on 5/25/26.
//


//  MemoListView.swift
//  VideoMemoRecorder
//
//  View: Main list view showing all video memos
//  This is typically the first screen users see
//

import SwiftUI

// MARK: - MemoListView

/// MemoListView displays a list of all recorded video memos
/// This is the main screen of the app
struct MemoListView: View {
    
    // MARK: - Properties
    
    /// The ViewModel managing app state and logic
    /// @StateObject ensures the ViewModel stays alive for the entire lifecycle of this view
    @StateObject private var viewModel = VideoMemoViewModel()
    
    /// State for showing permission alert
    @State private var showingPermissionAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                if viewModel.videoMemos.isEmpty {
                    // Empty state when no memos exist
                    emptyStateView
                } else {
                    // List of memos
                    memosList
                }
            }
            .navigationTitle("Video Memos")
            .toolbar {
                // Add new memo button in toolbar
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        openCamera()
                    }) {
                        Image(systemName: "video.badge.plus")
                            .font(.title3)
                    }
                }
            }
            // Camera view sheet
            .sheet(isPresented: $viewModel.showingCameraSheet) {
                CameraView(viewModel: viewModel)
            }
            // Video detail/playback sheet
            .sheet(isPresented: $viewModel.showingDetailSheet) {
                if let memo = viewModel.selectedMemo {
                    VideoPlayerView(memo: memo, viewModel: viewModel)
                }
            }
            // Permission denied alert
            .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    // Open app settings so user can enable permissions
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable camera and microphone access in Settings to record video memos.")
            }
        }
    }
    
    // MARK: - View Components
    
    /// Empty state view shown when no memos exist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "video.slash")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            // Title
            Text("No Video Memos Yet")
                .font(.title2)
                .bold()
            
            // Description
            Text("Tap the + button to record your first video memo")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Action button
            Button(action: {
                openCamera()
            }) {
                Label("Record Video Memo", systemImage: "video.badge.plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }
    
    /// List of all video memos
    private var memosList: some View {
        List {
            // Iterate through all memos
            ForEach(viewModel.videoMemos) { memo in
                MemoRowView(memo: memo)
                    .contentShape(Rectangle())  // Makes entire row tappable
                    .onTapGesture {
                        // Open memo for playback
                        viewModel.openMemo(memo)
                    }
            }
            // Swipe to delete
            .onDelete(perform: deleteMemos)
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions
    
    /// Opens the camera to record a new memo
    private func openCamera() {
        // Check for camera and microphone permissions first
        viewModel.checkPermissions { granted in
            if granted {
                // Permissions granted, show camera
                viewModel.showingCameraSheet = true
            } else {
                // Permissions denied, show alert
                showingPermissionAlert = true
            }
        }
    }
    
    /// Deletes memos at the specified indices
    /// This is called by the swipe-to-delete gesture
    private func deleteMemos(at offsets: IndexSet) {
        // Get the memos to delete
        let memosToDelete = offsets.map { viewModel.videoMemos[$0] }
        
        // Delete each memo
        memosToDelete.forEach { memo in
            viewModel.deleteMemo(memo)
        }
    }
}

// MARK: - MemoRowView

/// MemoRowView displays a single memo in the list
/// Separating this into its own view makes the code cleaner and more reusable
struct MemoRowView: View {
    
    // MARK: - Properties
    
    /// The memo to display
    let memo: VideoMemo
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Video icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            // Memo information
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(memo.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // Date
                Text(memo.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(memo.formattedDuration)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Notes preview (if available)
                if !memo.notes.isEmpty {
                    Text(memo.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Chevron to indicate it's tappable
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    MemoListView()
}

#Preview("With Data") {
    // Preview with sample data
    let viewModel = VideoMemoViewModel()
    viewModel.videoMemos = VideoMemo.samples
    
    return NavigationView {
        List {
            ForEach(VideoMemo.samples) { memo in
                MemoRowView(memo: memo)
            }
        }
        .navigationTitle("Video Memos")
    }
}
