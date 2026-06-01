import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/confetti_celebration.dart';

class BecomeMasterScreen extends StatefulWidget {
  const BecomeMasterScreen({super.key});

  @override
  State<BecomeMasterScreen> createState() => _BecomeMasterScreenState();
}

class _BecomeMasterScreenState extends State<BecomeMasterScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0; // 0 = rules, 1 = quiz, 2 = result
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _rulesAccepted = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Quiz questions — 5 short questions about service rules
  List<_QuizQuestion> _getQuestions(LocalizationProvider l10n) {
    return [
      _QuizQuestion(
        question: l10n.tr('master_quiz_q1'),
        options: [
          l10n.tr('master_quiz_q1_a'),
          l10n.tr('master_quiz_q1_b'),
          l10n.tr('master_quiz_q1_c'),
        ],
        correctIndex: 1,
      ),
      _QuizQuestion(
        question: l10n.tr('master_quiz_q2'),
        options: [
          l10n.tr('master_quiz_q2_a'),
          l10n.tr('master_quiz_q2_b'),
          l10n.tr('master_quiz_q2_c'),
        ],
        correctIndex: 0,
      ),
      _QuizQuestion(
        question: l10n.tr('master_quiz_q3'),
        options: [
          l10n.tr('master_quiz_q3_a'),
          l10n.tr('master_quiz_q3_b'),
          l10n.tr('master_quiz_q3_c'),
        ],
        correctIndex: 2,
      ),
      _QuizQuestion(
        question: l10n.tr('master_quiz_q4'),
        options: [
          l10n.tr('master_quiz_q4_a'),
          l10n.tr('master_quiz_q4_b'),
          l10n.tr('master_quiz_q4_c'),
        ],
        correctIndex: 0,
      ),
      _QuizQuestion(
        question: l10n.tr('master_quiz_q5'),
        options: [
          l10n.tr('master_quiz_q5_a'),
          l10n.tr('master_quiz_q5_b'),
          l10n.tr('master_quiz_q5_c'),
        ],
        correctIndex: 1,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    _fadeController.reverse().then((_) {
      setState(() {
        _currentStep++;
      });
      _fadeController.forward();
    });
  }

  void _selectAnswer(int index, List<_QuizQuestion> questions) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == questions[_currentQuestion].correctIndex) {
        _correctAnswers++;
      }
    });

    // Auto-advance after 1.2 seconds
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQuestion < questions.length - 1) {
        _fadeController.reverse().then((_) {
          setState(() {
            _currentQuestion++;
            _selectedAnswer = null;
            _answered = false;
          });
          _fadeController.forward();
        });
      } else {
        // Quiz finished — show results
        _nextStep();
      }
    });
  }

  void _resetQuiz() {
    _fadeController.reverse().then((_) {
      setState(() {
        _currentStep = 1;
        _currentQuestion = 0;
        _correctAnswers = 0;
        _selectedAnswer = null;
        _answered = false;
      });
      _fadeController.forward();
    });
  }

  bool get _passed => _correctAnswers >= 4; // 4/5 to pass

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final questions = _getQuestions(l10n);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('master_become_title')),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _currentStep == 0
              ? _buildRulesStep(l10n)
              : _currentStep == 1
                  ? _buildQuizStep(l10n, questions)
                  : _buildResultStep(l10n),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // STEP 1: Rules Page
  // ═══════════════════════════════════════════
  Widget _buildRulesStep(LocalizationProvider l10n) {
    final rules = [
      _RuleItem(
        icon: Icons.handshake_outlined,
        title: l10n.tr('master_rule_1_title'),
        desc: l10n.tr('master_rule_1_desc'),
      ),
      _RuleItem(
        icon: Icons.schedule_outlined,
        title: l10n.tr('master_rule_2_title'),
        desc: l10n.tr('master_rule_2_desc'),
      ),
      _RuleItem(
        icon: Icons.chat_outlined,
        title: l10n.tr('master_rule_3_title'),
        desc: l10n.tr('master_rule_3_desc'),
      ),
      _RuleItem(
        icon: Icons.security_outlined,
        title: l10n.tr('master_rule_4_title'),
        desc: l10n.tr('master_rule_4_desc'),
      ),
      _RuleItem(
        icon: Icons.star_outline,
        title: l10n.tr('master_rule_5_title'),
        desc: l10n.tr('master_rule_5_desc'),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.engineering, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        l10n.tr('master_rules_header'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.tr('master_rules_subtitle'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  l10n.tr('master_rules_section'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepSlate,
                  ),
                ),
                const SizedBox(height: 16),

                // Rules list
                ...rules.asMap().entries.map((entry) {
                  final i = entry.key;
                  final rule = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(rule.icon, color: AppColors.primary, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}. ${rule.title}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepSlate,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rule.desc,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slateGray,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Accept checkbox
                InkWell(
                  onTap: () {
                    setState(() {
                      _rulesAccepted = !_rulesAccepted;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _rulesAccepted
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _rulesAccepted ? AppColors.primary : AppColors.divider,
                        width: _rulesAccepted ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _rulesAccepted
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _rulesAccepted
                                  ? AppColors.primary
                                  : AppColors.lightSlate,
                              width: 2,
                            ),
                          ),
                          child: _rulesAccepted
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.tr('master_rules_accept'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _rulesAccepted
                                  ? AppColors.primary
                                  : AppColors.slateGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '1/3',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _rulesAccepted ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.divider,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.tr('master_start_quiz'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // STEP 2: Quiz
  // ═══════════════════════════════════════════
  Widget _buildQuizStep(LocalizationProvider l10n, List<_QuizQuestion> questions) {
    final q = questions[_currentQuestion];

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.tr('master_quiz_question')} ${_currentQuestion + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slateGray,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          '$_correctAnswers',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentQuestion + 1) / questions.length,
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    q.question,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepSlate,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Options
                ...q.options.asMap().entries.map((entry) {
                  final i = entry.key;
                  final option = entry.value;
                  final isSelected = _selectedAnswer == i;
                  final isCorrect = i == q.correctIndex;
                  final showResult = _answered;

                  Color bgColor = AppColors.surface;
                  Color borderColor = AppColors.divider;
                  Color textColor = AppColors.deepSlate;
                  IconData? trailingIcon;
                  Color iconColor = AppColors.primary;

                  if (showResult) {
                    if (isCorrect) {
                      bgColor = AppColors.success.withValues(alpha: 0.08);
                      borderColor = AppColors.success;
                      textColor = AppColors.success;
                      trailingIcon = Icons.check_circle;
                      iconColor = AppColors.success;
                    } else if (isSelected && !isCorrect) {
                      bgColor = AppColors.error.withValues(alpha: 0.08);
                      borderColor = AppColors.error;
                      textColor = AppColors.error;
                      trailingIcon = Icons.cancel;
                      iconColor = AppColors.error;
                    }
                  } else if (isSelected) {
                    bgColor = AppColors.primary.withValues(alpha: 0.08);
                    borderColor = AppColors.primary;
                  }

                  return GestureDetector(
                    onTap: () => _selectAnswer(i, questions),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: (showResult && isCorrect)
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : (showResult && isSelected && !isCorrect)
                                      ? AppColors.error.withValues(alpha: 0.15)
                                      : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + i), // A, B, C
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (trailingIcon != null)
                            Icon(trailingIcon, color: iconColor, size: 22),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Bottom step indicator
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '2/3',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.tr('master_quiz_hint'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slateGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // STEP 3: Result
  // ═══════════════════════════════════════════
  Widget _buildResultStep(LocalizationProvider l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Result icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: (_passed ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _passed ? Icons.celebration : Icons.refresh,
              size: 50,
              color: _passed ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            _passed
                ? l10n.tr('master_result_passed_title')
                : l10n.tr('master_result_failed_title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.deepSlate,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: (_passed ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${l10n.tr('master_result_score')}: $_correctAnswers/5',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _passed ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            _passed
                ? l10n.tr('master_result_passed_desc')
                : l10n.tr('master_result_failed_desc'),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.slateGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '3/3',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_passed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final state = context.read<AppStateProvider>();
                  state.becomeMaster();
                  // 🎉 Show confetti celebration!
                  ConfettiCelebration.show(context,
                      type: CelebrationType.becomeMaster);
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.engineering, size: 20),
                label: Text(
                  l10n.tr('master_result_activate'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetQuiz,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(
                  l10n.tr('master_result_retry'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.tr('master_result_later'),
              style: const TextStyle(color: AppColors.slateGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class _RuleItem {
  final IconData icon;
  final String title;
  final String desc;

  const _RuleItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
