package br.com.felnanuke2.media_cast_dlna

import AudioMetadata
import DeviceDiscoveryApi
import DiscoveryOptions
import DlnaDevice
import DlnaService
import ImageMetadata
import MediaCastDlnaApi
import MediaItem
import MediaMetadata
import MediaRendererEventsApi
import MediaServerEventsApi
import PlaybackInfo
import TransportState
import VideoMetadata
import VolumeInfo
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.ComponentName
import android.os.IBinder
import android.util.Log
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import org.jupnp.android.AndroidUpnpService
import org.jupnp.android.AndroidUpnpServiceImpl
import org.jupnp.model.message.UpnpResponse
import org.jupnp.model.meta.Device
import org.jupnp.model.meta.Service
import org.jupnp.model.types.UDAServiceId
import org.jupnp.model.types.UDN
import org.jupnp.support.model.DIDLContent
import org.jupnp.support.model.ProtocolInfo
import org.jupnp.support.model.Res
import org.jupnp.support.model.item.VideoItem
import org.jupnp.support.contentdirectory.DIDLParser
import org.jupnp.support.avtransport.callback.SetAVTransportURI
import org.jupnp.support.avtransport.callback.Play
import org.jupnp.support.avtransport.callback.GetTransportInfo
import org.jupnp.support.avtransport.callback.GetPositionInfo
import org.jupnp.support.renderingcontrol.callback.GetVolume
import org.jupnp.support.renderingcontrol.callback.GetMute
import org.jupnp.controlpoint.ActionCallback
import org.jupnp.controlpoint.SubscriptionCallback
import org.jupnp.model.action.ActionArgumentValue
import org.jupnp.model.action.ActionInvocation
import org.jupnp.model.gena.CancelReason
import org.jupnp.model.gena.GENASubscription
import org.jupnp.model.state.StateVariableValue
import java.net.URI
import java.util.concurrent.ConcurrentHashMap
import java.util.Timer
import java.util.TimerTask


/** MediaCastDlnaPlugin */
class MediaCastDlnaPlugin : FlutterPlugin, MediaCastDlnaApi {

    private var context: Context? = null
    private var deviceDiscoveryApi: DeviceDiscoveryApi? = null
    private var mediaRendererEventsApi: MediaRendererEventsApi? = null
    private var mediaServerEventsApi: MediaServerEventsApi? = null
    private var upnpRegistryListener: UpnpRegistryListener? = null
    private var upnpService: AndroidUpnpService? = null
    private var isServiceBound = false

    // Media status monitoring
    private val activeSubscriptions = ConcurrentHashMap<String, SubscriptionCallback>()
    private val monitoringTimers = ConcurrentHashMap<String, Timer>()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            upnpService = service as AndroidUpnpService
            upnpService?.get()?.startup()
            upnpService?.registry?.addListener(upnpRegistryListener)
            isServiceBound = true
        }

        override fun onServiceDisconnected(className: ComponentName) {
            upnpService = null
            isServiceBound = false
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // Store the Android context
        context = flutterPluginBinding.applicationContext
        // Set up Pigeon API
        MediaCastDlnaApi.setUp(flutterPluginBinding.binaryMessenger, this)
        // Initialize Flutter callback APIs
        deviceDiscoveryApi = DeviceDiscoveryApi(flutterPluginBinding.binaryMessenger)
        mediaRendererEventsApi = MediaRendererEventsApi(flutterPluginBinding.binaryMessenger)
        mediaServerEventsApi = MediaServerEventsApi(flutterPluginBinding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Stop all monitoring and clean up subscriptions
        stopAllMediaMonitoring()

        // Clean up Pigeon API
        MediaCastDlnaApi.setUp(binding.binaryMessenger, null)

        // Remove registry listener before unbinding
        if (upnpService != null) {
            upnpService?.registry?.removeListener(upnpRegistryListener)
        }

        // Unbind from the UPnP service
        if (upnpService != null && context != null) {
            context?.unbindService(serviceConnection)
        }

        // Clear callback API references
        deviceDiscoveryApi = null
        mediaRendererEventsApi = null
        mediaServerEventsApi = null
        upnpRegistryListener = null
        upnpService = null
        context = null
    }

    override fun initializeUpnpService() {
        if (context == null) {
            throw IllegalStateException("Context is not available. Ensure the plugin is attached to the engine.")
        }

        // Initialize the UPnP registry listener if not already done
        if (upnpRegistryListener == null) {
            upnpRegistryListener = UpnpRegistryListener(this, deviceDiscoveryApi!!)
        }

        // Create and bind to the UPnP service
        val intent = Intent(context, AndroidUpnpServiceImpl::class.java)
        context!!.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    override fun isUpnpServiceInitialized(): Boolean {
        return upnpService != null && isServiceBound
    }

    override fun shutdownUpnpService() {
        if (upnpService != null) {
            // Remove the registry listener
            upnpService?.registry?.removeListener(upnpRegistryListener)

            // Shutdown the UPnP service properly

            // Unbind from the service
            if (context != null && isServiceBound) {
                try {
                    context!!.unbindService(serviceConnection)
                } catch (e: IllegalArgumentException) {
                    // Service was not bound, ignore
                }
                isServiceBound = false
            }
            upnpService = null
        }
    }

    override fun startDiscovery(options: DiscoveryOptions) {
        if (!isServiceBound) {
            throw IllegalStateException("UPnP service is not bound. Please ensure the service is started before calling startDiscovery.")
        }

        if (upnpService == null) {
            throw IllegalStateException("UPnP service is null. Please ensure the service is initialized before calling startDiscovery.")
        }

        // Initialize the UPnP registry listener if not already done
        if (upnpRegistryListener == null) {
            upnpRegistryListener = UpnpRegistryListener(this, deviceDiscoveryApi!!)
            upnpService?.registry?.addListener(upnpRegistryListener)
        }

        // Start discovery using the control point
        try {
            upnpService?.controlPoint?.search()
        } catch (e: Exception) {
            throw RuntimeException("Failed to start UPnP discovery: ${e.message}", e)
        }
    }

    override fun stopDiscovery() {
        // Stop device discovery but keep the service bound for potential future use
        if (upnpService != null && upnpRegistryListener != null) {
            upnpService?.registry?.removeListener(upnpRegistryListener)
            // Note: We don't unbind the service here as it might be needed for other operations
            // Use shutdownUpnpService() to completely shutdown the service
        }
    }

    override fun getDiscoveredDevices(): List<DlnaDevice> {
        TODO("Not yet implemented")
    }

    override fun refreshDevice(deviceUdn: String): DlnaDevice? {
        TODO("Not yet implemented")
    }

    override fun getDeviceServices(deviceUdn: String): List<DlnaService> {
        TODO("Not yet implemented")
    }

    override fun hasService(deviceUdn: String, serviceType: String): Boolean {
        TODO("Not yet implemented")
    }

    override fun browseContentDirectory(
        deviceUdn: String, parentId: String, startIndex: Long, requestCount: Long
    ): List<MediaItem> {
        TODO("Not yet implemented")
    }

    override fun searchContentDirectory(
        deviceUdn: String,
        containerId: String,
        searchCriteria: String,
        startIndex: Long,
        requestCount: Long
    ): List<MediaItem> {
        TODO("Not yet implemented")
    }

    override fun setMediaUri(deviceUdn: String, uri: String, metadata: MediaMetadata) {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }

        val device = findDeviceByUdn(deviceUdn)
        if (device == null) {
            throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        }

        val avTransportService = device.findService(UDAServiceId("AVTransport"))
        if (avTransportService == null) {
            throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        }

        // Convert MediaMetadata to DIDL-Lite XML string
        val finalMetadata = mediaMetadataToDidlLite(metadata, uri)

        // Set the URI using SetAVTransportURI action
        val setAVTransportURIAction =
            object : SetAVTransportURI(avTransportService, uri, finalMetadata) {
                override fun success(invocation: ActionInvocation<*>?) {
                    Log.d("MediaCastDlna", "SetAVTransportURI successful for device $deviceUdn")
                }

                override fun failure(
                    invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
                ) {
                    Log.e(
                        "MediaCastDlna",
                        "SetAVTransportURI failed for device $deviceUdn: $defaultMsg"
                    )
                    throw RuntimeException("Failed to set media URI: $defaultMsg")
                }
            }

        upnpService?.controlPoint?.execute(setAVTransportURIAction)
    }

    // Helper to convert MediaMetadata to DIDL-Lite XML string
    private fun mediaMetadataToDidlLite(metadata: MediaMetadata, uri: String): String {
        // TODO: Implement conversion from MediaMetadata to DIDL-Lite XML string
        // For now, fallback to a default metadata
        return createDefaultMetadata(uri, "Media")
    }

    override fun play(deviceUdn: String) {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }

        val device = findDeviceByUdn(deviceUdn)
        if (device == null) {
            throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        }

        val avTransportService = device.findService(UDAServiceId("AVTransport"))
        if (avTransportService == null) {
            throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        }

        // Execute play action
        val playAction = object : Play(avTransportService) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Play action successful for device $deviceUdn")
                // Start monitoring if not already started
                if (!monitoringTimers.containsKey(deviceUdn)) {
                    startMediaStatusMonitoring(deviceUdn)
                }
                // Immediately report state change
                mainHandler.post {
                    mediaRendererEventsApi?.onTransportStateChanged(
                        deviceUdn, TransportState.PLAYING
                    ) { }
                }
            }

            override fun failure(
                invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
            ) {
                Log.e("MediaCastDlna", "Play action failed for device $deviceUdn: $defaultMsg")
                mainHandler.post {
                    mediaRendererEventsApi?.onPlaybackError(
                        deviceUdn, "Failed to play media: $defaultMsg"
                    ) { }
                }
                throw RuntimeException("Failed to play media: $defaultMsg")
            }
        }

        upnpService?.controlPoint?.execute(playAction)
    }

    override fun pause(deviceUdn: String) {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }

        val device = findDeviceByUdn(deviceUdn)
        if (device == null) {
            throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        }

        val avTransportService = device.findService(UDAServiceId("AVTransport"))
        if (avTransportService == null) {
            throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        }

        // Check current transport state before pausing
        val currentState = getTransportState(deviceUdn)
        if (currentState != TransportState.PLAYING) {
            Log.w("MediaCastDlna", "Cannot pause: Device is not in PLAYING state (current: $currentState)")
            mainHandler.post {
                mediaRendererEventsApi?.onPlaybackError(
                    deviceUdn, "Cannot pause: Device is not in PLAYING state (current: $currentState)"
                ) { }
            }
            throw IllegalStateException("Cannot pause: Device is not in PLAYING state (current: $currentState)")
        }

        // Execute pause action using ActionCallback
        val pauseAction = avTransportService.getAction("Pause")
        if (pauseAction == null) {
            throw IllegalStateException("Pause action not available on device $deviceUdn")
        }

        val actionInvocation = ActionInvocation(pauseAction)
        actionInvocation.setInput("InstanceID", 0)

        val pauseCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Pause action successful for device $deviceUdn")
                // Report state change
                mainHandler.post {
                    mediaRendererEventsApi?.onTransportStateChanged(
                        deviceUdn, TransportState.PAUSED
                    ) { }
                }
            }

            override fun failure(
                invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
            ) {
                Log.e("MediaCastDlna", "Pause action failed for device $deviceUdn: $defaultMsg")
                mainHandler.post {
                    mediaRendererEventsApi?.onPlaybackError(
                        deviceUdn, "Failed to pause media: $defaultMsg"
                    ) { }
                }
                throw RuntimeException("Failed to pause media: $defaultMsg")
            }
        }

        upnpService?.controlPoint?.execute(pauseCallback)
    }

    override fun stop(deviceUdn: String) {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }

        val device = findDeviceByUdn(deviceUdn)
        if (device == null) {
            throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        }

        val avTransportService = device.findService(UDAServiceId("AVTransport"))
        if (avTransportService == null) {
            throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        }

        // Execute stop action using ActionCallback
        val stopAction = avTransportService.getAction("Stop")
        if (stopAction == null) {
            throw IllegalStateException("Stop action not available on device $deviceUdn")
        }

        val actionInvocation = ActionInvocation(stopAction)
        actionInvocation.setInput("InstanceID", 0)

        val stopCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Stop action successful for device $deviceUdn")
                // Stop monitoring and report state change
                stopMediaStatusMonitoring(deviceUdn)
                mainHandler.post {
                    mediaRendererEventsApi?.onTransportStateChanged(
                        deviceUdn, TransportState.STOPPED
                    ) { }
                }
            }

            override fun failure(
                invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
            ) {
                Log.e("MediaCastDlna", "Stop action failed for device $deviceUdn: $defaultMsg")
                mainHandler.post {
                    mediaRendererEventsApi?.onPlaybackError(
                        deviceUdn, "Failed to stop media: $defaultMsg"
                    ) { }
                }
                throw RuntimeException("Failed to stop media: $defaultMsg")
            }
        }

        upnpService?.controlPoint?.execute(stopCallback)
    }

    override fun seek(deviceUdn: String, positionSeconds: Long) {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }

        val device = findDeviceByUdn(deviceUdn)
        if (device == null) {
            throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        }

        val avTransportService = device.findService(UDAServiceId("AVTransport"))
        if (avTransportService == null) {
            throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        }

        val seekAction = avTransportService.getAction("Seek")
        if (seekAction == null) {
            throw IllegalStateException("Seek action not available on device $deviceUdn")
        }

        val actionInvocation = ActionInvocation(seekAction)
        actionInvocation.setInput("InstanceID", 0)
        actionInvocation.setInput("Unit", "REL_TIME")
        // Format seconds to HH:MM:SS
        val hours = positionSeconds / 3600
        val minutes = (positionSeconds % 3600) / 60
        val seconds = positionSeconds % 60
        val timeString = String.format("%02d:%02d:%02d", hours, minutes, seconds)
        actionInvocation.setInput("Target", timeString)

        val seekCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Seek action successful for device $deviceUdn to $timeString")
                // Optionally, notify listeners or update state here
            }

            override fun failure(
                invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
            ) {
                Log.e("MediaCastDlna", "Seek action failed for device $deviceUdn: $defaultMsg")
                mainHandler.post {
                    mediaRendererEventsApi?.onPlaybackError(
                        deviceUdn, "Failed to seek media: $defaultMsg"
                    ) { }
                }
                throw RuntimeException("Failed to seek media: $defaultMsg")
            }
        }

        upnpService?.controlPoint?.execute(seekCallback)
    }

    override fun next(deviceUdn: String) {
        TODO("Not yet implemented")
    }

    override fun previous(deviceUdn: String) {
        TODO("Not yet implemented")
    }

    override fun setVolume(deviceUdn: String, volume: Long) {
        TODO("Not yet implemented")
    }

    override fun getVolumeInfo(deviceUdn: String): VolumeInfo {
        TODO("Not yet implemented")
    }

    override fun setMute(deviceUdn: String, muted: Boolean) {
        TODO("Not yet implemented")
    }

    override fun getPlaybackInfo(deviceUdn: String): PlaybackInfo {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }

        val device = findDeviceByUdn(deviceUdn)
        if (device == null) {
            throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        }

        val avTransportService = device.findService(UDAServiceId("AVTransport"))
        if (avTransportService == null) {
            throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        }

        // Get transport state
        val state = getTransportState(deviceUdn)

        // Get position info
        var position = 0
        var duration = 0
        var currentTrackUri: String? = null
        var currentTrackMetadata: String? = null
        val semaphore = java.util.concurrent.Semaphore(0)

        val getPositionInfoAction = object : GetPositionInfo(avTransportService) {
            override fun received(
                invocation: ActionInvocation<*>?,
                positionInfo: org.jupnp.support.model.PositionInfo?
            ) {
                positionInfo?.let { info ->
                    position = parseTimeToSeconds(info.relTime)
                    duration = parseTimeToSeconds(info.trackDuration)
                    currentTrackUri = info.trackURI
                    currentTrackMetadata = info.trackMetaData
                }
                semaphore.release()
            }

            override fun failure(
                invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
            ) {
                Log.v("MediaCastDlna", "GetPositionInfo failed for device $deviceUdn: $defaultMsg")
                semaphore.release()
            }
        }

        upnpService?.controlPoint?.execute(getPositionInfoAction)
        try {
            semaphore.tryAcquire(3, java.util.concurrent.TimeUnit.SECONDS)
        } catch (e: InterruptedException) {
            Log.w("MediaCastDlna", "GetPlaybackInfo interrupted for device $deviceUdn")
        }

        return PlaybackInfo(
            state,
            position.toLong(),
            duration.toLong(),
            currentTrackUri,
            currentTrackMetadata
        )
    }

    override fun getCurrentPosition(deviceUdn: String): Long {
        TODO("Not yet implemented")
    }

    override fun getTransportState(deviceUdn: String): TransportState {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }

        val device = findDeviceByUdn(deviceUdn)
        if (device == null) {
            throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        }

        val avTransportService = device.findService(UDAServiceId("AVTransport"))
        if (avTransportService == null) {
            throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        }

        var currentState = TransportState.STOPPED
        val semaphore = java.util.concurrent.Semaphore(0)

        val getTransportInfoAction = object : GetTransportInfo(avTransportService) {
            override fun received(
                invocation: ActionInvocation<*>?,
                transportInfo: org.jupnp.support.model.TransportInfo?
            ) {
                transportInfo?.let { info ->
                    currentState = when (info.currentTransportState) {
                        org.jupnp.support.model.TransportState.PLAYING -> TransportState.PLAYING
                        org.jupnp.support.model.TransportState.PAUSED_PLAYBACK -> TransportState.PAUSED
                        org.jupnp.support.model.TransportState.STOPPED -> TransportState.STOPPED
                        org.jupnp.support.model.TransportState.TRANSITIONING -> TransportState.TRANSITIONING
                        org.jupnp.support.model.TransportState.NO_MEDIA_PRESENT -> TransportState.NO_MEDIA_PRESENT
                        else -> TransportState.STOPPED
                    }
                }
                semaphore.release()
            }

            override fun failure(
                invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
            ) {
                Log.e("MediaCastDlna", "GetTransportInfo failed for device $deviceUdn: $defaultMsg")
                semaphore.release()
            }
        }

        upnpService?.controlPoint?.execute(getTransportInfoAction)

        try {
            // Wait for response with timeout
            semaphore.tryAcquire(5, java.util.concurrent.TimeUnit.SECONDS)
        } catch (e: InterruptedException) {
            Log.w("MediaCastDlna", "GetTransportState interrupted for device $deviceUdn")
        }

        return currentState
    }

    override fun subscribeToEvents(deviceUdn: String, serviceType: String) {
        Log.d("MediaCastDlna", "Subscribing to events for device $deviceUdn, service $serviceType")

        when (serviceType.lowercase()) {
            "avtransport" -> subscribeToAVTransportEvents(deviceUdn)
            "renderingcontrol" -> subscribeToRenderingControlEvents(deviceUdn)
            else -> {
                Log.w("MediaCastDlna", "Unknown service type for subscription: $serviceType")
                throw IllegalArgumentException("Unsupported service type: $serviceType")
            }
        }
    }

    override fun unsubscribeFromEvents(deviceUdn: String, serviceType: String) {
        Log.d(
            "MediaCastDlna", "Unsubscribing from events for device $deviceUdn, service $serviceType"
        )

        // For now, we'll stop all monitoring for the device
        // In a more sophisticated implementation, we could track subscriptions per service type
        stopMediaStatusMonitoring(deviceUdn)
    }

    override fun getPlatformVersion(): String {
        TODO("Not yet implemented")
    }

    override fun isUpnpAvailable(): Boolean {
        TODO("Not yet implemented")
    }

    override fun getNetworkInterfaces(): List<String> {
        TODO("Not yet implemented")
    }

    // Helper method to find device by UDN
    private fun findDeviceByUdn(deviceUdn: String): Device<*, *, *>? {
        if (upnpService == null) return null

        val udn = UDN.valueOf(deviceUdn)
        return upnpService?.registry?.getDevice(udn, false)
    }

    // Helper method to create default DIDL metadata
    private fun createDefaultMetadata(
        uri: String, title: String, metadata: MediaMetadata? = null
    ): String {
        return try {
            val didl = DIDLContent()
            when (metadata) {
                is AudioMetadata -> {
                    val resource = Res(ProtocolInfo("http-get:*:audio/mpeg:*"), metadata.duration, uri)
                    val audioItem = org.jupnp.support.model.item.MusicTrack()
                    audioItem.addResource(resource)
                    metadata.album?.let { audioItem.album = it }
                    metadata.genre?.let {
                        audioItem.addProperty(org.jupnp.support.model.DIDLObject.Property.UPNP.GENRE(it))
                    }
                    metadata.description?.let { audioItem.description = it }
                    metadata.albumArtUri?.let {
                        audioItem.addProperty(org.jupnp.support.model.DIDLObject.Property.UPNP.ALBUM_ART_URI(
                            URI.create(it)
                        ))
                    }
                    didl.addItem(audioItem)
                }
                is VideoMetadata -> {
                    val resource = Res(ProtocolInfo("http-get:*:video/mp4:*"), metadata.duration, uri)
                    val videoItem = VideoItem()
                    videoItem.addResource(resource)
                    metadata.description?.let { videoItem.description = it }
                    metadata.thumbnailUri?.let {
                        videoItem.addProperty(org.jupnp.support.model.DIDLObject.Property.UPNP.ALBUM_ART_URI(
                            URI.create(it)
                        ))
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
                        imageItem.addProperty(org.jupnp.support.model.DIDLObject.Property.UPNP.ALBUM_ART_URI(
                            URI.create(it)
                        ))
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

    // Enhanced castVideo method that combines setMediaUri and play (like the original Java code)
    fun castVideo(deviceUdn: String, videoUrl: String, title: String) {
        if (upnpService == null) {
            Log.e("MediaCastDlna", "UPnP service is not available")
            throw IllegalStateException("UPnP service is not available")
        }

        val device = findDeviceByUdn(deviceUdn)
        if (device == null) {
            Log.e("MediaCastDlna", "Device with UDN $deviceUdn not found")
            throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        }

        val avTransportService = device.findService(UDAServiceId("AVTransport"))
        if (avTransportService == null) {
            Log.e("MediaCastDlna", "AVTransport service not found on device $deviceUdn")
            throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        }

        // Create DIDL-Lite metadata
        val metadata = createDefaultMetadata(videoUrl, title)
        if (metadata.isEmpty()) {
            Log.e("MediaCastDlna", "Failed to generate DIDL metadata")
            throw RuntimeException("Failed to generate DIDL metadata")
        }

        // 1. Set the URI
        val setAVTransportURIAction =
            object : SetAVTransportURI(avTransportService, videoUrl, metadata) {
                override fun success(invocation: ActionInvocation<*>?) {
                    Log.d("MediaCastDlna", "SetAVTransportURI successful, now starting playback")

                    // 2. Play the media (chained after successful URI setting)
                    val playAction = object : Play(avTransportService) {
                        override fun success(invocation: ActionInvocation<*>?) {
                            Log.d(
                                "MediaCastDlna",
                                "Playback started successfully for '$title' on device $deviceUdn"
                            )
                            // Start monitoring media status after successful playback start
                            startMediaStatusMonitoring(deviceUdn)
                        }

                        override fun failure(
                            invocation: ActionInvocation<*>?,
                            operation: UpnpResponse?,
                            defaultMsg: String?
                        ) {
                            Log.e(
                                "MediaCastDlna",
                                "Play action failed for device $deviceUdn: $defaultMsg"
                            )
                        }
                    }
                    upnpService?.controlPoint?.execute(playAction)
                }

                override fun failure(
                    invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
                ) {
                    Log.e(
                        "MediaCastDlna",
                        "SetAVTransportURI failed for device $deviceUdn: $defaultMsg"
                    )
                    throw RuntimeException("Failed to set media URI: $defaultMsg")
                }
            }

        upnpService?.controlPoint?.execute(setAVTransportURIAction)
    }

    // Media Status Monitoring Methods

    private fun startMediaStatusMonitoring(deviceUdn: String) {
        Log.d("MediaCastDlna", "Starting media status monitoring for device $deviceUdn")

        // Subscribe to events if possible
        subscribeToAVTransportEvents(deviceUdn)
        subscribeToRenderingControlEvents(deviceUdn)

        // Start polling for position updates
        startPositionPolling(deviceUdn)
    }

    private fun stopMediaStatusMonitoring(deviceUdn: String) {
        Log.d("MediaCastDlna", "Stopping media status monitoring for device $deviceUdn")

        // Cancel active subscription callback
        activeSubscriptions[deviceUdn]?.let { subscriptionCallback ->
            try {
                // Cancel the subscription by setting subscription duration to 0
                subscriptionCallback.end()
            } catch (e: Exception) {
                Log.w("MediaCastDlna", "Error ending subscription for $deviceUdn", e)
            }
            activeSubscriptions.remove(deviceUdn)
        }

        // Stop polling timer
        monitoringTimers[deviceUdn]?.let { timer ->
            timer.cancel()
            monitoringTimers.remove(deviceUdn)
        }
    }

    private fun stopAllMediaMonitoring() {
        Log.d("MediaCastDlna", "Stopping all media monitoring")

        // Cancel all active subscriptions
        activeSubscriptions.entries.forEach { (deviceUdn, subscriptionCallback) ->
            try {
                subscriptionCallback.end()
            } catch (e: Exception) {
                Log.w("MediaCastDlna", "Error ending subscription for $deviceUdn", e)
            }
        }
        activeSubscriptions.clear()

        // Cancel all timers
        monitoringTimers.values.forEach { timer ->
            try {
                timer.cancel()
            } catch (e: Exception) {
                Log.w("MediaCastDlna", "Error canceling timer", e)
            }
        }
        monitoringTimers.clear()
    }

    private fun subscribeToAVTransportEvents(deviceUdn: String) {
        val device = findDeviceByUdn(deviceUdn) ?: return
        val avTransportService = device.findService(UDAServiceId("AVTransport")) ?: return

        // Cancel any existing subscription for this device
        activeSubscriptions[deviceUdn]?.let { existingCallback ->
            try {
                existingCallback.end()
            } catch (e: Exception) {
                Log.w("MediaCastDlna", "Error ending existing subscription", e)
            }
        }

        val subscriptionCallback = object : SubscriptionCallback(avTransportService, 600) {
            override fun established(subscription: GENASubscription<*>?) {
                Log.d("MediaCastDlna", "AVTransport subscription established for $deviceUdn")
            }

            override fun failed(
                subscription: GENASubscription<*>?,
                responseStatus: UpnpResponse?,
                exception: Exception?,
                defaultMsg: String?
            ) {
                Log.e(
                    "MediaCastDlna",
                    "AVTransport subscription failed for $deviceUdn: $defaultMsg",
                    exception
                )
                activeSubscriptions.remove(deviceUdn)
            }

            override fun eventReceived(subscription: GENASubscription<*>?) {
                Log.d("MediaCastDlna", "AVTransport event received for $deviceUdn")
                handleAVTransportEvent(deviceUdn, subscription)
            }

            override fun eventsMissed(
                subscription: GENASubscription<*>?, numberOfMissedEvents: Int
            ) {
                Log.w(
                    "MediaCastDlna",
                    "AVTransport events missed for $deviceUdn: $numberOfMissedEvents"
                )
            }

            override fun ended(
                subscription: GENASubscription<*>?,
                reason: CancelReason?,
                responseStatus: UpnpResponse?
            ) {
                Log.d("MediaCastDlna", "AVTransport subscription ended for $deviceUdn: $reason")
                activeSubscriptions.remove(deviceUdn)
            }
        }

        activeSubscriptions[deviceUdn] = subscriptionCallback
        upnpService?.controlPoint?.execute(subscriptionCallback)
    }

    private fun subscribeToRenderingControlEvents(deviceUdn: String) {
        val device = findDeviceByUdn(deviceUdn) ?: return
        val renderingControlService = device.findService(UDAServiceId("RenderingControl")) ?: return

        val subscriptionCallback = object : SubscriptionCallback(renderingControlService, 600) {
            override fun established(subscription: GENASubscription<*>?) {
                Log.d("MediaCastDlna", "RenderingControl subscription established for $deviceUdn")
            }

            override fun failed(
                subscription: GENASubscription<*>?,
                responseStatus: UpnpResponse?,
                exception: Exception?,
                defaultMsg: String?
            ) {
                Log.e(
                    "MediaCastDlna",
                    "RenderingControl subscription failed for $deviceUdn: $defaultMsg",
                    exception
                )
            }

            override fun eventReceived(subscription: GENASubscription<*>?) {
                Log.d("MediaCastDlna", "RenderingControl event received for $deviceUdn")
                handleRenderingControlEvent(deviceUdn, subscription)
            }

            override fun eventsMissed(
                subscription: GENASubscription<*>?, numberOfMissedEvents: Int
            ) {
                Log.w(
                    "MediaCastDlna",
                    "RenderingControl events missed for $deviceUdn: $numberOfMissedEvents"
                )
            }

            override fun ended(
                subscription: GENASubscription<*>?,
                reason: CancelReason?,
                responseStatus: UpnpResponse?
            ) {
                Log.d(
                    "MediaCastDlna", "RenderingControl subscription ended for $deviceUdn: $reason"
                )
            }
        }

        upnpService?.controlPoint?.execute(subscriptionCallback)
    }

    private fun handleAVTransportEvent(deviceUdn: String, subscription: GENASubscription<*>?) {
        subscription?.currentValues?.let { values ->
            // Handle transport state changes
            values["TransportState"]?.let { stateValue ->
                val transportState = when (stateValue.value.toString()) {
                    "PLAYING" -> TransportState.PLAYING
                    "PAUSED_PLAYBACK" -> TransportState.PAUSED
                    "STOPPED" -> TransportState.STOPPED
                    "TRANSITIONING" -> TransportState.TRANSITIONING
                    "NO_MEDIA_PRESENT" -> TransportState.NO_MEDIA_PRESENT
                    else -> TransportState.STOPPED
                }

                mainHandler.post {
                    mediaRendererEventsApi?.onTransportStateChanged(deviceUdn, transportState) { }
                }
            }

            // Handle current track changes
            values["CurrentTrackURI"]?.let { uriValue ->
                val trackUri = uriValue.value.toString()
                val trackMetadata = values["CurrentTrackMetaData"]?.value?.toString()

                mainHandler.post {
                    mediaRendererEventsApi?.onTrackChanged(deviceUdn, trackUri, trackMetadata) { }
                }
            }
        }
    }

    private fun handleRenderingControlEvent(deviceUdn: String, subscription: GENASubscription<*>?) {
        subscription?.currentValues?.let { values ->
            // Handle volume changes
            values["Volume"]?.let { volumeValue ->
                val volume = volumeValue.value.toString().toLongOrNull() ?: 0L
                val muted = values["Mute"]?.value.toString().toBoolean()

                val volumeInfo = VolumeInfo(volume, muted)

                mainHandler.post {
                    mediaRendererEventsApi?.onVolumeChanged(deviceUdn, volumeInfo) { }
                }
            }
        }
    }

    private fun startPositionPolling(deviceUdn: String) {
        // Cancel existing timer for this device
        monitoringTimers[deviceUdn]?.cancel()

        val timer = Timer()
        monitoringTimers[deviceUdn] = timer

        timer.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                pollPositionInfo(deviceUdn)
            }
        }, 1000, 1000) // Poll every second
    }

    private fun pollPositionInfo(deviceUdn: String) {
        val device = findDeviceByUdn(deviceUdn) ?: return
        val avTransportService = device.findService(UDAServiceId("AVTransport")) ?: return

        val getPositionInfoAction = object : GetPositionInfo(avTransportService) {
            override fun received(
                invocation: ActionInvocation<*>?,
                positionInfo: org.jupnp.support.model.PositionInfo?
            ) {
                positionInfo?.let { info ->
                    val positionSeconds = parseTimeToSeconds(info.relTime).toLong()

                    mainHandler.post {
                        mediaRendererEventsApi?.onPositionChanged(
                            deviceUdn, positionSeconds
                        ) { }
                    }
                }
            }

            override fun failure(
                invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?
            ) {
                // Don't log every failure as some devices may not support GetPositionInfo
                Log.v("MediaCastDlna", "GetPositionInfo failed for $deviceUdn: $defaultMsg")
            }
        }

        upnpService?.controlPoint?.execute(getPositionInfoAction)
    }

    private fun parseTimeToSeconds(timeString: String?): Int {
        if (timeString.isNullOrEmpty() || timeString == "NOT_IMPLEMENTED") return 0

        try {
            // Parse time format like "0:01:23" or "00:01:23.000"
            val parts = timeString.split(":")
            if (parts.size >= 3) {
                val hours = parts[0].toInt()
                val minutes = parts[1].toInt()
                val seconds = parts[2].split(".")[0].toInt() // Remove milliseconds if present
                return hours * 3600 + minutes * 60 + seconds
            }
        } catch (e: Exception) {
            Log.w("MediaCastDlna", "Failed to parse time: $timeString", e)
        }

        return 0
    }
}
