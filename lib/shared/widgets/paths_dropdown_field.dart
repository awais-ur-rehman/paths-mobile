import 'package:flutter/material.dart';

final class PathsDropdownOption<T> {
  const PathsDropdownOption(this.value, this.label);
  final T value;
  final String label;
}

/// A form field and anchored option menu sharing the Paths input treatment.
class PathsDropdownField<T> extends FormField<T> {
  PathsDropdownField({
    required String label,
    required List<PathsDropdownOption<T>> options,
    required T? value,
    required ValueChanged<T> onChanged,
    super.enabled,
    super.validator,
    super.key,
  }) : super(
         initialValue: value,
         builder: (state) => LayoutBuilder(
           builder: (context, constraints) {
             final selected = options.where(
               (item) => item.value == state.value,
             );
             final field = state as _PathsDropdownState<T>;
             return MenuAnchor(
               childFocusNode: field.anchorFocus,
               consumeOutsideTap: true,
               onOpen: field.opened,
               onClose: field.closed,
               crossAxisUnconstrained: false,
               style: MenuStyle(
                 backgroundColor: const WidgetStatePropertyAll(Colors.white),
                 surfaceTintColor: const WidgetStatePropertyAll(
                   Colors.transparent,
                 ),
                 elevation: const WidgetStatePropertyAll(8),
                 padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
                 shape: WidgetStatePropertyAll(
                   RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(16),
                   ),
                 ),
                 side: const WidgetStatePropertyAll(
                   BorderSide(color: Color(0xFFD8E4EC)),
                 ),
                 maximumSize: WidgetStatePropertyAll(
                   Size(constraints.maxWidth, 320),
                 ),
               ),
               alignmentOffset: const Offset(0, 6),
               menuChildren: [
                 for (final (index, option) in options.indexed)
                   MenuItemButton(
                     focusNode: index == 0 ? field.firstOptionFocus : null,
                     onPressed: state.widget.enabled
                         ? () {
                             state.didChange(option.value);
                             onChanged(option.value);
                           }
                         : null,
                     style: MenuItemButton.styleFrom(
                       minimumSize: Size(constraints.maxWidth - 16, 52),
                       foregroundColor: const Color(0xFF101418),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(10),
                       ),
                     ),
                     trailingIcon: option.value == state.value
                         ? const Icon(
                             Icons.check_rounded,
                             color: Color(0xFF147DCE),
                             size: 20,
                           )
                         : null,
                     child: Text(option.label, softWrap: true),
                   ),
               ],
               builder: (context, controller, child) => PopScope(
                 canPop: !field.menuOpen,
                 onPopInvokedWithResult: (didPop, result) {
                   if (!didPop && controller.isOpen) controller.close();
                 },
                 child: Semantics(
                   button: true,
                   enabled: state.widget.enabled,
                   child: InkWell(
                     focusNode: field.anchorFocus,
                     borderRadius: BorderRadius.circular(14),
                     onTap: state.widget.enabled
                         ? () {
                             if (controller.isOpen) {
                               controller.close();
                             } else {
                               FocusScope.of(context).unfocus();
                               controller.open();
                             }
                           }
                         : null,
                     child: InputDecorator(
                       isEmpty: selected.isEmpty,
                       decoration: InputDecoration(
                         labelText: label,
                         enabled: state.widget.enabled,
                         errorText: state.errorText,
                       ),
                       child: Row(
                         children: [
                           Expanded(
                             child: Text(
                               selected.isEmpty ? '' : selected.first.label,
                             ),
                           ),
                           const SizedBox(width: 8),
                           const Icon(
                             Icons.keyboard_arrow_down_rounded,
                             size: 22,
                           ),
                         ],
                       ),
                     ),
                   ),
                 ),
               ),
             );
           },
         ),
       );

  @override
  FormFieldState<T> createState() => _PathsDropdownState<T>();
}

class _PathsDropdownState<T> extends FormFieldState<T> {
  final anchorFocus = FocusNode();
  final firstOptionFocus = FocusNode();
  bool menuOpen = false;
  void opened() {
    setState(() => menuOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && menuOpen) firstOptionFocus.requestFocus();
    });
  }

  void closed() {
    if (mounted) setState(() => menuOpen = false);
  }

  @override
  void dispose() {
    anchorFocus.dispose();
    firstOptionFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PathsDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
  }
}
