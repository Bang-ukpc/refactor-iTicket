import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownSearch<int>(
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        label: Text(
                          'haha',
                        ),
                        hintText: 'Select',
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      fit: FlexFit.loose,
                      constraints: const BoxConstraints(maxHeight: 200),
                      itemBuilder: (context, item, isSelected) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.toString()),
                            const Text('ao ma'),
                          ],
                        ),
                      ),
                    ),
                    items: const [],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: DropdownSearch<int>(
                    items: List.generate(50, (i) => i),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
