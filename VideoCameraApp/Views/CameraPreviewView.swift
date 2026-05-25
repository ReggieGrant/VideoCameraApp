//
//  CameraPreviewView.swift
//  VideoCameraApp
//
//  Created by Reginald Grant on 5/25/26.
//


//  CameraPreviewView.swift
//  VideoMemoRecorder
//
//  View Component: Displays the live camera preview
//  UIViewRepresentable allows us to use UIKit views in SwiftUI
//

import SwiftUI
import AVFoundation

// MARK: - CameraPreviewView

/// CameraPreviewView displays the live camera feed in a SwiftUI view
/// UIViewRepresentable bridges between UIKit (AVCaptureVideoPreviewLayer) and SwiftUI
struct CameraPreviewView: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// The capture session from the camera service
    /// This provides the video stream to display
    let session: AVCaptureSession
    
    // MARK: - UIViewRepresentable Protocol
    
    /// Creates the UIKit view (called once when the view is created)
    /// - Parameter context: Context provided by SwiftUI
    /// - Returns: A PreviewView to display the camera feed
    func makeUIView(context: Context) -> PreviewView {
        // Create and return our custom PreviewView
        let view = PreviewView()
        view.session = session
        return view
    }
    
    /// Updates the UIKit view (called when SwiftUI state changes)
    /// - Parameters:
    ///   - uiView: The PreviewView to update
    ///   - context: Context provided by SwiftUI
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Update the session if it changed
        uiView.session = session
    }
    
    // MARK: - PreviewView (Custom UIView)
    
    /// PreviewView is a custom UIView that displays the camera preview
    /// It uses AVCaptureVideoPreviewLayer to show the camera feed
    class PreviewView: UIView {
        
        /// The capture session to display
        var session: AVCaptureSession? {
            didSet {
                // When the session is set, update the preview layer
                previewLayer.session = session
            }
        }
        
        /// Override the layerClass to use AVCaptureVideoPreviewLayer
        /// This tells UIKit to use a video preview layer instead of a regular CALayer
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        /// Computed property to access the layer as a preview layer
        /// This casts the layer to AVCaptureVideoPreviewLayer for easier access
        var previewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        /// Initialize the preview view
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupPreviewLayer()
        }
        
        /// Required initializer for NSCoding (not used but required by UIKit)
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupPreviewLayer()
        }
        
        /// Configures the preview layer settings
        private func setupPreviewLayer() {
            // Set the video gravity to resize aspect fill
            // This makes the preview fill the entire view while maintaining aspect ratio
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}
