import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = "Please fill in all fields");
      return;
    }
    if (password.length < 6) {
      setState(() => _error = "Password must be at least 6 characters");
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final error = await auth.register(name, email, password);

    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final data = context.read<DataProvider>();
    data.setToken(auth.token);
    await data.loadAll();

    // go back to login, the root will already be showing the home screen
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Join StudyMate",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 4),
              const Text(
                "Organize your subjects, assignments and deadlines in one place.",
                style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 22),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13.5),
                  ),
                ),
              ],

              const Text("Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: "Admin", prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 14),

              const Text("Email", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: "you@example.com", prefixIcon: Icon(Icons.mail_outline)),
              ),
              const SizedBox(height: 14),

              const Text("Password", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: "min 6 characters",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: const InputDecoration(hintText: "Repeat password", prefixIcon: Icon(Icons.lock_outline)),
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 26),

              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: auth.loading ? null : _register,
                  child: auth.loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text("Register", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?", style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280))),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Login"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
