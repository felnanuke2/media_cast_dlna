package br.com.felnanuke2.media_cast_dlna

import DiscoveryOptions
import DlnaDevice
import DlnaService
import MediaCastDlnaApi
import MediaItem
import MediaMetadata
import PlaybackInfo
import TransportState
import VolumeInfo
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.ComponentName
import android.os.IBinder
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import org.jupnp.android.AndroidUpnpService
import org.jupnp.android.AndroidUpnpServiceImpl
import org.jupnp.model.message.UpnpResponse
import org.jupnp.model.meta.Device
import org.jupnp.model.meta.Service
import org.jupnp.model.types.UDAServiceId
import org.jupnp.model.types.UDN
import org.jupnp.support.avtransport.callback.SetAVTransportURI
import org.jupnp.support.avtransport.callback.Play
import org.jupnp.support.avtransport.callback.GetTransportInfo
import org.jupnp.support.avtransport.callback.GetPositionInfo
import org.jupnp.model.action.ActionInvocation
import org.jupnp.model.types.UnsignedIntegerFourBytes
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit
import br.com.felnanuke2.media_cast_dlna.core.DeviceServiceManager
import br.com.felnanuke2.media_cast_dlna.core.DefaultDeviceServiceManager
import br.com.felnanuke2.media_cast_dlna.core.DidlMetadataConverter
import br.com.felnanuke2.media_cast_dlna.core.DefaultDidlMetadataConverter
import br.com.felnanuke2.media_cast_dlna.core.MediaControlManager
import br.com.felnanuke2.media_cast_dlna.core.DeviceDiscoveryManager
import br.com.felnanuke2.media_cast_dlna.core.VolumeManager
import br.com.felnanuke2.media_cast_dlna.core.createDefaultMetadata

/** MediaCastDlnaPlugin (polling-only, no event/callback APIs) */
class MediaCastDlnaPlugin : FlutterPlugin, MediaCastDlnaApi {
    private var context: Context? = null
    private var upnpService: AndroidUpnpService? = null
    private var isServiceBound = false
    private var lastTransportState: MutableMap<String, TransportState> = ConcurrentHashMap()
    private var lastPosition: MutableMap<String, Long> = ConcurrentHashMap()
    private var upnpRegistryListener: UpnpRegistryListener? = null
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            upnpService = service as AndroidUpnpService
            upnpService?.get()?.startup()
            upnpRegistryListener = UpnpRegistryListener()
            upnpService?.registry?.addListener(upnpRegistryListener)
            isServiceBound = true
        }

        override fun onServiceDisconnected(className: ComponentName) {
            upnpService = null
            isServiceBound = false
        }
    }

    private val deviceServiceManager: DeviceServiceManager = DefaultDeviceServiceManager()
    private val didlMetadataConverter: DidlMetadataConverter = DefaultDidlMetadataConverter()
    private val mediaControlManager: MediaControlManager by lazy {
        MediaControlManager(upnpService) { udn -> findDeviceByUdn(udn) }
    }
    private val deviceDiscoveryManager: DeviceDiscoveryManager by lazy {
        DeviceDiscoveryManager(upnpService)
    }
    private val volumeManager: VolumeManager by lazy {
        VolumeManager(upnpService) { udn -> findDeviceByUdn(udn) }
    }

    // --- Utility helpers ---
    private inline fun <T> requireUpnpService(block: (AndroidUpnpService) -> T): T {
        val service = upnpService ?: throw IllegalStateException("UPnP service is not available")
        return block(service)
    }

    private fun requireDevice(deviceUdn: String): Device<*, *, *> =
        findDeviceByUdn(deviceUdn)
            ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")

    private fun <T> withService(device: Device<*, *, *>, serviceId: String, error: String, block: (Service<*, *>) -> T): T {
        val service = device.findService(UDAServiceId(serviceId))
            ?: throw IllegalStateException("$error on device ${device.identity.udn}")
        return block(service)
    }

    // --- Plugin lifecycle ---
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        MediaCastDlnaApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MediaCastDlnaApi.setUp(binding.binaryMessenger, null)
        if (upnpService != null && context != null) {
            context?.unbindService(serviceConnection)
        }
        upnpService = null
        context = null
    }

    override fun initializeUpnpService() {
        context?.let {
            val intent = Intent(it, AndroidUpnpServiceImpl::class.java)
            it.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
        } ?: throw IllegalStateException("Context is not available. Ensure the plugin is attached to the engine.")
    }

    override fun isUpnpServiceInitialized(): Boolean = upnpService != null && isServiceBound

    override fun shutdownUpnpService() {
        if (upnpService != null && context != null && isServiceBound) {
            try {
                context!!.unbindService(serviceConnection)
            } catch (e: IllegalArgumentException) {
                Log.w("MediaCastDlna", "Service unbind failed: ${e.message}")
            }
            isServiceBound = false
        }
        upnpService = null
    }

    // --- Discovery ---
    override fun startDiscovery(options: DiscoveryOptions) {
        if (!isServiceBound) throw IllegalStateException("UPnP service is not bound. Please ensure the service is started before calling startDiscovery.")
        deviceDiscoveryManager.startDiscovery(options)
    }

    override fun stopDiscovery() {
        deviceDiscoveryManager.stopDiscovery()
    }

    override fun getDiscoveredDevices(): List<DlnaDevice> = deviceDiscoveryManager.getDiscoveredDevices()

    override fun refreshDevice(deviceUdn: String): DlnaDevice? = deviceDiscoveryManager.refreshDevice(deviceUdn)

    override fun getDeviceServices(deviceUdn: String): List<DlnaService> = deviceDiscoveryManager.getDeviceServices(deviceUdn)

    override fun hasService(deviceUdn: String, serviceType: String): Boolean = deviceDiscoveryManager.hasService(deviceUdn, serviceType)

    override fun browseContentDirectory(
        deviceUdn: String, parentId: String, startIndex: Long, requestCount: Long
    ): List<MediaItem> = deviceDiscoveryManager.browseContentDirectory(deviceUdn, parentId, startIndex, requestCount)

    override fun searchContentDirectory(
        deviceUdn: String,
        containerId: String,
        searchCriteria: String,
        startIndex: Long,
        requestCount: Long
    ): List<MediaItem> {
        throw NotImplementedError()
    }

    // --- Media Control ---
    override fun setMediaUri(deviceUdn: String, uri: String, metadata: MediaMetadata) {
        requireUpnpService { service ->
            val device = requireDevice(deviceUdn)
            val avTransportService = deviceServiceManager.findService(device, "AVTransport")
                ?: throw IllegalStateException("AVTransport service not found on device $deviceUdn")
            val finalMetadata = didlMetadataConverter.toDidlLite(metadata, uri)
            mediaControlManager.setMediaUri(deviceUdn, uri, finalMetadata, avTransportService)
        }
    }

    override fun play(deviceUdn: String) {
        requireUpnpService { service ->
            val device = requireDevice(deviceUdn)
            withService(device, "AVTransport", "AVTransport service not found") { avTransportService ->
                mediaControlManager.play(deviceUdn, avTransportService)
            }
        }
    }

    override fun pause(deviceUdn: String) {
        requireUpnpService { service ->
            val device = requireDevice(deviceUdn)
            withService(device, "AVTransport", "AVTransport service not found") { avTransportService ->
                mediaControlManager.pause(deviceUdn, avTransportService)
            }
        }
    }

    override fun stop(deviceUdn: String) {
        requireUpnpService { service ->
            val device = requireDevice(deviceUdn)
            withService(device, "AVTransport", "AVTransport service not found") { avTransportService ->
                mediaControlManager.stop(deviceUdn, avTransportService)
            }
        }
    }

    override fun seek(deviceUdn: String, positionSeconds: Long) {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }
        val device = findDeviceByUdn(deviceUdn)
            ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        val avTransportService = device.findService(UDAServiceId("AVTransport"))
            ?: throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        val seekAction = avTransportService.getAction("Seek")
            ?: throw IllegalStateException("Seek action not available on device $deviceUdn")
        val actionInvocation = ActionInvocation(seekAction)
        actionInvocation.setInput("InstanceID", UnsignedIntegerFourBytes(0))
        actionInvocation.setInput("Unit", "REL_TIME")
        // Format seconds to HH:MM:SS
        val hours = positionSeconds / 3600
        val minutes = (positionSeconds % 3600) / 60
        val seconds = positionSeconds % 60
        val timeString = String.format("%02d:%02d:%02d", hours, minutes, seconds)
        actionInvocation.setInput("Target", timeString)
        mediaControlManager.seek(deviceUdn, actionInvocation, timeString)
    }

    override fun next(deviceUdn: String) {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }
        val device = findDeviceByUdn(deviceUdn)
            ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        val avTransportService = device.findService(UDAServiceId("AVTransport"))
            ?: throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        mediaControlManager.next(deviceUdn, avTransportService)
    }

    override fun previous(deviceUdn: String) {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }
        val device = findDeviceByUdn(deviceUdn)
            ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        val avTransportService = device.findService(UDAServiceId("AVTransport"))
            ?: throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        mediaControlManager.previous(deviceUdn, avTransportService)
    }

    override fun setVolume(deviceUdn: String, volume: Long) {
        volumeManager.setVolume(deviceUdn, volume)
    }

    override fun getVolumeInfo(deviceUdn: String): VolumeInfo {
        return volumeManager.getVolumeInfo(deviceUdn)
    }

    override fun setMute(deviceUdn: String, muted: Boolean) {
        volumeManager.setMute(deviceUdn, muted)
    }

    override fun getPlaybackInfo(deviceUdn: String): PlaybackInfo {
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }
        val device = findDeviceByUdn(deviceUdn)
            ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        val avTransportService = device.findService(UDAServiceId("AVTransport"))
            ?: throw IllegalStateException("AVTransport service not found on device $deviceUdn")
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
        if (upnpService == null) {
            throw IllegalStateException("UPnP service is not available")
        }
        val device = findDeviceByUdn(deviceUdn)
            ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        val avTransportService = device.findService(UDAServiceId("AVTransport"))
            ?: throw IllegalStateException("AVTransport service not found on device $deviceUdn")
        var position: Long = -1L
        val semaphore = Semaphore(0)
        val getPositionInfoAction = object : GetPositionInfo(avTransportService) {
            override fun received(
                invocation: ActionInvocation<*>?,
                positionInfo: org.jupnp.support.model.PositionInfo?
            ) {
                positionInfo?.let { info ->
                    position = parseTimeToSeconds(info.relTime).toLong()
                }
                semaphore.release()
            }

            override fun failure(
                invocation: ActionInvocation<*>?,
                operation: UpnpResponse?,
                defaultMsg: String?
            ) {
                Log.e(
                    "MediaCastDlna",
                    "GetCurrentPosition failed for device $deviceUdn: $defaultMsg"
                )
                semaphore.release()
            }
        }
        upnpService?.controlPoint?.execute(getPositionInfoAction)
        try {
            // Wait for the asynchronous call to complete with a timeout
            if (!semaphore.tryAcquire(5, TimeUnit.SECONDS)) {
                Log.w(
                    "MediaCastDlna",
                    "Timeout waiting for GetCurrentPosition response for device $deviceUdn"
                )
            }
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt() // Restore the interrupted status
            Log.w("MediaCastDlna", "GetCurrentPosition interrupted for device $deviceUdn", e)
        }
        return position
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
                    lastTransportState[deviceUdn] = currentState
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

    override fun getPlatformVersion(): String {
        throw NotImplementedError()
    }

    override fun isUpnpAvailable(): Boolean {
        throw NotImplementedError()
    }

    override fun getNetworkInterfaces(): List<String> {
        throw NotImplementedError()
    }

    // Helper method to find device by UDN
    private fun findDeviceByUdn(deviceUdn: String): Device<*, *, *>? {
        if (upnpService == null) return null
        val udn = UDN.valueOf(deviceUdn)
        return upnpService?.registry?.getDevice(udn, false)
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

