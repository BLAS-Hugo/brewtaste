import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SvgPicture.asset(
                'assets/images/beer.svg',
                height: 220,
                colorFilter: ColorFilter.mode(
                  colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              const Spacer(),
              Text(
                'BrewTaste',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                "Dégustations à l'aveugle entre amis",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () => context.push('/session/create'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Créer une session'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/session/join'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text('Rejoindre une session'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
