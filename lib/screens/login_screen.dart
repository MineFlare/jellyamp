import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/jellyfin_api.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverCtrl = TextEditingController(text: 'http://');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _discovering = false;
  String? _error;
  bool _obscurePass = true;
  List<DiscoveredServer> _discovered = [];

  @override
  void initState() {
    super.initState();
    _discover();
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _discover() async {
    setState(() => _discovering = true);
    final servers = await JellyfinApi.discoverServers();
    if (mounted) setState(() { _discovered = servers; _discovering = false; });
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().login(
            _serverCtrl.text.trim(),
            _userCtrl.text.trim(),
            _passCtrl.text,
          );
      if (mounted) {
        context.read<LibraryProvider>().loadLibrary(context.read<AuthProvider>().api!);
      }
    } catch (e) {
      setState(() => _error = 'Login failed. Check your server URL and credentials.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.music_note_rounded, color: AppTheme.accent, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    'JellyAmp',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text('Connect to your Jellyfin server',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  _buildDiscoverySection(),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _serverCtrl,
                    style: const TextStyle(color: AppTheme.onBackground),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Server URL  e.g. http://192.168.1.x:8096',
                      prefixIcon: Icon(Icons.dns_rounded, color: AppTheme.subtle),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _userCtrl,
                    style: const TextStyle(color: AppTheme.onBackground),
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Username',
                      prefixIcon: Icon(Icons.person_rounded, color: AppTheme.subtle),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    style: const TextStyle(color: AppTheme.onBackground),
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.subtle),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: AppTheme.subtle,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _loading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                      : ElevatedButton(onPressed: _login, child: const Text('Connect')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverySection() {
    if (_discovering) {
      return Row(
        children: const [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.subtle),
          ),
          SizedBox(width: 12),
          Text('Scanning for Jellyfin servers…', style: TextStyle(color: AppTheme.subtle, fontSize: 13)),
        ],
      );
    }

    if (_discovered.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.wifi_find_rounded, color: AppTheme.subtle, size: 16),
          const SizedBox(width: 8),
          const Text('No servers found on local network',
              style: TextStyle(color: AppTheme.subtle, fontSize: 13)),
          const Spacer(),
          TextButton(
            onPressed: _discover,
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Retry', style: TextStyle(fontSize: 13)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Icon(Icons.wifi_find_rounded, color: AppTheme.accent, size: 16),
          const SizedBox(width: 8),
          Text('${_discovered.length} server${_discovered.length == 1 ? '' : 's'} found nearby',
              style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton(
            onPressed: _discover,
            style: TextButton.styleFrom(foregroundColor: AppTheme.subtle,
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Rescan', style: TextStyle(fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 8),
        ..._discovered.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () => setState(() => _serverCtrl.text = s.address),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _serverCtrl.text == s.address
                      ? AppTheme.accent
                      : AppTheme.divider,
                ),
              ),
              child: Row(children: [
                const Icon(Icons.computer_rounded, color: AppTheme.accent, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name,
                        style: const TextStyle(color: AppTheme.onBackground,
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(s.address,
                        style: const TextStyle(color: AppTheme.subtle, fontSize: 12)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.subtle, size: 18),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 4),
        const Text('Or enter manually below',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 4),
      ],
    );
  }
}
