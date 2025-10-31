import 'package:flutter/material.dart';
import 'package:hotelapp/model/hotel_model.dart';
import 'package:hotelapp/services/api_services.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final String visitorToken;

  const SearchResultsPage({
    super.key,
    required this.query,
    required this.visitorToken,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  final List<HotelResult> _hotels = [];
  bool _isLoading = true; // For the initial search call
  bool _isLoadingMore = false; // For pagination
  bool _hasMore = true;
  String? _errorMessage;
  List<String> _excludedHotelIds = [];

  @override
  void initState() {
    super.initState();
    _performSearch(isNewSearch: true); // Perform search on load
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Check if we're at the end of the list
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoadingMore &&
          _hasMore) {
        _performSearch(isNewSearch: false); // Load more data
      }
    });
  }

  // Main function to get data from the API
  Future<void> _performSearch({required bool isNewSearch}) async {
    if (isNewSearch) {
      // A new search resets everything
      setState(() {
        _isLoading = true; // Show full-screen spinner
        _hotels.clear();
        _excludedHotelIds.clear(); // Reset pagination
        _hasMore = true;
        _errorMessage = null;
      });
    } else {
      // This is a pagination call
      setState(() {
        _isLoadingMore = true; // Show bottom spinner
      });
    }

    try {
      // Call the API
      final response = await _apiService.searchHotels(
        query: widget.query, // Use the query passed to this page
        visitorToken: widget.visitorToken, // Use the token passed to this page
        previouslyLoadedHotels: _excludedHotelIds, // Pass the list of IDs
      );

      // We have new data
      setState(() {
        _hotels.addAll(response.hotelList);
        _excludedHotelIds.addAll(
          response.excludedHotels,
        ); // Add new IDs to exclude

        // Check if we've reached the end
        if (response.hotelList.isEmpty) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      // Always stop loading spinners
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Results for '${widget.query}'")),
      body: _buildBody(), // Use the same body logic
    );
  }

  // --- This is the same logic from your home_page.dart ---
  Widget _buildBody() {
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

    // Main list view
    return ListView.builder(
      controller: _scrollController,
      itemCount: _hotels.length + 1, // +1 for the loading indicator
      itemBuilder: (context, index) {
        if (index == _hotels.length) {
          // This is the last item
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
            return const SizedBox.shrink(); // Nothing to show
          }
        }
        // This is a hotel item
        return HotelCard(hotel: _hotels[index]);
      },
    );
  }
}

// --- Hotel Card Widget (Copied from your home_page.dart) ---
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
          // Image
          if (hotel.imageUrl.isNotEmpty)
            Image.network(
              hotel.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              // Error handling for broken images
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorImage();
              },
              // Loading indicator for image
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

          // --- Content ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel Name
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
                // Location
                Text(
                  "${hotel.city}, ${hotel.country}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                // Price and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rating
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
                    // Price
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
