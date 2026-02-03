import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomreserve/Pages/Reserve_Page.dart';
import 'package:roomreserve/Pages/Rooms_Page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roomreserve/l10n/app_localizations.dart';

void main() {
  testWidgets('ReservePage has title and inputs', (WidgetTester tester) async {
    // 1. Create a dummy Room
    final room = Room(
      id: 'test_room_1',
      name: 'Test Room',
      type: 'Meeting',
      building: 'Building A',
      floor: '1',
      isAvailable: true,
      tags: [],
      description: 'A test room',
      capacity: 10,
      bookingRules: {
        'minDurationMinutes': 30, 
        'maxDurationMinutes': 120,
        'advanceBookingDays': 30
      },
      availability: {},
    );

    // 2. Pump the widget with navigation structure
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReservePage(room: room)),
                  );
                },
                child: const Text('Go to Reserve'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Reserve Page
    await tester.tap(find.text('Go to Reserve'));
    await tester.pumpAndSettle();

    // 3. Verify elements
    // Verify room name first to ensure page rendered
    expect(find.text('Test Room'), findsOneWidget); 
    
    // AppBar title
    expect(find.textContaining('Reserve Room'), findsOneWidget); 
    
    // Check for updated labels
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('30mins'), findsOneWidget); // Default value formatted
    
    // Check that helper text is NOT present (as requested to be removed)
    expect(find.text('Booking allowed up to 30 days in advance'), findsNothing);
    
    // Verify max duration filtering (max is 120 in test room)
    await tester.tap(find.text('30mins'));
    await tester.pumpAndSettle();
    
    // 120 should be present (2hrs)
    expect(find.text('2hrs'), findsOneWidget);
    // 180 should NOT be present (3hrs)
    expect(find.text('3hrs'), findsNothing);
    
    // Close dropdown
    await tester.tap(find.text('2hrs')); // Select 2hrs
    await tester.pumpAndSettle();
    
    expect(find.text('Confirm Reservation'), findsOneWidget);

    // 4. Enter Purpose
    await tester.enterText(find.byType(TextFormField), 'Unit Test Meeting');
    await tester.pump();

    // 5. Tap Confirm
    final buttonFinder = find.text('Confirm Reservation');
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pump(); // Start animation
    await tester.pump(const Duration(seconds: 3)); // Finish animation (SnackBar)

    // 6. Verify SnackBar
    expect(find.text('Reservation Confirmed (Logged to Console)'), findsOneWidget);
  });

  testWidgets('ReservePage handles approval required', (WidgetTester tester) async {
    // 1. Create a dummy Room with approval required
    final room = Room(
      id: 'test_room_2',
      name: 'Approval Room',
      type: 'Hall',
      building: 'Building B',
      floor: '2',
      isAvailable: true,
      tags: [],
      description: 'Room requiring approval',
      capacity: 50,
      bookingRules: {
        'minDurationMinutes': 60,
        'maxDurationMinutes': 240,
        'requiresApproval': true
      },
      availability: {},
    );

    // 2. Pump the widget
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReservePage(room: room)),
                  );
                },
                child: const Text('Go to Reserve'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Reserve Page
    await tester.tap(find.text('Go to Reserve'));
    await tester.pumpAndSettle();

    expect(find.text('Approval Room'), findsOneWidget);

    // 3. Enter Purpose
    await tester.enterText(find.byType(TextFormField), 'Approval Test');
    await tester.pump();

    // 4. Tap Confirm
    final buttonFinder = find.text('Confirm Reservation');
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pump(); 
    await tester.pump(const Duration(seconds: 3));

    // 5. Verify SnackBar (execution successful)
    expect(find.text('Reservation Confirmed (Logged to Console)'), findsOneWidget);
  });
}
