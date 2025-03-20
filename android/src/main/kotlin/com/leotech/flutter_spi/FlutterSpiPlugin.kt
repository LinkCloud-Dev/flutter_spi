package com.leotech.flutter_spi

import android.content.Context
import android.content.pm.PackageInfo
import android.os.Build
import android.os.Handler
import android.os.StrictMode
import android.util.Log
import androidx.annotation.NonNull
import io.mx51.spi.Spi;
import io.mx51.spi.Spi.CompatibilityException;
import io.mx51.spi.model.*;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.six.timapi.*

/** FlutterSpiPlugin */
class FlutterSpiPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var spiChannel: MethodChannel
  private lateinit var context: Context

  lateinit var mSpi: Spi

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    spiChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_spi")
    spiChannel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "init") {
      init(call.argument("posId")!!, call.argument("serialNumber")!!, call.argument("eftposAddress")!!,
        call.argument("apiKey")!!, call.argument("tenantCode")!!, call.argument("secrets"), result)
    } else if (call.method == "start") {
      start(result)
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
    } else if (call.method == "test") {
      test(result)
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
    mSpi.config.setPrintMerchantCopy(printMerchantCopy)
    result.success(null)
  }

  fun test(result: Result) {
    try {
      // Create new TerminalSettings instance
      val settings = TerminalSettings()

      // ----------------------------LOGGING----------------------------
      // Set the Logging directory path where the log file will be saved
      // Adjust this path based on your Android file system
      val logDir = context.getExternalFilesDir(null)?.absolutePath + "/logs"
      settings.logDir = logDir

      // ----------------------------CONNECTION----------------------------
      // Set the Terminal ID (Replace with the actual terminal ID)
      settings.terminalId = "12345678"

      // ----------------------------COMMIT----------------------------
      // If the ECR (this plugin) should be responsible for commit, set this to false.
      settings.isAutoCommit = false

      // ----------------------------CREATE TERMINAL INSTANCE----------------------------
      // Create a terminal instance using the adjusted settings
      val terminal = Terminal(settings)

      // Return success message
      Log.d("SUCCESS", "TimApi Test Success")
      result.success("TimApi Terminal initialized successfully")
    } catch (e: Exception) {
      Log.d("ERROR", "TimApi Test Error")
      result.error("INIT_ERROR", "Failed to initialize TimApi Terminal: ${e.message}", null)
    }
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
}

