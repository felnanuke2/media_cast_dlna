package br.com.felnanuke2.media_cast_dlna.core

import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeout
import org.jupnp.controlpoint.ActionCallback
import org.jupnp.controlpoint.ControlPoint
import org.jupnp.model.action.ActionInvocation
import org.jupnp.model.message.UpnpResponse
import org.jupnp.support.avtransport.callback.GetPositionInfo
import org.jupnp.support.avtransport.callback.GetTransportInfo
import org.jupnp.support.renderingcontrol.callback.GetVolume
import org.jupnp.support.renderingcontrol.callback.GetMute
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Extension function to execute UPnP actions as suspend functions
 */
suspend fun <T : ActionCallback> ControlPoint.executeSuspending(
    callback: T,
    timeoutMs: Long = 15000 // Increased timeout to 15 seconds
): T = withTimeout(timeoutMs) {
    android.util.Log.d("JupnpExtensions", "executeSuspending called with timeout: ${timeoutMs}ms")
    android.util.Log.d("JupnpExtensions", "Callback type: ${callback.javaClass.simpleName}")
    android.util.Log.d("JupnpExtensions", "Action: ${callback.actionInvocation?.action?.name}")
    
    suspendCancellableCoroutine { continuation ->
        android.util.Log.d("JupnpExtensions", "Creating wrapper callback...")
        
        val startTime = System.currentTimeMillis()
        
        val originalCallback = object : ActionCallback(callback.actionInvocation) {
            override fun success(invocation: ActionInvocation<*>?) {
                val duration = System.currentTimeMillis() - startTime
                android.util.Log.d("JupnpExtensions", "Action successful after ${duration}ms, calling original callback success...")
                try {
                    // Call the original callback's success method if it has custom logic
                    callback.success(invocation)
                    android.util.Log.d("JupnpExtensions", "Original callback success completed, resuming coroutine...")
                    continuation.resume(callback)
                } catch (e: Exception) {
                    android.util.Log.e("JupnpExtensions", "Exception in success callback", e)
                    continuation.resumeWithException(e)
                }
            }

            override fun failure(invocation: ActionInvocation<*>?, response: UpnpResponse?, defaultMsg: String?) {
                val duration = System.currentTimeMillis() - startTime
                android.util.Log.e("JupnpExtensions", "Action failed after ${duration}ms: $defaultMsg")
                response?.let { resp ->
                    android.util.Log.e("JupnpExtensions", "Response details: ${resp.responseDetails}")
                    android.util.Log.e("JupnpExtensions", "Response message: ${resp.statusMessage}")
                }
                
                try {
                    // Call the original callback's failure method if it has custom logic
                    callback.failure(invocation, response, defaultMsg)
                    android.util.Log.d("JupnpExtensions", "Original callback failure completed, resuming with exception...")
                    val exception = RuntimeException(defaultMsg ?: "UPnP action failed")
                    continuation.resumeWithException(exception)
                } catch (e: Exception) {
                    android.util.Log.e("JupnpExtensions", "Exception in failure callback", e)
                    continuation.resumeWithException(e)
                }
            }
        }

        android.util.Log.d("JupnpExtensions", "Executing action with control point...")
        try {
            execute(originalCallback)
            android.util.Log.d("JupnpExtensions", "Action submitted to control point successfully")
        } catch (e: Exception) {
            android.util.Log.e("JupnpExtensions", "Failed to execute action", e)
            continuation.resumeWithException(e)
            return@suspendCancellableCoroutine
        }

        // Handle cancellation
        continuation.invokeOnCancellation {
            // jupnp doesn't have direct cancellation, but we can log it
            val duration = System.currentTimeMillis() - startTime
            android.util.Log.d("JupnpExtensions", "Coroutine was cancelled after ${duration}ms")
        }
    }
}

/**
 * Specific extension for GetPositionInfo with better type safety
 */
suspend fun ControlPoint.getPositionInfoSuspending(
    service: org.jupnp.model.meta.Service<*, *>,
    timeoutMs: Long = 5000
): org.jupnp.support.model.PositionInfo? = withTimeout(timeoutMs) {
    suspendCancellableCoroutine { continuation ->
        var positionInfo: org.jupnp.support.model.PositionInfo? = null
        
        val callback = object : GetPositionInfo(service) {
            override fun received(
                invocation: ActionInvocation<*>?,
                info: org.jupnp.support.model.PositionInfo?
            ) {
                positionInfo = info
                continuation.resume(positionInfo)
            }

            override fun failure(
                invocation: ActionInvocation<*>?,
                operation: UpnpResponse?,
                defaultMsg: String?
            ) {
                val exception = RuntimeException(defaultMsg ?: "GetPositionInfo failed")
                continuation.resumeWithException(exception)
            }
        }

        execute(callback)

        continuation.invokeOnCancellation {
            android.util.Log.d("JupnpExtensions", "GetPositionInfo was cancelled")
        }
    }
}

/**
 * Specific extension for GetTransportInfo with better type safety
 */
suspend fun ControlPoint.getTransportInfoSuspending(
    service: org.jupnp.model.meta.Service<*, *>,
    timeoutMs: Long = 5000
): org.jupnp.support.model.TransportInfo? = withTimeout(timeoutMs) {
    suspendCancellableCoroutine { continuation ->
        var transportInfo: org.jupnp.support.model.TransportInfo? = null
        
        val callback = object : GetTransportInfo(service) {
            override fun received(
                invocation: ActionInvocation<*>?,
                info: org.jupnp.support.model.TransportInfo?
            ) {
                transportInfo = info
                continuation.resume(transportInfo)
            }

            override fun failure(
                invocation: ActionInvocation<*>?,
                operation: UpnpResponse?,
                defaultMsg: String?
            ) {
                val exception = RuntimeException(defaultMsg ?: "GetTransportInfo failed")
                continuation.resumeWithException(exception)
            }
        }

        execute(callback)

        continuation.invokeOnCancellation {
            android.util.Log.d("JupnpExtensions", "GetTransportInfo was cancelled")
        }
    }
}

/**
 * Specific extension for GetVolume with better type safety
 */
suspend fun ControlPoint.getVolumeSuspending(
    service: org.jupnp.model.meta.Service<*, *>,
    timeoutMs: Long = 5000
): Int = withTimeout(timeoutMs) {
    suspendCancellableCoroutine { continuation ->
        var volume = 0
        
        val callback = object : GetVolume(service) {
            override fun received(invocation: ActionInvocation<*>?, currentVolume: Int) {
                volume = currentVolume
                continuation.resume(volume)
            }

            override fun failure(
                invocation: ActionInvocation<*>?,
                operation: UpnpResponse?,
                defaultMsg: String?
            ) {
                val exception = RuntimeException(defaultMsg ?: "GetVolume failed")
                continuation.resumeWithException(exception)
            }
        }

        execute(callback)

        continuation.invokeOnCancellation {
            android.util.Log.d("JupnpExtensions", "GetVolume was cancelled")
        }
    }
}

/**
 * Specific extension for GetMute with better type safety
 */
suspend fun ControlPoint.getMuteSuspending(
    service: org.jupnp.model.meta.Service<*, *>,
    timeoutMs: Long = 5000
): Boolean = withTimeout(timeoutMs) {
    suspendCancellableCoroutine { continuation ->
        var isMuted = false
        
        val callback = object : GetMute(service) {
            override fun received(invocation: ActionInvocation<*>?, currentMute: Boolean) {
                isMuted = currentMute
                continuation.resume(isMuted)
            }

            override fun failure(
                invocation: ActionInvocation<*>?,
                operation: UpnpResponse?,
                defaultMsg: String?
            ) {
                val exception = RuntimeException(defaultMsg ?: "GetMute failed")
                continuation.resumeWithException(exception)
            }
        }

        execute(callback)

        continuation.invokeOnCancellation {
            android.util.Log.d("JupnpExtensions", "GetMute was cancelled")
        }
    }
}
