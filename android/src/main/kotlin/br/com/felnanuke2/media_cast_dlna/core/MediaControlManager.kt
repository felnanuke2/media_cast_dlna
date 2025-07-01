package br.com.felnanuke2.media_cast_dlna.core

import PlaybackInfo
import TransportState
import SubtitleTrack
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.jupnp.android.AndroidUpnpService
import org.jupnp.model.action.ActionInvocation
import org.jupnp.model.message.UpnpResponse
import org.jupnp.model.meta.Device
import org.jupnp.model.types.UDAServiceId
import org.jupnp.support.avtransport.callback.SetAVTransportURI
import org.jupnp.support.avtransport.callback.Play
import org.jupnp.support.avtransport.callback.GetTransportInfo
import org.jupnp.support.avtransport.callback.GetPositionInfo
import org.jupnp.support.model.TransportInfo
import org.jupnp.controlpoint.ActionCallback
import org.jupnp.model.types.UnsignedIntegerFourBytes
import org.jupnp.support.contentdirectory.DIDLParser
import org.jupnp.support.model.ProtocolInfo
import org.jupnp.support.model.Res
import org.jupnp.model.meta.Service

class MediaControlManager(upnpService: AndroidUpnpService?) : BaseManager(upnpService) {
    
    /**
     * Sets media URI using coroutines for cleaner async handling
     */
    suspend fun setMediaUri(deviceUdn: String, uri: String, finalMetadata: String) {
        Log.d("MediaCastDlna", "MediaControlManager.setMediaUri called - deviceUdn: $deviceUdn")
        Log.d("MediaCastDlna", "URI: $uri")
        Log.d("MediaCastDlna", "Metadata: $finalMetadata")
        
        try {
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            Log.d("MediaCastDlna", "Found device and AVTransport service: ${device.details.friendlyName}")
            
            val controlPoint = requireUpnpService().controlPoint
            Log.d("MediaCastDlna", "Got control point, creating SetAVTransportURI callback...")
            
            val setUriCallback = object : SetAVTransportURI(avTransportService, uri, finalMetadata) {
                override fun success(invocation: ActionInvocation<*>?) {
                    Log.d("MediaCastDlna", "SetAVTransportURI successful for device $deviceUdn")
                    invocation?.let { inv ->
                        Log.d("MediaCastDlna", "Invocation details - Action: ${inv.action?.name}, Input count: ${inv.input?.size}")
                        inv.output?.forEach { output ->
                            Log.d("MediaCastDlna", "Output: ${output.argument.name} = ${output.value}")
                        }
                    }
                }
                override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                    Log.e("MediaCastDlna", "SetAVTransportURI failed for device $deviceUdn: $defaultMsg")
                    operation?.let { resp ->
                        Log.e("MediaCastDlna", "Response status: ${resp.responseDetails}")
                        Log.e("MediaCastDlna", "Response message: ${resp.statusMessage}")
                    }
                    invocation?.let { inv ->
                        Log.e("MediaCastDlna", "Failed invocation details - Action: ${inv.action?.name}")
                        inv.input?.forEach { input ->
                            Log.e("MediaCastDlna", "Input: ${input.argument.name} = ${input.value}")
                        }
                    }
                }
            }
            
            Log.d("MediaCastDlna", "Executing SetAVTransportURI callback...")
            controlPoint.executeSuspending(setUriCallback)
            Log.d("MediaCastDlna", "SetAVTransportURI execution completed")
            
            // Add a small delay to ensure the device processes the URI before play is called
            kotlinx.coroutines.delay(500)
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Exception in setMediaUri: ${e.message}", e)
            throw e
        }
    }

    /**
     * Plays media using coroutines
     */
    suspend fun play(deviceUdn: String) {
        Log.d("MediaCastDlna", "MediaControlManager.play called - deviceUdn: $deviceUdn")
        
        try {
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            Log.d("MediaCastDlna", "Found device and AVTransport service: ${device.details.friendlyName}")
            
            val controlPoint = requireUpnpService().controlPoint
            Log.d("MediaCastDlna", "Got control point, creating Play callback...")
            
            val playCallback = object : Play(avTransportService) {
                override fun success(invocation: ActionInvocation<*>?) {
                    Log.d("MediaCastDlna", "Play action successful for device $deviceUdn")
                    invocation?.let { inv ->
                        Log.d("MediaCastDlna", "Invocation details - Action: ${inv.action?.name}, Input count: ${inv.input?.size}")
                        inv.output?.forEach { output ->
                            Log.d("MediaCastDlna", "Output: ${output.argument.name} = ${output.value}")
                        }
                    }
                }
                override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                    Log.e("MediaCastDlna", "Play action failed for device $deviceUdn: $defaultMsg")
                    operation?.let { resp ->
                        Log.e("MediaCastDlna", "Response status: ${resp.responseDetails}")
                        Log.e("MediaCastDlna", "Response message: ${resp.statusMessage}")
                    }
                    invocation?.let { inv ->
                        Log.e("MediaCastDlna", "Failed invocation details - Action: ${inv.action?.name}")
                        inv.input?.forEach { input ->
                            Log.e("MediaCastDlna", "Input: ${input.argument.name} = ${input.value}")
                        }
                    }
                }
            }
            
            Log.d("MediaCastDlna", "Executing Play callback...")
            controlPoint.executeSuspending(playCallback)
            Log.d("MediaCastDlna", "Play execution completed")
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Exception in play: ${e.message}", e)
            throw e
        }
    }

    /**
     * Pauses media using coroutines with proper state checking
     */
    suspend fun pause(deviceUdn: String) {
        val (_, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
        val controlPoint = requireUpnpService().controlPoint
        
        // First check if device is playing
        val transportInfo = controlPoint.getTransportInfoSuspending(avTransportService)
        if (transportInfo?.currentTransportState != org.jupnp.support.model.TransportState.PLAYING) {
            Log.w("MediaCastDlna", "Cannot pause: Device is not in PLAYING state (current: ${transportInfo?.currentTransportState})")
            return
        }
        
        val pauseAction = avTransportService.getAction("Pause")
            ?: throw IllegalStateException("Pause action not available on device $deviceUdn")
        
        val actionInvocation = ActionInvocation(pauseAction).apply {
            setInput("InstanceID", "0")
        }
        
        val pauseCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Pause action successful for device $deviceUdn")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Pause action failed for device $deviceUdn: $defaultMsg")
            }
        }
        
        controlPoint.executeSuspending(pauseCallback)
    }

    /**
     * Stops media using coroutines with proper state checking
     */
    suspend fun stop(deviceUdn: String) {
        val (_, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
        val controlPoint = requireUpnpService().controlPoint
        
        // First check if device is already stopped
        val transportInfo = controlPoint.getTransportInfoSuspending(avTransportService)
        if (transportInfo?.currentTransportState == org.jupnp.support.model.TransportState.STOPPED) {
            Log.w("MediaCastDlna", "Cannot stop: Device is already in STOPPED state.")
            return
        }
        
        val stopAction = avTransportService.getAction("Stop")
            ?: throw IllegalStateException("Stop action not available on device $deviceUdn")
        
        val actionInvocation = ActionInvocation(stopAction).apply {
            setInput("InstanceID", "0")
        }
        
        val stopCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Stop action successful for device $deviceUdn")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Stop action failed for device $deviceUdn: $defaultMsg")
            }
        }
        
        controlPoint.executeSuspending(stopCallback)
    }

    /**
     * Seeks to a specific position using coroutines
     */
    suspend fun seek(deviceUdn: String, positionSeconds: Long) {
        val (_, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
        val controlPoint = requireUpnpService().controlPoint
        
        val seekAction = avTransportService.getAction("Seek")
            ?: throw IllegalStateException("Seek action not available on device $deviceUdn")
        
        val timeString = formatSecondsToTime(positionSeconds)
        
        val actionInvocation = ActionInvocation(seekAction).apply {
            setInput("InstanceID", UnsignedIntegerFourBytes(0))
            setInput("Unit", "REL_TIME")
            setInput("Target", timeString)
        }
        
        val seekCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Seek action successful for device $deviceUdn to $timeString")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Seek action failed for device $deviceUdn: $defaultMsg")
            }
        }
        
        controlPoint.executeSuspending(seekCallback)
    }

    /**
     * Goes to next track using coroutines
     */
    suspend fun next(deviceUdn: String) {
        val (_, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
        val controlPoint = requireUpnpService().controlPoint
        
        val nextAction = avTransportService.getAction("Next")
            ?: throw IllegalStateException("Next action not available on device $deviceUdn")
        
        val actionInvocation = ActionInvocation(nextAction).apply {
            setInput("InstanceID", UnsignedIntegerFourBytes(0))
        }
        
        val nextCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Next action successful for device $deviceUdn")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Next action failed for device $deviceUdn: $defaultMsg")
            }
        }
        
        controlPoint.executeSuspending(nextCallback)
    }

    /**
     * Goes to previous track using coroutines
     */
    suspend fun previous(deviceUdn: String) {
        val (_, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
        val controlPoint = requireUpnpService().controlPoint
        
        val previousAction = avTransportService.getAction("Previous")
            ?: throw IllegalStateException("Previous action not available on device $deviceUdn")
        
        val actionInvocation = ActionInvocation(previousAction).apply {
            setInput("InstanceID", UnsignedIntegerFourBytes(0))
        }
        
        val previousCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Previous action successful for device $deviceUdn")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Previous action failed for device $deviceUdn: $defaultMsg")
            }
        }
        
        controlPoint.executeSuspending(previousCallback)
    }
    
    /**
     * Gets current playback position using coroutines
     */
    suspend fun getCurrentPosition(deviceUdn: String): Long {
        val (_, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
        val controlPoint = requireUpnpService().controlPoint
        
        return try {
            val positionInfo = controlPoint.getPositionInfoSuspending(avTransportService)
            parseTimeToSeconds(positionInfo?.relTime).toLong()
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "GetCurrentPosition failed for device $deviceUdn", e)
            -1L
        }
    }
    
    /**
     * Gets transport state using coroutines
     */
    suspend fun getTransportState(deviceUdn: String): TransportState {
        val (_, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
        val controlPoint = requireUpnpService().controlPoint
        
        return try {
            val transportInfo = controlPoint.getTransportInfoSuspending(avTransportService)
            when (transportInfo?.currentTransportState) {
                org.jupnp.support.model.TransportState.PLAYING -> TransportState.PLAYING
                org.jupnp.support.model.TransportState.PAUSED_PLAYBACK -> TransportState.PAUSED
                org.jupnp.support.model.TransportState.STOPPED -> TransportState.STOPPED
                org.jupnp.support.model.TransportState.TRANSITIONING -> TransportState.TRANSITIONING
                org.jupnp.support.model.TransportState.NO_MEDIA_PRESENT -> TransportState.NO_MEDIA_PRESENT
                else -> TransportState.STOPPED
            }
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "GetTransportState failed for device $deviceUdn", e)
            TransportState.STOPPED
        }
    }
    
    /**
     * Gets complete playback info using coroutines (runs position and transport info queries concurrently)
     */
    suspend fun getPlaybackInfo(deviceUdn: String): PlaybackInfo = coroutineScope {
        val (_, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
        val controlPoint = requireUpnpService().controlPoint
        
        try {
            // Execute both queries concurrently for better performance
            val transportInfoDeferred = async { 
                controlPoint.getTransportInfoSuspending(avTransportService) 
            }
            val positionInfoDeferred = async { 
                controlPoint.getPositionInfoSuspending(avTransportService) 
            }
            
            val transportInfo = transportInfoDeferred.await()
            val positionInfo = positionInfoDeferred.await()
            
            val state = when (transportInfo?.currentTransportState) {
                org.jupnp.support.model.TransportState.PLAYING -> TransportState.PLAYING
                org.jupnp.support.model.TransportState.PAUSED_PLAYBACK -> TransportState.PAUSED
                org.jupnp.support.model.TransportState.STOPPED -> TransportState.STOPPED
                org.jupnp.support.model.TransportState.TRANSITIONING -> TransportState.TRANSITIONING
                org.jupnp.support.model.TransportState.NO_MEDIA_PRESENT -> TransportState.NO_MEDIA_PRESENT
                else -> TransportState.STOPPED
            }
            
            PlaybackInfo(
                state = state,
                position = parseTimeToSeconds(positionInfo?.relTime).toLong(),
                duration = parseTimeToSeconds(positionInfo?.trackDuration).toLong(),
                currentTrackUri = positionInfo?.trackURI,
                currentTrackMetadata = parseMediaMetadataFromDidl(positionInfo?.trackMetaData)
            )
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "GetPlaybackInfo failed for device $deviceUdn", e)
            PlaybackInfo(
                state = TransportState.STOPPED,
                position = 0L,
                duration = 0L,
                currentTrackUri = null,
                currentTrackMetadata = null
            )
        }
    }
    
    /**
     * High-level method to cast video (combines setMediaUri + play) using coroutines
     */
    suspend fun castVideo(deviceUdn: String, videoUrl: String, metadata: String) {
        try {
            Log.d("MediaCastDlna", "Setting media URI for device $deviceUdn...")
            setMediaUri(deviceUdn, videoUrl, metadata)
            
            Log.d("MediaCastDlna", "Starting playback for device $deviceUdn...")
            play(deviceUdn)
            
            Log.d("MediaCastDlna", "Video cast successful for device $deviceUdn")
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Failed to cast video on device $deviceUdn", e)
            throw RuntimeException("Failed to cast video: ${e.message}", e)
        }
    }
    
    /**
     * Set media URI with subtitle tracks
     */
    suspend fun setMediaUriWithSubtitles(
        deviceUdn: String, 
        uri: String, 
        finalMetadata: String,
        subtitleTracks: List<SubtitleTrack>
    ) {
        Log.d("MediaCastDlna", "MediaControlManager.setMediaUriWithSubtitles called - deviceUdn: $deviceUdn")
        Log.d("MediaCastDlna", "URI: $uri")
        Log.d("MediaCastDlna", "Subtitle tracks: ${subtitleTracks.size}")
        
        try {
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            Log.d("MediaCastDlna", "Found device and AVTransport service: ${device.details.friendlyName}")
            
            val controlPoint = requireUpnpService().controlPoint
            Log.d("MediaCastDlna", "Got control point, creating SetAVTransportURI callback...")
            
            // Enhanced metadata with subtitle information
            val enhancedMetadata = enhanceMetadataWithSubtitles(finalMetadata, subtitleTracks)
            
            val setUriCallback = object : SetAVTransportURI(avTransportService, uri, enhancedMetadata) {
                override fun success(invocation: ActionInvocation<*>?) {
                    Log.d("MediaCastDlna", "SetAVTransportURI successful for device $deviceUdn")
                }

                override fun failure(
                    invocation: ActionInvocation<*>?,
                    operation: UpnpResponse?,
                    defaultMsg: String?
                ) {
                    val errorMsg = "SetAVTransportURI failed: ${operation?.responseDetails} - $defaultMsg"
                    Log.e("MediaCastDlna", errorMsg)
                    throw RuntimeException(errorMsg)
                }
            }
            
            controlPoint.execute(setUriCallback)
            withContext(Dispatchers.IO) {
                delay(100) // Small delay to ensure action completion
            }
            
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "setMediaUriWithSubtitles failed for device $deviceUdn", e)
            throw RuntimeException("Failed to set media URI with subtitles: ${e.message}", e)
        }
    }
    
    /**
     * Check if device supports subtitle track control
     */
    private suspend fun deviceSupportsSubtitleControl(deviceUdn: String): Boolean {
        return try {
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            
            // Check if the device has SetCurrentSubtitle action
            val setSubtitleAction = avTransportService.getAction("SetCurrentSubtitle")
            val result = setSubtitleAction != null
            
            Log.d("MediaCastDlna", "Device $deviceUdn subtitle support: $result")
            result
        } catch (e: Exception) {
            Log.w("MediaCastDlna", "Could not check subtitle support for device $deviceUdn", e)
            false
        }
    }

    /**
     * Enhanced method to set media URI with subtitle support check
     */
    suspend fun setMediaUriWithSubtitlesEnhanced(
        deviceUdn: String, 
        uri: String, 
        finalMetadata: String,
        subtitleTracks: List<SubtitleTrack>
    ) {
        Log.d("MediaCastDlna", "Enhanced setMediaUriWithSubtitles called - deviceUdn: $deviceUdn")
        Log.d("MediaCastDlna", "URI: $uri")
        Log.d("MediaCastDlna", "Subtitle tracks: ${subtitleTracks.size}")
        
        try {
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            Log.d("MediaCastDlna", "Found device and AVTransport service: ${device.details.friendlyName}")
            
            val controlPoint = requireUpnpService().controlPoint
            Log.d("MediaCastDlna", "Got control point, creating SetAVTransportURI callback...")
            
            // Check if device supports subtitle control
            val supportsSubtitles = deviceSupportsSubtitleControl(deviceUdn)
            
            val metadataToUse = if (supportsSubtitles && subtitleTracks.isNotEmpty()) {
                Log.d("MediaCastDlna", "Device supports subtitles, enhancing metadata...")
                enhanceMetadataWithSubtitles(finalMetadata, subtitleTracks)
            } else {
                if (!supportsSubtitles && subtitleTracks.isNotEmpty()) {
                    Log.w("MediaCastDlna", "Device does not support subtitle control, playing without subtitles")
                }
                finalMetadata
            }
            
            val setUriCallback = object : SetAVTransportURI(avTransportService, uri, metadataToUse) {
                override fun success(invocation: ActionInvocation<*>?) {
                    Log.d("MediaCastDlna", "SetAVTransportURI successful for device $deviceUdn")
                }

                override fun failure(
                    invocation: ActionInvocation<*>?,
                    operation: UpnpResponse?,
                    defaultMsg: String?
                ) {
                    val errorMsg = "SetAVTransportURI failed: ${operation?.responseDetails} - $defaultMsg"
                    Log.e("MediaCastDlna", errorMsg)
                    throw RuntimeException(errorMsg)
                }
            }
            
            controlPoint.execute(setUriCallback)
            withContext(Dispatchers.IO) {
                delay(100) // Small delay to ensure action completion
            }
            
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Enhanced setMediaUriWithSubtitles failed for device $deviceUdn", e)
            throw RuntimeException("Failed to set media URI with subtitles: ${e.message}", e)
        }
    }

    /**
     * Enable or disable subtitle track
     */
    suspend fun setSubtitleTrack(deviceUdn: String, subtitleTrackId: String?) {
        Log.d("MediaCastDlna", "Setting subtitle track: $subtitleTrackId for device: $deviceUdn")
        
        try {
            // First check if the device supports subtitle control
            if (!deviceSupportsSubtitleControl(deviceUdn)) {
                Log.w("MediaCastDlna", "Device $deviceUdn does not support subtitle track control")
                throw UnsupportedOperationException("Device does not support subtitle track control")
            }
            
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            val controlPoint = requireUpnpService().controlPoint
            
            // Use SetCurrentSubtitle action
            val setSubtitleAction = avTransportService.getAction("SetCurrentSubtitle")!!
            
            val actionInvocation = ActionInvocation(setSubtitleAction).apply {
                setInput("InstanceID", "0")
                setInput("SubtitleURI", subtitleTrackId ?: "")
            }
            
            val callback = object : ActionCallback(actionInvocation) {
                override fun success(invocation: ActionInvocation<*>?) {
                    Log.d("MediaCastDlna", "Subtitle track set successfully")
                }

                override fun failure(
                    invocation: ActionInvocation<*>?,
                    operation: UpnpResponse?,
                    defaultMsg: String?
                ) {
                    Log.w("MediaCastDlna", "Failed to set subtitle track: $defaultMsg")
                }
            }
            
            controlPoint.execute(callback)
            
        } catch (e: UnsupportedOperationException) {
            // Re-throw UnsupportedOperationException as-is for proper handling
            throw e
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "setSubtitleTrack failed", e)
            throw RuntimeException("Failed to set subtitle track: ${e.message}", e)
        }
    }
    
    /**
     * Get available subtitle tracks for current media
     */
    suspend fun getAvailableSubtitleTracks(deviceUdn: String): List<SubtitleTrack> {
        Log.d("MediaCastDlna", "Getting available subtitle tracks for device: $deviceUdn")
        
        try {
            // First check if the device supports subtitle control
            if (!deviceSupportsSubtitleControl(deviceUdn)) {
                Log.w("MediaCastDlna", "Device $deviceUdn does not support subtitle track control")
                return emptyList()
            }
            
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            val controlPoint = requireUpnpService().controlPoint
            
            // Get current media information which may contain subtitle track info
            val positionInfo = controlPoint.getPositionInfoSuspending(avTransportService)
            val metadata = positionInfo?.trackMetaData
            
            if (metadata != null) {
                return parseSubtitleTracksFromMetadata(metadata)
            }
            
            return emptyList()
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "getAvailableSubtitleTracks failed", e)
            return emptyList()
        }
    }
    
    /**
     * Get currently active subtitle track
     */
    suspend fun getCurrentSubtitleTrack(deviceUdn: String): SubtitleTrack? {
        Log.d("MediaCastDlna", "Getting current subtitle track for device: $deviceUdn")
        
        try {
            // First check if the device supports subtitle control
            if (!deviceSupportsSubtitleControl(deviceUdn)) {
                Log.w("MediaCastDlna", "Device $deviceUdn does not support subtitle track control")
                return null
            }
            
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            val controlPoint = requireUpnpService().controlPoint
            
            // Try to get current subtitle info if the device supports it
            val getCurrentSubtitleAction = avTransportService.getAction("GetCurrentSubtitle")
            
            if (getCurrentSubtitleAction != null) {
                val actionInvocation = ActionInvocation(getCurrentSubtitleAction).apply {
                    setInput("InstanceID", "0")
                }
                
                // This would need to be implemented with a synchronous callback
                // For now, return null as most devices don't support this action
                Log.w("MediaCastDlna", "GetCurrentSubtitle action found but not implemented yet")
            }
            
            return null
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "getCurrentSubtitleTrack failed", e)
            return null
        }
    }
    
    /**
     * Parse subtitle tracks from DIDL-Lite metadata
     */
    private fun parseSubtitleTracksFromMetadata(metadata: String): List<SubtitleTrack> {
        return try {
            val parser = DIDLParser()
            val didl = parser.parse(metadata)
            
            val subtitleTracks = mutableListOf<SubtitleTrack>()
            
            if (didl.items.isNotEmpty()) {
                val item = didl.items[0]
                
                item.resources.forEachIndexed { index, resource ->
                    val mimeType = resource.protocolInfo.contentFormat
                    
                    if (mimeType.startsWith("text/")) {
                        // This is likely a subtitle track
                        val track = SubtitleTrack(
                            id = "track_$index",
                            uri = resource.value,
                            mimeType = mimeType,
                            language = extractLanguageFromResource(resource) ?: "unknown",
                            title = extractTitleFromResource(resource),
                            isDefault = index == 0
                        )
                        subtitleTracks.add(track)
                    }
                }
            }
            
            subtitleTracks
        } catch (e: Exception) {
            Log.w("MediaCastDlna", "Failed to parse subtitle tracks from metadata", e)
            emptyList()
        }
    }
    
    /**
     * Extract language code from resource metadata
     */
    private fun extractLanguageFromResource(resource: Res): String? {
        // This would need to be implemented based on how the DLNA device
        // stores language information in the resource metadata
        return null
    }
    
    /**
     * Extract title from resource metadata
     */
    private fun extractTitleFromResource(resource: Res): String? {
        // This would need to be implemented based on how the DLNA device
        // stores title information in the resource metadata
        return null
    }

    /**
     * Enhance DIDL metadata with subtitle information
     */
    private fun enhanceMetadataWithSubtitles(metadata: String, subtitleTracks: List<SubtitleTrack>): String {
        return try {
            Log.d("MediaCastDlna", "Enhancing metadata with ${subtitleTracks.size} subtitle tracks")
            
            val parser = DIDLParser()
            val didl = parser.parse(metadata)
            
            // Add subtitle resources to the first item (assuming single item)
            if (didl.items.isNotEmpty()) {
                val item = didl.items[0]
                
                subtitleTracks.forEach { track ->
                    Log.d("MediaCastDlna", "Adding subtitle track: ${track.language} - ${track.uri}")
                    
                    // Create protocol info with proper DLNA profile for subtitles
                    val protocolInfoString = when {
                        track.mimeType.contains("srt") -> "http-get:*:text/srt:DLNA.ORG_PN=TEXT_SRT"
                        track.mimeType.contains("vtt") -> "http-get:*:text/vtt:DLNA.ORG_PN=TEXT_VTT"
                        track.mimeType.contains("sub") -> "http-get:*:text/sub:*"
                        track.mimeType.contains("ass") -> "http-get:*:text/ass:*"
                        else -> "http-get:*:${track.mimeType}:*"
                    }
                    
                    val subtitleResource = Res(
                        ProtocolInfo(protocolInfoString),
                        null, // Subtitle files don't have duration
                        track.uri
                    )
                    
                    // Note: Language attribute would need custom implementation
                    // as the Res class doesn't have a setLanguage method
                    
                    item.addResource(subtitleResource)
                    Log.d("MediaCastDlna", "Added subtitle resource with protocol: $protocolInfoString")
                }
            }
            
            val enhancedMetadata = parser.generate(didl, true)
            Log.d("MediaCastDlna", "Enhanced metadata generated successfully")
            Log.v("MediaCastDlna", "Enhanced metadata: $enhancedMetadata")
            
            return enhancedMetadata
        } catch (e: Exception) {
            Log.w("MediaCastDlna", "Failed to enhance metadata with subtitles, using original", e)
            return metadata
        }
    }
    
    /**
     * Public method to check if device supports subtitle control (for debugging)
     */
    suspend fun checkDeviceSubtitleSupport(deviceUdn: String): Boolean {
        return deviceSupportsSubtitleControl(deviceUdn)
    }
    
    /**
     * Debug method to inspect device capabilities
     */
    suspend fun debugDeviceCapabilities(deviceUdn: String): Map<String, Any> {
        val debug = mutableMapOf<String, Any>()
        
        try {
            val (device, avTransportService) = requireDeviceAndService(deviceUdn, "AVTransport")
            
            // Basic device info
            debug["deviceName"] = device.details.friendlyName
            debug["deviceType"] = device.type.toString()
            debug["manufacturer"] = device.details.manufacturerDetails?.manufacturer ?: "Unknown"
            debug["modelName"] = device.details.modelDetails?.modelName ?: "Unknown"
            
            // AVTransport service actions
            val actions = avTransportService.actions.map { it.name }
            debug["availableActions"] = actions
            debug["hasSetCurrentSubtitle"] = actions.contains("SetCurrentSubtitle")
            debug["hasGetCurrentSubtitle"] = actions.contains("GetCurrentSubtitle")
            
            // Check for other subtitle-related actions
            val subtitleActions = actions.filter { it.contains("subtitle", ignoreCase = true) || it.contains("caption", ignoreCase = true) }
            debug["subtitleRelatedActions"] = subtitleActions
            
            Log.d("MediaCastDlna", "Device capabilities for $deviceUdn: $debug")
            
        } catch (e: Exception) {
            debug["error"] = e.message ?: "Unknown error"
            Log.e("MediaCastDlna", "Failed to get device capabilities for $deviceUdn", e)
        }
        
        return debug
    }
    
    /**
     * Debug method to inspect generated metadata
     */
    fun debugMetadata(originalMetadata: String, subtitleTracks: List<SubtitleTrack>): Map<String, String> {
        val debug = mutableMapOf<String, String>()
        
        try {
            debug["originalMetadata"] = originalMetadata
            debug["subtitleTracksCount"] = subtitleTracks.size.toString()
            
            if (subtitleTracks.isNotEmpty()) {
                val enhancedMetadata = enhanceMetadataWithSubtitles(originalMetadata, subtitleTracks)
                debug["enhancedMetadata"] = enhancedMetadata
                debug["metadataChanged"] = (originalMetadata != enhancedMetadata).toString()
            }
            
            // Parse and analyze the metadata
            val parser = DIDLParser()
            val didl = parser.parse(originalMetadata)
            
            if (didl.items.isNotEmpty()) {
                val item = didl.items[0]
                debug["itemTitle"] = item.title
                debug["itemClass"] = item.clazz.value
                debug["resourceCount"] = item.resources.size.toString()
                
                val resourceInfo = item.resources.mapIndexed { index, resource ->
                    "Resource $index: ${resource.protocolInfo.contentFormat} - ${resource.value}"
                }
                debug["resources"] = resourceInfo.joinToString("\n")
            }
            
            Log.d("MediaCastDlna", "Metadata debug info: $debug")
            
        } catch (e: Exception) {
            debug["error"] = e.message ?: "Unknown error"
            Log.e("MediaCastDlna", "Failed to debug metadata", e)
        }
        
        return debug
    }
}

