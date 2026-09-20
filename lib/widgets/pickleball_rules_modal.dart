import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'game_2d_button.dart';

/// Modal dialog providing comprehensive, interactive Pickleball Rules and
/// context-aware explanations for faults and violations during gameplay.
class PickleballRulesModal extends StatefulWidget {
  final String? highlightedViolation;
  final VoidCallback onResume;

  const PickleballRulesModal({
    super.key,
    this.highlightedViolation,
    required this.onResume,
  });

  static Future<void> show(
    BuildContext context, {
    String? highlightedViolation,
    required VoidCallback onResume,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PickleballRulesModal(
        highlightedViolation: highlightedViolation,
        onResume: onResume,
      ),
    );
  }

  @override
  State<PickleballRulesModal> createState() => _PickleballRulesModalState();
}

class _PickleballRulesModalState extends State<PickleballRulesModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'Violations & Faults',
    'Two-Bounce Rule',
    'The Kitchen (NVZ)',
    'Serving & Court',
    'Scoring & Rotation',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.highlightedViolation != null) {
      final v = widget.highlightedViolation!.toUpperCase();
      if (v.contains('TWO-BOUNCE')) {
        initialIndex = 1;
      } else if (v.contains('KITCHEN')) {
        initialIndex = 2;
      } else if (v.contains('SERVICE')) {
        initialIndex = 3;
      } else {
        initialIndex = 0;
      }
    }
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isShortHeight = screenSize.height < 520;
    final dialogWidth = math.min(screenSize.width * 0.94, 580.0);
    final dialogHeight = math.min(screenSize.height * 0.92, 640.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isShortHeight ? 6 : 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: dialogHeight,
          ),
          child: Material(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.85),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header
                  _buildHeader(context, isShortHeight),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // 2. Navigation Tabs
                  _buildTabBar(isShortHeight),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // 3. Tab Body
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildViolationsTab(),
                        _buildTwoBounceTab(),
                        _buildKitchenTab(),
                        _buildServingTab(),
                        _buildScoringTab(),
                      ],
                    ),
                  ),

                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  // 4. Footer Action
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: isShortHeight ? 6 : 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Official USA Pickleball / IFP Rules Enforcement',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: isShortHeight ? 9.5 : 11,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Game2DButton(
                          text: 'RESUME PLAY',
                          icon: Icons.play_arrow_rounded,
                          size: isShortHeight ? GameButtonSize.small : GameButtonSize.medium,
                          variant: GameButtonVariant.primary,
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onResume();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isShortHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isShortHeight ? 8 : 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.neonLime.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.neonLime, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PICKLEBALL RULES GUIDE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  widget.highlightedViolation != null
                      ? 'Violation Review: ${widget.highlightedViolation}'
                      : 'Live Interactive Rules & Fault Explanations',
                  style: const TextStyle(
                    color: AppTheme.neonLime,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onResume();
            },
            visualDensity: VisualDensity.compact,
            tooltip: 'Resume Game',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isShortHeight) {
    return Container(
      color: AppTheme.surfaceLight.withValues(alpha: 0.4),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.neonLime,
        indicatorWeight: 2.5,
        labelColor: AppTheme.neonLime,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: TextStyle(fontSize: isShortHeight ? 11 : 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: isShortHeight ? 11 : 12),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        tabs: _tabs.map((t) => Tab(text: t, height: isShortHeight ? 34 : 40)).toList(),
      ),
    );
  }

  Widget _buildViolationsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (widget.highlightedViolation != null) ...[
          _buildAlertBanner(
            title: 'RECENT VIOLATION: ${widget.highlightedViolation}',
            message: 'A fault occurred which immediately ended the rally and awarded the point or side-out.',
            isCritical: true,
          ),
          const SizedBox(height: 12),
        ],
        _buildRuleCard(
          title: 'Two-Bounce Rule Violation',
          subtitle: 'Rule 2: Serve & Return Must Bounce',
          body:
              'The receiving team MUST let the serve bounce before returning it.\n'
              'The serving team MUST let the returned ball bounce before hitting it back.\n'
              'Volleying the ball out of the air during these first two shots is an immediate fault!',
          proTip: 'Watch the live HUD indicator! Wait for the neon green "BOUNCED • STRIKE NOW!" badge before swinging.',
          badgeColor: AppTheme.fireOrange,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Kitchen Volley (Non-Volley Zone)',
          subtitle: 'Rule 3: No Volleys in 7ft Kitchen',
          body:
              'Players may NEVER hit the ball out of the air (volley) while touching any part of the kitchen or its line.\n'
              'You CAN enter the kitchen to hit a ball that has already bounced on the court floor.',
          proTip: 'Dink from the kitchen line, but stay behind the white tape when attacking balls in mid-air.',
          badgeColor: AppTheme.electricCyan,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Kitchen Momentum Fault',
          subtitle: 'Rule 3: Forward Follow-Through Check',
          body:
              'If you hit a legal volley outside the kitchen, but your momentum carries you onto or inside the kitchen line after the hit, it is a FAULT even if the rally was already won!',
          proTip: 'Plant your feet firmly behind the non-volley line when executing smashes.',
          badgeColor: AppTheme.trophyAmber,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Double Bounce Fault',
          subtitle: 'Rule 4: Ball Bounced Twice on Floor',
          body:
              'The ball cannot bounce more than once on your side before you return it over the net.\n'
              'A second bounce ends the rally immediately.',
          proTip: 'Sprint towards short dinks early using the on-screen joystick or movement keys.',
          badgeColor: Colors.purpleAccent,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Body Fault',
          subtitle: 'Rule 4: Live Ball Contact With Player',
          body:
              'A live ball in flight touching a player or their clothing before bouncing is a fault on the player struck.\n'
              'Only paddle contact is legal.',
          proTip: 'If an opponent hits a ball that is flying out of bounds, dodge out of the way so it lands out!',
          badgeColor: Colors.deepOrangeAccent,
        ),
      ],
    );
  }

  Widget _buildTwoBounceTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildAlertBanner(
          title: 'THE TWO-BOUNCE RULE (USA Pickleball Rule 2)',
          message: 'Both the serve and the return of serve must bounce once before being struck.',
          isCritical: false,
        ),
        const SizedBox(height: 12),
        _buildStepCard(
          step: '1',
          title: 'Shot 1: The Serve',
          description: 'The server hits the ball across the net. The receiver MUST let the ball bounce once in their service court before hitting it back. Volleying the serve is an automatic fault.',
        ),
        const SizedBox(height: 8),
        _buildStepCard(
          step: '2',
          title: 'Shot 2: Return of Serve',
          description: 'The receiver hits the ball back across the net. The serving team MUST let this return bounce once on their side before hitting it. Volleying the return is an automatic fault.',
        ),
        const SizedBox(height: 8),
        _buildStepCard(
          step: '3',
          title: 'Shot 3 & Beyond: Open Play',
          description: 'After these first two bounces have occurred, both teams may either volley the ball out of the air (outside the Kitchen) or play it off the bounce.',
        ),
        const SizedBox(height: 12),
        _buildProTipBox(
          'Our gameplay HUD displays real-time coaching: "LET IT BOUNCE!" turns into "BOUNCED • STRIKE NOW!" as soon as the ball makes legal contact with the court floor.',
        ),
      ],
    );
  }

  Widget _buildKitchenTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildAlertBanner(
          title: 'THE KITCHEN (NON-VOLLEY ZONE / NVZ)',
          message: 'The 7-foot zone extending on each side of the net designed to prevent aggressive net camping.',
          isCritical: false,
        ),
        const SizedBox(height: 12),
        _buildRuleCard(
          title: 'No Volleys Allowed Inside',
          subtitle: 'Feet Must Be Behind the Kitchen Line',
          body:
              'A volley is hitting the ball out of the air before it bounces.\n'
              'You cannot volley while standing in the kitchen, and your feet cannot touch the kitchen line during the swing.',
          proTip: 'Stand an inch behind the kitchen line so you can volley without penalty.',
          badgeColor: AppTheme.neonLime,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Hitting Off the Bounce (Dinking)',
          subtitle: 'Legal Entry into the Kitchen',
          body:
              'You CAN enter the kitchen at any time to hit a ball that has already bounced!\n'
              'Once the ball bounces, it is a groundstroke/dink, which is 100% legal anywhere on the court.',
          proTip: 'When your opponent drops a soft dink in the kitchen, step in to hit it after the bounce, then immediately back up!',
          badgeColor: AppTheme.electricCyan,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Momentum Rule',
          subtitle: 'Follow-Through Constraint',
          body:
              'Even if you hit the volley outside the kitchen, your forward swing momentum cannot carry you into the kitchen. If your foot slips inside afterward, it is a fault!',
          proTip: 'Use controlled split-steps when attacking floating balls.',
          badgeColor: AppTheme.fireOrange,
        ),
      ],
    );
  }

  Widget _buildServingTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildRuleCard(
          title: 'Underhand Motion',
          subtitle: 'Contact Below the Waist',
          body:
              'The serve must be hit with an upward underhand motion, with paddle contact occurring below the belly button and the paddle head below the wrist.',
          proTip: 'In our 2D game, tap the "SERVE" prompt or strike button to deliver a crisp underhand serve.',
          badgeColor: AppTheme.neonLime,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Diagonal Crosscourt Requirement',
          subtitle: 'Must Land in the Diagonal Service Box',
          body:
              'The ball must travel diagonally over the net into the opponent\'s receiving court.\n'
              'Serving into the straight-ahead court is an out-of-bounds fault.',
          proTip: 'When serving from the Right court, aim for the opponent\'s Right court (from their perspective).',
          badgeColor: AppTheme.electricCyan,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Clearing the Kitchen Line',
          subtitle: 'Kitchen Line is OUT on Serve',
          body:
              'On regular shots, line contact is considered IN. However, ON A SERVE, the Kitchen line is considered OUT (a fault).\n'
              'The serve must land completely past the 7ft non-volley line.',
          proTip: 'Aim serves deep towards the opponent\'s baseline.',
          badgeColor: AppTheme.fireOrange,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Net Clips Are Live',
          subtitle: 'No More "Lets"',
          body:
              'Under modern official pickleball rules, if a serve clips the top of the net cord and still lands inside the correct service court, the ball is LIVE and play continues.',
          proTip: 'Stay alert when a serve clips the net tape — be ready to return the ball off the bounce!',
          badgeColor: AppTheme.trophyAmber,
        ),
      ],
    );
  }

  Widget _buildScoringTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildRuleCard(
          title: 'Only the Serving Side Scores',
          subtitle: 'First to 11 Points • Win by 2',
          body:
              'You can only score a point when your team is serving!\n'
              'If the receiving team wins the rally, no point is awarded; instead, a side-out or second-server turnover occurs.',
          proTip: 'Defend fiercely when receiving, and capitalize on your serve turns to stack points.',
          badgeColor: AppTheme.neonLime,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Singles Scoring & Court Position',
          subtitle: 'Even Score = Right • Odd Score = Left',
          body:
              'When the server\'s score is EVEN (0, 2, 4, 6, 8, 10), they serve from the Right side.\n'
              'When the server\'s score is ODD (1, 3, 5, 7, 9), they serve from the Left side.',
          proTip: 'Look at the "R" or "L" badge next to the server\'s avatar on the scoreboard to see the active side.',
          badgeColor: AppTheme.electricCyan,
        ),
        const SizedBox(height: 10),
        _buildRuleCard(
          title: 'Doubles 3-Number Callout (e.g. 4 - 2 - 1)',
          subtitle: 'Server Score - Receiver Score - Server Number',
          body:
              'In 2v2 Doubles, the score callout has 3 numbers:\n'
              '1. Serving Team\'s score\n'
              '2. Receiving Team\'s score\n'
              '3. Server Number (1 or 2)\n\n'
              '• Server 1 serves until losing a rally.\n'
              '• Then Server 2 serves until losing a rally.\n'
              '• Then SIDE-OUT: serve passes to the opposing team.',
          proTip: 'Opening exception: The match begins at 0 - 0 - 2, meaning only one server gets to serve on the very first turn to prevent unfair opening advantage.',
          badgeColor: AppTheme.trophyAmber,
        ),
      ],
    );
  }

  Widget _buildAlertBanner({required String title, required String message, required bool isCritical}) {
    final color = isCritical ? AppTheme.fireOrange : AppTheme.neonLime;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isCritical ? Icons.warning_amber_rounded : Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard({
    required String title,
    required String subtitle,
    required String body,
    required String proTip,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: badgeColor, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    proTip,
                    style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({required String step, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppTheme.playButtonGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTipBox(String tip) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.neonLime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: AppTheme.neonLime, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
