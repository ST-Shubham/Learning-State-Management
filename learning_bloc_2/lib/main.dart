import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: BlocProvider(
      create: (_) => PersonsBloc(),
      child: const HomePage(),
    ),
    debugShowCheckedModeBanner: false,
  ));
}

@immutable
abstract class LoadActions {
  const LoadActions();
}

enum PersonUrl {
  person1,
  person2,
}

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.person1:
        return 'http://10.12.27.245:5500/Courses/Flutter-State-Management/learning_bloc_2/api/persons1.json';
      case PersonUrl.person2:
        return 'http://10.12.27.245:5500/Courses/Flutter-State-Management/learning_bloc_2/api/persons2.json';
    }
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

@immutable
class LoadPersonsAction implements LoadActions {
  final PersonUrl url;
  const LoadPersonsAction({required this.url}) : super();
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({
    required this.name,
    required this.age,
  });

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;

  @override
  String toString() {
    return 'Person (name = $name, age = $age)';
  }
}

Future<Iterable<Person>> getPersons(String url) {
  return HttpClient()
      .getUrl(Uri.parse(url)) //* Gives us the request
      .then((req) => req.close()) //* Request to Response
      .then((resp) =>
          resp.transform(utf8.decoder).join()) //* Response here returns string
      .then((str) =>
          json.decode(str) as List<dynamic>) //* String is converted to list
      .then((list) => list.map((e) => Person.fromJson(e))); //* List to Iterable
}

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrievedFromCache;

  const FetchResult({
    required this.persons,
    required this.isRetrievedFromCache,
  });

  @override
  String toString() {
    return 'FetchResult (isRetrievedFromCache = $isRetrievedFromCache, persons = $persons)';
  }
}

class PersonsBloc extends Bloc<LoadActions, FetchResult?> {
  //Bloc<Event,State>
  final Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonsBloc() : super(null) {
    on<LoadPersonsAction>(
      //on<Event> we perform tasks and emit States
      (event, emit) async {
        final PersonUrl url = event.url;
        if (_cache.containsKey(url)) {
          final cachedPersons = _cache[url]!;
          final result = FetchResult(
            persons: cachedPersons,
            isRetrievedFromCache: true,
          );
          emit(result);
        } else {
          final persons = await getPersons(url.urlString);
          _cache[url] = persons;
          final result =
              FetchResult(persons: persons, isRetrievedFromCache: false);
          emit(result);
        }
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  context.read<PersonsBloc>().add(
                        const LoadPersonsAction(
                          url: PersonUrl.person1,
                        ),
                      );
                },
                child: const Text(
                  'Load json #1',
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<PersonsBloc>().add(
                        const LoadPersonsAction(
                          url: PersonUrl.person2,
                        ),
                      );
                },
                child: const Text(
                  'Load json #2',
                ),
              ),
            ],
          ),
          BlocBuilder<PersonsBloc, FetchResult?>(
            buildWhen: (previous, current) {
              return previous?.persons != current?.persons;
            },
            builder: (context, fetchResult) {
              fetchResult?.log();
              final persons = fetchResult?.persons;
              if (persons == null) {
                return const SizedBox();
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: persons.length,
                  itemBuilder: (context, index) {
                    final person = persons[index]!;
                    return ListTile(
                      title: Text(
                        person.name,
                      ),
                    );
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
