import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quantum_qube/lottery_number_display.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int? _randomNumber;
  bool _isLoading = false;
  String? _error;
  int _selectedDigits = 6;

  late AnimationController _spinController;
  
  bool _showRoulette = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }


  void _startRouletteAnimation() {
    _spinController.reset();
    _spinController.forward().whenComplete(() {
      setState(() {
        _showRoulette = false;
      });
    });
  }

  Future<void> _fetchQuantumRandomNumber() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _randomNumber = null;
      _showRoulette = true;
    });
    _startRouletteAnimation();

    int digits = _selectedDigits;
    try {
      final uri = Uri.parse('http://localhost:8000/random');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'digits': digits}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int? randomNumber;
        if (data is Map && data.containsKey('random_number')) {
          randomNumber = data['random_number'] is int
              ? data['random_number']
              : int.tryParse(data['random_number'].toString());
        }
        if (randomNumber != null) {
          setState(() {
            _randomNumber = randomNumber;
          });
        } else {
          setState(() {
            _error = 'Invalid response from backend.';
          });
        }
      } else {
        setState(() {
          _error = 'Backend error: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch number: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Quantum Lottery', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF512DA8), Color(0xFF7C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'How many digits?',
                    style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: List.generate(6, (i) {
                      int d = i + 1;
                      return ChoiceChip(
                        label: Text('$d', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        selected: _selectedDigits == d,
                        selectedColor: Colors.amber,
                        backgroundColor: Colors.white10,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDigits = d;
                          });
                        },
                        labelStyle: TextStyle(
                          color: _selectedDigits == d ? Colors.black : Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  LotteryNumberDisplay(
  number: _randomNumber ?? 0,
  animate: !_showRoulette && !_isLoading,
  key: ValueKey(_randomNumber),
  digitCount: _selectedDigits,
),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchQuantumRandomNumber,
                    icon: const Icon(Icons.bolt, size: 28, color: Colors.amber),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text(
                        _isLoading ? 'Generating...' : 'Generate Quantum Number',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                  ),
                  const SizedBox(height: 34),
                  if (_randomNumber != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.blueAccent, Colors.purpleAccent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Your Quantum Lottery Number', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 18)),
                          const SizedBox(height: 12),
                          LotteryNumberDisplay(
                            number: _randomNumber ?? 0,
                            animate: !_showRoulette && !_isLoading,
                            key: ValueKey(_randomNumber),
                            digitCount: _selectedDigits,
                          ),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 32),
                  const Text(
                    'Powered by Quantum Randomness',
                    style: TextStyle(color: Colors.white38, fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
