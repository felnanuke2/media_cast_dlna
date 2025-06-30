package br.com.felnanuke2.media_cast_dlna

import MediaCastDlnaApi
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.jupnp.model.meta.LocalDevice
import org.jupnp.model.meta.RemoteDevice
import org.jupnp.registry.Registry
import org.jupnp.registry.RegistryListener
import java.lang.Exception

/**
 * RegistryListener implementation for handling UPnP device discovery events.
 * This class manages device discovery callbacks and communicates with Flutter
 * through the provided MediaCastDlnaApi and DeviceDiscoveryApi instances.
 * 
 * IMPORTANT: All Flutter API calls must be executed on the main UI thread.
 * The UPnP registry callbacks are executed on background threads (e.g., jupnp-4),
 * so this class uses a Handler to post all Flutter API calls to the main thread
 * to avoid the "Methods marked with @UiThread must be executed on the main thread" error.
 */
class UpnpRegistryListener(
) : RegistryListener {

    private var remoteDevices: MutableList<RemoteDevice> = mutableListOf()
    private var localDevice: MutableList<LocalDevice> = mutableListOf()
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        // Device types that we're interested in for media casting
        private val MEDIA_DEVICE_TYPES = setOf(
            "urn:schemas-upnp-org:device:MediaRenderer:1",
            "urn:schemas-upnp-org:device:MediaRenderer:2",
            "urn:schemas-upnp-org:device:MediaRenderer:3",
            "urn:schemas-upnp-org:device:MediaServer:1",
            "urn:schemas-upnp-org:device:MediaServer:2",
            "urn:schemas-upnp-org:device:MediaServer:3",
            "urn:schemas-upnp-org:device:MediaServer:4"
        )
        
        // Device type prefixes to filter for media devices
        private val MEDIA_DEVICE_PREFIXES = setOf(
            "MediaRenderer",
            "MediaServer"
        )
        
        // Devices to exclude (like Internet Gateway Devices)
        private val EXCLUDED_DEVICE_PREFIXES = setOf(
            "InternetGatewayDevice",
            "WANDevice",
            "LANDevice",
            "WFADevice"
        )
    }

    /**
     * Helper method to safely post Flutter API calls to the main thread
     */
    private fun runOnMainThread(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action()
        } else {
            mainHandler.post(action)
        }
    }

    /**
     * Check if a device is a media device (MediaRenderer or MediaServer)
     */
    private fun isMediaDevice(device: RemoteDevice): Boolean {
        val deviceType = device.type.toString()
        val friendlyName = device.details?.friendlyName ?: "Unknown"
        
        Log.d("UpnpRegistryListener", "Checking device: $friendlyName, type: $deviceType")
        
        // First check if it's explicitly excluded
        if (EXCLUDED_DEVICE_PREFIXES.any { deviceType.contains(it, ignoreCase = true) }) {
            Log.d("UpnpRegistryListener", "Device excluded: $friendlyName ($deviceType)")
            return false
        }
        
        // Check for exact match with known media device types
        if (MEDIA_DEVICE_TYPES.contains(deviceType)) {
            Log.d("UpnpRegistryListener", "Device accepted (exact match): $friendlyName ($deviceType)")
            return true
        }
        
        // Check for partial match with media device prefixes
        val isMediaDevice = MEDIA_DEVICE_PREFIXES.any { deviceType.contains(it, ignoreCase = true) }
        if (isMediaDevice) {
            Log.d("UpnpRegistryListener", "Device accepted (partial match): $friendlyName ($deviceType)")
        } else {
            Log.d("UpnpRegistryListener", "Device rejected: $friendlyName ($deviceType)")
        }
        
        return isMediaDevice
    }

    /**
     * Check if a local device is a media device (MediaRenderer or MediaServer)
     */
    private fun isMediaDevice(device: LocalDevice): Boolean {
        val deviceType = device.type.toString()
        val friendlyName = device.details?.friendlyName ?: "Unknown"
        
        Log.d("UpnpRegistryListener", "Checking local device: $friendlyName, type: $deviceType")
        
        // First check if it's explicitly excluded
        if (EXCLUDED_DEVICE_PREFIXES.any { deviceType.contains(it, ignoreCase = true) }) {
            Log.d("UpnpRegistryListener", "Local device excluded: $friendlyName ($deviceType)")
            return false
        }
        
        // Check for exact match with known media device types
        if (MEDIA_DEVICE_TYPES.contains(deviceType)) {
            Log.d("UpnpRegistryListener", "Local device accepted (exact match): $friendlyName ($deviceType)")
            return true
        }
        
        // Check for partial match with media device prefixes
        val isMediaDevice = MEDIA_DEVICE_PREFIXES.any { deviceType.contains(it, ignoreCase = true) }
        if (isMediaDevice) {
            Log.d("UpnpRegistryListener", "Local device accepted (partial match): $friendlyName ($deviceType)")
        } else {
            Log.d("UpnpRegistryListener", "Local device rejected: $friendlyName ($deviceType)")
        }
        
        return isMediaDevice
    }

    override fun remoteDeviceDiscoveryStarted(registry: Registry?, device: RemoteDevice?) {
        // This method is called when remote device discovery starts.
        // You can notify Flutter that discovery has started if needed.
        // For example, you might want to clear the existing list of devices.
        remoteDevices.clear()
        device?.let {
            // Only notify Flutter if this is a media device
            if (isMediaDevice(it)) {

            }
        }
    }

    override fun remoteDeviceDiscoveryFailed(
        registry: Registry?, device: RemoteDevice?, e: Exception?
    ) {

    }

    override fun remoteDeviceAdded(registry: Registry?, device: RemoteDevice?) {
        device?.let {
            // Only process media devices
            if (isMediaDevice(it)) {
                // Add the discovered remote device to the list
                remoteDevices.add(it)

                // Convert to DlnaDevice and notify Flutter
                val dlnaDevice = it.toDlnaDevice()

            }
        }
    }

    override fun remoteDeviceUpdated(registry: Registry?, device: RemoteDevice?) {
        device?.let {
            // Only process media devices
            if (isMediaDevice(it)) {
                // Update the device in the list if it exists
                val index = remoteDevices.indexOfFirst { d -> d.identity == it.identity }
                if (index != -1) {
                    remoteDevices[index] = it
                } else {
                    remoteDevices.add(it)
                }

                // Convert to DlnaDevice and notify Flutter about the update
                val dlnaDevice = it.toDlnaDevice()

            }
        }
    }

    override fun remoteDeviceRemoved(registry: Registry?, device: RemoteDevice?) {
        device?.let {
            // Only process media devices
            if (isMediaDevice(it)) {
                val iterator = remoteDevices.iterator()
                while (iterator.hasNext()) {
                    if (iterator.next().identity == it.identity) {
                        iterator.remove()
                        // Notify Flutter about the removed device
                        val dlnaDevice = it.toDlnaDevice()

                        break;
                    }
                }
            }
        }
    }

    override fun localDeviceAdded(registry: Registry?, device: LocalDevice?) {
        device?.let {
            // Only process media devices
            if (isMediaDevice(it)) {
                // Add the discovered local device to the list
                localDevice.add(it)

                // Convert to DlnaDevice and notify Flutter
                val dlnaDevice = it.toDlnaDevice()

            }
        }
    }

    override fun localDeviceRemoved(registry: Registry?, device: LocalDevice?) {
        device?.let {
            // Only process media devices
            if (isMediaDevice(it)) {
                val iterator = localDevice.iterator()
                while (iterator.hasNext()) {
                    if (iterator.next().identity == it.identity) {
                        iterator.remove()
                        // Notify Flutter about the removed local device
                        val dlnaDevice = it.toDlnaDevice()

                        break;
                    }
                }
            }
        }
    }

    override fun beforeShutdown(registry: Registry?) {
        // This method is called before the registry is shut down.
        // You can perform any necessary cleanup here, such as notifying Flutter
        // that device discovery is stopping.
        TODO("Implement pre-shutdown logic if needed")
    }

    override fun afterShutdown() {
        // This method is called after the registry has been shut down.
        // You can perform any necessary cleanup here, such as notifying Flutter
        // that device discovery has stopped.
        TODO("Implement post-shutdown logic if needed")
    }
}
