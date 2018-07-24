// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exports all API from Kernel's ast.dart that can be used
/// throughout fasta.
library fasta.kernel_ast_api;

export 'package:kernel/ast.dart'
    show
        Arguments,
        AssertStatement,
        AsyncMarker,
        Block,
        BreakStatement,
        Catch,
        CheckLibraryIsLoaded,
        Class,
        Constructor,
        ConstructorInvocation,
        ContinueSwitchStatement,
        DartType,
        DynamicType,
        EmptyStatement,
        Expression,
        ExpressionStatement,
        Field,
        FunctionDeclaration,
        FunctionNode,
        FunctionType,
        Initializer,
        InvalidType,
        LabeledStatement,
        Let,
        Library,
        LibraryDependency,
        LibraryPart,
        ListLiteral,
        Location,
        Member,
        MethodInvocation,
        Name,
        NamedExpression,
        NamedType,
        Node,
        Procedure,
        ProcedureKind,
        PropertySet,
        Rethrow,
        ReturnStatement,
        Statement,
        StaticGet,
        StaticInvocation,
        StaticSet,
        StringConcatenation,
        SuperInitializer,
        SuperMethodInvocation,
        SuperPropertySet,
        SwitchCase,
        Throw,
        TreeNode,
        Typedef,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet,
        VariableSet,
        VoidType,
        setParents;

export 'kernel_shadow_ast.dart'
    show
        ArgumentsJudgment,
        AssertInitializerJudgment,
        AssertStatementJudgment,
        BreakJudgment,
        CascadeJudgment,
        ComplexAssignmentJudgment,
        ConstructorInvocationJudgment,
        ContinueSwitchJudgment,
        DeferredCheckJudgment,
        ExpressionJudgment,
        ExpressionStatementJudgment,
        FactoryConstructorInvocationJudgment,
        ShadowFieldInitializer,
        ForInJudgment,
        FunctionDeclarationJudgment,
        FunctionExpressionJudgment,
        FunctionNodeJudgment,
        IfNullJudgment,
        IfJudgment,
        IllegalAssignmentJudgment,
        IndexAssignmentJudgment,
        InvalidConstructorInvocationJudgment,
        InvalidPropertyGetJudgment,
        InvalidStatementJudgment,
        InvalidSuperInitializerJudgment,
        InvalidVariableWriteJudgment,
        InvalidWriteJudgment,
        ShadowInvalidFieldInitializer,
        ShadowInvalidInitializer,
        LabeledStatementJudgment,
        LoadLibraryTearOffJudgment,
        LogicalJudgment,
        MethodInvocationJudgment,
        NamedFunctionExpressionJudgment,
        NullAwareMethodInvocationJudgment,
        NullAwarePropertyGetJudgment,
        PropertyAssignmentJudgment,
        PropertyGetJudgment,
        RedirectingInitializerJudgment,
        ReturnJudgment,
        StaticAssignmentJudgment,
        StaticGetJudgment,
        StaticInvocationJudgment,
        SuperInitializerJudgment,
        SuperMethodInvocationJudgment,
        SuperPropertyGetJudgment,
        SwitchCaseJudgment,
        SwitchStatementJudgment,
        SyntheticExpressionJudgment,
        ThrowJudgment,
        UnresolvedTargetInvocationJudgment,
        UnresolvedVariableGetJudgment,
        UnresolvedVariableAssignmentJudgment,
        UnresolvedVariableUnaryJudgment,
        VariableAssignmentJudgment,
        VariableDeclarationJudgment,
        VariableGetJudgment,
        YieldJudgment,
        NamedExpressionJudgment;
