import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A sleek numeric stepper that allows both +/- buttons and direct manual editing.
class EditableQuantityStepper extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final double height;
  final double fieldWidth;

  const EditableQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.height = 32,
    this.fieldWidth = 44,
  });

  @override
  State<EditableQuantityStepper> createState() => _EditableQuantityStepperState();
}

class _EditableQuantityStepperState extends State<EditableQuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      } else {
        _commitValue();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EditableQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commitValue() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < widget.min) {
      _controller.text = '${widget.value}';
    } else if (parsed != widget.value) {
      widget.onChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement Button
          InkWell(
            onTap: () {
              if (widget.value > widget.min) {
                final newVal = widget.value - 1;
                _controller.text = '$newVal';
                widget.onChanged(newVal);
              }
            },
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              child: Icon(Icons.remove, size: 12, color: Color(0xFF64748B)),
            ),
          ),

          // Editable Number Input
          SizedBox(
            width: widget.fieldWidth,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _commitValue(),
              onChanged: (val) {
                final parsed = int.tryParse(val.trim());
                if (parsed != null && parsed >= widget.min) {
                  widget.onChanged(parsed);
                }
              },
            ),
          ),

          // Increment Button
          InkWell(
            onTap: () {
              final newVal = widget.value + 1;
              _controller.text = '$newVal';
              widget.onChanged(newVal);
            },
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              child: Icon(Icons.add, size: 12, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}
