import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Knowledge screen - How the app works.
/// Clean explanation. No jargon.
/// Steve Jobs would present this.
class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhilosophy(context),
                    const SizedBox(height: AppTheme.spacing48),
                    _buildHowItWorks(context),
                    const SizedBox(height: AppTheme.spacing48),
                    _buildTheNumbers(context),
                    const SizedBox(height: AppTheme.spacing48),
                    _buildExample(context),
                    const SizedBox(height: AppTheme.spacing48),
                    _buildCategories(context),
                    const SizedBox(height: AppTheme.spacing64),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.chevron_left,
              color: AppTheme.black,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Text(
            'How it works',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPhilosophy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The Philosophy',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing16),
        Text(
          'You shouldn\'t think about money every day.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          'FinanceSensei answers one question: "How much can I spend today without hurting my future?"',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          'That\'s it. One number. Every day.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The Math',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildStep(
          context,
          number: '1',
          title: 'Your income comes in',
          description: 'We start with what you earn each month.',
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildStep(
          context,
          number: '2',
          title: 'Fixed costs go out',
          description: 'Rent, bills, subscriptions. These don\'t change.',
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildStep(
          context,
          number: '3',
          title: 'Savings are protected',
          description: 'Emergency fund and goals. Non-negotiable.',
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildStep(
          context,
          number: '4',
          title: 'The rest is yours',
          description: 'Divided equally across the days in your cycle.',
        ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppTheme.black,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTheNumbers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Two Numbers',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildNumberExplanation(
          context,
          label: 'Planned',
          value: '₹1,000/day',
          description: 'Your target. Fixed for the entire month. This is what you planned to spend each day.',
        ),
        const SizedBox(height: AppTheme.spacing20),
        _buildNumberExplanation(
          context,
          label: 'Available',
          value: '₹847/day',
          description: 'Your reality. Updates based on actual spending. This is what you can spend today.',
          isHero: true,
        ),
      ],
    );
  }

  Widget _buildNumberExplanation(
    BuildContext context, {
    required String label,
    required String value,
    required String description,
    bool isHero = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isHero ? AppTheme.black : AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isHero ? AppTheme.gray400 : AppTheme.gray500,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isHero ? AppTheme.white : AppTheme.black,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isHero ? AppTheme.gray300 : AppTheme.gray600,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              _buildExampleRow(context, 'Monthly budget', '₹30,000'),
              _buildExampleDivider(),
              _buildExampleRow(context, 'Days in month', '30'),
              _buildExampleDivider(),
              _buildExampleRow(context, 'Planned daily', '₹1,000', bold: true),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Text(
          'If you spend ₹1,200 on Day 1:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              _buildExampleRow(context, 'Remaining budget', '₹28,800'),
              _buildExampleDivider(),
              _buildExampleRow(context, 'Days left', '29'),
              _buildExampleDivider(),
              _buildExampleRow(context, 'New daily allowance', '₹993', bold: true),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          'Overspent by ₹200, so your daily allowance drops slightly. Spend less tomorrow to get back on track.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray600,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildExampleRow(BuildContext context, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: bold
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildExampleDivider() {
    return const Divider(
      height: 1,
      color: AppTheme.gray200,
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Three Buckets',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing16),
        Text(
          'Every expense falls into one of three categories:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildCategory(
          context,
          title: 'Needs',
          description: 'Essentials. Food, transport, healthcare. Things you can\'t avoid.',
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildCategory(
          context,
          title: 'Wants',
          description: 'Lifestyle. Dining out, entertainment, shopping. Things you choose.',
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildCategory(
          context,
          title: 'Savings',
          description: 'Future. Investments, emergency fund contributions. Things that grow.',
        ),
      ],
    );
  }

  Widget _buildCategory(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
