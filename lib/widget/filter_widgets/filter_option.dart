import 'package:flutter/material.dart';

class FilterOption extends StatelessWidget {
  final String label;
  final String value;
  final bool isVisible;
  final VoidCallback onToggle;
  final int itemCount;
  final Widget Function(int) itemBuilder;

  const FilterOption({
    super.key,
    required this.label,
    required this.value,
    required this.isVisible,
    required this.onToggle,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: isVisible ? itemCount == 12 ? (itemCount / 2)*65 : (itemCount / 2)*85 : 100,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.02,
              vertical: screenHeight * 0.01,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onToggle,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    value.length > 10 ? '${value.substring(0, 10)}...' : value,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.black87,
                    ),
                  )
                ],
              ),
            ),
          ),
          isVisible
              ? Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Numero di colonne
                crossAxisSpacing: 1.0, // Spaziatura tra le colonne
                mainAxisSpacing: 1.0, // Spaziatura tra le righe
                childAspectRatio: 3,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) => itemBuilder(index),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          )
              : const SizedBox(),
        ],
      ),
    );
  }
}
