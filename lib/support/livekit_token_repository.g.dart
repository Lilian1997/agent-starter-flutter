// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livekit_token_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(liveKitTokenRepository)
final liveKitTokenRepositoryProvider = LiveKitTokenRepositoryProvider._();

final class LiveKitTokenRepositoryProvider extends $FunctionalProvider<
    LiveKitTokenRepository,
    LiveKitTokenRepository,
    LiveKitTokenRepository> with $Provider<LiveKitTokenRepository> {
  LiveKitTokenRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'liveKitTokenRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$liveKitTokenRepositoryHash();

  @$internal
  @override
  $ProviderElement<LiveKitTokenRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LiveKitTokenRepository create(Ref ref) {
    return liveKitTokenRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveKitTokenRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveKitTokenRepository>(value),
    );
  }
}

String _$liveKitTokenRepositoryHash() =>
    r'2616a9f0fe64d7dabc51392cd12b1ee7f51fafe9';
