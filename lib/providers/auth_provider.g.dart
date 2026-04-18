// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authNotifierHash() => r'fc7da88d21493855ccbe3ae99a394c95a66b26e1';

/// 监听认证状态，驱动 GoRouter redirect 重新计算。
/// keepAlive=true 保持全生命周期存活。
///
/// Copied from [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider = NotifierProvider<AuthNotifier, bool>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthNotifier = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
