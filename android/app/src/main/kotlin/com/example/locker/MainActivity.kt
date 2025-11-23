package com.example.locker

import android.media.MediaScannerConnection
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.locker/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        scanFile(path)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scanFile(path: String) {
        MediaScannerConnection.scanFile(
            this,
            arrayOf(path),
            null
        ) { scanPath, uri ->
            android.util.Log.d("MediaScanner", "Scanned $scanPath: $uri")
        }
    }
}
