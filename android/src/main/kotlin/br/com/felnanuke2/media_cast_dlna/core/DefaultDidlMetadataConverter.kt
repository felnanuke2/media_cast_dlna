package br.com.felnanuke2.media_cast_dlna.core

import AudioMetadata
import ImageMetadata
import MediaMetadata
import VideoMetadata

class DefaultDidlMetadataConverter : DidlMetadataConverter {
    override fun toDidlLite(metadata: MediaMetadata, uri: String): String {
        // Use the comprehensive metadata utils to generate DIDL-Lite XML
        val title = when (metadata) {
            is AudioMetadata -> metadata.title ?: "Unknown Audio"
            is VideoMetadata -> metadata.title ?: "Unknown Video"
            is ImageMetadata -> metadata.title ?: "Unknown Image"
            else -> "Unknown Media"
        }

        // Detect MIME type from URI extension for better compatibility
        val mimeType = when {
            metadata is AudioMetadata -> detectMimeTypeFromUri(uri, "audio")
            metadata is VideoMetadata -> detectMimeTypeFromUri(uri, "video")
            metadata is ImageMetadata -> detectMimeTypeFromUri(uri, "image")
            else -> detectMimeTypeFromUri(uri, "audio") // Default to audio
        }

        return createDefaultMetadata(
            uri = uri,
            title = title,
            metadata = metadata,
            mimeType = mimeType
        )
    }

    private fun detectMimeTypeFromUri(uri: String, mediaType: String): String {
        val extension = uri.substringAfterLast('.').lowercase()
        return when (mediaType) {
            "audio" -> when (extension) {
                "mp3" -> "audio/mpeg"
                "wav" -> "audio/wav"
                "flac" -> "audio/flac"
                "aac" -> "audio/aac"
                "m4a" -> "audio/mp4"
                "ogg" -> "audio/ogg"
                "wma" -> "audio/x-ms-wma"
                else -> "audio/mpeg" // Default to MP3
            }
            "video" -> when (extension) {
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
            "image" -> when (extension) {
                "jpg", "jpeg" -> "image/jpeg"
                "png" -> "image/png"
                "gif" -> "image/gif"
                "bmp" -> "image/bmp"
                "webp" -> "image/webp"
                "tiff", "tif" -> "image/tiff"
                else -> "image/jpeg" // Default to JPEG
            }
            else -> "application/octet-stream"
        }
    }
}
