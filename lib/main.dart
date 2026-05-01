import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationText = "位置情報がOFFです";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationText = "位置情報が拒否されています";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("検索条件")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              locationText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),

            const Text("距離"),
            DropdownButton<String>(
              value: selectedRange,
              items: const [
                DropdownMenuItem(value: "1", child: Text("300m")),
                DropdownMenuItem(value: "2", child: Text("500m")),
                DropdownMenuItem(value: "3", child: Text("1000m")),
                DropdownMenuItem(value: "4", child: Text("2000m")),
                DropdownMenuItem(value: "5", child: Text("3000m")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRange = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text("ジャンル"),
            DropdownButton<String>(
              value: selectedGenre,
              items: const [
                DropdownMenuItem(value: "", child: Text("指定なし")),
                DropdownMenuItem(value: "G001", child: Text("居酒屋")),
                DropdownMenuItem(value: "G004", child: Text("和食")),
                DropdownMenuItem(value: "G005", child: Text("洋食")),
                DropdownMenuItem(value: "G014", child: Text("カフェ")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGenre = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text("予算"),
            DropdownButton<String>(
              value: selectedBudget,
              items: const [
                DropdownMenuItem(value: "", child: Text("指定なし")),
                DropdownMenuItem(value: "B009", child: Text("〜1000円")),
                DropdownMenuItem(value: "B010", child: Text("〜2000円")),
                DropdownMenuItem(value: "B011", child: Text("〜3000円")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedBudget = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: goSearch,
              child: const Text("検索"),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 結果画面（インスタ風） =================
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
    final apiKey = API_KEY;

    final url =
        "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/"
        "?key=$apiKey"
        "&lat=${widget.lat}"
        "&lng=${widget.lng}"
        "&range=${widget.range}"
        "&genre=${widget.genre}"
        "&budget=${widget.budget}"
        "&format=json";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    setState(() {
      if (data["results"] != null &&
          data["results"]["shop"] != null) {
        shops = data["results"]["shop"];
      } else {
        shops = [];
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // ←インスタっぽく
      appBar: AppBar(title: const Text("検索結果")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : shops.isEmpty
          ? const Center(child: Text("お店が見つかりません"))
          : ListView.builder(
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];

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
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      shop["photo"]["pc"]["l"],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const SizedBox(
                        height: 180,
                        child: Icon(Icons.image),
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop["name"],
                          style:
                          const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shop["mobile_access"],
                          style:
                          const TextStyle(
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

// ================= 詳細画面 =================
class DetailPage extends StatelessWidget {
  final dynamic shop;

  const DetailPage({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shop["name"])),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Image.network(
                shop["photo"]["pc"]["l"],
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image),
              ),
              const SizedBox(height: 10),
              Text("住所: ${shop["address"]}"),
              Text("営業時間: ${shop["open"]}"),
            ],
          ),
        ),
      ),
    );
  }
}