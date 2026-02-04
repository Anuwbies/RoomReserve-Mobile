import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

import 'Booked_Page.dart';
import 'Home_Page.dart';
import 'Profile_Page.dart';
import 'Rooms_Page.dart';
import '../l10n/app_localizations.dart';
import '../services/fcm_service.dart';

class NavigationBarPage extends StatefulWidget {
  const NavigationBarPage({super.key});

  @override
  State<NavigationBarPage> createState() => _NavigationBarPageState();
}

class _NavigationBarPageState extends State<NavigationBarPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    FCMService.initialize();
  }

  final List<Widget> _pages = const [
    HomePage(),
    BookedPage(),
    RoomsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SizedBox(height: 62,
        child: StylishBottomBar(
          option: BubbleBarOptions(
            barStyle: BubbleBarStyle.horizontal, // keeps width stable
            bubbleFillStyle: BubbleFillStyle.fill,
            opacity: 0.15, // controls background intensity
          ),
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomBarItem(
              icon: SvgPicture.asset(
                'lib/assets/images/home.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              selectedIcon: SvgPicture.asset(
                'lib/assets/images/home.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.blue,
                  BlendMode.srcIn,
                ),
              ),
              title: Text(l10n.get('home')),
              selectedColor: Colors.blue,
              unSelectedColor: Colors.grey,
              backgroundColor: Colors.blue,
            ),

            BottomBarItem(
              icon: SvgPicture.asset(
                'lib/assets/images/booked.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              selectedIcon: SvgPicture.asset(
                'lib/assets/images/booked.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.blue,
                  BlendMode.srcIn,
                ),
              ),
              title: Text(l10n.get('booked')),
              selectedColor: Colors.blue,
              unSelectedColor: Colors.grey,
              backgroundColor: Colors.blue,
            ),

            BottomBarItem(
              icon: SvgPicture.asset(
                'lib/assets/images/rooms.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              selectedIcon: SvgPicture.asset(
                'lib/assets/images/rooms.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.blue,
                  BlendMode.srcIn,
                ),
              ),
              title: Text(l10n.get('rooms')),
              selectedColor: Colors.blue,
              unSelectedColor: Colors.grey,
              backgroundColor: Colors.blue,
            ),

            BottomBarItem(
              icon: SvgPicture.asset(
                'lib/assets/images/profile.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              selectedIcon: SvgPicture.asset(
                'lib/assets/images/profile.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.blue,
                  BlendMode.srcIn,
                ),
              ),
              title: Text(l10n.get('profile')),
              selectedColor: Colors.blue,
              unSelectedColor: Colors.grey,
              backgroundColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}