//
//  VideoMemo.swift
//  VideoCameraApp
//
//  Created by Reginald Grant on 5/25/26.
//


//
//  VideoMemo.swift
//  VideoMemoRecorder
//
//  Model: Represents a single video memo with its metadata
//  In MVVM, the Model contains the data structure and business objects
//

import Foundation

// MARK: - VideoMemo Model

/// VideoMemo represents a single recorded video with its associated metadata
/// Identifiable: Allows SwiftUI to uniquely identify each memo in lists
/// Codable: Enables saving/loading to/from disk (JSON serialization)
struct VideoMemo: Identifiable, Codable {
    
    // MARK: - Properties
    
    /// Unique identifier for each video memo
    /// Using UUID ensures each memo has a unique ID
    let id: UUID
    
    /// User-provided title for the video memo
    var title: String
    
    /// Optional notes/description about the video content
    var notes: String
    
    /// Date and time when the video was recorded
    let dateCreated: Date
    
    /// Filename of the video file stored in the documents directory
    /// We store the filename (not full path) because the documents directory
    /// path can change between app launches
    let videoFileName: String
    
    /// Duration of the video in seconds
    /// Optional because we may not always have this information immediately
    var duration: Double?
    
    // MARK: - Computed Properties
    
    /// Full URL path to the video file in the documents directory
    /// This is computed each time because the base documents directory path may change
    var videoURL: URL {
        // Get the documents directory for the current app
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Append the video filename to create the full path
        return documentsPath.appendingPathComponent(videoFileName)
    }
    
    /// Formatted date string for display in the UI
    /// Returns a user-friendly date format like "Jan 15, 2024 at 2:30 PM"
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // e.g., "Jan 15, 2024"
        formatter.timeStyle = .short    // e.g., "2:30 PM"
        return formatter.string(from: dateCreated)
    }
    
    /// Formatted duration string for display
    /// Converts seconds into a readable format like "1:23" (1 minute, 23 seconds)
    var formattedDuration: String {
        guard let duration = duration else {
            return "Unknown"
        }
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Initializer
    
    /// Creates a new VideoMemo instance
    /// - Parameters:
    ///   - title: The title for this video memo
    ///   - notes: Additional notes or description
    ///   - videoFileName: The filename where the video is stored
    ///   - duration: Optional duration in seconds
    init(title: String, notes: String, videoFileName: String, duration: Double? = nil) {
        self.id = UUID()  // Generate a unique ID
        self.title = title
        self.notes = notes
        self.dateCreated = Date()  // Set to current date/time
        self.videoFileName = videoFileName
        self.duration = duration
    }
}

// MARK: - Sample Data

/// Extension to provide sample data for previews and testing
extension VideoMemo {
    /// Creates sample video memos for SwiftUI previews
    /// This helps us design the UI without needing actual video files
    static var samples: [VideoMemo] {
        [
            VideoMemo(
                title: "Morning Meeting Notes",
                notes: "Discussed Q1 goals and team assignments",
                videoFileName: "sample1.mov",
                duration: 125.0
            ),
            VideoMemo(
                title: "Quick Idea",
                notes: "App feature brainstorming",
                videoFileName: "sample2.mov",
                duration: 45.0
            ),
            VideoMemo(
                title: "Recipe Tutorial",
                notes: "How to make chocolate chip cookies",
                videoFileName: "sample3.mov",
                duration: 320.0
            )
        ]
    }
}
