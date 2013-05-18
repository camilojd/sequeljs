/**
 * Still pending:
 *  - UNION
 */

/* description: Parses SQL */
/* :tabSize=4:indentSize=4:noTabs=true: */
%lex

%options case-insensitive

%%

[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*   return 'QUALIFIED_IDENTIFIER'
[a-zA-Z_][a-zA-Z0-9_]*\.\*                       return 'QUALIFIED_STAR'
\s+                                              /* skip whitespace */
'SELECT'                                         return 'SELECT'
'FROM'                                           return 'FROM'
'WHERE'                                          return 'WHERE'
'DISTINCT'                                       return 'DISTINCT'
'BETWEEN'                                        return 'BETWEEN'
'GROUP BY'                                       return 'GROUP_BY'
'HAVING'                                         return 'HAVING'
'ORDER BY'                                       return 'ORDER_BY'
','                                              return 'COMMA'
'+'                                              return 'PLUS'
'-'                                              return 'MINUS'
'/'                                              return 'DIVIDE'
'*'                                              return 'STAR'
'%'                                              return 'MODULO'
'='                                              return 'CMP_EQUALS'
'!='                                             return 'CMP_NOTEQUALS'
'<>'                                             return 'CMP_NOTEQUALS_BASIC'
'>='                                             return 'CMP_GREATEROREQUAL'
'>'                                              return 'CMP_GREATER'
'<='                                             return 'CMP_LESSOREQUAL'
'<'                                              return 'CMP_LESS'
'('                                              return 'LPAREN'
')'                                              return 'RPAREN'
'||'                                             return 'CONCAT'
'AS'                                             return 'AS'
'ALL'                                            return 'ALL'
'ANY'                                            return 'ANY'
'SOME'                                           return 'SOME'
'EXISTS'                                         return 'EXISTS'
'IS'                                             return 'IS'
'IN'                                             return 'IN'
'ON'                                             return 'ON'
'AND'                                            return 'LOGICAL_AND'
'OR'                                             return 'LOGICAL_OR'
'NOT'                                            return 'LOGICAL_NOT'
'INNER'                                          return 'INNER'
'OUTER'                                          return 'OUTER'
'JOIN'                                           return 'JOIN'
'LEFT'                                           return 'LEFT'
'RIGHT'                                          return 'RIGHT'
'FULL'                                           return 'FULL'
'NATURAL'                                        return 'NATURAL'
'CROSS'                                          return 'CROSS'
'CASE'                                           return 'CASE'
'WHEN'                                           return 'WHEN'
'THEN'                                           return 'THEN'
'ELSE'                                           return 'ELSE'
'END'                                            return 'END'
'LIKE'                                           return 'LIKE'
'ASC'                                            return 'ASC'
'DESC'                                           return 'DESC'
'NULLS'                                          return 'NULLS'
'FIRST'                                          return 'FIRST'
'LAST'                                           return 'LAST'
['](\\.|[^'])*[']                                return 'STRING'
'NULL'                                           return 'NULL'
(true|false)                                     return 'BOOLEAN'
[0-9]+(\.[0-9]+)?                                return 'NUMERIC'
[a-zA-Z_][a-zA-Z0-9_]*                           return 'IDENTIFIER'
<<EOF>>                                          return 'EOF'
.                                                return 'INVALID'

/lex

%start main

%% /* language grammar */

main
    : selectClause EOF { return {nodeType: 'Main', value: $1}; } 
    ;

selectClause
    : SELECT selectExprList 
      FROM tableExprList
      optWhereClause optGroupByClause optHavingClause optOrderByClause
      { $$ = {nodeType: 'Select', columns: $2, from: $4, where:$5, groupBy:$6, having:$7, orderBy:$8}; }
    ;

optWhereClause
    : { $$ = null; }
    | WHERE expression { $$ = $2; }
    ;

optGroupByClause
    : { $$ = null; }
    | GROUP_BY commaSepExpressionList { $$ = $2; }
    ;

optHavingClause
    : { $$ = null; }
    | HAVING expression { $$ = $2; }
    ;

optOrderByClause
    : { $$ = null; }
    | ORDER_BY orderByList { $$ = $2; }
    ;

orderByList
    : orderByList COMMA orderByListItem { $$ = $1; $1.push($3); }
    | orderByListItem { $$ = [$1]; }
    ;

orderByListItem
    : expression optOrderByOrder optOrderByNulls { $$ = {expression:$1, orderByOrder: $2, orderByNulls: $3}; }
    ;
    
optOrderByOrder
    : { $$ = ''; }
    | ASC { $$ = $1; }
    | DESC { $$ = $1; }
    ;

optOrderByNulls
    : { $$ = '';}
    | NULLS FIRST { $$ = 'NULLS FIRST'; }
    | NULLS LAST { $$ = 'NULLS LAST'; }
    ;
    
selectExprList
    : selectExpr { $$ = [$1]; } 
    | selectExprList COMMA selectExpr { $$ = $1; $1.push($3); }
    ;

selectExpr
    : STAR { $$ = {nodeType: 'Column', value:'*'}; }
    | QUALIFIED_STAR  { $$ = {nodeType: 'Column', value:$1}; }
    | expression optTableExprAlias  { $$ = {nodeType: 'Column', value:$1, alias:$2}; }
    ;

tableExprList
    : tableExpr { $$ = [$1]; }
    | tableExprList COMMA tableExpr { $$ = $1; $1.push($3); }
    ;

tableExpr
    : joinComponent { $$ = {nodeType:'TableExpr', value: [$1]}; }
    | tableExpr optJoinModifier JOIN joinComponent { $$ = $1; $1.value.push({nodeType:'TableExpr', value: $4, modifier:$2}); }
    | tableExpr optJoinModifier JOIN joinComponent ON expression { $$ = $1; $1.value.push({nodeType:'TableExpr', value: $4, modifier:$2, expression:$6}); }
    ;

joinComponent
    : tableExprPart optTableExprAlias { $$ = {exprName: $1, alias: $2}; }
    ;

tableExprPart
    : IDENTIFIER { $$ = $1; }
    | QUALIFIED_IDENTIFIER { $$ = $1; }
    | LPAREN selectClause RPAREN { $$ = $2; }
    ;

optTableExprAlias
    : { $$ = null; }
    | IDENTIFIER { $$ = {value: $1 }; }
    | AS IDENTIFIER { $$ = {value: $2, includeAs: 1}; }
    ;

optJoinModifier
    : { $$ = ''; }
    | LEFT        { $$ = 'LEFT'; }
    | LEFT OUTER  { $$ = 'LEFT OUTER'; }
    | RIGHT       { $$ = 'RIGHT'; }
    | RIGHT OUTER { $$ = 'RIGHT OUTER'; }
    | FULL        { $$ = 'FULL'; }
    | INNER       { $$ = 'INNER'; }
    | CROSS       { $$ = 'CROSS'; }
    | NATURAL     { $$ = 'NATURAL'; }
    ;

expression
    : andCondition { $$ = {nodeType:'AndCondition', value: $1}; }
    | expression LOGICAL_OR andCondition { $$ = {nodeType:'OrCondition', left: $1, right: $3}; }
    ;

andCondition
    : condition { $$ = [$1]; }
    | andCondition LOGICAL_AND condition { $$ = $1; $1.push($3); }
    ;

condition
    : operand { $$ = {nodeType: 'Condition', value: $1}; }
    | operand conditionRightHandSide { $$ = {nodeType: 'BinaryCondition', left: $1, right: $2}; }
    | EXISTS LPAREN selectClause RPAREN { $$ = {nodeType: 'ExistsCondition', value: $3}; }
    | LOGICAL_NOT condition { $$ = {nodeType: 'NotCondition', value: $2}; }
    ;

compare
    : CMP_EQUALS { $$ = $1; }
    | CMP_NOTEQUALS { $$ = $1; }
    | CMP_NOTEQUALS_BASIC { $$ = $1; }
    | CMP_GREATER { $$ = $1; }
    | CMP_GREATEROREQUAL { $$ = $1; }
    | CMP_LESS { $$ = $1; }
    | CMP_LESSOREQUAL { $$ = $1; }
    ;

conditionRightHandSide
    : rhsCompareTest { $$ = $1; }
    | rhsIsTest { $$ = $1; }
    | rhsInTest { $$ = $1; }
    | rhsLikeTest { $$ = $1; }
    | rhsBetweenTest { $$ = $1; }
    ;

rhsCompareTest
    : compare operand { $$ = {nodeType: 'RhsCompare', op: $1, value: $2 }; }
    | compare ALL LPAREN selectClause RPAREN { $$ = {nodeType: 'RhsCompareSub', op:$1, kind: $2, value: $4 }; }
    | compare ANY LPAREN selectClause RPAREN { $$ = {nodeType: 'RhsCompareSub', op:$1, kind: $2, value: $4 }; }
    | compare SOME LPAREN selectClause RPAREN { $$ = {nodeType: 'RhsCompareSub', op:$1, kind: $2, value: $4 }; }
    ;

rhsIsTest
    : IS operand { $$ = {nodeType: 'RhsIs', value: $2}; }
    | IS LOGICAL_NOT operand { $$ = {nodeType: 'RhsIs', value: $3, not:1}; }
    | IS DISTINCT FROM operand { $$ = {nodeType: 'RhsIs', value: $4, distinctFrom:1}; }
    | IS LOGICAL_NOT DISTINCT FROM operand { $$ = {nodeType: 'RhsIs', value: $5, not:1, distinctFrom:1}; }
    ;
    
rhsInTest
    : IN LPAREN selectClause RPAREN { $$ = { nodeType: 'RhsInSelect', value: $3 }; }
    | LOGICAL_NOT IN LPAREN selectClause RPAREN { $$ = { nodeType: 'RhsInSelect', value: $4, not:1 }; }
    | IN LPAREN commaSepExpressionList RPAREN { $$ = { nodeType: 'RhsInExpressionList', value: $3 }; }
    | LOGICAL_NOT IN LPAREN commaSepExpressionList RPAREN { $$ = { nodeType: 'RhsInExpressionList', value: $4, not:1 }; }
    ;

commaSepExpressionList
    : commaSepExpressionList COMMA expression { $$ = $1; $1.push($3); }
    | expression { $$ = [$1]; }
    ;

functionParam
    : expression { $$ = $1; }
    | STAR { $$ = $1; }
    | QUALIFIED_STAR { $$ = $1; }
    ;

functionExpressionList
    : functionExpressionList COMMA functionParam { $$ = $1; $1.push($3); }
    | functionParam { $$ = [$1]; }
    ;

/*
 * Function params are defined by an optional list of functionParam elements,
 * because you may call functions of with STAR/QUALIFIED_STAR parameters (Like COUNT(*)),
 * which aren't `Term`(s) because they cant't have an alias
 */
optFunctionExpressionList
    : { $$ = null; }
    | functionExpressionList { $$ = $1; }
    ;

rhsLikeTest
    : LIKE operand { $$ = {nodeType: 'RhsLike', value: $2}; }
    | LOGICAL_NOT LIKE operand { $$ = {nodeType: 'RhsLike', value: $3, not:1}; }
    ;

rhsBetweenTest
    : BETWEEN operand LOGICAL_AND operand { $$ = {nodeType: 'RhsBetween', left: $2, right: $4}; }
    | LOGICAL_NOT BETWEEN operand LOGICAL_AND operand { $$ = {nodeType: 'RhsBetween', left: $3, right: $5, not:1}; }
    ;

operand
    : summand { $$ = $1; }
    | operand CONCAT summand { $$ = {nodeType:'Operand', left:$1, right:$3, op:$2}; }
    ;


summand
    : factor { $$ = $1; }
    | summand PLUS factor { $$ = {nodeType:'Summand', left:$1, right:$3, op:$2}; }
    | summand MINUS factor { $$ = {nodeType:'Summand', left:$1, right:$3, op:$2}; }
    ;

factor
    : term { $$ = $1; }
    | factor DIVIDE term { $$ = {nodeType:'Factor', left:$1, right:$3, op:$2}; }
    | factor STAR term { $$ = {nodeType:'Factor', left:$1, right:$3, op:$2}; }
    | factor MODULO term { $$ = {nodeType:'Factor', left:$1, right:$3, op:$2}; }
    ;

term
    : value { $$ = {nodeType: 'Term', value: $1}; }
    | IDENTIFIER { $$ = {nodeType: 'Term', value: $1}; }
    | QUALIFIED_IDENTIFIER { $$ = {nodeType: 'Term', value: $1}; }
    | caseWhen { $$ = $1; }
    | LPAREN expression RPAREN { $$ = {nodeType: 'Term', value: $2}; }
    | IDENTIFIER LPAREN optFunctionExpressionList RPAREN { $$ = {nodeType: 'FunctionCall', name: $1, args: $3}; }
    | QUALIFIED_IDENTIFIER LPAREN optFunctionExpressionList RPAREN { $$ = {nodeType: 'FunctionCall', name: $1, args: $3}; }
    ;

caseWhen
    : CASE caseWhenList optCaseWhenElse END { $$ = {nodeType:'Case', clauses: $2, else: $3}; }
    ;

caseWhenList
    : caseWhenList WHEN expression THEN expression { $$ = $1; $1.push({nodeType: 'CaseItem', when: $3, then: $5}); }
    | WHEN expression THEN expression { $$ = [{nodeType: 'CaseItem', when: $2, then: $4}]; }
    ;

optCaseWhenElse
    : { $$ = null; }
    | ELSE expression { $$ = $2; }
    ;

value
    : STRING { $$ = $1; } 
    | NUMERIC { $$ = $1; }
    | BOOLEAN { $$ = $1; }
    | NULL { $$ = $1; }
    ;

