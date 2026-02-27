import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A page presenting the Hajj guide with steps, checkboxes, and progress.
class HajjPage extends StatefulWidget {
  const HajjPage({super.key});
  @override
  State<HajjPage> createState() => _HajjPageState();
}

class _HajjPageState extends State<HajjPage> {
  final List<Map<String, String>> _stepsData = [
    {
      'title': 'Ihram',
      'desc':
          'Enter the sacred state by wearing the white garments and making the intention for Hajj.',
      'dua':
          'Labbayka Allahumma Labbayk. Labbayka laa shareeka Laka, labbayk. Innal-hamda wan-n`imata Laka wal-mulk laa shareeka Lak.',
    },
    {
      'title': 'Tawaf',
      'desc':
          'Circumambulate the Kaaba seven times in a counter-clockwise direction.',
      'dua': 'Rabbana taqabbal minna innaka Anta al-Samee`u al-`Aleem.',
    },
    {
      'title': 'Sa\'i',
      'desc': 'Walk seven times between the hills of Safa and Marwah.',
      'dua':
          'La ilaha illa Allah wahdahu la sharika lah lahul-mulk wa lahul-hamd wa huwa ala kulli shay’in qadeer.',
    },
    {
      'title': 'Arafat',
      'desc':
          'Stand in prayer and supplication at the plain of Arafat on the 9th day.',
      'dua': 'Allahumma ighfir lil-mu’minina wal-mu’minat.',
    },
    {
      'title': 'Muzdalifah',
      'desc': 'Collect pebbles and pray the night prayer under the open sky.',
      'dua': 'Rabbana taqabbal minni waj\'alna minal-adhkareen.',
    },
    {
      'title': 'Ramy al-Jamarat',
      'desc':
          'Throw stones at the three pillars symbolizing the rejection of evil.',
      'dua': 'Bismillah, Allahu Akbar.',
    },
    {
      'title': 'Eid al-Adha & Sacrifice',
      'desc': 'Offer an animal sacrifice and share meat with the needy.',
      'dua': 'Allahumma taqabbal minni.',
    },
    {
      'title': 'Tawaf al-Ifadah',
      'desc': 'Perform another circumambulation of the Kaaba after Eid.',
      'dua': 'Rabbana taqabbal minna innaka Anta al-Samee`u al-`Aleem.',
    },
    {
      'title': 'Shaving/Cutting Hair',
      'desc': 'Men shave or trim hair; women cut a small portion.',
      'dua': 'Alhamdulillahil-ladhi ‘afani wa fadhlani.',
    },
    {
      'title': 'Tawaf al-Wada',
      'desc': 'Perform the farewell Tawaf before leaving Mecca.',
      'dua': 'Allahumma inni as’aluka hubbaka wa hubba man yuhibbuka.',
    },
  ];
  late List<bool> _completed;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _completed = List.filled(_stepsData.length, false);
    _loadCompletionState();
  }

  Future<void> _loadCompletionState() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _stepsData.length; i++) {
      _completed[i] = prefs.getBool('hajjStep_$i') ?? false;
    }
    setState(() {});
  }

  Future<void> _toggleStep(int index, bool? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _completed[index] = value);
    await prefs.setBool('hajjStep_$index', value);
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completed.where((c) => c).length;
    final progress = completedCount / _stepsData.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hajj Guide'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LinearProgressIndicator(value: progress),
          ),
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepTapped: (i) => setState(() => _currentStep = i),
              onStepContinue: () {
                if (_currentStep < _stepsData.length - 1) {
                  setState(() => _currentStep++);
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              steps: List.generate(_stepsData.length, (i) {
                final data = _stepsData[i];
                return Step(
                  title: Text(data['title']!),
                  state: _completed[i] ? StepState.complete : StepState.indexed,
                  isActive: i == _currentStep,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            'Wireframe: ${data['title']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(data['desc']!),
                      const SizedBox(height: 8),
                      Text(
                        'Dua: ${data['dua']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      CheckboxListTile(
                        value: _completed[i],
                        title: const Text('Completed'),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (v) => _toggleStep(i, v),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
