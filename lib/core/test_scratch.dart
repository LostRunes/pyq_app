import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const options = AuthClientOptions(
    pkceAsyncStorage: null,
  );
  print(options.pkceAsyncStorage);
}
