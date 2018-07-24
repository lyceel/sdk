// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/kernel_type_variable_builder.dart';
import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart'
    show Catch, DartType, FunctionType, Node, TypeParameter;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'factory.dart' show Factory;

import 'kernel_shadow_ast.dart'
    show
        ExpressionJudgment,
        InitializerJudgment,
        StatementJudgment,
        SwitchCaseJudgment;

import 'kernel_type_variable_builder.dart' show KernelTypeVariableBuilder;

const toplevelInferenceFactory = const ToplevelInferenceFactory();

/// Implementation of [Factory] for use during top level type inference, when
/// no representation of the code semantics needs to be created (only the type
/// needs to be inferred).
class ToplevelInferenceFactory implements Factory<void, void, void, void> {
  const ToplevelInferenceFactory();

  @override
  void asExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void expression,
      Token asOperator,
      void literalType,
      DartType inferredType) {}

  @override
  void assertInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis) {}

  @override
  void assertStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis,
      Token semicolon) {}

  @override
  void awaitExpression(ExpressionJudgment judgment, int fileOffset,
      Token awaitKeyword, void expression, DartType inferredType) {}

  @override
  void binderForFunctionDeclaration(
      StatementJudgment judgment, int fileOffset, String name) {}

  @override
  void binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name) {}

  @override
  void binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name) {}

  @override
  void binderForTypeVariable(
      KernelTypeVariableBuilder builder, int fileOffset, String name) {}

  @override
  void binderForVariableDeclaration(
      StatementJudgment judgment, int fileOffset, String name) {}

  @override
  void block(StatementJudgment judgment, int fileOffset, Token leftBracket,
      void statements, Token rightBracket) {}

  @override
  void boolLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      bool value, DartType inferredType) {}

  @override
  void breakStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token breakKeyword,
      void label,
      Token semicolon,
      covariant void labelBinder) {}

  @override
  void cascadeExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  Object catchStatement(
      Catch judgment,
      int fileOffset,
      Token onKeyword,
      void type,
      Token catchKeyword,
      Token leftParenthesis,
      Token exceptionParameter,
      Token comma,
      Token stackTraceParameter,
      Token rightParenthesis,
      void body,
      covariant void exceptionBinder,
      DartType exceptionType,
      covariant void stackTraceBinder,
      DartType stackTraceType) {
    return judgment;
  }

  @override
  void conditionalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void condition,
      Token question,
      void thenExpression,
      Token colon,
      void elseExpression,
      DartType inferredType) {}

  @override
  void constructorInvocation(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType) {}

  @override
  void continueStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token continueKeyword,
      void label,
      Token semicolon,
      covariant void labelBinder) {}

  @override
  void continueSwitchStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token continueKeyword,
      void label,
      Token semicolon,
      covariant void labelBinder) {}

  @override
  void deferredCheck(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void doStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token doKeyword,
      void body,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      Token semicolon) {}

  @override
  void doubleLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      double value, DartType inferredType) {}

  @override
  void emptyStatement(Token semicolon) {}

  @override
  void expressionStatement(StatementJudgment judgment, int fileOffset,
      void expression, Token semicolon) {}

  @override
  void fieldInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token thisKeyword,
      Token period,
      Token fieldName,
      Token equals,
      void expression,
      Node initializerField) {}

  @override
  void forInStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      Object loopVariable,
      Token identifier,
      Token inKeyword,
      void iterator,
      Token rightParenthesis,
      void body,
      covariant void loopVariableBinder,
      DartType loopVariableType,
      int writeOffset,
      DartType writeVariableType,
      covariant void writeVariableBinder,
      Node writeTarget) {}

  @override
  void forStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token forKeyword,
      Token leftParenthesis,
      void variableDeclarationList,
      void initialization,
      Token leftSeparator,
      void condition,
      Token rightSeparator,
      void updaters,
      Token rightParenthesis,
      void body) {}

  @override
  void functionDeclaration(covariant void binder, FunctionType inferredType) {}

  @override
  void functionExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void functionType(int fileOffset, DartType type) {}

  @override
  void functionTypedFormalParameter(int fileOffset, DartType type) {}

  @override
  void ifNull(ExpressionJudgment judgment, int fileOffset, void leftOperand,
      Token operator, void rightOperand, DartType inferredType) {}

  @override
  void ifStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token ifKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void thenStatement,
      Token elseKeyword,
      void elseStatement) {}

  @override
  void indexAssign(ExpressionJudgment judgment, int fileOffset,
      Node writeMember, Node combiner, DartType inferredType) {}

  @override
  void intLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      num value, DartType inferredType) {}

  @override
  void invalidInitializer(InitializerJudgment judgment, int fileOffset) {}

  @override
  void isExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void expression,
      Token isOperator,
      void literalType,
      DartType inferredType) {}

  @override
  void isNotExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void expression,
      Token isOperator,
      Token notOperator,
      void literalType,
      DartType inferredType) {}

  @override
  void labeledStatement(List<Object> labels, void statement) {}

  @override
  void listLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token constKeyword,
      Object typeArguments,
      Token leftBracket,
      void elements,
      Token rightBracket,
      DartType inferredType) {}

  @override
  void logicalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      void leftOperand,
      Token operator,
      void rightOperand,
      DartType inferredType) {}

  @override
  void mapLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token constKeyword,
      void typeArguments,
      Token leftBracket,
      void entries,
      Token rightBracket,
      DartType inferredType) {}

  @override
  void mapLiteralEntry(
      Object judgment, int fileOffset, void key, Token separator, void value) {}

  @override
  void methodInvocation(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Node interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void methodInvocationCall(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void namedFunctionExpression(ExpressionJudgment judgment,
      covariant void binder, DartType inferredType) {}

  @override
  void not(ExpressionJudgment judgment, int fileOffset, Token operator,
      void operand, DartType inferredType) {}

  @override
  void nullLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      bool isSynthetic, DartType inferredType) {}

  @override
  void propertyAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType) {}

  @override
  void propertyGet(ExpressionJudgment judgment, int fileOffset,
      bool forSyntheticToken, Node member, DartType inferredType) {}

  @override
  void propertyGetCall(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void propertySet(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void redirectingInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token thisKeyword,
      Token period,
      Token constructorName,
      Object argumentList,
      Node initializerTarget) {}

  @override
  void rethrow_(ExpressionJudgment judgment, int fileOffset,
      Token rethrowKeyword, DartType inferredType) {}

  @override
  void returnStatement(StatementJudgment judgment, int fileOffset,
      Token returnKeyword, void expression, Token semicolon) {}

  @override
  void statementLabel(covariant void binder, Token label, Token colon) {}

  @override
  void staticAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType) {}

  @override
  void staticGet(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType) {}

  @override
  void staticInvocation(
      ExpressionJudgment judgment,
      int fileOffset,
      Node expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {}

  @override
  void storeClassReference(int fileOffset, Node reference, DartType rawType) {}

  @override
  void storePrefixInfo(int fileOffset, int prefixImportIndex) {}

  @override
  void stringConcatenation(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType) {}

  @override
  void stringLiteral(ExpressionJudgment judgment, int fileOffset, Token literal,
      String value, DartType inferredType) {}

  @override
  void superInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token superKeyword,
      Token period,
      Token constructorName,
      Object argumentList) {}

  @override
  void switchCase(SwitchCaseJudgment judgment, List<Object> labels,
      Token keyword, void expression, Token colon, List<void> statements) {}

  @override
  void switchLabel(covariant void binder, Token label, Token colon) {}

  @override
  void switchStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token switchKeyword,
      Token leftParenthesis,
      void expression,
      Token rightParenthesis,
      Token leftBracket,
      void members,
      Token rightBracket) {}

  @override
  void symbolLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token poundSign,
      List<Token> components,
      String value,
      DartType inferredType) {}

  @override
  void thisExpression(ExpressionJudgment judgment, int fileOffset,
      Token thisKeyword, DartType inferredType) {}

  @override
  void throw_(ExpressionJudgment judgment, int fileOffset, Token throwKeyword,
      void expression, DartType inferredType) {}

  @override
  void tryCatch(StatementJudgment judgment, int fileOffset) {}

  @override
  void tryFinally(StatementJudgment judgment, int fileOffset, Token tryKeyword,
      void body, void catchClauses, Token finallyKeyword, void finallyBlock) {}

  @override
  void typeLiteral(ExpressionJudgment judgment, int fileOffset,
      Node expressionType, DartType inferredType) {}

  @override
  void typeReference(
      int fileOffset,
      bool forSyntheticToken,
      Token leftBracket,
      List<void> typeArguments,
      Token rightBracket,
      Node reference,
      covariant void binder,
      DartType type) {}

  @override
  void typeVariableDeclaration(
      int fileOffset, covariant void binder, TypeParameter typeParameter) {}

  @override
  void variableAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      DartType writeContext,
      covariant void writeVariableBinder,
      Node combiner,
      DartType inferredType) {}

  @override
  void variableDeclaration(covariant void binder, DartType inferredType) {}

  @override
  void variableGet(
      ExpressionJudgment judgment,
      int fileOffset,
      bool forSyntheticToken,
      bool isInCascade,
      covariant void variableBinder,
      DartType inferredType) {}

  @override
  void whileStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void body) {}

  @override
  void yieldStatement(StatementJudgment judgment, int fileOffset,
      Token yieldKeyword, Token star, void expression, Token semicolon) {}
}
