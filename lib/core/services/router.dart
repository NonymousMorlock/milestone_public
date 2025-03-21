import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/app_state_reactor.dart';
import 'package:milestone/core/services/injection_container.dart';
import 'package:milestone/src/auth/presentation/views/register_view.dart';
import 'package:milestone/src/auth/presentation/views/sign_in_view.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';
import 'package:milestone/src/client/presentation/views/add_client_view.dart';
import 'package:milestone/src/home/presentation/views/home_page.dart';
import 'package:milestone/src/profile/presentation/app/adapter/profile_cubit.dart';
import 'package:milestone/src/profile/presentation/views/profile_view.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';
import 'package:milestone/src/project/features/milestone/presentation/views/add_milestone_view.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/expandable_card_controller.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/views/add_project_view.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';
import 'package:milestone/src/project/presentation/views/project_details_view.dart';
import 'package:provider/provider.dart';

part 'router.main.dart';
