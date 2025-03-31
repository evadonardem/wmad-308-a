import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer' as developer;
import 'dart:ui';
import '../main.dart';

class AdoptedDogsPage extends StatefulWidget {
  const AdoptedDogsPage(
      {super.key, required this.adoptedDogs, required this.giveAwayDogs, required this.showNotification});

  final List<AdoptedDog> adoptedDogs;
  final List<GiveAwayDog> giveAwayDogs;
  final void Function(String) showNotification;

  @override
  AdoptedDogsPageState createState() => AdoptedDogsPageState();
}

class AdoptedDogsPageState extends State<AdoptedDogsPage> {
  List<double> _scaleList = [];
  String? _hoveredButton;

  @override
  void initState() {
    super.initState();
    _updateScaleList();
    _animateGrids();
  }

  @override
  void didUpdateWidget(covariant AdoptedDogsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adoptedDogs.length != widget.adoptedDogs.length) {
      _updateScaleList();
      _animateGrids();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    resetAnimation();
  }

  void resetAnimation() {
    setState(() {
      _scaleList = List.generate(widget.adoptedDogs.length, (_) => 0.0); 
    });
    _animateGrids(); 
  }

  void _updateScaleList() {
    
    _scaleList = List.generate(widget.adoptedDogs.length, (_) => 0.0);
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

  Future<void> _giveAwayDog(AdoptedDog dog, int index) async {
    final dbHelper = DatabaseHelper.instance;
    try {
      setState(() {
        _scaleList[index] = 0.0; 
      });
      await Future.delayed(const Duration(milliseconds: 300)); 
      await dbHelper.insertGiveAwayDog(GiveAwayDog(
        breed: dog.breed,
        imageUrl: dog.imageUrl,
        name: dog.name,
      ));
      await dbHelper.deleteAdoptedDog(dog.name);
      setState(() {
        widget.adoptedDogs.removeAt(index);
        widget.giveAwayDogs.add(GiveAwayDog(
          breed: dog.breed,
          imageUrl: dog.imageUrl,
          name: dog.name,
        )); 
        _scaleList.removeAt(index); 
      });
      widget.showNotification('You have given away ${dog.name}');
    } catch (e) {
      developer.log('Error giving away dog: $e', level: 1);
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
                  'Adopted Dogs',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 30, fontFamily: 'Orbitron'),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: widget.adoptedDogs.isEmpty
                      ? const Center(
                          child: Text(
                            'No adopted dogs',
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
                                final dog = widget.adoptedDogs[index];
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
                                              onEnter: (_) => setState(() => _hoveredButton = 'giveaway_$index'),
                                              onExit: (_) => setState(() => _hoveredButton = null),
                                              child: ElevatedButton.icon(
                                                onPressed: () => _giveAwayDog(dog, index),
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
                                                icon: const FaIcon(FontAwesomeIcons.gift, size: 16),
                                                label: const Text('Give Away', style: TextStyle(fontFamily: 'Orbitron')),
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
