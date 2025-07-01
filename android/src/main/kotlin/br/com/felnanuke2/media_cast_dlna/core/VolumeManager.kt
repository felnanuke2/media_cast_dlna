package br.com.felnanuke2.media_cast_dlna.core

import VolumeInfo
import android.util.Log
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import org.jupnp.android.AndroidUpnpService
import org.jupnp.model.action.ActionInvocation
import org.jupnp.model.message.UpnpResponse
import org.jupnp.model.types.UnsignedIntegerFourBytes
import org.jupnp.model.types.UnsignedIntegerTwoBytes
import org.jupnp.controlpoint.ActionCallback

class VolumeManager(upnpService: AndroidUpnpService?) : BaseManager(upnpService) {
    
    /**
     * Sets volume using coroutines
     */
    suspend fun setVolume(deviceUdn: String, volume: Long) {
        val (_, renderingControlService) = requireDeviceAndService(deviceUdn, "RenderingControl")
        val controlPoint = requireUpnpService().controlPoint
        
        val setVolumeAction = renderingControlService.getAction("SetVolume")
            ?: throw IllegalStateException("SetVolume action not available on device $deviceUdn")
        
        val actionInvocation = ActionInvocation(setVolumeAction).apply {
            setInput("InstanceID", UnsignedIntegerFourBytes(0))
            setInput("Channel", "Master")
            setInput("DesiredVolume", UnsignedIntegerTwoBytes(volume))
        }
        
        val setVolumeCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("VolumeManager", "SetVolume successful for device $deviceUdn to $volume")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("VolumeManager", "SetVolume failed for device $deviceUdn: $defaultMsg")
            }
        }
        
        controlPoint.executeSuspending(setVolumeCallback)
    }

    /**
     * Gets volume info using coroutines (runs volume and mute queries concurrently)
     */
    suspend fun getVolumeInfo(deviceUdn: String): VolumeInfo = coroutineScope {
        val (_, renderingControlService) = requireDeviceAndService(deviceUdn, "RenderingControl")
        val controlPoint = requireUpnpService().controlPoint
        
        try {
            // Execute both queries concurrently for better performance
            val volumeDeferred = async { 
                controlPoint.getVolumeSuspending(renderingControlService) 
            }
            val muteDeferred = async { 
                controlPoint.getMuteSuspending(renderingControlService) 
            }
            
            val volume = volumeDeferred.await()
            val muted = muteDeferred.await()
            
            VolumeInfo(volume.toLong(), muted)
        } catch (e: Exception) {
            Log.e("VolumeManager", "Failed to get volume info for device $deviceUdn", e)
            VolumeInfo(0L, false)
        }
    }

    /**
     * Sets mute state using coroutines
     */
    suspend fun setMute(deviceUdn: String, muted: Boolean) {
        val (_, renderingControlService) = requireDeviceAndService(deviceUdn, "RenderingControl")
        val controlPoint = requireUpnpService().controlPoint
        
        val setMuteAction = renderingControlService.getAction("SetMute")
            ?: throw IllegalStateException("SetMute action not available on device $deviceUdn")
        
        val actionInvocation = ActionInvocation(setMuteAction).apply {
            setInput("InstanceID", UnsignedIntegerFourBytes(0))
            setInput("Channel", "Master")
            setInput("DesiredMute", muted)
        }
        
        val setMuteCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("VolumeManager", "SetMute successful for device $deviceUdn to $muted")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("VolumeManager", "SetMute failed for device $deviceUdn: $defaultMsg")
            }
        }
        
        controlPoint.executeSuspending(setMuteCallback)
    }
}

