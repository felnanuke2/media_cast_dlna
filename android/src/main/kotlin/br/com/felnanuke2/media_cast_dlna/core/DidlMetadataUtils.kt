package br.com.felnanuke2.media_cast_dlna.core

import AudioMetadata
import ImageMetadata
import MediaMetadata
import SubtitleTrack
import VideoMetadata
import android.util.Log
import org.jupnp.support.model.DIDLContent
import org.jupnp.support.model.ProtocolInfo
import org.jupnp.support.model.Res
import org.jupnp.support.model.item.VideoItem
import org.jupnp.support.model.item.ImageItem
import org.jupnp.support.model.item.MusicTrack
import org.jupnp.support.contentdirectory.DIDLParser
import org.jupnp.support.model.DIDLObject
import org.jupnp.support.model.PersonWithRole
import java.net.URI
import java.util.*

/**
 * Utility to create DIDL-Lite metadata for DLNA media items with comprehensive metadata support.
 */
public fun createDefaultMetadata(
    uri: String,
    title: String,
    metadata: MediaMetadata? = null,
    mimeType: String? = null
): String {
    return try {
        val didl = DIDLContent()
        val itemId = UUID.randomUUID().toString()
        val parentId = "0"

        when (metadata) {
            is AudioMetadata -> {
                createAudioItem(didl, itemId, parentId, uri, title, metadata, mimeType)
            }

            is VideoMetadata -> {
                createVideoItem(didl, itemId, parentId, uri, title, metadata, mimeType, null)
            }

            is ImageMetadata -> {
                createImageItem(didl, itemId, parentId, uri, title, metadata, mimeType)
            }

            else -> {
                // Fallback based on MIME type or default to audio
                when {
                    mimeType?.startsWith("video/") == true -> {
                        createVideoItem(didl, itemId, parentId, uri, title, null, mimeType, null)
                    }
                    mimeType?.startsWith("image/") == true -> {
                        createImageItem(didl, itemId, parentId, uri, title, null, mimeType)
                    }
                    else -> {
                        createAudioItem(didl, itemId, parentId, uri, title, null, mimeType)
                    }
                }
            }
        }
        DIDLParser().generate(didl)
    } catch (e: Exception) {
        Log.e("MediaCastDlna", "Error generating DIDL metadata", e)
        ""
    }
}

/**
 * Creates an audio item with minimal, compatible metadata
 */
private fun createAudioItem(
    didl: DIDLContent,
    itemId: String,
    parentId: String,
    uri: String,
    title: String,
    metadata: AudioMetadata?,
    mimeType: String?
) {
    // Use the most basic, compatible setup
    val audioMimeType = mimeType ?: "audio/mpeg" // Default to MP3 for maximum compatibility
    
    // Create resource with minimal protocol info
    val resource = Res(
        ProtocolInfo("http-get:*:$audioMimeType:*"),
        null, // No duration for simplicity
        uri
    )

    // Create MusicTrack with the full constructor for maximum compatibility
    val artist = metadata?.artist ?: "Unknown Artist"
    val album = metadata?.album ?: "Unknown Album"
    
    val audioItem = MusicTrack(
        itemId,
        parentId,
        title,
        artist,  // creator
        album,   // album
        artist,  // artist
        resource // resource
    )

    // Set the standard UPnP class
    audioItem.clazz = DIDLObject.Class("object.item.audioItem.musicTrack")

    // Add album art if available
    metadata?.albumArtUri?.let { albumArtUri ->
        try {
            audioItem.addProperty(DIDLObject.Property.UPNP.ALBUM_ART_URI(URI.create(albumArtUri)))
            Log.d("MediaCastDlna", "  Album Art: $albumArtUri")
        } catch (e: Exception) {
            Log.w("MediaCastDlna", "Invalid album art URI: $albumArtUri", e)
        }
    }

    didl.addItem(audioItem)
    
    // Log the essential info
    Log.d("MediaCastDlna", "Created simple audio DIDL item:")
    Log.d("MediaCastDlna", "  Title: $title")
    Log.d("MediaCastDlna", "  URI: $uri")
    Log.d("MediaCastDlna", "  MIME Type: $audioMimeType")
    Log.d("MediaCastDlna", "  Artist: $artist")
    Log.d("MediaCastDlna", "  Album: $album")
    if (metadata?.albumArtUri != null) {
        Log.d("MediaCastDlna", "  Album Art: ${metadata.albumArtUri}")
    }
}

/**
 * Creates a video item with comprehensive metadata support including subtitle tracks
 */
private fun createVideoItem(
    didl: DIDLContent,
    itemId: String,
    parentId: String,
    uri: String,
    title: String,
    metadata: VideoMetadata?,
    mimeType: String?,
    subtitleTracks: List<SubtitleTrack>? = null
) {
    val videoMimeType = mimeType ?: detectVideoMimeType(uri)
    val protocolInfo = "http-get:*:$videoMimeType:*"

    val resource = Res(
        ProtocolInfo(protocolInfo),
        metadata?.duration?.toLong(),
        uri
    )

    // Set bitrate if available
    metadata?.bitrate?.let { resource.bitrate = it.toLong() }

    val videoItem = VideoItem(itemId, parentId, title, "Unknown")
    videoItem.addResource(resource)

    // Add subtitle tracks as additional resources
    subtitleTracks?.forEach { subtitleTrack ->
        val protocolInfoString = "http-get:*:${subtitleTrack.mimeType}:DLNA.ORG_PN=TEXT_SRT"
        val subtitleResource = Res(
            ProtocolInfo(protocolInfoString),
            null, // Subtitle files don't have duration
            subtitleTrack.uri
        )
        
        videoItem.addResource(subtitleResource)
        
        Log.d("MediaCastDlna", "  Added subtitle track: ${subtitleTrack.language} - ${subtitleTrack.uri}")
    }

    // Set metadata properties based on Pigeon definition
    metadata?.let { meta ->
        meta.description?.let { videoItem.description = it }
        meta.genre?.let { videoItem.addProperty(DIDLObject.Property.UPNP.GENRE(it)) }
        meta.resolution?.let {
            // Set resolution as resource property instead
            try {
                val resolutionParts = it.split("x")
                if (resolutionParts.size == 2) {
                    resource.resolution = "${resolutionParts[0]}x${resolutionParts[1]}"
                } else {
                    Log.w("MediaCastDlna", "Invalid resolution format: $it")
                }
            } catch (e: Exception) {
                Log.w("MediaCastDlna", "Invalid resolution format: $it", e)
            }
        }
        meta.thumbnailUri?.let {
            try {
                videoItem.addProperty(DIDLObject.Property.UPNP.ALBUM_ART_URI(URI.create(it)))
            } catch (e: Exception) {
                Log.w("MediaCastDlna", "Invalid thumbnail URI: $it", e)
            }
        }
        meta.upnpClass?.let {
            videoItem.clazz = DIDLObject.Class(it)
        } ?: run {
            videoItem.clazz = DIDLObject.Class("object.item.videoItem")
        }
    } ?: run {
        // Default UPnP class for video
        videoItem.clazz = DIDLObject.Class("object.item.videoItem")
    }

    didl.addItem(videoItem)
    
    Log.d("MediaCastDlna", "Created video DIDL item with ${subtitleTracks?.size ?: 0} subtitle tracks")
}

/**
 * Creates an image item with comprehensive metadata support
 */
private fun createImageItem(
    didl: DIDLContent,
    itemId: String,
    parentId: String,
    uri: String,
    title: String,
    metadata: ImageMetadata?,
    mimeType: String?
) {
    val imageMimeType = mimeType ?: detectImageMimeType(uri)
    val protocolInfo = "http-get:*:$imageMimeType:*"

    val resource = Res(ProtocolInfo(protocolInfo), null, uri)

    val imageItem = ImageItem(itemId, parentId, title, "Unknown")
    imageItem.addResource(resource)

    // Set metadata properties based on Pigeon definition
    metadata?.let { meta ->
        meta.description?.let { imageItem.description = it }
        meta.resolution?.let {
            // Set resolution as resource property for images too
            try {
                val resolutionParts = it.split("x")
                if (resolutionParts.size == 2) {
                    resource.resolution = "${resolutionParts[0]}x${resolutionParts[1]}"
                } else {
                    Log.w("MediaCastDlna", "Invalid resolution format: $it")
                }
            } catch (e: Exception) {
                Log.w("MediaCastDlna", "Invalid resolution format: $it", e)
            }
        }
        meta.date?.let {
            imageItem.addProperty(DIDLObject.Property.DC.DATE(it))
        }
        meta.thumbnailUri?.let {
            try {
                imageItem.addProperty(DIDLObject.Property.UPNP.ALBUM_ART_URI(URI.create(it)))
            } catch (e: Exception) {
                Log.w("MediaCastDlna", "Invalid thumbnail URI: $it", e)
            }
        }
        meta.upnpClass?.let {
            imageItem.clazz = DIDLObject.Class(it)
        } ?: run {
            imageItem.clazz = DIDLObject.Class("object.item.imageItem")
        }
    } ?: run {
        // Default UPnP class for image
        imageItem.clazz = DIDLObject.Class("object.item.imageItem")
    }

    didl.addItem(imageItem)
}

/**
 * Detects MIME type for audio files based on URI extension
 */
private fun detectAudioMimeType(uri: String): String {
    return when (uri.substringAfterLast('.').lowercase()) {
        "mp3" -> "audio/mpeg"
        "wav" -> "audio/wav"
        "flac" -> "audio/flac"
        "aac" -> "audio/aac"
        "m4a" -> "audio/mp4"
        "ogg" -> "audio/ogg"
        "wma" -> "audio/x-ms-wma"
        else -> "audio/mpeg" // Default to MP3
    }
}

/**
 * Detects MIME type for video files based on URI extension
 */
private fun detectVideoMimeType(uri: String): String {
    return when (uri.substringAfterLast('.').lowercase()) {
        "mp4" -> "video/mp4"
        "avi" -> "video/x-msvideo"
        "mkv" -> "video/x-matroska"
        "mov" -> "video/quicktime"
        "wmv" -> "video/x-ms-wmv"
        "flv" -> "video/x-flv"
        "webm" -> "video/webm"
        "m4v" -> "video/mp4"
        else -> "video/mp4" // Default to MP4
    }
}

/**
 * Detects MIME type for image files based on URI extension
 */
private fun detectImageMimeType(uri: String): String {
    return when (uri.substringAfterLast('.').lowercase()) {
        "jpg", "jpeg" -> "image/jpeg"
        "png" -> "image/png"
        "gif" -> "image/gif"
        "bmp" -> "image/bmp"
        "webp" -> "image/webp"
        "tiff", "tif" -> "image/tiff"
        else -> "image/jpeg" // Default to JPEG
    }
}

/**
 * Backward compatibility function - delegates to the enhanced version
 */
@Deprecated(
    "Use createDefaultMetadata with mimeType parameter for better MIME type detection",
    ReplaceWith("createDefaultMetadata(uri, title, metadata, null)")
)
public fun createDefaultMetadata(
    uri: String,
    title: String,
    metadata: MediaMetadata? = null
): String {
    return createDefaultMetadata(uri, title, metadata, null)
}

/**
 * Parses DIDL-Lite metadata string back into MediaMetadata objects
 * This implementation safely extracts all available properties from the item.properties collection
 * 
 * @param didlMetadata The DIDL-Lite XML metadata string
 * @param enableDebugLogging If true, logs all available properties for debugging
 */
public fun parseMediaMetadataFromDidl(didlMetadata: String?, enableDebugLogging: Boolean = false): MediaMetadata? {
    if (didlMetadata.isNullOrBlank()) {
        return null
    }
    
    return try {
        val parser = DIDLParser()
        val didl = parser.parse(didlMetadata)
        
        if (didl.items.isEmpty()) {
            return null
        }
        
        val item = didl.items[0]
        
        // Optional debug logging
        if (enableDebugLogging) {
            logItemProperties(item)
        }
        
        when (item) {
            is MusicTrack -> {
                // Extract properties safely from item.properties collection
                val album = getPropertyValue(item, "UPNP.ALBUM")
                val genre = getPropertyValue(item, "UPNP.GENRE")
                val albumArtUri = getPropertyValue(item, "UPNP.ALBUM_ART_URI")
                val description = item.description ?: getPropertyValue(item, "DC.DESCRIPTION")
                val originalTrackNumber = getPropertyValue(item, "UPNP.ORIGINAL_TRACK_NUMBER")?.toIntOrNull()
                
                // Try multiple sources for artist information
                val artist = try { 
                    item.creator 
                } catch (e: Exception) { 
                    null 
                } ?: try {
                    item.firstArtist?.name
                } catch (e: Exception) {
                    null
                } ?: getPropertyValue(item, "UPNP.ARTIST")
                    ?: getPropertyValue(item, "DC.CREATOR")
                
                AudioMetadata(
                    title = item.title,
                    artist = artist,
                    album = album,
                    genre = genre,
                    duration = try {
                        item.firstResource?.duration?.let { parseTimeToSeconds(it).toLong() }
                    } catch (e: Exception) { null },
                    albumArtUri = albumArtUri,
                    description = description,
                    originalTrackNumber = originalTrackNumber?.toLong(),
                    upnpClass = try { item.clazz?.value } catch (e: Exception) { null }
                )
            }
            
            is VideoItem -> {
                // Extract properties safely from item.properties collection
                val genre = getPropertyValue(item, "UPNP.GENRE")
                val thumbnailUri = getPropertyValue(item, "UPNP.ALBUM_ART_URI")
                val description = item.description ?: getPropertyValue(item, "DC.DESCRIPTION")
                
                VideoMetadata(
                    title = item.title,
                    resolution = try { item.firstResource?.resolution } catch (e: Exception) { null },
                    duration = try {
                        item.firstResource?.duration?.let { parseTimeToSeconds(it).toLong() }
                    } catch (e: Exception) { null },
                    description = description,
                    thumbnailUri = thumbnailUri,
                    genre = genre,
                    upnpClass = try { item.clazz?.value } catch (e: Exception) { null },
                    bitrate = try { item.firstResource?.bitrate?.toLong() } catch (e: Exception) { null }
                )
            }
            
            is ImageItem -> {
                // Extract properties safely from item.properties collection
                val thumbnailUri = getPropertyValue(item, "UPNP.ALBUM_ART_URI")
                val description = item.description ?: getPropertyValue(item, "DC.DESCRIPTION")
                val date = getPropertyValue(item, "DC.DATE")
                
                ImageMetadata(
                    title = item.title,
                    resolution = try { item.firstResource?.resolution } catch (e: Exception) { null },
                    description = description,
                    thumbnailUri = thumbnailUri,
                    date = date,
                    upnpClass = try { item.clazz?.value } catch (e: Exception) { null }
                )
            }
            
            else -> {
                // For other types, create a basic audio metadata as fallback
                AudioMetadata(
                    title = item.title ?: "Unknown",
                    artist = "Unknown",
                    album = "Unknown"
                )
            }
        }
    } catch (e: Exception) {
        Log.w("MediaCastDlna", "Failed to parse DIDL metadata: $didlMetadata", e)
        // Return a basic fallback metadata
        AudioMetadata(
            title = "Unknown",
            artist = "Unknown",
            album = "Unknown"
        )
    }
}

/**
 * Backward compatible overload of parseMediaMetadataFromDidl without debug logging
 */
public fun parseMediaMetadataFromDidl(didlMetadata: String?): MediaMetadata? {
    return parseMediaMetadataFromDidl(didlMetadata, false)
}

/**
 * Helper function to safely extract property values from DIDL item properties
 */
private fun getPropertyValue(item: DIDLObject, propertyName: String): String? {
    return try {
        item.properties.find { property -> 
            property.javaClass.simpleName.contains(propertyName.substringAfter("."))
        }?.let { property ->
            // Try to get value through reflection
            try {
                val valueField = property.javaClass.getDeclaredField("value")
                valueField.isAccessible = true
                valueField.get(property)?.toString()
            } catch (e: Exception) {
                // Fallback to toString if reflection fails
                property.toString().substringAfter("=").trim()
            }
        }
    } catch (e: Exception) {
        Log.w("MediaCastDlna", "Failed to extract property $propertyName", e)
        null
    }
}

/**
 * Helper function to get all properties of a specific type from DIDL item
 */
private fun getAllPropertyValues(item: DIDLObject, propertyName: String): List<String> {
    return try {
        item.properties.filter { property -> 
            property.javaClass.simpleName.contains(propertyName.substringAfter("."))
        }.mapNotNull { property ->
            try {
                val valueField = property.javaClass.getDeclaredField("value")
                valueField.isAccessible = true
                valueField.get(property)?.toString()
            } catch (e: Exception) {
                property.toString().substringAfter("=").trim()
            }
        }
    } catch (e: Exception) {
        Log.w("MediaCastDlna", "Failed to extract properties $propertyName", e)
        emptyList()
    }
}

/**
 * Helper function to parse time to seconds
 */
private fun parseTimeToSeconds(timeString: String?): Double {
    if (timeString.isNullOrBlank() || timeString == "NOT_IMPLEMENTED") {
        return 0.0
    }
    
    return try {
        val parts = timeString.split(":")
        when (parts.size) {
            3 -> {
                val hours = parts[0].toDouble()
                val minutes = parts[1].toDouble()
                val seconds = parts[2].toDouble()
                hours * 3600 + minutes * 60 + seconds
            }
            2 -> {
                val minutes = parts[0].toDouble()
                val seconds = parts[1].toDouble()
                minutes * 60 + seconds
            }
            1 -> parts[0].toDouble()
            else -> 0.0
        }
    } catch (e: Exception) {
        0.0
    }
}

/**
 * Debug function to log all available properties of a DIDL item
 */
private fun logItemProperties(item: DIDLObject, tag: String = "MediaCastDlna") {
    try {
        Log.d(tag, "=== DIDL Item Properties Debug ===")
        Log.d(tag, "Item type: ${item.javaClass.simpleName}")
        Log.d(tag, "Title: ${item.title}")
        Log.d(tag, "ID: ${item.id}")
        Log.d(tag, "UPnP Class: ${item.clazz?.value}")
        
        Log.d(tag, "Properties count: ${item.properties.size}")
        item.properties.forEachIndexed { index, property ->
            try {
                val propertyName = property.javaClass.simpleName
                val propertyValue = try {
                    val valueField = property.javaClass.getDeclaredField("value")
                    valueField.isAccessible = true
                    valueField.get(property)?.toString() ?: "null"
                } catch (e: Exception) {
                    property.toString()
                }
                Log.d(tag, "  Property[$index]: $propertyName = $propertyValue")
            } catch (e: Exception) {
                Log.w(tag, "  Property[$index]: Error reading property", e)
            }
        }
        
        // Log resources information
        Log.d(tag, "Resources count: ${item.resources.size}")
        item.resources.forEachIndexed { index, resource ->
            Log.d(tag, "  Resource[$index]: ${resource.value} (${resource.protocolInfo})")
            resource.duration?.let { Log.d(tag, "    Duration: $it") }
            resource.resolution?.let { Log.d(tag, "    Resolution: $it") }
            resource.bitrate?.let { Log.d(tag, "    Bitrate: $it") }
        }
        
        Log.d(tag, "=== End Properties Debug ===")
    } catch (e: Exception) {
        Log.e(tag, "Error logging item properties", e)
    }
}

