open Base
open Core

type evalObject =
  | Nil
  | EvalIntObject of int
  | EvalBoolObject of bool
  | EvalFuncObject of
      Parse.astIdentifierNode list * Parse.astStatementNode list

type objectType = INT_OBJ | BOOL_OBJ

type symbolTable = (string * evalObject) list

type evalEnvironment = Nil | EvalEnvironment of symbolTable * evalEnvironment

type evalObjectAndEnv = evalObject * evalEnvironment

let typeOfObject (obj : evalObject) : objectType =
  match obj with EvalIntObject _ -> INT_OBJ | EvalBoolObject _ -> BOOL_OBJ

let inspectObject (obj : evalObject) =
  match obj with
  | EvalIntObject x ->
      printf "%d\n" x
  | EvalBoolObject x ->
      printf "%b\n" x
  | EvalFuncObject (args, statements) ->
      printf "func defined"

(*let evalLet (node: astLetNode) : evalObject = *)
(*let ident, express = node in*)

let findInEnv (env : evalEnvironment) (key : string) : evalObject =
  match env with
  | Nil ->
      failwith ""
  | EvalEnvironment (table, parent_env) -> (
      let objopt = List.Assoc.find ~equal:String.equal table key in
      match objopt with None -> failwith "No timezone provided" | Some x -> x )

let addInEnv (env : evalEnvironment) (key : string) (obj : evalObject) :
    evalEnvironment =
  match env with
  | Nil ->
      failwith ""
  | EvalEnvironment (table, parent_env) ->
      let table = List.Assoc.add ~equal:String.equal table key obj in
      EvalEnvironment (table, parent_env)

let evalPlus (evalleft : evalObject) (evalright : evalObject) : evalObject =
  match (evalleft, evalright) with
  | EvalIntObject x, EvalIntObject y ->
      EvalIntObject (x + y)

let evalMul (evalleft : evalObject) (evalright : evalObject) : evalObject =
  match (evalleft, evalright) with
  | EvalIntObject x, EvalIntObject y ->
      EvalIntObject (x * y)

let evalInfix (optype : Lex.tokenType) (evalleft : evalObject)
    (evalright : evalObject) : evalObject =
  match optype with
  | Lex.PLUS ->
      evalPlus evalleft evalright
  | Lex.MUL ->
      evalMul evalleft evalright

let evalIdent (ident : Parse.astIdentifierNode) (env : evalEnvironment) :
    evalObjectAndEnv =
  let obj = findInEnv env ident.value in
  (obj, env)

let getParentEnv (env : evalEnvironment) : evalEnvironment =
  match env with
  | EvalEnvironment (symbol, parent_env) ->
      parent_env
  | Nil ->
      failwith ""

let rec evalFuncBody (nodes : Parse.astProgramNode) (env : evalEnvironment) :
    evalObjectAndEnv =
  match nodes with
  | [hd] -> (
    match hd with
    | AstReturnNode express ->
        let obj, env = evalStatement hd env in
        let env = getParentEnv env in
        (obj, env)
    | _ ->
        let obj, env = evalStatement hd env in
        (Nil, env)
    | hd :: tl -> (
      match hd with
      | AstReturnNode express ->
          let obj, env = evalStatement hd env in
          let env = getParentEnv env in
          (obj, env)
      | _ ->
          let obj, env = evalStatement hd env in
          evalFuncBody tl env ) )

let rec evalExpression (node : Parse.astExpressionNode) (env : evalEnvironment)
    : evalObjectAndEnv =
  match node with
  | AstNumberNode x ->
      (EvalIntObject x, env)
  | AstIdentNode x ->
      let obj, env = evalIdent x env in
      (obj, env)
  | AstInfixNode (optoken, astExpleft, astExpright) ->
      let evalleft, env = evalExpression astExpleft env in
      let evalright, env = evalExpression astExpright env in
      (evalInfix optoken evalleft evalright, env)
  | AstFuncCallNode (ident, arglist) -> (
      let funcObj = findInEnv env ident.value in
      match funcObj with
      | EvalFuncObject (argparas, statements) ->
          let symboltable : symbolTable = [] in
          let env = EvalEnvironment (symboltable, env) in
          let obj, env = evalFuncBody statements env in
          (obj, env) )

let rec evalLet (node : Parse.astLetNode) (env : evalEnvironment) :
    evalObjectAndEnv =
  let ident, expression = node in
  let expressionObj, env = evalExpression expression env in
  let env = addInEnv env ident.value expressionObj in
  (expressionObj, env)

let evalFunc (node : Parse.astFunctionNode) (env : evalEnvironment) :
    evalObjectAndEnv =
  let ident, arglist, statements = node in
  let funcObj = EvalFuncObject (arglist, statements) in
  let env = addInEnv env ident.value funcObj in
  (funcObj, env)

let rec evalStatement (node : Parse.astStatementNode) (env : evalEnvironment) :
    evalObjectAndEnv =
  match node with
  | AstExpressionNode node ->
      evalExpression node env
  | AstLetNode node ->
      evalLet node env
  | AstFunctionNode node ->
      evalFunc node env

let genEnvironment : evalEnvironment =
  let symboltable : symbolTable = [] in
  EvalEnvironment (symboltable, Nil)

let rec evalProgram (node : Parse.astProgramNode) (env : evalEnvironment) :
    evalObjectAndEnv =
  match node with
  | [hd] ->
      let obj, env = evalStatement hd env in
      (obj, env)
  | hd :: tl ->
      let obj, env = evalStatement hd env in
      evalProgram tl env
