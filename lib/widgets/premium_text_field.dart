import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final int maxLines;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  double _calculatePasswordStrength() {
    if (_password.isEmpty) return 0.0;
    if (_password.length < 6) return 0.2; // Very weak

    double score = 0.4; // Met minimum length
    bool hasLetters = _password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumbers = _password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = _password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasUpper = _password.contains(RegExp(r'[A-Z]'));

    if (hasLetters && hasNumbers) score += 0.3; // Medium
    if (hasSpecial || (hasLetters && hasNumbers && hasUpper && _password.length >= 8)) {
      score += 0.3; // Strong
    }

    return score.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.2) return AppColors.error;
    if (strength <= 0.7) return AppColors.warning;
    return AppColors.success;
  }

  String _getStrengthText(double strength) {
    if (strength <= 0.0) return '';
    if (strength <= 0.2) return 'Weak (too short)';
    if (strength <= 0.7) return 'Medium (add uppercase/special chars)';
    return 'Strong password!';
  }

  @override
  Widget build(BuildContext context) {
    final double strength = _calculatePasswordStrength();
    final Color strengthColor = _getStrengthColor(strength);
    final String strengthText = _getStrengthText(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.isPassword
                    ? AppColors.primary.withValues(alpha: _isFocused ? 0.2 : 0.0)
                    : AppColors.secondary.withValues(alpha: _isFocused ? 0.2 : 0.0),
                spreadRadius: _isFocused ? 3.0 : 0.0,
                blurRadius: _isFocused ? 8.0 : 0.0,
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            onChanged: (val) {
              if (widget.isPassword) {
                setState(() {
                  _password = val;
                });
              }
              if (widget.onChanged != null) {
                widget.onChanged!(val);
              }
            },
            validator: widget.validator,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused
                    ? (widget.isPassword ? AppColors.primary : AppColors.secondary)
                    : AppColors.textMuted,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _isFocused ? AppColors.primary : AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface.withValues(alpha: _isFocused ? 0.6 : 0.35),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isPassword
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : AppColors.secondary.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.surfaceLight.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isPassword ? AppColors.primary : AppColors.secondary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        if (widget.isPassword && _password.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        width: MediaQuery.of(context).size.width * 0.8 * strength,
                        decoration: BoxDecoration(
                          color: strengthColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  strengthText,
                  style: TextStyle(
                    color: strengthColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
