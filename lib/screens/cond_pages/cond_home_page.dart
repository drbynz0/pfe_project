import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:p_f_e_project/providers/locale_provider.dart';
import 'package:p_f_e_project/screens/cond_pages/messages_page.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '/screens/cond_pages/suivi_bus.dart';
import '/screens/cond_pages/settings.dart';
import '/generated/l10n.dart';
import '/screens/cond_pages/profile_page.dart';
import '/screens/cond_pages/notifications_page.dart';

class CondHomePage extends StatefulWidget {
  const CondHomePage({super.key});

  @override
  CondHomePageState createState() => CondHomePageState();
}

class CondHomePageState extends State<CondHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  List<BusRoute> plannedRoutes = [];
  String currentDay = '';
  bool isLoading = true;
  String currentUserId = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _initializePage();
    _pages = [
      HomeScreen(routes: plannedRoutes, isLoading: isLoading, fadeAnimation: _fadeAnimation),
      const MessagesPage(),
      SuiviBusPage(),
      SettingsPage(onLocaleChange: (locale) {
        Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);
      }),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _getCurrentUserId();
    await _loadTodayRoutes();
    _animationController.forward();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          setState(() {
            currentUserId = userSnapshot.docs.first.id;
          });
          SnackBar(
            content: Text('Utilisateur connecté: $currentUserId'),
            duration: const Duration(seconds: 2),
          );
        } else {
          debugPrint('Aucun utilisateur trouvé avec cet ID.');
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun utilisateur trouvé')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadTodayRoutes() async {
    if (mounted) setState(() => isLoading = true);

    final now = DateTime.now();
    final formatter = DateFormat('EEEE', 'fr_FR');
    currentDay = formatter.format(now).toLowerCase();

    if (currentUserId.isEmpty) return;

    try {
      final scheduleSnapshot = await FirebaseFirestore.instance
          .collection('Conducteurs')
          .doc(currentUserId)
          .collection('Bus')
          .doc('itineraires')
          .get();

      if (scheduleSnapshot.exists) {
        final scheduleData = scheduleSnapshot.data()!;
        if (mounted) {
          setState(() {
            plannedRoutes.clear();
            if (scheduleData.containsKey(currentDay)) {
              final dayData = scheduleData[currentDay] as Map<String, dynamic>;
              _processRouteData(dayData);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des itinéraires: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _processRouteData(Map<String, dynamic> dayData) {
    if (dayData['matin'] != null) {
      final morning = dayData['matin'] as Map<String, dynamic>;
      plannedRoutes.add(BusRoute(
        routeName: "Trajet du matin",
        startTime: _parseTime(morning['debut'] ?? '08:00'),
        endTime: _parseTime(morning['fin'] ?? '12:00'),
        stops: List<String>.from(morning['arret'] ?? []),
        status: "Planifié",
      ));
    }

    if (dayData['apres_midi'] != null) {
      final afternoon = dayData['apres_midi'] as Map<String, dynamic>;
      plannedRoutes.add(BusRoute(
        routeName: "Trajet de l'après-midi",
        startTime: _parseTime(afternoon['debut'] ?? '13:00'),
        endTime: _parseTime(afternoon['fin'] ?? '17:00'),
        stops: List<String>.from(afternoon['arret'] ?? []),
        status: "Planifié",
      ));
    }
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.replaceAll('h', ':').split(':');
    return DateTime(now.year, now.month, now.day, 
      int.parse(parts[0]), int.parse(parts.length > 1 ? parts[1] : '0'));
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {

        final String? condId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 35, 51),
      appBar: AppBar(
        title: const Text(
          'School App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 25, 40, 62),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _animationController.reset();
              _loadTodayRoutes().then((_) => _animationController.forward());
            },
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'profile') {
                // Rediriger vers la page de profil
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(teacherId: condId!),
                  ),
                );
              } else if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Text(S.of(context).profile), // Utilisez les traductions ici
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text(S.of(context).logout), // Utilisez les traductions ici
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus_outlined),
              activeIcon: Icon(Icons.directions_bus),
              label: 'Suivi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Réglages',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color.fromARGB(255, 19, 20, 40),
          unselectedItemColor: const Color.fromARGB(255, 87, 99, 108),
          selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<BusRoute> routes;
  final bool isLoading;
  final Animation<double> fadeAnimation;

  const HomeScreen({
    super.key,
    required this.routes,
    required this.isLoading,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return  FadeTransition(
                opacity: fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(),
                      const SizedBox(height: 20),
                      _buildTodayRoutesSection(),
                      const SizedBox(height: 20),
                      _buildHoursChartSection(),
                      const SizedBox(height: 20),
                      _buildRecentActivitiesSection(),
                    ],
                  ),
                ),
              );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final greeting = _getTimeGreeting(now.hour);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE d MMMM y', 'fr_FR').format(now),
          style: TextStyle(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _getTimeGreeting(int hour) {
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Widget _buildTodayRoutesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vos itinéraires aujourd\'hui',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...routes.map((route) => _buildRouteCard(route)),
      ],
    );
  }

  Widget _buildRouteCard(BusRoute route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color.fromARGB(255, 37, 40, 65),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    route.routeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(route.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      route.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.access_time, 
                '${DateFormat('HH:mm').format(route.startTime)} - ${DateFormat('HH:mm').format(route.endTime)}'),
              const SizedBox(height: 8),
              const Text(
                'Arrêts:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...route.stops.map((stop) => _buildStopItem(stop)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Commencer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStopItem(String stop) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, size: 8, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stop,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return Colors.orange;
      case 'terminé':
        return Colors.green;
      case 'annulé':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildHoursChartSection() {
    // Données simulées pour le graphique
    final List<ChartData> chartData = [
      ChartData('Ecole', 7),
      ChartData('Arrêt 1', 8),
      ChartData('Arrêt 2', 6),
      ChartData('Arrêt 3', 10),
      ChartData('Arrêt 4', 16),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Heures de conduite cette journée',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color.fromARGB(255, 30, 34, 74),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: SfCartesianChart(
                backgroundColor: Colors.transparent,
                primaryXAxis: CategoryAxis(
                  axisLine: const AxisLine(color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white),
                  majorGridLines: const MajorGridLines(color: Colors.transparent),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 6,
                  maximum: 18,
                  interval: 2,
                  axisLine: const AxisLine(color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white),
                  majorTickLines: const MajorTickLines(color: Colors.white70),
                  majorGridLines: const MajorGridLines(color: Colors.white12),
                ),
                series: <CartesianSeries<dynamic, dynamic>>[
                  SplineAreaSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.day,
                    yValueMapper: (ChartData data, _) => data.hours,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF536DFE), Color(0xFF304FFE)],
                      stops: [0.0, 0.6],
                    ),
                    borderColor: const Color(0xFF00C853),
                    borderWidth: 2,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      borderWidth: 2,
                      borderColor: Colors.white,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection() {
    // Activités simulées
    final activities = [
      {'type': 'Trajet', 'time': '08:30', 'description': 'Trajet du matin terminé'},
      {'type': 'Maintenance', 'time': '12:15', 'description': 'Vérification des pneus'},
      {'type': 'Pause', 'time': '12:30', 'description': 'Pause déjeuner'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activités récentes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color.fromARGB(255, 40, 46, 87),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: activities.map((activity) => _buildActivityItem(
                activity['type']!,
                activity['time']!,
                activity['description']!,
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String type, String time, String description) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'Trajet':
        icon = Icons.directions_bus;
        color = Colors.green;
        break;
      case 'Maintenance':
        icon = Icons.build;
        color = Colors.orange;
        break;
      case 'Pause':
        icon = Icons.free_breakfast;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.purple;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BusRoute {
  final String routeName;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> stops;
  final String status;

  BusRoute({
    required this.routeName,
    required this.startTime,
    required this.endTime,
    required this.stops,
    required this.status,
  });
}

class ChartData {
  final String day;
  final double hours;

  ChartData(this.day, this.hours);
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Theme(
        data: ThemeData.dark().copyWith(
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          cardColor: const Color.fromARGB(255, 47, 48, 81), dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 35, 43, 77)),
        ),
        child: AlertDialog(
          title: Text(S.of(context).logout, style: TextStyle(color: Colors.white)),
          content: const Text("Voulez-vous vraiment vous déconnecter ?", style: TextStyle(color: Colors.white),),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 35, 31, 65),
              ),
              onPressed: () async {
                AuthService.logout(context);
              },
              child: Text(S.of(context).logout),
            ),
          ],
        ),
      );   
    }
  );
}