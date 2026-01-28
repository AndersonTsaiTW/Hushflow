import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/motion_detection_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const _SectionHeader(title: 'Account'),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: const Text('user@example.com'),
          subtitle: const Text('Google Account'),
          trailing: const Icon(Icons.chevron_right),
        ),
        const Divider(),
        const _SectionHeader(title: 'Whitelist'),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('Whitelisted Senders'),
          subtitle: const Text('Manage subscription senders'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to whitelist detail screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Whitelist management coming soon')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Rescan Inbox'),
          subtitle: const Text('Find new subscription senders'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/onboarding/whitelist'),
        ),
        const Divider(),
        const _SectionHeader(title: 'Summary Settings'),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Summary Schedule'),
          subtitle: const Text('Weekly on Mondays at 9:00 AM'),
          trailing: const Icon(Icons.chevron_right),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.headphones),
          title: const Text('Auto-generate Audio'),
          subtitle: const Text('Create TTS briefings'),
          value: true,
          onChanged: (_) {},
        ),
        const Divider(),
        const _SectionHeader(title: 'Exclusions'),
        ListTile(
          leading: const Icon(Icons.person_off),
          title: const Text('Excluded Senders'),
          subtitle: const Text('5 senders excluded'),
          trailing: const Icon(Icons.chevron_right),
        ),
        const Divider(),
        const _SectionHeader(title: 'Advanced'),
        ListTile(
          leading: const Icon(Icons.psychology),
          title: const Text('ML Model'),
          subtitle: const Text('Last trained: 2 days ago'),
          trailing: TextButton(onPressed: () {}, child: const Text('Retrain')),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.speed),
          title: const Text('Motion Detection'),
          subtitle: const Text('Suggest audio when traveling'),
          value: ref.watch(motionDetectionEnabledProvider),
          onChanged: (value) {
            ref.read(motionDetectionEnabledProvider.notifier).toggle(value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value 
                  ? 'Motion detection enabled' 
                  : 'Motion detection disabled'
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        const Divider(),
        const _SectionHeader(title: 'About'),
        const ListTile(leading: Icon(Icons.info), title: Text('Version'), subtitle: Text('1.0.0+1')),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      )),
    );
  }
}
