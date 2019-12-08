package com.scientifichackers.use_location

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import com.pycampers.plugin_scaffold.createPluginScaffold
import com.pycampers.plugin_scaffold.trySend
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

enum class LocationPermissionType {
    ACCESS_FINE_LOCATION,
    ACCESS_COARSE_LOCATION
}

fun parsePermissionType(typeIndex: Int): String {
    val type = LocationPermissionType.values()[typeIndex]
    return when (type) {
        LocationPermissionType.ACCESS_FINE_LOCATION -> Manifest.permission.ACCESS_FINE_LOCATION
        LocationPermissionType.ACCESS_COARSE_LOCATION -> Manifest.permission.ACCESS_COARSE_LOCATION
    }
}

class UseLocationPlugin(val registrar: Registrar) {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            createPluginScaffold(
                registrar.messenger(),
                "com.scientifichackers.use_location",
                UseLocationPlugin(registrar)
            )
        }
    }

    val activity = registrar.activity()
    val perm = PermissionManager(registrar)

    fun useLocation(call: MethodCall, result: Result) {
        val permissionType = call.argument<Int>("permissionType")!!

        perm.ensurePermission(parsePermissionType(permissionType), true) {
            if (it == InternalStatus.OK) {
                perm.ensureEnabled {
                    trySend(result) { it.ordinal }
                }
            } else {
                trySend(result) { it.ordinal }
            }
        }
    }

    fun ensurePermission(call: MethodCall, result: Result) {
        val considerShowRationale = call.argument<Boolean>("considerShowRationale")!!
        val permissionType = call.argument<Int>("permissionType")!!

        perm.ensurePermission(parsePermissionType(permissionType), considerShowRationale) {
            trySend(result) { it.ordinal }
        }
    }

    fun openPermissionSettings(call: MethodCall, result: Result) {
        activity.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", activity.packageName, null)
            }
        )
        result.success(null)
    }

    fun openEnableSettings(call: MethodCall, result: Result) {
        activity.startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
        result.success(null)
    }
}
