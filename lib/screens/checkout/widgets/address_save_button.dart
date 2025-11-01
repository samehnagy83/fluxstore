import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';

/// Address save button widget
/// Replaces the save button logic in main screen
class AddressSaveButton extends StatelessWidget {
  final bool isLoading;
  final bool isEditing;
  final VoidCallback? onPressed;

  const AddressSaveButton({
    super.key,
    required this.isLoading,
    required this.isEditing,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.save),
          label: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isEditing
                      ? S.of(context).updateAddress
                      : S.of(context).saveAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
