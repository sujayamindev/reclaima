// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claims_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing claims for a specific receipt

@ProviderFor(Claims)
final claimsProvider = ClaimsFamily._();

/// Notifier for managing claims for a specific receipt
final class ClaimsProvider extends $NotifierProvider<Claims, ClaimsState> {
  /// Notifier for managing claims for a specific receipt
  ClaimsProvider._({
    required ClaimsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'claimsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$claimsHash();

  @override
  String toString() {
    return r'claimsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Claims create() => Claims();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClaimsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClaimsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClaimsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$claimsHash() => r'92fc57a60668f3da66dab51e2b60f773e8995e95';

/// Notifier for managing claims for a specific receipt

final class ClaimsFamily extends $Family
    with
        $ClassFamilyOverride<
          Claims,
          ClaimsState,
          ClaimsState,
          ClaimsState,
          String
        > {
  ClaimsFamily._()
    : super(
        retry: null,
        name: r'claimsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for managing claims for a specific receipt

  ClaimsProvider call(String receiptId) =>
      ClaimsProvider._(argument: receiptId, from: this);

  @override
  String toString() => r'claimsProvider';
}

/// Notifier for managing claims for a specific receipt

abstract class _$Claims extends $Notifier<ClaimsState> {
  late final _$args = ref.$arg as String;
  String get receiptId => _$args;

  ClaimsState build(String receiptId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClaimsState, ClaimsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClaimsState, ClaimsState>,
              ClaimsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
