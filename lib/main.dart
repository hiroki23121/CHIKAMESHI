import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'api_key.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SearchPage(),
    );
  }
}

// ================= 検索画面 =================

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String locationText = "現在地取得中...";
  String selectedRange = "3";
  String selectedGenre = "";
  String selectedBudget = "";

  double? lat;
  double? lng;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    try {
      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          locationText = "位置情報がOFFです";
        });
        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationText = "位置情報が拒否されています";
        });
        return;
      }

      Position position =
      await Geolocator.getCurrentPosition();

      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        locationText = "現在地取得済み";
      });
    } catch (e) {
      setState(() {
        locationText = "取得失敗";
      });
    }
  }

  void goSearch() {
    double useLat = lat ?? 34.67;
    double useLng = lng ?? 135.52;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          lat: useLat,
          lng: useLng,
          range: selectedRange,
          genre: selectedGenre,
          budget: selectedBudget,
        ),
      ),
    );
  }

  // ================= ジャンルアイコン（変更済み） =================
  Widget genreIconButton({
    required String label,
    required String imagePath,
    required String genreCode,
  }) {
    final isSelected = selectedGenre == genreCode;
    final isAll = genreCode == "";

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGenre = genreCode;
        });
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                  color: Colors.orange,
                  width: 4,
                )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              // ===================== 修正ポイント =====================
              child: ClipOval(
                child: Transform.scale(
                  // ★ここで「先に強く拡大」
                  scale: isAll ? 1.8 : 1.5,
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover, // ← 重要（引き伸ばし）
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
              ),
              // =======================================================
            ),

            const SizedBox(height: 8),

            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E09B),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4E09B),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ちかめし",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "近くのおいしいを、すぐに",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.orange),
                const SizedBox(width: 10),
                Text(locationText),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text("距離",
              style: TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: ["1", "2", "3", "4", "5"].map((v) {
              final labels = {
                "1": "300m",
                "2": "500m",
                "3": "1000m",
                "4": "2000m",
                "5": "3000m",
              };

              return ChoiceChip(
                label: Text(labels[v]!),
                selected: selectedRange == v,
                selectedColor: const Color(0xFFFFCC80),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) {
                  setState(() {
                    selectedRange = v;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          const Text("ジャンル",
              style: TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                genreIconButton(
                  label: "指定なし",
                  imagePath: "assets/icons/all.png",
                  genreCode: "",
                ),
                genreIconButton(
                  label: "居酒屋",
                  imagePath: "assets/icons/izakaya.png",
                  genreCode: "G001",
                ),
                genreIconButton(
                  label: "和食",
                  imagePath: "assets/icons/washoku.png",
                  genreCode: "G004",
                ),
                genreIconButton(
                  label: "洋食",
                  imagePath: "assets/icons/yoshoku.png",
                  genreCode: "G005",
                ),
                genreIconButton(
                  label: "カフェ",
                  imagePath: "assets/icons/cafe.png",
                  genreCode: "G014",
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text("予算",
              style: TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {"": "指定なし"},
              {"B009": "〜1000円"},
              {"B010": "〜2000円"},
              {"B011": "〜3000円"},
            ].map((map) {
              final key = map.keys.first;
              final label = map.values.first;

              return ChoiceChip(
                label: Text(label),
                selected: selectedBudget == key,
                selectedColor: const Color(0xFFFFCC80),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) {
                  setState(() {
                    selectedBudget = key;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 34),

          SizedBox(
            height: 58,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: goSearch,
              child: const Text(
                "お店を探す",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= 検索結果 =================

class ResultPage extends StatefulWidget {
  final double lat;
  final double lng;
  final String range;
  final String genre;
  final String budget;

  const ResultPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.range,
    required this.genre,
    required this.budget,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  List shops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  Future<void> fetchShops() async {
    final url =
        "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/"
        "?key=$API_KEY"
        "&lat=${widget.lat}"
        "&lng=${widget.lng}"
        "&range=${widget.range}"
        "&genre=${widget.genre}"
        "&budget=${widget.budget}"
        "&format=json";

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    setState(() {
      shops = data["results"]?["shop"] ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E09B),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4E09B),
        elevation: 0,
        centerTitle: true,
        title: const Text("検索結果",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shops.length,
        itemBuilder: (context, i) {
          final shop = shops[i];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(shop: shop),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Image.network(
                      shop["photo"]?["pc"]?["l"] ?? "",
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop["name"] ?? "No Name",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 18, color: Colors.orange),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop["mobile_access"] ?? "",
                                style: const TextStyle(
                                    color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= 詳細画面 =================

class DetailPage extends StatelessWidget {
  final dynamic shop;

  const DetailPage({super.key, required this.shop});

  Future<void> openMap(String address) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    }
  }

  Future<void> call(String tel) async {
    final uri = Uri.parse("tel:$tel");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> openWeb(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tel = shop["tel"];
    final url = shop["urls"]?["pc"];
    final image = shop["photo"]?["pc"]?["l"];

    return Scaffold(
      backgroundColor: const Color(0xFFD4E09B),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  image ?? "",
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 320,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  top: 45,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Text(
                    shop["name"] ?? "No Name",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Container(
              margin: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("店舗情報",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          shop["address"] ?? "不明",
                          style: const TextStyle(
                            height: 1.6,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () =>
                        openMap(shop["address"] ?? ""),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, color: Colors.orange),
                          SizedBox(width: 8),
                          Text("地図で見る",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  tel != null && tel != ""
                      ? GestureDetector(
                    onTap: () => call(tel),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone,
                              color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : GestureDetector(
                    onTap: () =>
                        openWeb(url ?? ""),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.language,
                              color: Colors.orange),
                          SizedBox(width: 10),
                          Text("公式サイトを見る",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight:
                                FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}