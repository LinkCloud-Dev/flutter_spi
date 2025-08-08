package com.leotech.flutter_spi

import android.content.Context
import android.content.pm.PackageInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.StrictMode
import android.util.Log
import androidx.annotation.NonNull
import com.six.timapi.ActivateResponse
import com.six.timapi.BalanceInquiryResponse
import com.six.timapi.BalanceResponse
import com.six.timapi.CardData
import com.six.timapi.ClientIdentificationResponse
import com.six.timapi.CommandResponse
import com.six.timapi.Counters
import com.six.timapi.DeactivateResponse
import com.six.timapi.HardwareInformationResponse
import com.six.timapi.InitTransactionResponse
import com.six.timapi.LoyaltyItem
import com.six.timapi.MobileTopupData
import com.six.timapi.MobileTopupValue
import com.six.timapi.PrintData
import com.six.timapi.ReceiptRequestResponse
import com.six.timapi.ReconciliationResponse
import com.six.timapi.ScreenshotInformation
import com.six.timapi.ShowDialogResponse
import com.six.timapi.ShowSignatureCaptureResponse
import com.six.timapi.SystemInformationResponse
import io.mx51.spi.Spi;
import io.mx51.spi.Spi.CompatibilityException;
import io.mx51.spi.model.*;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel

import java.util.EnumSet
import java.util.logging.Logger
import java.util.logging.Level
import com.six.timapi.constants.Guides
import com.six.timapi.constants.TransactionStatus as TimapiTransactionStatus
import com.six.timapi.Terminal
import com.six.timapi.TerminalSettings;
import com.six.timapi.constants.TransactionType as TimapiTransactionType;
import com.six.timapi.Amount as TimapiAmount;
import com.six.timapi.constants.Currency as TimapiCurrency;
import com.six.timapi.constants.ConnectionMode;
import com.six.timapi.TerminalListener
import com.six.timapi.ThirdPartyAppPayload
import com.six.timapi.TimEvent
import com.six.timapi.TimException
import com.six.timapi.TransactionInfoRequestResponse
import com.six.timapi.TransactionInformation
import com.six.timapi.TransactionResponse
import com.six.timapi.TransactionRequest
import com.six.timapi.TransactionData
import com.six.timapi.VasCheckoutInformation
import com.six.timapi.VasResult
import com.six.timapi.PrintOption
import com.six.timapi.constants.Reason
import com.six.timapi.constants.UpdateStatus
import com.six.timapi.constants.ReceiptRequestType
import com.six.timapi.constants.Recipient
import com.six.timapi.constants.*

/** FlutterSpiPlugin */
class FlutterSpiPlugin: FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var spiChannel: MethodChannel
    private lateinit var timApiChannel: MethodChannel
    private lateinit var context: Context

    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    lateinit var mSpi: Spi
    var mTim: com.six.timapi.Terminal? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        spiChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_spi")
        spiChannel.setMethodCallHandler(this)

        timApiChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_spi_timapi")
        timApiChannel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_spi_timapi_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                println("✅ EventChannel onListen triggered")

                    }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "init") {
            init(call.argument("posId")!!, call.argument("serialNumber")!!, call.argument("eftposAddress")!!,
                    call.argument("apiKey")!!, call.argument("tenantCode")!!, call.argument("secrets"), result)
        } else if (call.method == "start") {
            start(result)
        } else if (call.method == "timApiTestConnection"){
            timApiTestConnection(result)
        } else if (call.method == "timApiInit") {
            timApiInit(
                call.argument<String>("eftposAddress"),
                call.argument<String>("posId"),
                call.argument<Int>("port"),
                call.argument<Boolean>("enablePrinting") ?: false, // For accreditation - control receipt printing
                result)
        } else if (call.method == "timApiConnect") {
            timApiConnect(
                result)
        } else if (call.method == "timApiLogin") {
            timApiLogin(
                result)
        } else if (call.method == "timApiActivate") {
            timApiActivate(
                result)
        } else if (call.method == "timApiStartTransaction") {
            timApiStartTransaction(
                call.argument("posRefId")!!,
                call.argument("amount")!!,
                result
            )
        } else if (call.method == "timApiDoRefund") {
            timApiDoRefund(
                call.argument("posRefId")!!,
                call.argument("amount")!!,
                result
            )
        } else if (call.method == "timApiDoRefRefund") {
            timApiDoRefRefund(
                call.argument("posRefId")!!,
                call.argument("amount")!!,
                call.argument("sixTrxRefNum")!!,
                result
            )
        } else if (call.method == "timApiDoBalance") {
            timApiDoBalance(
                call.argument("posRefId")!!,
                result
            )
        } else if (call.method == "timApiDoReversal") {
            timApiDoReversal(
                call.argument("posRefId"),
                call.argument("transSeq"),
                result
            )
        /*}else if (call.method == "timApiPrint") {
            timApiPrint(
                call.argument("ticket")!!,
                result)*/
        }else if (call.method == "timApiStartListening") {
            dummy(result)
        } else if (call.method == "setPosId") {
            setPosId(call.argument("posId")!!, result)
        } else if (call.method == "setSerialNumber") {
            setSerialNumber(call.argument("serialNumber")!!, result)
        } else if (call.method == "setEftposAddress") {
            setEftposAddress(call.argument("address")!!, result)
        } else if (call.method == "setTenantCode") {
            setTenantCode(call.argument("tenantCode")!!, result)
        } else if (call.method == "setPosInfo") {
            setPosInfo(call.argument("posVendorId")!!, call.argument("posVersion")!!, result)
        } else if (call.method == "getTenantsList") {
            getTenantsList(call.argument("apiKey")!!, call.argument("countryCode")!!, result)
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
            getConfig(result)
        } else if (call.method == "ackFlowEndedAndBackToIdle") {
            ackFlowEndedAndBackToIdle(result)
        } else if (call.method == "pair") {
            pair(result)
        } else if (call.method == "pairingConfirmCode") {
            pairingConfirmCode(result)
        } else if (call.method == "pairingCancel") {
            pairingCancel(result)
        } else if (call.method == "unpair") {
            unpair(result)
        } else if (call.method == "initiatePurchaseTx") {
            initiatePurchaseTx(call.argument("posRefId")!!, call.argument("purchaseAmount")!!, call.argument("tipAmount")!!, call.argument("cashoutAmount")!!, call.argument("promptForCashout")!!,  result)
        } else if (call.method == "initiateRefundTx") {
            initiateRefundTx(call.argument("posRefId")!!, call.argument("refundAmount")!!, result)
        } else if (call.method == "acceptSignature") {
            acceptSignature(call.argument("accepted")!!, result)
        } else if (call.method == "submitAuthCode") {
            submitAuthCode(call.argument("authCode")!!, result)
        } else if (call.method == "cancelTransaction") {
            cancelTransaction(result)
        } else if (call.method == "initiateCashoutOnlyTx") {
            initiateCashoutOnlyTx(call.argument("posRefId")!!, call.argument("amountCents")!!, result)
        } else if (call.method == "initiateMotoPurchaseTx") {
            initiateMotoPurchaseTx(call.argument("posRefId")!!, call.argument("amountCents")!!, result)
        } else if (call.method == "initiateSettleTx") {
            initiateSettleTx(call.argument("id")!!, result)
        } else if (call.method == "initiateSettlementEnquiry") {
            initiateSettlementEnquiry(call.argument("posRefId")!!, result)
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
        } else if (call.method == "timApiDisconnect") {
            timApiDisconnect(result)
        } else if (call.method == "timApiLogout") {
            timApiLogout(result)
        } else if (call.method == "timApiDeactivate") {
            timApiDeactivate(result)
        } else  {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        spiChannel.setMethodCallHandler(null)
    }

    private fun invokeFlutterMethod(flutterMethod: String, message: Any?) {
        val mainHandler = Handler(context.mainLooper)
        mainHandler.post {
            spiChannel.invokeMethod(flutterMethod, message, object : MethodChannel.Result {
                override fun success(o: Any?) {
                    Log.d("SUCCESS", "invokeMethod: success")
                }
                override fun error(s: String, s1: String?, o: Any?) {
                    Log.d("ERROR", "invokeMethod: error")
                }
                override fun notImplemented() {
                    Log.d("ERROR", "notImplemented")
                }
            })
        }
    }

    fun init(posId: String, serialNumber: String, eftposAddress: String, apiKey: String, tenantCode: String, secrets: HashMap<String, String>?, result: Result) {
        var initialized = true
        try {
            mSpi
        } catch (e: UninitializedPropertyAccessException) {
            initialized = false
        }
        if (initialized) {
            result.error("INITIALIZED", "Initialized Already.", null)
            return
        }

        try {
            mSpi = Spi(posId, serialNumber, eftposAddress, if (secrets.isNullOrEmpty()) null else Secrets(secrets!!.get("encKey"), secrets!!.get("hmacKey")))
            val pInfo: PackageInfo = context.getPackageManager().getPackageInfo(context.getPackageName(), 0)
            mSpi.setPosInfo("LinkPOS", pInfo.versionName)
            mSpi.setAutoAddressResolution(false);
            mSpi.setDeviceApiKey(apiKey);
            mSpi.setTenantCode(tenantCode);
            setStatusChangedHandler()
            setPairingFlowStateChangedHandler()
            setTxFlowStateChangedHandler()
            setSecretsChangedHandler()
            result.success(null)
        } catch (e: CompatibilityException) {
            result.error("INIT_ERROR", "Init Error.", null)
        }
    }

    /**
     * Subscribe to this event to know when the status has changed.
     */
    private fun setStatusChangedHandler() {
        mSpi.setStatusChangedHandler {
            invokeFlutterMethod("statusChanged", it?.name)
        }
    }

    /**
     * Subscribe to this event to know when the current pairing flow state has changed.
     */
    private fun setPairingFlowStateChangedHandler() {
        mSpi.setPairingFlowStateChangedHandler {
            invokeFlutterMethod("pairingFlowStateChanged", mapPairingFlowState(it))
        }
    }

    /**
     * Subscribe to this event to know when the current pairing flow state changes
     */
    private fun setTxFlowStateChangedHandler() {
        mSpi.setTxFlowStateChangedHandler {
            invokeFlutterMethod("txFlowStateChanged", mapTransactionState(it))
        }
    }

    /**
     * Subscribe to this event to know when the secrets change, such as at the end of the pairing process,
     * or every time that the keys are periodically rolled.
     *
     *
     * You then need to persist the secrets safely so you can instantiate SPI with them next time around.
     */
    private fun setSecretsChangedHandler() {
        mSpi.setSecretsChangedHandler {
            invokeFlutterMethod("secretsChanged", mapSecrets(it))
        }
    }

    /**
     * Call this method after constructing an instance of the class and subscribing to events.
     * It will start background maintenance threads.
     *
     *
     * Most importantly, it connects to the EFTPOS server if it has secrets.
     */
    fun start(result: Result) {
        mSpi.start()
        result.success(null)
    }

    /**
     * Allows you to set the pos ID, which identifies this instance of your POS.
     * Can only be called in the unpaired state.
     */
    fun setPosId(id: String, result: Result) {
        result.handleResult(mSpi.setPosId(id), result)
    }

    /**
     * Allows you to set the serial number.
     */
    fun setSerialNumber(serialNumber: String, result: Result) {
        result.handleResult(mSpi.setSerialNumber(serialNumber), result)
    }

    /**
     * Allows you to enable/disable auto address resolution.
     */
    fun setAutoAddressResolution(autoAddressResolution: Boolean, result: Result) {
        result.handleResult(mSpi.setAutoAddressResolution(autoAddressResolution), result)
    }

    /**
     * Allows you to set the PIN pad address. Sometimes the PIN pad might change IP address (we recommend
     * reserving static IPs if possible). Either way you need to allow your User to enter the IP address
     * of the PIN pad. Make sure you disable auto address resolution before calling this function.
     */
    fun setEftposAddress(address: String, result: Result) {
        result.handleResult(mSpi.setEftposAddress(address), result)
    }

    /**
     * Allows you to set the acquirer code.
     */
    fun setTenantCode(tenantCode: String, result: Result) {
        result.handleResult(mSpi.setTenantCode(tenantCode), result)
    }

    /**
     * Sets values used to identify the POS software to the EFTPOS terminal.
     *
     *
     * Must be set before starting!
     *
     * @param posVendorId Vendor identifier of the POS itself.
     * @param posVersion  Version string of the POS itself.
     */
    fun setPosInfo(posVendorId: String, posVersion: String, result: Result) {
        mSpi.setPosInfo(posVendorId, posVersion)
        result.success(null)
    }

    /**
     * Get available tenants list.
     *
     * @param apiKey  The api key to access mx51 api.
     * @param countryCode  Country code.
     */
    fun getTenantsList(apiKey: String, countryCode: String, result: Result) {
        result.success(mapTenants(Spi.getAvailableTenants("LinkPOS", apiKey, countryCode)))
    }

    /**
     * Retrieves package version of the SPI client library.
     *
     * @promise.resolve(Full version (e.g. '2.0.1') or, when running locally, protocol version (e.g. '2.0.0-PROTOCOL').
     */
    fun getVersion(result: Result) {
        result.success(Spi.getVersion())
    }

    /**
     * The current status of this SPI instance.
     *
     * @promise.resolve(Status value [SpiStatus].
     */
    fun getCurrentStatus(result: Result) {
        result.success(mSpi.currentStatus.name)
    }

    /**
     * The current flow that this SPI instance is currently in.
     *
     * @promise.resolve(Current flow value [SpiFlow].
     */
    fun getCurrentFlow(result: Result) {
        result.success(mSpi.currentFlow.name)
    }

    /**
     * When current flow is [SpiFlow.PAIRING], this represents the state of the pairing process.
     */
    fun getCurrentPairingFlowState(result: Result) {
        result.success(mapPairingFlowState(mSpi.currentPairingFlowState))
    }

    /**
     * When current flow is [SpiFlow.TRANSACTION], this represents the state of the transaction process.
     */
    fun getCurrentTxFlowState(result: Result) {
        result.success(mapTransactionState(mSpi.currentTxFlowState))
    }

    fun getConfig(result: Result) {
        result.success(mapSpiConfig(mSpi.config))
    }

    /**
     * Call this one when a flow is finished and you want to go back to idle state.
     *
     *
     * Typically when your user clicks the "OK" button to acknowledge that pairing is finished, or that
     * transaction is finished. When true, you can dismiss the flow screen and show back the idle screen.
     *
     * @promise.resolve(`true` means we have moved back to the [SpiFlow.IDLE] state,
     * `false` means current flow was not finished yet.
     */
    fun ackFlowEndedAndBackToIdle(result: Result) {
        result.handleResult(mSpi.ackFlowEndedAndBackToIdle(), result)
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
        result.handleResult(mSpi.pair(), result)
    }

    /**
     * Call this when your user clicks 'Yes' to confirm the pairing code on your screen matches the one on the EFTPOS.
     */
    fun pairingConfirmCode(result: Result) {
        mSpi.pairingConfirmCode()
        result.success(null)
    }

    /**
     * Call this if your user clicks 'Cancel' or 'No' during the pairing process.
     */
    fun pairingCancel(result: Result) {
        mSpi.pairingCancel()
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
        result.handleResult(mSpi.unpair(), result)
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
        result.handleResult(mSpi.initiatePurchaseTx(posRefId, purchaseAmount, tipAmount, cashoutAmount, promptForCashout, TransactionOptions()), result)
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
        result.handleResult(mSpi.initiateRefundTx(posRefId, refundAmount), result)
    }

    /**
     * Let the EFTPOS know whether merchant accepted or declined the signature.
     *
     * @param accepted Whether merchant accepted the signature from customer or not.
     * @promise.resolve(MidTxResult - false only if you called it in the wrong state.
     */
    fun acceptSignature(accepted: Boolean, result: Result) {
        result.handleResult(mSpi.acceptSignature(accepted), result)
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
        result.handleResult(mSpi.submitAuthCode(authCode), result)
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
        result.handleResult(mSpi.cancelTransaction(), result)
    }

    /**
     * Initiates a cashout only transaction.
     *
     *
     * Be subscribed to [.setTxFlowStateChangedHandler] event to get updates on the process.
     *
     * @param posRefId    Alphanumeric identifier for your transaction.
     * @param amountCents Amount in cents to cash out.
     */
    fun initiateCashoutOnlyTx(posRefId: String, amountCents: Int, result: Result) {
        result.handleResult(mSpi.initiateCashoutOnlyTx(posRefId, amountCents), result)
    }

    /**
     * Initiates a Mail Order / Telephone Order Purchase Transaction.
     *
     * @param posRefId    Alphanumeric identifier for your transaction.
     * @param amountCents Amount in cents
     */
    fun initiateMotoPurchaseTx(posRefId: String, amountCents: Int, result: Result) {
        result.handleResult(mSpi.initiateMotoPurchaseTx(posRefId, amountCents), result)
    }

    /**
     * Initiates a settlement transaction.
     *
     *
     * Be subscribed to [.setTxFlowStateChangedHandler] to get updates on the process.
     */
    fun initiateSettleTx(id: String, result: Result) {
        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
        StrictMode.setThreadPolicy(policy)
        result.handleResult(mSpi.initiateSettleTx(id), result)
    }

    /**
     * Initiates settlement enquiry operation.
     */
    fun initiateSettlementEnquiry(posRefId: String, result: Result) {
        result.handleResult(mSpi.initiateSettlementEnquiry(posRefId), result)
    }

    /**
     * Initiates a get last transaction operation. Use this when you want to retrieve the most recent transaction
     * that was processed by the EFTPOS.
     *
     *
     * Be subscribed to [.setTxFlowStateChangedHandler] to get updates on the process.
     */
    fun initiateGetLastTx(result: Result) {
        result.handleResult(mSpi.initiateGetLastTx(), result)
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
        result.handleResult( mSpi.initiateRecovery(
                posRefId,
                TransactionType.valueOf(txType)
        ), result)
    }
    /**
     * Stops all running processes and resets to state before starting.
     * <p>
     * Call this method when finished with SPI, e.g. when closing the application.
     */
    fun dispose(result: Result) {
        mSpi.dispose()
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
        mSpi.config.isPromptForCustomerCopyOnEftpos = promptForCustomerCopyOnEftpos
        result.success(null)
    }

    fun setSignatureFlowOnEftpos(signatureFlowOnEftpos: Boolean, result: Result) {
        mSpi.config.isSignatureFlowOnEftpos = signatureFlowOnEftpos
        result.success(null)
    }

    fun setPrintMerchantCopy(printMerchantCopy: Boolean, result: Result) {
        mSpi.config.isPrintMerchantCopy = printMerchantCopy
        result.success(null)
    }

    fun mapSecrets(obj: Secrets?):  HashMap<String, Any>? {
        if (obj == null) return null
        var map : HashMap<String, Any>
                = HashMap<String, Any> ()
        map.put("encKey", obj.encKey)
        map.put("hmacKey", obj.hmacKey)
        return map
    }

    fun mapPairingFlowState(obj: PairingFlowState): HashMap<String, Any> {
        var map : HashMap<String, Any>
                = HashMap<String, Any> ()
        map.put("message", obj.message)
        map.put("awaitingCheckFromEftpos", obj.isAwaitingCheckFromEftpos)
        map.put("awaitingCheckFromPos", obj.isAwaitingCheckFromPos)
        map.put("confirmationCode", obj.confirmationCode)
        map.put("finished", obj.isFinished)
        map.put("successful", obj.isSuccessful)
        return map
    }

    fun mapTransactionState(obj: TransactionFlowState): HashMap<String, Any?> {
        var map : HashMap<String, Any?>
                = HashMap<String, Any?> ()
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
        map.put("phoneForAuthRequiredMessage", mapPhoneForAuthRequired(obj.phoneForAuthRequiredMessage))
        map.put("cancelAttemptTime", obj.cancelAttemptTime.toString())
        map.put("request", mapMessage(obj.request))
        map.put("awaitingGltResponse", obj.isAwaitingGtResponse)  //GltResponse has been replaced by GtResponse
        return map
    }

    fun mapSpiConfig(obj: SpiConfig): HashMap<String, Any> {
        var map : HashMap<String, Any>
                = HashMap<String, Any> ()
        map.put("promptForCustomerCopyOnEftpos", obj.isPromptForCustomerCopyOnEftpos)
        map.put("signatureFlowOnEftpos", obj.isSignatureFlowOnEftpos)
        return map
    }

    fun mapMessage(obj: Message?): HashMap<String, Any?> {
        var map : HashMap<String, Any?>
                = HashMap<String, Any?> ()
        map.put("id", obj?.id)
        map.put("event", obj?.eventName)
        map.put("data", hashMapToWritableMap(obj?.data))
        return map
    }

    fun mapTenants(obj: Tenants): ArrayList<HashMap<String, String>> {
        var list : ArrayList<HashMap<String, String>>
                = ArrayList<HashMap<String, String>>()
        for (datum in obj.data) {
            var map : HashMap<String, String>
                    = HashMap<String, String> ()
            map.put("name", datum.name)
            map.put("code", datum.code)
            list.add(map)
        }
        return list
    }

    @Suppress("UNCHECKED_CAST")
    private fun hashMapToWritableMap(map: Map<String, Any?>?): HashMap<String, Any?> {
        var result : HashMap<String, Any?>
                = HashMap<String, Any?> ()
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
                        v.map { it to  hashMapToWritableMap(it as Map<String, Any?>) }.toList()
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
        var map : HashMap<String, Any?>
                = HashMap<String, Any?> ()
        map.put("requestId", obj?.requestId)
        map.put("posRefId", obj?.posRefId)
        map.put("receiptToSign", obj?.merchantReceipt)
        return map
    }

    fun mapPhoneForAuthRequired(obj: PhoneForAuthRequired?):  HashMap<String, Any?> {
        var map : HashMap<String, Any?>
                = HashMap<String, Any?> ()
        map.put("requestId", obj?.requestId)
        map.put("posRefId", obj?.posRefId)
        map.put("phoneNumber", obj?.phoneNumber)
        map.put("merchantId", obj?.merchantId)
        return map
    }


    companion object {

        private const val statusChangedEvent = "StatusChanged"
        private const val pairingFlowStateChangedEvent = "PairingFlowStateChanged"
        private const val txFlowStateChangedEvent = "TxFlowStateChanged"
        private const val secretsChangedEvent = "SecretsChanged"

        private fun Result.handleResult(success: Boolean, result: Result) {
            if (success) {
                result.success(null)
            } else {
                result.error("ERROR", "Error.", null)
            }
        }

        private fun Result.handleResult(initiateTxResult: InitiateTxResult, result: Result) {
            if (initiateTxResult.isInitiated) {
                result.success(null)
            } else {
                result.error("ERROR", "Error.", null)
            }
        }

        private fun Result.handleResult(midTxResult: MidTxResult, result: Result) {
            if (midTxResult.isValid) {
                result.success(null)
            } else {
                result.error("ERROR", "Error.", null)
            }
        }

        private fun Result.handleResult(submitAuthCodeResult: SubmitAuthCodeResult, result: Result) {
            if (submitAuthCodeResult.isValidFormat) {
                result.success(null)
            } else {
                result.error("ERROR", "Error.", null)
            }
        }

    }

    private fun initTerminalSettings(eftposAddress: String?, posId: String?, port: Int?): TerminalSettings {
        val settings: com.six.timapi.TerminalSettings = TerminalSettings()
        settings.setTerminalId(posId)
        settings.setConnectionMode(com.six.timapi.constants.ConnectionMode.ON_FIX_IP)
        settings.setGuides(EnumSet.of(Guides.RETAIL))
        settings.setConnectionIPString(eftposAddress)
        settings.setConnectionIPPort(port ?: 7784)
        settings.setIntegratorId("fc5bd2aa-d29d-4d7d-9d0b-8f8c7384a552")
        settings.setEnableKeepAlive(true)
        settings.setAutoCommit(true)
        settings.setGuides(EnumSet.of(Guides.RETAIL))
        settings.setDcc(false)
        settings.setTipAllowed(false)

        val logPath = context.filesDir.absolutePath + "/six_logs"
        settings.setLogDir(logPath)

        return settings
    }

    private fun setupLoggerForTim(terminal: Terminal) {
        val logger = Logger.getLogger(terminal.loggerName)
        logger.level = Level.ALL
        for (handler in logger.handlers) {
            handler.level = Level.FINEST
        }
    }

    private fun setPrintOptionsForTim(terminal: Terminal) {
        // For accreditation - this method is only called when enablePrinting is true
        val printOption = PrintOption(
            Recipient.BOTH,
            PrintFormat.ON_DEVICE_WITH_RECEIPT,
            32,
            EnumSet.noneOf(PrintFlag::class.java)
        )
        terminal.setPrintOptions(listOf(printOption))
    }

/*    private fun sendTimError(eventSink: EventChannel.EventSink?, source: String, exception: Exception?) {
        val errorMessage = exception?.localizedMessage ?: "Unknown error"

        Handler(Looper.getMainLooper()).post {
            eventSink?.success(
                mapOf(
                    "type" to "error",
                    "source" to source, // Source identifier for error tracking (e.g., "login", "activate")
                    "message" to "$source failed: $errorMessage"
                )
            )
        }
    }*/
    private fun addTerminalListeners(terminal: Terminal) {
        terminal.addListener(object : TerminalListener {
            override fun connectCompleted(event: TimEvent?) {
                println("✅ connectCompleted triggered")
                
                println("📊 Event: $event")
                
                // 检查 event 是否为 null
                if (event == null) {
                    println("❌ Connect failed: event is null")
                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(
                            mapOf(
                                "type" to "error",
                                "message" to "Connect failed: event is null",
                                "resultCode" to "UNKNOWN_ERROR"
                            )
                        )
                    }
                    return
                }
                
                val exception = event.getException()
                println("📊 Exception: $exception")

                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(
                        if (exception == null) {
                            mapOf("type" to "connectCompleted", "status" to "success")
                        } else {
                            mapOf(
                                "type" to "error",
                                "message" to "Connect failed: ${exception.errorMessage ?: "Unknown error"}",
                                "resultCode" to (exception.resultCode?.name ?: "UNKNOWN_ERROR")
                            )
                        }
                    )
                }
            }
            override fun activateCompleted(event: TimEvent?, p1: ActivateResponse?) {
                println("✅ activateCompleted triggered")
                val exception = event?.getException()

                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(
                        if (exception == null) {
                            mapOf("type" to "activateCompleted", "status" to "success")
                        } else {
                            mapOf(
                                "type" to "error",
                                "message" to "Activate failed: ${exception.errorMessage ?: "Unknown error"}",
                                "resultCode" to (exception.resultCode?.name ?: "UNKNOWN_ERROR")
                            )
                        }
                    )
                }
            }

            override fun applicationInformationCompleted(p0: TimEvent?) {
                println("✅ applicationInformationCompleted triggered")
            }

            override fun balanceCompleted(event: TimEvent?, data: BalanceResponse?) {
                val exception = event?.getException()

                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(
                        if (data != null) {
                            val receiptList = data.printData?.receipts?.mapNotNull { it?.value }?.filter { it.isNotBlank() } ?: emptyList()

                            mapOf("type" to "balanceCompleted",
                                "receipts" to receiptList)
                        } else {
                            mapOf(
                                "type" to "error",
                                "message" to "Balance failed: ${exception?.errorMessage ?: "Unknown error (no data returned)"}",
                                "resultCode" to (exception?.resultCode?.name ?: "UNKNOWN_ERROR")
                            )
                        }
                    )
                }
            }

            override fun changeSettingsCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun commitCompleted(p0: TimEvent?, p1: PrintData?) {
                println("Not yet implemented")
            }

            override fun counterRequestCompleted(p0: TimEvent?, p1: Counters?) {
                println("Not yet implemented")
            }

            override fun deactivateCompleted(event: TimEvent?, response: DeactivateResponse?) {
                println("✅ deactivateCompleted triggered")
                val exception = event?.getException()
                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(
                        if (exception == null) {
                            mapOf("type" to "deactivateCompleted", "status" to "success")
                        } else {
                            mapOf(
                                "type" to "unpairError",
                                "message" to "Deactivate failed: "+ (exception.errorMessage ?: "Unknown error"),
                                "resultCode" to (exception.resultCode?.name ?: "UNKNOWN_ERROR")
                            )
                        }
                    )
                }
            }

            override fun dccRatesCompleted(p0: TimEvent?, p1: PrintData?) {
                println("Not yet implemented")
            }

            override fun hardwareInformationCompleted(
                p0: TimEvent?,
                p1: HardwareInformationResponse?
            ) {
                println("Not yet implemented")
            }

            override fun initTransactionCompleted(p0: TimEvent?, p1: CardData?) {
                println("✅ initTransactionCompleted triggered")
            }

            override fun initTransactionWithDialogCompleted(
                p0: TimEvent?,
                p1: InitTransactionResponse?
            ) {
                println("Not yet implemented")
            }

            override fun loginCompleted(event: TimEvent?) {
                println("✅ loginCompleted triggered")
                val exception = event?.getException()

                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(
                        if (exception == null) {
                            mapOf("type" to "loginCompleted", "status" to "success")
                        } else {
                            mapOf(
                                "type" to "error",
                                "message" to "Login failed: ${exception.localizedMessage ?: "Unknown error"}",
                                "resultCode" to (exception.resultCode?.name ?: "UNKNOWN_ERROR")
                            )
                        }
                    )
                }
            }

            override fun logoutCompleted(event: TimEvent?) {
                println("✅ logoutCompleted triggered")
                val exception = event?.getException()
                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(
                        if (exception == null) {
                            mapOf("type" to "logoutCompleted", "status" to "success")
                        } else {
                            mapOf(
                                "type" to "unpairError",
                                "message" to "Logout failed: "+ (exception.errorMessage ?: "Unknown error"),
                                "resultCode" to (exception.resultCode?.name ?: "UNKNOWN_ERROR")
                            )
                        }
                    )
                }
            }

            override fun rebootCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun reconciliationCompleted(
                p0: TimEvent?,
                p1: ReconciliationResponse?
            ) {
                println("Not yet implemented")
            }

            override fun receiptRequestCompleted(
                event: TimEvent?,
                data: ReceiptRequestResponse?
            ) {
                println("receiptRequestCompleted triggered")
                if (data != null) {
                    println("✅ Receipt data received - hasMoreReceipts: ${data.hasMoreReceipts()}")
                } else {
                    println("❌ Receipt data is null")
                }
            }

            override fun transactionInfoRequestCompleted(
                p0: TimEvent?,
                p1: TransactionInfoRequestResponse?
            ) {
                println("Not yet implemented")
            }

            override fun reconfigCompleted(p0: TimEvent?, p1: PrintData?) {
                println("Not yet implemented")
            }

            override fun rollbackCompleted(p0: TimEvent?, p1: PrintData?) {
                println("Not yet implemented")
            }

            override fun softwareUpdateCompleted(p0: TimEvent?, p1: UpdateStatus?) {
                println("Not yet implemented")
            }

            override fun systemInformationCompleted(
                p0: TimEvent?,
                p1: SystemInformationResponse?
            ) {
                println("Not yet implemented")
            }

            override fun transactionCompleted(event: TimEvent, data: TransactionResponse?) {
                println("🟢 transactionCompleted callback triggered")
                val exception = event.getException()
                
                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(
                        if (data != null && exception == null) {
                            // Extract transaction data
                            val transInfo = data.transactionInformation
                            val receiptList = data.printData?.receipts?.mapNotNull { it?.value }?.filter { it.isNotBlank() } ?: emptyList()
                            
                            mapOf(
                                "type" to "transactionCompleted",
                                "amount" to data.amount.amount,
                                "currency" to data.amount.currency.name,
                                "transactionType" to data.transactionType.name,
                                "transRef" to transInfo?.transRef,
                                "transSeq" to transInfo?.transSeq,
                                "cardRef" to transInfo?.cardId,
                                "acqTransRef" to transInfo?.acqTransRef,
                                "receipts" to receiptList
                            )
                        } else {
                            mapOf(
                                "type" to "error",
                                "message" to "Transaction failed: ${exception?.errorMessage ?: "Unknown error (no data returned)"}",
                                "resultCode" to (exception?.resultCode?.name ?: "UNKNOWN_ERROR")
                            )
                        }
                    )
                }
            }

            override fun clientIdentificationCompleted(
                p0: TimEvent?,
                p1: ClientIdentificationResponse?
            ) {
                println("Not yet implemented")
            }

            override fun terminalStatusChanged(terminal: Terminal?) {
                println("✅ terminalStatusChanged triggered")
                
                if (terminal == null) {
                    println("❌ Terminal is null")
                    return
                }
                
                try {
                    val connectionStatus = terminal.getTerminalStatus().connectionStatus?.name ?: "Unknown"
                    println("📊 Terminal Status: $connectionStatus")
                    
                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(
                            mapOf(
                                "type" to "terminalStatusChanged",
                                "connectionStatus" to connectionStatus
                            )
                        )
                    }
                } catch (e: Exception) {
                    println("❌ Error processing terminal status: ${e.message}")
                }
            }

            override fun disconnected(terminal: Terminal?, exception: TimException?) {
                println("✅ disconnected triggered")
                if (terminal == null) {
                     Handler(Looper.getMainLooper()).post {
                        eventSink?.success(
                            mapOf(
                                "type" to "disconnected",
                                "status" to "failed",
                                "message" to (exception?.errorMessage ?: "Unknown error"),
                                "resultCode" to (exception?.resultCode?.name ?: "UNKNOWN_ERROR")
                            )
                        )
                    }
                    return
                }
                try {
                    val connectionStatus = terminal.getTerminalStatus().connectionStatus?.name ?: "Unknown"
                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(
                            mapOf(
                                "type" to "disposed",
                                "status" to "success",
                                "connectionStatus" to connectionStatus
                            )
                        )
                    }
                    terminal?.dispose()
                    // 重置 mTim 变量，避免后续调用已销毁的实例
                    mTim = null
                } catch (e: Exception) {
                    println("❌ Error disposing terminal: ${e.message}")
                        Handler(Looper.getMainLooper()).post {
                            eventSink?.success(
                                mapOf(
                                    "type" to "disconnected",
                                    "status" to "failed",
                                    "message" to (e.localizedMessage ?: "Dispose failed"),
                                    "resultCode" to "DISPOSE_FAILED"
                                )
                            )
                        }
                }
            }

            override fun closeReaderCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun openReaderCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun ejectCardCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun openMaintenanceWindowCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun closeMaintenanceWindowCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun activateServiceMenuCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun openDialogModeCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun closeDialogModeCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun showSignatureCaptureCompleted(
                p0: TimEvent?,
                p1: ShowSignatureCaptureResponse?
            ) {
                println("Not yet implemented")
            }

            override fun showDialogCompleted(p0: TimEvent?, p1: ShowDialogResponse?) {
                println("Not yet implemented")
            }

            override fun sendCardCommandCompleted(
                p0: TimEvent?,
                p1: MutableList<CommandResponse>?
            ) {
                println("Not yet implemented")
            }

            override fun printOnTerminal(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun balanceInquiryCompleted(
                p0: TimEvent?,
                p1: BalanceInquiryResponse?
            ) {
                println("Not yet implemented")
            }

            override fun deferredAuth(p0: Terminal?, p1: TransactionResponse?) {
                println("Not yet implemented")
            }

            override fun keyPressed(p0: Terminal?, p1: Reason?) {
                println("Not yet implemented")
            }

            override fun screenshot(p0: Terminal?, p1: ScreenshotInformation?) {
                println("Not yet implemented")
            }

            override fun errorNotification(p0: Terminal?, p1: TimException?) {
                println("Not yet implemented")
            }

            override fun licenseChanged(p0: Terminal?) {
                println("Not yet implemented")
            }

            override fun vasInfo(p0: Terminal?, p1: VasCheckoutInformation?) {
                println("Not yet implemented")
            }

            override fun loyaltyDataCompleted(p0: TimEvent?, p1: CardData?) {
                println("Not yet implemented")
            }

            override fun startCheckoutCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun finishCheckoutCompleted(
                p0: TimEvent?,
                p1: VasCheckoutInformation?
            ) {
                println("Not yet implemented")
            }

            override fun provideLoyaltyBasketCompleted(
                p0: TimEvent?,
                p1: MutableList<LoyaltyItem>?
            ) {
                println("Not yet implemented")
            }

            override fun provideVasResultCompleted(p0: TimEvent?, p1: VasResult?) {
                println("Not yet implemented")
            }

            override fun mobileTopupIssuerInfoCompleted(
                p0: TimEvent?,
                p1: MutableList<MobileTopupValue>?
            ) {
                println("Not yet implemented")
            }

            override fun mobileTopupCompleted(p0: TimEvent?, p1: MobileTopupData?) {
                println("Not yet implemented")
            }

            override fun thirdPartyAppData(p0: Terminal?, p1: ThirdPartyAppPayload?) {
                println("Not yet implemented")
            }

            override fun requestAliasCompleted(p0: TimEvent?, p1: String?) {
                println("Not yet implemented")
            }

            override fun deviceMaintenanceCompleted(p0: TimEvent?) {
                println("Not yet implemented")
            }

            override fun ageCheckCompleted(p0: TimEvent?, p1: TransactionInformation?) {
                println("Not yet implemented")
            }
        })
    }
    private fun timApiInit(eftposAddress: String?, posId: String?, port: Int?, enablePrinting: Boolean, result: Result) {
        try {
            println("......TIM API Init with eftposAddress=$eftposAddress, posId=$posId, enablePrinting=$enablePrinting")

            // 如果已经有 Terminal 实例，先清理它
            if (mTim != null) {
                try {
                    mTim?.dispose()
                } catch (e: Exception) {
                    println("⚠️ Warning: Failed to dispose existing terminal: ${e.message}")
                }
                mTim = null
            }

            val settings = initTerminalSettings(eftposAddress, posId, port)
            mTim = Terminal(settings)

            setupLoggerForTim(mTim!!)
            if (enablePrinting) {
                setPrintOptionsForTim(mTim!!)
            }
            addTerminalListeners(mTim!!)

            result.success(null)
        } catch (e: TimException) {
            result.error("INIT_FAILED", e.localizedMessage, null)
        }
    }

    private fun timApiConnect(result: Result) {
        try {
//            if (mTim == null) {
//                result.error("Connect_FAILED", "Terminal not initialized. Please call init first.", null)
//                return
//            }
            mTim?.connectAsync()

            result.success(null)
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Connect request pending - terminal is busy with another operation")
                result.error("Connect_FAILED", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("Connect_FAILED", e.localizedMessage, null)
            }
        } catch (e: IllegalStateException) {
            result.error("Connect_FAILED", "Terminal has been disposed. Please reinitialize: ${e.message}", null)
        } catch (e: Exception) {
            result.error("Connect_FAILED", "Unexpected error: ${e.message}", null)
        }
    }

    private fun timApiLogin(result: Result) {
        try {
            if (mTim == null) {
                result.error("Login_FAILED", "Terminal not initialized. Please call init first.", null)
                return
            }
            mTim?.loginAsync()

            result.success(null)
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Login request pending - terminal is busy with another operation")
                result.error("Login_FAILED", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("Login_FAILED", e.localizedMessage, null)
            }
        } catch (e: IllegalStateException) {
            result.error("Login_FAILED", "Terminal has been disposed. Please reinitialize: ${e.message}", null)
        } catch (e: Exception) {
            result.error("Login_FAILED", "Unexpected error: ${e.message}", null)
        }
    }

    private fun timApiActivate(result: Result) {
        try {
            if (mTim == null) {
                result.error("Activate_FAILED", "Terminal not initialized. Please call init first.", null)
                return
            }

            mTim?.activateAsync()

            result.success(null)
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Activate request pending - terminal is busy with another operation")
                result.error("Activate_FAILED", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("Activate_FAILED", e.localizedMessage, null)
            }
        } catch (e: IllegalStateException) {
            result.error("Activate_FAILED", "Terminal has been disposed. Please reinitialize: ${e.message}", null)
        } catch (e: Exception) {
            result.error("Activate_FAILED", "Unexpected error: ${e.message}", null)
        }
    }

    private fun timApiDeactivate(result: Result) {
        try {
            if (mTim == null) {
                result.error("Deactivate_FAILED", "Terminal not initialized. Please call init first.", null)
                return
            }
            mTim?.deactivateAsync()
            result.success(null)
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Deactivate request pending - terminal is busy with another operation")
                result.error("Deactivate_FAILED", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("Deactivate_FAILED", e.localizedMessage, null)
            }
        } catch (e: Exception) {
            result.error("Deactivate_FAILED", e.localizedMessage, null)
        }
    }

    private fun timApiLogout(result: Result) {
        try {
            if (mTim == null) {
                result.error("Logout_FAILED", "Terminal not initialized. Please call init first.", null)
                return
            }
            mTim?.logoutAsync()
            result.success(null)
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Logout request pending - terminal is busy with another operation")
                result.error("Logout_FAILED", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("Logout_FAILED", e.localizedMessage, null)
            }
        } catch (e: Exception) {
            result.error("Logout_FAILED", e.localizedMessage, null)
        }
    }

    private fun timApiDisconnect(result: Result) {
        try {
            if (mTim == null) {
                result.error("Disconnect_FAILED", "Terminal not initialized. Please call init first.", null)
                return
            }
            mTim?.disconnectAsync()
            result.success(null)
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Disconnect request pending - terminal is busy with another operation")
                result.error("Disconnect_FAILED", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("Disconnect_FAILED", e.localizedMessage, null)
            }
        } catch (e: Exception) {
            result.error("Disconnect_FAILED", e.localizedMessage, null)
        }
    }

    private fun dummy(result: Result) {
        print("hello");
    }

    private fun timApiStartTransaction(posRefId: String?, amount: Double, result: Result) {
        try {
            Log.d("TimAPI", "Starting transaction with posRefId=$posRefId amount=$amount")

            if (mTim == null) {
                result.error("TRANSACTION_ERROR", "Terminal not initialized. Please call init first.", null)
                return
            }

            if (mTim?.getTerminalStatus()?.getTransactionStatus() == TimapiTransactionStatus.IDLE) {
                val transactionAmount = TimapiAmount(amount / 100.0, TimapiCurrency.AUD)

                // Use async
                mTim?.transactionAsync(TimapiTransactionType.PURCHASE, transactionAmount)

                // ⚠️ Don't return result.success(true) because transaction is not finished yet
                result.success(null)  // Indicates "call was successfully sent", not "transaction completed"
            } else {
                result.error("TERMINAL_BUSY", "Terminal is busy processing another transaction", null)
            }
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Transaction request pending - terminal is busy with another operation")
                result.error("TRANSACTION_ERROR", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("TRANSACTION_ERROR", "Failed to start transaction: ${e.message}", null)
            }
        } catch (e: Exception) {
            result.error("TRANSACTION_ERROR", "Failed to start transaction: ${e.message}", null)
        }
    }


    private fun timApiDoRefund(posRefId: String?, amount: Double, result: Result) { //for standard refund
        try {
            Log.d("TimAPI", "Starting standard refund with posRefId=$posRefId amount=$amount")

            if (mTim == null) {
                result.error("REFUND_ERROR", "Terminal not initialized. Please call init first.", null)
                return
            }

            if (mTim?.getTerminalStatus()?.getTransactionStatus() == TimapiTransactionStatus.IDLE) {
                val refundAmount = TimapiAmount(amount / 100.0, TimapiCurrency.AUD)

                // ✅ Refund uses CREDIT 
                mTim?.transactionAsync(TimapiTransactionType.CREDIT, refundAmount)

                result.success(null)
            } else {
                result.error("TERMINAL_BUSY", "Terminal is busy processing another transaction", null)
            }
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Refund request pending - terminal is busy with another operation")
                result.error("REFUND_ERROR", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("REFUND_ERROR", "Failed to start refund: ${e.message}", null)
            }
        } catch (e: Exception) {
            result.error("REFUND_ERROR", "Failed to start refund: ${e.message}", null)
        }
    }

    private fun timApiDoRefRefund(posRefId: String?, amount: Double, sixTrxRefNum: String?, result: Result) { //for reference refund
        try {
            Log.d("TimAPI", "Starting reference refund with posRefId=$posRefId, sixTrxRefNum=$sixTrxRefNum, amount=$amount")

            if (mTim == null) {
                result.error("REFUND_ERROR", "Terminal not initialized. Please call init first.", null)
                return
            }

            if (mTim?.getTerminalStatus()?.getTransactionStatus() == TimapiTransactionStatus.IDLE) {
                val refundAmount = TimapiAmount(amount / 100.0, TimapiCurrency.AUD)

                // Build TransactionData and set reference information
                val txnData = TransactionData()
                
                // Set six trx ref num
                if (!sixTrxRefNum.isNullOrBlank()) {
                    txnData.setSixTrxRefNum(sixTrxRefNum)
                }

                // Build TransactionRequest and set data
                val request = TransactionRequest()
                request.setAmount(refundAmount)
                request.setTransactionData(txnData)

                // Initiate CREDIT type transaction (refund)
                mTim?.transactionAsync(TimapiTransactionType.CREDIT, request)

                result.success(null)
            } else {
                result.error("TERMINAL_BUSY", "Terminal is busy processing another transaction", null)
            }
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Reference refund request pending - terminal is busy with another operation")
                result.error("REFUND_ERROR", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("REFUND_ERROR", "Failed to start reference refund: ${e.message}", null)
            }
        } catch (e: Exception) {
            result.error("REFUND_ERROR", "Failed to start reference refund: ${e.message}", null)
        }
    }

    private fun timApiDoBalance(posRefId: String?,result: Result) {
        try {
            Log.d("TimAPI", "Starting balance with posRefId=$posRefId")

            if (mTim == null) {
                result.error("BALANCE_ERROR", "Terminal not initialized. Please call init first.", null)
                return
            }

            mTim?.balanceAsync() // Asynchronously trigger Balance operation, automatically sends deactivate request first

            result.success(null)

        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Balance request pending - terminal is busy with another operation")
                result.error("BALANCE_ERROR", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("BALANCE_ERROR", "Failed to start balance: ${e.message}", null)
            }
        } catch (e: Exception) {
            result.error("BALANCE_ERROR", "Failed to start balance: ${e.message}", null)
        }
    }

    private fun timApiDoReversal(posRefId: String?, transSeq: String?, result: Result) {
        try {
            Log.d("TimAPI", "Starting reversal with posRefId=$posRefId, transSeq=$transSeq")

            if (mTim == null) {
                result.error("REVERSAL_ERROR", "Terminal not initialized. Please call init first.", null)
                return
            }

            if (mTim?.getTerminalStatus()?.getTransactionStatus() == TimapiTransactionStatus.IDLE) {
                //val reversalAmount = TimapiAmount(0.0, TimapiCurrency.AUD)
                val txnData = TransactionData()
                if (transSeq != null) {
                    txnData.setTransSeq(transSeq.toLong())
                }
                val request = TransactionRequest()
                request.setTransactionData(txnData)
                //request.setAmount(reversalAmount)

                mTim?.transactionAsync(TimapiTransactionType.REVERSAL, request)
                result.success(null)
            } else {
                result.error("TERMINAL_BUSY", "Terminal is busy processing another transaction", null)
            }
        } catch (e: TimException) {
            // REQUEST_PENDING 表示终端正在处理其他请求，需要等待
            if (e.resultCode?.name == "REQUEST_PENDING") {
                println("⚠️ Reversal request pending - terminal is busy with another operation")
                result.error("REVERSAL_ERROR", "Terminal is busy with another operation. Please try again later.", null)
            } else {
                result.error("REVERSAL_ERROR", "Failed to start reversal: ${e.message}", null)
            }
        } catch (e: Exception) {
            result.error("REVERSAL_ERROR", "Failed to start reversal: ${e.message}", null)
        }
    }

    /*private fun timApiPrint(ticket:String?, result: Result) {// funcprivate fun timApiDoReversal(posRefId: String?, result: Result) {
    try {
        Log.d("TimAPI", "Starting reversal with posRefId=$posRefId")

        if (mTim.getTerminalStatus().getTransactionStatus() == TimapiTransactionStatus.IDLE) {
            val reversalAmount = TimapiAmount(0.0, TimapiCurrency.AUD) // 或者传实际金额
            mTim.transactionAsync(TimapiTransactionType.REVERSAL, reversalAmount)
            result.success(null)
        } else {
            result.error("TERMINAL_BUSY", "Terminal is busy processing another transaction", null)
        }
    } catch (e: Exception) {
        result.error("REVERSAL_ERROR", "Failed to start reversal: ${e.message}", null)
    }
}ion not accepted
        try {
            Log.d("TimAPI", "Requesting last receipt...")

            mTim.printOnTerminalAsync(ticket) // Function disallowed in API, check later

            result.success(null)
        } catch (e: Exception) {
            Log.e("TimAPI", "❌ Receipt request failed: ${e.message}")
            result.error("RECEIPT_REQUEST_FAILED", e.message, null)
        }
    }*/
    
    fun timApiTestConnection(result: Result) {
        try {
            val settings = TerminalSettings()
            val logDir = context.getExternalFilesDir(null)?.absolutePath + "/logs"
            settings.logDir = logDir
            Log.d("TimAPI_TEST", "Log directory set to: $logDir")

            settings.terminalId = "25196219"
            settings.setConnectionMode(ConnectionMode.ON_FIX_IP)
            settings.setConnectionIPString("172.20.10.4")
            settings.setConnectionIPPort(7784)
            settings.setAutoCommit(true)
            settings.setGuides(EnumSet.of(Guides.RETAIL))
            settings.setDcc(false)
            settings.setTipAllowed(false)

            val testTerminal = Terminal(settings)
            val testResults = HashMap<String, String>()

            Log.d("TimAPI_TEST", "Test 1: Getting terminal status...")
            try {
                val terminalStatus = testTerminal.getTerminalStatus()
                testResults["getTerminalStatus"] = "SUCCESS - Transaction status: ${terminalStatus.transactionStatus}"
                Log.d("TimAPI_TEST", testResults["getTerminalStatus"]!!)
            } catch (e: Exception) {
                testResults["getTerminalStatus"] = "FAILED - Error: ${e.message}"
                Log.e("TimAPI_TEST", testResults["getTerminalStatus"]!!)
            }

            if (testTerminal.getTerminalStatus().transactionStatus == TimapiTransactionStatus.IDLE) {
                Log.d("TimAPI_TEST", "Test 3: Starting a test transaction...")
                try {
                    val txAmount = TimapiAmount(0.10, TimapiCurrency.USD)
                    testTerminal.transaction(TimapiTransactionType.PURCHASE, txAmount)
                    testResults["startTransaction"] = "SUCCESS - Test transaction started"
                    Log.d("TimAPI_TEST", testResults["startTransaction"]!!)
                } catch (e: Exception) {
                    testResults["startTransaction"] = "FAILED - Error: ${e.message}"
                    Log.e("TimAPI_TEST", testResults["startTransaction"]!!)
                }
            } else {
                testResults["startTransaction"] = "SKIPPED - Terminal not in IDLE state"
                Log.d("TimAPI_TEST", testResults["startTransaction"]!!)
            }

            val resultSummary = StringBuilder()
            resultSummary.append("TimAPI Test Results:\n")
            testResults.forEach { (funcName, value) ->
                resultSummary.append("- $funcName: $value\n")
            }

            try {
                testTerminal.dispose()
                Log.d("TimAPI_TEST", "Test terminal disposed")
            } catch (e: Exception) {
                Log.e("TimAPI_TEST", "Error disposing test terminal: ${e.message}")
            }

            result.success(resultSummary.toString())
        } catch (e: Exception) {
            Log.e("TimAPI_TEST", "Test initialization error: ${e.message}")
            result.error("TEST_ERROR", "Failed to initialize TimAPI test: ${e.message}", null)
        }
    }

}
