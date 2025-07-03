package br.com.felnanuke2.media_cast_dlna.core

import DlnaDevice
import DlnaService
import br.com.felnanuke2.media_cast_dlna.UpnpRegistryListener
import br.com.felnanuke2.media_cast_dlna.toDlnaDevice
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import org.jupnp.android.AndroidUpnpService
import org.jupnp.model.action.ActionInvocation
import org.jupnp.model.message.UpnpResponse
import org.jupnp.model.meta.LocalDevice
import org.jupnp.model.meta.RemoteDevice
import org.jupnp.model.types.ServiceType
import org.jupnp.controlpoint.ActionCallback
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class DeviceDiscoveryManager(
    private val upnpService: AndroidUpnpService?,
    private val upnpRegistryListener: UpnpRegistryListener
) {
    fun startDiscovery() {
        upnpService?.controlPoint?.search()
    }

    fun stopDiscovery() {
        upnpService?.registry?.pause()
        // Clean up expired devices when stopping discovery
        cleanupOfflineDevices()
    }

    fun getDiscoveredDevices(): List<DlnaDevice> {
        return upnpRegistryListener.devices
    }

    fun refreshDevice(deviceUdn: String): DlnaDevice? {
        val device =
            upnpService?.registry?.getDevice(org.jupnp.model.types.UDN.valueOf(deviceUdn), false)
                ?: return null

        return when (device) {
            is RemoteDevice -> device.toDlnaDevice()
            is LocalDevice -> device.toDlnaDevice()
            else -> null
        }
    }

    fun getDeviceServices(deviceUdn: String): List<DlnaService> {
        // Not yet implemented
        return emptyList()
    }

    fun hasService(deviceUdn: String, serviceType: String): Boolean {
        // Not yet implemented
        return false
    }

    suspend fun isDeviceOnline(deviceUdn: String): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val device = upnpService?.registry?.getDevice(
                    org.jupnp.model.types.UDN.valueOf(deviceUdn), false
                ) ?: return@withContext false

                // Check if device is still in registry
                if (device !is RemoteDevice) {
                    return@withContext true // Local devices are always online
                }

                // Try to ping the device by calling GetDeviceCapabilities or similar lightweight action
                val connectionManagerService = device.findService(
                    ServiceType.valueOf("urn:schemas-upnp-org:service:ConnectionManager:1")
                )

                if (connectionManagerService != null) {
                    // Use GetCurrentConnectionInfo action to test connectivity
                    val action = connectionManagerService.getAction("GetCurrentConnectionInfo")
                    if (action != null) {
                        return@withContext withTimeoutOrNull(5000) {
                            suspendCoroutine { continuation ->
                                val actionInvocation = ActionInvocation(action).apply {
                                    setInput("ConnectionID", 0)
                                }

                                upnpService.controlPoint?.execute(object :
                                    ActionCallback(actionInvocation) {
                                    override fun success(invocation: ActionInvocation<*>?) {
                                        continuation.resume(true)
                                    }

                                    override fun failure(
                                        invocation: ActionInvocation<*>?,
                                        operation: UpnpResponse?,
                                        defaultMsg: String?
                                    ) {
                                        continuation.resume(false)
                                    }
                                })
                            }
                        } ?: false
                    }
                }

                // Fallback: try GetProtocolInfo action
                val protocolInfoAction = connectionManagerService?.getAction("GetProtocolInfo")
                if (protocolInfoAction != null) {
                    return@withContext withTimeoutOrNull(5000) {
                        suspendCoroutine { continuation ->
                            val actionInvocation = ActionInvocation(protocolInfoAction)

                            upnpService?.controlPoint?.execute(object :
                                ActionCallback(actionInvocation) {
                                override fun success(invocation: ActionInvocation<*>?) {
                                    continuation.resume(true)
                                }

                                override fun failure(
                                    invocation: ActionInvocation<*>?,
                                    operation: UpnpResponse?,
                                    defaultMsg: String?
                                ) {
                                    continuation.resume(false)
                                }
                            })
                        }
                    } ?: false
                }

                // If no suitable service found, check if device is reachable via basic registry lookup
                return@withContext device.isFullyHydrated

            } catch (e: Exception) {
                return@withContext false
            }
        }
    }

    suspend fun getOnlineDevices(): List<DlnaDevice> {
        return withContext(Dispatchers.IO) {
            val devices = upnpService?.registry?.devices ?: emptyList()
            devices.mapNotNull { device ->
                when (device) {
                    is RemoteDevice -> {
                        // Check if device is online before including it
                        if (isDeviceOnline(device.identity.udn.identifierString)) {
                            device.toDlnaDevice()
                        } else {
                            null
                        }
                    }

                    is LocalDevice -> device.toDlnaDevice()
                    else -> null
                }
            }
        }
    }

    fun cleanupOfflineDevices() {
        upnpService?.registry?.devices?.toList()?.forEach { device ->
            if (device is RemoteDevice) {
                // Check if device has expired based on its max age
                val maxAge = device.identity.maxAgeSeconds
                val currentTime = System.currentTimeMillis() / 1000

                // Simple expiration check - let UPnP handle the rest
                if (maxAge > 0 && currentTime > maxAge) {
                    upnpService?.registry?.removeDevice(device)
                }
            }
        }
    }

    /**
     * Removes expired devices from the registry
     */
    fun removeExpiredDevices() {
        upnpService?.registry?.devices?.toList()?.forEach { device ->
            if (device is RemoteDevice) {
                try {
                    // Let UPnP handle device expiration naturally
                    // Just remove obviously stale devices
                    val identity = device.identity
                    if (identity.maxAgeSeconds <= 0) {
                        upnpService?.registry?.removeDevice(device)
                    }
                } catch (e: Exception) {
                    // If there's any error checking the device, it's likely stale
                    upnpService?.registry?.removeDevice(device)
                }
            }
        }
    }

    /**
     * Force refresh device list by restarting discovery
     */
    fun refreshDeviceList() {
        upnpService?.registry?.pause()
        cleanupOfflineDevices()
        upnpService?.controlPoint?.search()
    }
}
