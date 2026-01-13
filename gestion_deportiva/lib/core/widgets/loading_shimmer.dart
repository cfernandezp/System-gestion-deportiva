import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/app_colors.dart';

/// Widget de shimmer loading que respeta el tema Light/Dark
/// Usar para mostrar placeholders mientras se cargan datos
class LoadingShimmer extends StatefulWidget {
  /// Constructor principal
  const LoadingShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// Widget hijo que define la forma del shimmer
  final Widget child;

  /// Si el shimmer esta activo
  final bool enabled;

  /// Color base del shimmer
  final Color? baseColor;

  /// Color de highlight del shimmer
  final Color? highlightColor;

  /// Duracion de la animacion
  final Duration duration;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final isDark = AppColors.isDarkMode(context);

    final baseColor = widget.baseColor ??
        (isDark
            ? DesignTokens.darkSurfaceVariant
            : DesignTokens.lightSurfaceVariant);

    final highlightColor = widget.highlightColor ??
        (isDark
            ? DesignTokens.darkSurface.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Placeholder rectangular para shimmer
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  /// Ancho (null = expandir)
  final double? width;

  /// Alto
  final double height;

  /// Radio de bordes
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final color = isDark
        ? DesignTokens.darkSurfaceVariant
        : DesignTokens.lightSurfaceVariant;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          borderRadius ?? DesignTokens.radiusXs,
        ),
      ),
    );
  }
}

/// Placeholder circular para avatares
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final color = isDark
        ? DesignTokens.darkSurfaceVariant
        : DesignTokens.lightSurfaceVariant;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Card shimmer para listas
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.height = 80,
    this.hasAvatar = true,
    this.linesCount = 2,
  });

  final double height;
  final bool hasAvatar;
  final int linesCount;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            if (hasAvatar) ...[
              const ShimmerCircle(size: 48),
              const SizedBox(width: DesignTokens.spacingM),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  linesCount,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index < linesCount - 1 ? DesignTokens.spacingS : 0,
                    ),
                    child: ShimmerPlaceholder(
                      width: index == 0 ? null : 150,
                      height: index == 0 ? 16 : 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de shimmer cards
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.hasAvatar = true,
    this.spacing = DesignTokens.spacingS,
  });

  final int itemCount;
  final double itemHeight;
  final bool hasAvatar;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (context, index) => ShimmerCard(
        height: itemHeight,
        hasAvatar: hasAvatar,
      ),
    );
  }
}

/// Grid de shimmer para estadisticas
class ShimmerStatGrid extends StatelessWidget {
  const ShimmerStatGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
  });

  final int crossAxisCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: DesignTokens.spacingS,
          crossAxisSpacing: DesignTokens.spacingS,
          childAspectRatio: 1.2,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerCircle(size: 36),
              Spacer(),
              ShimmerPlaceholder(width: 60, height: 24),
              SizedBox(height: DesignTokens.spacingXs),
              ShimmerPlaceholder(width: 100, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer para formularios
class ShimmerForm extends StatelessWidget {
  const ShimmerForm({
    super.key,
    this.fieldCount = 4,
  });

  final int fieldCount;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          fieldCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerPlaceholder(width: 80, height: 12),
                const SizedBox(height: DesignTokens.spacingXs),
                ShimmerPlaceholder(
                  height: 48,
                  borderRadius: DesignTokens.radiusS,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
