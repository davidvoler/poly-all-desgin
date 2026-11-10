import 'package:editor/features/auth/data/auth.dart';

const testUser = EditorUser(
  userId: 5,
  schoolId: 1,
  schoolName: 'local',
  email: 'demo@local.dev',
);

/// Starts in [initial] instead of asking the server for a session, and signs
/// in [testUser] with the password `changeme`.
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier([this.initial = const AuthSignedIn(testUser)]);

  final AuthState initial;
  int signOuts = 0;

  @override
  AuthState build() => initial;

  @override
  Future<void> signIn({required String email, required String password}) async {
    state = email == testUser.email && password == 'changeme'
        ? const AuthSignedIn(testUser)
        : const AuthSignedOut('Invalid email or password');
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    state = const AuthSignedOut();
  }
}
