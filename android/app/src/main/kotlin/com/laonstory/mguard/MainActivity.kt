package com.laonstory.mguard

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import com.samsung.android.knox.EnterpriseDeviceManager
import com.samsung.android.knox.application.ApplicationPolicy
import com.samsung.android.knox.license.KnoxEnterpriseLicenseManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager


class MainActivity : FlutterActivity() {
    private var devicePolicyManager: DevicePolicyManager? = null
    private var enterpriseDeviceManager: EnterpriseDeviceManager? = null
    private var appPolicy: ApplicationPolicy? = null
    private var componentName: ComponentName? = null
    private val methodChannel = "mguard/android"
    private var mContext: Context? = null
    private var channel: MethodChannel? = null




    @Override
    fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        mContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, methodChannel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannel
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "active" -> {
                    adminActive()
                    result.success("OK")
                }

                "force_active" -> {
                    adminForceActive()
                }

                "inactive" -> {
                    adminDisable()
                    result.success("OK")
                }

                "disable" -> {
                    setCameraStatus(true)
                    result.success("OK")
                }

                "enable" -> {
                    setCameraStatus(false)
                    result.success("OK")
                }

                "check_admin" -> {
                    result.success(devicePolicyManager?.isAdminActive(componentName!!) == true)
                }

                "check_camera" -> {
                    val active: Boolean =
                        devicePolicyManager?.isAdminActive(componentName!!) == true
                    result.success(getCameraStatus() && active)
                }

                "show_license" -> {
                    activateLicense()
                    result.success("OK")
                }

                "uninstall" -> {
                    uninstallApp()
//                    preventDeviceAdminDeactivation()
                    result.success("OK")
                }

                "getId" -> {
                    val id = Settings.Secure.getString(this.contentResolver, Settings.Secure.ANDROID_ID)
                    result.success(id)
                }

            }
        }
    }

    @Override
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        mContext = applicationContext
        devicePolicyManager =
            getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager?
        componentName = AppDeviceAdminReceiver.getComponentName(this)
        enterpriseDeviceManager = EnterpriseDeviceManager.getInstance(this)
        appPolicy = enterpriseDeviceManager?.getApplicationPolicy()
    }


    private fun activateLicense() {
        val licenseManager:KnoxEnterpriseLicenseManager = KnoxEnterpriseLicenseManager.getInstance(this);
        val key: String = "KLM09-GP345-JFZCW-38R3T-59SJK-8H1F7"
        licenseManager.activateLicense(key)

//        enterpriseDeviceManager?.setAdminRemovable(false,"com.laonstory.mguard")
//            if (licenseResult.isSuccess()) {
//                if (licenseResult.isActivation()) {
//                    enterpriseDeviceManager?.setAdminRemovable(false,"com.laonstory.mguard")
//                }
//            }
//            Log.d("라이센스",licenseResult.toString())
//            enterpriseDeviceManager?.setAdminRemovable(false,"com.laonstory.mguard")
//        val mgr: KnoxEnterpriseLicenseManager = KnoxEnterpriseLicenseManager.getInstance(context)
//        val knoxLicenseKey: String = "KLM11-....."
//        mgr.activateLicense(knoxLicenseKey, { licenseResult ->
//            Log.w("License result arrived.")
//        })
    }

    private fun adminActive() {
        val componentName = ComponentName(this, AppDeviceAdminReceiver::class.java)
        val isAdminActive = devicePolicyManager?.isAdminActive(componentName) ?: false
        Log.d("debug adminActive", isAdminActive.toString())

        if (!isAdminActive) {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
            intent.putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "TPASS에서는 보안을 위해 아래와 같은 기능을 제한하고 있습니다. 장치 관리자 권한을 허용해야 TPASS를 사용하실 수 있습니다."
            )
            startActivityForResult(intent, DEVICE_ADMIN_ADD_RESULT_ENABLE)
        } else {
            Log.d("debug", "관리자 권한이 이미 활성화되어 있습니다.")
        }
//        val componentName = AppDeviceAdminReceiver.getComponentName(this)
//        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
//        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
//        intent.putExtra(
//            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
//            "TPASS에서는 보안을 위해 아래와 같은 기능을 제한하고 있습니다. 장치 관리자 권한을 허용해야 TPASS를 사용하실 수 있습니다."
//        )
//        startActivityForResult(intent, DEVICE_ADMIN_ADD_RESULT_ENABLE)
    }

    private fun adminForceActive(){
        val componentName = ComponentName(this, AppDeviceAdminReceiver::class.java)
        val isAdminActive = devicePolicyManager?.isAdminActive(componentName) ?: false
        Log.d("debug adminActive", isAdminActive.toString())

        if (!isAdminActive) {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
            intent.putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "TPASS에서는 보안을 위해 아래와 같은 기능을 제한하고 있습니다. 장치 관리자 권한을 허용해야 TPASS를 사용하실 수 있습니다."
            )
            startActivityForResult(intent, 2)
        } else {
            Log.d("debug", "관리자 권한이 이미 활성화되어 있습니다.")
        }
    }

    private fun uninstallApp() {
        val intent = Intent(Intent.ACTION_DELETE, Uri.parse("package:com.laonstory.mguard"))
//        intent.data =
//        Log.d("DeviceAdmin", " 삭제가 취소되었습니다.")
        startActivityForResult(intent, UNINSTALL_REQUEST_CODE)


    }

    private fun adminDisable() {
            enterpriseDeviceManager?.setAdminRemovable(true, "com.laonstory.mguard")
            val componentName = AppDeviceAdminReceiver.getComponentName(this)
            val devicePolicyManager = getSystemService(DevicePolicyManager::class.java)
            if(devicePolicyManager?.isAdminActive(componentName) == true){
                val activeAdmins = devicePolicyManager.getActiveAdmins()
                if(activeAdmins != null){
                    for (admin in activeAdmins) {
                        Log.d("debug", admin.packageName)
                        if(admin.packageName == "com.laonstory.mguard"){
                            devicePolicyManager.removeActiveAdmin(admin)
                            Log.d("debug", "관리자 권한해제 완료")
                        }

                    }
                }
                uninstallApp()
            }else{
                Log.d("debug", "관리자 권한이 이미 해제")
                uninstallApp()
            }



    }

    @Override
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
//
//        if (requestCode == DEVICE_ADMIN_ADD_RESULT_ENABLE) {
//            Log.d("debug 결과", resultCode.toString())
//            if (resultCode == RESULT_OK) {
//                activateLicense()
//            } else {
//                Log.d("debug 제거3", resultCode.toString())
//                adminActive()
//            }
//        } else {
//            if (resultCode == RESULT_OK) {
//                Log.d("DeviceAdmin", "앱이 성공적으로 삭제되었습니다.")
//            } else if (resultCode == RESULT_CANCELED) {
//                adminActive()
//                Log.d("DeviceAdmin", " 삭제가 취소되었습니다.")
//
//            }
//        }
        if (requestCode == DEVICE_ADMIN_ADD_RESULT_ENABLE) {
            if (resultCode == RESULT_OK) {
                activateLicense()
//                enterpriseDeviceManager?.setAdminRemovable(false,"com.laonstory.mguard")
                channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, methodChannel)
                if(channel == null){
                    Log.d("DeviceAdmin", "초기화안됐음")
                }
                Log.d("DeviceAdmin", "다시 관리자 활성화 성공")
            }else {
                adminForceActive();
            }
        }
        if (requestCode == 2) {
            if (resultCode == RESULT_OK) {
                activateLicense()
                channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, methodChannel)
                if(channel == null){
                    Log.d("DeviceAdmin", "초기화안됐음")
                }
                Log.d("DeviceAdmin", "다시 관리자 활성화 성공")
                channel?.invokeMethod("update", null)
            } else {
                adminForceActive();
            }
        }
        Log.d("DeviceAdmin", " 삭제가 취소되었습니다.1")
        if(requestCode == UNINSTALL_REQUEST_CODE){
            if (resultCode != RESULT_OK) {
//                enterpriseDeviceManager?.setAdminRemovable(false,"com.laonstory.mguard")
                activateLicense()
                channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, methodChannel)
                if(channel == null){
                    Log.d("DeviceAdmin", "초기화안됐음")
                }
                Log.d("DeviceAdmin", " 삭제가 취소되었습니다.2")
                channel?.invokeMethod("uninstall_canceled", null)
            }
        }
    }

    private fun setCameraStatus(cameraDisabled: Boolean) {
        if (devicePolicyManager?.isAdminActive(componentName!!) == false) {
            adminActive()
        }
        enterpriseDeviceManager?.restrictionPolicy?.setCameraState(!cameraDisabled)
        enterpriseDeviceManager?.restrictionPolicy?.allowAudioRecord(!cameraDisabled)

//        if(cameraDisabled){
//            appPolicy?.setApplicationUninstallationDisabled("com.laonstory.mguard")
//        }else{
//            appPolicy?.setApplicationUninstallationEnabled("com.laonstory.mguard")
//        }
    }

    private fun getCameraStatus(): Boolean {
//        enterpriseDeviceManager?.setAdminRemovable(false)
        return !enterpriseDeviceManager?.restrictionPolicy?.isCameraEnabled(false)!!
    }

    companion object {
        private const val DEVICE_ADMIN_ADD_RESULT_ENABLE = 1111
        private const val UNINSTALL_REQUEST_CODE = 1

//        private const val REQUEST_DISABLE_ADMIN = 1
    }


}
//package com.laonstory.mguard
//
//import android.app.admin.DevicePolicyManager
//import android.content.ComponentName
//import android.content.Context
//import android.content.Intent
//import android.net.Uri
//import android.os.Bundle
//import android.util.Log
//import com.samsung.android.knox.EnterpriseDeviceManager
//import com.samsung.android.knox.application.ApplicationPolicy
//import com.samsung.android.knox.license.KnoxEnterpriseLicenseManager
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.embedding.engine.plugins.FlutterPlugin
//import io.flutter.plugin.common.MethodChannel
//import android.provider.Settings
//
//
//class MainActivity : FlutterActivity() {
//    private var devicePolicyManager: DevicePolicyManager? = null
//    private var enterpriseDeviceManager: EnterpriseDeviceManager? = null
//    private var componentName: ComponentName? = null
//    private val methodChannel = "mguard/android"
//    private var mContext: Context? = null
//    private var channel: MethodChannel? = null
//
//
//    @Override
//    fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//        mContext = flutterPluginBinding.applicationContext
//        channel = MethodChannel(flutterPluginBinding.binaryMessenger, methodChannel)
//    }
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//        MethodChannel(
//            flutterEngine.dartExecutor.binaryMessenger,
//            methodChannel
//        ).setMethodCallHandler { call, result ->
//
//            when (call.method) {
//                "active" -> {
//                    adminActive()
//                    result.success("OK")
//                }
//
//                "inactive" -> {
//                    adminDisable()
//                    result.success("OK")
//                }
//
//                "disable" -> {
//                    setCameraStatus(true)
//                    result.success("OK")
//                }
//
//                "enable" -> {
//                    setCameraStatus(false)
//                    result.success("OK")
//                }
//
//                "check_admin" -> {
//                    result.success(devicePolicyManager?.isAdminActive(componentName!!) == true)
//                }
//
//                "check_camera" -> {
//                    val active: Boolean =
//                        devicePolicyManager?.isAdminActive(componentName!!) == true
//                    result.success(getCameraStatus() && active)
//                }
//
//                "show_license" -> {
//                    activateLicense()
//                    result.success("OK")
//                }
//
//                "uninstall" -> {
//                    uninstallApp()
//                    result.success("OK")
//                }
//
//               "getId" -> {
//                    val id = Settings.Secure.getString(this.contentResolver, Settings.Secure.ANDROID_ID)
//                    result.success(id)
//                }
//            }
//        }
//    }
//
//    @Override
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        mContext = applicationContext
//        devicePolicyManager =
//            getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager?
//        componentName = AppDeviceAdminReceiver.getComponentName(this)
//        enterpriseDeviceManager = EnterpriseDeviceManager.getInstance(this)
//    }
//
//
//    private fun activateLicense() {
//        val licenseManager = KnoxEnterpriseLicenseManager.getInstance(this);
//        licenseManager.activateLicense("KLM09-GP345-JFZCW-38R3T-59SJK-8H1F7");
//    }
//
//    private fun adminActive() {
//        val componentName = AppDeviceAdminReceiver.getComponentName(this)
//        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
//        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
//        intent.putExtra(
//            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
//            "TPASS에서는 보안을 위해 아래와 같은 기능을 제한하고 있습니다. 장치 관리자 권한을 허용해야 TPASS를 사용하실 수 있습니다."
//        )
//        startActivityForResult(intent, DEVICE_ADMIN_ADD_RESULT_ENABLE)
//
//    }
//
//    private fun uninstallApp() {
//        val intent = Intent(Intent.ACTION_DELETE, Uri.parse("package:com.laonstory.mguard"))
////        intent.data =
//        startActivityForResult(intent, UNINSTALL_REQUEST_CODE)
//    }
//
//    private fun adminDisable() {
//        devicePolicyManager?.removeActiveAdmin(componentName!!)
//    }
//
//    @Override
//    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
//        super.onActivityResult(requestCode, resultCode, data)
//
//        if (requestCode == DEVICE_ADMIN_ADD_RESULT_ENABLE) {
//            if (resultCode == RESULT_OK) {
//                activateLicense()
//            } else {
//            }
//        } else {
//            Log.d("debug", resultCode.toString())
//        }
//
//    }
//
//
//    private fun setCameraStatus(cameraDisabled: Boolean) {
//        if (devicePolicyManager?.isAdminActive(componentName!!) == false) {
//            adminActive()
//        }
//        enterpriseDeviceManager?.restrictionPolicy?.setCameraState(!cameraDisabled)
//        if (cameraDisabled) {
//            enterpriseDeviceManager?.applicationPolicy?.setApplicationUninstallationMode(
//                ApplicationPolicy.APPLICATION_UNINSTALLATION_MODE_DISALLOW
//            )
//        } else {
//            enterpriseDeviceManager?.applicationPolicy?.setApplicationUninstallationMode(
//                ApplicationPolicy.APPLICATION_UNINSTALLATION_MODE_ALLOW
//            )
//
//        }
//    }
//
//    private fun getCameraStatus(): Boolean {
//        return !enterpriseDeviceManager?.restrictionPolicy?.isCameraEnabled(false)!!
//    }
//
//    companion object {
//        private const val DEVICE_ADMIN_ADD_RESULT_ENABLE = 1111
//        private const val UNINSTALL_REQUEST_CODE = 1
//    }
//
//
//}