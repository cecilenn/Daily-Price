package com.dailyprice.daily_price

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val systemBarsChannelName = "daily_price/system_bars"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        restoreSystemBars()
    }

    override fun onPostResume() {
        super.onPostResume()
        restoreSystemBars()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            restoreSystemBars()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemBarsChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSystemBars" -> {
                    val statusBarColor = call.argument<Number>("statusBarColor")?.toInt()
                    val navigationBarColor =
                        call.argument<Number>("navigationBarColor")?.toInt()
                    val darkStatusBarIcons =
                        call.argument<Boolean>("darkStatusBarIcons") ?: false
                    val darkNavigationBarIcons =
                        call.argument<Boolean>("darkNavigationBarIcons") ?: false

                    applySystemBarStyle(
                        statusBarColor,
                        navigationBarColor,
                        darkStatusBarIcons,
                        darkNavigationBarIcons
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun restoreSystemBars() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.apply {
                show(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
            }
        }

        val immersiveFlags =
            View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_IMMERSIVE or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY

        window.decorView.systemUiVisibility =
            window.decorView.systemUiVisibility and immersiveFlags.inv()
    }

    @Suppress("DEPRECATION")
    private fun applySystemBarStyle(
        statusBarColor: Int?,
        navigationBarColor: Int?,
        darkStatusBarIcons: Boolean,
        darkNavigationBarIcons: Boolean
    ) {
        restoreSystemBars()

        statusBarColor?.let { window.statusBarColor = it }
        navigationBarColor?.let { window.navigationBarColor = it }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val appearance = statusBarAppearance(darkStatusBarIcons) or
                navigationBarAppearance(darkNavigationBarIcons)
            val mask = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            window.insetsController?.setSystemBarsAppearance(appearance, mask)
            return
        }

        var flags = window.decorView.systemUiVisibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = if (darkStatusBarIcons) {
                flags or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            } else {
                flags and View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR.inv()
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            flags = if (darkNavigationBarIcons) {
                flags or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
            } else {
                flags and View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR.inv()
            }
        }
        window.decorView.systemUiVisibility = flags
    }

    private fun statusBarAppearance(darkIcons: Boolean): Int {
        return if (darkIcons && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
        } else {
            0
        }
    }

    private fun navigationBarAppearance(darkIcons: Boolean): Int {
        return if (darkIcons && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
        } else {
            0
        }
    }
}
