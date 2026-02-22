import Flutter
import UIKit
import GoogleMaps
import PassKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPaymentAuthorizationControllerDelegate {
    var paymentResult: FlutterResult?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyBGxQwI9bZy3GPmAIzwGXV5m2gs3ob2igo")
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let applePayChannel = FlutterMethodChannel(name: "com.ucpksa/apple_pay",
                                                  binaryMessenger: controller.binaryMessenger)
        
        applePayChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "startApplePay" {
                self.handleApplePayCall(call: call, result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleApplePayCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.paymentResult = result
        
        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? String,
              let currency = args["currency"] as? String,
              let merchantId = args["merchantId"] as? String,
              let label = args["label"] as? String,
              let countryCode = args["countryCode"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Arguments are missing", details: nil))
            return
        }
        
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantId
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currency
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex, .mada]
        
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(string: amount))
        ]
        
        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        paymentController.present(completion: { (presented: Bool) in
            if !presented {
                result(FlutterError(code: "PRESENTATION_FAILED", message: "Failed to present Apple Pay", details: nil))
            }
        })
    }
    
    // MARK: - PKPaymentAuthorizationControllerDelegate
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        let token = payment.token
        let paymentData = token.paymentData
        
        do {
            let paymentDataJson = try JSONSerialization.jsonObject(with: paymentData, options: [])
            
            let response: [String: Any] = [
                "paymentData": paymentDataJson,
                "transactionIdentifier": token.transactionIdentifier,
                "paymentMethod": [
                    "displayName": token.paymentMethod.displayName ?? "",
                    "network": token.paymentMethod.network?.rawValue ?? "",
                    "type": token.paymentMethod.type.rawValue
                ]
            ]
            
            self.paymentResult?(response)
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        } catch {
            self.paymentResult?(FlutterError(code: "JSON_ERROR", message: "Failed to parse payment data", details: nil))
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
        }
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
        if self.paymentResult != nil {
            self.paymentResult?(nil) // User cancelled or finished without auth
            self.paymentResult = nil
        }
    }
}
