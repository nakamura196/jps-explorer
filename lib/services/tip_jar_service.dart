import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum TipJarState { idle, loading, purchasing, success, error }

class TipJarService extends ChangeNotifier {
  static const _productIds = <String>{
    'com.nakamura196.jpsExplorer.tip.small',
    'com.nakamura196.jpsExplorer.tip.medium',
    'com.nakamura196.jpsExplorer.tip.large',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  TipJarState _state = TipJarState.idle;
  TipJarState get state => _state;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool _available = false;
  bool get available => _available;

  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      _state = TipJarState.error;
      _errorMessage = 'In-app purchases not available';
      notifyListeners();
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        _state = TipJarState.error;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    _state = TipJarState.loading;
    notifyListeners();

    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      _state = TipJarState.error;
      _errorMessage = response.error!.message;
      notifyListeners();
      return;
    }

    _products = response.productDetails
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    _state = TipJarState.idle;
    notifyListeners();
  }

  Future<void> purchase(ProductDetails product) async {
    _state = TipJarState.purchasing;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _state = TipJarState.success;
          notifyListeners();
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          _state = TipJarState.error;
          _errorMessage = purchase.error?.message ?? 'Purchase failed';
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _state = TipJarState.idle;
          notifyListeners();
          break;
        case PurchaseStatus.pending:
          _state = TipJarState.purchasing;
          notifyListeners();
          break;
      }
    }
  }

  void resetState() {
    _state = TipJarState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
