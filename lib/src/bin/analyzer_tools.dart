import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart' as fs;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/engine.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/java_io.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/source_io.dart'; // ignore: implementation_imports
import 'package:path/path.dart' as path;

final RegExp newLinePartOfRegexp = new RegExp('\npart of ');
final RegExp partOfRegexp = new RegExp('part of ');

final Directory sdkDir = new File(Platform.resolvedExecutable).parent.parent;
final AnalysisContext context = _createAnalysisContext(sdkDir);

Map<Source, List<ClassElement>> getModulesWithoutNamesBySource(
    {Directory packageDir}) {
  final entryPoints = _getPackageEntryPoints(packageDir);
  final sources = _parseSources(context, entryPoints);
  _verifyAnalysis(context, sources);

  final Iterable<LibraryElement> libraries =
      sources.where(isLibrary).map(asLibraryElement);

  final Iterable<ClassElement> subclasses = libraries
      .expand(getSubclassesOfLifecycleModule)
      .where(isConcreteClass)
      .where(isNameGetterMissing);

  return groupClassesBySource(subclasses);
}

bool isLibrary(Source source) =>
    source.uri != null && context.computeKindOf(source) == SourceKind.LIBRARY;

LibraryElement asLibraryElement(Source source) =>
    context.computeLibraryElement(source);

Iterable<ClassElement> getSubclassesOfLifecycleModule(LibraryElement library) =>
    library.definingCompilationUnit.types.where(_isSubtypeOfLifecycleModule);

bool _isSubtypeOfLifecycleModule(Element e) =>
    e is ClassElement &&
    !e.isEnum &&
    doesTypeExtendLifecycleModule(e.supertype);

bool doesTypeExtendLifecycleModule(InterfaceType e) =>
    e != null &&
    (e.name == 'LifecycleModule' ||
        doesTypeExtendLifecycleModule(e.superclass));

Map<Source, List<ClassElement>> groupClassesBySource(
    Iterable<ClassElement> classes) {
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

bool isConcreteClass(ClassElement element) => !element.isAbstract;

bool isNameGetterMissing(ClassElement element) =>
    element.getField('name')?.getter == null;

AnalysisContext _createAnalysisContext(Directory sdkDir) {
  final resolvers = _getUriResolvers(sdkDir);
  final sourceFactory = new SourceFactory(resolvers);

  AnalysisEngine.instance.processRequiredPlugins();

  return AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = sourceFactory;
}

Iterable<UriResolver> _getUriResolvers(Directory sdkDir) {
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

Iterable<String> _getPackageEntryPoints(Directory packageDir) {
  final currentPath = packageDir?.path ?? Directory.current.path;

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

Iterable<Source> _parseSources(
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

void _verifyAnalysis(AnalysisContext context, Iterable<Source> sources) {
  AnalysisResult result = context.performAnalysisTask();
  while (result.hasMoreWork) {
    result = context.performAnalysisTask();
  }
}
