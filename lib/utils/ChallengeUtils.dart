import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ecdsa/ecdsa.dart';
import 'package:elliptic/elliptic.dart';

List<int> singChallenge(List<int> challenge, String privKey) {
  try {
    Curve ec = getSecp256k1();
    List<int> private_key = base64.decode(privKey).toList();
    PrivateKey key = PrivateKey.fromBytes(ec, private_key);
    List<int> challengebytes = sha256.convert(challenge).bytes;
    Signature sig = signature(key, challengebytes);
    List<int> res = challenge;
    res.addAll(sig.toDER());
    return res;
  } catch (e) {
    throw ChallengeSignException(e: e);
  }
}

class ChallengeSignException implements Exception {
  final Object e;
  ChallengeSignException({required this.e});
}
