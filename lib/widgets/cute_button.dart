import 'package:flutter/material.dart';

class CuteButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;

  const CuteButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  State<CuteButton> createState() => _CuteButtonState();
}

class _CuteButtonState extends State<CuteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient:
                  widget.isPrimary
                      ? LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              color: widget.isPrimary ? null : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  widget.isPrimary
                      ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap:
                    widget.isLoading
                        ? null
                        : () {
                          _controller.forward().then((_) {
                            _controller.reverse();
                            widget.onPressed();
                          });
                        },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isPrimary
                                  ? Colors.white
                                  : Colors.blue[600]!,
                            ),
                          ),
                        )
                      else if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color:
                              widget.isPrimary
                                  ? Colors.white
                                  : Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color:
                              widget.isPrimary
                                  ? Colors.white
                                  : Colors.blue[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
