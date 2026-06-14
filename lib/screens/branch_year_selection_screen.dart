import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/branch.dart';
import '../core/providers.dart';
import '../widgets/theme_toggle_button.dart';

class BranchYearSelectionScreen extends ConsumerStatefulWidget {
  const BranchYearSelectionScreen({super.key});

  @override
  ConsumerState<BranchYearSelectionScreen> createState() =>
      _BranchYearSelectionScreenState();
}

class _BranchYearSelectionScreenState
    extends ConsumerState<BranchYearSelectionScreen> {
  Branch? selectedBranch;
  int? selectedSemester;

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(actions: const [ThemeToggleButton()]),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF171330).withOpacity(0.55),
                    BlendMode.srcOver,
                  ),
                ),
              )
            : null,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 5),
                Center(
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/cat.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome back! ✨',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select your branch and semester to start studying.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 48),
                _buildSelectionCard(
                  context,
                  label: 'Branch',
                  icon: Icons.account_tree_outlined,
                  child: branchesAsync.when(
                    data: (branches) => DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<Branch>(
                        isExpanded: true,
                        value: selectedBranch,
                        items: branches
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  b.name,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (b) => setState(() => selectedBranch = b),
                        decoration: const InputDecoration(
                          hintText: 'Select branch',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    loading: () =>
                        const Center(child: LinearProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSelectionCard(
                  context,
                  label: 'Semester',
                  icon: Icons.calendar_today_outlined,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: selectedSemester,
                      items: List.generate(8, (index) => index + 1)
                          .map(
                            (sem) => DropdownMenuItem(
                              value: sem,
                              child: Text(
                                'Semester $sem',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (sem) =>
                          setState(() => selectedSemester = sem),
                      decoration: const InputDecoration(
                        hintText: 'Select semester',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 48,
                ), // Replaced Spacer with fixed height for scrollability
                ElevatedButton(
                  onPressed:
                      (selectedBranch != null && selectedSemester != null)
                      ? () async {
                          await ref
                              .read(selectedBranchIdProvider.notifier)
                              .setBranchId(selectedBranch!.id);
                          await ref
                              .read(selectedSemesterProvider.notifier)
                              .setSemester(selectedSemester!);
                          if (mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/main_navigation',
                              arguments: {
                                'branchId': selectedBranch!.id,
                                'semester': selectedSemester,
                              },
                            );
                          }
                        }
                      : null,
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
