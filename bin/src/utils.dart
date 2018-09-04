import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
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
import 'package:path/path.dart' as path;

final RegExp newLinePartOfRegexp = new RegExp('\npart of ');
final RegExp partOfRegexp = new RegExp('part of ');

Iterable<ClassElement> moduleClassesWithoutNames(
    AnalysisContext context, Directory sdkDir) {
  final entryPoints = getPackageEntryPoints();
  final sources = parseSources(context, entryPoints);
  verifyAnalysis(context, sources);

  return parseLibraries(context, sources)
      .expand(getSubclassesOfLifecycleModule)
      .where((element) => element.getField('name') == null);
}

Map<Source, List<ClassElement>> groupClassesBySource(
    List<ClassElement> classes) {
  final Map<Source, List<ClassElement>> results = {};

  classes.forEach((c) {
    if (results.containsKey(c.source)) {
      results[c.source].add(c);
    } else {
      results[c.source] = [c];
    }
  });

  return results;
}

void writeGettersForSource(Source source, List<ClassElement> classes) {
  // Sort descending to modify the bottom classes before the top
  classes.sort((a, b) => b.computeNode().end - a.computeNode().end);

  classes.forEach(writeGetterForClass);
}

void writeGetterForClass(ClassElement e) {
  final ePath = e.source.uri.path;

  String filePath = ePath.substring(ePath.indexOf('/') + 1);

  File f = new File('lib/$filePath');
  if (!f.existsSync()) {
    stdout.writeln('Does not exist: ${f.path}');
    exit(1);
  }

  final StringBuffer outputLines = new StringBuffer();

  final source = f.readAsStringSync();
  // The offset of the end of the class's opening '{' bracket token
  // ignore: avoid_as
  final insertionOffset = (e.computeNode() as ClassDeclaration).leftBracket.end;

  outputLines
    ..writeln(source.substring(0, insertionOffset))
    ..writeln('  @override')
    ..writeln('  String get name => \'${e.name}\';')
    ..write(source.substring(insertionOffset));

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

Iterable<String> getPackageEntryPoints() {
  final currentPath = Directory.current.path;
  final libPath = path.join(currentPath, 'lib');

  final lib = new Directory(libPath);
  if (!lib.existsSync()) return [];

  bool entityIsDartFile(FileSystemEntity entity) {
    return entity is File && entity.path.endsWith('.dart');
  }

  bool fileIsNotInPackagesDir(FileSystemEntity file) {
    return !file.path.contains('${path.separator}packages');
  }

  bool fileIsInLibPath(FileSystemEntity file) {
    return path.isWithin(libPath, file.path);
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
}

List<ClassElement> getSubclassesOfLifecycleModule(LibraryElement library) =>
    library.definingCompilationUnit.types.where((e) {
      return e is ClassElement &&
          !e.isEnum &&
          doesTypeExtendLifecycleModule(e.supertype);
    });

bool doesTypeExtendLifecycleModule(InterfaceType e) {
  if (e == null) {
    return false;
  }

  if (e.name == 'LifecycleModule') {
    return true;
  }

  return doesTypeExtendLifecycleModule(e.superclass);
}

void runMoveCommand(String from, String to) {
  Process.runSync('mv', [from, to]);
}

void moveTargetsIntoLib(List<String> targets) {
  targets.forEach((target) {
    runMoveCommand(target, tempNameForTarget(target));
  });
}

void moveTargetsOutOfLib(List<String> targets) {
  targets.forEach((target) {
    runMoveCommand(tempNameForTarget(target), target);
  });
}

String tempNameForTarget(String target) => 'lib/w_module_temp_$target';
