package com.leotech.flutter_spi

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.StrictMode
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.mx51.spi.Spi
import io.mx51.spi.Spi.CompatibilityException
import io.mx51.spi.model.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry


/** FlutterSpiPlugin */


class ThumbzUp : MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private val VALIDATE_REQUEST_CODE = 19273
    private val SALE_REQUEST_CODE = 990572
    private val REFUND_REQUEST_CODE = 978907

    private val appURL: String = "payment.thumbzup.com"
    private val appClass: String = "payment.thumbzup.com.IntentActivity"
    private var act: Activity? = null;

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "init") {
            print("Hahahahahaha success!")
//      init(call.argument("posId")!!, call.argument("serialNumber")!!, call.argument("eftposAddress")!!,
//        call.argument("apiKey")!!, call.argument("tenantCode")!!, call.argument("secrets"), result)
        } else if (call.method == "start") {
            println("Starting!")
//      start(result)
        } else if (call.method == "getTenantsList") {
//            getTenantsList(call.argument("apiKey")!!, call.argument("countryCode")!!, result)
        } else if (call.method == "getVersion") {
            getVersion(result)
        } else if (call.method == "getCurrentStatus") {
            getCurrentStatus(result)
        } else if (call.method == "getCurrentFlow") {
            getCurrentFlow(result)
        } else if (call.method == "getCurrentPairingFlowState") {
            getCurrentPairingFlowState(result)
        } else if (call.method == "getCurrentTxFlowState") {
            getCurrentTxFlowState(result)
        } else if (call.method == "getConfig") {
//            getConfig(result)
        } else if (call.method == "ackFlowEndedAndBackToIdle") {
//            ackFlowEndedAndBackToIdle(result)
        } else if (call.method == "pair") {
            pair(result)
        } else if (call.method == "pairingConfirmCode") {
            pairingConfirmCode(result)
        } else if (call.method == "pairingCancel") {
            pairingCancel(result)
        } else if (call.method == "unpair") {
            unpair(result)
        } else if (call.method == "initiatePurchaseTx") {
            initiatePurchaseTx(call.argument("posRefId")!!, call.argument("purchaseAmount")!!, call.argument("tipAmount")!!, call.argument("cashoutAmount")!!, call.argument("promptForCashout")!!, result)
        } else if (call.method == "initiateRefundTx") {
            initiateRefundTx(call.argument("posRefId")!!, call.argument("refundAmount")!!, result)
        } else if (call.method == "acceptSignature") {
//            acceptSignature(call.argument("accepted")!!, result)
        } else if (call.method == "submitAuthCode") {
            submitAuthCode(call.argument("authCode")!!, result)
        } else if (call.method == "cancelTransaction") {
            cancelTransaction(result)
        } else if (call.method == "initiateCashoutOnlyTx") {
//            initiateCashoutOnlyTx(call.argument("posRefId")!!, call.argument("amountCents")!!, result)
        } else if (call.method == "initiateMotoPurchaseTx") {
//            initiateMotoPurchaseTx(call.argument("posRefId")!!, call.argument("amountCents")!!, result)
        } else if (call.method == "initiateSettleTx") {
//            initiateSettleTx(call.argument("id")!!, result)
        } else if (call.method == "initiateSettlementEnquiry") {
//            initiateSettlementEnquiry(call.argument("posRefId")!!, result)
        } else if (call.method == "initiateGetLastTx") {
            initiateGetLastTx(result)
        } else if (call.method == "initiateRecovery") {
            initiateRecovery(call.argument("posRefId")!!, call.argument("txType")!!, result)
        } else if (call.method == "dispose") {
            dispose(result)
        } else if (call.method == "getDeviceSN") {
            getDeviceSN(result)
        } else if (call.method == "setPromptForCustomerCopyOnEftpos") {
            setPromptForCustomerCopyOnEftpos(call.argument("promptForCustomerCopyOnEftpos")!!, result)
        } else if (call.method == "setSignatureFlowOnEftpos") {
            setSignatureFlowOnEftpos(call.argument("signatureFlowOnEftpos")!!, result)
        } else if (call.method == "setPrintMerchantCopy") {
            setPrintMerchantCopy(call.argument("printMerchantCopy")!!, result)
        } else {
            result.notImplemented()
        }
    }

    private fun validate() {
        var intent = Intent()
        intent.setClassName(appURL, appClass)

        var dataBundle = Bundle()

        dataBundle.putString("launchType", "RETAIL_AUTH")
        dataBundle.putString("applicationKey", "KEY")
        dataBundle.putString("merchantID", "ID")
        dataBundle.putString("secreteKey", "KEY")
        dataBundle.putString("accessKey", "KEY")

        intent.putExtra("thumbzupBundle", dataBundle)
        act?.startActivityForResult(intent, VALIDATE_REQUEST_CODE)
    }

    private fun invokeFlutterMethod(flutterMethod: String, message: Any?) {
        FlutterSpiPlugin().invokeFlutterMethodThumbzUp(flutterMethod, message);
    }

    fun init(posId: String, serialNumber: String, eftposAddress: String, apiKey: String, tenantCode: String, secrets: HashMap<String, String>?, result: Result) {
        result.success(null)
    }

    /**
     * Retrieves package version of the SPI client library.
     *
     * @promise.resolve(Full version (e.g. '2.0.1') or, when running locally, protocol version (e.g. '2.0.0-PROTOCOL').
     */
    fun getVersion(result: Result) {
        result.success("ThumbzUp");
    }

    /**
     * The current status of this SPI instance.
     *
     * @promise.resolve(Status value [SpiStatus].
     */
    fun getCurrentStatus(result: Result) {
        result.success(null)
    }

    /**
     * The current flow that this SPI instance is currently in.
     *
     * @promise.resolve(Current flow value [SpiFlow].
     */
    fun getCurrentFlow(result: Result) {
        result.success(null)
    }

    /**
     * When current flow is [SpiFlow.PAIRING], this represents the state of the pairing process.
     */
    fun getCurrentPairingFlowState(result: Result) {
        result.success(null)
    }

    /**
     * When current flow is [SpiFlow.TRANSACTION], this represents the state of the transaction process.
     */
    fun getCurrentTxFlowState(result: Result) {
        result.success(null)
    }


    /**
     * This will connect to the EFTPOS and start the pairing process.
     *
     *
     * Only call this if you are in the [SpiStatus.UNPAIRED] state.
     *
     *
     * Subscribe to [.setPairingFlowStateChangedHandler] to get updates on the pairing process.
     *
     * @promise.resolve(Whether pairing has initiated or not.
     */
    fun pair(result: Result) {
        result.success(null)
    }

    /**
     * Call this when your user clicks 'Yes' to confirm the pairing code on your screen matches the one on the EFTPOS.
     */
    fun pairingConfirmCode(result: Result) {
        result.success(null)
    }

    /**
     * Call this if your user clicks 'Cancel' or 'No' during the pairing process.
     */
    fun pairingCancel(result: Result) {
        result.success(null)
    }

    /**
     * Call this when your uses clicks the 'Unpair' button.
     *
     *
     * This will disconnect from the EFTPOS and forget the secrets.
     * The current state is then changed to [SpiStatus.UNPAIRED].
     *
     *
     * Call this only if you are not yet in the [SpiStatus.UNPAIRED] state.
     */
    fun unpair(result: Result) {
        result.success(null)
    }


    /**
     * Initiates a purchase transaction.
     *
     *
     * Be subscribed to [.setTxFlowStateChangedHandler] to get updates on the process.
     *
     * @param posRefId       Alphanumeric identifier for your purchase.
     * @param purchaseAmount Amount in cents to charge.
     * @promise.resolve(Initiation result [InitiateTxResult].
     */

    fun initiatePurchaseTx(posRefId: String, purchaseAmount: Int, tipAmount: Int, cashoutAmount: Int, promptForCashout: Boolean, result: Result) {
        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
        StrictMode.setThreadPolicy(policy)
        result.success(null)
    }

    /**
     * Initiates a refund transaction.
     *
     *
     * Be subscribed to [.setTxFlowStateChangedHandler] to get updates on the process.
     *
     * @param posRefId     Alphanumeric identifier for your refund.
     * @param refundAmount Amount in cents to charge.
     * @promise.resolve(Initiation result [InitiateTxResult].
     */
    fun initiateRefundTx(posRefId: String, refundAmount: Int, result: Result) {
        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
        StrictMode.setThreadPolicy(policy)
        result.success(null)
    }
    /**
     * Submit the Code obtained by your user when phoning for auth.
     * It will promise.resolve(immediately to tell you whether the code has a valid format or not.
     * If valid==true is returned, no need to do anything else. Expect updates via standard callback.
     * If valid==false is returned, you can show your user the accompanying message, and invite them to enter another code.
     *
     * @param authCode The code obtained by your user from the merchant call centre. It should be a 6-character alpha-numeric value.
     * @promise.resolve(Whether code has a valid format or not.
     */
    fun submitAuthCode(authCode: String, result: Result) {
        result.success(null)
    }

    /**
     * Attempts to cancel a transaction.
     *
     *
     * Be subscribed to [.setTxFlowStateChangedHandler] to see how it goes.
     *
     *
     * Wait for the transaction to be finished and then see whether cancellation was successful or not.
     *
     * @promise.resolve(MidTxResult - false only if you called it in the wrong state.
     */
    fun cancelTransaction(result: Result) {
        result.success(null)
    }

    /**
     * Initiates a get last transaction operation. Use this when you want to retrieve the most recent transaction
     * that was processed by the EFTPOS.
     *
     *
     * Be subscribed to [.setTxFlowStateChangedHandler] to get updates on the process.
     */
    fun initiateGetLastTx(result: Result) {
        result.success(null)
    }

    /**
     * This is useful to recover from your POS crashing in the middle of a transaction.
     * When you restart your POS, if you had saved enough state, you can call this method to recover the client library state.
     * You need to have the posRefId that you passed in with the original transaction, and the transaction type.
     * This method will promise.resolve(immediately whether recovery has started or not.
     * If recovery has started, you need to bring up the transaction modal to your user a be listening to TxFlowStateChanged.
     *
     * @param posRefId The is that you had assigned to the transaction that you are trying to recover.
     * @param txType   The transaction type.
     */
    fun initiateRecovery(posRefId: String, txType: String, result: Result) {
        result.success(null)
    }

    /**
     * Stops all running processes and resets to state before starting.
     * <p>
     * Call this method when finished with SPI, e.g. when closing the application.
     */
    fun dispose(result: Result) {
        result.success(null)
    }

    fun getDeviceSN(result: Result) {

        var serialNumber: String? = null
        try {
            val c = Class.forName("android.os.SystemProperties")
            val get = c.getMethod("get", String::class.java)

            serialNumber = get.invoke(c, "gsm.sn1") as String
            if (serialNumber == "")
                serialNumber = get.invoke(c, "ril.serialnumber") as String
            if (serialNumber == "")
                serialNumber = get.invoke(c, "ro.serialno") as String
            if (serialNumber == "")
                serialNumber = get.invoke(c, "sys.serialnumber") as String
            if (serialNumber == "")
                serialNumber = Build.SERIAL
            result.success(serialNumber)
        } catch (ignored: Exception) {
            result.error("ERROR", "Error.", null)
        }

    }

    fun setPromptForCustomerCopyOnEftpos(promptForCustomerCopyOnEftpos: Boolean, result: Result) {
//        mSpi.config.isPromptForCustomerCopyOnEftpos = promptForCustomerCopyOnEftpos
        result.success(null)
    }

    fun setSignatureFlowOnEftpos(signatureFlowOnEftpos: Boolean, result: Result) {
//        mSpi.config.isSignatureFlowOnEftpos = signatureFlowOnEftpos
        result.success(null)
    }

    fun setPrintMerchantCopy(printMerchantCopy: Boolean, result: Result) {
//        mSpi.config.setPrintMerchantCopy(printMerchantCopy)
        result.success(null)
    }
    fun mapPairingFlowState(obj: PairingFlowState): HashMap<String, Any> {
        var map: HashMap<String, Any> = HashMap<String, Any>()
        map.put("message", obj.message)
        map.put("awaitingCheckFromEftpos", obj.isAwaitingCheckFromEftpos)
        map.put("awaitingCheckFromPos", obj.isAwaitingCheckFromPos)
        map.put("confirmationCode", obj.confirmationCode)
        map.put("finished", obj.isFinished)
        map.put("successful", obj.isSuccessful)
        return map
    }

    fun mapTransactionState(obj: TransactionFlowState): HashMap<String, Any?> {
        var map: HashMap<String, Any?> = HashMap<String, Any?>()
        map.put("posRefId", obj.posRefId)
        map.put("type", obj.type?.name)
        map.put("displayMessage", obj.displayMessage)
        map.put("amountCents", obj.amountCents)
        map.put("requestSent", obj.isRequestSent)
        map.put("requestTime", obj.requestTime.toString())
        map.put("lastStateRequestTime", obj.lastStateRequestTime.toString())
        map.put("attemptingToCancel", obj.isAttemptingToCancel)
        map.put("awaitingSignatureCheck", obj.isAwaitingSignatureCheck)
        map.put("awaitingPhoneForAuth", obj.isAwaitingPhoneForAuth)
        map.put("finished", obj.isFinished)
        map.put("success", obj.success?.name)
        map.put("response", mapMessage(obj.response))
        map.put("signatureRequiredMessage", mapSignatureRequest(obj.signatureRequiredMessage))
//        map.put("phoneForAuthRequiredMessage", mapPhoneForAuthRequired(obj.phoneForAuthRequiredMessage))
        map.put("cancelAttemptTime", obj.cancelAttemptTime.toString())
        map.put("request", mapMessage(obj.request))
        map.put("awaitingGltResponse", obj.isAwaitingGtResponse)  //GltResponse has been replaced by GtResponse
        return map
    }

    fun mapMessage(obj: Message?): HashMap<String, Any?> {
        var map: HashMap<String, Any?> = HashMap<String, Any?>()
        map.put("id", obj?.id)
        map.put("event", obj?.eventName)
        map.put("data", hashMapToWritableMap(obj?.data))
        return map
    }
    @Suppress("UNCHECKED_CAST")
    private fun hashMapToWritableMap(map: Map<String, Any?>?): HashMap<String, Any?> {
        var result: HashMap<String, Any?> = HashMap<String, Any?>()
        map?.forEach { (k, v) ->
            try {
                when (v) {
                    is Boolean ->
                        result.put(k, v)

                    is Int ->
                        result.put(k, v)

                    is Double ->
                        result.put(k, v)

                    is Float ->
                        result.put(k, v.toDouble())

                    is String ->
                        result.put(k, v)

                    is Map<*, *> ->
                        result.put(k, hashMapToWritableMap(v as Map<String, Any?>))

                    is List<*> -> {
                        v.map { it to hashMapToWritableMap(it as Map<String, Any?>) }.toList()
                    }

                    null ->
                        result.put(k, null)
                }
            } catch (e: Exception) {
                result.put(k, "Mapper [com.leotech.assembly.spi.mapper.MessageMapper::hashMapToWritableMap] cannot map data $v")
            }
        }
        return result
    }

    fun mapSignatureRequest(obj: SignatureRequired?): HashMap<String, Any?> {
        var map: HashMap<String, Any?> = HashMap<String, Any?>()
        map.put("requestId", obj?.requestId)
        map.put("posRefId", obj?.posRefId)
        map.put("receiptToSign", obj?.merchantReceipt)
        return map
    }

    companion object {

        private const val statusChangedEvent = "StatusChanged"
        private const val pairingFlowStateChangedEvent = "PairingFlowStateChanged"
        private const val txFlowStateChangedEvent = "TxFlowStateChanged"
        private const val secretsChangedEvent = "SecretsChanged"

//        private fun Result.handleResult(success: Boolean, result: Result) {
//            if (success) {
//                result.success(null)
//            } else {
//                result.error("ERROR", "Error.", null)
//            }
//        }
//
//        private fun Result.handleResult(initiateTxResult: InitiateTxResult, result: Result) {
//            if (initiateTxResult.isInitiated) {
//                result.success(null)
//            } else {
//                result.error("ERROR", "Error.", null)
//            }
//        }
//
//        private fun Result.handleResult(midTxResult: MidTxResult, result: Result) {
//            if (midTxResult.isValid) {
//                result.success(null)
//            } else {
//                result.error("ERROR", "Error.", null)
//            }
//        }
//
//        private fun Result.handleResult(submitAuthCodeResult: SubmitAuthCodeResult, result: Result) {
//            if (submitAuthCodeResult.isValidFormat) {
//                result.success(null)
//            } else {
//                result.error("ERROR", "Error.", null)
//            }
//        }

    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        act = binding.activity;
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        act = null;
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        act = binding.activity;
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        act = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        TODO("Implement these")
        var result = ""
        var b = Bundle(data?.getBundleExtra("thumbzupApplicationResponse"))
        if (requestCode == VALIDATE_REQUEST_CODE){

        }else if (requestCode == SALE_REQUEST_CODE){

        }else if (requestCode == REFUND_REQUEST_CODE){

        }
    }
}

