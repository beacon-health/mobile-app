package org.beaconhealth.app

import android.os.Build
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * The Ask tab's bridge to Gemini Nano, the language model that runs on the
 * phone, through ML Kit's GenAI Prompt API. Nothing is sent off the device.
 *
 * The Dart side (`MethodChannelAssistantModel`) writes every prompt; this
 * class only reports whether the model can be used and runs what it is given.
 * iOS has the same two calls over Apple's Foundation Models.
 */
class AssistantBridge : MethodChannel.MethodCallHandler {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    // Made on first use, and only on Android 8+: the library is built for
    // API 26, and the app still installs on 24 and 25.
    private val model: GenerativeModel by lazy { Generation.getClient() }
    private var downloadStarted = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "availability" -> scope.launch { result.success(availability()) }
            "extractFilters" -> {
                val instructions = call.argument<String>("instructions")
                val prompt = call.argument<String>("prompt")
                if (instructions == null || prompt == null) {
                    result.error("bad_arguments", "instructions and prompt are required", null)
                    return
                }
                scope.launch {
                    try {
                        result.success(generate(instructions, prompt))
                    } catch (e: Exception) {
                        // Busy, over quota, blocked in the background, or a
                        // reply the model refused: Dart treats every failure
                        // the same way, by handing the request to the Map.
                        result.error("generation_failed", e.message, null)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        scope.cancel()
    }

    /**
     * "available", "notReady" (the phone can run the model and is fetching
     * it) or "unsupported". Asking is also what starts the download, so a
     * phone that can run the model has it by the time Ask is opened again.
     */
    private suspend fun availability(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return "unsupported"
        return try {
            when (model.checkStatus()) {
                FeatureStatus.AVAILABLE -> "available"
                FeatureStatus.DOWNLOADING -> "notReady"
                FeatureStatus.DOWNLOADABLE -> {
                    startDownload()
                    "notReady"
                }
                else -> "unsupported"
            }
        } catch (e: Exception) {
            "unsupported"
        }
    }

    private fun startDownload() {
        if (downloadStarted) return
        downloadStarted = true
        scope.launch {
            try {
                model.download().collect { }
            } catch (e: Exception) {
                // Asked for again the next time the tab is opened.
                downloadStarted = false
            }
        }
    }

    /**
     * Runs one request, with sampling turned down as far as it goes: the
     * reply is a short form to fill in, and the same request should fill it
     * in the same way every time.
     */
    private suspend fun generate(instructions: String, prompt: String): String {
        // The Prompt API takes one block of text, so the instructions lead it.
        val request = generateContentRequest(TextPart("$instructions\n\n$prompt")) {
            temperature = 0f
            topK = 1
            maxOutputTokens = MAX_OUTPUT_TOKENS
        }
        return model.generateContent(request).candidates.firstOrNull()?.text.orEmpty()
    }

    companion object {
        const val CHANNEL = "org.beaconhealth.app/assistant"

        /** Enough for the filters JSON, and no more. */
        private const val MAX_OUTPUT_TOKENS = 256
    }
}
