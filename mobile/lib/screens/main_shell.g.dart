// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_shell.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MainNavIndex)
final mainNavIndexProvider = MainNavIndexProvider._();

final class MainNavIndexProvider extends $NotifierProvider<MainNavIndex, int> {
  MainNavIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mainNavIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mainNavIndexHash();

  @$internal
  @override
  MainNavIndex create() => MainNavIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$mainNavIndexHash() => r'8cb94c2ecb07da6d708e6f2c93b8e78a58a9168b';

abstract class _$MainNavIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(VaultSearchFocusTrigger)
final vaultSearchFocusTriggerProvider = VaultSearchFocusTriggerProvider._();

final class VaultSearchFocusTriggerProvider
    extends $NotifierProvider<VaultSearchFocusTrigger, bool> {
  VaultSearchFocusTriggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vaultSearchFocusTriggerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vaultSearchFocusTriggerHash();

  @$internal
  @override
  VaultSearchFocusTrigger create() => VaultSearchFocusTrigger();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$vaultSearchFocusTriggerHash() =>
    r'0f8b88b78dd942dc2a2c705b99f228081d15ed20';

abstract class _$VaultSearchFocusTrigger extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
