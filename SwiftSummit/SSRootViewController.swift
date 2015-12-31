//
//  SSRootViewController.swift
//  SwiftSummit
//
//  Created by Wendy Lu on 10/28/15.
//  Copyright © 2015 Wendy Lu. All rights reserved.
//

import Foundation
import UIKit
import PassKit

enum CurrencyType : String {
    case USDollar = "en_US", CanadianDollar = "en_CA", Euro = "fr_FR", Pound = "en_GB"
}

class SSRootViewController : UIViewController, PKPaymentAuthorizationViewControllerDelegate {

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let number = 3
        let currencyType = CurrencyType.Pound

        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        formatter.locale = NSLocale(localeIdentifier: currencyType.rawValue)

        let formattedPrice = formatter.stringFromNumber(number)

        NSLog("%@", formattedPrice!)

        self.view.backgroundColor = UIColor.whiteColor()
        if (PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks([PKPaymentNetworkVisa, PKPaymentNetworkDiscover])) {
            let button = PKPaymentButton(type: PKPaymentButtonType.Plain, style: PKPaymentButtonStyle.Black)
            button.addTarget(self, action: "buttonTapped:", forControlEvents: UIControlEvents.TouchUpInside);
            self.view.addSubview(button)
            button.center = self.view.center;
        }
    }

    func buttonTapped(sender : AnyObject) {
        let request = PKPaymentRequest()
        request.supportedNetworks = [PKPaymentNetworkVisa, PKPaymentNetworkDiscover]
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.merchantIdentifier = #<your merchant ID>
        request.merchantCapabilities = .Capability3DS
        request.requiredShippingAddressFields = PKAddressField.PostalAddress.union(PKAddressField.Phone)
        request.requiredBillingAddressFields = PKAddressField.PostalAddress

        let subtotalItem = PKPaymentSummaryItem(label: "Subtotal", amount: NSDecimalNumber(double: 100.00))
        let taxItem = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(double: 8.75))
        let totalItem = PKPaymentSummaryItem(label: "Grass-fed Jeans Inc", amount: NSDecimalNumber(double: 108.75))
        let summaryItems = [subtotalItem, taxItem, totalItem]

        request.paymentSummaryItems = summaryItems

        let viewController = PKPaymentAuthorizationViewController(paymentRequest: request)
        viewController.delegate = self
        presentViewController(viewController, animated: true, completion: nil)
    }


    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didSelectShippingContact contact: PKContact, completion: (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {

        guard let postalCode = contact.postalAddress?.postalCode else {
            // Throw error
            completion(PKPaymentAuthorizationStatus.InvalidShippingContact, [], []);
            return;
        }

        let subtotal = self.subtotal()

        // Recalculate our tax and total
        let tax = self.taxForPostalCode(postalCode)
        let total = tax.decimalNumberByAdding(subtotal)

        // Create our new payment summary items
        let subtotalItem = PKPaymentSummaryItem(label: "Subtotal", amount: subtotal)
        let taxItem = PKPaymentSummaryItem(label: "Tax", amount: tax)
        let totalItem = PKPaymentSummaryItem(label: "Grass-fed Jeans Inc", amount: total)
        let paymentSummaryItems = [subtotalItem, taxItem, totalItem]

        let shippingMethods = self.shippingMethodsForPostalCode(postalCode);

        completion(PKPaymentAuthorizationStatus.Success, shippingMethods, paymentSummaryItems)
    }

    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        NSLog("%@", payment.token);
    }

    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        
    }

    func taxForPostalCode(postalCode: String) -> NSDecimalNumber {
        return NSDecimalNumber(string: "6.50")
    }

    func subtotal() -> NSDecimalNumber
    {
        return NSDecimalNumber(string: "100.0")
    }

    func shippingMethodsForPostalCode(postalCode: String) -> [PKShippingMethod] {


        let method = PKShippingMethod(label: "Standard Shipping", amount: NSDecimalNumber(string: "1.00"))
        return [method]
    }
}
