import Foundation
import os.log

class SOAPClient {
    
    // MARK: - Properties
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "SOAPClient")
    private let session: URLSession
    
    // MARK: - Initialization
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - SOAP Request Methods
    func performSOAPAction(
        serviceURL: URL,
        soapAction: String,
        action: String,
        parameters: [String: String],
        serviceType: String
    ) async throws -> [String: String] {
        
        let envelope = createSOAPEnvelope(
            action: action,
            parameters: parameters,
            serviceType: serviceType
        )
        
        var request = URLRequest(url: serviceURL)
        request.httpMethod = "POST"
        request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("\"\(soapAction)\"", forHTTPHeaderField: "SOAPAction")
        request.addValue(String(envelope.count), forHTTPHeaderField: "Content-Length")
        request.httpBody = envelope.data(using: .utf8)
        
        os_log("Sending SOAP request to %@ with action %@", log: logger, type: .info, serviceURL.absoluteString, action)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SOAPError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            os_log("SOAP request failed with status code %d", log: logger, type: .error, httpResponse.statusCode)
            throw SOAPError.httpError(httpResponse.statusCode)
        }
        
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw SOAPError.invalidResponse
        }
        
        os_log("Received SOAP response: %@", log: logger, type: .debug, responseString)
        
        return try parseSOAPResponse(responseString, action: action)
    }
    
    // MARK: - SOAP Envelope Creation
    private func createSOAPEnvelope(action: String, parameters: [String: String], serviceType: String) -> String {
        let parameterElements = parameters.map { key, value in
            "<\(key)>\(escapeXML(value))</\(key)>"
        }.joined()
        
        return """
        <?xml version="1.0" encoding="utf-8"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body>
        <u:\(action) xmlns:u="\(serviceType)">
        \(parameterElements)
        </u:\(action)>
        </s:Body>
        </s:Envelope>
        """
    }
    
    // MARK: - SOAP Response Parsing
    private func parseSOAPResponse(_ response: String, action: String) throws -> [String: String] {
        var result: [String: String] = [:]
        
        // Simple XML parsing for SOAP response
        // In a production app, you'd want to use XMLParser for more robust parsing
        
        // Look for the response wrapper
        let responseAction = "\(action)Response"
        
        if let startRange = response.range(of: "<.*:\(responseAction)[^>]*>", options: .regularExpression),
           let endRange = response.range(of: "</.*:\(responseAction)>", options: .regularExpression) {
            
            let responseBody = String(response[startRange.upperBound..<endRange.lowerBound])
            
            // Extract individual elements
            let elementPattern = "<([^>]+)>([^<]*)</[^>]+>"
            let regex = try NSRegularExpression(pattern: elementPattern, options: [])
            let matches = regex.matches(in: responseBody, options: [], range: NSRange(responseBody.startIndex..., in: responseBody))
            
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let elementName = String(responseBody[Range(match.range(at: 1), in: responseBody)!])
                    let elementValue = String(responseBody[Range(match.range(at: 2), in: responseBody)!])
                    result[elementName] = elementValue
                }
            }
        }
        
        return result
    }
    
    // MARK: - Utility Methods
    private func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - SOAP Error Types
enum SOAPError: Error {
    case invalidResponse
    case httpError(Int)
    case soapFault(String)
    case parsingError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid SOAP response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .soapFault(let fault):
            return "SOAP fault: \(fault)"
        case .parsingError(let error):
            return "Parsing error: \(error)"
        }
    }
}
