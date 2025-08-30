import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutWIAScreen extends StatefulWidget {
  const AboutWIAScreen({super.key});

  @override
  _AboutWIAScreenState createState() => _AboutWIAScreenState();
}

class _AboutWIAScreenState extends State<AboutWIAScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (!await launchUrl(emailUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email app'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Widget _buildSocialMediaCard(String title, String url, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _launchURL(url),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  color: color.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _launchEmail('wia@windsormosque.com'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.email,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email WIA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'wia@windsormosque.com',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.mail_outline,
                  color: Colors.red.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[300]
              : Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildHistorySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green[400]
                : Colors.green[600],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green[700]
            : Colors.green[600],
        elevation: 4,
        title: const Text(
          'About WIA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          // Detect swipe from left edge - made more sensitive
          if (details.delta.dx > 8 && details.globalPosition.dx < 80) {
            Navigator.pop(context);
          }
        },
        onPanEnd: (details) {
          // Alternative: detect completed swipe gesture
          if (details.velocity.pixelsPerSecond.dx > 500 && details.localPosition.dx < 100) {
            Navigator.pop(context);
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            // About Tab
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // WIA Info Section
                  _buildSectionHeader('Windsor Islamic Association'),
                  _buildSocialMediaCard(
                    'Visit Our Website',
                    'https://windsorislamicassociation.com/',
                    Icons.language,
                    Colors.green,
                  ),
                  _buildSocialMediaCard(
                    'Find Us on Google Maps',
                    'https://maps.app.goo.gl/SpZ3uFctsnBKM7sU7?g_st=ipc',
                    Icons.location_on,
                    Colors.blue,
                  ),
                  _buildEmailCard(),

                  // Social Media Section
                  _buildSectionHeader('Follow Us'),
                  _buildSocialMediaCard(
                    'Facebook',
                    'https://www.facebook.com/windsormosque/',
                    Icons.facebook,
                    const Color(0xFF1877F2),
                  ),
                  _buildSocialMediaCard(
                    'Instagram',
                    'https://www.instagram.com/windsormosque/',
                    Icons.camera_alt,
                    const Color(0xFFE4405F),
                  ),
                  _buildSocialMediaCard(
                    'YouTube Channel',
                    'https://m.youtube.com/user/windsormosque',
                    Icons.play_circle_outline,
                    const Color(0xFFFF0000),
                  ),

                  // Educational Institutions Section
                  _buildSectionHeader('Educational Institutions'),
                  _buildSocialMediaCard(
                    'An-Noor School',
                    'https://annoorschool.ca/',
                    Icons.school,
                    Colors.orange,
                  ),
                  _buildSocialMediaCard(
                    'Al-Hijra Academy',
                    'http://alhijraacademy.com/',
                    Icons.library_books,
                    Colors.purple,
                  ),
                  _buildSocialMediaCard(
                    'Windsor Islamic High School',
                    'https://wihs.ca/',
                    Icons.account_balance,
                    Colors.teal,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
            
            // History Tab
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our History',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[300]
                            : Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildHistorySection(
                      'Brief History of Windsor Ontario',
                      'We are grateful to be practising Islam on land that is the traditional territory of the Anishnaabeg people of the Three Fires Confederacy (Ojibwe, Potawatomi, and Odawa).\n\n'
                      'First incorporated as a city in 1892, Windsor\'s population grew from 21,000 in 1908 to 105,000 in 1928. This rise was almost entirely due to employment offered in the automobile industry.\n\n'
                      'This was capped by the opening of the Ambassador Bridge (1929), the world\'s longest international suspension bridge, and the Detroit-Windsor Auto Tunnel (1930), the only international vehicular tunnel in the world.\n\n'
                      'In 1965, following the signing of the Canada-US Auto Pact, employment was high and immigration increased. The city began to take shape and developed into how we see it today.',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    _buildHistorySection(
                      'The First Mosque in Windsor',
                      'Muslims began immigrating to Essex county in the early 20th century. In 1950, the Windsor Muslim community consisted of 20 families.\n\n'
                      'In 1956, the community officially started the Windsor Islamic Youth Association, Windsor\'s first mosque. By 1960, the name was updated to Windsor Islamic Association. This was a space for Muslims to pray, socialize, and grow.',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    _buildHistorySection(
                      'The blessings of Allah SWT',
                      'By 1963, our community outnumbered 3,000 Muslims from 19 different countries. As we experienced this rapid growth, we began to lack enough space to accommodate everyone. Our team began to look for long-term solutions.\n\n'
                      'In 1969 we first broke ground on 1320 Northwood Street, where we are still located today.',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    _buildHistorySection(
                      'Current Build',
                      'Over the next few decades, our community continued to grow and so did the need for a larger space.\n\n'
                      'In 1991, we began construction on the Windsor Mosque and worked towards the building that we see on the corner of Dominion and Northwood today.\n\n'
                      'In 1993, we completed construction of the Windsor Mosque\n\n'
                      '***Thank you to all the amazing and wonderful people that helped bring this dream to reality. Your contributions are gracious examples for all. ***',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    _buildHistorySection(
                      'Senior Residences',
                      'In the spring of 2023, we began construction of five residential buildings across the street from the mosque, with six apartments in each building and 36 parking spaces total.\n\n'
                      'These 30 spacious apartments are 1250-1300 sq ft with large windows facing the mosque, two bedrooms and two bathrooms each. The residential apartments will have elevators to allow seniors easy access to the mosque and wider community inshaAllah.',
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}