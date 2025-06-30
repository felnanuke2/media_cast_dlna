package br.com.felnanuke2.media_cast_dlna.core

import MediaMetadata
import android.util.Log
import org.jupnp.support.model.DIDLContent
import org.jupnp.support.model.ProtocolInfo
import org.jupnp.support.model.Res
import org.jupnp.support.model.item.VideoItem
import org.jupnp.support.contentdirectory.DIDLParser
import java.net.URI

class DefaultDidlMetadataConverter : DidlMetadataConverter {
    override fun toDidlLite(metadata: MediaMetadata, uri: String): String {
        // TODO: Implement conversion from MediaMetadata to DIDL-Lite XML string
        // For now, fallback to a default metadata
        return try {
            val didl = DIDLContent()
            val resource = Res(ProtocolInfo("http-get:*:video/mp4:*"), null, uri)
            val videoItem = VideoItem("1", "0", "Media", "Unknown")
            videoItem.addResource(resource)
            didl.addItem(videoItem)
            DIDLParser().generate(didl)
        } catch (e: Exception) {
            Log.e("DidlMetadataConverter", "Error generating DIDL metadata", e)
            ""
        }
    }
}
