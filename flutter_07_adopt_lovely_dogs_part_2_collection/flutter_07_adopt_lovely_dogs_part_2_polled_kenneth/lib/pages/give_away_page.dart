import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer' as developer;
import 'dart:ui';
import '../main.dart';

class GiveAwayPage extends StatefulWidget {
  const GiveAwayPage({super.key, required this.giveAwayDogs, required this.showNotification});

  final List<GiveAwayDog> giveAwayDogs;
  final void Function(String) showNotification;

  @override
  GiveAwayPageState createState() => GiveAwayPageState();
}

class GiveAwayPageState extends State<GiveAwayPage> {
  List<GiveAwayDog> _giveAwayDogs = [];
  List<double> _scaleList = [];
  String? _hoveredButton;

  @override
  void initState() {
    super.initState();
    _loadGiveAwayDogs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    resetAnimation(); 
  }

  @override
  void didUpdateWidget(covariant GiveAwayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.giveAwayDogs.length != widget.giveAwayDogs.length) {
      _loadGiveAwayDogs();
    }
  }

  Future<void> _loadGiveAwayDogs() async {
    final dbHelper = DatabaseHelper.instance;
    try {
      final dogs = await dbHelper.fetchGiveAwayDogs();
      setState(() {
        _giveAwayDogs = dogs;
        _updateScaleList();
        _animateGrids();
      });
    } catch (e) {
      developer.log('Error loading give away dogs: $e', level: 1);
    }
  }

  Future<void> loadGiveAwayDogs() async {
    await _loadGiveAwayDogs(); 
  }

  void resetAnimation() {
    setState(() {
      _scaleList = List.generate(_giveAwayDogs.length, (_) => 0.0); 
    });
    _animateGrids(); 
  }

  void _updateScaleList() {
    
    _scaleList = List.generate(_giveAwayDogs.length, (_) => 0.0);
  }

  void _animateGrids() {
    for (int i = 0; i < _scaleList.length; i++) {
      Future.delayed(Duration(milliseconds: 300 * (i + 1)), () { 
        if (mounted && i < _scaleList.length) {
          setState(() {
            _scaleList[i] = 1.0; 
          });
        }
      });
    }
  }

  Future<void> _removeGiveAwayDog(GiveAwayDog dog, int index) async {
    final dbHelper = DatabaseHelper.instance;
    try {
      setState(() {
        _scaleList[index] = 0.0; 
      });
      await Future.delayed(const Duration(milliseconds: 300)); 
      await dbHelper.deleteGiveAwayDog(dog.name);
      setState(() {
        _giveAwayDogs.removeAt(index);
        _scaleList.removeAt(index); 
      });
      widget.showNotification('You have removed ${dog.name}');
    } catch (e) {
      developer.log('Error removing give away dog: $e', level: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16.0),
                const Text(
                  'Give Away Dogs',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 30, fontFamily: 'Orbitron'),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: _giveAwayDogs.isEmpty
                      ? const Center(
                          child: Text(
                            'No given away dogs',
                            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 18, fontFamily: 'Orbitron'),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 1;
                            if (constraints.maxWidth > 1200) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth > 900) {
                              crossAxisCount = 3;
                            } else if (constraints.maxWidth > 600) {
                              crossAxisCount = 2;
                            }
                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                              ),
                              itemCount: _scaleList.length, 
                              itemBuilder: (context, index) {
                                final dog = _giveAwayDogs[index];
                                return AnimatedScale(
                                  key: ValueKey(dog.name),
                                  scale: _scaleList[index],
                                  duration: const Duration(milliseconds: 500),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          border: Border.all(color: Colors.white, width: 1.0),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8.0),
                                              child: Image.network(
                                                dog.imageUrl,
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                            const SizedBox(height: 8.0),
                                            Text(
                                              'Name: ${dog.name}',
                                              style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Orbitron'),
                                            ),
                                            Text(
                                              'Breed: ${dog.breed}',
                                              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Orbitron'),
                                            ),
                                            MouseRegion(
                                              onEnter: (_) => setState(() => _hoveredButton = 'remove_$index'),
                                              onExit: (_) => setState(() => _hoveredButton = null),
                                              child: ElevatedButton.icon(
                                                onPressed: () => _removeGiveAwayDog(dog, index),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(color: Colors.white),
                                                ).copyWith(
                                                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                                                    if (states.contains(MaterialState.hovered)) return Colors.grey[800];
                                                    return Colors.black;
                                                  }),
                                                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                                                    if (states.contains(MaterialState.hovered)) return Colors.white;
                                                    return Colors.white;
                                                  }),
                                                ),
                                                icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                                                label: const Text('Remove', style: TextStyle(fontFamily: 'Orbitron')),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
