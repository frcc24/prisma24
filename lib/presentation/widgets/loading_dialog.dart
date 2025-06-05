import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingDialog extends StatelessWidget {
  final VoidCallback onClose;
  const LoadingDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Stack(
        children: [
          Center(
            child: Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_j1adxtyb.json',
              width: 160,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}
