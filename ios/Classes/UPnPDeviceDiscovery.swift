import Foundation
import Network
import os.log

protocol UPnPDeviceDiscoveryDelegate: AnyObject {
    func deviceDiscovered(_ device: DlnaDevice)
    func deviceRemoved(_ deviceUdn: String)
}

class UPnPDeviceDiscovery {
    
    // MARK: - Properties
    weak var delegate: UPnPDeviceDiscoveryDelegate?
    private var udpSocket: NWConnection?
    private var isDiscovering = false
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "Discovery")
    
    // SSDP Multicast address and port
    private let ssdpAddress = "239.255.255.250"
    private let ssdpPort: UInt16 = 1900
    
    // Discovery message templates
    private let msearchMessage = """
        M-SEARCH * HTTP/1.1\r
        HOST: 239.255.255.250:1900\r
        MAN: "ssdp:discover"\r
        ST: upnp:rootdevice\r
        MX: 3\r
        \r
        
        """
    
    private let mediaRendererSearchMessage = """
        M-SEARCH * HTTP/1.1\r
        HOST: 239.255.255.250:1900\r
        MAN: "ssdp:discover"\r
        ST: urn:schemas-upnp-org:device:MediaRenderer:1\r
        MX: 3\r
        \r
        
        """
    
    private let mediaServerSearchMessage = """
        M-SEARCH * HTTP/1.1\r
        HOST: 239.255.255.250:1900\r
        MAN: "ssdp:discover"\r
        ST: urn:schemas-upnp-org:device:MediaServer:1\r
        MX: 3\r
        \r
        
        """
    
    // MARK: - Discovery Control
    func startDiscovery() {
        guard !isDiscovering else {
            os_log("Discovery already in progress", log: logger, type: .info)
            return
        }
        
        os_log("Starting UPnP device discovery", log: logger, type: .info)
        
        setupUDPSocket()
        sendDiscoveryMessages()
        isDiscovering = true
    }
    
    func stopDiscovery() {
        os_log("Stopping UPnP device discovery", log: logger, type: .info)
        
        udpSocket?.cancel()
        udpSocket = nil
        isDiscovering = false
    }
    
    func refreshDevices() {
        guard isDiscovering else { return }
        sendDiscoveryMessages()
    }
    
    // MARK: - Socket Setup
    private func setupUDPSocket() {
        let host = NWEndpoint.Host(ssdpAddress)
        let port = NWEndpoint.Port(rawValue: ssdpPort)!
        
        udpSocket = NWConnection(host: host, port: port, using: .udp)
        
        udpSocket?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                os_log("UDP socket ready for discovery", log: self?.logger ?? OSLog.default, type: .info)
                self?.startReceiving()
            case .failed(let error):
                os_log("UDP socket failed: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
            case .cancelled:
                os_log("UDP socket cancelled", log: self?.logger ?? OSLog.default, type: .info)
            default:
                break
            }
        }
        
        udpSocket?.start(queue: .global(qos: .background))
    }
    
    // MARK: - Message Sending
    private func sendDiscoveryMessages() {
        sendMessage(msearchMessage)
        sendMessage(mediaRendererSearchMessage)
        sendMessage(mediaServerSearchMessage)
    }
    
    private func sendMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        udpSocket?.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                os_log("Failed to send discovery message: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
            }
        })
    }
    
    // MARK: - Message Receiving
    private func startReceiving() {
        udpSocket?.receiveMessage { [weak self] (data, context, isComplete, error) in
            if let data = data, !data.isEmpty {
                self?.processReceivedData(data)
            }
            
            if let error = error {
                os_log("Error receiving data: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
            }
            
            // Continue receiving
            if self?.isDiscovering == true {
                self?.startReceiving()
            }
        }
    }
    
    // MARK: - Response Processing
    private func processReceivedData(_ data: Data) {
        guard let response = String(data: data, encoding: .utf8) else { return }
        
        os_log("Received SSDP response: %@", log: logger, type: .debug, response)
        
        // Parse SSDP response
        if response.contains("HTTP/1.1 200 OK") {
            parseDeviceResponse(response)
        }
    }
    
    private func parseDeviceResponse(_ response: String) {
        let lines = response.components(separatedBy: .newlines)
        var headers: [String: String] = [:]
        
        // Parse headers
        for line in lines {
            let components = line.components(separatedBy: ": ")
            if components.count == 2 {
                headers[components[0].uppercased()] = components[1]
            }
        }
        
        // Extract device information
        guard let location = headers["LOCATION"],
              let usn = headers["USN"] else {
            return
        }
        
        // Fetch device description
        fetchDeviceDescription(from: location, usn: usn)
    }
    
    // MARK: - Device Description Fetching
    private func fetchDeviceDescription(from location: String, usn: String) {
        guard let url = URL(string: location) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                os_log("Failed to fetch device description: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
                return
            }
            
            guard let data = data else { return }
            
            self?.parseDeviceDescription(data: data, location: location, usn: usn)
        }
        
        task.resume()
    }
    
    private func parseDeviceDescription(data: Data, location: String, usn: String) {
        do {
            let parser = XMLParser(data: data)
            let deviceParser = DeviceDescriptionParser()
            parser.delegate = deviceParser
            
            if parser.parse(), let deviceInfo = deviceParser.deviceInfo {
                let device = createDlnaDevice(from: deviceInfo, location: location, usn: usn)
                
                DispatchQueue.main.async {
                    self.delegate?.deviceDiscovered(device)
                }
            }
        } catch {
            os_log("Failed to parse device description: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    private func createDlnaDevice(from deviceInfo: [String: String], location: String, usn: String) -> DlnaDevice {
        let url = URL(string: location)
        let host = url?.host ?? ""
        let port = url?.port ?? 80
        
        return DlnaDevice(
            udn: deviceInfo["UDN"] ?? usn,
            friendlyName: deviceInfo["friendlyName"] ?? "Unknown Device",
            deviceType: deviceInfo["deviceType"] ?? "Unknown",
            manufacturerName: deviceInfo["manufacturer"] ?? "Unknown",
            modelName: deviceInfo["modelName"] ?? "Unknown",
            ipAddress: host,
            port: Int64(port),
            modelDescription: deviceInfo["modelDescription"],
            presentationUrl: deviceInfo["presentationURL"],
            iconUrl: deviceInfo["iconURL"]
        )
    }
}

// MARK: - XML Parser for Device Description
class DeviceDescriptionParser: NSObject, XMLParserDelegate {
    var deviceInfo: [String: String] = [:]
    private var currentElement: String = ""
    private var currentValue: String = ""
    private var inDevice = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
        
        if elementName == "device" {
            inDevice = true
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if inDevice && !currentValue.isEmpty {
            switch elementName {
            case "UDN", "friendlyName", "deviceType", "manufacturer", "modelName", "modelDescription", "presentationURL":
                deviceInfo[elementName] = currentValue
            case "icon":
                // Handle icon parsing if needed
                break
            default:
                break
            }
        }
        
        if elementName == "device" {
            inDevice = false
        }
        
        currentValue = ""
    }
}
