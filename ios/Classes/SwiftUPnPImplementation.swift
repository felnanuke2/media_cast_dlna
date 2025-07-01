import Foundation
import UPnAtom
import os.log

class UPnAtomDeviceDiscovery {
    
    // MARK: - Properties
    weak var delegate: UPnPDeviceDiscoveryDelegate?
    private var upnpRegistry: UPnPRegistry?
    private var isDiscovering = false
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "UPnAtomDiscovery")
    private var discoveredDevices: [String: DlnaDevice] = [:]
    
    // MARK: - Discovery Control
    func startDiscovery() {
        guard !isDiscovering else {
            os_log("Discovery already in progress", log: logger, type: .info)
            return
        }
        
        os_log("Starting UPnAtom device discovery", log: logger, type: .info)
        
        // Initialize UPnP registry
        upnpRegistry = UPnPRegistry.shared
        
        // Set up device notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceWasAdded(_:)),
            name: UPnPRegistry.UPnPDeviceAddedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceWasRemoved(_:)),
            name: UPnPRegistry.UPnPDeviceRemovedNotification,
            object: nil
        )
        
        // Start discovery
        upnpRegistry?.startDiscovery()
        isDiscovering = true
    }
    
    func stopDiscovery() {
        os_log("Stopping UPnAtom device discovery", log: logger, type: .info)
        
        NotificationCenter.default.removeObserver(self)
        upnpRegistry?.stopDiscovery()
        isDiscovering = false
    }
    
    func refreshDevices() {
        guard isDiscovering else { return }
        
        // UPnAtom handles refresh automatically through SSDP
        upnpRegistry?.startBrowsing(forServices: ["urn:schemas-upnp-org:device:MediaRenderer:1"])
        upnpRegistry?.startBrowsing(forServices: ["urn:schemas-upnp-org:device:MediaServer:1"])
    }
    
    // MARK: - Notification Handlers
    @objc private func deviceWasAdded(_ notification: Notification) {
        guard let device = notification.object as? UPnPDevice else { return }
        
        os_log("UPnAtom device discovered: %@", log: logger, type: .info, device.friendlyName)
        
        let dlnaDevice = convertToDlnaDevice(device)
        
        if discoveredDevices[dlnaDevice.udn] == nil {
            discoveredDevices[dlnaDevice.udn] = dlnaDevice
            delegate?.deviceDiscovered(dlnaDevice)
        }
    }
    
    @objc private func deviceWasRemoved(_ notification: Notification) {
        guard let device = notification.object as? UPnPDevice else { return }
        
        os_log("UPnAtom device removed: %@", log: logger, type: .info, device.udn)
        
        discoveredDevices.removeValue(forKey: device.udn)
        delegate?.deviceRemoved(device.udn)
    }
    
    private func convertToDlnaDevice(_ upnpDevice: UPnPDevice) -> DlnaDevice {
        // Extract IP address and port from base URL
        var ipAddress = ""
        var port: Int64 = 80
        
        if let baseURL = upnpDevice.baseURL {
            ipAddress = baseURL.host ?? ""
            port = Int64(baseURL.port ?? 80)
        }
        
        return DlnaDevice(
            udn: upnpDevice.udn,
            friendlyName: upnpDevice.friendlyName,
            deviceType: upnpDevice.deviceType,
            manufacturerName: upnpDevice.manufacturer ?? "Unknown",
            modelName: upnpDevice.modelName ?? "Unknown",
            ipAddress: ipAddress,
            port: port,
            modelDescription: upnpDevice.modelDescription,
            presentationUrl: upnpDevice.presentationURL?.absoluteString,
            iconUrl: upnpDevice.iconURL?.absoluteString
        )
    }
    
    // MARK: - Device Access
    func getDevice(udn: String) -> UPnPDevice? {
        return upnpRegistry?.device(for: udn)
    }
    
    func getDevices() -> [UPnPDevice] {
        return upnpRegistry?.devices ?? []
    }
}

// MARK: - Enhanced Media Control Manager using UPnAtom
class UPnAtomMediaControlManager {
    
    // MARK: - Properties
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "UPnAtomMediaControl")
    private var deviceSessions: [String: UPnAtomMediaSession] = [:]
    private let discovery: UPnAtomDeviceDiscovery
    
    init(discovery: UPnAtomDeviceDiscovery) {
        self.discovery = discovery
    }
    
    // MARK: - Session Management
    private func getOrCreateSession(for deviceUdn: String) throws -> UPnAtomMediaSession {
        if let existingSession = deviceSessions[deviceUdn] {
            return existingSession
        }
        
        guard let upnpDevice = discovery.getDevice(udn: deviceUdn) else {
            throw PigeonError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil)
        }
        
        let newSession = UPnAtomMediaSession(device: upnpDevice)
        deviceSessions[deviceUdn] = newSession
        return newSession
    }
    
    // MARK: - Media Control
    func setMediaUri(deviceUdn: String, uri: String, metadata: String) async throws {
        let session = try getOrCreateSession(for: deviceUdn)
        try await session.setAVTransportURI(uri: uri, metadata: metadata)
    }
    
    func play(deviceUdn: String) async throws {
        let session = try getOrCreateSession(for: deviceUdn)
        try await session.play()
    }
    
    func pause(deviceUdn: String) async throws {
        let session = try getOrCreateSession(for: deviceUdn)
        try await session.pause()
    }
    
    func stop(deviceUdn: String) async throws {
        let session = try getOrCreateSession(for: deviceUdn)
        try await session.stop()
    }
    
    func seek(deviceUdn: String, positionSeconds: Int64) async throws {
        let session = try getOrCreateSession(for: deviceUdn)
        try await session.seek(to: positionSeconds)
    }
    
    func getPlaybackInfo(deviceUdn: String) throws -> PlaybackInfo {
        let session = try getOrCreateSession(for: deviceUdn)
        return session.getPlaybackInfo()
    }
    
    func getCurrentPosition(deviceUdn: String) throws -> Int64 {
        let session = try getOrCreateSession(for: deviceUdn)
        return session.getCurrentPosition()
    }
    
    func getTransportState(deviceUdn: String) throws -> TransportState {
        let session = try getOrCreateSession(for: deviceUdn)
        return session.getTransportState()
    }
}

// MARK: - UPnAtom Media Session
class UPnAtomMediaSession {
    
    // MARK: - Properties
    private let device: UPnPDevice
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "UPnAtomMediaSession")
    private var avTransportService: UPnPService?
    private var renderingControlService: UPnPService?
    
    // State tracking
    private var currentTransportState: TransportState = .stopped
    private var currentPosition: Int64 = 0
    private var totalDuration: Int64 = 0
    
    init(device: UPnPDevice) {
        self.device = device
        setupServices()
    }
    
    private func setupServices() {
        // Find AVTransport service
        avTransportService = device.services.first { service in
            service.serviceType.contains("AVTransport")
        }
        
        // Find RenderingControl service
        renderingControlService = device.services.first { service in
            service.serviceType.contains("RenderingControl")
        }
        
        os_log("AVTransport service: %@", log: logger, type: .info, avTransportService?.serviceType ?? "Not found")
        os_log("RenderingControl service: %@", log: logger, type: .info, renderingControlService?.serviceType ?? "Not found")
    }
    
    // MARK: - Media Control
    func setAVTransportURI(uri: String, metadata: String) async throws {
        guard let service = avTransportService else {
            throw PigeonError(code: "SERVICE_NOT_AVAILABLE", message: "AVTransport service not available", details: nil)
        }
        
        let action = service.action(named: "SetAVTransportURI")
        action?.setValue("0", forInputArgument: "InstanceID")
        action?.setValue(uri, forInputArgument: "CurrentURI")
        action?.setValue(metadata, forInputArgument: "CurrentURIMetaData")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            action?.execute { result in
                switch result {
                case .success:
                    self.currentTransportState = .stopped
                    self.currentPosition = 0
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func play() async throws {
        guard let service = avTransportService else {
            throw PigeonError(code: "SERVICE_NOT_AVAILABLE", message: "AVTransport service not available", details: nil)
        }
        
        let action = service.action(named: "Play")
        action?.setValue("0", forInputArgument: "InstanceID")
        action?.setValue("1", forInputArgument: "Speed")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            action?.execute { result in
                switch result {
                case .success:
                    self.currentTransportState = .playing
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func pause() async throws {
        guard let service = avTransportService else {
            throw PigeonError(code: "SERVICE_NOT_AVAILABLE", message: "AVTransport service not available", details: nil)
        }
        
        let action = service.action(named: "Pause")
        action?.setValue("0", forInputArgument: "InstanceID")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            action?.execute { result in
                switch result {
                case .success:
                    self.currentTransportState = .paused
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func stop() async throws {
        guard let service = avTransportService else {
            throw PigeonError(code: "SERVICE_NOT_AVAILABLE", message: "AVTransport service not available", details: nil)
        }
        
        let action = service.action(named: "Stop")
        action?.setValue("0", forInputArgument: "InstanceID")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            action?.execute { result in
                switch result {
                case .success:
                    self.currentTransportState = .stopped
                    self.currentPosition = 0
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func seek(to positionSeconds: Int64) async throws {
        guard let service = avTransportService else {
            throw PigeonError(code: "SERVICE_NOT_AVAILABLE", message: "AVTransport service not available", details: nil)
        }
        
        let timeString = formatDuration(positionSeconds)
        let action = service.action(named: "Seek")
        action?.setValue("0", forInputArgument: "InstanceID")
        action?.setValue("REL_TIME", forInputArgument: "Unit")
        action?.setValue(timeString, forInputArgument: "Target")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            action?.execute { result in
                switch result {
                case .success:
                    self.currentPosition = positionSeconds
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
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
    
    // MARK: - Utilities
    private func formatDuration(_ seconds: Int64) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
