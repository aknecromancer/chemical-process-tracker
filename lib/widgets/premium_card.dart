import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

/// Premium Enterprise Card Component
/// High-end card design with professional styling and micro-interactions
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final double? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool isHoverable;
  final bool showShadow;
  final String? title;
  final Widget? trailing;
  final IconData? icon;
  final Color? iconColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.gradient,
    this.onTap,
    this.isHoverable = true,
    this.showShadow = true,
    this.title,
    this.trailing,
    this.icon,
    this.iconColor,
  });

  /// Factory constructor for KPI cards
  factory PremiumCard.kpi({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
    Color? valueColor,
    String? subtitle,
    VoidCallback? onTap,
    bool showTrend = false,
    double? trendValue,
  }) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryBlue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (showTrend && trendValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: trendValue >= 0 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendValue >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: trendValue >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trendValue.abs().toStringAsFixed(1)}%',
                        style: AppTheme.bodySmall.copyWith(
                          color: trendValue >= 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            value,
            style: AppTheme.headlineMedium.copyWith(
              color: valueColor ?? AppColors.neutral900,
              fontWeight: FontWeight.w700,
              fontFamily: AppTheme.dataFontFamily,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacing4),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Factory constructor for status cards
  factory PremiumCard.status({
    required String title,
    required String status,
    required Color statusColor,
    IconData? icon,
    String? description,
    VoidCallback? onTap,
  }) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: statusColor, size: 20),
                const SizedBox(width: AppTheme.spacing8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: AppTheme.labelMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            Text(
              description,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? AppTheme.elevationLow,
      end: (widget.elevation ?? AppTheme.elevationLow) + 4,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverChange(bool isHovered) {
    if (!widget.isHoverable) return;
    
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      widget.borderRadius ?? AppTheme.radiusLarge,
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin ?? const EdgeInsets.all(AppTheme.spacing8),
            child: Material(
              elevation: widget.showShadow ? _elevationAnimation.value : 0,
              borderRadius: borderRadius,
              shadowColor: AppColors.shadow,
              child: InkWell(
                onTap: widget.onTap,
                onHover: _onHoverChange,
                borderRadius: borderRadius,
                splashColor: AppColors.primaryBlue.withOpacity(0.1),
                highlightColor: AppColors.primaryBlue.withOpacity(0.05),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? AppColors.surface,
                    gradient: widget.gradient,
                    borderRadius: borderRadius,
                    border: widget.border ?? 
                        (_isHovered && widget.onTap != null
                            ? Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                width: 1,
                              )
                            : null),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null || widget.trailing != null || widget.icon != null)
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.spacing20,
                            AppTheme.spacing20,
                            AppTheme.spacing20,
                            AppTheme.spacing8,
                          ),
                          child: Row(
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: widget.iconColor ?? AppColors.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                              ],
                              if (widget.title != null)
                                Expanded(
                                  child: Text(
                                    widget.title!,
                                    style: AppTheme.titleMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutral900,
                                    ),
                                  ),
                                ),
                              if (widget.trailing != null)
                                widget.trailing!,
                            ],
                          ),
                        ),
                      Container(
                        padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacing20),
                        child: widget.child,
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

/// Premium Card Header Component
class PremiumCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const PremiumCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryBlue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      subtitle!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppTheme.spacing12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Premium Data Card for displaying key metrics
class PremiumDataCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? valueColor;
  final Color? iconColor;
  final double? trendValue;
  final bool showTrend;
  final VoidCallback? onTap;

  const PremiumDataCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.valueColor,
    this.iconColor,
    this.trendValue,
    this.showTrend = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: iconColor ?? AppColors.primaryBlue,
                  size: 20,
                ),
              if (showTrend && trendValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing6,
                    vertical: AppTheme.spacing2,
                  ),
                  decoration: BoxDecoration(
                    color: (trendValue! >= 0 ? AppColors.success : AppColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendValue! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: trendValue! >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trendValue!.abs().toStringAsFixed(1)}%',
                        style: AppTheme.bodySmall.copyWith(
                          color: trendValue! >= 0 ? AppColors.success : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTheme.titleLarge.copyWith(
                  color: valueColor ?? AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.dataFontFamily,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  unit!,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}