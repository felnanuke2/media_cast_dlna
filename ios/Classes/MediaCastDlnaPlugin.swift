import Flutter
import UIKit
import Foundation
import Network
import os.log
import UPnAtom

#if canImport(Darwin)
import Darwin
#endif

#if canImport(SystemConfiguration)
import SystemConfiguration
#endif

public class MediaCastDlnaPlugin: NSObject, FlutterPlugin, MediaCastDlnaApi {
    
    // MARK: - Properties
    private var upnpDiscovery: UPnAtomDeviceDiscovery?
    private var discoveredDevices: [String: DlnaDevice] = [:]
    private var isServiceInitialized = false
    private var discoveryTimer: Timer?
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "iOS")
    
    // Managers for different functionality (using UPnAtom)
    private lazy var deviceDiscoveryManager = DeviceDiscoveryManager()
    private lazy var mediaControlManager: UPnAtomMediaControlManager = {
        return UPnAtomMediaControlManager(discovery: upnpDiscovery!)
    }()
    private lazy var volumeManager = VolumeManager()
    private lazy var metadataConverter = DidlMetadataConverter()
    
    // MARK: - Flutter Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MediaCastDlnaPlugin()
        MediaCastDlnaApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }
    
    // MARK: - Service Lifecycle
    public func initializeUpnpService() throws {
        os_log("Initializing UPnP service on iOS", log: logger, type: .info)
        
        guard !isServiceInitialized else {
            os_log("UPnP service already initialized", log: logger, type: .info)
            return
        }
        
        // Initialize UPnP discovery using UPnAtom
        upnpDiscovery = UPnAtomDeviceDiscovery()
        upnpDiscovery?.delegate = self
        
        // Initialize managers
        deviceDiscoveryManager.initialize()
        mediaControlManager.initialize()
        volumeManager.initialize()
        
        isServiceInitialized = true
        os_log("UPnP service initialized successfully", log: logger, type: .info)
    }
    
    public func isUpnpServiceInitialized() throws -> Bool {
        return isServiceInitialized
    }
    
    public func shutdownUpnpService() throws {
        os_log("Shutting down UPnP service", log: logger, type: .info)
        
        stopDiscovery()
        upnpDiscovery = nil
        discoveredDevices.removeAll()
        isServiceInitialized = false
        
        os_log("UPnP service shutdown complete", log: logger, type: .info)
    }
    
    // MARK: - Device Discovery
    // MARK: - Device Discovery
    public func startDiscovery(options: DiscoveryOptions) throws {
        guard isServiceInitialized else {
            throw PigeonError(code: "SERVICE_NOT_INITIALIZED", 
                            message: "UPnP service is not initialized", 
                            details: nil)
        }
        
        os_log("Starting device discovery", log: logger, type: .info)
        
        // Start SSDP discovery
        upnpDiscovery?.startDiscovery()
        
        // Set up periodic refresh using timeout as refresh interval
        discoveryTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(options.timeout), repeats: true) { _ in
            self.refreshDeviceList()
        }
        
        os_log("Device discovery started", log: logger, type: .info)
    }
    
    public func stopDiscovery() throws {
        os_log("Stopping device discovery", log: logger, type: .info)
        
        upnpDiscovery?.stopDiscovery()
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        
        os_log("Device discovery stopped", log: logger, type: .info)
    }
    
    public func getDiscoveredDevices() throws -> [DlnaDevice] {
        return Array(discoveredDevices.values)
    }
    
    public func refreshDevice(deviceUdn: String) throws -> DlnaDevice? {
        return deviceDiscoveryManager.refreshDevice(deviceUdn: deviceUdn)
    }
    
    public func getDeviceServices(deviceUdn: String) throws -> [DlnaService] {
        return deviceDiscoveryManager.getDeviceServices(deviceUdn: deviceUdn)
    }
    
    public func hasService(deviceUdn: String, serviceType: String) throws -> Bool {
        return deviceDiscoveryManager.hasService(deviceUdn: deviceUdn, serviceType: serviceType)
    }
    
    public func browseContentDirectory(deviceUdn: String, parentId: String, startIndex: Int64, requestCount: Int64) throws -> [MediaItem] {
        return deviceDiscoveryManager.browseContentDirectory(
            deviceUdn: deviceUdn,
            parentId: parentId,
            startIndex: startIndex,
            requestCount: requestCount
        )
    }
    
    public func searchContentDirectory(deviceUdn: String, containerId: String, searchCriteria: String, startIndex: Int64, requestCount: Int64) throws -> [MediaItem] {
        return deviceDiscoveryManager.searchContentDirectory(
            deviceUdn: deviceUdn,
            containerId: containerId,
            searchCriteria: searchCriteria,
            startIndex: startIndex,
            requestCount: requestCount
        )
    }
    
    // MARK: - Media Control
    public func setMediaUri(deviceUdn: String, uri: String, metadata: MediaMetadata, completion: @escaping (Result<Void, Error>) -> Void) {
        os_log("Setting media URI for device %@: %@", log: logger, type: .info, deviceUdn, uri)
        
        guard isServiceInitialized else {
            completion(.failure(PigeonError(code: "SERVICE_NOT_INITIALIZED", 
                                          message: "UPnP service is not initialized", 
                                          details: nil)))
            return
        }
        
        Task {
            do {
                let didlMetadata = try metadataConverter.toDidlLite(metadata: metadata, uri: uri)
                try await mediaControlManager.setMediaUri(deviceUdn: deviceUdn, uri: uri, metadata: didlMetadata)
                completion(.success(()))
            } catch {
                os_log("Failed to set media URI: %@", log: logger, type: .error, error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    public func setMediaUriWithSubtitles(deviceUdn: String, uri: String, metadata: MediaMetadata, subtitleTracks: [SubtitleTrack], completion: @escaping (Result<Void, Error>) -> Void) {
        os_log("Setting media URI with subtitles for device %@", log: logger, type: .info, deviceUdn)
        
        guard isServiceInitialized else {
            completion(.failure(PigeonError(code: "SERVICE_NOT_INITIALIZED", 
                                          message: "UPnP service is not initialized", 
                                          details: nil)))
            return
        }
        
        Task {
            do {
                let didlMetadata = try metadataConverter.toDidlLite(metadata: metadata, uri: uri)
                try await mediaControlManager.setMediaUriWithSubtitles(
                    deviceUdn: deviceUdn,
                    uri: uri,
                    metadata: didlMetadata,
                    subtitleTracks: subtitleTracks
                )
                completion(.success(()))
            } catch {
                os_log("Failed to set media URI with subtitles: %@", log: logger, type: .error, error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    public func supportsSubtitleControl(deviceUdn: String) throws -> Bool {
        return mediaControlManager.supportsSubtitleControl(deviceUdn: deviceUdn)
    }
    
    public func setSubtitleTrack(deviceUdn: String, subtitleTrackId: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await mediaControlManager.setSubtitleTrack(deviceUdn: deviceUdn, subtitleTrackId: subtitleTrackId)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func getAvailableSubtitleTracks(deviceUdn: String) throws -> [SubtitleTrack] {
        return mediaControlManager.getAvailableSubtitleTracks(deviceUdn: deviceUdn)
    }
    
    public func getCurrentSubtitleTrack(deviceUdn: String) throws -> SubtitleTrack? {
        return mediaControlManager.getCurrentSubtitleTrack(deviceUdn: deviceUdn)
    }
    
    public func play(deviceUdn: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await mediaControlManager.play(deviceUdn: deviceUdn)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func pause(deviceUdn: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await mediaControlManager.pause(deviceUdn: deviceUdn)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func stop(deviceUdn: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await mediaControlManager.stop(deviceUdn: deviceUdn)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func seek(deviceUdn: String, positionSeconds: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await mediaControlManager.seek(deviceUdn: deviceUdn, positionSeconds: positionSeconds)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func next(deviceUdn: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await mediaControlManager.next(deviceUdn: deviceUdn)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func previous(deviceUdn: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await mediaControlManager.previous(deviceUdn: deviceUdn)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Volume Control
    public func setVolume(deviceUdn: String, volume: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await volumeManager.setVolume(deviceUdn: deviceUdn, volume: volume)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func getVolumeInfo(deviceUdn: String) throws -> VolumeInfo {
        return volumeManager.getVolumeInfo(deviceUdn: deviceUdn)
    }
    
    public func setMute(deviceUdn: String, muted: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await volumeManager.setMute(deviceUdn: deviceUdn, muted: muted)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Playback Info
    public func getPlaybackInfo(deviceUdn: String) throws -> PlaybackInfo {
        return mediaControlManager.getPlaybackInfo(deviceUdn: deviceUdn)
    }
    
    public func getCurrentPosition(deviceUdn: String) throws -> Int64 {
        return mediaControlManager.getCurrentPosition(deviceUdn: deviceUdn)
    }
    
    public func getTransportState(deviceUdn: String) throws -> TransportState {
        return mediaControlManager.getTransportState(deviceUdn: deviceUdn)
    }
    
    // MARK: - Platform Info
    public func getPlatformVersion() throws -> String {
        return "iOS " + UIDevice.current.systemVersion
    }
    
    public func isUpnpAvailable() throws -> Bool {
        return true // UPnP is available on iOS
    }
    
    public func getNetworkInterfaces() throws -> [String] {
        var interfaces: [String] = []
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return interfaces }
        guard let firstAddr = ifaddr else { return interfaces }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                if !interfaces.contains(name) {
                    interfaces.append(name)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return interfaces
    }
    
    // MARK: - Private Methods
    private func refreshDeviceList() {
        upnpDiscovery?.refreshDevices()
    }
}

// MARK: - UPnP Discovery Delegate
extension MediaCastDlnaPlugin: UPnPDeviceDiscoveryDelegate {
    func deviceDiscovered(_ device: DlnaDevice) {
        discoveredDevices[device.udn] = device
        deviceDiscoveryManager.addDevice(device)
        os_log("Device discovered: %@", log: logger, type: .info, device.friendlyName)
    }
    
    func deviceRemoved(_ deviceUdn: String) {
        discoveredDevices.removeValue(forKey: deviceUdn)
        deviceDiscoveryManager.removeDevice(udn: deviceUdn)
        os_log("Device removed: %@", log: logger, type: .info, deviceUdn)
    }
}
