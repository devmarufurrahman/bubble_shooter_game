import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/utils.dart';
import '../../data/repositories/repositories.dart';
import '../../ui/game_screen.dart';
import '../../ui/widgets/arcade_background.dart';
import '../overlays/overlays.dart';

/// Clean alias for backward-compatibility with existing LevelSelectScreen references.
typedef LevelSelectScreen = StageSelectScreen;

/// Screen allowing players to choose from 10 arcade stages, inspect high scores,
/// view earned star ratings, manage preferences, and inspect their profile.
class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({super.key});

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  final AuthRepository _authRepository = AuthRepository();

  int _unlockedLevel = 1;
  final Map<int, int> _highScores = {};
  final Map<int, int> _starsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  /// Reads unlocked level progress, high scores, and earned stars for all 10 levels,
  /// then triggers a reactive UI rebuild.
  Future<void> _loadProgress() async {
    final int unlocked = await LevelRepository.getUnlockedLevel();
    final Map<int, int> scores = {};
    final Map<int, int> stars = {};

    for (int i = 1; i <= LevelRepository.totalLevels; i++) {
      scores[i] = await LevelRepository.getHighScore(i);
      stars[i] = await LevelRepository.getStars(i);
    }

    if (mounted) {
      setState(() {
        _unlockedLevel = unlocked;
        _highScores
          ..clear()
          ..addAll(scores);
        _starsMap
          ..clear()
          ..addAll(stars);
        _isLoading = false;
      });
    }
  }

  /// Launches the selected stage and automatically re-fetches latest stars & score upon return.
  Future<void> _openLevel(int level) async {
    HapticsHelper.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(levelNumber: level),
      ),
    );
    _loadProgress();
  }

  Future<void> _confirmSignOut() async {
    HapticsHelper.selectionClick();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131A33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFF007F), width: 1.5),
          ),
          title: const Text(
            'LOG OUT',
            style: TextStyle(
              color: Color(0xFFFF007F),
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your arcade session?',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticsHelper.selectionClick();
                Navigator.of(context).pop(false);
              },
              child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF007F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                HapticsHelper.heavyImpact();
                Navigator.of(context).pop(true);
              },
              child: const Text('LOG OUT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _authRepository.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _authRepository.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: ArcadeBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Profile & App Bar Header
              _StageSelectHeader(
                user: user,
                onSignOutPressed: _confirmSignOut,
                onSettingsPressed: () {
                  HapticsHelper.selectionClick();
                  SettingsDialog.show(
                    context,
                    onProgressReset: _loadProgress,
                  );
                },
              ),

              const SizedBox(height: 8),

              // Title Header & Campaign Progress Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'STAGE SELECT',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.2,
                                shadows: [
                                  Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            'CHALLENGE STAGES 01 - 10',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF19203C),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$_unlockedLevel/10 UNLOCKED',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFFD600),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF1F2B4C), height: 16, thickness: 1),

              // Level Cards Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final double availableWidth = constraints.maxWidth;
                          final int crossAxisCount = availableWidth > 700
                              ? 4
                              : (availableWidth > 500 ? 3 : 2);

                          // Responsive padding and item spacing
                          final double horizontalPadding = availableWidth < 360 ? 12.0 : 16.0;
                          final double itemSpacing = 14.0;
                          final double cardWidth = (availableWidth -
                                  (horizontalPadding * 2) -
                                  ((crossAxisCount - 1) * itemSpacing)) /
                              crossAxisCount;
                          // Dynamically scale card aspect ratio between 0.88 and 1.05
                          final double childAspectRatio =
                              (cardWidth / (cardWidth * 1.08)).clamp(0.88, 1.05);

                          return CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  8,
                                  horizontalPadding,
                                  24,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: itemSpacing,
                                    mainAxisSpacing: itemSpacing,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final int level = index + 1;
                                      final bool isUnlocked = level <= _unlockedLevel;
                                      final int score = _highScores[level] ?? 0;
                                      final int stars = _starsMap[level] ?? 0;

                                      return _LevelGridCard(
                                        level: level,
                                        isUnlocked: isUnlocked,
                                        highScore: score,
                                        stars: stars,
                                        onTap: () => _openLevel(level),
                                      );
                                    },
                                    childCount: LevelManager.totalLevels,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top Profile Header dynamically displaying registered player's Name,
/// avatar initials / photo, and session sign-out actions.
class _StageSelectHeader extends StatelessWidget {
  const _StageSelectHeader({
    required this.user,
    required this.onSignOutPressed,
    required this.onSettingsPressed,
  });

  final User? user;
  final VoidCallback onSignOutPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final String displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
            ? user!.displayName!.trim()
            : (user?.email != null && user!.email!.isNotEmpty)
                ? user!.email!.split('@').first
                : 'Pilot';

    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

    final String emailText = user?.email != null && user!.email!.isNotEmpty
        ? user!.email!
        : (user?.isAnonymous == true ? 'GUEST PILOT' : 'ONLINE');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Player Profile Pill
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0051FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user?.photoURL != null
                        ? Image.network(
                            user!.photoURL!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _DefaultAvatarLetter(initial: initial),
                          )
                        : _DefaultAvatarLetter(initial: initial),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        emailText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: user?.isAnonymous == true
                              ? const Color(0xFFFFD600)
                              : const Color(0xFF00E676),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action Buttons: Settings & Sign-Out (wrapped in FittedBox for safe shrinking)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Settings Button
                Tooltip(
                  message: 'Settings',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSettingsPressed,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF19203C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Color(0xFF00E5FF),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Sign-Out Button
                Tooltip(
                  message: 'Sign Out',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSignOutPressed,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF19203C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF007F).withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF007F).withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Color(0xFFFF007F), size: 18),
                            SizedBox(width: 4),
                            Text(
                              'EXIT',
                              style: TextStyle(
                                color: Color(0xFFFF007F),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.2,
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
        ],
      ),
    );
  }
}

class _DefaultAvatarLetter extends StatelessWidget {
  const _DefaultAvatarLetter({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

/// Visual card presenting a stage with lock/unlock status, high score, and earned stars.
class _LevelGridCard extends StatelessWidget {
  const _LevelGridCard({
    required this.level,
    required this.isUnlocked,
    required this.highScore,
    required this.stars,
    required this.onTap,
  });

  final int level;
  final bool isUnlocked;
  final int highScore;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
        highlightColor: const Color(0xFFFF007F).withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            color: isUnlocked
                ? const Color(0xFF131A33).withValues(alpha: 0.9)
                : const Color(0xFF0C101E).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnlocked
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                  : const Color(0xFF26324D).withValues(alpha: 0.4),
              width: isUnlocked ? 1.5 : 1.0,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Row: Level number + Lock/Play status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LV ${level.toString().padLeft(2, '0')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnlocked ? const Color(0xFF00E5FF) : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Icon(
                    isUnlocked ? Icons.play_circle_fill_rounded : Icons.lock_rounded,
                    color: isUnlocked ? const Color(0xFFFF007F) : Colors.white24,
                    size: 20,
                  ),
                ],
              ),

              // Center Visual: Level number & High Score (scaled dynamically)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isUnlocked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$level',
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'HIGH: $highScore',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: highScore > 0
                                    ? const Color(0xFFFFD600)
                                    : Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white24,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LOCKED',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.24),
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Bottom Star Bar: 3 stars rendered dynamically with FittedBox
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (starIndex) {
                    final bool earned = isUnlocked && starIndex < stars;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Icon(
                        earned ? Icons.star : Icons.star_border,
                        color: earned ? Colors.amber : Colors.white24,
                        size: 18,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

