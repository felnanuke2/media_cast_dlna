package br.com.felnanuke2.media_cast_dlna

import DeviceUdn
import DlnaDevice
import IpAddress
import NetworkPort
import Url
import org.jupnp.model.meta.LocalDevice
import org.jupnp.model.meta.RemoteDevice

/**
 * Extension function to convert a RemoteDevice to DlnaDevice
 */
fun RemoteDevice.toDlnaDevice(): DlnaDevice {
    val deviceDetails = this.details
    val identity = this.identity

    // Extract IP address and port from the device identity
    val ipAddress = identity.descriptorURL?.host ?: ""
    val port = identity.descriptorURL?.port?.toLong() ?: 0L

    // Get device icon URL if available
    val iconUrl = ""

    return DlnaDevice(
        udn = DeviceUdn(identity.udn.identifierString),
        friendlyName = deviceDetails.friendlyName ?: "Unknown Device",
        deviceType = this.type.type,
        manufacturerName = deviceDetails.manufacturerDetails?.manufacturer
            ?: "Unknown Manufacturer",
        modelName = deviceDetails.modelDetails?.modelName ?: "Unknown Model",
        ipAddress = IpAddress(ipAddress),
        port = NetworkPort(port),
        modelDescription = deviceDetails.modelDetails?.modelDescription,
        presentationUrl = deviceDetails.presentationURI?.toString()?.let { Url(it) },
        iconUrl = if (iconUrl.isNotEmpty()) Url(iconUrl) else null
    )
}

/**
 * Extension function to convert a LocalDevice to DlnaDevice
 */
fun LocalDevice.toDlnaDevice(): DlnaDevice {
    val deviceDetails = this.details
    val identity = this.identity

    // For local devices, we might need to get the IP address differently
    // Since it's a local device, we can use localhost or try to get the actual IP
    val ipAddress = "127.0.0.1" // This could be enhanced to get actual local IP
    val port = 0L // Local devices might not have a specific port in the same way

    // Get device icon URL if available
    val iconUrl = ""

    return DlnaDevice(
        udn = DeviceUdn(identity.udn.identifierString),
        friendlyName = deviceDetails.friendlyName ?: "Unknown Local Device",
        deviceType = this.type.type,
        manufacturerName = deviceDetails.manufacturerDetails?.manufacturer
            ?: "Unknown Manufacturer",
        modelName = deviceDetails.modelDetails?.modelName ?: "Unknown Model",
        ipAddress = IpAddress(ipAddress),
        port = NetworkPort(port),
        modelDescription = deviceDetails.modelDetails?.modelDescription,
        presentationUrl = deviceDetails.presentationURI?.toString()?.let { Url(it) },
        iconUrl = if (iconUrl.isNotEmpty()) Url(iconUrl) else null
    )
}
