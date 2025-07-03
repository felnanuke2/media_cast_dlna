import Foundation
import os.log

class DeviceDiscoveryManager {
    
    // MARK: - Properties
    private var discoveredDevices: [String: DlnaDevice] = [:]
    private var deviceServices: [String: [DlnaService]] = [:]
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "DeviceDiscovery")
    
    // MARK: - Initialization
    func initialize() {
        os_log("DeviceDiscoveryManager initialized", log: logger, type: .info)
    }
    
    // MARK: - Device Management
    func addDevice(_ device: DlnaDevice) {
        discoveredDevices[device.udn] = device
        fetchDeviceServices(for: device)
    }
    
    func removeDevice(udn: String) {
        discoveredDevices.removeValue(forKey: udn)
        deviceServices.removeValue(forKey: udn)
    }
    
    func getDiscoveredDevices() -> [DlnaDevice] {
        return Array(discoveredDevices.values)
    }
    
    func refreshDevice(deviceUdn: String) -> DlnaDevice? {
        // In a real implementation, this would re-fetch device info
        return discoveredDevices[deviceUdn]
    }
    
    // MARK: - Service Management
    func getDeviceServices(deviceUdn: String) -> [DlnaService] {
        return deviceServices[deviceUdn] ?? []
    }
    
    func hasService(deviceUdn: String, serviceType: String) -> Bool {
        guard let services = deviceServices[deviceUdn] else { return false }
        return services.contains { $0.serviceType.contains(serviceType) }
    }
    
    func isDeviceOnline(deviceUdn: String) -> Bool {
        // Check if device is still in our discovered devices registry
        guard let device = discoveredDevices[deviceUdn] else {
            os_log("Device not found in registry: %@", log: logger, type: .debug, deviceUdn)
            return false
        }
        
        // For iOS, we'll use a simple approach: check if device is in our registry
        // The UPnP library should automatically remove expired devices
        // Additional check could be added here if needed (e.g., timestamp-based expiration)
        
        os_log("Device %@ is online", log: logger, type: .debug, deviceUdn)
        return true
    }
    
    private func fetchDeviceServices(for device: DlnaDevice) {
        // Construct device description URL
        let baseUrl = "http://\(device.ipAddress):\(device.port)"
        
        // Common UPnP service paths
        let servicePaths = [
            "/description.xml",
            "/upnp/description.xml",
            "/device.xml"
        ]
        
        for path in servicePaths {
            guard let url = URL(string: baseUrl + path) else { continue }
            
            fetchServices(from: url, for: device.udn)
            break // Try the first valid URL
        }
    }
    
    private func fetchServices(from url: URL, for deviceUdn: String) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                os_log("Failed to fetch services: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
                return
            }
            
            guard let data = data else { return }
            
            self?.parseServices(data: data, for: deviceUdn)
        }
        
        task.resume()
    }
    
    private func parseServices(data: Data, for deviceUdn: String) {
        let parser = XMLParser(data: data)
        let serviceParser = ServiceDescriptionParser()
        parser.delegate = serviceParser
        
        if parser.parse() {
            deviceServices[deviceUdn] = serviceParser.services
            os_log("Found %d services for device %@", log: logger, type: .info, serviceParser.services.count, deviceUdn)
        }
    }
    
    // MARK: - Content Directory Browsing
    func browseContentDirectory(deviceUdn: String, parentId: String, startIndex: Int64, requestCount: Int64) -> [MediaItem] {
        // This is a simplified implementation
        // In a real app, you'd make SOAP calls to the ContentDirectory service
        
        guard hasService(deviceUdn: deviceUdn, serviceType: "ContentDirectory") else {
            os_log("Device %@ does not support ContentDirectory", log: logger, type: .warning, deviceUdn)
            return []
        }
        
        // Mock implementation - return empty for now
        // Real implementation would:
        // 1. Find ContentDirectory service
        // 2. Make SOAP Browse action call
        // 3. Parse DIDL-Lite response
        // 4. Convert to MediaItem objects
        
        return []
    }
    
    func searchContentDirectory(deviceUdn: String, containerId: String, searchCriteria: String, startIndex: Int64, requestCount: Int64) -> [MediaItem] {
        // This is a simplified implementation
        // In a real app, you'd make SOAP calls to the ContentDirectory service
        
        guard hasService(deviceUdn: deviceUdn, serviceType: "ContentDirectory") else {
            os_log("Device %@ does not support ContentDirectory", log: logger, type: .warning, deviceUdn)
            return []
        }
        
        // Mock implementation - return empty for now
        return []
    }
}

// MARK: - Service Description Parser
class ServiceDescriptionParser: NSObject, XMLParserDelegate {
    var services: [DlnaService] = []
    private var currentService: [String: String] = [:]
    private var currentElement: String = ""
    private var currentValue: String = ""
    private var inService = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
        
        if elementName == "service" {
            inService = true
            currentService.removeAll()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if inService && !currentValue.isEmpty {
            switch elementName {
            case "serviceType", "serviceId", "SCPDURL", "controlURL", "eventSubURL":
                currentService[elementName] = currentValue
            default:
                break
            }
        }
        
        if elementName == "service" && inService {
            // Create DlnaService from parsed data
            if let serviceType = currentService["serviceType"],
               let serviceId = currentService["serviceId"],
               let scpdUrl = currentService["SCPDURL"],
               let controlUrl = currentService["controlURL"],
               let eventSubUrl = currentService["eventSubURL"] {
                
                let service = DlnaService(
                    serviceType: serviceType,
                    serviceId: serviceId,
                    scpdUrl: scpdUrl,
                    controlUrl: controlUrl,
                    eventSubUrl: eventSubUrl
                )
                services.append(service)
            }
            inService = false
        }
        
        currentValue = ""
    }
}
