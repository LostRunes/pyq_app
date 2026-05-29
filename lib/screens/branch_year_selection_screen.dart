import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/branch.dart';
import '../models/year.dart';
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
  Year? selectedYear;

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);
    final yearsAsync = ref.watch(yearsProvider);

    return Scaffold(
      appBar: AppBar(
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: SafeArea(
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
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                'Select your branch and year to start studying.',
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
                            (b) =>
                                DropdownMenuItem(value: b, child: Text(b.name)),
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
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ),
              const SizedBox(height: 24),
              _buildSelectionCard(
                context,
                label: 'Year',
                icon: Icons.calendar_today_outlined,
                child: yearsAsync.when(
                  data: (years) => DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<Year>(
                      isExpanded: true,
                      value: selectedYear,
                      items: years
                          .map(
                            (y) =>
                                DropdownMenuItem(value: y, child: Text(y.name)),
                          )
                          .toList(),
                      onChanged: (y) => setState(() => selectedYear = y),
                      decoration: const InputDecoration(
                        hintText: 'Select year',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ),
              const SizedBox(
                height: 48,
              ), // Replaced Spacer with fixed height for scrollability
              ElevatedButton(
                onPressed: (selectedBranch != null && selectedYear != null)
                    ? () {
                        Navigator.pushNamed(
                          context,
                          '/subjects',
                          arguments: {
                            'branchId': selectedBranch!.id,
                            'yearId': selectedYear!.id,
                          },
                        );
                      }
                    : null,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 40),
            ],
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
