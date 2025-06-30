package br.com.felnanuke2.media_cast_dlna.core

import AudioMetadata
import ImageMetadata
import MediaMetadata
import VideoMetadata
import android.util.Log
import org.jupnp.support.model.DIDLContent
import org.jupnp.support.model.ProtocolInfo
import org.jupnp.support.model.Res
import org.jupnp.support.model.item.VideoItem
import org.jupnp.support.contentdirectory.DIDLParser
import java.net.URI

/**
 * Utility to create default DIDL-Lite metadata for DLNA media items.
 */
public fun createDefaultMetadata(
    uri: String, title: String, metadata: MediaMetadata? = null
): String {
    return try {
        val didl = DIDLContent()
        when (metadata) {
            is AudioMetadata -> {
                val resource =
                    Res(ProtocolInfo("http-get:*:audio/mpeg:*"), metadata.duration, uri)
                val audioItem = org.jupnp.support.model.item.MusicTrack()
                audioItem.addResource(resource)
                metadata.album?.let { audioItem.album = it }
                metadata.genre?.let {
                    audioItem.addProperty(
                        org.jupnp.support.model.DIDLObject.Property.UPNP.GENRE(
                            it
                        )
                    )
                }
                metadata.description?.let { audioItem.description = it }
                metadata.albumArtUri?.let {
                    audioItem.addProperty(
                        org.jupnp.support.model.DIDLObject.Property.UPNP.ALBUM_ART_URI(
                            URI.create(it)
                        )
                    )
                }
                didl.addItem(audioItem)
            }

            is VideoMetadata -> {
                val resource =
                    Res(ProtocolInfo("http-get:*:video/mp4:*"), metadata.duration, uri)
                val videoItem = VideoItem()
                videoItem.addResource(resource)
                metadata.description?.let { videoItem.description = it }
                metadata.thumbnailUri?.let {
                    videoItem.addProperty(
                        org.jupnp.support.model.DIDLObject.Property.UPNP.ALBUM_ART_URI(
                            URI.create(it)
                        )
                    )
                }
                didl.addItem(videoItem)
            }

            is ImageMetadata -> {
                val resource = Res(ProtocolInfo("http-get:*:image/jpeg:*"), null, uri)
                val imageItem = org.jupnp.support.model.item.ImageItem(
                    "1", "0", title, "Unknown"
                )
                imageItem.addResource(resource)
                metadata.thumbnailUri?.let {
                    imageItem.addProperty(
                        org.jupnp.support.model.DIDLObject.Property.UPNP.ALBUM_ART_URI(
                            URI.create(it)
                        )
                    )
                }
                didl.addItem(imageItem)
            }

            else -> {
                // Fallback to video item if type is unknown
                val resource = Res(ProtocolInfo("http-get:*:video/mp4:*"), null, uri)
                val videoItem = VideoItem("1", "0", title, "Unknown")
                videoItem.addResource(resource)
                didl.addItem(videoItem)
            }
        }
        DIDLParser().generate(didl)
    } catch (e: Exception) {
        Log.e("MediaCastDlna", "Error generating DIDL metadata", e)
        ""
    }
}

