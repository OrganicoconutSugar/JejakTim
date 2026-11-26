import 'dart:async';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/illustrated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/controller.dart';
import '../../core/design.dart';
import '../../core/models.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> {
  late final VideoPlayerController _video;
  Timer? _transitionTimer;
  Future<void>? _restore;
  bool _videoFailed = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.asset('assets/video/kincir-splash.mp4');
    _restore = ref.read(controllerProvider).restore().catchError((Object _) {});
    _transitionTimer = Timer(const Duration(seconds: 4), _finish);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!reduceMotion(context)) unawaited(_playVideo());
    }
  }

  Future<void> _playVideo() async {
    try {
      await _video.initialize();
      if (!mounted) return;
      await _video.setVolume(0);
      await _video.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  Future<void> _finish() async {
    // Auth restore cannot keep the opening screen visible indefinitely.
    await _restore?.timeout(Duration.zero, onTimeout: () {});
    if (!mounted) return;
    final c = ref.read(controllerProvider);
    context.go(
      c.authenticated
          ? '/home'
          : !c.onboarded
          ? '/onboarding'
          : '/auth/login',
    );
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    unawaited(_video.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final videoHeight = (constraints.maxHeight * .64).clamp(0.0, 520.0);
          final showVideo =
              !reduceMotion(context) &&
              !_videoFailed &&
              _video.value.isInitialized;
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: videoHeight,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child:
                          showVideo
                              ? ExcludeSemantics(child: VideoPlayer(_video))
                              : Center(
                                child: BrandLogo(
                                  size: (videoHeight * .45).clamp(0.0, 150.0),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'JejakTim',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int step = 0;

  static const slides = [
    (
      label: 'SATU TIM, SATU TUJUAN',
      title: 'Ide besar dimulai\ndari kerja bareng.',
      body:
          'Satukan proyek, bagi peran, dan temukan ritme kerja kelompok yang nyaman.',
      image: 'assets/onboarding/tim-bersama.png',
    ),
    (
      label: 'SETIAP LANGKAH BERARTI',
      title: 'Kerjamu punya\njejak yang nyata.',
      body:
          'Catat progres, kumpulkan bukti, dan saling beri masukan. Semua proses terlihat.',
      image: 'assets/onboarding/jejak-langkah.png',
    ),
    (
      label: 'TUMBUH BERSAMA',
      title: 'Tim lebih paham.\nLangkah lebih terarah.',
      body:
          'Lihat progres dan dapatkan saran koordinasi berbasis data. Keputusan tetap di tangan tim.',
      image: 'assets/onboarding/tumbuh-bersama.png',
    ),
  ];

  Future<void> finish() async {
    await ref.read(controllerProvider).finishOnboarding();
    if (mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final slide = slides[step];
    final motionDuration = Duration(
      milliseconds: reduceMotion(context) ? 0 : 360,
    );
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: motionDuration,
            child: Image.asset(
              slide.image,
              key: ValueKey(slide.image),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              semanticLabel: 'Foto kebersamaan untuk pengenalan JejakTim',
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, .34, .61, 1],
                colors: [
                  Colors.black.withValues(alpha: .55),
                  Colors.black.withValues(alpha: .34),
                  Colors.black.withValues(alpha: .62),
                  Colors.black.withValues(alpha: .89),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder:
                  (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const BrandLogo(size: 42),
                                  const SizedBox(width: 11),
                                  const Expanded(
                                    child: Text(
                                      'JejakTim',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: finish,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                    ),
                                    child: const Text('Lewati'),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              AnimatedSwitcher(
                                duration: motionDuration,
                                transitionBuilder:
                                    (child, animation) => FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, .07),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: Column(
                                  key: ValueKey(step),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slide.label,
                                      style: const TextStyle(
                                        color: Color(0xFFDCEBFF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      slide.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w600,
                                        height: 1.08,
                                        letterSpacing: -1.1,
                                        shadows: [
                                          Shadow(
                                            color: Color(0x66000000),
                                            blurRadius: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      slide.body,
                                      style: const TextStyle(
                                        color: Color(0xFFF4F8FF),
                                        fontSize: 16,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                children: List.generate(
                                  slides.length,
                                  (i) => AnimatedContainer(
                                    duration: motionDuration,
                                    margin: const EdgeInsets.only(right: 7),
                                    width: step == i ? 30 : 8,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color:
                                          step == i
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                alpha: .40,
                                              ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed:
                                      step == slides.length - 1
                                          ? finish
                                          : () => setState(() => step++),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: C.blue,
                                    minimumSize: const Size.fromHeight(58),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    step == slides.length - 1
                                        ? 'Mulai perjalananmu'
                                        : 'Lanjut',
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 48,
                                child:
                                    step == 0
                                        ? null
                                        : Center(
                                          child: TextButton(
                                            onPressed:
                                                () => setState(() => step--),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Kembali'),
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        ),
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

class AuthScreen extends ConsumerStatefulWidget {
  final String mode;
  const AuthScreen({super.key, this.mode = 'login'});
  @override
  ConsumerState<AuthScreen> createState() => _AuthState();
}

class _AuthState extends ConsumerState<AuthScreen> {
  static const _heroScenes = [
    (
      image: 'assets/onboarding/jejak-langkah.png',
      alignment: Alignment(0, .42),
      chip: 'Jejak Langkah',
    ),
    (
      image: 'assets/onboarding/tim-bersama.png',
      alignment: Alignment.center,
      chip: 'Satu Tim',
    ),
    (
      image: 'assets/onboarding/tumbuh-bersama.png',
      alignment: Alignment.center,
      chip: 'Tumbuh Bersama',
    ),
  ];

  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirmPassword = TextEditingController(),
      name = TextEditingController();
  late int _sceneIndex =
      widget.mode == 'register'
          ? 1
          : widget.mode == 'forgot-password'
          ? 2
          : 0;
  Timer? _sceneTimer;
  bool _sceneTimerStarted = false;
  bool busy = false, hidden = true, confirmHidden = true, sent = false;
  bool rememberPassword = false;
  String? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sceneTimerStarted) {
      _sceneTimerStarted = true;
      if (!reduceMotion(context)) _startSceneTimer();
    }
  }

  void _startSceneTimer() {
    _sceneTimer?.cancel();
    _sceneTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _sceneIndex = (_sceneIndex + 1) % _heroScenes.length);
    });
  }

  void _advanceScene() {
    setState(() => _sceneIndex = (_sceneIndex + 1) % _heroScenes.length);
    if (!reduceMotion(context)) _startSceneTimer();
  }

  @override
  void dispose() {
    _sceneTimer?.cancel();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final c = ref.read(controllerProvider);
      if (widget.mode == 'forgot-password') {
        await c.resetPassword(email.text);
        if (mounted) setState(() => sent = true);
      } else {
        await c.signIn(
          email.text,
          password.text,
          name: widget.mode == 'register' ? name.text : null,
        );
        if (widget.mode == 'login') {
          TextInput.finishAutofillContext(shouldSave: rememberPassword);
        }
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (widget.mode == 'register' &&
              e is AppFailure &&
              e.message.startsWith('Akun dibuat.')) {
            sent = true;
          } else {
            error = errorMessage(e);
          }
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> googleSignIn() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(controllerProvider).signInWithGoogle();
      if (mounted && ref.read(controllerProvider).authenticated) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final register = widget.mode == 'register',
        forgot = widget.mode == 'forgot-password';
    final compact = MediaQuery.sizeOf(context).width <= 375;
    final scene = _heroScenes[_sceneIndex % _heroScenes.length];
    final heroMinHeight =
        forgot
            ? 200.0
            : register
            ? (compact ? 210.0 : 230.0)
            : (compact ? 240.0 : 280.0);
    final motionDuration = Duration(
      milliseconds: reduceMotion(context) ? 0 : 700,
    );
    return Scaffold(
      backgroundColor: C.canvas,
      body: SingleChildScrollView(
        child: AutofillGroup(
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: motionDuration,
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        child: Image.asset(
                          scene.image,
                          key: ValueKey(scene.image),
                          fit: BoxFit.cover,
                          alignment: scene.alignment,
                          width: double.infinity,
                          height: double.infinity,
                          gaplessPlayback: true,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, .38, .72, 1],
                            colors: [
                              Colors.black.withValues(alpha: .46),
                              Colors.black.withValues(alpha: .16),
                              Colors.black.withValues(alpha: .64),
                              Colors.black.withValues(alpha: .86),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: heroMinHeight),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 44),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const BrandLogo(size: 38, inverse: true),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'JejakTim',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(
                                            color: Color(0x55000000),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Ganti suasana foto',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 12,
                                          sigmaY: 12,
                                        ),
                                        child: Material(
                                          color: Colors.white.withValues(
                                            alpha: .18,
                                          ),
                                          child: InkWell(
                                            onTap: _advanceScene,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 7,
                                                  ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: .32),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  for (
                                                    var i = 0;
                                                    i < _heroScenes.length;
                                                    i++
                                                  )
                                                    AnimatedContainer(
                                                      duration: motionDuration,
                                                      margin: EdgeInsets.only(
                                                        right:
                                                            i ==
                                                                    _heroScenes
                                                                            .length -
                                                                        1
                                                                ? 0
                                                                : 4,
                                                      ),
                                                      width:
                                                          _sceneIndex == i
                                                              ? 14
                                                              : 5,
                                                      height: 5,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _sceneIndex == i
                                                                ? Colors.white
                                                                : Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          .48,
                                                                    ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: forgot ? 28 : 48),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    forgot
                                        ? 'PULIHKAN AKSES'
                                        : register
                                        ? 'MULAI BERSAMA'
                                        : 'RUANG KOLABORASI',
                                    style: const TextStyle(
                                      color: Color(0xFFDCEBFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.7,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    forgot
                                        ? 'Lupa kata sandi?'
                                        : register
                                        ? 'Kenalan dulu, yuk.'
                                        : 'Senang kamu kembali.',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w600,
                                      height: 1.12,
                                      letterSpacing: -.7,
                                      shadows: [
                                        Shadow(
                                          color: Color(0x66000000),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    forgot
                                        ? 'Kami akan mengirim tautan untuk mengatur ulang kata sandi.'
                                        : register
                                        ? 'Buat akun dan mulai langkah pertama bersama tim.'
                                        : 'Masuk untuk melanjutkan langkah bersama timmu.',
                                    style: const TextStyle(
                                      color: Color(0xFFF2F6FF),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: -1,
                      child: SizedBox(
                        height: 26,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: C.canvas,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(S.page, 4, S.page, S.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (error != null) ...[
                          ErrorBanner(error!),
                          const SizedBox(height: 16),
                        ],
                        if (sent)
                          Surface(
                            color: C.lime,
                            child: Text(
                              register
                                  ? 'Akun dibuat. Periksa email verifikasi, lalu kembali ke halaman masuk.'
                                  : 'Jika alamat email terdaftar, tautan reset telah dikirim. Periksa kotak masuk Anda.',
                            ),
                          )
                        else ...[
                          if (register) ...[
                            TextFormField(
                              controller: name,
                              decoration: const InputDecoration(
                                labelText: 'Nama lengkap',
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  size: 20,
                                  color: Color(0xFF286DA0),
                                ),
                              ),
                              validator: (v) => requiredText(v, max: 80),
                              autofillHints: const [AutofillHints.name],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: AppIcon(LucideIcons.mail, size: 20),
                            ),
                            validator: emailError,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                          ),
                          if (!forgot) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: password,
                              obscureText: hidden,
                              decoration: InputDecoration(
                                labelText: 'Kata sandi',
                                prefixIcon: const AppIcon(
                                  LucideIcons.lock,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  tooltip:
                                      hidden
                                          ? 'Tampilkan kata sandi'
                                          : 'Sembunyikan kata sandi',
                                  onPressed:
                                      () => setState(() => hidden = !hidden),
                                  icon: AppIcon(
                                    hidden
                                        ? LucideIcons.eye
                                        : LucideIcons.eyeOff,
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator:
                                  (v) =>
                                      (v?.length ?? 0) < 8
                                          ? 'Gunakan minimal 8 karakter.'
                                          : null,
                              autofillHints: [
                                register
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              textInputAction:
                                  register
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                              onFieldSubmitted:
                                  register ? null : (_) => submit(),
                            ),
                            if (register) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: confirmPassword,
                                obscureText: confirmHidden,
                                decoration: InputDecoration(
                                  labelText: 'Konfirmasi kata sandi',
                                  prefixIcon: const AppIcon(
                                    LucideIcons.lock,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip:
                                        confirmHidden
                                            ? 'Tampilkan konfirmasi kata sandi'
                                            : 'Sembunyikan konfirmasi kata sandi',
                                    onPressed:
                                        () => setState(
                                          () => confirmHidden = !confirmHidden,
                                        ),
                                    icon: AppIcon(
                                      confirmHidden
                                          ? LucideIcons.eye
                                          : LucideIcons.eyeOff,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Masukkan ulang kata sandi.';
                                  }
                                  if (value != password.text) {
                                    return 'Kata sandi belum sama.';
                                  }
                                  return null;
                                },
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => submit(),
                              ),
                            ],
                            if (!register) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Checkbox(
                                    value: rememberPassword,
                                    onChanged:
                                        busy
                                            ? null
                                            : (value) => setState(
                                              () =>
                                                  rememberPassword =
                                                      value ?? false,
                                            ),
                                  ),
                                  const Expanded(
                                    child: Text('Ingat kata sandi'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => context.push(
                                          '/auth/forgot-password',
                                        ),
                                    child: const Text('Lupa kata sandi?'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                          const SizedBox(height: 18),
                          PrimaryButton(
                            forgot
                                ? 'Kirim tautan reset'
                                : register
                                ? 'Buat akun'
                                : 'Masuk',
                            onPressed: submit,
                            busy: busy,
                          ),
                        ],
                        if (!forgot) ...[
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: C.line)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'atau',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: C.muted,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: C.line)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                            ),
                            onPressed: busy ? null : googleSignIn,
                            icon: SvgPicture.asset(
                              'assets/branding/google-g.svg',
                              width: 20,
                              height: 20,
                              excludeFromSemantics: true,
                            ),
                            label: Text(
                              register
                                  ? 'Daftar dengan Google'
                                  : 'Masuk dengan Google',
                            ),
                          ),
                        ],
                        const SizedBox(height: S.md),
                        Center(
                          child: TextButton(
                            onPressed:
                                () => context.go(
                                  register || forgot
                                      ? '/auth/login'
                                      : '/auth/register',
                                ),
                            child: Text(
                              register || forgot
                                  ? 'Sudah punya akun? Masuk'
                                  : 'Belum punya akun? Daftar',
                            ),
                          ),
                        ),
                        const SizedBox(height: S.sm),
                        const Center(
                          child: Text(
                            'Kerja bareng, kontribusi terlihat.',
                            style: T.caption,
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
      ),
    );
  }
}
