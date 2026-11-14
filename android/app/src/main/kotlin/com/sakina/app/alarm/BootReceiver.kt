package com.sakina.app.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BootReceiver — listens for:
 *   - android.intent.action.BOOT_COMPLETED
 *   - android.intent.action.MY_PACKAGE_REPLACED
 *   - android.intent.action.TIME_SET
 *   - android.intent.action.TIMEZONE_CHANGED
 *
 * On any of these events, prayer alarms must be rescheduled because
 * AlarmManager alarms do NOT survive a device reboot.
 *
 * This receiver also sends a broadcast that the Flutter Engine (if running)
 * can listen to via AlarmBridgePlugin's EventChannel.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"

        // Public broadcast that Flutter side can receive via EventChannel
        const val ACTION_RESCHEDULE_NEEDED = "com.sakina.app.ACTION_RESCHEDULE_NEEDED"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        Log.i(TAG, "Received: $action")

        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                val pendingResult = goAsync()
                Thread {
                    try {
                        handleReschedule(context, action)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error in background reschedule: ${e.message}", e)
                    } finally {
                        pendingResult.finish()
                    }
                }.start()
            }
        }
    }

    private fun handleReschedule(context: Context, triggerAction: String) {
        // Try to reschedule from stored prayer times
        val success = AlarmScheduler.rescheduleFromStorage(context)

        if (success) {
            Log.i(TAG, "Alarms rescheduled after: $triggerAction")
        } else {
            Log.w(TAG, "No stored prayer times – Flutter must reschedule after launch")
        }

        // Broadcast so that if the Flutter engine is alive (WorkManager / background isolate),
        // it can respond by pushing fresh prayer times.
        val rescheduleIntent = Intent(ACTION_RESCHEDULE_NEEDED).apply {
            setPackage(context.packageName)
            putExtra("trigger", triggerAction)
            putExtra("rescheduled_from_storage", success)
        }
        context.sendBroadcast(rescheduleIntent)

        // Also attempt to wake the app via WorkManager if available, so Flutter
        // can recalculate prayer times for the new timezone / date.
        scheduleRescheduleWorker(context, triggerAction)
    }

    /**
     * Enqueue a one-time WorkManager job so the Flutter isolate is started
     * and can push updated prayer times back to AlarmScheduler.
     *
     * We use reflection so this code compiles even if WorkManager is not on
     * the classpath (optional dependency), and we fall back gracefully.
     */
    private fun scheduleRescheduleWorker(context: Context, triggerAction: String) {
        try {
            val workerClass = Class.forName("com.sakina.app.worker.RescheduleWorker")
            val workManagerClass = Class.forName("androidx.work.WorkManager")
            val oneTimeWorkRequestBuilderClass =
                Class.forName("androidx.work.OneTimeWorkRequest\$Builder")

            val builder = oneTimeWorkRequestBuilderClass.getDeclaredConstructor(Class::class.java)
                .newInstance(workerClass)

            // Build data with trigger action
            val dataBuilderClass = Class.forName("androidx.work.Data\$Builder")
            val dataBuilder = dataBuilderClass.newInstance()
            dataBuilderClass.getMethod("putString", String::class.java, String::class.java)
                .invoke(dataBuilder, "trigger", triggerAction)
            val data = dataBuilderClass.getMethod("build").invoke(dataBuilder)

            // Set input data
            oneTimeWorkRequestBuilderClass.getMethod(
                "setInputData",
                Class.forName("androidx.work.Data")
            ).invoke(builder, data)

            val request = oneTimeWorkRequestBuilderClass.getMethod("build").invoke(builder)

            // Enqueue
            val workManager = workManagerClass.getMethod(
                "getInstance", Context::class.java
            ).invoke(null, context)
            workManagerClass.getMethod(
                "enqueue",
                Class.forName("androidx.work.WorkRequest")
            ).invoke(workManager, request)

            Log.d(TAG, "RescheduleWorker enqueued")
        } catch (e: ClassNotFoundException) {
            Log.d(TAG, "WorkManager not available – skipping worker enqueue")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to enqueue RescheduleWorker: ${e.message}")
        }
    }
}
