package org.getlantern.lantern.utils

import android.content.Context
import android.content.SharedPreferences

/**
 * Stores a user-provided custom device ID (Android ID override).
 *
 * The value lives in its own app-private SharedPreferences file so it can be
 * read, replaced, or cleared independently of every other app setting. When a
 * valid custom ID is stored, [DeviceUtil.deviceId] returns it instead of the
 * system Settings.Secure.ANDROID_ID.
 *
 * A custom ID must look like an Android ID: exactly 16 hexadecimal
 * characters. Values are validated on write and stored lowercase.
 */
object CustomDeviceIdStore {

    private const val PREFS_NAME = "custom_device_id_store"
    private const val KEY_CUSTOM_DEVICE_ID = "custom_device_id"

    private val ID_PATTERN = Regex("^[0-9a-fA-F]{16}$")

    fun isValidDeviceId(id: String): Boolean = ID_PATTERN.matches(id)

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** The stored custom device ID (lowercase), or null when none is set. */
    fun getCustomDeviceId(context: Context): String? {
        val stored = prefs(context).getString(KEY_CUSTOM_DEVICE_ID, null) ?: return null
        // A value that no longer validates is treated as unset.
        return if (isValidDeviceId(stored)) stored.lowercase() else null
    }

    /**
     * Validates and stores [id], normalized to lowercase.
     * Returns false (and stores nothing) when [id] is not 16 hex characters.
     */
    fun setCustomDeviceId(context: Context, id: String): Boolean {
        if (!isValidDeviceId(id)) return false
        return prefs(context).edit()
            .putString(KEY_CUSTOM_DEVICE_ID, id.lowercase())
            .commit()
    }

    /** Removes the custom device ID, restoring the system Android ID. */
    fun clearCustomDeviceId(context: Context) {
        prefs(context).edit().remove(KEY_CUSTOM_DEVICE_ID).apply()
    }
}
