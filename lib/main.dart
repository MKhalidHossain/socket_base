import 'package:flutter/material.dart';

void main() {
  runApp(const SocketBaseApp());
}

class SocketBaseApp extends StatelessWidget {
  const SocketBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F766E),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Socket Base',
      theme: theme,
      home: const SocketGuideScreen(),
    );
  }
}

class SocketGuideScreen extends StatelessWidget {
  const SocketGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reusable Socket Base')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Reusable Flutter Socket.IO asset',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Copy the lib/socket_service folder into another project and use the documented API from socket_service.dart.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const _InfoCard(
            title: 'Main features',
            lines: [
              'Connect, disconnect, reconnect, and manual connect',
              'Ack emit, one-time listeners, all-event listeners',
              'Room helpers, config object, exceptions, and streams',
            ],
          ),
          const SizedBox(height: 16),
          const _InfoCard(
            title: 'Preferred import',
            lines: [
              "import 'package:your_app/socket_service/socket_service.dart';",
            ],
          ),
          const SizedBox(height: 16),
          const _InfoCard(
            title: 'Files to check',
            lines: [
              'lib/socket_service/README.md',
              'lib/socket_service/examples.dart',
              'lib/socket_service/src/socket_client.dart',
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final line in lines) ...[
              Text(line),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
