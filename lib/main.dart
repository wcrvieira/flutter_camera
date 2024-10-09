import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Função principal do app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtém a lista de câmeras disponíveis
  final cameras = await availableCameras();
  final firstCamera = cameras.last;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: TakePictureScreen(camera: camera),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({super.key, required this.camera});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Inicializa o controlador da câmera
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Libera os recursos da câmera ao descartar o widget
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tirar uma Foto')),
      // Usa um FutureBuilder para exibir a pré-visualização da câmera
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Se a inicialização estiver concluída, exibe a pré-visualização.
            return CameraPreview(_controller);
          } else {
            // Caso contrário, exibe um indicador de carregamento.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // Aguarda a inicialização do controlador da câmera
            await _initializeControllerFuture;

            // Tira a foto
            final image = await _controller.takePicture();

            // Obtém o diretório temporário para salvar a imagem
            final directory = await getApplicationDocumentsDirectory();

            // Define o caminho onde a imagem será salva
            final imagePath = '${directory.path}/${DateTime.now()}.png';

            // Move a imagem tirada para o diretório definido
            await image.saveTo(imagePath);

            // Navega para a tela que exibe a foto
            if (!mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    DisplayPictureScreen(imagePath: imagePath),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// Tela que exibe a foto tirada
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imagem Capturada')),
      body: Image.file(File(imagePath)),
    );
  }
}
