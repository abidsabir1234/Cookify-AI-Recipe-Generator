import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipe_app/recipe_detail_screen.dart';
import 'package:recipe_app/fitness_chat_widget.dart';
import 'package:recipe_app/login_screen.dart';

void main() {
  runApp(const RecipeAIApp());
}

class RecipeAIApp extends StatelessWidget {
  const RecipeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.light,
          primary: const Color(0xFFD32F2F),
          secondary: const Color(0xFFFFC107),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme).copyWith(
          headlineSmall: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
          titleLarge: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
          bodyMedium: GoogleFonts.lato(fontSize: 14, color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFD32F2F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<XFile> _imageFiles = [];
  final _picker = ImagePicker();
  bool _isLoading = false;
  final Set<String> _detectedIngredients = {};
  final TextEditingController _manualIngredientController = TextEditingController();
  Map<String, dynamic> _recipes = {};
  Map<String, dynamic> _nutritionData = {};
  List<String> _matchingRecipes = [];
  bool _isStrictFilter = true;
  final Map<String, TextEditingController> _gramsControllers = {};

  String get _cookifyApiUrl {
    if (kIsWeb) return "http://localhost:8000/detect";
    // Using the laptop's local IP address so the physical Android phone can connect
    if (Platform.isAndroid) return "http://172.28.204.166:8000/detect";
    return "http://localhost:8000/detect";
  }
  String _grokApiKey = const String.fromEnvironment('GROK_API_KEY');
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadNutritionData();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    if (_grokApiKey.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('grok_api_key') ?? '';
      if (savedKey.isNotEmpty) {
        setState(() {
          _grokApiKey = savedKey;
        });
      }
    } catch (_) {}
  }

  void _checkAndPromptApiKey({required VoidCallback onProceed}) {
    if (_grokApiKey.trim().isNotEmpty) {
      onProceed();
    } else {
      _showApiKeySetupDialog(onProceed);
    }
  }

  void _showApiKeySetupDialog(VoidCallback onProceed) {
    final controller = TextEditingController(text: _grokApiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.vpn_key, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Text('Grok API Key Required', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To generate recipes and chat with the Fitness AI, please enter your X.AI Grok API key.',
              style: GoogleFonts.lato(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'xai-...',
                labelText: 'API Key',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your API key is stored locally on your device and never sent anywhere else.',
              style: GoogleFonts.lato(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.montserrat(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                final navigator = Navigator.of(context);
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('grok_api_key', newKey);
                  setState(() {
                    _grokApiKey = newKey;
                  });
                } catch (_) {}
                if (mounted) {
                  navigator.pop();
                  onProceed();
                }
              }
            },
            child: Text('Save & Continue', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _gramsControllers.values) {
      controller.dispose();
    }
    _manualIngredientController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final String response = await rootBundle.loadString('assets/recipes.json');
      final Map<String, dynamic> recipeData = json.decode(response);

      setState(() {
        _recipes = recipeData;
      });
    } catch (e) {
      _showError("Error loading recipes: $e");
    }
  }

  Future<void> _loadNutritionData() async {
    try {
      final String response = await rootBundle.loadString('assets/nutrition.json');
      final Map<String, dynamic> nutrition = json.decode(response);
      setState(() {
        _nutritionData = nutrition;
      });
    } catch (e) {
      _showError("Error loading nutrition data: $e");
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final List<XFile> pickedFiles = source == ImageSource.camera
          ? [await _picker.pickImage(source: source)].nonNulls.toList()
          : await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles.addAll(pickedFiles);
        });
        await _detectIngredients(pickedFiles);
      }
    } catch (e) {
      _showError("Could not pick image(s): $e");
    }
  }

  Future<void> _detectIngredients(List<XFile> newFiles) async {
    if (newFiles.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      for (var file in newFiles) {
        await _detectWithCookifyModel(file);
      }
      _findMatchingRecipes();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _detectWithCookifyModel(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final uri = Uri.parse(_cookifyApiUrl);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name.isNotEmpty ? imageFile.name : 'image.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final List predictions = result['predictions'] as List;
        const double confidenceThreshold = 0.30;

        final detectedForThisImage = predictions
            .where((p) => (p['confidence'] as num).toDouble() >= confidenceThreshold)
            .map((p) => (p['class'] as String).toLowerCase().replaceAll('_', ' '))
            .toSet();

        setState(() {
          _detectedIngredients.addAll(detectedForThisImage);
          for (final ingredient in detectedForThisImage) {
            _ensureGramController(ingredient);
          }
        });
      }
    } catch (e) {
      _showError('Detection failed: $e');
    }
  }

  void _addManualIngredient(String ingredient) {
    final text = ingredient.trim().toLowerCase();
    if (text.isNotEmpty) {
      setState(() {
        _detectedIngredients.add(text);
        _ensureGramController(text);
        _manualIngredientController.clear();
        _findMatchingRecipes();
      });
    }
  }

  String _singularize(String word) {
    if (word.endsWith('ies') && word.length > 3) return '${word.substring(0, word.length - 3)}y';
    if (word.endsWith('ves') && word.length > 3) return '${word.substring(0, word.length - 3)}f';
    if (word.endsWith('oes') && word.length > 3) return word.substring(0, word.length - 2);
    if (word.endsWith('es') && word.length > 2) return word.substring(0, word.length - 2);
    if (word.endsWith('s') && word.length > 1) return word.substring(0, word.length - 1);
    return word;
  }

  bool _ingredientMatches(String userIngredient, String recipeIngredient) {
    if (userIngredient == recipeIngredient) return true;
    final singUser = _singularize(userIngredient);
    final singRecipe = _singularize(recipeIngredient);
    return singUser == singRecipe || userIngredient.contains(recipeIngredient) || recipeIngredient.contains(userIngredient);
  }

  bool _userHasRecipeIngredient(String recipeIngredient, Set<String> searchTerms) {
    return searchTerms.any((userIng) => _ingredientMatches(userIng, recipeIngredient));
  }

  void _findMatchingRecipes() {
    if (_recipes.isEmpty || _detectedIngredients.isEmpty) {
      setState(() => _matchingRecipes = []);
      return;
    }
    List<String> matches = [];
    final searchTerms = _detectedIngredients.map((i) => i.toLowerCase()).toSet();
    for (var entry in _recipes.entries) {
      final recipeIngredients = (entry.value['ingredients'] as List).map((i) => i.toString().toLowerCase()).toSet();
      if (_isStrictFilter) {
        if (recipeIngredients.every((ri) => _userHasRecipeIngredient(ri, searchTerms))) matches.add(entry.key);
      } else {
        if (recipeIngredients.any((ri) => _userHasRecipeIngredient(ri, searchTerms))) matches.add(entry.key);
      }
    }
    setState(() => _matchingRecipes = matches);
  }

  void _ensureGramController(String ingredient) {
    if (_gramsControllers.containsKey(ingredient)) return;
    _gramsControllers[ingredient] = TextEditingController(text: '0');
  }

  double _parseGrams(String ingredient) {
    final raw = _gramsControllers[ingredient]?.text.trim() ?? '';
    return double.tryParse(raw) ?? 0;
  }

  double? _caloriesForIngredient(String ingredient) {
    final normalized = ingredient.toLowerCase();
    final caloriesPer100 = (_nutritionData[normalized] as num?)?.toDouble();
    if (caloriesPer100 == null) return null;
    return (caloriesPer100 * _parseGrams(normalized)) / 100;
  }

  double _totalEstimatedCalories() {
    double total = 0;
    for (final ingredient in _detectedIngredients) {
      final calories = _caloriesForIngredient(ingredient);
      if (calories != null) total += calories;
    }
    return total;
  }

  Future<void> _generateAiRecipe() async {
    if (_detectedIngredients.isEmpty) return;
    _checkAndPromptApiKey(onProceed: () async {
      setState(() => _isGenerating = true);
      try {
        final ingredientsList = _detectedIngredients.join(", ");
        final response = await http.post(
          Uri.parse('https://api.x.ai/v1/chat/completions'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_grokApiKey'},
          body: jsonEncode({
            'model': 'grok-4.20-reasoning',
            'messages': [
              {'role': 'system', 'content': 'You are a professional chef. Always respond with pure JSON.'},
              {'role': 'user', 'content': 'Generate a recipe for: $ingredientsList. Format as JSON with name, ingredients, instructions, prepTime, servings, difficulty.'},
            ],
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final cleanContent = data['choices'][0]['message']['content'].replaceAll('```json', '').replaceAll('```', '').trim();
          final Map<String, dynamic> recipe = jsonDecode(cleanContent);
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipeName: recipe['name'], recipeDetails: recipe)));
        }
      } catch (e) {
        _showError("AI Error: $e");
      } finally {
        if (mounted) setState(() => _isGenerating = false);
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            expandedHeight: 200.0,
            pinned: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/cookify_logo.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Text('Cookify', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showApiKeySetupDialog(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key updated successfully!'), backgroundColor: Colors.green),
                  );
                }),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset('assets/images/header.jpg', fit: BoxFit.cover, colorBlendMode: BlendMode.darken, color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildImageUploader(),
                const SizedBox(height: 24),
                _buildManualIngredientInput(),
                const SizedBox(height: 24),
                _buildDetectedIngredients(),
                const SizedBox(height: 16),
                _buildCaloriesEstimator(),
                const SizedBox(height: 24),
                _buildRecipeFilter(),
                const SizedBox(height: 10),
                if (_isLoading || _isGenerating) Center(child: CircularProgressIndicator()),
                if (!_isLoading && !_isGenerating) ...[
                  _buildRecipeList(),
                  const SizedBox(height: 24),
                  _buildAiGenerationSection(),
                  const SizedBox(height: 40),
                ],
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFitnessFab(),
    );
  }

  Widget _buildAiGenerationSection() {
    if (_detectedIngredients.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFD32F2F), Colors.orange.shade800]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text("Try AI Recipe Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ElevatedButton(onPressed: _isGenerating ? null : _generateAiRecipe, child: const Text("Generate")),
        ],
      ),
    ).animate().fade();
  }

  Widget _buildFitnessFab() {
    return GestureDetector(
      onTap: () => _checkAndPromptApiKey(onProceed: () {
        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => FitnessChatWidget(grokApiKey: _grokApiKey));
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00BFA5), Color(0xFF4CAF50)]), borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.fitness_center, color: Colors.white), const SizedBox(width: 8), Text("Fitness AI", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold))]),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds);
  }

  Widget _buildImageUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Images", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: _imageFiles.isEmpty
              ? Center(child: Text("No images selected"))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.network(_imageFiles[i].path, width: 120, height: 120, fit: BoxFit.cover) : Image.file(File(_imageFiles[i].path), width: 120, height: 120, fit: BoxFit.cover)),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(onPressed: () => _getImage(ImageSource.camera), icon: Icon(Icons.camera), label: Text("Camera")), ElevatedButton.icon(onPressed: () => _getImage(ImageSource.gallery), icon: Icon(Icons.photo), label: Text("Gallery"))]),
      ],
    );
  }

  Widget _buildManualIngredientInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Add Ingredients", style: Theme.of(context).textTheme.titleLarge),
        TextField(
          controller: _manualIngredientController,
          onSubmitted: _addManualIngredient,
          decoration: InputDecoration(hintText: 'e.g., chicken, spices', suffixIcon: IconButton(icon: Icon(Icons.add), onPressed: () => _addManualIngredient(_manualIngredientController.text))),
        ),
      ],
    );
  }

  Widget _buildDetectedIngredients() {
    if (_detectedIngredients.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: _detectedIngredients.map((ing) => Chip(label: Text(ing), onDeleted: () => setState(() { _detectedIngredients.remove(ing); _findMatchingRecipes(); }))).toList(),
    );
  }

  Widget _buildCaloriesEstimator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Calories Estimator", style: TextStyle(fontWeight: FontWeight.bold)),
            ..._detectedIngredients.map((ing) => Row(children: [Expanded(child: Text(ing)), SizedBox(width: 60, child: TextField(controller: _gramsControllers[ing], keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'grams'), onChanged: (_) => setState(() {})))] )),
            Text("Total: ${_totalEstimatedCalories().toStringAsFixed(1)} kcal"),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeFilter() {
    return Row(
      children: [
        Text("Strict Match"),
        Switch(value: _isStrictFilter, onChanged: (v) => setState(() { _isStrictFilter = v; _findMatchingRecipes(); })),
      ],
    );
  }

  Widget _buildRecipeList() {
    if (_matchingRecipes.isEmpty) return Center(child: Text("No matching recipes found"));
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _matchingRecipes.length,
      itemBuilder: (context, i) {
        final name = _matchingRecipes[i];
        return ListTile(title: Text(name), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipeName: name, recipeDetails: _recipes[name]))));
      },
    );
  }
}
