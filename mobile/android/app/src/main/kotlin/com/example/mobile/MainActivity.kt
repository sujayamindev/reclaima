package com.example.mobile

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smart_receipt/downloads")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"enqueuePdfDownload" -> {
						val url = call.argument<String>("url")
						val fileName = call.argument<String>("fileName")
						val title = call.argument<String>("title") ?: "Claim PDF"
						val description = call.argument<String>("description") ?: "Downloading document. Open notification to view when complete."

						if (url.isNullOrBlank() || fileName.isNullOrBlank()) {
							result.error("INVALID_ARGUMENTS", "Missing url or fileName", null)
							return@setMethodCallHandler
						}

						try {
							val request = DownloadManager.Request(Uri.parse(url)).apply {
								setMimeType("application/pdf")
								setTitle(title)
								setDescription(description)
								setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
								setAllowedOverMetered(true)
								setAllowedOverRoaming(true)
								setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
							}

							val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
							val downloadId = downloadManager.enqueue(request)
							result.success(downloadId.toInt())
						} catch (e: Exception) {
							result.error("DOWNLOAD_FAILED", e.message, null)
						}
					}
					else -> result.notImplemented()
				}
			}
	}
}
