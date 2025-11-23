package com.example.locker

import android.app.RecoverableSecurityException
import android.content.ContentResolver
import android.content.ContentUris
import android.content.IntentSender
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.locker/media_scanner"
    private var pendingResult: MethodChannel.Result? = null

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
                "deleteFromGallery" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        deleteFromGallery(path, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
                    }
                }
                "deleteMediaByUri" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        deleteMediaByUri(uriString, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is required", null)
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

    private fun deleteFromGallery(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            
            // Delete the physical file if it exists
            var fileDeleted = false
            if (file.exists()) {
                fileDeleted = file.delete()
                android.util.Log.d("MediaScanner", "File deleted: $fileDeleted")
            }

            // Delete from MediaStore
            val contentResolver: ContentResolver = contentResolver
            val uri: Uri = MediaStore.Files.getContentUri("external")
            
            val selection = "${MediaStore.MediaColumns.DATA} = ?"
            val selectionArgs = arrayOf(filePath)
            
            val deletedRows = contentResolver.delete(uri, selection, selectionArgs)
            android.util.Log.d("MediaScanner", "MediaStore rows deleted: $deletedRows")
            
            // Trigger media scan to update the gallery
            MediaScannerConnection.scanFile(
                this,
                arrayOf(filePath),
                null
            ) { path, uri ->
                android.util.Log.d("MediaScanner", "Post-delete scan complete: $path")
            }
            
            result.success(fileDeleted || deletedRows > 0)
        } catch (e: Exception) {
            android.util.Log.e("MediaScanner", "Error deleting from gallery: ${e.message}")
            result.success(false)
        }
    }

    private fun deleteMediaByUri(uriString: String, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse(uriString)
            val contentResolver: ContentResolver = contentResolver
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+ (API 30+) - Need to use PendingIntent for user permission
                try {
                    val deletedRows = contentResolver.delete(uri, null, null)
                    android.util.Log.d("MediaScanner", "Deleted $deletedRows rows for URI: $uriString")
                    result.success(deletedRows > 0)
                } catch (securityException: SecurityException) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val recoverableSecurityException =
                            securityException as? RecoverableSecurityException
                                ?: throw securityException

                        // Request user permission via system dialog
                        val intentSender = recoverableSecurityException.userAction.actionIntent.intentSender
                        pendingResult = result
                        
                        try {
                            startIntentSenderForResult(
                                intentSender,
                                DELETE_REQUEST_CODE,
                                null,
                                0,
                                0,
                                0,
                                null
                            )
                        } catch (e: IntentSender.SendIntentException) {
                            android.util.Log.e("MediaScanner", "Error starting intent: ${e.message}")
                            result.error("INTENT_ERROR", "Failed to request permission", null)
                        }
                    } else {
                        throw securityException
                    }
                }
            } else {
                // Android 10 and below
                val deletedRows = contentResolver.delete(uri, null, null)
                android.util.Log.d("MediaScanner", "Deleted $deletedRows rows for URI: $uriString")
                result.success(deletedRows > 0)
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaScanner", "Error deleting media by URI: ${e.message}")
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == DELETE_REQUEST_CODE) {
            val result = pendingResult
            pendingResult = null
            
            if (resultCode == RESULT_OK) {
                android.util.Log.d("MediaScanner", "User granted permission to delete")
                result?.success(true)
            } else {
                android.util.Log.d("MediaScanner", "User denied permission to delete")
                result?.success(false)
            }
        }
    }

    companion object {
        private const val DELETE_REQUEST_CODE = 1001
    }
}
