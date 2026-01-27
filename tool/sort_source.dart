// ignore_for_file: avoid_print

import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

void main(List<String> args) {
  final Directory dir = Directory('lib');

  // Defer scanning until after first print
  final List<FileSystemEntity> files = <FileSystemEntity>[];

  for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity);
    }
  }

  // Sort files by folder depth (shallow first), then alphabetically by path
  files.sort((FileSystemEntity a, FileSystemEntity b) {
    final int depthA = a.path.split(Platform.pathSeparator).length;
    final int depthB = b.path.split(Platform.pathSeparator).length;
    if (depthA != depthB) {
      return depthA.compareTo(depthB);
    }
    return a.path.compareTo(b.path);
  });

  for (final FileSystemEntity fileEntity in files) {
    final File file = fileEntity as File;
    final String content = file.readAsStringSync();

    final ParseStringResult result = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    final CompilationUnit compilationUnit = result.unit;

    final ClassVisitor classVisitor = ClassVisitor();
    compilationUnit.accept(classVisitor);

    String newContent = content;
    bool fileHasChanges = false;

    for (final ClassDeclaration classNode in classVisitor.targetClasses.reversed) {
      final MemberSorter sorter = MemberSorter(content, classNode);
      final String sortedBody = sorter.getSortedBody();

      final BlockClassBody body = classNode.body as BlockClassBody;
      final int classBodyStart = body.leftBracket.offset + 1;
      final int classBodyEnd = body.rightBracket.offset;
      final String originalBody = content.substring(
        classBodyStart,
        classBodyEnd,
      );

      if (sortedBody.trim().replaceAll(RegExp(r'\s+'), ' ') != originalBody.trim().replaceAll(RegExp(r'\s+'), ' ')) {
        fileHasChanges = true;
        newContent = newContent.substring(0, classBodyStart) + sortedBody + newContent.substring(classBodyEnd);
      }
    }

    if (fileHasChanges) {
      file.writeAsStringSync(newContent);
    }
  }
}

/// Finds classes that we want to sort: StatelessWidget, StatefulWidget, or
/// State<...> classes (the typical Flutter patterns).
class ClassVisitor extends GeneralizingAstVisitor<void> {
  final List<ClassDeclaration> targetClasses = <ClassDeclaration>[];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final ExtendsClause? extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final String superName = extendsClause.superclass.toString();
      // Match StatelessWidget, StatefulWidget, or State (including generics: State<MyWidget>)
      if (superName == 'StatelessWidget' ||
          superName == 'StatefulWidget' ||
          superName == 'State' ||
          superName.startsWith('State<')) {
        targetClasses.add(node);
      }
    }
    super.visitClassDeclaration(node);
  }
}

/// Sorts members inside a class body so that:
/// 1) non-method members (fields, constructors, etc.) remain first in their original order
/// 2) all public methods (alphabetical) come next
/// 3) all private methods (alphabetical) come last
class MemberSorter {
  MemberSorter(this._content, this._classNode);
  final String _content;
  final ClassDeclaration _classNode;

  String getSortedBody() {
    final BlockClassBody body = _classNode.body as BlockClassBody;
    final NodeList<ClassMember> members = body.members;
    if (members.isEmpty) {
      return '';
    }

    final List<String> otherMembers = <String>[];
    final List<_SortableMethod> lifecycleMethods = <_SortableMethod>[];
    final List<_SortableMethod> publicMethods = <_SortableMethod>[];
    final List<_SortableMethod> privateMethods = <_SortableMethod>[];

    final Set<String> lifecycleMethodNames = <String>{
      'initState',
      'dispose',
      'didUpdateWidget',
      'build',
    };

    // Map from field name to list of member sources (field + associated getters/setters)
    final Map<String, List<String>> fieldGroups = <String, List<String>>{};
    // Keep track of which members have been grouped (to skip later)
    final Set<ClassMember> groupedMembers = <ClassMember>{};

    // First, group FieldDeclarations and their associated PropertyAccessorDeclarations
    for (final ClassMember member in members) {
      if (member is FieldDeclaration) {
        // For each variable declared in the field
        for (final VariableDeclaration variable in member.fields.variables) {
          final String name = variable.name.lexeme;
          final List<String> groupSources = <String>[];
          groupSources.add(_getSource(member));
          fieldGroups[name] = groupSources;
          groupedMembers.add(member);
        }
      }
    }

    // Now associate PropertyAccessorDeclarations (getters/setters) with their fields if possible
    for (final ClassMember member in members) {
      if (member is MethodDeclaration && (member.isGetter || member.isSetter)) {
        final String name = member.name.lexeme;
        if (fieldGroups.containsKey(name)) {
          fieldGroups[name]!.add(_getSource(member));
          groupedMembers.add(member);
        }
      }
    }

    // Add non-field, non-method members (e.g., constructors) in original order at the top
    for (final ClassMember member in members) {
      if (!groupedMembers.contains(member) && member is! MethodDeclaration) {
        otherMembers.add(_getSource(member));
      }
    }

    // Collect fields and their grouped accessors into a list and sort alphabetically
    final List<_SortableField> sortedFields = <_SortableField>[];
    for (final String fieldName in fieldGroups.keys) {
      sortedFields.add(_SortableField(fieldName, fieldGroups[fieldName]!));
    }
    sortedFields.sort(
      (_SortableField a, _SortableField b) => a.name.compareTo(b.name),
    );

    // Add sorted fields to otherMembers
    for (final _SortableField field in sortedFields) {
      otherMembers.addAll(field.sources);
    }

    // Now process standalone methods only (exclude getters/setters which were grouped)
    for (final ClassMember member in members) {
      if (member is MethodDeclaration && !groupedMembers.contains(member)) {
        final String name = member.name.lexeme;
        if (lifecycleMethodNames.contains(name)) {
          lifecycleMethods.add(_SortableMethod(name, _getSource(member)));
        } else if (name.startsWith('_')) {
          privateMethods.add(_SortableMethod(name, _getSource(member)));
        } else {
          publicMethods.add(_SortableMethod(name, _getSource(member)));
        }
      }
    }

    // Sort lifecycle methods in fixed order (preserve exact order as in lifecycleOrder)
    final List<String> lifecycleOrder = <String>[
      'initState',
      'dispose',
      'didUpdateWidget',
      'build',
    ];
    final Map<String, int> lifecycleOrderMap = <String, int>{
      for (int i = 0; i < lifecycleOrder.length; i++) lifecycleOrder[i]: i,
    };
    lifecycleMethods.sort(
      (_SortableMethod a, _SortableMethod b) => (lifecycleOrderMap[a.name] ?? 999).compareTo(
        lifecycleOrderMap[b.name] ?? 999,
      ),
    );
    publicMethods.sort(
      (_SortableMethod a, _SortableMethod b) => a.name.compareTo(b.name),
    );

    privateMethods.sort(
      (_SortableMethod a, _SortableMethod b) => a.name.compareTo(b.name),
    );

    final List<String> parts = <String>[];
    if (otherMembers.isNotEmpty) {
      parts.addAll(otherMembers.map((String s) => s.trimRight()));
    }
    if (lifecycleMethods.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add('');
      }
      parts.addAll(
        lifecycleMethods.map((_SortableMethod m) => m.source.trimRight()),
      );
    }
    if (publicMethods.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add('');
      }
      parts.addAll(
        publicMethods.map((_SortableMethod m) => m.source.trimRight()),
      );
    }
    if (privateMethods.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add('');
      }
      parts.addAll(
        privateMethods.map((_SortableMethod m) => m.source.trimRight()),
      );
    }

    final String result = parts.join('\n\n');
    return result.isEmpty ? '' : '\n$result\n';
  }

  String _getSource(AstNode node) => _content.substring(node.offset, node.end);
}

class _SortableMethod {
  _SortableMethod(this.name, this.source);
  final String name;
  final String source;
}

class _SortableField {
  _SortableField(this.name, this.sources);
  final String name;
  final List<String> sources;
}
