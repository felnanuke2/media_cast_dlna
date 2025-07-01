import Foundation
import os.log

class DidlMetadataConverter {
    
    // MARK: - Properties
    private let logger = OSLog(subsystem: "media_cast_dlna", category: "MetadataConverter")
    
    // MARK: - Conversion Methods
    func toDidlLite(metadata: MediaMetadata, uri: String) throws -> String {
        os_log("Converting metadata to DIDL-Lite format", log: logger, type: .info)
        
        // Determine the type of metadata and convert accordingly
        if let audioMetadata = metadata as? AudioMetadata {
            return try convertAudioMetadata(audioMetadata, uri: uri)
        } else if let videoMetadata = metadata as? VideoMetadata {
            return try convertVideoMetadata(videoMetadata, uri: uri)
        } else if let imageMetadata = metadata as? ImageMetadata {
            return try convertImageMetadata(imageMetadata, uri: uri)
        } else {
            // Default conversion for unknown metadata types
            return try convertGenericMetadata(uri: uri)
        }
    }
    
    // MARK: - Audio Metadata Conversion
    private func convertAudioMetadata(_ metadata: AudioMetadata, uri: String) throws -> String {
        let title = metadata.title ?? "Unknown Title"
        let artist = metadata.artist ?? "Unknown Artist"
        let album = metadata.album ?? "Unknown Album"
        let genre = metadata.genre ?? ""
        let albumArtUri = metadata.albumArtUri ?? ""
        let duration = formatDuration(metadata.duration)
        let upnpClass = metadata.upnpClass ?? "object.item.audioItem.musicTrack"
        
        let didl = """
        <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">
        <item id="1" parentID="0" restricted="1">
        <dc:title>\(escapeXML(title))</dc:title>
        <upnp:artist>\(escapeXML(artist))</upnp:artist>
        <upnp:album>\(escapeXML(album))</upnp:album>
        <upnp:genre>\(escapeXML(genre))</upnp:genre>
        <upnp:class>\(upnpClass)</upnp:class>
        <res duration="\(duration)" protocolInfo="http-get:*:audio/*:*">\(escapeXML(uri))</res>
        \(albumArtUri.isEmpty ? "" : "<upnp:albumArtURI>\(escapeXML(albumArtUri))</upnp:albumArtURI>")
        </item>
        </DIDL-Lite>
        """
        
        return didl.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "  ", with: "")
    }
    
    // MARK: - Video Metadata Conversion
    private func convertVideoMetadata(_ metadata: VideoMetadata, uri: String) throws -> String {
        let title = metadata.title ?? "Unknown Title"
        let description = metadata.description ?? ""
        let genre = metadata.genre ?? ""
        let resolution = metadata.resolution ?? ""
        let duration = formatDuration(metadata.duration)
        let thumbnailUri = metadata.thumbnailUri ?? ""
        let upnpClass = metadata.upnpClass ?? "object.item.videoItem"
        
        let didl = """
        <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">
        <item id="1" parentID="0" restricted="1">
        <dc:title>\(escapeXML(title))</dc:title>
        <dc:description>\(escapeXML(description))</dc:description>
        <upnp:genre>\(escapeXML(genre))</upnp:genre>
        <upnp:class>\(upnpClass)</upnp:class>
        <res duration="\(duration)" resolution="\(resolution)" protocolInfo="http-get:*:video/*:*">\(escapeXML(uri))</res>
        \(thumbnailUri.isEmpty ? "" : "<upnp:icon>\(escapeXML(thumbnailUri))</upnp:icon>")
        </item>
        </DIDL-Lite>
        """
        
        return didl.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "  ", with: "")
    }
    
    // MARK: - Image Metadata Conversion
    private func convertImageMetadata(_ metadata: ImageMetadata, uri: String) throws -> String {
        let title = metadata.title ?? "Unknown Image"
        let description = metadata.description ?? ""
        let resolution = metadata.resolution ?? ""
        let upnpClass = metadata.upnpClass ?? "object.item.imageItem"
        
        let didl = """
        <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">
        <item id="1" parentID="0" restricted="1">
        <dc:title>\(escapeXML(title))</dc:title>
        <dc:description>\(escapeXML(description))</dc:description>
        <upnp:class>\(upnpClass)</upnp:class>
        <res resolution="\(resolution)" protocolInfo="http-get:*:image/*:*">\(escapeXML(uri))</res>
        </item>
        </DIDL-Lite>
        """
        
        return didl.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "  ", with: "")
    }
    
    // MARK: - Generic Metadata Conversion
    private func convertGenericMetadata(uri: String) throws -> String {
        let didl = """
        <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">
        <item id="1" parentID="0" restricted="1">
        <dc:title>Media Content</dc:title>
        <upnp:class>object.item</upnp:class>
        <res protocolInfo="http-get:*:*:*">\(escapeXML(uri))</res>
        </item>
        </DIDL-Lite>
        """
        
        return didl.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "  ", with: "")
    }
    
    // MARK: - Subtitle Integration
    func toDidlLiteWithSubtitles(metadata: MediaMetadata, uri: String, subtitleTracks: [SubtitleTrack]) throws -> String {
        os_log("Converting metadata with subtitles to DIDL-Lite format", log: logger, type: .info)
        
        var baseDidl = try toDidlLite(metadata: metadata, uri: uri)
        
        // Add subtitle resources to DIDL-Lite
        let subtitleResources = subtitleTracks.map { track in
            """
            <res protocolInfo="http-get:*:\(track.mimeType):*">\(escapeXML(track.uri))</res>
            """
        }.joined()
        
        // Insert subtitle resources before closing item tag
        if let insertIndex = baseDidl.range(of: "</item>") {
            baseDidl.insert(contentsOf: subtitleResources, at: insertIndex.lowerBound)
        }
        
        return baseDidl
    }
    
    // MARK: - Utility Methods
    private func formatDuration(_ duration: Int64?) -> String {
        guard let duration = duration, duration > 0 else {
            return "00:00:00"
        }
        
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
