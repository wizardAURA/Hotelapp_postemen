import 'package:flutter/material.dart';
import 'package:hotelapp/services/api_services.dart';
import 'package:hotelapp/services/google_auth.dart';
import 'package:hotelapp/screens/page01/login_page.dart';
import '../../model/hotel_model.dart';
import '../page03/search_result.dart';

class home_page extends StatefulWidget {
  const home_page({super.key});

  @override
  State<home_page> createState() => _HomePageState();
}

class _HomePageState extends State<home_page> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<HotelResult> _hotels = [];
  String _currentSearchQuery = "India";
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  List<String> _excludedHotelIds = [];

  String? _visitorToken;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupScrollListener();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      final token = await _apiService.registerDevice();
      setState(() {
        _visitorToken = token;
        _isInitializing = false;
      });

      await _performSearch(isNewSearch: true);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoadingMore &&
          _hasMore) {
        _performSearch(isNewSearch: false);
      }
    });
  }

  Future<void> _performSearch({required bool isNewSearch}) async {
    if (_visitorToken == null) {
      setState(() {
        _errorMessage = "Failed to get visitor token. Please restart the app.";
        _isLoading = false;
      });
      return;
    }

    if (isNewSearch) {
      setState(() {
        _isLoading = true;
        _hotels.clear();
        _excludedHotelIds.clear();
        _hasMore = true;
        _errorMessage = null;
        if (_searchController.text.isNotEmpty) {
          _currentSearchQuery = _searchController.text;
        } else {
          _currentSearchQuery = "India";
        }
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await _apiService.searchHotels(
        query: _currentSearchQuery,
        visitorToken: _visitorToken!,
        previouslyLoadedHotels: _excludedHotelIds,
      );

      setState(() {
        _hotels.addAll(response.hotelList);
        _excludedHotelIds.addAll(response.excludedHotels);

        if (response.hotelList.isEmpty) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hotel Search"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await GoogleSignInService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by country...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty && _visitorToken != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultsPage(
                        query: value,
                        visitorToken: _visitorToken!,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Registering device..."),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "Error: $_errorMessage",
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_hotels.isEmpty) {
      return const Center(child: Text("No hotels found."));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _hotels.length + 1,
      itemBuilder: (context, index) {
        if (index == _hotels.length) {
          if (_isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          } else if (!_hasMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("You've reached the end of the list."),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }
        return HotelCard(hotel: _hotels[index]);
      },
    );
  }
}

class HotelCard extends StatelessWidget {
  final HotelResult hotel;
  const HotelCard({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hotel.imageUrl.isNotEmpty)
            Image.network(
              hotel.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorImage();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            )
          else
            _buildErrorImage(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.propertyName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "${hotel.city}, ${hotel.country}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hotel.googleRating != null && hotel.googleRating! > 0)
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "${hotel.googleRating}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            " (${hotel.googleRatingCount} reviews)",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        "No rating",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    Text(
                      hotel.displayPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 180,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.business, color: Colors.grey[400], size: 50),
      ),
    );
  }
}
