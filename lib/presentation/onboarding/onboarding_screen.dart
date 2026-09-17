import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/layout/app_breakpoints.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/validation/profile_input.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/services/activity_spheres_service.dart';
import '../../data/services/first_run_service.dart';
import '../../domain/profile/contractor_profile.dart';

/// Онбординг первого запуска.
///
/// Проводит пользователя через два шага: выбор сфер деятельности и заполнение
/// профиля ИП. Новый пользователь всегда начинает с нуля — демонстрационные
/// данные можно загрузить позже из настроек. По завершении сохраняет введённые
/// данные и отмечает онбординг пройденным.
class OnboardingScreen extends StatefulWidget {
  final ActivitySpheresService activitySpheresService;
  final ContractorProfileRepository profileRepository;
  final FirstRunService firstRunService;

  /// Вызывается после успешного завершения онбординга.
  final VoidCallback onCompleted;

  const OnboardingScreen({
    super.key,
    required this.activitySpheresService,
    required this.profileRepository,
    required this.firstRunService,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 2;

  int _step = 0;
  bool _busy = false;

  final _selectedSpheres = <TransactionSphere>{};

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _inn = TextEditingController();
  final _ogrnip = TextEditingController();
  final _address = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccount = TextEditingController();
  final _bankBik = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _inn.dispose();
    _ogrnip.dispose();
    _address.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    _bankBik.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _selectedSpheres.isEmpty) {
      _showSnack('Выберите хотя бы одну сферу деятельности');
      return;
    }
    if (_step == 1 && !(_formKey.currentState?.validate() ?? true)) {
      return;
    }
    if (_step == _stepCount - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  Future<void> _finish() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      final profile = _buildProfile();
      if (profile != null) {
        await widget.profileRepository.save(profile);
      }
      await widget.activitySpheresService.save(_selectedSpheres.toList());
      await widget.firstRunService.completeOnboarding(StartMode.fromScratch);
      widget.onCompleted();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ContractorProfile? _buildProfile() {
    final fullName = _fullName.text.trim();
    final inn = _inn.text.trim();
    final ogrnip = _ogrnip.text.trim();
    final address = _address.text.trim();
    final bankName = _bankName.text.trim();
    final bankAccount = _bankAccount.text.trim();
    final bankBik = _bankBik.text.trim();

    final isEmpty = [
      fullName,
      inn,
      ogrnip,
      address,
      bankName,
      bankAccount,
      bankBik,
    ].every((value) => value.isEmpty);
    if (isEmpty) return null;

    return ContractorProfile(
      fullName: fullName,
      inn: inn,
      ogrnip: ogrnip,
      registrationAddress: address,
      bankName: bankName,
      bankAccount: bankAccount,
      bankBik: bankBik,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingHeader(step: _step, stepCount: _stepCount),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotionDurations.medium),
                switchInCurve: AppMotion.enterCurve(context),
                switchOutCurve: AppMotion.exitCurve(context),
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_step),
                  child: switch (_step) {
                    0 => _buildSpheresStep(context),
                    _ => _buildProfileStep(context),
                  },
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSpheresStep(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return ListView(
      key: const Key('onboarding_step_spheres'),
      padding: AppBreakpoints.screenPadding(width),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: AppIconSize.lg,
                    color: tokens.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Сферы деятельности',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Выберите, чем вы занимаетесь. Это поможет подобрать шаблоны '
                'договоров и разделить учёт по направлениям.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final sphere in TransactionSphere.values)
                    AppFilterChip(
                      key: Key('onboarding_sphere_${sphere.name}'),
                      label: sphere.label,
                      selected: _selectedSpheres.contains(sphere),
                      accent: _sphereAccent(sphere, tokens),
                      onSelected: () => setState(() {
                        if (_selectedSpheres.contains(sphere)) {
                          _selectedSpheres.remove(sphere);
                        } else {
                          _selectedSpheres.add(sphere);
                        }
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('onboarding_step_profile'),
        padding: AppBreakpoints.screenPadding(width),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: AppIconSize.lg,
                      color: tokens.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Профиль ИП',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Реквизиты подставляются в договоры, чеки и акты. Можно '
                  'заполнить позже — все поля необязательны.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextFormField(
                  key: const Key('onboarding_full_name'),
                  controller: _fullName,
                  label: 'ФИО',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextFormField(
                  key: const Key('onboarding_inn'),
                  controller: _inn,
                  label: 'ИНН',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) =>
                      ProfileInput.validateDigits(value, lengths: const [10, 12]),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextFormField(
                  key: const Key('onboarding_ogrnip'),
                  controller: _ogrnip,
                  label: 'ОГРНИП',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: (value) =>
                      ProfileInput.validateDigits(value, lengths: const [15]),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextFormField(
                  key: const Key('onboarding_address'),
                  controller: _address,
                  label: 'Адрес регистрации',
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Банковские реквизиты', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                AppTextFormField(
                  key: const Key('onboarding_bank_name'),
                  controller: _bankName,
                  label: 'Банк',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextFormField(
                  key: const Key('onboarding_bank_account'),
                  controller: _bankAccount,
                  label: 'Расчётный счёт',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (value) =>
                      ProfileInput.validateDigits(value, lengths: const [20]),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextFormField(
                  key: const Key('onboarding_bank_bik'),
                  controller: _bankBik,
                  label: 'БИК',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: (value) =>
                      ProfileInput.validateDigits(value, lengths: const [9]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isLast = _step == _stepCount - 1;
    final width = MediaQuery.sizeOf(context).width;
    // При крупном системном шрифте кнопки переносятся в столбец, чтобы не
    // переполнять строку.
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;

    final back = _step > 0
        ? AppButton(
            key: const Key('onboarding_back'),
            label: 'Назад',
            variant: AppButtonVariant.text,
            expanded: largeText,
            onPressed: _busy ? null : _back,
          )
        : null;
    final next = AppButton(
      key: isLast
          ? const Key('onboarding_finish')
          : const Key('onboarding_next'),
      label: isLast ? 'Начать работу' : 'Далее',
      icon: isLast ? Icons.check : Icons.arrow_forward,
      loading: _busy,
      expanded: largeText,
      onPressed: _busy ? null : _next,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppBreakpoints.horizontalGutter(width),
        AppSpacing.sm,
        AppBreakpoints.horizontalGutter(width),
        AppSpacing.md,
      ),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (back != null) ...[back, const SizedBox(height: AppSpacing.xs)],
                next,
              ],
            )
          : Row(
              children: [
                ?back,
                const Spacer(),
                next,
              ],
            ),
    );
  }

  Color _sphereAccent(TransactionSphere sphere, AppTokens tokens) {
    return switch (sphere) {
      TransactionSphere.it => tokens.sphereIt,
      TransactionSphere.logistics => tokens.sphereLogistics,
    };
  }
}

/// Градиентная шапка онбординга с индикатором прогресса шагов.
class _OnboardingHeader extends StatelessWidget {
  final int step;
  final int stepCount;

  const _OnboardingHeader({required this.step, required this.stepCount});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final theme = Theme.of(context);
    final progress = (step + 1) / stepCount;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: tokens.brandGradient),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: tokens.onPrimary, size: AppIconSize.lg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'NPD Shield',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: tokens.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Настройка приложения',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: tokens.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            key: const Key('onboarding_progress'),
            label: 'Шаг ${step + 1} из $stepCount',
            value: '${(progress * 100).round()}%',
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: AppMotion.duration(
                    context,
                    AppMotionDurations.medium,
                  ),
                  curve: AppMotion.enterCurve(context),
                  builder: (context, value, _) =>
                      LinearProgressIndicator(value: value),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Шаг ${step + 1} из $stepCount',
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
