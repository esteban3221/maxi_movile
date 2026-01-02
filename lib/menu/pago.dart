import 'package:flutter/material.dart';
import 'pagoManual.dart';
import 'pagoAuto.dart';

class PagosPageCompact extends StatefulWidget {
  const PagosPageCompact({super.key});

  @override
  _PagosPageCompactState createState() => _PagosPageCompactState();
}

class _PagosPageCompactState extends State<PagosPageCompact> {
  bool _modoAutomatico = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector compacto
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, color: Colors.grey),
                const SizedBox(width: 12),
                const Text(
                  'Modo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Manual'),
                  selected: !_modoAutomatico,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _modoAutomatico = false;
                      });
                    }
                  },
                  selectedColor: Colors.blue,
                  // labelStyle: TextStyle(
                  //   color: !_modoAutomatico ? Colors.white : Colors.black,
                  // ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Automático'),
                  selected: _modoAutomatico,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _modoAutomatico = true;
                      });
                    }
                  },
                  selectedColor: Colors.green,
                  // labelStyle: TextStyle(
                  //   color: _modoAutomatico ? Colors.white : Colors.black,
                  // ),
                ),
              ],
            ),
          ),
        ),

        // Vista correspondiente
        Expanded(child: _modoAutomatico ? PagoAutoPage() : PagoManualView()),
      ],
    );
  }
}
