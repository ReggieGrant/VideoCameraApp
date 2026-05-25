//
//  VideoMemoViewModel.swift
//  VideoCameraApp
//
//  Created by Reginald Grant on 5/25/26.
//


//  VideoMemoViewModel.swift
//  VideoMemoRecorder
//
//  ViewModel: Manages the business logic and state for video memos
//  In MVVM, the ViewModel sits between the View and Model
//  It processes data from the Model and prepares it for the View
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

// MARK: - VideoMemoViewModel

/// VideoMemoViewModel manages all video memos and coordinates with the camera service
/// ObservableObject: Allows SwiftUI views to observe changes to this object
class VideoMemoViewModel: ObservableObject {
    
    // MARK: - Published Properties
    // These properties trigger view updates when changed
    
    /// Array of all video memos
    /// When this changes, any views displaying the list will automatically update
    @Published var videoMemos: [VideoMemo] = []
    
    /// The camera service instance for recording videos
    @Published var cameraService = CameraService()
    
    /// Currently selected video memo for playback
    /// Optional because no memo may be selected
    @Published var selectedMemo: VideoMemo?
    
    /// Controls whether the detail/playback sheet is shown
    @Published var showingDetailSheet = false
    
    /// Controls whether the camera/recording sheet is shown
    @Published var showingCameraSheet = false
    
    /// Temporary URL of the just-recorded video (before saving)
    /// This holds the video while the user adds title/notes
    @Published var temporaryVideoURL: URL?
    
    // MARK: - Private Properties
    
    /// File manager for handling file operations
    private let fileManager = FileManager.default
    
    /// URL of the file where we save the memos list (as JSON)
    private var memosFileURL: URL {
        // Get the documents directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Create a file called "videoMemos.json" in documents directory
        return documentsPath.appendingPathComponent("videoMemos.json")
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved memos when the ViewModel is created
        loadMemos()
        
        // Setup the camera
        cameraService.setupCamera()
    }
    
    // MARK: - Recording Functions
    
    /// Starts recording a new video memo
    func startRecording() {
        // Start the camera session if not already running
        if !cameraService.isSessionRunning {
            cameraService.startSession()
        }
        
        // Begin recording and handle completion
        cameraService.startRecording { [weak self] url in
            // This closure is called when recording stops
            DispatchQueue.main.async {
                // Store the temporary video URL
                self?.temporaryVideoURL = url
            }
        }
    }
    
    /// Stops the current recording
    func stopRecording() {
        cameraService.stopRecording()
    }
    
    /// Saves a recorded video as a new memo with title and notes
    /// - Parameters:
    ///   - title: The title for the video memo
    ///   - notes: Optional notes about the video
    func saveRecording(title: String, notes: String)  {
        // Make sure we have a temporary video to save
        guard let tempURL = temporaryVideoURL else {
            print("No temporary video to save")
            return
        }
        
        // Generate a unique filename for permanent storage
        let fileName = "video_\(UUID().uuidString).mov"
        
        // Get the documents directory path for permanent storage
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // Move the video from temporary storage to documents directory
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            // Get the video duration using AVAsset
            // let asset = AVURLAsset(url: destinationURL)
            // Get the video duration using AVAsset
                        let asset = AVAsset(url: destinationURL)
                        let duration = asset.duration.seconds
            
            // Create a new VideoMemo object
            let newMemo = VideoMemo(
                title: title.isEmpty ? "Untitled Video" : title,  // Default title if empty
                notes: notes,
                videoFileName: fileName,
                duration:duration
            )
            
            // Add to the beginning of the array (newest first)
            videoMemos.insert(newMemo, at: 0)
            
            // Save the updated memos list to disk
            saveMemos()
            
            // Clean up temporary URL
            temporaryVideoURL = nil
            
        } catch {
            print("Error saving video: \(error.localizedDescription)")
        }
    }
    
    /// Cancels the current recording without saving
    func cancelRecording() {
        // Delete the temporary video file
        if let tempURL = temporaryVideoURL {
            try? fileManager.removeItem(at: tempURL)
        }
        
        // Clear the temporary URL
        temporaryVideoURL = nil
    }
    
    // MARK: - Memo Management
    
    /// Deletes a video memo
    /// - Parameter memo: The memo to delete
    func deleteMemo(_ memo: VideoMemo) {
        // Remove the video file from disk
        try? fileManager.removeItem(at: memo.videoURL)
        
        // Remove from the array
        videoMemos.removeAll { $0.id == memo.id }
        
        // Save the updated list
        saveMemos()
    }
    
    /// Updates an existing memo's title and notes
    /// - Parameters:
    ///   - memo: The memo to update
    ///   - title: New title
    ///   - notes: New notes
    func updateMemo(_ memo: VideoMemo, title: String, notes: String) {
        // Find the index of the memo in the array
        if let index = videoMemos.firstIndex(where: { $0.id == memo.id }) {
            // Update the memo's properties
            videoMemos[index].title = title
            videoMemos[index].notes = notes
            
            // Save changes to disk
            saveMemos()
        }
    }
    
    /// Opens a memo for viewing/playback
    /// - Parameter memo: The memo to view
    func openMemo(_ memo: VideoMemo) {
        selectedMemo = memo
        showingDetailSheet = true
    }
    
    // MARK: - Persistence (Saving/Loading)
    
    /// Saves the current list of memos to disk as JSON
    private func saveMemos() {
        do {
            // Encode the array of memos to JSON data
            // JSONEncoder converts Swift objects to JSON
            let data = try JSONEncoder().encode(videoMemos)
            
            // Write the JSON data to the file
            try data.write(to: memosFileURL)
            
        } catch {
            print("Error saving memos: \(error.localizedDescription)")
        }
    }
    
    /// Loads the saved list of memos from disk
    private func loadMemos() {
        // Check if the file exists
        guard fileManager.fileExists(atPath: memosFileURL.path) else {
            print("No saved memos found")
            return
        }
        
        do {
            // Read the JSON data from the file
            let data = try Data(contentsOf: memosFileURL)
            
            // Decode the JSON data back into an array of VideoMemo objects
            // JSONDecoder converts JSON back to Swift objects
            let memos = try JSONDecoder().decode([VideoMemo].self, from: data)
            
            // Update the published property
            // This will trigger UI updates
            self.videoMemos = memos
            
        } catch {
            print("Error loading memos: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Functions
    
    /// Checks and requests camera and microphone permissions
    /// - Parameter completion: Called with true if permissions granted, false otherwise
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Camera already authorized, now check microphone
            checkMicrophonePermission(completion: completion)
            
        case .notDetermined:
            // Permission not requested yet, ask for it
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    // Camera granted, now check microphone
                    self.checkMicrophonePermission(completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
            
        default:
            // Permission denied or restricted
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    /// Checks microphone permission
    private func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        default:
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}
