// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Receipt Controller

@ProviderFor(ReceiptController)
final receiptControllerProvider = ReceiptControllerProvider._();

/// Receipt Controller
final class ReceiptControllerProvider
    extends $AsyncNotifierProvider<ReceiptController, void> {
  /// Receipt Controller
  ReceiptControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptControllerHash();

  @$internal
  @override
  ReceiptController create() => ReceiptController();
}

String _$receiptControllerHash() => r'e665a2c9a2c9ecfa859f436aa34f854535b305c1';

/// Receipt Controller

abstract class _$ReceiptController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
