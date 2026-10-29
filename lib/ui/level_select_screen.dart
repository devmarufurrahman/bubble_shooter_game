import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../levels/level_manager.dart';
import 'game_screen.dart';
import 'widgets/arcade_background.dart';

/// Screen allowing players to choose from 10 arcade levels, inspect high scores,
/// view earned star ratings, and manage their authentication state.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final AuthService _authService = AuthService.instance;

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
    final int unlocked = await LevelManager.getUnlockedLevel();
    final Map<int, int> scores = {};
    final Map<int, int> stars = {};

    for (int i = 1; i <= LevelManager.totalLevels; i++) {
      scores[i] = await LevelManager.getHighScore(i);
      stars[i] = await LevelManager.getStars(i);
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(levelNumber: level),
      ),
    );
    _loadProgress();
  }

  Future<void> _confirmSignOut() async {
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
              onPressed: () => Navigator.of(context).pop(false),
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
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('LOG OUT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: ArcadeBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Profile & App Bar Header
              _LevelSelectHeader(
                user: user,
                onSignOutPressed: _confirmSignOut,
              ),

              const SizedBox(height: 8),

              // Title Header & Campaign Progress Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STAGE SELECT',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            shadows: [
                              Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
                            ],
                          ),
                        ),
                        Text(
                          'CHALLENGE STAGES 01 - 10',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF19203C),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_unlockedLevel/10 UNLOCKED',
                            style: const TextStyle(
                              color: Color(0xFFFFD600),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
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
                          final int crossAxisCount = constraints.maxWidth > 700
                              ? 4
                              : (constraints.maxWidth > 500 ? 3 : 2);

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.94,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: LevelManager.totalLevels,
                            itemBuilder: (context, index) {
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

/// Top Profile Header displaying user avatar and sign-out action.
class _LevelSelectHeader extends StatelessWidget {
  const _LevelSelectHeader({
    required this.user,
    required this.onSignOutPressed,
  });

  final User? user;
  final VoidCallback onSignOutPressed;

  @override
  Widget build(BuildContext context) {
    final String displayName = user?.displayName ?? 'Player 1';
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Profile Pill
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
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
                  ),
                  const Text(
                    'ONLINE',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Sign-Out Button
          Tooltip(
            message: 'Sign Out',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSignOutPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  child: Row(
                    children: const [
                      Icon(Icons.logout_rounded, color: Color(0xFFFF007F), size: 18),
                      SizedBox(width: 6),
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

/// Visual card presenting a level with lock/unlock status, high score, and earned stars.
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
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Row: Level number + Lock/Play status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LV ${level.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isUnlocked ? const Color(0xFF00E5FF) : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Icon(
                    isUnlocked ? Icons.play_circle_fill_rounded : Icons.lock_rounded,
                    color: isUnlocked ? const Color(0xFFFF007F) : Colors.white24,
                    size: 22,
                  ),
                ],
              ),

              // Center Visual: Level number & High Score
              if (isUnlocked)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$level',
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
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white24,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'LOCKED',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.24),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

              // Bottom Star Bar: 3 stars rendered dynamically
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (starIndex) {
                  final bool earned = isUnlocked && starIndex < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Icon(
                      earned ? Icons.star : Icons.star_border,
                      color: earned ? Colors.amber : Colors.white24,
                      size: 20,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
