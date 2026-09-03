import 'package:flutter/material.dart';
import 'create_company_screen.dart';
import 'company_list_screen.dart';

class SuperAdminHomeScreen extends StatelessWidget {
  const SuperAdminHomeScreen({super.key});

  // FLEXTIME COLORS
  static const Color primary = Color(0xFF2864E8);
  static const Color primaryDark = Color(0xFF294477);

  static const Color background = Color(0xFFF1F5FF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF294477);
  static const Color textSecondary = Color(0xFF687895);

  static const Color border = Color(0xFFC9D9FF);
  static const Color softBlue = Color(0xFFEAF0FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 42),
              _buildWelcome(),

              const SizedBox(height: 32),

              _buildSystemCard(),

              const SizedBox(height: 34),
              _buildSectionTitle(),

              const SizedBox(height: 16),

              // ACTION CARDS
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.add_business_rounded,
                      title: 'Tạo công ty mới',
                      iconColor: const Color(0xFF22B891),
                      iconBackground: const Color(0xFFE6F8F2),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateCompanyScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.business_rounded,
                      title: 'Quản lý công ty',
                      iconColor: primary,
                      iconBackground: softBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CompanyListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Decorative bottom area
              _buildBottomDecoration(),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Row(
      children: [
        // Logo
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.20),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 29),
        ),

        const SizedBox(width: 14),

        // Brand
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FlexTime',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: primaryDark,
                letterSpacing: -0.5,
              ),
            ),

            SizedBox(height: 3),

            Text(
              'Quản trị hệ thống',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // WELCOME

  Widget _buildWelcome() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xin chào 👋',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),

        SizedBox(height: 6),

        Text(
          'SuperAdmin',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  // SYSTEM CARD

  Widget _buildSystemCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2864E8), Color(0xFF3976F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Company icon
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.domain_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 18),

          // Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HỆ THỐNG DOANH NGHIỆP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),

                SizedBox(height: 7),

                Text(
                  'Quản lý tập trung',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                SizedBox(height: 9),

                // Small decorative line
                SizedBox(
                  width: 45,
                  child: Divider(color: Colors.white54, thickness: 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION TITLE

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        const SizedBox(width: 12),

        const Text(
          'QUẢN LÝ HỆ THỐNG',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  // ACTION CARD

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 190,
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border.withOpacity(0.65), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, color: iconColor, size: 42),
                ),

                const SizedBox(height: 18),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BOTTOM DECORATION

  Widget _buildBottomDecoration() {
    return SizedBox(
      height: 55,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 8,
            child: Row(
              children: List.generate(
                6,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: -20,
            bottom: -35,
            child: Container(
              width: 180,
              height: 80,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.035),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
