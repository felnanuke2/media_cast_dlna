package br.com.felnanuke2.media_cast_dlna.core

import android.util.Log
import org.jupnp.android.AndroidUpnpService
import org.jupnp.model.action.ActionInvocation
import org.jupnp.model.message.UpnpResponse
import org.jupnp.model.meta.Device
import org.jupnp.model.types.UDAServiceId
import org.jupnp.support.avtransport.callback.SetAVTransportURI
import org.jupnp.support.avtransport.callback.Play
import org.jupnp.support.avtransport.callback.GetTransportInfo
import org.jupnp.support.model.TransportInfo
import org.jupnp.support.model.TransportState
import org.jupnp.controlpoint.ActionCallback
import org.jupnp.model.types.UnsignedIntegerFourBytes

class MediaControlManager(private val upnpService: AndroidUpnpService?, private val deviceFinder: (String) -> Device<*, *, *>?) {
    fun setMediaUri(deviceUdn: String, uri: String, finalMetadata: String, avTransportService: org.jupnp.model.meta.Service<*, *>) {
        val setAVTransportURIAction = object : SetAVTransportURI(avTransportService, uri, finalMetadata) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "SetAVTransportURI successful for device $deviceUdn")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "SetAVTransportURI failed for device $deviceUdn: $defaultMsg")
                throw RuntimeException("Failed to set media URI: $defaultMsg")
            }
        }
        upnpService?.controlPoint?.execute(setAVTransportURIAction)
    }

    fun play(deviceUdn: String, avTransportService: org.jupnp.model.meta.Service<*, *>) {
        val playAction = object : Play(avTransportService) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Play action successful for device $deviceUdn")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Play action failed for device $deviceUdn: $defaultMsg")
                throw RuntimeException("Failed to play media: $defaultMsg")
            }
        }
        upnpService?.controlPoint?.execute(playAction)
    }

    fun pause(deviceUdn: String, avTransportService: org.jupnp.model.meta.Service<*, *>) {
        val getTransportInfoAction = object : GetTransportInfo(avTransportService) {
            override fun received(invocation: ActionInvocation<*>?, transportInfo: TransportInfo?) {
                if (transportInfo?.currentTransportState != TransportState.PLAYING) {
                    Log.w("MediaCastDlna", "Cannot pause: Device is not in PLAYING state (current: ${transportInfo?.currentTransportState})")
                    return
                }
                val pauseAction = avTransportService.getAction("Pause")
                    ?: throw IllegalStateException("Pause action not available on device $deviceUdn")
                val actionInvocation = ActionInvocation(pauseAction).apply {
                    setInput("InstanceID", "0")
                }
                val pauseCallback = object : ActionCallback(actionInvocation) {
                    override fun success(invocation: ActionInvocation<*>?) {
                        Log.d("MediaCastDlna", "Pause action successful for device $deviceUdn")
                    }
                    override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                        Log.e("MediaCastDlna", "Pause action failed for device $deviceUdn: $defaultMsg")
                    }
                }
                upnpService?.controlPoint?.execute(pauseCallback)
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Failed to get transport info before pausing: $defaultMsg")
            }
        }
        upnpService?.controlPoint?.execute(getTransportInfoAction)
    }

    fun stop(deviceUdn: String, avTransportService: org.jupnp.model.meta.Service<*, *>) {
        val getTransportInfoAction = object : GetTransportInfo(avTransportService) {
            override fun received(invocation: ActionInvocation<*>?, transportInfo: TransportInfo?) {
                if (transportInfo?.currentTransportState == TransportState.STOPPED) {
                    Log.w("MediaCastDlna", "Cannot stop: Device is already in STOPPED state.")
                    return
                }
                val stopAction = avTransportService.getAction("Stop")
                    ?: throw IllegalStateException("Stop action not available on device $deviceUdn")
                val actionInvocation = ActionInvocation(stopAction).apply {
                    setInput("InstanceID", "0")
                }
                val stopCallback = object : ActionCallback(actionInvocation) {
                    override fun success(invocation: ActionInvocation<*>?) {
                        Log.d("MediaCastDlna", "Stop action successful for device $deviceUdn")
                    }
                    override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                        Log.e("MediaCastDlna", "Stop action failed for device $deviceUdn: $defaultMsg")
                    }
                }
                upnpService?.controlPoint?.execute(stopCallback)
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Failed to get transport info before stopping: $defaultMsg")
            }
        }
        upnpService?.controlPoint?.execute(getTransportInfoAction)
    }

    fun seek(deviceUdn: String, actionInvocation: ActionInvocation<*>, timeString: String) {
        val seekCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Seek action successful for device $deviceUdn to $timeString")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Seek action failed for device $deviceUdn: $defaultMsg")
                throw RuntimeException("Failed to seek media: $defaultMsg")
            }
        }
        upnpService?.controlPoint?.execute(seekCallback)
    }

    fun next(deviceUdn: String, avTransportService: org.jupnp.model.meta.Service<*, *>) {
        val nextAction = avTransportService.getAction("Next")
        if (nextAction != null) {
            val actionInvocation = ActionInvocation(nextAction)
            actionInvocation.setInput("InstanceID", UnsignedIntegerFourBytes(0))
            val nextCallback = object : ActionCallback(actionInvocation) {
                override fun success(invocation: ActionInvocation<*>?) {
                    Log.d("MediaCastDlna", "Next action successful for device $deviceUdn")
                }
                override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                    Log.e("MediaCastDlna", "Next action failed for device $deviceUdn: $defaultMsg")
                }
            }
            upnpService?.controlPoint?.execute(nextCallback)
        }
    }

    fun previous(deviceUdn: String, avTransportService: org.jupnp.model.meta.Service<*, *>) {
        val previousAction = avTransportService.getAction("Previous")
            ?: throw IllegalStateException("Previous action not available on device $deviceUdn")
        val actionInvocation = ActionInvocation(previousAction)
        actionInvocation.setInput("InstanceID", UnsignedIntegerFourBytes(0))
        val previousCallback = object : ActionCallback(actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                Log.d("MediaCastDlna", "Previous action successful for device $deviceUdn")
            }
            override fun failure(invocation: ActionInvocation<*>?, operation: UpnpResponse?, defaultMsg: String?) {
                Log.e("MediaCastDlna", "Previous action failed for device $deviceUdn: $defaultMsg")
            }
        }
        upnpService?.controlPoint?.execute(previousCallback)
    }
}

