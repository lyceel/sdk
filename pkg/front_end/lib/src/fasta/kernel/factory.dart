// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show Catch, DartType, FunctionType, Node, TypeParameter;

import 'package:kernel/type_algebra.dart' show Substitution;

import '../../scanner/token.dart' show Token;

import 'kernel_shadow_ast.dart'
    show
        ExpressionJudgment,
        InitializerJudgment,
        StatementJudgment,
        SwitchCaseJudgment;

import 'kernel_type_variable_builder.dart' show KernelTypeVariableBuilder;

/// Abstract base class for factories that can construct trees of expressions,
/// statements, initializers, and literal types based on tokens, inferred types,
/// and invocation targets.
abstract class Factory<Expression, Statement, Initializer, Type> {
  Expression asExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token asOperator,
      Type literalType,
      DartType inferredType);

  Initializer assertInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message,
      Token rightParenthesis);

  Statement assertStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token assertKeyword,
      Token leftParenthesis,
      Expression condition,
      Token comma,
      Expression message,
      Token rightParenthesis,
      Token semicolon);

  Expression awaitExpression(ExpressionJudgment judgment, int fileOffset,
      Token awaitKeyword, Expression expression, DartType inferredType);

  Object binderForFunctionDeclaration(
      StatementJudgment judgment, int fileOffset, String name);

  Object binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name);

  Object binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name);

  Object binderForTypeVariable(
      KernelTypeVariableBuilder builder, int fileOffset, String name);

  Object binderForVariableDeclaration(
      StatementJudgment judgment, int fileOffset, String name);

  Statement block(StatementJudgment judgment, int fileOffset, Token leftBracket,
      List<Statement> statements, Token rightBracket);

  Expression boolLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, bool value, DartType inferredType);

  Statement breakStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token breakKeyword,
      Expression label,
      Token semicolon,
      covariant Object labelBinder);

  Expression cascadeExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Object catchStatement(
      Catch judgment,
      int fileOffset,
      Token onKeyword,
      Type type,
      Token catchKeyword,
      Token leftParenthesis,
      Token exceptionParameter,
      Token comma,
      Token stackTraceParameter,
      Token rightParenthesis,
      Statement body,
      covariant Object exceptionBinder,
      DartType exceptionType,
      covariant Object stackTraceBinder,
      DartType stackTraceType);

  Expression conditionalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression condition,
      Token question,
      Expression thenExpression,
      Token colon,
      Expression elseExpression,
      DartType inferredType);

  Expression constructorInvocation(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType);

  Statement continueStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token continueKeyword,
      Expression label,
      Token semicolon,
      covariant Object labelBinder);

  Statement continueSwitchStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token continueKeyword,
      Expression label,
      Token semicolon,
      covariant Object labelBinder);

  Expression deferredCheck(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Statement doStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token doKeyword,
      Statement body,
      Token whileKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Token semicolon);

  Expression doubleLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, double value, DartType inferredType);

  Statement emptyStatement(Token semicolon);

  Statement expressionStatement(StatementJudgment judgment, int fileOffset,
      Expression expression, Token semicolon);

  Initializer fieldInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token thisKeyword,
      Token period,
      Token fieldName,
      Token equals,
      Expression expression,
      Node initializerField);

  Statement forInStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      covariant Object loopVariable,
      Token identifier,
      Token inKeyword,
      Expression iterator,
      Token rightParenthesis,
      Statement body,
      covariant Object loopVariableBinder,
      DartType loopVariableType,
      int writeOffset,
      DartType writeVariableType,
      covariant Object writeVariableBinder,
      Node writeTarget);

  Statement forStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token forKeyword,
      Token leftParenthesis,
      covariant Object variableDeclarationList,
      Expression initialization,
      Token leftSeparator,
      Expression condition,
      Token rightSeparator,
      List<Expression> updaters,
      Token rightParenthesis,
      Statement body);

  Statement functionDeclaration(
      covariant Object binder, FunctionType inferredType);

  Expression functionExpression(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Object functionType(int fileOffset, DartType type);

  Object functionTypedFormalParameter(int fileOffset, DartType type);

  Expression ifNull(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression leftOperand,
      Token operator,
      Expression rightOperand,
      DartType inferredType);

  Statement ifStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token ifKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Statement thenStatement,
      Token elseKeyword,
      Statement elseStatement);

  Expression indexAssign(ExpressionJudgment judgment, int fileOffset,
      Node writeMember, Node combiner, DartType inferredType);

  Expression intLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, num value, DartType inferredType);

  Initializer invalidInitializer(InitializerJudgment judgment, int fileOffset);

  Expression isExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token isOperator,
      Type literalType,
      DartType inferredType);

  Expression isNotExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression expression,
      Token isOperator,
      Token notOperator,
      Type literalType,
      DartType inferredType);

  Statement labeledStatement(List<Object> labels, Statement statement);

  Expression listLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token constKeyword,
      covariant Object typeArguments,
      Token leftBracket,
      List<Expression> elements,
      Token rightBracket,
      DartType inferredType);

  Expression logicalExpression(
      ExpressionJudgment judgment,
      int fileOffset,
      Expression leftOperand,
      Token operator,
      Expression rightOperand,
      DartType inferredType);

  Expression mapLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token constKeyword,
      covariant Object typeArguments,
      Token leftBracket,
      List<Object> entries,
      Token rightBracket,
      DartType inferredType);

  Object mapLiteralEntry(Object judgment, int fileOffset, Expression key,
      Token separator, Expression value);

  Expression methodInvocation(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Node interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  Expression methodInvocationCall(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  Expression namedFunctionExpression(ExpressionJudgment judgment,
      covariant Object binder, DartType inferredType);

  Expression not(ExpressionJudgment judgment, int fileOffset, Token operator,
      Expression operand, DartType inferredType);

  Expression nullLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, bool isSynthetic, DartType inferredType);

  Expression propertyAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType);

  Expression propertyGet(ExpressionJudgment judgment, int fileOffset,
      bool forSyntheticToken, Node member, DartType inferredType);

  Expression propertyGetCall(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Expression propertySet(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Initializer redirectingInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token thisKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList,
      Node initializerTarget);

  Expression rethrow_(ExpressionJudgment judgment, int fileOffset,
      Token rethrowKeyword, DartType inferredType);

  Statement returnStatement(StatementJudgment judgment, int fileOffset,
      Token returnKeyword, Expression expression, Token semicolon);

  Object statementLabel(covariant Object binder, Token label, Token colon);

  Expression staticAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType);

  Expression staticGet(ExpressionJudgment judgment, int fileOffset,
      Node expressionTarget, DartType inferredType);

  Expression staticInvocation(
      ExpressionJudgment judgment,
      int fileOffset,
      Node expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType);

  /// TODO(paulberry): this isn't really shaped properly for a factory class.
  void storeClassReference(int fileOffset, Node reference, DartType rawType);

  /// TODO(paulberry): this isn't really shaped properly for a factory class.
  void storePrefixInfo(int fileOffset, int prefixImportIndex);

  Expression stringConcatenation(
      ExpressionJudgment judgment, int fileOffset, DartType inferredType);

  Expression stringLiteral(ExpressionJudgment judgment, int fileOffset,
      Token literal, String value, DartType inferredType);

  Initializer superInitializer(
      InitializerJudgment judgment,
      int fileOffset,
      Token superKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList);

  Object switchCase(
      SwitchCaseJudgment judgment,
      List<Object> labels,
      Token keyword,
      Expression expression,
      Token colon,
      List<Statement> statements);

  Object switchLabel(covariant Object binder, Token label, Token colon);

  Statement switchStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token switchKeyword,
      Token leftParenthesis,
      Expression expression,
      Token rightParenthesis,
      Token leftBracket,
      List<Object> members,
      Token rightBracket);

  Expression symbolLiteral(
      ExpressionJudgment judgment,
      int fileOffset,
      Token poundSign,
      List<Token> components,
      String value,
      DartType inferredType);

  Expression thisExpression(ExpressionJudgment judgment, int fileOffset,
      Token thisKeyword, DartType inferredType);

  Expression throw_(ExpressionJudgment judgment, int fileOffset,
      Token throwKeyword, Expression expression, DartType inferredType);

  Statement tryCatch(StatementJudgment judgment, int fileOffset);

  Statement tryFinally(
      StatementJudgment judgment,
      int fileOffset,
      Token tryKeyword,
      Statement body,
      List<Object> catchClauses,
      Token finallyKeyword,
      Statement finallyBlock);

  Expression typeLiteral(ExpressionJudgment judgment, int fileOffset,
      Node expressionType, DartType inferredType);

  Type typeReference(
      int fileOffset,
      bool forSyntheticToken,
      Token leftBracket,
      List<Type> typeArguments,
      Token rightBracket,
      Node reference,
      covariant Object binder,
      DartType type);

  Object typeVariableDeclaration(
      int fileOffset, covariant Object binder, TypeParameter typeParameter);

  Expression variableAssign(
      ExpressionJudgment judgment,
      int fileOffset,
      DartType writeContext,
      covariant Object writeVariableBinder,
      Node combiner,
      DartType inferredType);

  Statement variableDeclaration(covariant Object binder, DartType inferredType);

  Expression variableGet(
      ExpressionJudgment judgment,
      int fileOffset,
      bool forSyntheticToken,
      bool isInCascade,
      covariant Object variableBinder,
      DartType inferredType);

  Statement whileStatement(
      StatementJudgment judgment,
      int fileOffset,
      Token whileKeyword,
      Token leftParenthesis,
      Expression condition,
      Token rightParenthesis,
      Statement body);

  Statement yieldStatement(StatementJudgment judgment, int fileOffset,
      Token yieldKeyword, Token star, Expression expression, Token semicolon);
}
