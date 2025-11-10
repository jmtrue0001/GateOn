package com.laonstory.mguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import com.samsung.android.knox.license.KnoxEnterpriseLicenseManager
import com.samsung.android.knox.license.EnterpriseLicenseManager
import com.samsung.android.knox.EnterpriseDeviceManager


class KnoxLicenseReceiver : BroadcastReceiver() {

    private var enterpriseDeviceManager: EnterpriseDeviceManager? = null

    private fun showToast(context: Context, msg: String) {
        Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
    }

    override fun onReceive(context: Context, intent: Intent?) {
        Log.d("KnoxLicenseReceiver", "onReceive called")
        if (intent == null) {
            Log.d("KnoxLicenseReceiver", "Intent is null")
            showToast(context, context.getResources().getString(R.string.no_intent))
        } else {
            val action: String? = intent.getAction()
            Log.d("KnoxLicenseReceiver", "Action received: $action")
            if (action == null) {
                Log.d("KnoxLicenseReceiver", "Action is null")
                showToast(context, context.getResources().getString(R.string.no_intent_action))
            } else if (action.equals(KnoxEnterpriseLicenseManager.ACTION_LICENSE_STATUS)) {
                // ELM activation result Intent is obtained
                val errorCode: Int = intent.getIntExtra(
                    KnoxEnterpriseLicenseManager.EXTRA_LICENSE_ERROR_CODE, DEFAULT_ERROR_CODE
                )
                if (errorCode == KnoxEnterpriseLicenseManager.ERROR_NONE) {
                    showToast(context, context.getResources().getString(R.string.kpe_activated_succesfully))
                    // MainActivity에 성공 결과 전달
//                    MainActivity.getInstance()?.onLicenseResult(true)
                } else {
                    val errorMessage = getKPEErrorMessage(context, intent, errorCode)
                    showToast(context, errorMessage)
                    // MainActivity에 실패 결과 전달
//                    MainActivity.getInstance()?.onLicenseResult(false)
                }
            } else if (action.equals(EnterpriseLicenseManager.ACTION_LICENSE_STATUS)) {
                val errorCode: Int = intent.getIntExtra(
                    EnterpriseLicenseManager.EXTRA_LICENSE_ERROR_CODE, DEFAULT_ERROR_CODE
                )
                if (errorCode == EnterpriseLicenseManager.ERROR_NONE) {
                    showToast(context, context.getResources().getString(R.string.elm_action_successful))
                    // MainActivity에 성공 결과 전달
//                    MainActivity.getInstance()?.onLicenseResult(true)
                } else {
                    val errorMessage = getELMErrorMessage(context, intent, errorCode)
                    showToast(context, errorMessage)
                    // MainActivity에 실패 결과 전달
//                    MainActivity.getInstance()?.onLicenseResult(false)
                }
            }
        }
    }

    private fun getELMErrorMessage(context: Context, intent: Intent, errorCode: Int): String {
        val message: String
        message = when (errorCode) {
            EnterpriseLicenseManager.ERROR_INTERNAL -> context.getResources().getString(R.string.err_elm_internal)
            EnterpriseLicenseManager.ERROR_INTERNAL_SERVER -> context.getResources()
                .getString(R.string.err_elm_internal_server)
            EnterpriseLicenseManager.ERROR_INVALID_LICENSE -> context.getResources()
                .getString(R.string.err_elm_licence_invalid_license)
            EnterpriseLicenseManager.ERROR_INVALID_PACKAGE_NAME -> context.getResources()
                .getString(R.string.err_elm_invalid_package_name)
            EnterpriseLicenseManager.ERROR_LICENSE_TERMINATED -> context.getResources()
                .getString(R.string.err_elm_licence_terminated)
            EnterpriseLicenseManager.ERROR_NETWORK_DISCONNECTED -> context.getResources()
                .getString(R.string.err_elm_network_disconnected)
            EnterpriseLicenseManager.ERROR_NETWORK_GENERAL -> context.getResources()
                .getString(R.string.err_elm_network_general)
            EnterpriseLicenseManager.ERROR_NOT_CURRENT_DATE -> context.getResources()
                .getString(R.string.err_elm_not_current_date)
            EnterpriseLicenseManager.ERROR_NULL_PARAMS -> context.getResources().getString(R.string.err_elm_null_params)
            EnterpriseLicenseManager.ERROR_SIGNATURE_MISMATCH -> context.getResources()
                .getString(R.string.err_elm_sig_mismatch)
            EnterpriseLicenseManager.ERROR_UNKNOWN -> context.getResources().getString(R.string.err_elm_unknown)
            EnterpriseLicenseManager.ERROR_USER_DISAGREES_LICENSE_AGREEMENT -> context.getResources()
                .getString(R.string.err_elm_user_disagrees_license_agreement)
            EnterpriseLicenseManager.ERROR_VERSION_CODE_MISMATCH -> context.getResources()
                .getString(R.string.err_elm_ver_code_mismatch)
            else -> {
                // Unknown error code
                val errorStatus: String? = intent.getStringExtra(
                    EnterpriseLicenseManager.EXTRA_LICENSE_STATUS
                )
                context.getResources()
                    .getString(R.string.err_elm_code_unknown, Integer.toString(errorCode), errorStatus)
            }
        }
        return message
    }

    private fun getKPEErrorMessage(context: Context, intent: Intent, errorCode: Int): String {
        val message: String
        message = when (errorCode) {
            KnoxEnterpriseLicenseManager.ERROR_INTERNAL -> context.getResources().getString(R.string.err_kpe_internal)
            KnoxEnterpriseLicenseManager.ERROR_INTERNAL_SERVER -> context.getResources()
                .getString(R.string.err_kpe_internal_server)
            KnoxEnterpriseLicenseManager.ERROR_INVALID_LICENSE -> context.getResources()
                .getString(R.string.err_kpe_licence_invalid_license)
            KnoxEnterpriseLicenseManager.ERROR_INVALID_PACKAGE_NAME -> context.getResources()
                .getString(R.string.err_kpe_invalid_package_name)
            KnoxEnterpriseLicenseManager.ERROR_LICENSE_TERMINATED -> context.getResources()
                .getString(R.string.err_kpe_licence_terminated)
            KnoxEnterpriseLicenseManager.ERROR_NETWORK_DISCONNECTED -> context.getResources()
                .getString(R.string.err_kpe_network_disconnected)
            KnoxEnterpriseLicenseManager.ERROR_NETWORK_GENERAL -> context.getResources()
                .getString(R.string.err_kpe_network_general)
            KnoxEnterpriseLicenseManager.ERROR_NOT_CURRENT_DATE -> context.getResources()
                .getString(R.string.err_kpe_not_current_date)
            KnoxEnterpriseLicenseManager.ERROR_NULL_PARAMS -> context.getResources()
                .getString(R.string.err_kpe_null_params)
            KnoxEnterpriseLicenseManager.ERROR_UNKNOWN -> context.getResources().getString(R.string.err_kpe_unknown)
            KnoxEnterpriseLicenseManager.ERROR_USER_DISAGREES_LICENSE_AGREEMENT -> context.getResources()
                .getString(R.string.err_kpe_user_disagrees_license_agreement)
            KnoxEnterpriseLicenseManager.ERROR_LICENSE_DEACTIVATED -> context.getResources()
                .getString(R.string.err_kpe_license_deactivated)
            KnoxEnterpriseLicenseManager.ERROR_LICENSE_EXPIRED -> context.getResources()
                .getString(R.string.err_kpe_license_expired)
            KnoxEnterpriseLicenseManager.ERROR_LICENSE_QUANTITY_EXHAUSTED -> context.getResources()
                .getString(R.string.err_kpe_license_quantity_exhausted)
            KnoxEnterpriseLicenseManager.ERROR_LICENSE_ACTIVATION_NOT_FOUND -> context.getResources()
                .getString(R.string.err_kpe_license_activation_not_found)
            KnoxEnterpriseLicenseManager.ERROR_LICENSE_QUANTITY_EXHAUSTED_ON_AUTO_RELEASE -> context.getResources()
                .getString(R.string.err_kpe_license_quantity_exhausted_on_auto_release)
            else -> {
                // Unknown error code
                val errorStatus: String? = intent.getStringExtra(
                    KnoxEnterpriseLicenseManager.EXTRA_LICENSE_STATUS
                )
                context.getResources()
                    .getString(R.string.err_kpe_code_unknown, Integer.toString(errorCode), errorStatus)
            }
        }
        return message
    }

    companion object {
        private const val DEFAULT_ERROR_CODE = -1
    }
}