package br.com.felnanuke2.media_cast_dlna.core

import DlnaDevice
import DlnaService
import MediaItem
import br.com.felnanuke2.media_cast_dlna.toDlnaDevice
import org.jupnp.android.AndroidUpnpService
import org.jupnp.model.meta.LocalDevice
import org.jupnp.model.meta.RemoteDevice

class DeviceDiscoveryManager(private val upnpService: AndroidUpnpService?) {
    fun startDiscovery() {
        upnpService?.controlPoint?.search()
    }

    fun stopDiscovery() {
        upnpService?.registry?.pause()
    }

    fun getDiscoveredDevices(): List<DlnaDevice> {
        val devices = upnpService?.registry?.devices ?: emptyList()
        return devices.mapNotNull { device ->
            when (device){
                is RemoteDevice -> device.toDlnaDevice()
                is LocalDevice -> device.toDlnaDevice()
                else -> null
            }
        }
    }

    fun refreshDevice(deviceUdn: String): DlnaDevice? {
        // Not yet implemented
        return null
    }

    fun getDeviceServices(deviceUdn: String): List<DlnaService> {
        // Not yet implemented
        return emptyList()
    }

    fun hasService(deviceUdn: String, serviceType: String): Boolean {
        // Not yet implemented
        return false
    }

    fun browseContentDirectory(deviceUdn: String, parentId: String, startIndex: Long, requestCount: Long): List<MediaItem> {
        // Not yet implemented
        return emptyList()
    }
}
