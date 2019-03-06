open Excmd

let scrpt desc str =
   Printf.printf "\n\n### %s:\nParser.script %S\n" desc str ;
   AST.pp (Parser.script_of_string str)


let stmt desc str =
   Printf.printf "\n\n### %s:\nParser.statement %S\n" desc str ;
   Statement.pp (Parser.statement_of_string str)


let incr_stmt desc str =
   Printf.printf "\n\n### %s:\nIncremental.statement %S\n" desc str ;
   let pp stmt = Statement.dehydrate stmt |> Statement.pp in
   (pp, Incremental.statement_of_string str)


let tests () =
   (* Basic statements *)
   stmt "Simple, single command" "test" ;
   stmt "Single command, with count" "2test" ;
   (* Basic statements, with parameters *)
   stmt "Single command, with single positional parameter" "test foo" ;
   stmt "Single command, count, and single positional parameter" "2test foo" ;
   stmt "Single command, with multiple positional parameters" "test foo bar" ;
   stmt "Single command, count, and multiple positional parameters" "2test foo bar" ;
   stmt "Single command, with single boolean flag" "test --foo" ;
   stmt "Single command, with multiple boolean flags" "test --foo --bar" ;
   stmt "Single command, with single boolean short-flag" "test -f" ;
   stmt "Single command, with multiple, concatenated boolean short-flags" "test -foo" ;
   stmt "Single command, with multiple, separated boolean short-flags" "test -f -o -o" ;
   stmt "Single command, with single possibly-parameterized flag" "test --foo bar" ;
   stmt "Single command, with single possibly-parameterized short-flag" "test -f bar" ;
   stmt
      "Single command with single possibly-parameterized flag followed by a positional \
       parameter"
      "test --foo bar baz" ;
   stmt "Single command with two possibly-parameterized flags"
      "test --foo bar --baz widget" ;
   stmt "Single command, with single explicitly-parameterized flag" "test --foo=bar" ;
   stmt
      "Single command with single explicitly-parameterized flag followed by a positional \
       parameter"
      "test --foo=bar baz" ;
   stmt "Single command with mixed flags and parameters"
      "test --foo bar --baz=widget qux -qu ux" ;
   (* Simple multi-statement scripts *)
   scrpt "Statements separated by semicolons" "test; 2test; 3test" ;
   scrpt "Statements separated by semicolons, with a trailing semicolon"
      "test; 2test; 3test;" ;
   scrpt "Statements, with arguments, separated by semicolons"
      "test --foo bar; 2test --foo=bar; 3test --foo bar" ;
   scrpt "Statements, with arguments, separated by semicolons, with a trailing semicolon"
      "test --foo bar; 2test --foo=bar; 3test --foo bar;" ;
   scrpt "Newlines after statements" "test;\n   2test;\n   3test" ;
   scrpt "Newlines after statements, with a trailing newline"
      "test;\n   2test;\n   3test;\n   " ;
   (* Incremental API *)
   let pp, entrypoint =
      incr_stmt "An acceptable statement, incrementally" "hello --where=world"
   in
   let accept statement = pp statement in
   let fail _last_good _failing = failwith "parsing should have succeeded" in
   Incremental.continue ~accept ~fail entrypoint


let () =
   match Sys.argv with
   (* Automated tests *)
   | [|_|] -> tests ()
   (* Interactive usage *)
   | [|_; "script"; str|] -> AST.pp (Parser.script_of_string str)
   | [|_; "statement"; str|] -> Statement.pp (Parser.statement_of_string str)
   | [|_; _; _|] ->
      raise
         (Invalid_argument
             "First argument must be a valid non-terminal (e.g. 'script' or 'statement')")
   | _ ->
      Printf.eprintf
         "!! Please provide either no arguments (to run the automated tests), or exactly \
          two arguments (for\n" ;
      Printf.eprintf
         "!! interactive experimentation): a nonterminal entry-point (e.g. 'script'), and \
          a string to parse.\n" ;
      raise (Invalid_argument "Either exactly two, or zero, arguments are required")
