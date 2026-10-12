import 'package:flutter/material.dart';

class CommunityShimmer extends StatefulWidget {
  const CommunityShimmer({super.key});
  @override
  State<CommunityShimmer> createState() => _CommunityShimmerState();
}

class _CommunityShimmerState extends State<CommunityShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget block({double? width, double height = 12}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Semantics(
      label: 'Loading community posts',
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-2 + 4 * _controller.value, 0),
                end: Alignment(-1 + 4 * _controller.value, 0),
                colors: [
                  colors.surfaceContainerHighest,
                  colors.surface,
                  colors.surfaceContainerHighest,
                ],
              ).createShader(bounds),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 4,
                itemBuilder: (context, index) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            block(width: 38, height: 38),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  block(width: 140),
                                  const SizedBox(height: 8),
                                  block(width: 90, height: 9),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        block(),
                        const SizedBox(height: 8),
                        block(),
                        const SizedBox(height: 8),
                        block(width: 170),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            block(width: 65),
                            block(width: 65),
                            block(width: 65),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
