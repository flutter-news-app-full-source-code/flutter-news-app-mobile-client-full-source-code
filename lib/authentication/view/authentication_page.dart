import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthenticationBloc(
        authenticationRepository: context.read<HtAuthenticationRepository>(),
      ),
      child: const _AuthenticationView(),
    );
  }
}

class _AuthenticationView extends StatelessWidget {
  const _AuthenticationView();

  @override
  Widget build(BuildContext context) {
    return const Placeholder(child: Text('AUTHENTICATION PAGE'),);
  }
}
