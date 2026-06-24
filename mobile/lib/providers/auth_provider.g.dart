// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auth Controller
///
/// keepAlive so long-running async methods (deleteAccount, signOut) that
/// `ref.read` services across `await` points aren't disposed mid-flight when
/// the only caller `ref.read`s the notifier without watching it — disposal
/// would make the post-await `ref.read` throw "Ref ... already disposed".

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Auth Controller
///
/// keepAlive so long-running async methods (deleteAccount, signOut) that
/// `ref.read` services across `await` points aren't disposed mid-flight when
/// the only caller `ref.read`s the notifier without watching it — disposal
/// would make the post-await `ref.read` throw "Ref ... already disposed".
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, void> {
  /// Auth Controller
  ///
  /// keepAlive so long-running async methods (deleteAccount, signOut) that
  /// `ref.read` services across `await` points aren't disposed mid-flight when
  /// the only caller `ref.read`s the notifier without watching it — disposal
  /// would make the post-await `ref.read` throw "Ref ... already disposed".
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'53a471ac873ca5d7028d119b4b81eaa8bbb76915';

/// Auth Controller
///
/// keepAlive so long-running async methods (deleteAccount, signOut) that
/// `ref.read` services across `await` points aren't disposed mid-flight when
/// the only caller `ref.read`s the notifier without watching it — disposal
/// would make the post-await `ref.read` throw "Ref ... already disposed".

abstract class _$AuthController extends $AsyncNotifier<void> {
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
