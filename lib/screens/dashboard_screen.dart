import 'package:flutter/material.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import 'views/home_view.dart';
import 'views/tournament_view.dart';
import 'views/challenges_view.dart';
import 'views/settings_view.dart';
import 'game_play_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;

  void _navigateToGame({
    String matchType = 'quick',
    String? tournamentId,
    String? opponentName,
    String? matchTitle,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GamePlayScreen(
          matchType: matchType,
          tournamentId: tournamentId,
          opponentName: opponentName,
          matchTitle: matchTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppTheme.compactBreakpoint;

            return Scaffold(
              backgroundColor: AppTheme.background,
              body: SafeArea(
                child: Column(
                  children: [
                    // Top Player Profile & Currencies Header
                    _buildTopHeader(context, state),
                    const Divider(color: AppTheme.surfaceBorder, height: 1),
                    // Body Area
                    Expanded(
                      child: isWide
                          ? Row(
                              children: [
                                _buildNavigationRail(),
                                const VerticalDivider(color: AppTheme.surfaceBorder, width: 1),
                                Expanded(child: _buildCurrentView()),
                              ],
                            )
                          : _buildCurrentView(),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: isWide ? null : _buildBottomNavigationBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, GameStateManager state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      color: AppTheme.surface,
      child: Row(
        children: [
          // Player Avatar & Info
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neonLime, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.sports_tennis, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        state.playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.neonLime,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LVL ${state.playerLevel}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // XP Progress bar
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.xpProgress,
                          backgroundColor: AppTheme.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricCyan),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.playerXp}/${state.xpToNextLevel} XP',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Currencies Chips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCurrencyChip(
                icon: Icons.monetization_on_rounded,
                iconColor: AppTheme.goldCoin,
                value: '${state.coins}',
              ),
              const SizedBox(width: 8),
              _buildCurrencyChip(
                icon: Icons.emoji_events_rounded,
                iconColor: AppTheme.trophyAmber,
                value: '${state.trophies}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      color: AppTheme.surface,
      width: 110,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildRailItem(0, Icons.sports_tennis_rounded, 'Court'),
          _buildRailItem(1, Icons.emoji_events_rounded, 'Tournaments'),
          _buildRailItem(2, Icons.military_tech_rounded, 'Challenges'),
          _buildRailItem(3, Icons.tune_rounded, 'Settings'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'SMASH\nv1.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailItem(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: InkWell(
        key: ValueKey('rail_item_$index'),
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.neonLime : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.neonLime : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedTabIndex,
        backgroundColor: Colors.transparent,
        indicatorColor: AppTheme.neonLime.withValues(alpha: 0.25),
        elevation: 0,
        height: 65,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            key: ValueKey('nav_dest_0'),
            icon: Icon(Icons.sports_tennis_rounded, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.sports_tennis_rounded, color: AppTheme.neonLime),
            label: 'Home',
          ),
          NavigationDestination(
            key: ValueKey('nav_dest_1'),
            icon: Icon(Icons.emoji_events_rounded, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.emoji_events_rounded, color: AppTheme.neonLime),
            label: 'Tournaments',
          ),
          NavigationDestination(
            key: ValueKey('nav_dest_2'),
            icon: Icon(Icons.military_tech_rounded, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.military_tech_rounded, color: AppTheme.neonLime),
            label: 'Challenges',
          ),
          NavigationDestination(
            key: ValueKey('nav_dest_3'),
            icon: Icon(Icons.tune_rounded, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.tune_rounded, color: AppTheme.neonLime),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedTabIndex) {
      case 0:
        return HomeView(
          onPlayQuickMatch: () => _navigateToGame(matchType: 'quick'),
          onOpenTournament: () {
            setState(() {
              _selectedTabIndex = 1;
            });
          },
          onOpenChallenges: () {
            setState(() {
              _selectedTabIndex = 2;
            });
          },
        );
      case 1:
        return TournamentView(
          onStartMatch: (tournament, match) {
            _navigateToGame(
              matchType: 'tournament',
              tournamentId: tournament.id,
              matchTitle: match.roundTitle,
              opponentName: match.player2Name,
            );
          },
        );
      case 2:
        return ChallengesView(
          onGoPlay: () => _navigateToGame(matchType: 'quick'),
        );
      case 3:
        return const SettingsView();
      default:
        return const SizedBox.shrink();
    }
  }
}

