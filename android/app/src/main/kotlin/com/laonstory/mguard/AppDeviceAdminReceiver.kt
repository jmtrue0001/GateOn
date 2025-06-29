package com.laonstory.mguard

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.Toast
import android.util.Log


class AppDeviceAdminReceiver : DeviceAdminReceiver() {

    companion object {
        fun getComponentName(context: Context): ComponentName {
            return ComponentName(context, AppDeviceAdminReceiver::class.java)
        }
    }

    @Override
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
    }

    @Override
    override fun onDisabled(context: Context, intent: Intent) {
//        devicePolicyManager.removeActiveAdmin(ComponentName(context, AppDeviceAdminReceiver::class.java))
//        Toast.makeText(context, "디바이스 관리자가 비활성화되었습니다.", Toast.LENGTH_SHORT).show()
        Log.d("debug", "비활성화 오버라이드")
        super.onDisabled(context, intent)
    }

}