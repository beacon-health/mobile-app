import 'package:flutter/material.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';

class CriteriaPage extends StatefulWidget {
  const CriteriaPage({super.key});

  @override
  State<CriteriaPage> createState() => _CriteriaPageState();
}

class _CriteriaPageState extends State<CriteriaPage> {
  int? _selectedMonth;
  int? _selectedYear;
  TextEditingController _zipCodeController = TextEditingController();
  String? _selectedEmployment;
  double _income = 0;
  String? _selectedGender;
  String? _selectedHouseholdSize;
  String? _selectedCitizenship;
  String? _selectedStudent;
  String? _selectedLGBTQ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 50.0),
            const Text(
              'Help us help you.',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'We will never share your data without your permission. All fields are entirely optional but will help us find better resources for you.',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            const Text('Age', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Month'),
                            content: SingleChildScrollView(
                              child: Column(
                                children: List.generate(12, (index) {
                                  final month = index + 1;
                                  return ListTile(
                                    title: Text('$month'),
                                    onTap: () {
                                      setState(() {
                                        _selectedMonth = month;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedMonth?.toString() ?? 'Month',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.black54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Year'),
                            content: SingleChildScrollView(
                              child: Column(
                                children: List.generate(
                                  DateTime.now().year - 1900 + 1,
                                  (index) {
                                    final year = 1900 + index;
                                    return ListTile(
                                      title: Text('$year'),
                                      onTap: () {
                                        setState(() {
                                          _selectedYear = year;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedYear?.toString() ?? 'Year',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text('Zip Code',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  width: 0.6,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: _zipCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter your zip code',
                  hintStyle: TextStyle(
                    color: Colors.black87,
                    fontSize: 14.0,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  border: InputBorder.none,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14.0,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Employment Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Select Employment Status'),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            'Employed',
                            'Unemployed',
                            'Student',
                            'Retired',
                            'Disabled',
                            'Other'
                          ]
                              .map((status) => ListTile(
                                    title: Text(status),
                                    onTap: () {
                                      setState(() {
                                        _selectedEmployment = status;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedEmployment ?? 'Select employment status',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Annual Income',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 0.6),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: _income,
                    min: 0,
                    max: 200000,
                    divisions: 20,
                    label: '\$${_income.round()}',
                    onChanged: (double value) {
                      setState(() {
                        _income = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '\$${_income.round()} per year',
                    style:
                        const TextStyle(fontSize: 16.0, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Select Gender'),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            'Male',
                            'Female',
                            'Non-binary',
                            'Prefer not to say',
                            'Other'
                          ]
                              .map((gender) => ListTile(
                                    title: Text(gender),
                                    onTap: () {
                                      setState(() {
                                        _selectedGender = gender;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedGender ?? 'Select gender',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Household Size',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Select Household Size'),
                      content: SingleChildScrollView(
                        child: Column(
                          children: List.generate(10, (index) {
                            final size = (index + 1).toString();
                            return ListTile(
                              title: Text(
                                  '$size ${int.parse(size) == 1 ? 'person' : 'people'}'),
                              onTap: () {
                                setState(() {
                                  _selectedHouseholdSize = size;
                                });
                                Navigator.of(context).pop();
                              },
                            );
                          }),
                        ),
                      ),
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedHouseholdSize != null
                          ? '$_selectedHouseholdSize ${int.parse(_selectedHouseholdSize!) == 1 ? 'person' : 'people'}'
                          : 'Select household size',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Citizenship Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Select Citizenship Status'),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            'US Citizen',
                            'Permanent Resident',
                            'Visa Holder',
                            'Undocumented',
                            'Prefer not to say'
                          ]
                              .map((status) => ListTile(
                                    title: Text(status),
                                    onTap: () {
                                      setState(() {
                                        _selectedCitizenship = status;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCitizenship ?? 'Select citizenship status',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Student Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Select Student Status'),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            'Yes, full-time student',
                            'Yes, part-time student',
                            'No, not a student',
                            'Prefer not to say'
                          ]
                              .map((status) => ListTile(
                                    title: Text(status),
                                    onTap: () {
                                      setState(() {
                                        _selectedStudent = status;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedStudent ?? 'Are you currently a student?',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('LGBTQ+ Community Member',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('LGBTQ+ Community Member'),
                      content: SingleChildScrollView(
                        child: Column(
                          children: ['Yes', 'No', 'Prefer not to say']
                              .map((status) => ListTile(
                                    title: Text(status),
                                    onTap: () {
                                      setState(() {
                                        _selectedLGBTQ = status;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedLGBTQ ??
                          'Are you a member of the LGBTQ+ community?',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainNavBar()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainNavBar()),
                );
              },
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
