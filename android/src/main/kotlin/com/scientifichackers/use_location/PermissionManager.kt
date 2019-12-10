package com.scientifichackers.use_location

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.Build.VERSION.SDK_INT
import android.provider.Settings
import androidx.annotation.RequiresApi
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.LocationSettingsStatusCodes
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import java.util.ArrayDeque
import java.util.NoSuchElementException

enum class InternalStatus {
    OK,
    ENABLE_DENIED,
    PERMISSION_DENIED,
    SHOW_PERMISSION_RATIONALE,
    OPEN_PERMISSION_SETTINGS,
    OPEN_ENABLE_SETTINGS
}

typealias InternalStatusCallback = (InternalStatus) -> Unit

class PermissionManager(val registrar: PluginRegistry.Registrar) :
    ActivityResultListener,
    RequestPermissionsResultListener {

    val activity: Activity
        get() = registrar.activity()
    val ctx: Context
        get() = activity.applicationContext

    val requestEnableResultCode = randomResultCode()
    val requestPermissionResultCode = randomResultCode()
    val enableCallback = ArrayDeque<InternalStatusCallback>()
    val permissionCallback = ArrayDeque<Pair<String, InternalStatusCallback>>()

    init {
        registrar.addActivityResultListener(this)
        registrar.addRequestPermissionsResultListener(this)
    }

    fun hasPermission(perm: String): Boolean {
        return SDK_INT < Build.VERSION_CODES.M
            || ctx.checkSelfPermission(perm) == PackageManager.PERMISSION_GRANTED
    }

    @RequiresApi(Build.VERSION_CODES.M)
    fun requestPermission(perm: String, callback: InternalStatusCallback) {
        activity.requestPermissions(arrayOf(perm), requestPermissionResultCode)
        permissionCallback.add(Pair(perm, callback))
    }

    fun ensurePermission(
        perm: String,
        considerShowRationale: Boolean,
        callback: InternalStatusCallback
    ) {
        if (hasPermission(perm)) {
            return callback(InternalStatus.OK)
        }
        if (considerShowRationale && activity.shouldShowRequestPermissionRationale(perm)) {
            callback(InternalStatus.SHOW_PERMISSION_RATIONALE)
        } else {
            requestPermission(perm, callback)
        }
    }

    fun isGooglePlayServicesAvailable(): Boolean {
        return GoogleApiAvailability
            .getInstance()
            .isGooglePlayServicesAvailable(ctx) == ConnectionResult.SUCCESS
    }

    fun ensureEnabledWithGPlay(callback: InternalStatusCallback) {
        val request = LocationSettingsRequest.Builder()
            .addLocationRequest(LocationRequest())
            .setAlwaysShow(true)
            .build()

        val taskResult = LocationServices.getSettingsClient(ctx)
            .checkLocationSettings(request)

        taskResult.addOnCompleteListener {
            val response = try {
                taskResult.getResult(ApiException::class.java)
            } catch (e: ApiException) {
                if (e.statusCode == LocationSettingsStatusCodes.RESOLUTION_REQUIRED) {
                    val resolvable = e as ResolvableApiException
                    resolvable.startResolutionForResult(
                        activity,
                        requestEnableResultCode
                    )
                    enableCallback.add(callback)
                    return@addOnCompleteListener
                }
                null
            }

            callback(
                if (response != null && response.locationSettingsStates.isLocationUsable) {
                    InternalStatus.OK
                } else {
                    InternalStatus.ENABLE_DENIED
                }
            )
        }
    }

    fun ensureEnabledWithoutGPlay(callback: InternalStatusCallback) {
        val enabled = if (SDK_INT >= Build.VERSION_CODES.P) {
            val manager = ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            manager.isLocationEnabled
        } else {
            val locationMode = Settings.Secure.getInt(
                activity.contentResolver, Settings.Secure.LOCATION_MODE
            )
            locationMode != Settings.Secure.LOCATION_MODE_OFF
        }

        callback(
            if (enabled) {
                InternalStatus.OK
            } else {
                InternalStatus.OPEN_ENABLE_SETTINGS
            }
        )
    }

    fun ensureEnabled(
        callback: InternalStatusCallback
    ) {
        if (isGooglePlayServicesAvailable()) {
            ensureEnabledWithGPlay(callback)
        } else {
            ensureEnabledWithoutGPlay(callback)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (requestCode != requestEnableResultCode) {
            return false
        }

        val callback = try {
            enableCallback.remove()
        } catch (e: NoSuchElementException) {
            return false
        }

        callback(
            when (resultCode) {
                Activity.RESULT_OK -> {
                    InternalStatus.OK
                }
                Activity.RESULT_CANCELED -> {
                    InternalStatus.ENABLE_DENIED
                }
                else -> {
                    throw IllegalArgumentException(
                        "unexpected \"resultCode\" for requestEnableResultCode { $resultCode }"
                    )
                }
            }
        )

        return true
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>?,
        grantResults: IntArray?
    ): Boolean {
        if (requestCode != requestPermissionResultCode) {
            return false
        }

        val (perm, callback) = try {
            permissionCallback.remove()
        } catch (e: NoSuchElementException) {
            return false
        }

        val granted = try {
            grantResults?.first() == PackageManager.PERMISSION_GRANTED
        } catch (e: NoSuchElementException) {
            false
        }

        callback(
            if (granted) {
                InternalStatus.OK
            } else if (SDK_INT >= Build.VERSION_CODES.M) {
                if (activity.shouldShowRequestPermissionRationale(perm)) {
                    InternalStatus.PERMISSION_DENIED
                } else {
                    InternalStatus.OPEN_PERMISSION_SETTINGS
                }
            } else {
                InternalStatus.PERMISSION_DENIED
            }
        )

        return true
    }
}