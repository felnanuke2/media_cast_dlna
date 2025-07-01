package br.com.felnanuke2.media_cast_dlna

import DiscoveryOptions
import DlnaDevice
import DlnaService
import MediaCastDlnaApi
import MediaItem
import MediaMetadata
import PlaybackInfo
import SubtitleTrack
import TransportState
import VolumeInfo
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.ComponentName
import android.os.IBinder
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.runBlocking
import org.jupnp.android.AndroidUpnpService
import org.jupnp.android.AndroidUpnpServiceImpl
import org.jupnp.model.types.UDN
import org.jupnp.model.types.UDAServiceId
import br.com.felnanuke2.media_cast_dlna.core.DidlMetadataConverter
import br.com.felnanuke2.media_cast_dlna.core.DefaultDidlMetadataConverter
import br.com.felnanuke2.media_cast_dlna.core.MediaControlManager
import br.com.felnanuke2.media_cast_dlna.core.DeviceDiscoveryManager
import br.com.felnanuke2.media_cast_dlna.core.VolumeManager

/** MediaCastDlnaPlugin - Refactored to act as a simple Facade with coroutines support */
class MediaCastDlnaPlugin : FlutterPlugin, MediaCastDlnaApi {
    private var context: Context? = null
    private var upnpService: AndroidUpnpService? = null
    private var isServiceBound = false
    private var upnpRegistryListener: UpnpRegistryListener? = null

    // Coroutine scope for managing async operations
    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.IO) // Changed to IO dispatcher

    // Service connection for UPnP service
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            Log.d("MediaCastDlna", "UPnP service connected: $className")
            upnpService = service as AndroidUpnpService
            Log.d("MediaCastDlna", "Starting UPnP service...")
            upnpService?.get()?.startup()
            upnpRegistryListener = UpnpRegistryListener()
            upnpService?.registry?.addListener(upnpRegistryListener)
            isServiceBound = true
            Log.d("MediaCastDlna", "UPnP service initialization completed")
        }

        override fun onServiceDisconnected(className: ComponentName) {
            Log.w("MediaCastDlna", "UPnP service disconnected: $className")
            upnpService = null
            isServiceBound = false
        }
    }

    private val didlMetadataConverter: DidlMetadataConverter = DefaultDidlMetadataConverter()
    private val mediaControlManager: MediaControlManager by lazy {
        MediaControlManager(upnpService)
    }
    private val deviceDiscoveryManager: DeviceDiscoveryManager by lazy {
        DeviceDiscoveryManager(upnpService)
    }
    private val volumeManager: VolumeManager by lazy {
        VolumeManager(upnpService)
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
        Log.d("MediaCastDlna", "initializeUpnpService called")
        context?.let {
            Log.d("MediaCastDlna", "Context available, creating service intent")
            val intent = Intent(it, AndroidUpnpServiceImpl::class.java)
            val bindResult = it.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
            Log.d("MediaCastDlna", "bindService result: $bindResult")
        }
            ?: throw IllegalStateException("Context is not available. Ensure the plugin is attached to the engine.")
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
        deviceDiscoveryManager.startDiscovery()
    }

    override fun stopDiscovery() {
        deviceDiscoveryManager.stopDiscovery()
    }

    override fun getDiscoveredDevices(): List<DlnaDevice> =
        deviceDiscoveryManager.getDiscoveredDevices()

    override fun refreshDevice(deviceUdn: String): DlnaDevice? =
        deviceDiscoveryManager.refreshDevice(deviceUdn)

    override fun getDeviceServices(deviceUdn: String): List<DlnaService> =
        deviceDiscoveryManager.getDeviceServices(deviceUdn)

    override fun hasService(deviceUdn: String, serviceType: String): Boolean =
        deviceDiscoveryManager.hasService(deviceUdn, serviceType)

    override fun browseContentDirectory(
        deviceUdn: String, parentId: String, startIndex: Long, requestCount: Long
    ): List<MediaItem> =
        deviceDiscoveryManager.browseContentDirectory(deviceUdn, parentId, startIndex, requestCount)

    override fun searchContentDirectory(
        deviceUdn: String,
        containerId: String,
        searchCriteria: String,
        startIndex: Long,
        requestCount: Long
    ): List<MediaItem> {
        throw NotImplementedError()
    }

    // --- Media Control (delegating to managers with coroutines) ---
    override fun setMediaUri(deviceUdn: String, uri: String, metadata: MediaMetadata, callback: (Result<Unit>) -> Unit) {
        Log.d("MediaCastDlna", "setMediaUri called - deviceUdn: $deviceUdn, uri: $uri")
        Log.d("MediaCastDlna", "UPnP service bound: $isServiceBound, upnpService: $upnpService")
        
        if (!isServiceBound || upnpService == null) {
            Log.e("MediaCastDlna", "UPnP service is not properly initialized. Cannot set media URI.")
            callback(Result.failure(Exception("UPnP service not initialized")))
            return
        }
        
        pluginScope.launch {
            try {
                Log.d("MediaCastDlna", "Converting metadata to DIDL-Lite...")
                val finalMetadata = didlMetadataConverter.toDidlLite(metadata, uri)
                Log.d("MediaCastDlna", "DIDL-Lite metadata: $finalMetadata")
                
                Log.d("MediaCastDlna", "Calling mediaControlManager.setMediaUri...")
                // Add debug info before calling
                debugDeviceConnection(deviceUdn)
                
                // Add timeout to the operation
                withTimeout(30000L) { // 30 second timeout
                    mediaControlManager.setMediaUri(deviceUdn, uri, finalMetadata)
                }
                Log.d("MediaCastDlna", "setMediaUri completed successfully")
                callback(Result.success(Unit))
            } catch (e: TimeoutCancellationException) {
                Log.e("MediaCastDlna", "setMediaUri timed out after 30 seconds for device $deviceUdn")
                callback(Result.failure(e))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to set media URI for device $deviceUdn", e)
                Log.e("MediaCastDlna", "Exception stack trace:", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun setMediaUriWithSubtitles(
        deviceUdn: String,
        uri: String,
        metadata: MediaMetadata,
        subtitleTracks: List<SubtitleTrack>,
        callback: (Result<Unit>) -> Unit
    ) {
        Log.d("MediaCastDlna", "setMediaUriWithSubtitles called - deviceUdn: $deviceUdn, uri: $uri")
        Log.d("MediaCastDlna", "Subtitle tracks: ${subtitleTracks.size}")
        
        if (!isServiceBound || upnpService == null) {
            Log.e("MediaCastDlna", "UPnP service is not properly initialized. Cannot set media URI with subtitles.")
            callback(Result.failure(Exception("UPnP service not initialized")))
            return
        }
        
        pluginScope.launch {
            try {
                val mediaControlManager = MediaControlManager(upnpService)
                val metadataConverter = DefaultDidlMetadataConverter()
                val finalMetadata = metadataConverter.toDidlLite(metadata, uri)
                
                Log.d("MediaCastDlna", "Generated DIDL-Lite metadata: $finalMetadata")
                
                withTimeout(30000) { // 30-second timeout
                    mediaControlManager.setMediaUriWithSubtitlesEnhanced(deviceUdn, uri, finalMetadata, subtitleTracks)
                }
                
                Log.d("MediaCastDlna", "setMediaUriWithSubtitles completed successfully")
                callback(Result.success(Unit))
            } catch (e: TimeoutCancellationException) {
                Log.e("MediaCastDlna", "setMediaUriWithSubtitles timed out", e)
                callback(Result.failure(Exception("Operation timed out: ${e.message}")))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "setMediaUriWithSubtitles failed", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun supportsSubtitleControl(deviceUdn: String): Boolean {
        return try {
            runBlocking {
                mediaControlManager.checkDeviceSubtitleSupport(deviceUdn)
            }
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Failed to check subtitle support for device $deviceUdn", e)
            false
        }
    }

    override fun setSubtitleTrack(
        deviceUdn: String,
        subtitleTrackId: String?,
        callback: (Result<Unit>) -> Unit
    ) {
        Log.d("MediaCastDlna", "setSubtitleTrack called - deviceUdn: $deviceUdn, subtitleTrackId: $subtitleTrackId")
        
        if (!isServiceBound || upnpService == null) {
            Log.e("MediaCastDlna", "UPnP service is not properly initialized. Cannot set subtitle track.")
            callback(Result.failure(Exception("UPnP service not initialized")))
            return
        }
        
        pluginScope.launch {
            try {
                val mediaControlManager = MediaControlManager(upnpService)
                
                withTimeout(10000) { // 10-second timeout
                    mediaControlManager.setSubtitleTrack(deviceUdn, subtitleTrackId)
                }
                
                Log.d("MediaCastDlna", "setSubtitleTrack completed successfully")
                callback(Result.success(Unit))
            } catch (e: UnsupportedOperationException) {
                Log.w("MediaCastDlna", "Device does not support subtitle track control: ${e.message}")
                callback(Result.failure(e))
            } catch (e: TimeoutCancellationException) {
                Log.e("MediaCastDlna", "setSubtitleTrack timed out", e)
                callback(Result.failure(Exception("Operation timed out: ${e.message}")))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "setSubtitleTrack failed", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun getAvailableSubtitleTracks(deviceUdn: String): List<SubtitleTrack> {
        Log.d("MediaCastDlna", "getAvailableSubtitleTracks called - deviceUdn: $deviceUdn")
        
        if (!isServiceBound || upnpService == null) {
            Log.e("MediaCastDlna", "UPnP service is not properly initialized. Cannot get subtitle tracks.")
            return emptyList()
        }
        
        return try {
            val mediaControlManager = MediaControlManager(upnpService)
            
            // Use runBlocking since this is a synchronous method
            runBlocking {
                withTimeout(10000) { // 10-second timeout
                    mediaControlManager.getAvailableSubtitleTracks(deviceUdn)
                }
            }
        } catch (e: TimeoutCancellationException) {
            Log.e("MediaCastDlna", "getAvailableSubtitleTracks timed out", e)
            emptyList()
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "getAvailableSubtitleTracks failed", e)
            emptyList()
        }
    }

    override fun getCurrentSubtitleTrack(deviceUdn: String): SubtitleTrack? {
        Log.d("MediaCastDlna", "getCurrentSubtitleTrack called - deviceUdn: $deviceUdn")
        
        if (!isServiceBound || upnpService == null) {
            Log.e("MediaCastDlna", "UPnP service is not properly initialized. Cannot get current subtitle track.")
            return null
        }
        
        return try {
            val mediaControlManager = MediaControlManager(upnpService)
            
            // Use runBlocking since this is a synchronous method
            runBlocking {
                withTimeout(10000) { // 10-second timeout
                    mediaControlManager.getCurrentSubtitleTrack(deviceUdn)
                }
            }
        } catch (e: TimeoutCancellationException) {
            Log.e("MediaCastDlna", "getCurrentSubtitleTrack timed out", e)
            null
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "getCurrentSubtitleTrack failed", e)
            null
        }
    }

    override fun play(deviceUdn: String, callback: (Result<Unit>) -> Unit) {
        Log.d("MediaCastDlna", "play called - deviceUdn: $deviceUdn")
        Log.d("MediaCastDlna", "UPnP service bound: $isServiceBound, upnpService: $upnpService")
        
        if (!isServiceBound || upnpService == null) {
            Log.e("MediaCastDlna", "UPnP service is not properly initialized. Cannot play.")
            callback(Result.failure(Exception("UPnP service not initialized")))
            return
        }
        
        pluginScope.launch {
            try {
                Log.d("MediaCastDlna", "Calling mediaControlManager.play...")
                // Add debug info before calling
                debugDeviceConnection(deviceUdn)
                
                // Add timeout to the operation
                withTimeout(30000L) { // 30 second timeout
                    mediaControlManager.play(deviceUdn)
                }
                Log.d("MediaCastDlna", "play completed successfully")
                callback(Result.success(Unit))
            } catch (e: TimeoutCancellationException) {
                Log.e("MediaCastDlna", "play timed out after 30 seconds for device $deviceUdn")
                callback(Result.failure(e))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to play for device $deviceUdn", e)
                Log.e("MediaCastDlna", "Exception stack trace:", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun pause(deviceUdn: String, callback: (Result<Unit>) -> Unit) {
        pluginScope.launch {
            try {
                mediaControlManager.pause(deviceUdn)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to pause for device $deviceUdn", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun stop(deviceUdn: String, callback: (Result<Unit>) -> Unit) {
        pluginScope.launch {
            try {
                mediaControlManager.stop(deviceUdn)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to stop for device $deviceUdn", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun seek(deviceUdn: String, positionSeconds: Long, callback: (Result<Unit>) -> Unit) {
        pluginScope.launch {
            try {
                mediaControlManager.seek(deviceUdn, positionSeconds)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to seek for device $deviceUdn", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun next(deviceUdn: String, callback: (Result<Unit>) -> Unit) {
        pluginScope.launch {
            try {
                mediaControlManager.next(deviceUdn)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to go to next for device $deviceUdn", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun previous(deviceUdn: String, callback: (Result<Unit>) -> Unit) {
        pluginScope.launch {
            try {
                mediaControlManager.previous(deviceUdn)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to go to previous for device $deviceUdn", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun setVolume(deviceUdn: String, volume: Long, callback: (Result<Unit>) -> Unit) {
        pluginScope.launch {
            try {
                volumeManager.setVolume(deviceUdn, volume)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to set volume for device $deviceUdn", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun getVolumeInfo(deviceUdn: String): VolumeInfo {
        // Note: This is synchronous in the Pigeon API, but we should consider making it async
        return try {
            // For now, we'll use runBlocking, but ideally the Pigeon API should support suspend functions
            runBlocking {
                volumeManager.getVolumeInfo(deviceUdn)
            }
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Failed to get volume info for device $deviceUdn", e)
            VolumeInfo(0L, false)
        }
    }

    override fun setMute(deviceUdn: String, muted: Boolean, callback: (Result<Unit>) -> Unit) {
        pluginScope.launch {
            try {
                volumeManager.setMute(deviceUdn, muted)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "Failed to set mute for device $deviceUdn", e)
                callback(Result.failure(e))
            }
        }
    }

    override fun getPlaybackInfo(deviceUdn: String): PlaybackInfo {
        // Note: This is synchronous in the Pigeon API, but we should consider making it async
        return try {
            runBlocking {
                mediaControlManager.getPlaybackInfo(deviceUdn)
            }
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Failed to get playback info for device $deviceUdn", e)
            PlaybackInfo(
                TransportState.STOPPED, 0L, 0L, null, null
            )
        }
    }

    override fun getCurrentPosition(deviceUdn: String): Long {
        return try {
            runBlocking {
                mediaControlManager.getCurrentPosition(deviceUdn)
            }
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Failed to get current position for device $deviceUdn", e)
            -1L
        }
    }

    override fun getTransportState(deviceUdn: String): TransportState {
        return try {
            runBlocking {
                mediaControlManager.getTransportState(deviceUdn)
            }
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Failed to get transport state for device $deviceUdn", e)
            TransportState.STOPPED
        }
    }

    // --- Debug methods ---
    fun debugDeviceConnection(deviceUdn: String) {
        Log.d("MediaCastDlna", "=== DEBUG: Testing device connection for $deviceUdn ===")
        
        try {
            Log.d("MediaCastDlna", "1. Checking UPnP service state...")
            Log.d("MediaCastDlna", "   isServiceBound: $isServiceBound")
            Log.d("MediaCastDlna", "   upnpService: $upnpService")
            
            if (upnpService == null) {
                Log.e("MediaCastDlna", "   ERROR: UPnP service is null")
                return
            }
            
            Log.d("MediaCastDlna", "2. Checking registry...")
            val registry = upnpService?.registry
            Log.d("MediaCastDlna", "   registry: $registry")
            
            if (registry == null) {
                Log.e("MediaCastDlna", "   ERROR: Registry is null")
                return
            }
            
            Log.d("MediaCastDlna", "3. Looking for device...")
            val udn = UDN.valueOf(deviceUdn)
            val device = registry.getDevice(udn, false)
            Log.d("MediaCastDlna", "   device: ${device?.details?.friendlyName ?: "null"}")
            
            if (device == null) {
                Log.e("MediaCastDlna", "   ERROR: Device not found")
                Log.d("MediaCastDlna", "   Available devices:")
                registry.devices?.forEach { availableDevice ->
                    Log.d("MediaCastDlna", "     - ${availableDevice.identity.udn} (${availableDevice.details.friendlyName})")
                }
                return
            }
            
            Log.d("MediaCastDlna", "4. Checking AVTransport service...")
            val avTransportService = device.findService(UDAServiceId("AVTransport"))
            Log.d("MediaCastDlna", "   AVTransport service: ${avTransportService?.serviceId ?: "null"}")
            
            if (avTransportService == null) {
                Log.e("MediaCastDlna", "   ERROR: AVTransport service not found")
                Log.d("MediaCastDlna", "   Available services:")
                device.services?.forEach { service ->
                    Log.d("MediaCastDlna", "     - ${service.serviceId}")
                }
                return
            }
            
            Log.d("MediaCastDlna", "5. Checking control point...")
            val controlPoint = upnpService?.controlPoint
            Log.d("MediaCastDlna", "   controlPoint: $controlPoint")
            
            if (controlPoint == null) {
                Log.e("MediaCastDlna", "   ERROR: Control point is null")
                return
            }
            
            Log.d("MediaCastDlna", "=== DEBUG: All checks passed! Device should be ready for commands ===")
            
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "=== DEBUG: Exception during device connection test ===", e)
        }
    }

    // Test method to be called from Dart  
    fun testDeviceConnection(deviceUdn: String): Boolean {
        Log.d("MediaCastDlna", "testDeviceConnection called for device: $deviceUdn")
        return try {
            debugDeviceConnection(deviceUdn)
            true
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Device test failed", e)
            false
        }
    }

    // --- Debug methods to help troubleshoot subtitle issues ---
    fun debugDeviceSubtitleSupport(deviceUdn: String, callback: (Result<Map<String, Any>>) -> Unit) {
        Log.d("MediaCastDlna", "debugDeviceSubtitleSupport called for device: $deviceUdn")
        
        if (!isServiceBound || upnpService == null) {
            callback(Result.failure(Exception("UPnP service not initialized")))
            return
        }
        
        pluginScope.launch {
            try {
                val mediaControlManager = MediaControlManager(upnpService)
                val capabilities = mediaControlManager.debugDeviceCapabilities(deviceUdn)
                val supportsSubtitles = mediaControlManager.checkDeviceSubtitleSupport(deviceUdn)
                
                val result = capabilities.toMutableMap()
                result["supportsSubtitleControl"] = supportsSubtitles
                
                Log.d("MediaCastDlna", "Device subtitle support debug result: $result")
                callback(Result.success(result))
            } catch (e: Exception) {
                Log.e("MediaCastDlna", "debugDeviceSubtitleSupport failed", e)
                callback(Result.failure(e))
            }
        }
    }
    
    fun debugSubtitleMetadata(originalMetadata: String, subtitleTracks: List<SubtitleTrack>): Map<String, String> {
        Log.d("MediaCastDlna", "debugSubtitleMetadata called")
        
        return try {
            val mediaControlManager = MediaControlManager(upnpService)
            mediaControlManager.debugMetadata(originalMetadata, subtitleTracks)
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "debugSubtitleMetadata failed", e)
            mapOf("error" to (e.message ?: "Unknown error"))
        }
    }

    // --- Helper method to check if a device supports subtitle track control ---
    // Exposed to Dart
    fun checkSubtitleSupport(deviceUdn: String): Boolean {
        Log.d("MediaCastDlna", "checkSubtitleSupport called for device: $deviceUdn")
        
        if (!isServiceBound || upnpService == null) {
            Log.e("MediaCastDlna", "UPnP service is not properly initialized.")
            return false
        }
        
        return try {
            val mediaControlManager = MediaControlManager(upnpService)
            runBlocking {
                // Use the private method through reflection or create a public version
                // For now, let's check directly
                val udn = org.jupnp.model.types.UDN.valueOf(deviceUdn)
                val device = upnpService?.registry?.getDevice(udn, false)
                if (device != null) {
                    val avTransportService = device.findService(org.jupnp.model.types.UDAServiceId("AVTransport"))
                    val setSubtitleAction = avTransportService?.getAction("SetCurrentSubtitle")
                    val result = setSubtitleAction != null
                    Log.d("MediaCastDlna", "Device $deviceUdn subtitle support: $result")
                    result
                } else {
                    Log.w("MediaCastDlna", "Device $deviceUdn not found")
                    false
                }
            }
        } catch (e: Exception) {
            Log.e("MediaCastDlna", "Error checking subtitle support for device $deviceUdn", e)
            false
        }
    }

    // --- Unimplemented methods (kept as-is for now) ---
    override fun getPlatformVersion(): String {
        throw NotImplementedError()
    }

    override fun isUpnpAvailable(): Boolean {
        throw NotImplementedError()
    }

    override fun getNetworkInterfaces(): List<String> {
        throw NotImplementedError()
    }

}

