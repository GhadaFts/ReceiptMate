import 'package:flutter/material.dart';
import 'dart:async';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // Animation controller for fade in/out
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Start fade in animation
    _fadeController.forward();

    // Auto navigate after 5 seconds
    Timer(const Duration(seconds: 5), () {
      _navigateToHome();
    });
  }

  Future<void> _navigateToHome() async {
    if (_isExiting) return;

    setState(() {
      _isExiting = true;
    });

    // Fade out animation
    await _fadeController.reverse();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _navigateToHome,
        child: Stack(
          children: [
            // Top left BEANS decoration
            Positioned(
              top: 0,
              left: 70,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/beans 2.png',
                  width: 120,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CustomPaint(
                      size: const Size(120, 60),
                      painter: GrapesPainter(),
                    );
                  },
                ),
              ),
            ),

            // Top left salad
            Positioned(
              top: 0,
              left: -50,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/keto-salad-with-roasted-eggplant-kale 1.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 220,
                      height: 220,
                      color: Colors.green.shade100,
                      child: Icon(
                        Icons.restaurant,
                        size: 70,
                        color: Colors.green.shade300,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Top right salad
            Positioned(
              top: 0,
              right: -50,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/salad3 3.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 220,
                      height: 220,
                      color: Colors.orange.shade100,
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 70,
                        color: Colors.orange.shade300,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Center content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 45,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Receipe',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              color: Colors.green.shade400,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const TextSpan(
                            text: 'Mate',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const TextSpan(
                            text: ' 👨‍🍳',
                            style: TextStyle(
                              fontSize: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Welcome to Receipe Mate',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom left avocado
            Positioned(
              bottom: -10,
              left: -50,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/avocado 2.png',
                  width: 150,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 200,
                      color: Colors.green.shade100,
                      child: Icon(
                        Icons.eco,
                        size: 50,
                        color: Colors.green.shade300,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom right vegetables stack
            Positioned(
              bottom: 0,
              right: -30,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/Group 1.png',
                  width: 150,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 200,
                      color: Colors.orange.shade100,
                      child: Icon(
                        Icons.set_meal,
                        size: 50,
                        color: Colors.orange.shade300,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Loading indicator
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SizedBox(
                    width: 35,
                    height: 35,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.orange.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for grapes decoration (fallback)
class GrapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.fill;

    // Draw grapes as circles
    final positions = [
      const Offset(20, 10),
      const Offset(40, 10),
      const Offset(60, 10),
      const Offset(30, 25),
      const Offset(50, 25),
      const Offset(40, 40),
    ];

    for (var pos in positions) {
      canvas.drawCircle(pos, 12, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for peas decoration (fallback)
class PeasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.fill;

    // Draw peas as circles
    final positions = [
      const Offset(15, 20),
      const Offset(35, 20),
      const Offset(55, 20),
    ];

    for (var pos in positions) {
      canvas.drawCircle(pos, 10, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}