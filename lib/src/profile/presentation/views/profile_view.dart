import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milestone/core/common/app/milestone/app_state.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/outlined_back_button.dart';
import 'package:milestone/core/services/injection_container.dart';
import 'package:milestone/core/utils/constants/network_contants.dart';
import 'package:milestone/src/profile/presentation/app/adapter/profile_cubit.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  static const path = '/profile';

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String? _imagePath;

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        if (context.canPop()) {
          log('POPPPINGGGG---------------', name: 'ProfileView');
          return context.pop();
        }
        log('GOING HOME------------', name: 'ProfileView');
        context.go('/');
      },
      child: AdaptiveBase(
        title: 'Profile',
        child: BlocListener<ProfileCubit, ProfileState>(
          listener: (context, state) {
            AppState.instance.stopLoading();
            if (state is ProfileLoading) {
              AppState.instance.startLoading();
            }
          },
          child: StreamBuilder<User?>(
            stream: sl<FirebaseAuth>().userChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (sl<FirebaseAuth>().currentUser == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/');
                });
                return const SizedBox.shrink();
              }
              return ProfileScreen(
                appBar: AppBar(
                  leading: const OutlinedBackButton(alwaysVisible: true),
                ),
                showDeleteConfirmationDialog: true,
                showUnlinkConfirmationDialog: true,
                actions: [
                  SignedOutAction((context) => context.go('/')),
                  DisplayNameChangedAction((context, oldName, newName) {
                    // TODO(UPDATE-USER): Move this functionality to the proper
                    //  place
                    sl<FirebaseFirestore>()
                        .collection('users')
                        .doc(sl<FirebaseAuth>().currentUser!.uid)
                        .update({'userName': newName});
                  }),
                ],
                // TODO(MFA): Enable Multi-factor Auth
                showMFATile: true,
                // actionCodeSettings: ActionCodeSettings(
                //   url: 'https://milestone-e4ea6.web.app',
                //   handleCodeInApp: true,
                //   androidInstallApp: true,
                //   androidMinimumVersion: '1',
                //   androidPackageName: 'co.akundadababalei.milestone',
                //   iOSBundleId: 'co.akundadababalei.milestone',
                // ),
                avatar: GestureDetector(
                  onTap: () async {
                    final profileCubit = context.read<ProfileCubit>();
                    final userProfileImage =
                        sl<FirebaseAuth>().currentUser?.photoURL;
                    final userHasProfileImage = userProfileImage != null;
                    if (userHasProfileImage) {
                      await showDialog<void>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Profile Image'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Delete'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    unawaited(
                                      profileCubit.updateProfileImage(null),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: const Text('Replace'),
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    await pickImage();
                                    navigator.pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    } else {
                      await pickImage();
                    }

                    if (_imagePath != null) {
                      unawaited(
                        profileCubit.updateProfileImage(_imagePath),
                      );
                    }
                  },
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(
                          user?.photoURL ?? NetworkConstants.defaultAvatar,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
