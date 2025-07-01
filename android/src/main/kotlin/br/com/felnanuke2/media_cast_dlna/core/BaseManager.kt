package br.com.felnanuke2.media_cast_dlna.core

import org.jupnp.android.AndroidUpnpService
import org.jupnp.model.meta.Device
import org.jupnp.model.meta.Service
import org.jupnp.model.types.UDAServiceId
import org.jupnp.model.types.UDN

/**
 * Base class for all managers that provides common device and service operations
 */
abstract class BaseManager(protected val upnpService: AndroidUpnpService?) {
    
    /**
     * Requires that the UPnP service is available
     */
    protected fun requireUpnpService(): AndroidUpnpService {
        android.util.Log.d("BaseManager", "requireUpnpService called, upnpService: $upnpService")
        return upnpService ?: throw IllegalStateException("UPnP service is not available")
    }
    
    /**
     * Finds a device by its UDN, throws exception if not found
     */
    protected fun requireDevice(deviceUdn: String): Device<*, *, *> {
        android.util.Log.d("BaseManager", "requireDevice called with UDN: $deviceUdn")
        val service = requireUpnpService()
        val udn = UDN.valueOf(deviceUdn)
        android.util.Log.d("BaseManager", "Looking for device with UDN: $udn")
        
        val device = service.registry?.getDevice(udn, false)
        android.util.Log.d("BaseManager", "Found device: ${device?.details?.friendlyName ?: "null"}")
        
        return device ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
    }
    
    /**
     * Finds a service on a device, throws exception if not found
     */
    protected fun requireService(device: Device<*, *, *>, serviceId: String): Service<*, *> {
        android.util.Log.d("BaseManager", "requireService called with serviceId: $serviceId on device: ${device.details.friendlyName}")
        val service = device.findService(UDAServiceId(serviceId))
        android.util.Log.d("BaseManager", "Found service: ${service?.serviceId ?: "null"}")
        
        return service ?: throw IllegalStateException("$serviceId service not found on device ${device.identity.udn}")
    }
    
    /**
     * Finds a device and service in one call
     */
    protected fun requireDeviceAndService(deviceUdn: String, serviceId: String): Pair<Device<*, *, *>, Service<*, *>> {
        android.util.Log.d("BaseManager", "requireDeviceAndService called - UDN: $deviceUdn, serviceId: $serviceId")
        val device = requireDevice(deviceUdn)
        val service = requireService(device, serviceId)
        android.util.Log.d("BaseManager", "Successfully found device and service")
        return Pair(device, service)
    }
    
    /**
     * Utility method to parse time strings like "0:01:23" to seconds
     */
    protected fun parseTimeToSeconds(timeString: String?): Int {
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
            android.util.Log.w("BaseManager", "Failed to parse time: $timeString", e)
        }
        return 0
    }
    
    /**
     * Utility method to format seconds to time string like "HH:MM:SS"
     */
    protected fun formatSecondsToTime(seconds: Long): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60
        return String.format("%02d:%02d:%02d", hours, minutes, secs)
    }
}
