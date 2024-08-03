
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock AUthenticatioin', () {
    final provider = MockAuthProvider();
    test('Should not be initialized to begin with', () {
      expect(provider.isInitialized, isFalse);
    });

    test('Cannot log out if not initialized', () {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedAuthException>()),
      );
    });

    test('Should be able to initialize', () async {
      await provider.initialize();
      expect(provider.isInitialized, isTrue);
    });

    test('User should be null after initialization', () {
      expect(provider.currentUser, isNull);
    });

    test(
      'Should be able to initialize in less than 2 seconds',
      () async {
        //final stopwatch = Stopwatch()..start();
        await provider.initialize();
        expect(provider.isInitialized, isTrue);
        //expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      },
      timeout: const Timeout(
        Duration(seconds: 2),
      ),
    );
    // is timer better than stopwatch?
    // Stopwatch is better for measuring elapsed time in Dart because it is more accurate than Timer.
    test('Create user should delegate to login function', () async {
      final badEmailUser = provider.createUser(
        email: 'foo@bar.com',
        password: 'anypassword',
      );
      expect(badEmailUser,
          throwsA(const TypeMatcher<UserNotFoundAuthException>()));
      final basPasswordUser = provider.createUser(
        email: 'someone@wow.com',
        password: 'foobar',
      );
      expect(basPasswordUser,
          throwsA(const TypeMatcher<WrongPasswordAuthException>()));

      final user = await provider.createUser(email: 'foo', password: 'bar');
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, isFalse);
    });

    test('Login user should be able to get verified', () async {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, isTrue);
    });

    test('Should be able to log out and login in again', () async {
      await provider.logOut();
      await provider.logIn(
        email: 'foo',
        password: 'bar',
      );
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedAuthException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedAuthException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  // TODO: implement currentUser
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NotInitializedAuthException();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw WrongPasswordAuthException();
    var user = AuthUser(isEmailVerified: false, email: email);
    _user = user;
    return Future.value(user);
    // what is the difference between Future.value and Future.delayed?
    // Future.value returns a Future that completes with the given value.
    // Future.delayed returns a Future that completes after the given duration with the given value.
    // why do we need to return a Future?
    // The return type of the method is Future<AuthUser>, so we need to return a Future that completes with the AuthUser object.
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedAuthException();
    if (_user == null) throw UserNotLoggedInAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedAuthException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    var newUser = AuthUser(isEmailVerified: true, email: user.email);
    _user = newUser;
  }
}
