import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/firebase_data_cubit.dart';
import '../cubit/firebase_data_state.dart';
import '../models/farm_payload.dart';

class FirebaseDataPage extends StatelessWidget {
  const FirebaseDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer<FirebaseDataCubit, FirebaseDataState>(
        listenWhen: (FirebaseDataState previous, FirebaseDataState current) {
          return previous.message != current.message && current.message != null;
        },
        listener: (BuildContext context, FirebaseDataState state) {
          final String? message = state.message;
          if (message == null || message.isEmpty) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (BuildContext context, FirebaseDataState state) {
          final FirebaseDataCubit cubit = context.read<FirebaseDataCubit>();
          final bool isLoading = state.status == FirebaseDataStatus.loading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Firebase Realtime Database Test',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Path: ${FarmPayload.nitrogenPath}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : cubit.writeSampleData,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Write Sample Data'),
                    ),
                    FilledButton.icon(
                      onPressed: isLoading ? null : cubit.readNitrogenOnce,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Read Nitrogen'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isLoading) ...<Widget>[
                  const Center(child: CircularProgressIndicator()),
                ] else ...<Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Latest Read',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.nitrogen == null
                                ? 'Nitrogen Level: not loaded yet'
                                : 'Nitrogen Level: ${state.nitrogen}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
