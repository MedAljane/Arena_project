import 'package:Arena/Screens/shared/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const List<_PageData> _pages = [
    _PageData(
      image: 'assets/american football.jpg',
      title: 'Find your squad',
      description: 'Connect with local players and never\nplay a short-handed game again',
    ),
    _PageData(
      image: 'assets/Basketall.jpg',
      title: 'Book in seconds',
      description: 'Instant access to the best courts in the city.\nNo phone calls required.',
    ),
    _PageData(
      image: 'assets/Padel court.jpg',
      title: "Let's get playing",
      description: 'Your next match is just a few taps away.\nWelcome to Arena.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (_, index) => Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_pages[index].image, fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.5, 0.75],
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              decoration: BoxDecoration(
                color: const Color(0xA1D9D9D9),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _pages[_currentPage].title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _pages[_currentPage].description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.21,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: const WormEffect(
                      activeDotColor: Color(0xFF0F172A),
                      dotColor: Color(0xFF5073C7),
                      dotHeight: 7,
                      dotWidth: 24,
                      paintStyle: PaintingStyle.fill,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _currentPage == 2 ? _letsGoButton() : _navRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _controller.jumpToPage(2),
          child: Container(
            width: 75,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(100),
            ),
            alignment: Alignment.center,
            child: Text(
              'Skip',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _controller.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
          ),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(100),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _letsGoButton() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        child: Container(
          width: 220,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Text(
            "Let's Go",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageData {
  final String image;
  final String title;
  final String description;
  const _PageData({required this.image, required this.title, required this.description});
}
