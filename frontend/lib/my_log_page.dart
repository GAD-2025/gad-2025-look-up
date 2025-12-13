import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyLogPage extends StatefulWidget {
  const MyLogPage({super.key});

  @override
  State<MyLogPage> createState() => _MyLogPageState();
}

class _MyLogPageState extends State<MyLogPage> {
  int _selectedTab = 0; // 0 = grid, 1 = map

  late GoogleMapController _mapController;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 15,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // ============= SLEEP ICON ==============
        Image.asset("assets/icons/sleep_icon.png", width: 90, height: 90),

        const SizedBox(height: 4),

        // ============= 닉네임 =============
        const Text(
          "루거비 님",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 4),

        // ============= 아이디 =============
        const Text(
          "@lookup_user",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),

        const SizedBox(height: 30),

        // =========== GRID / MAP TAB ============
        _buildTabBar(),

        const SizedBox(height: 16),

        // =========== CONTENT ============
        Expanded(
          child: _selectedTab == 0 ? _buildGridScrollView() : _buildMapView(),
        ),
      ],
    );
  }

  // ================= TAB BAR =================
  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tabItem(icon: Icons.grid_view_rounded, index: 0),
        const SizedBox(width: 60),
        _tabItem(icon: Icons.map_outlined, index: 1),
      ],
    );
  }

  Widget _tabItem({required IconData icon, required int index}) {
    final selected = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Icon(icon, size: 26, color: selected ? Colors.black : Colors.grey),
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 40,
              height: 2,
              color: Colors.black,
            ),
        ],
      ),
    );
  }

  // ============ GRID (스크롤 O) ============
  Widget _buildGridScrollView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: const [
          SizedBox(height: 50),
          Text(
            "아직 게시물을 올리지 않으셨군요",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "피드에 참여하여 내가 찍은 풍경을 자랑해볼까요?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 120),
        ],
      ),
    );
  }

  // ============== MAP (스크롤 X, 제스처 O) ==============
  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
    );
  }
}
