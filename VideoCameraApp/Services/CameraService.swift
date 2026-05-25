//
//  CameraService.swift
//  VideoCameraApp
//
//  Created by Reginald Grant on 5/25/26.
//


//  Service: Handles camera configuration and video recording
//  This is a separate service class to keep camera logic isolated
//

import AVFoundation
import Combine
import UIKit

// MARK: - CameraService

/// CameraService manages all camera-related functionality
/// This includes setting up the camera session, recording video, and saving files
class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    // @Published properties automatically notify views when they change
    
    /// Indicates whether the camera is currently recording
    @Published var isRecording = false
    
    /// Indicates whether the camera session is running (preview active)
    @Published var isSessionRunning = false
    
    /// Error message to display to the user if something goes wrong
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// The main camera capture session that manages data flow from inputs to outputs
    private let captureSession = AVCaptureSession()
    
    /// The output that writes video and audio to a file
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    /// Queue for managing camera operations on a background thread
    /// Camera operations should not run on the main thread to avoid blocking the UI
    private let sessionQueue = DispatchQueue(label: "com.videomemo.sessionQueue")
    
    /// Callback closure that gets called when recording finishes
    /// This allows us to pass the saved file URL back to the ViewModel
    private var recordingCompletionHandler: ((URL) -> Void)?
    
    // MARK: - Camera Setup
    
    /// Sets up the camera session with video and audio inputs
    /// This configures the camera to be ready for recording
    func setupCamera() {
        // Run setup on the background queue to avoid blocking the UI
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Begin configuration - this batches multiple configuration changes
            self.captureSession.beginConfiguration()
            
            // Set the session preset to determine quality
            // .high provides good quality while maintaining reasonable file sizes
            self.captureSession.sessionPreset = .high
            
            // Add video input (camera)
            self.setupVideoInput()
            
            // Add audio input (microphone)
            self.setupAudioInput()
            
            // Add movie file output (for saving recorded video)
            self.setupMovieOutput()
            
            // Commit all configuration changes
            self.captureSession.commitConfiguration()
            
            // Update published property on main thread (required for UI updates)
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
    
    /// Adds the video input (back camera) to the capture session
    private func setupVideoInput() {
        // Get the default video capture device (back camera)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .back) else {
            handleError("Unable to access camera")
            return
        }
        
        do {
            // Create an input from the video device
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            // Add the input to the session if possible
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                handleError("Unable to add video input")
            }
        } catch {
            handleError("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    /// Adds the audio input (microphone) to the capture session
    private func setupAudioInput() {
        // Get the default audio capture device (microphone)
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            handleError("Unable to access microphone")
            return
        }
        
        do {
            // Create an input from the audio device
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            // Add the input to the session if possible
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            } else {
                handleError("Unable to add audio input")
            }
        } catch {
            handleError("Error setting up microphone: \(error.localizedDescription)")
        }
    }
    
    /// Adds the movie file output to the capture session
    /// This output writes the recorded video to a file
    private func setupMovieOutput() {
        let output = AVCaptureMovieFileOutput()
        
        // Add the output to the session if possible
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            self.movieFileOutput = output
        } else {
            handleError("Unable to add movie output")
        }
    }
    
    // MARK: - Session Control
    
    /// Starts the camera preview session
    /// Call this when the camera view appears
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only start if not already running
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    /// Stops the camera preview session
    /// Call this when the camera view disappears to save battery
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only stop if currently running
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    /// Returns the capture session for displaying in a preview layer
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    
    // MARK: - Recording Control
    
    /// Starts recording a video
    /// - Parameter completion: Closure called when recording finishes with the video URL
    func startRecording(completion: @escaping (URL) -> Void) {
        // Store the completion handler to call later
        self.recordingCompletionHandler = completion
        
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let movieOutput = self.movieFileOutput else { return }
            
            // Generate a unique filename for this video
            let fileName = "video_\(UUID().uuidString).mov"
            
            // Get the temporary directory to store the video initially
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            // Start recording to the file
            // self is the delegate (AVCaptureFileOutputRecordingDelegate)
            movieOutput.startRecording(to: tempURL, recordingDelegate: self)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }
    
    /// Stops the current recording
    func stopRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let movieOutput = self.movieFileOutput else { return }
            
            // Stop the recording - this will trigger the delegate method
            movieOutput.stopRecording()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handles errors by setting the error message
    /// - Parameter message: The error message to display
    private func handleError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

/// Extension to handle recording completion callbacks
extension CameraService: AVCaptureFileOutputRecordingDelegate {
    
    /// Called when the recording finishes successfully or with an error
    func fileOutput(_ output: AVCaptureFileOutput,
                   didFinishRecordingTo outputFileURL: URL,
                   from connections: [AVCaptureConnection],
                   error: Error?) {
        
        // Check if there was an error during recording
        if let error = error {
            handleError("Recording error: \(error.localizedDescription)")
            return
        }
        
        // Call the completion handler with the video URL
        // This passes the URL back to whoever started the recording
        DispatchQueue.main.async { [weak self] in
            self?.recordingCompletionHandler?(outputFileURL)
        }
    }
}
