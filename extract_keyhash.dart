import 'dart:io';
import 'dart:convert';

void main() async {
  try {
    print('Starting extraction...');

    // Command for Release Key
    var releaseResult = await Process.run('keytool', [
      '-exportcert',
      '-alias',
      'upload',
      '-keystore',
      'android/app/upload-keystore.jks',
      '-storepass',
      'ucp123456',
    ]);

    if (releaseResult.exitCode == 0) {
      var sha1 = await Process.start('openssl', ['sha1', '-binary']);
      sha1.stdin.add(releaseResult.stdout as List<int>);
      await sha1.stdin.close();

      var sha1Output = await sha1.stdout.toList();
      var flatSha1 = sha1Output.expand((x) => x).toList();

      // Manual base64 if openssl base64 fails
      var keyHash = base64Encode(flatSha1);
      print('Release Key Hash: $keyHash');
    } else {
      print('Error running keytool for release: ${releaseResult.stderr}');
    }

    // Try Debug Key
    var userProfile = Platform.environment['USERPROFILE'];
    var debugKeystorePath = '$userProfile\\.android\\debug.keystore';
    print('Checking debug keystore at: $debugKeystorePath');

    var debugResult = await Process.run('keytool', [
      '-exportcert',
      '-alias',
      'androiddebugkey',
      '-keystore',
      debugKeystorePath,
      '-storepass',
      'android',
    ]);

    if (debugResult.exitCode == 0) {
      var sha1 = await Process.start('openssl', ['sha1', '-binary']);
      sha1.stdin.add(debugResult.stdout as List<int>);
      await sha1.stdin.close();

      var sha1Output = await sha1.stdout.toList();
      var flatSha1 = sha1Output.expand((x) => x).toList();
      var keyHash = base64Encode(flatSha1);
      print('Debug Key Hash: $keyHash');
    } else {
      print('Error running keytool for debug: ${debugResult.stderr}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
