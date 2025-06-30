package br.com.felnanuke2.media_cast_dlna.core

import VolumeInfo
import org.jupnp.android.AndroidUpnpService
import org.jupnp.model.meta.Device
import org.jupnp.model.types.UDAServiceId
import org.jupnp.model.types.UnsignedIntegerFourBytes
import org.jupnp.model.types.UnsignedIntegerTwoBytes
import org.jupnp.support.renderingcontrol.callback.GetVolume
import org.jupnp.support.renderingcontrol.callback.GetMute
import org.jupnp.controlpoint.ActionCallback
import org.jupnp.model.action.ActionInvocation
import org.jupnp.model.message.UpnpResponse
import android.util.Log
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit

class VolumeManager(private val upnpService: AndroidUpnpService?, private val deviceFinder: (String) -> Device<*, *, *>?) {
    fun setVolume(deviceUdn: String, volume: Long) {
        val device = deviceFinder(deviceUdn) ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        val renderingControlService = device.findService(UDAServiceId("RenderingControl"))
            ?: throw IllegalStateException("RenderingControl service not found on device $deviceUdn")
        val setVolumeAction = renderingControlService.getAction("SetVolume")
            ?: throw IllegalStateException("SetVolume action not available on device $deviceUdn")
        val actionInvocation = ActionInvocation(setVolumeAction)
        actionInvocation.setInput("InstanceID", UnsignedIntegerFourBytes(0))
        actionInvocation.setInput("Channel", "Master")
        actionInvocation.setInput("DesiredVolume", UnsignedIntegerTwoBytes(volume))
        val setVolumeCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("VolumeManager", "SetVolume successful for device $deviceUdn to $volume")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("VolumeManager", "SetVolume failed for device $deviceUdn: $defaultMsg")
                throw RuntimeException("Failed to set volume: $defaultMsg")
            }
        }
        upnpService?.controlPoint?.execute(setVolumeCallback)
    }

    fun getVolumeInfo(deviceUdn: String): VolumeInfo {
        val device = deviceFinder(deviceUdn) ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        val renderingControlService = device.findService(UDAServiceId("RenderingControl"))
            ?: throw IllegalStateException("RenderingControl service not found on device $deviceUdn")
        var volume: Long = 0L
        var muted = false
        val semaphore = Semaphore(0)
        val getVolumeAction = object : GetVolume(renderingControlService) {
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("VolumeManager", "GetVolume failed for device $deviceUdn: $defaultMsg")
                semaphore.release()
            }
            override fun received(actionInvocation: ActionInvocation<*>?, currentVolume: Int) {
                volume = currentVolume.toLong()
                semaphore.release()
            }
        }
        upnpService?.controlPoint?.execute(getVolumeAction)
        try { semaphore.tryAcquire(3, TimeUnit.SECONDS) } catch (e: InterruptedException) {}
        val muteSemaphore = Semaphore(0)
        val getMuteAction = object : GetMute(renderingControlService) {
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("VolumeManager", "GetMute failed for device $deviceUdn: $defaultMsg")
                muteSemaphore.release()
            }
            override fun received(actionInvocation: ActionInvocation<*>?, currentMute: Boolean) {
                muted = currentMute
                muteSemaphore.release()
            }
        }
        upnpService?.controlPoint?.execute(getMuteAction)
        try { muteSemaphore.tryAcquire(3, TimeUnit.SECONDS) } catch (e: InterruptedException) {}
        return VolumeInfo(volume, muted)
    }

    fun setMute(deviceUdn: String, muted: Boolean) {
        val device = deviceFinder(deviceUdn) ?: throw IllegalArgumentException("Device with UDN $deviceUdn not found")
        val renderingControlService = device.findService(UDAServiceId("RenderingControl"))
            ?: throw IllegalStateException("RenderingControl service not found on device $deviceUdn")
        val setMuteAction = renderingControlService.getAction("SetMute")
            ?: throw IllegalStateException("SetMute action not available on device $deviceUdn")
        val actionInvocation = ActionInvocation(setMuteAction)
        actionInvocation.setInput("InstanceID", UnsignedIntegerFourBytes(0))
        actionInvocation.setInput("Channel", "Master")
        actionInvocation.setInput("DesiredMute", muted)
        val setMuteCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("VolumeManager", "SetMute successful for device $deviceUdn to $muted")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("VolumeManager", "SetMute failed for device $deviceUdn: $defaultMsg")
                throw RuntimeException("Failed to set mute: $defaultMsg")
            }
        }
        upnpService?.controlPoint?.execute(setMuteCallback)
    }
}

