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
  String locationText = "現在地未取得";
  String selectedRange = "3";
  double? lat;
  double? lng;

  Future<void> getLocation() async {
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
      locationText = "緯度: $lat\n経度: $lng";
    });
  }

  void goSearch() {
    // GPS未取得なら大阪（保険）
    double useLat = lat ?? 34.67;
    double useLng = lng ?? 135.52;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          lat: useLat,
          lng: useLng,
          range: selectedRange,
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
        child: Column(
          children: [
            Text(locationText),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: getLocation,
              child: const Text("現在地取得"),
            ),

            const SizedBox(height: 20),

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

// ================= 結果画面 =================
class ResultPage extends StatefulWidget {
  final double lat;
  final double lng;
  final String range;

  const ResultPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.range,
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
      appBar: AppBar(title: const Text("検索結果")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : shops.isEmpty
          ? const Center(child: Text("お店が見つかりません"))
          : ListView.builder(
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];

          return ListTile(
            leading: Image.network(
              shop["photo"]["mobile"]["s"],
              width: 60,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.image),
            ),
            title: Text(shop["name"]),
            subtitle: Text(shop["mobile_access"]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(shop: shop),
                ),
              );
            },
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                shop["photo"]["pc"]["l"],
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
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