// lib/features/home/presentation/widgets/security_status_card.dart
import 'package:flutter/material.dart';

class SecurityStatusCard extends StatelessWidget {
  final int totalItems;

  const SecurityStatusCard({super.key, required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2E), Color(0xFF2D2D44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_user_rounded,
                  color: Colors.green, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Files Secured',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$totalItems items • 256-bit encryption',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}