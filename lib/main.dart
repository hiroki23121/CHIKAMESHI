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

// ================= 検索画面（変更なし） =================
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => locationText = "位置情報がOFFです");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => locationText = "位置情報が拒否されています");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        locationText = "現在地取得済み";
      });
    } catch (e) {
      setState(() => locationText = "取得失敗");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("ちかめし",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "近くのおいしいを、すぐに",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 10),
                Text(locationText),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text("距離"),
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
                onSelected: (_) => setState(() => selectedRange = v),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          const Text("ジャンル"),
          Wrap(
            spacing: 8,
            children: [
              {"": "指定なし"},
              {"G001": "居酒屋"},
              {"G004": "和食"},
              {"G005": "洋食"},
              {"G014": "カフェ"},
            ].map((map) {
              final key = map.keys.first;
              final label = map.values.first;
              return ChoiceChip(
                label: Text(label),
                selected: selectedGenre == key,
                onSelected: (_) => setState(() => selectedGenre = key),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          const Text("予算"),
          Wrap(
            spacing: 8,
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
                onSelected: (_) => setState(() => selectedBudget = key),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: goSearch,
            child: const Text("お店を探す"),
          ),
        ],
      ),
    );
  }
}

// ================= 検索結果（そのまま） =================
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("検索結果")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : shops.isEmpty
          ? const Center(child: Text("お店が見つかりません"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      shop["photo"]?["pc"]?["l"] ?? "",
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const SizedBox(
                        height: 200,
                        child: Icon(Icons.image),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop["name"] ?? "No Name",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shop["mobile_access"] ?? "",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
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

// ================= 詳細画面（ここだけ変更） =================
class DetailPage extends StatelessWidget {
  final dynamic shop;

  const DetailPage({super.key, required this.shop});

  Future<void> openMap(String address) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tel = shop["tel"];
    final url = shop["urls"]?["pc"];
    final image = shop["photo"]?["pc"]?["l"];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  image ?? "",
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    shop["name"] ?? "No Name",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(shop["address"] ?? "不明")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => openMap(shop["address"] ?? ""),
                    child: const Text("地図で見る",
                        style: TextStyle(color: Colors.blue)),
                  ),
                  const SizedBox(height: 16),

                  tel != null
                      ? GestureDetector(
                    onTap: () => call(tel),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(tel,
                            style: const TextStyle(
                                color: Colors.blue,
                                decoration:
                                TextDecoration.underline)),
                      ],
                    ),
                  )
                      : GestureDetector(
                    onTap: () => openWeb(url ?? ""),
                    child: const Text("公式サイトを見る",
                        style: TextStyle(color: Colors.blue)),
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