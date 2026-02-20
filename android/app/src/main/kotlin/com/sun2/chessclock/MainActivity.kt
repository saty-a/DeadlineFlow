package com.sun2.chessclock
import android.app.Activity
import android.content.Intent
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "de.ffuf.in_app_update/methods"
    private val EVENT_CHANNEL = "de.ffuf.in_app_update/stateEvents"
    private val REQUEST_CODE_UPDATE = 1234

    // Simulation mode is currently disabled because the testing library version was not found.
    // Use Internal App Sharing (as described in testing_guide.md) to test the real UI.
    private val USE_FAKE_UPDATE_MANAGER = false 

    private lateinit var appUpdateManager: AppUpdateManager
    private var installStateUpdatedListener: InstallStateUpdatedListener? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        appUpdateManager = AppUpdateManagerFactory.create(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkForUpdate" -> checkForUpdate(result)
                "performImmediateUpdate" -> performImmediateUpdate(result)
                "startFlexibleUpdate" -> startFlexibleUpdate(result)
                "completeFlexibleUpdate" -> completeFlexibleUpdate(result)
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    installStateUpdatedListener = InstallStateUpdatedListener { state ->
                        eventSink?.success(state.installStatus())
                    }
                    appUpdateManager.registerListener(installStateUpdatedListener!!)
                }

                override fun onCancel(arguments: Any?) {
                    installStateUpdatedListener?.let {
                        appUpdateManager.unregisterListener(it)
                    }
                    installStateUpdatedListener = null
                    eventSink = null
                }
            }
        )
    }

    private fun checkForUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo.addOnSuccessListener { info ->
            val data = mutableMapOf<String, Any?>(
                "updateAvailability" to info.updateAvailability(),
                "immediateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                "flexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                "availableVersionCode" to info.availableVersionCode(),
                "installStatus" to info.installStatus(),
                "packageName" to info.packageName(),
                "clientVersionStalenessDays" to info.clientVersionStalenessDays(),
                "updatePriority" to info.updatePriority()
            )
            result.success(data)
        }.addOnFailureListener { e ->
            result.error("CHECK_FAILED", e.message, null)
        }
    }

    private fun performImmediateUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo.addOnSuccessListener { info ->
            if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                && info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
            ) {
                pendingResult = result
                appUpdateManager.startUpdateFlowForResult(
                    info,
                    AppUpdateType.IMMEDIATE,
                    this,
                    REQUEST_CODE_UPDATE
                )
            } else {
                result.error("UPDATE_NOT_ALLOWED", "Immediate update not allowed or unavailable", null)
            }
        }
    }

    private fun startFlexibleUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo.addOnSuccessListener { info ->
            if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                && info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
            ) {
                pendingResult = result
                appUpdateManager.startUpdateFlowForResult(
                    info,
                    AppUpdateType.FLEXIBLE,
                    this,
                    REQUEST_CODE_UPDATE
                )
            } else {
                result.error("UPDATE_NOT_ALLOWED", "Flexible update not allowed or unavailable", null)
            }
        }
    }

    private fun completeFlexibleUpdate(result: MethodChannel.Result) {
        appUpdateManager.completeUpdate().addOnSuccessListener {
            result.success(null)
        }.addOnFailureListener { e ->
            result.error("COMPLETE_FAILED", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_UPDATE) {
            when (resultCode) {
                Activity.RESULT_OK -> pendingResult?.success(null)
                Activity.RESULT_CANCELED -> pendingResult?.error("USER_DENIED_UPDATE", "User denied update", null)
                else -> pendingResult?.error("IN_APP_UPDATE_FAILED", "Update failed with result code: $resultCode", null)
            }
            pendingResult = null
        }
    }
}
