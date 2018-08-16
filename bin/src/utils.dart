import 'dart:io';
import 'package:meta/meta.dart';
import 'package:w_module/w_module.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart' as fs;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:path/path.dart' as path;

final RegExp newLinePartOfRegexp = new RegExp('\npart of ');
final RegExp partOfRegexp = new RegExp('part of ');

/// Just the fields of a `ClassElement` we care about
class TruncatedClassElement {
  /// Class name
  final String name;

  /// Path to the file where this class is declared
  final String path;

  TruncatedClassElement(this.name, this.path);
}

// TODO this needs to incorporate the targets
Iterable<TruncatedClassElement> getClassesThatExtendFromModule(
    AnalysisContext context, Directory sdkDir, List<String> targets) {
  final entryPoints = getPackageEntryPoints(targets);
  final sources = parseSources(context, entryPoints);
  verifyAnalysis(context, sources);

  final libraries = parseLibraries(context, sources);

  final List<ClassElement> list = []
    ..addAll(libraries
        .expand(getSubclassesOfLifecycleModule)
        .where((element) => element.getGetter('name') == null));

  print(list.map((t) => t.name).toString());
  return list.map((c) => new TruncatedClassElement(c.name, c.source.uri.path));
}

void writeGettersToFile(TruncatedClassElement e) {
  String filePath = e.path.substring(e.path.indexOf('/') + 1);
  File f = new File('lib/$filePath');
  if (!f.existsSync()) {
    stdout.writeln('Does not exist: ${f.path}');
//    exit(1);
    return;
  }

  final RegExp classDeclaration = new RegExp('class ${e.name}');

  final lines = f.readAsLinesSync();
  final StringBuffer outputLines = new StringBuffer();

  int i, padding;

  // Find the line with `class SomeModule`
  for (i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains(classDeclaration)) {
      padding = 2 + line.length - line.trimLeft().length;
      break;
    }
    outputLines.writeln(line);
  }

  if (i == lines.length) {
    print(outputLines.toString());
    print('ran out of lines');
    exit(1);
  }

  bool addClosingBracket = false;

  // Find the line with the first {
  for (; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('{')) {
      if (line.endsWith('}')) {
        outputLines.writeln(line.substring(0, line.indexOf('{') + 1));
        addClosingBracket = true;
        break;
      }

      outputLines.writeln(line);
      break;
    }

    outputLines.writeln(line);
  }

  if (i == lines.length) {
    print('ran out of lines');
    exit(1);
  }

  final bracketLine = lines[i];

  outputLines
    ..writeln('${' ' * padding}@override')
    ..writeln('${' ' * padding}String get name => \'${e.name}\';');

  if (addClosingBracket) {
    outputLines.writeln('}');
  }

  // Already printed this line
  i++;

  // Write all remaining lines
  for (; i < lines.length; i++) {
    outputLines.writeln(lines[i]);
  }

  print(outputLines.toString());

  f.writeAsStringSync(outputLines.toString());
}

List<String> getTargetsThatExist(List<String> rawTargets) {
  final list = []
    ..addAll(rawTargets.where((target) => new Directory(target).existsSync()));

  return list;
}

Iterable<LibraryElement> parseLibraries(
    AnalysisContext context, Iterable<Source> sources) {
  final libraries = <LibraryElement>[]
    ..addAll(sources
        .where((source) =>
            source.uri != null &&
            context.computeKindOf(source) == SourceKind.LIBRARY)
        .map((source) => context.computeLibraryElement(source)));

  return libraries;
}

AnalysisContext createAnalysisContext(Directory sdkDir) {
  final resolvers = getUriResolvers(sdkDir);
  final sourceFactory = new SourceFactory(resolvers);

  AnalysisEngine.instance.processRequiredPlugins();

  return AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = sourceFactory;
}

Iterable<UriResolver> getUriResolvers(Directory sdkDir) {
  final resolvers = <UriResolver>[];
  final instance = PhysicalResourceProvider.INSTANCE;
  final sdk = new FolderBasedDartSdk(instance, instance.getFolder(sdkDir.path));
  final cwd = instance.getFolder(Directory.current.path);

  final packageMap = new PubPackageMapProvider(instance, sdk)
      .computePackageMap(cwd)
      .packageMap;

  if (packageMap != null) {
    resolvers
      ..add(new SdkExtUriResolver(packageMap))
      ..add(new PackageMapUriResolver(instance, packageMap));
  }
  resolvers
    ..add(new DartUriResolver(sdk))
    ..add(new fs.ResourceUriResolver(instance));

  return resolvers;
}

Directory getSdkDir() {
  File vmExecutable = new File(Platform.resolvedExecutable);
  return vmExecutable.parent.parent;
}

Iterable<String> getPackageEntryPoints(List<String> targets) {
  final currentPath = Directory.current.path;
  var targetPaths = targets.map((target) => path.join(currentPath, target));

  var lib = new Directory(path.join(currentPath, 'lib'));
  if (!lib.existsSync()) return [];

  bool entityIsDartFile(FileSystemEntity entity) {
    return entity is File && entity.path.endsWith('.dart');
  }

  bool fileIsNotInPackagesDir(FileSystemEntity file) {
    return !file.path.contains('${path.separator}packages');
  }

  bool fileIsInLibPath(FileSystemEntity file) {
    return targetPaths
        .any((targetPath) => path.isWithin(targetPath, file.path));
  }

  bool fileIsNotPartOf(FileSystemEntity entity) {
    final File file = entity;
    final contents = file.readAsStringSync();

    return !contents.contains(newLinePartOfRegexp) &&
        !contents.startsWith(partOfRegexp);
  }

  return lib
      .listSync(followLinks: false, recursive: true)
      .where(entityIsDartFile)
      .where(fileIsNotInPackagesDir)
      .where(fileIsInLibPath)
      .where(fileIsNotPartOf)
      .map((entity) =>
          path.relative(entity.absolute.path, from: Directory.current.path));
}

Iterable<Source> parseSources(
    AnalysisContext context, Iterable<String> libraryFilePaths) {
  final sources = <Source>[];

  for (final filePath in libraryFilePaths) {
    String name = filePath;
    if (name.startsWith(Directory.current.path)) {
      name = name.substring(Directory.current.path.length);
      if (name.startsWith(Platform.pathSeparator)) name = name.substring(1);
    }
    final javaFile = new JavaFile(filePath).getAbsoluteFile();
    Source source = new FileBasedSource(javaFile);
    final uri = context.sourceFactory.restoreUri(source);
    if (uri != null) {
      source = new FileBasedSource(javaFile, uri);
    }
    sources.add(source);
  }

  return sources;
}

void verifyAnalysis(AnalysisContext context, Iterable<Source> sources) {
  AnalysisResult result = context.performAnalysisTask();
  while (result.hasMoreWork) {
    result = context.performAnalysisTask();
  }

  for (Source source in sources) {
    try {
      context.computeErrors(source);
    } catch (e) {
      print('Analysis computer errors failed: ${e}');
//      exit(1);
      print('Attempting to ignore');
    }

    final errors = context.getErrors(source).errors;
    if (errors.isNotEmpty) {
//      print('Analysis failed:\n${errors.first.toString()}');
//      exit(1);
//      print('Attempting to ignore');
    }
  }
}

List<ClassElement> getSubclassesOfLifecycleModule(LibraryElement library) =>
    library.definingCompilationUnit.types.where((e) {
      print('does ${e.name} do the thing');
      return
        e is ClassElement &&
        !e.isEnum &&
          doesTypeExtendLifecycleModule(e.supertype);
    });

bool doesTypeExtendLifecycleModule(InterfaceType e) {
  print('checking ${e?.name}');

  if (e == null) {
    print('no');
    return false;
  }

  if (e.name == 'LifecycleModule') {
    print('yes');
    return true;
  }

  return doesTypeExtendLifecycleModule(e.superclass);
}
