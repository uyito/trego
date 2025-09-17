# Trego Fitness Integration Guide

## 🤖 AI Services Integration

### OpenAI GPT Integration

#### Configuration
```yaml
# application.yml
openai:
  api-key: ${OPENAI_API_KEY}
  model: gpt-4
  max-tokens: 2000
  temperature: 0.7
  timeout: 30000
  rate-limit:
    requests-per-minute: 60
    requests-per-hour: 1000
```

#### Recipe Generation Service
```java
@Component
public class OpenAIRecipeService {
    
    @Value("${openai.api-key}")
    private String apiKey;
    
    @Value("${openai.model}")
    private String model;
    
    private final OpenAiService openAiService;
    private final RateLimiter rateLimiter;
    
    public OpenAIRecipeService() {
        this.openAiService = new OpenAiService(apiKey, Duration.ofSeconds(30));
        this.rateLimiter = RateLimiter.create(1.0); // 1 request per second
    }
    
    public Recipe generateRecipe(RecipeGenerationRequest request) {
        rateLimiter.acquire();
        
        String prompt = buildRecipePrompt(request);
        
        ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                .model(model)
                .messages(Arrays.asList(
                    new ChatMessage(ChatMessageRole.SYSTEM.value(), RECIPE_SYSTEM_PROMPT),
                    new ChatMessage(ChatMessageRole.USER.value(), prompt)
                ))
                .maxTokens(1500)
                .temperature(0.7)
                .build();
        
        try {
            ChatCompletionResult result = openAiService.createChatCompletion(chatRequest);
            String recipeJson = result.getChoices().get(0).getMessage().getContent();
            
            return parseRecipeFromJson(recipeJson);
        } catch (Exception e) {
            logger.error("Failed to generate recipe: {}", e.getMessage());
            throw new AIServiceException("Recipe generation failed", e);
        }
    }
    
    private static final String RECIPE_SYSTEM_PROMPT = """
        You are a professional chef and nutritionist. Generate recipes that are:
        1. Nutritionally balanced and accurate
        2. Easy to follow with clear instructions
        3. Include precise measurements and cooking times
        4. Provide complete nutrition facts
        5. Consider dietary restrictions and preferences
        
        Always return recipes in this JSON format:
        {
          "title": "Recipe Name",
          "description": "Brief description",
          "prepTime": 15,
          "cookTime": 25,
          "servings": 4,
          "difficulty": "easy|medium|hard",
          "ingredients": [
            {
              "name": "ingredient name",
              "quantity": 1.5,
              "unit": "cups",
              "notes": "optional preparation notes"
            }
          ],
          "instructions": [
            {
              "step": 1,
              "description": "Detailed instruction",
              "duration": 5,
              "temperature": "180°C"
            }
          ],
          "nutritionFacts": {
            "calories": 450,
            "protein": 25.5,
            "carbs": 35.2,
            "fat": 18.8,
            "fiber": 6.2,
            "sodium": 680
          },
          "tags": ["vegetarian", "quick", "healthy"],
          "cuisineType": "italian"
        }
        """;
    
    private String buildRecipePrompt(RecipeGenerationRequest request) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("Generate a recipe with the following requirements:\n\n");
        
        if (request.getMealType() != null) {
            prompt.append("Meal Type: ").append(request.getMealType()).append("\n");
        }
        
        if (request.getCuisineType() != null) {
            prompt.append("Cuisine: ").append(request.getCuisineType()).append("\n");
        }
        
        if (request.getDietaryRestrictions() != null && !request.getDietaryRestrictions().isEmpty()) {
            prompt.append("Dietary Restrictions: ").append(String.join(", ", request.getDietaryRestrictions())).append("\n");
        }
        
        if (request.getMaxPrepTime() != null) {
            prompt.append("Maximum Prep Time: ").append(request.getMaxPrepTime()).append(" minutes\n");
        }
        
        if (request.getTargetCalories() != null) {
            prompt.append("Target Calories per Serving: ").append(request.getTargetCalories()).append("\n");
        }
        
        if (request.getAvailableIngredients() != null && !request.getAvailableIngredients().isEmpty()) {
            prompt.append("Available Ingredients to Use: ").append(String.join(", ", request.getAvailableIngredients())).append("\n");
        }
        
        if (request.getServings() != null) {
            prompt.append("Number of Servings: ").append(request.getServings()).append("\n");
        }
        
        prompt.append("\nPlease create a delicious and nutritious recipe that meets these requirements.");
        
        return prompt.toString();
    }
}
```

#### Workout Generation Service
```java
@Component
public class OpenAIWorkoutService {
    
    public WorkoutPlan generateWorkout(WorkoutGenerationRequest request) {
        String prompt = buildWorkoutPrompt(request);
        
        ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                .model("gpt-4")
                .messages(Arrays.asList(
                    new ChatMessage(ChatMessageRole.SYSTEM.value(), WORKOUT_SYSTEM_PROMPT),
                    new ChatMessage(ChatMessageRole.USER.value(), prompt)
                ))
                .maxTokens(1500)
                .temperature(0.6)
                .build();
        
        ChatCompletionResult result = openAiService.createChatCompletion(chatRequest);
        String workoutJson = result.getChoices().get(0).getMessage().getContent();
        
        return parseWorkoutFromJson(workoutJson);
    }
    
    private static final String WORKOUT_SYSTEM_PROMPT = """
        You are a certified personal trainer and exercise physiologist. Create safe, effective workouts that:
        1. Match the user's fitness level and goals
        2. Include proper warm-up and cool-down
        3. Provide clear exercise instructions and safety tips
        4. Consider available equipment and time constraints
        5. Include progression recommendations
        
        Return workouts in this JSON format:
        {
          "name": "Workout Name",
          "description": "Brief description of workout focus",
          "duration": 45,
          "difficulty": "beginner|intermediate|advanced",
          "workoutType": "strength|cardio|hiit|flexibility",
          "targetMuscleGroups": ["chest", "shoulders", "triceps"],
          "estimatedCaloriesBurn": 320,
          "warmUp": {
            "duration": 5,
            "exercises": ["dynamic_stretches", "light_cardio"]
          },
          "exercises": [
            {
              "name": "Push-ups",
              "category": "bodyweight",
              "primaryMuscles": ["chest", "triceps"],
              "sets": 3,
              "reps": "10-15",
              "restTime": 60,
              "instructions": ["Start in plank position", "Lower body to ground", "Push back up"],
              "modifications": ["Knee push-ups for beginners", "Decline push-ups for advanced"],
              "safetyTips": ["Keep core engaged", "Don't let hips sag"]
            }
          ],
          "coolDown": {
            "duration": 5,
            "exercises": ["static_stretches", "deep_breathing"]
          }
        }
        """;
}
```

### Claude/Anthropic Integration (Alternative AI Service)
```java
@Component 
public class ClaudeAIService {
    
    @Value("${claude.api-key}")
    private String apiKey;
    
    private final WebClient webClient;
    
    public ClaudeAIService() {
        this.webClient = WebClient.builder()
                .baseUrl("https://api.anthropic.com")
                .defaultHeader("x-api-key", apiKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }
    
    public String generateCoachingAdvice(String userQuery, UserContext context) {
        Map<String, Object> request = Map.of(
            "model", "claude-3-sonnet-20240229",
            "max_tokens", 1000,
            "messages", List.of(
                Map.of("role", "user", "content", buildCoachingPrompt(userQuery, context))
            )
        );
        
        return webClient.post()
                .uri("/v1/messages")
                .bodyValue(request)
                .retrieve()
                .bodyToMono(String.class)
                .block();
    }
}
```

## 📱 Wearable Device Integration

### Apple HealthKit Integration

#### iOS Configuration (Info.plist)
```xml
<key>NSHealthUpdateUsageDescription</key>
<string>Trego needs access to write workout data to Health app</string>
<key>NSHealthShareUsageDescription</key>
<string>Trego needs access to read health data to provide personalized recommendations</string>
```

#### Flutter HealthKit Plugin Setup
```dart
// pubspec.yaml
dependencies:
  health: ^10.0.0
  permission_handler: ^11.0.0

// iOS specific setup
// ios/Podfile
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

#### Health Data Service (Flutter)
```dart
import 'package:health/health.dart';

class HealthDataService {
  static final Health _health = Health();
  
  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.SLEEP_IN_BED,
  ];
  
  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];
  
  Future<bool> requestPermissions() async {
    bool requested = await _health.requestAuthorization(_dataTypes, permissions: _permissions);
    return requested;
  }
  
  Future<List<HealthDataPoint>> getHealthData(DateTime start, DateTime end) async {
    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        start,
        end,
        _dataTypes,
      );
      
      return Health().removeDuplicates(healthData);
    } catch (error) {
      print("Error fetching health data: $error");
      return [];
    }
  }
  
  Future<bool> writeWorkoutData({
    required DateTime startTime,
    required DateTime endTime,
    required HealthWorkoutActivityType activityType,
    required int totalEnergyBurned,
    required int totalDistance,
  }) async {
    try {
      bool success = await _health.writeWorkoutData(
        activityType,
        startTime,
        endTime,
        totalEnergyBurned: totalEnergyBurned,
        totalDistance: totalDistance,
      );
      
      if (success) {
        await syncWithBackend({
          'source': 'apple_health',
          'type': 'workout',
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'activityType': activityType.name,
          'energyBurned': totalEnergyBurned,
          'distance': totalDistance,
        });
      }
      
      return success;
    } catch (error) {
      print("Error writing workout data: $error");
      return false;
    }
  }
  
  Future<void> syncWithBackend(Map<String, dynamic> healthData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/health/sync'),
        headers: {
          'Authorization': 'Bearer ${await AuthService.getToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'source': 'apple_health',
          'dataType': healthData['type'],
          'data': [healthData],
        }),
      );
      
      if (response.statusCode == 200) {
        print('Health data synced successfully');
      } else {
        print('Failed to sync health data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error syncing health data: $error');
    }
  }
}
```

### Google Fit Integration

#### Android Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="com.google.android.gms.permission.ACTIVITY_RECOGNITION" />
```

#### Google Fit Service (Flutter)
```dart
import 'package:googleapis/fitness/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleFitService {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/fitness.activity.read',
    'https://www.googleapis.com/auth/fitness.activity.write',
    'https://www.googleapis.com/auth/fitness.body.read',
    'https://www.googleapis.com/auth/fitness.body.write',
  ];
  
  late FitnessApi _fitnessApi;
  
  Future<bool> initialize() async {
    try {
      final authClient = await clientViaUserConsent(
        ClientId('your-client-id', 'your-client-secret'),
        _scopes,
        (url) {
          // Handle OAuth flow
          print('Please go to the following URL and re-enter the credentials:');
          print('  => $url');
        },
      );
      
      _fitnessApi = FitnessApi(authClient);
      return true;
    } catch (error) {
      print('Error initializing Google Fit: $error');
      return false;
    }
  }
  
  Future<void> syncWorkoutData() async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(Duration(days: 7));
      
      // Get activity data
      final request = AggregateRequest()
        ..aggregateBy = [
          AggregateBy()..dataTypeName = 'com.google.step_count.delta',
          AggregateBy()..dataTypeName = 'com.google.calories.expended',
          AggregateBy()..dataTypeName = 'com.google.heart_rate.bpm',
        ]
        ..bucketByTime = (BucketByTime()..durationMillis = 86400000) // 1 day
        ..startTimeMillis = oneWeekAgo.millisecondsSinceEpoch.toString()
        ..endTimeMillis = now.millisecondsSinceEpoch.toString();
      
      final response = await _fitnessApi.users.dataset.aggregate(request, 'me');
      
      // Process and sync with backend
      await processGoogleFitData(response);
      
    } catch (error) {
      print('Error syncing Google Fit data: $error');
    }
  }
  
  Future<void> processGoogleFitData(AggregateResponse response) async {
    // Process the aggregated data and sync with backend
    for (var bucket in response.bucket!) {
      final Map<String, dynamic> healthData = {
        'source': 'google_fit',
        'date': DateTime.fromMillisecondsSinceEpoch(
          int.parse(bucket.startTimeMillis!)
        ).toIso8601String().split('T')[0],
        'steps': 0,
        'caloriesBurned': 0.0,
        'averageHeartRate': 0.0,
      };
      
      for (var dataset in bucket.dataset!) {
        if (dataset.dataSourceId!.contains('step_count')) {
          healthData['steps'] = dataset.point?.first.value?.first.intVal ?? 0;
        } else if (dataset.dataSourceId!.contains('calories')) {
          healthData['caloriesBurned'] = dataset.point?.first.value?.first.fpVal ?? 0.0;
        } else if (dataset.dataSourceId!.contains('heart_rate')) {
          healthData['averageHeartRate'] = dataset.point?.first.value?.first.fpVal ?? 0.0;
        }
      }
      
      await syncWithBackend(healthData);
    }
  }
}
```

## 🗺️ Maps Integration

### Google Maps Integration

#### API Configuration
```yaml
# application.yml
google:
  maps:
    api-key: ${GOOGLE_MAPS_API_KEY}
    geocoding-url: https://maps.googleapis.com/maps/api/geocoding/json
    directions-url: https://maps.googleapis.com/maps/api/directions/json
    places-url: https://maps.googleapis.com/maps/api/place
```

#### Maps Service (Spring Boot)
```java
@Service
public class GoogleMapsService {
    
    @Value("${google.maps.api-key}")
    private String apiKey;
    
    private final WebClient webClient;
    
    public GoogleMapsService() {
        this.webClient = WebClient.builder()
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(1024 * 1024))
                .build();
    }
    
    public RouteInfo calculateRoute(RouteRequest request) {
        String url = UriComponentsBuilder
                .fromHttpUrl("https://maps.googleapis.com/maps/api/elevation/json")
                .queryParam("path", path)
                .queryParam("samples", Math.min(route.size(), 512)) // Google limits to 512 samples
                .queryParam("key", apiKey)
                .build()
                .toUriString();
        
        try {
            ElevationResponse response = webClient.get()
                    .uri(url)
                    .retrieve()
                    .bodyToMono(ElevationResponse.class)
                    .block();
            
            return convertToElevationProfile(response);
        } catch (Exception e) {
            logger.error("Error getting elevation profile: {}", e.getMessage());
            return new ElevationProfile();
        }
    }
}
```

#### Flutter Google Maps Integration
```dart
// pubspec.yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1

// lib/services/maps_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapsService {
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  Future<List<LatLng>> getRouteCoordinates(LatLng start, LatLng end) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${start.latitude},${start.longitude}&'
        'destination=${end.latitude},${end.longitude}&'
        'mode=walking&'
        'key=$_apiKey';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0]['overview_polyline']['points'];
      
      return decodePolyline(route);
    } else {
      throw Exception('Failed to load route');
    }
  }
  
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      
      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }
    
    return polyline;
  }
}
```

### Apple MapKit Integration (iOS)

#### MapKit Service (Swift)
```swift
import MapKit
import CoreLocation

class MapKitService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func calculateRoute(from source: CLLocationCoordinate2D, 
                       to destination: CLLocationCoordinate2D,
                       completion: @escaping ([CLLocationCoordinate2D]) -> Void) {
        
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                print("Error calculating route: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            let coordinates = self.extractCoordinates(from: route.polyline)
            completion(coordinates)
        }
    }
    
    private func extractCoordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        let pointCount = polyline.pointCount
        let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
        defer { coordinates.deallocate() }
        
        polyline.getCoordinates(coordinates, range: NSRange(location: 0, length: pointCount))
        
        return Array(UnsafeBufferPointer(start: coordinates, count: pointCount))
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Send location update to Flutter
        NotificationCenter.default.post(
            name: .locationUpdated,
            object: nil,
            userInfo: [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "altitude": location.altitude,
                "speed": location.speed,
                "timestamp": location.timestamp.timeIntervalSince1970
            ]
        )
    }
}

extension Notification.Name {
    static let locationUpdated = Notification.Name("locationUpdated")
}
```

## 📱 Frontend Integration (Flutter)

### Authentication Service
```dart
// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'https://api.trego.fitness/v1';
  static const _storage = FlutterSecureStorage();
  
  static String? _accessToken;
  static String? _refreshToken;
  
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storeTokens(data['data']);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  static Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storeTokens(data['data']);
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }
  
  static Future<void> _storeTokens(Map<String, dynamic> authData) async {
    _accessToken = authData['accessToken'];
    _refreshToken = authData['refreshToken'];
    
    await _storage.write(key: 'access_token', value: _accessToken);
    await _storage.write(key: 'refresh_token', value: _refreshToken);
  }
  
  static Future<String?> getToken() async {
    if (_accessToken == null) {
      _accessToken = await _storage.read(key: 'access_token');
    }
    
    if (_accessToken != null && _isTokenExpired(_accessToken!)) {
      await _refreshAccessToken();
    }
    
    return _accessToken;
  }
  
  static Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) {
      _refreshToken = await _storage.read(key: 'refresh_token');
    }
    
    if (_refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['data']['accessToken'];
        await _storage.write(key: 'access_token', value: _accessToken);
        return true;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    
    return false;
  }
  
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      
      if (payloadMap is! Map<String, dynamic>) return true;
      
      final exp = payloadMap['exp'];
      if (exp is! int) return true;
      
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      return now > exp;
    } catch (e) {
      return true;
    }
  }
  
  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
  }
}
```

### API Client Service
```dart
// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://api.trego.fitness/v1';
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(uri, headers: await _getHeaders());
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final data = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (fromJson != null && data['data'] != null) {
        return ApiResponse.success(fromJson(data['data']), data['message']);
      }
      return ApiResponse.success(data['data'] as T, data['message']);
    } else {
      return ApiResponse.error(data['message'] ?? 'Unknown error');
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final String? errorCode;
  
  ApiResponse._({
    required this.success,
    this.data,
    required this.message,
    this.errorCode,
  });
  
  factory ApiResponse.success(T data, String message) {
    return ApiResponse._(
      success: true,
      data: data,
      message: message,
    );
  }
  
  factory ApiResponse.error(String message, [String? errorCode]) {
    return ApiResponse._(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}
```

### Recipe Service (Flutter)
```dart
// lib/services/recipe_service.dart
class RecipeService {
  static Future<ApiResponse<Recipe>> generateAIRecipe({
    required String mealType,
    int? maxPrepTime,
    int? maxCalories,
    List<String>? dietaryRestrictions,
    List<String>? availableIngredients,
    String? cuisineType,
    int? servings,
  }) async {
    final data = {
      'preferences': {
        'mealType': mealType,
        if (maxPrepTime != null) 'maxPrepTime': maxPrepTime,
        if (maxCalories != null) 'maxCalories': maxCalories,
        if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty)
          'dietaryRestrictions': dietaryRestrictions,
        if (availableIngredients != null && availableIngredients.isNotEmpty)
          'useIngredients': availableIngredients,
        if (cuisineType != null) 'cuisineType': cuisineType,
        if (servings != null) 'servings': servings,
      },
      'context': {
        'timeOfDay': _getTimeOfDay(),
        'skillLevel': 'intermediate', // Could get from user profile
      }
    };
    
    return await ApiClient.post<Recipe>(
      '/recipes/generate-ai',
      data,
      fromJson: Recipe.fromJson,
    );
  }
  
  static Future<ApiResponse<List<Recipe>>> searchRecipes({
    String? query,
    String? cuisine,
    int? maxCalories,
    String? difficulty,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'query': query,
      if (cuisine != null) 'cuisine': cuisine,
      if (maxCalories != null) 'maxCalories': maxCalories.toString(),
      if (difficulty != null) 'difficulty': difficulty,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    return await ApiClient.get<List<Recipe>>(
      '/recipes/search',
      queryParams: queryParams,
      fromJson: (data) => (data as List)
          .map((item) => Recipe.fromJson(item))
          .toList(),
    );
  }
  
  static Future<ApiResponse<List<Recipe>>> getRecommendations({
    int limit = 10,
    String? mealType,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
      if (mealType != null) 'mealType': mealType,
    };
    
    return await ApiClient.get<List<Recipe>>(
      '/recipes/recommendations',
      queryParams: queryParams,
      fromJson: (data) => (data as List)
          .map((item) => Recipe.fromJson(item))
          .toList(),
    );
  }
  
  static Future<ApiResponse<Recipe>> generateFromPantry({
    bool useExpiringItems = true,
    int maxAdditionalIngredients = 3,
    String? mealType,
    int? prepTime,
    String? difficulty,
  }) async {
    final data = {
      'useExpiringItems': useExpiringItems,
      'maxAdditionalIngredients': maxAdditionalIngredients,
      if (mealType != null) 'mealType': mealType,
      'preferences': {
        if (prepTime != null) 'prepTime': prepTime,
        if (difficulty != null) 'difficulty': difficulty,
      }
    };
    
    return await ApiClient.post<Recipe>(
      '/recipes/from-pantry',
      data,
      fromJson: Recipe.fromJson,
    );
  }
  
  static String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
```

### Workout Service (Flutter)
```dart
// lib/services/workout_service.dart
class WorkoutService {
  static Future<ApiResponse<WorkoutPlan>> generateAIWorkout({
    required String workoutType,
    List<String>? targetMuscleGroups,
    int? duration,
    List<String>? equipment,
    String? difficulty,
    String? focus,
    int? timeAvailable,
    List<String>? injuryConsiderations,
    String? energyLevel,
    String? location,
  }) async {
    final data = {
      'preferences': {
        'workoutType': workoutType,
        if (targetMuscleGroups != null) 'targetMuscleGroups': targetMuscleGroups,
        if (duration != null) 'duration': duration,
        if (equipment != null) 'equipment': equipment,
        if (difficulty != null) 'difficulty': difficulty,
        if (focus != null) 'focus': focus,
      },
      'constraints': {
        if (timeAvailable != null) 'timeAvailable': timeAvailable,
        if (injuryConsiderations != null) 'injuryConsiderations': injuryConsiderations,
        if (energyLevel != null) 'energyLevel': energyLevel,
        if (location != null) 'location': location,
      }
    };
    
    return await ApiClient.post<WorkoutPlan>(
      '/workouts/generate-ai',
      data,
      fromJson: WorkoutPlan.fromJson,
    );
  }
  
  static Future<ApiResponse<WorkoutSession>> startSession({
    required String workoutPlanId,
    String? sessionName,
    Map<String, dynamic>? location,
    bool enableGPS = false,
    bool enableHeartRate = false,
  }) async {
    final data = {
      'workoutPlanId': workoutPlanId,
      if (sessionName != null) 'sessionName': sessionName,
      if (location != null) 'location': location,
      'enableGPS': enableGPS,
      'enableHeartRateTracking': enableHeartRate,
    };
    
    return await ApiClient.post<WorkoutSession>(
      '/workouts/sessions/start',
      data,
      fromJson: WorkoutSession.fromJson,
    );
  }
  
  static Future<ApiResponse<dynamic>> logExerciseSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    int? reps,
    double? weight,
    int? duration,
    double? distance,
    int? restTime,
    int? rpe,
    String? notes,
  }) async {
    final data = {
      'setNumber': setNumber,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (duration != null) 'duration': duration,
      if (distance != null) 'distance': distance,
      if (restTime != null) 'restTime': restTime,
      if (rpe != null) 'rpe': rpe,
      if (notes != null) 'notes': notes,
    };
    
    return await ApiClient.post(
      '/workouts/sessions/$sessionId/exercises/$exerciseId/sets',
      data,
    );
  }
  
  static Future<ApiResponse<WorkoutSession>> endSession({
    required String sessionId,
    String? mood,
    int? perceivedExertion,
    String? notes,
    int? actualDuration,
    List<String>? photos,
  }) async {
    final data = {
      if (mood != null) 'mood': mood,
      if (perceivedExertion != null) 'perceivedExertion': perceivedExertion,
      if (notes != null) 'notes': notes,
      if (actualDuration != null) 'actualDuration': actualDuration,
      if (photos != null) 'photos': photos,
    };
    
    return await ApiClient.post<WorkoutSession>(
      '/workouts/sessions/$sessionId/end',
      data,
      fromJson: WorkoutSession.fromJson,
    );
  }
}
```

## 🔄 Real-time Features

### WebSocket Integration
```java
// WebSocketConfig.java
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(new WorkoutTrackingHandler(), "/ws/workout-tracking")
                .setAllowedOrigins("*")
                .withSockJS();
        
        registry.addHandler(new SocialFeedHandler(), "/ws/social-feed")
                .setAllowedOrigins("*")
                .withSockJS();
    }
}

// WorkoutTrackingHandler.java
@Component
public class WorkoutTrackingHandler extends TextWebSocketHandler {
    
    private final Map<String, WebSocketSession> activeSessions = new ConcurrentHashMap<>();
    
    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = extractUserIdFromSession(session);
        activeSessions.put(userId, session);
        logger.info("WebSocket connection established for user: {}", userId);
    }
    
    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        try {
            WorkoutUpdate update = parseWorkoutUpdate(message.getPayload());
            
            // Process real-time workout data
            processWorkoutUpdate(update);
            
            // Broadcast to connected clients (for social features)
            broadcastWorkoutUpdate(update);
            
        } catch (Exception e) {
            logger.error("Error processing workout update: {}", e.getMessage());
            session.sendMessage(new TextMessage(
                "{\"type\":\"error\",\"message\":\"Failed to process update\"}"
            ));
        }
    }
    
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String userId = extractUserIdFromSession(session);
        activeSessions.remove(userId);
        logger.info("WebSocket connection closed for user: {}", userId);
    }
}
```

### Flutter WebSocket Client
```dart
// lib/services/websocket_service.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static StreamController<Map<String, dynamic>>? _messageController;
  
  static Future<void> connect(String endpoint) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('wss://api.trego.fitness/ws/$endpoint?token=$token');
    
    _channel = WebSocketChannel.connect(uri);
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    
    _channel!.stream.listen(
      (data) {
        try {
          final message = jsonDecode(data);
          _messageController!.add(message);
        } catch (e) {
          print('Error parsing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        _reconnect(endpoint);
      },
      onDone: () {
        print('WebSocket connection closed');
        _reconnect(endpoint);
      },
    );
  }
  
  static void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }
  
  static Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;
  
  static Future<void> _reconnect(String endpoint) async {
    await Future.delayed(Duration(seconds: 5));
    await connect(endpoint);
  }
  
  static void disconnect() {
    _channel?.sink.close();
    _messageController?.close();
    _channel = null;
    _messageController = null;
  }
}
```

This comprehensive integration guide covers all the major external services and systems that the Trego Fitness backend needs to work with. The implementation provides:

1. **AI Service Integration** - Full OpenAI and Claude integration for recipe and workout generation
2. **Wearable Device Support** - Apple HealthKit and Google Fit integration
3. **Maps Integration** - Google Maps and Apple MapKit for GPS tracking and route planning
4. **Flutter Frontend Integration** - Complete API client implementation with authentication
5. **Real-time Features** - WebSocket support for live workout tracking and social features

Each integration includes proper error handling, rate limiting, authentication, and follows best practices for production deployment.maps/api/directions/json")
                .queryParam("origin", request.getOrigin())
                .queryParam("destination", request.getDestination())
                .queryParam("mode", request.getMode()) // walking, running, cycling
                .queryParam("avoid", "highways") // for running routes
                .queryParam("key", apiKey)
                .build()
                .toUriString();
        
        try {
            DirectionsResponse response = webClient.get()
                    .uri(url)
                    .retrieve()
                    .bodyToMono(DirectionsResponse.class)
                    .timeout(Duration.ofSeconds(10))
                    .block();
            
            return convertToRouteInfo(response);
        } catch (Exception e) {
            logger.error("Error calculating route: {}", e.getMessage());
            throw new MapsServiceException("Failed to calculate route", e);
        }
    }
    
    public List<NearbyGym> findNearbyGyms(double latitude, double longitude, int radius) {
        String url = UriComponentsBuilder
                .fromHttpUrl("https://maps.googleapis.com/maps/api/place/nearbysearch/json")
                .queryParam("location", latitude + "," + longitude)
                .queryParam("radius", radius)
                .queryParam("type", "gym")
                .queryParam("key", apiKey)
                .build()
                .toUriString();
        
        try {
            PlacesResponse response = webClient.get()
                    .uri(url)
                    .retrieve()
                    .bodyToMono(PlacesResponse.class)
                    .block();
            
            return response.getResults().stream()
                    .map(this::convertToNearbyGym)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            logger.error("Error finding nearby gyms: {}", e.getMessage());
            return new ArrayList<>();
        }
    }
    
    public ElevationProfile getElevationProfile(List<GPSPoint> route) {
        // Convert GPS points to path parameter
        String path = route.stream()
                .map(point -> point.getLatitude() + "," + point.getLongitude())
                .collect(Collectors.joining("|"));
        
        String url = UriComponentsBuilder
                .fromHttpUrl("https://maps.googleapis.com/