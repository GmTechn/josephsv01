import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;

  static const String productId = 'com.josephs.voice.monthly';

  bool isAvailable = false;
  List<ProductDetails> products = [];
  List<PurchaseDetails> purchases = [];

  Future<void> init() async {
    isAvailable = await _iap.isAvailable();

    if (!isAvailable) return;

    final response = await _iap.queryProductDetails({productId});

    products = response.productDetails;

    _iap.purchaseStream.listen((purchaseDetailsList) {
      purchases.addAll(purchaseDetailsList);
    });
  }

  Future<void> buy() async {
    final product = products.firstWhere((p) => p.id == productId);

    final purchaseParam = PurchaseParam(productDetails: product);

    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  bool get isSubscribed {
    return purchases.any(
      (p) => p.productID == productId && p.status == PurchaseStatus.purchased,
    );
  }
}
