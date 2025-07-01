import Foundation
import os.log

class MediaControlManager {
    
    // MARK: - Properties
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "MediaControl")
    private var deviceSessions: [String: MediaSession] = [:]
    private let soapClient = SOAPClient()
    
    // MARK: - Initialization
    func initialize() {
        os_log("MediaControlManager initialized", log: logger, type: .info)
    }
    
    // MARK: - Media URI Setting
    func setMediaUri(deviceUdn: String, uri: String, metadata: String) async throws {
        os_log("Setting media URI for device %@", log: logger, type: .info, deviceUdn)
        
        let session = getOrCreateSession(for: deviceUdn)
        try await session.setAVTransportURI(uri: uri, metadata: metadata)
        
        os_log("Media URI set successfully for device %@", log: logger, type: .info, deviceUdn)
    }
    
    func setMediaUriWithSubtitles(deviceUdn: String, uri: String, metadata: String, subtitleTracks: [SubtitleTrack]) async throws {
        os_log("Setting media URI with subtitles for device %@", log: logger, type: .info, deviceUdn)
        
        let session = getOrCreateSession(for: deviceUdn)
        
        // First set the media URI
        try await session.setAVTransportURI(uri: uri, metadata: metadata)
        
        // Then set subtitle tracks if supported
        if supportsSubtitleControl(deviceUdn: deviceUdn) && !subtitleTracks.isEmpty {
            try await session.setSubtitleTracks(subtitleTracks)
        }
        
        os_log("Media URI with subtitles set successfully for device %@", log: logger, type: .info, deviceUdn)
    }
    
    // MARK: - Subtitle Control
    func supportsSubtitleControl(deviceUdn: String) -> Bool {
        let session = getOrCreateSession(for: deviceUdn)
        return session.supportsSubtitleControl()
    }
    
    func setSubtitleTrack(deviceUdn: String, subtitleTrackId: String?) async throws {
        let session = getOrCreateSession(for: deviceUdn)
        try await session.setCurrentSubtitleTrack(trackId: subtitleTrackId)
    }
    
    func getAvailableSubtitleTracks(deviceUdn: String) -> [SubtitleTrack] {
        let session = getOrCreateSession(for: deviceUdn)
        return session.getAvailableSubtitleTracks()
    }
    
    func getCurrentSubtitleTrack(deviceUdn: String) -> SubtitleTrack? {
        let session = getOrCreateSession(for: deviceUdn)
        return session.getCurrentSubtitleTrack()
    }
    
    // MARK: - Transport Control
    func play(deviceUdn: String) async throws {
        let session = getOrCreateSession(for: deviceUdn)
        try await session.play()
    }
    
    func pause(deviceUdn: String) async throws {
        let session = getOrCreateSession(for: deviceUdn)
        try await session.pause()
    }
    
    func stop(deviceUdn: String) async throws {
        let session = getOrCreateSession(for: deviceUdn)
        try await session.stop()
    }
    
    func seek(deviceUdn: String, positionSeconds: Int64) async throws {
        let session = getOrCreateSession(for: deviceUdn)
        try await session.seek(to: positionSeconds)
    }
    
    func next(deviceUdn: String) async throws {
        let session = getOrCreateSession(for: deviceUdn)
        try await session.next()
    }
    
    func previous(deviceUdn: String) async throws {
        let session = getOrCreateSession(for: deviceUdn)
        try await session.previous()
    }
    
    // MARK: - Status Information
    func getPlaybackInfo(deviceUdn: String) -> PlaybackInfo {
        let session = getOrCreateSession(for: deviceUdn)
        return session.getPlaybackInfo()
    }
    
    func getCurrentPosition(deviceUdn: String) -> Int64 {
        let session = getOrCreateSession(for: deviceUdn)
        return session.getCurrentPosition()
    }
    
    func getTransportState(deviceUdn: String) -> TransportState {
        let session = getOrCreateSession(for: deviceUdn)
        return session.getTransportState()
    }
    
    // MARK: - Session Management
    private func getOrCreateSession(for deviceUdn: String) -> MediaSession {
        if let existingSession = deviceSessions[deviceUdn] {
            return existingSession
        }
        
        let newSession = MediaSession(deviceUdn: deviceUdn)
        deviceSessions[deviceUdn] = newSession
        return newSession
    }
}

// MARK: - Media Session
class MediaSession {
    
    // MARK: - Properties
    private let deviceUdn: String
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "MediaSession")
    private var currentSubtitleTracks: [SubtitleTrack] = []
    private var currentSubtitleTrack: SubtitleTrack?
    private let soapClient = SOAPClient()
    
    // Mock playback state
    private var currentTransportState: TransportState = .stopped
    private var currentPosition: Int64 = 0
    private var totalDuration: Int64 = 0
    
    init(deviceUdn: String) {
        self.deviceUdn = deviceUdn
    }
    
    // MARK: - Media Setting
    func setAVTransportURI(uri: String, metadata: String) async throws {
        os_log("Setting AV Transport URI for device %@", log: logger, type: .info, deviceUdn)
        
        // In a real implementation, this would make a SOAP call to the device
        // For now, we'll simulate the behavior
        try await performSOAPAction(action: "SetAVTransportURI", parameters: [
            "CurrentURI": uri,
            "CurrentURIMetaData": metadata
        ])
        
        currentTransportState = .stopped
        currentPosition = 0
    }
    
    func setSubtitleTracks(_ tracks: [SubtitleTrack]) async throws {
        currentSubtitleTracks = tracks
        
        // Set the default subtitle track if available
        if let defaultTrack = tracks.first(where: { $0.isDefault == true }) {
            try await setCurrentSubtitleTrack(trackId: defaultTrack.id)
        }
    }
    
    // MARK: - Subtitle Control
    func supportsSubtitleControl() -> Bool {
        // In a real implementation, this would check device capabilities
        // For now, assume basic subtitle support
        return true
    }
    
    func setCurrentSubtitleTrack(trackId: String?) async throws {
        if let trackId = trackId {
            // Find the track
            guard let track = currentSubtitleTracks.first(where: { $0.id == trackId }) else {
                throw PigeonError(code: "INVALID_SUBTITLE_TRACK", message: "Subtitle track not found", details: nil)
            }
            
            try await performSOAPAction(action: "SetCurrentSubtitle", parameters: [
                "SubtitleTrackId": trackId
            ])
            
            currentSubtitleTrack = track
        } else {
            // Disable subtitles
            try await performSOAPAction(action: "SetCurrentSubtitle", parameters: [
                "SubtitleTrackId": ""
            ])
            
            currentSubtitleTrack = nil
        }
    }
    
    func getAvailableSubtitleTracks() -> [SubtitleTrack] {
        return currentSubtitleTracks
    }
    
    func getCurrentSubtitleTrack() -> SubtitleTrack? {
        return currentSubtitleTrack
    }
    
    // MARK: - Transport Control
    func play() async throws {
        try await performSOAPAction(action: "Play", parameters: ["Speed": "1"])
        currentTransportState = .playing
    }
    
    func pause() async throws {
        try await performSOAPAction(action: "Pause", parameters: [:])
        currentTransportState = .paused
    }
    
    func stop() async throws {
        try await performSOAPAction(action: "Stop", parameters: [:])
        currentTransportState = .stopped
        currentPosition = 0
    }
    
    func seek(to positionSeconds: Int64) async throws {
        let timeString = formatDuration(positionSeconds)
        try await performSOAPAction(action: "Seek", parameters: [
            "Unit": "REL_TIME",
            "Target": timeString
        ])
        currentPosition = positionSeconds
    }
    
    func next() async throws {
        try await performSOAPAction(action: "Next", parameters: [:])
    }
    
    func previous() async throws {
        try await performSOAPAction(action: "Previous", parameters: [:])
    }
    
    // MARK: - Status Information
    func getPlaybackInfo() -> PlaybackInfo {
        return PlaybackInfo(
            state: currentTransportState,
            position: currentPosition,
            duration: totalDuration,
            currentTrackUri: nil,
            currentTrackMetadata: nil
        )
    }
    
    func getCurrentPosition() -> Int64 {
        return currentPosition
    }
    
    func getTransportState() -> TransportState {
        return currentTransportState
    }
    
    // MARK: - SOAP Communication
    private func performSOAPAction(action: String, parameters: [String: String]) async throws {
        os_log("Performing SOAP action %@ for device %@", log: logger, type: .info, action, deviceUdn)
        
        // In a real implementation, this would:
        // 1. Construct proper SOAP envelope
        // 2. Make HTTP POST request to device control URL
        // 3. Parse response
        // 4. Handle errors
        
        // For now, simulate a delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        
        os_log("SOAP action %@ completed for device %@", log: logger, type: .info, action, deviceUdn)
    }
    
    // MARK: - Utilities
    private func formatDuration(_ seconds: Int64) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
