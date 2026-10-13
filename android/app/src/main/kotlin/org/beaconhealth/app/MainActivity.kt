package org.beaconhealth.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var assistant: AssistantBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val bridge = AssistantBridge()
        assistant = bridge
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AssistantBridge.CHANNEL)
            .setMethodCallHandler(bridge)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        assistant?.dispose()
        assistant = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
