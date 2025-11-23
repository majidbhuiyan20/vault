// lib/features/security/presentation/pin_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/security_provider.dart';
import '../../home/presentation/home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isPinVisible = false;
  bool _isConfirmPinVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    if (_pinController.text.isEmpty || _confirmPinController.text.isEmpty) {
      _showError('Please enter both PIN fields');
      return;
    }

    if (_pinController.text.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      _showError('PINs do not match');
      return;
    }

    setState(() => _isLoading = true);

    final securityProvider = Provider.of<SecurityProvider>(
      context,
      listen: false,
    );

    final success = await securityProvider.setPin(
      _pinController.text,
      _confirmPinController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    } else {
      _showError('Failed to set PIN');
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
              SizedBox(height: 40),

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
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 32),

              // Title
              Text(
                'Set Up Your PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12),

              // Subtitle
              Text(
                'Create a 4-digit PIN to secure your vault',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48),

              // PIN Input
              _buildPinInput(
                controller: _pinController,
                label: 'Enter PIN',
                isVisible: _isPinVisible,
                onVisibilityToggle: () {
                  setState(() => _isPinVisible = !_isPinVisible);
                },
              ),

              SizedBox(height: 20),

              // Confirm PIN Input
              _buildPinInput(
                controller: _confirmPinController,
                label: 'Confirm PIN',
                isVisible: _isConfirmPinVisible,
                onVisibilityToggle: () {
                  setState(() => _isConfirmPinVisible = !_isConfirmPinVisible);
                },
              ),

              SizedBox(height: 40),

              // Setup Button
              ElevatedButton(
                onPressed: _isLoading ? null : _setupPin,
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
                        'Set PIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              SizedBox(height: 24),

              // Security Info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blue,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your PIN is encrypted and stored securely',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
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

  Widget _buildPinInput({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: !isVisible,
          style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF4361EE), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: onVisibilityToggle,
            ),
          ),
        ),
      ],
    );
  }
}
