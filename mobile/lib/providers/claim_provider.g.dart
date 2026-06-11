// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for tracking a pending replacement claim ID when the user chooses "Add New Receipt"

@ProviderFor(PendingReplacementClaimId)
final pendingReplacementClaimIdProvider = PendingReplacementClaimIdProvider._();

/// Provider for tracking a pending replacement claim ID when the user chooses "Add New Receipt"
final class PendingReplacementClaimIdProvider
    extends $NotifierProvider<PendingReplacementClaimId, String?> {
  /// Provider for tracking a pending replacement claim ID when the user chooses "Add New Receipt"
  PendingReplacementClaimIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingReplacementClaimIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingReplacementClaimIdHash();

  @$internal
  @override
  PendingReplacementClaimId create() => PendingReplacementClaimId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingReplacementClaimIdHash() =>
    r'ca505773d05e3adb774a62dced13bd6cd3af999d';

/// Provider for tracking a pending replacement claim ID when the user chooses "Add New Receipt"

abstract class _$PendingReplacementClaimId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
