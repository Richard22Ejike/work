import 'package:work/colors.dart';
import 'package:work/repository/auth_repository.dart';
import 'package:work/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

import '../common/widgets/textfield.dart';

class LoginScreen extends ConsumerStatefulWidget {
   LoginScreen({Key? key}) : super(key: key);
   @override
   ConsumerState<ConsumerStatefulWidget>  createState() => _LoginScreenState();
}
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isObscure = true;
   bool isloading = false;
  void signInWithGoogle(WidgetRef ref, BuildContext context) async {
    setState(() {
      isloading = true;
    });
    final sMessenger = ScaffoldMessenger.of(context);
    final navigator = Routemaster.of(context);
    final errorModel = await ref.read(authRepositoryProvider).signInWithGoogle(context,_emailController.text,_passwordController.text);

    if (errorModel.error == null) {
      print('update');
      ref.read(userProvider.notifier).update((state) => errorModel.data);
      navigator.replace('/');
    } else {
      sMessenger.showSnackBar(
        SnackBar(
          content: Text(errorModel.error!),
        ),
      );
    }
    setState(() {
      isloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to WriteNet',style: TextStyle(fontSize: 30),),
           SizedBox(height: 100,),
            Text('Sign in or Sign Up with your name and email '),
            SizedBox(height: 20),
            Text('Name',),
            SizedBox(
                width:450,child: CustomTextField(controller: _emailController , hintText: '',)),
            SizedBox(height: 5,),
            Text('Email',),
            SizedBox(
              width:450,
              child: CustomTextField(controller: _passwordController , hintText: '',



              ),
            ),
            SizedBox(height: 20),
            Center(
              child: isloading ? CircularProgressIndicator():ElevatedButton(
                onPressed:  () => signInWithGoogle(ref, context),


                style: ElevatedButton.styleFrom(
                  backgroundColor: kWhiteColor,
                  minimumSize: const Size(150, 50),
                ), child: const Text(
                'Sign in or Sign Up',
                style: TextStyle(
                  color: kBlackColor,
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
