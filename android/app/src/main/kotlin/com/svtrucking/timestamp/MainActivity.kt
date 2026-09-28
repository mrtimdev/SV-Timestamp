package com.svtrucking.timestamp

import android.view.OrientationEventListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var orientationChannel: EventChannel? = null
    private var orientationListener: OrientationEventListener? = null
    private var orientationEvents: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        orientationChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.svtrucking.timestamp/device_orientation"
        ).also { channel ->
            channel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    orientationListener?.disable()
                    orientationEvents = events
                    orientationListener = object : OrientationEventListener(this@MainActivity) {
                        override fun onOrientationChanged(orientation: Int) {
                            if (orientation != ORIENTATION_UNKNOWN) {
                                // Read the sensor angle, not Configuration.orientation:
                                // the Flutter activity deliberately stays in portrait.
                                orientationEvents?.success(orientation)
                            }
                        }
                    }.also { listener ->
                        if (listener.canDetectOrientation()) {
                            listener.enable()
                        } else {
                            events.error("unavailable", "No orientation sensor is available", null)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    orientationListener?.disable()
                    orientationListener = null
                    orientationEvents = null
                }
            })
        }
    }

    override fun onResume() {
        super.onResume()
        orientationListener?.enable()
    }

    override fun onPause() {
        orientationListener?.disable()
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        orientationListener?.disable()
        orientationListener = null
        orientationEvents = null
        orientationChannel?.setStreamHandler(null)
        orientationChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
