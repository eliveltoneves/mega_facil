import 'package:flutter/material.dart';

class NumberGrid extends StatefulWidget {
  final Set<int> initial;
  final int max;
  final ValueChanged<Set<int>> onChanged;
  const NumberGrid({super.key, required this.initial, required this.max, required this.onChanged});

  @override
  State<NumberGrid> createState() => _NumberGridState();
}

class _NumberGridState extends State<NumberGrid> {
  late Set<int> _sel;

  @override
  void initState() {
    _sel = {...widget.initial};
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10, childAspectRatio: 1.2, mainAxisSpacing: 6, crossAxisSpacing: 6),
      itemCount: 60,
      itemBuilder: (_, i) {
        final n = i + 1;
        final chosen = _sel.contains(n);
        return InkWell(
          onTap: () {
            setState(() {
              if (chosen) {
                _sel.remove(n);
              } else if (_sel.length < widget.max) {
                _sel.add(n);
              }
              widget.onChanged(_sel);
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chosen ? Colors.green.shade700 : Colors.white,
              border: Border.all(color: chosen ? Colors.green.shade700 : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(n.toString().padLeft(2,'0'),
              style: TextStyle(color: chosen ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}
