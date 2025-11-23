// lib/features/security/presentation/pin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/security_provider.dart';
import '../../home/presentation/home_screen.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinVisible = false;
  bool _isLoading = false;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.isEmpty) {
      _showError('Please enter your PIN');
      return;
    }

    if (_pinController.text.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    setState(() => _isLoading = true);

    final securityProvider = Provider.of<SecurityProvider>(
      context,
      listen: false,
    );

    final success = await securityProvider.verifyPin(_pinController.text);

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    } else {
      setState(() {
        _failedAttempts++;
        _pinController.clear();
      });
      _showError('Incorrect PIN. Attempt $_failedAttempts');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),

              // Lock Icon
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_rounded, size: 60, color: Colors.white),
              ),

              SizedBox(height: 32),

              // Title
              Text(
                'Secure Vault',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12),

              // Subtitle
              Text(
                'Enter your PIN to unlock',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48),

              // PIN Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: !_isPinVisible,
                    autofocus: true,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 12,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF4361EE),
                          width: 2,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPinVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() => _isPinVisible = !_isPinVisible);
                        },
                      ),
                    ),
                    onSubmitted: (_) => _verifyPin(),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Unlock Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4361EE),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Unlock',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              SizedBox(height: 24),

              // Failed Attempts Warning
              if (_failedAttempts > 0)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.red, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Failed attempts: $_failedAttempts',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
