import 'dart:io'; // Для работы с файлами.
// Для работы с данными в байтах.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для взаимодействия с платформой.
import 'package:flutter_svg/flutter_svg.dart'; // Для обработки SVG.
import 'package:image_editor_plus/image_editor_plus.dart'; // Пакет для редактирования изображений.
import 'package:image_picker/image_picker.dart'; // Для выбора изображений из галереи.
import 'dart:math'; // Для рандомизации цвета.

void main() {
  runApp(
    const MaterialApp(
      home: ImageEditorExample(), // Устанавливаем стартовый экран приложения.
    ),
  );
}

class ImageEditorExample extends StatefulWidget {
  const ImageEditorExample({super.key});

  @override
  createState() => _ImageEditorExampleState();
}

class _ImageEditorExampleState extends State<ImageEditorExample> {
  Uint8List? imageData; // Данные PNG/JPG изображения.
  String? svgData; // Данные SVG в виде текста.
  File? savedImage; // Сохранённый файл изображения.

  // Метод для рандомизации цвета
  Color _generateRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1.0,
    );
  }

  // Функция для изменения цвета в SVG
  String _changeSvgColor(String svgContent, Color color) {
    final colorHex =
        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}'; // Преобразуем цвет в формат hex
    return svgContent.replaceAll(
        RegExp(r'#([0-9A-Fa-f]{6})'), colorHex); // Заменяем все цвета в SVG
  }

  // Загрузка изображения из устройства (включая SVG)
  Future<void> _loadImageFromDevice() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final extension = pickedFile.path.split('.').last.toLowerCase();

        if (extension == 'svg') {
          // Если файл SVG
          final svgContent = await pickedFile.readAsString();
          setState(() {
            svgData = svgContent;
            imageData =
                null; // Удаляем данные PNG/JPG, если были загружены ранее.
          });
        } else {
          // Если файл PNG/JPG
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            imageData = bytes;
            svgData = null; // Удаляем данные SVG, если были загружены ранее.
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изображение успешно загружено!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке: $e')),
      );
    }
  }

  // Редактирование изображения с использованием `image_editor_plus`
  Future<void> _editImage() async {
    if (imageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет изображения для редактирования!')),
      );
      return;
    }

    try {
      // Открываем редактор изображения
      final editedImage = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            image: imageData!, // Передаём текущие данные изображения.
          ),
        ),
      );

      if (editedImage != null) {
        setState(() => imageData = editedImage); // Обновляем изображение.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изображение успешно отредактировано!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при редактировании: $e')),
      );
    }
  }

  // Сохранение SVG-файла
  Future<void> _saveSvgToDownloads(String svgContent) async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        throw Exception('Папка Downloads недоступна');
      }

      final filePath =
          '${downloadsDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.svg';
      final file = File(filePath);

      await file.writeAsString(svgContent); // Сохраняем SVG как текст.
      setState(() => savedImage = file);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SVG сохранен в: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении SVG: $e')),
      );
    }
  }

  // Сохранение PNG/JPG изображения
  Future<void> _saveImageToDownloads(Uint8List image) async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        throw Exception('Папка Downloads недоступна');
      }

      final filePath =
          '${downloadsDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      await file.writeAsBytes(image);
      setState(() => savedImage = file);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Изображение сохранено в: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении изображения: $e')),
      );
    }
  }

  // Удаление изображения
  void _deleteImage() {
    if (imageData != null || svgData != null) {
      setState(() {
        imageData = null;
        svgData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изображение удалено!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет изображения для удаления!')),
      );
    }
  }

  // Построение интерфейса
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Редактор изображений"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageData != null)
                Image.memory(
                  imageData!,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                ),
              if (svgData != null)
                SvgPicture.string(
                  svgData!,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                ),
              if (savedImage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Сохранено в: ${savedImage!.path}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadImageFromDevice,
                child: const Text("Загрузить изображение"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: imageData == null ? null : _editImage,
                child: const Text("Редактировать изображение"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  if (imageData != null) {
                    await _saveImageToDownloads(imageData!);
                  } else if (svgData != null) {
                    await _saveSvgToDownloads(svgData!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Нет изображения для сохранения!')),
                    );
                  }
                },
                child: const Text("Сохранить изображение"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: (imageData == null && svgData == null)
                    ? null
                    : _deleteImage,
                child: const Text("Удалить изображение"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: svgData == null
                    ? null
                    : () async {
                        final randomColor = _generateRandomColor();
                        final updatedSvg =
                            _changeSvgColor(svgData!, randomColor);
                        setState(() {
                          svgData = updatedSvg;
                        });
                      },
                child: const Text("Изменить цвет SVG"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
