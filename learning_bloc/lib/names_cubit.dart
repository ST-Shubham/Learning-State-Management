import 'package:bloc/bloc.dart';
import 'package:learning_bloc/main.dart';

class NamesCubit extends Cubit<String?> {
  NamesCubit() : super(null);
  void pickRandomName() => emit(names.getRandomElement());
}
