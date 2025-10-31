My Hotel Search App (myTravaly)

This is a Flutter app I built to try out the myTravaly public API. I've included Google Sign-In for authentication and a paginated list that loads hotel results infinitely as you scroll.

Features

Google Authentication: Lets users securely log in with their Google account.

Persistent Login: I made it so users are taken directly to the home page if they're already logged in, skipping the login screen.

Hotel Search: A search bar to find hotels.

Main List: The home page loads an initial list of hotels (I defaulted it to "India" to start).

Search Results Page: When you search, it opens a new screen to display the results for that specific query.

Infinite Scrolling: Automatically loads more hotels as you scroll to the bottom of the list (this is the pagination).

Robust API Service: I wrote a dedicated service (api_service.dart) to handle all the API communication, like device registration and searching.

API Service (api_service.dart)

This file is the core of the app's external communication.

Device Registration: Before any search can happen, my app has to call registerDevice(). This function sends the device's details (model, OS, etc.) along with my permanent _authToken to the API. The server then sends back a temporary visitorToken.

Hotel Search: The searchHotels() function needs this visitorToken for all its requests. It sends the user's search query to get the list of hotels.

Pagination: The API supports pagination by letting me send a list of previouslyLoadedHotels (by their ID), which the server then excludes from the next response.

Important API Limitation

Through testing, I discovered some annoying limitations with the myTravaly search endpoint:

searchType: "searchByKeywords": This should have been the ideal search type for a general search bar, but it consistently returns a 500 Internal Server Error, which tells me it's probably a bug on their end.

searchType: "citySearch" / stateSearch": These types have very strict query rules (like requiring the city, state, and country all at once) that just don't work with a simple search bar and wouldn't filter correctly.

searchType: "countrySearch": This is the only stable searchType I found that actually works reliably. As a result, I had to hardcode the app to use this. Searches for "India" will work, but trying to search for cities or states (like "Kerala") won't return any results.

How to Run

Clone the Repository:

git clone <your-repo-url>
cd <your-repo-name>


Get Dependencies:

flutter pub get


Set up Google Sign-In:

You'll need to set up a Firebase project and configure Google Sign-In for both Android and iOS.

Just follow the setup instructions on firebase.google.com to add your google-services.json (for Android) and GoogleService-Info.plist (for iOS) files to the project.

Add your API Auth Token:

Open the file lib/services/api_service.dart.

On line 9, replace the placeholder token with your own valid myTravaly _authToken:

final String _authToken = "YOUR_VALID_AUTH_TOKEN_HERE";


Run the App:

flutter run


Key Files

lib/services/api_service.dart: Handles all communication with the myTravaly API.

lib/services/google_auth.dart: Manages all the Google Sign-In and Sign-Out logic.

lib/models/hotel_model.dart: This is where I defined the ApiResponse and HotelResult models for parsing the API's JSON response.

lib/screens/page01/login_page.dart: The app's entry point for logged-out users.

lib/screens/page02/home_page.dart: The main screen showing the default hotel list and the search bar.

lib/screens/page02/search_results_page.dart: A separate screen pushed onto the stack to display search-specific results.
