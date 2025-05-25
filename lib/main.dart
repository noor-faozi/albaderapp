import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://twlxilnxparfazvmfoaw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3bHhpbG54cGFyZmF6dm1mb2F3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNzU5MTQsImV4cCI6MjA2Mzc1MTkxNH0.1vwhTiSMIAoNozaO3BnNCwOSRNXl3-hzMHugYzPF2kg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _notesStream =
      Supabase.instance.client.from('notes').stream(primaryKey: ['id']);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _notesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final notes = snapshot.data!;

            return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(notes[index]['body']),
                  );
                });
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: ((context) {
                  return SimpleDialog(
                    title: const Text('Add a note'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      TextFormField(
                        onFieldSubmitted: (value) async {
                          await Supabase.instance.client
                              .from('notes')
                              .insert({'body': value});
                        },
                      )
                    ],
                  );
                }));
          },
          child: const Icon(Icons.add),
        ));
  }
}
