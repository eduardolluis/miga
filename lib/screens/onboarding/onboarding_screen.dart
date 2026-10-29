import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_screen.dart';
import 'onboarding_page.dart';
import 'onboarding_page_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    if (_isAnimating || !_pageController.hasClients) return;

    _isAnimating = true;
    try {
      await _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _isAnimating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pages = OnboardingPageData.fromLocalizations(l10n);
    final isLastPage = _currentPage == pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1710),
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: OnboardingBackground(
                key: ValueKey(pages[_currentPage].imagePath),
                page: pages[_currentPage],
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Column(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.4,
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.eco_rounded,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'miga',
                                                style: theme
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: -1,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          disabledForegroundColor:
                                              Colors.white54,
                                        ),
                                        onPressed: isLastPage
                                            ? null
                                            : () => _goToPage(pages.length - 1),
                                        child: Text(l10n.skip),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.onboardingIntro,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: pages.length,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemBuilder: (context, index) {
                              return OnboardingPage(
                                key: ValueKey(pages[index].imagePath),
                                page: pages[index],
                              );
                            },
                          ),
                        ),
                        _PageIndicator(
                          pageCount: pages.length,
                          currentPage: _currentPage,
                          onSelected: _goToPage,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primaryContainer,
                                foregroundColor: colors.onPrimaryContainer,
                                minimumSize: const Size.fromHeight(56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              onPressed: () {
                                if (_isAnimating) return;
                                if (isLastPage) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AuthScreen(),
                                    ),
                                  );
                                } else {
                                  _goToPage(_currentPage + 1);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      isLastPage
                                          ? l10n.createAccount
                                          : l10n.next,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.pageCount,
    required this.currentPage,
    required this.onSelected,
  });

  final int pageCount;
  final int currentPage;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.white;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isSelected = currentPage == index;

        return Semantics(
          label: l10n.onboardingStep(index + 1, pageCount),
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
