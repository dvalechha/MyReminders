import 'package:flutter/material.dart';

class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectionCount;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final String titleSuffix;

  const SelectionAppBar({
    super.key,
    required this.selectionCount,
    required this.onClearSelection,
    required this.onDeleteSelected,
    this.titleSuffix = 'Selected',
  });

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2D62ED);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            height: preferredSize.height,
            child: Row(
              children: [
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: brandBlue),
                  onPressed: onClearSelection,
                  tooltip: 'Clear selection',
                ),
                
                const SizedBox(width: 8),
                
                // Selection count
                Expanded(
                  child: Text(
                    '$selectionCount $titleSuffix',
                    style: const TextStyle(
                      color: brandBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: brandBlue),
                  onPressed: onDeleteSelected,
                  tooltip: 'Delete selected',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
