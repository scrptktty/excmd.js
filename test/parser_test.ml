open Excmd

let test_script desc str =
   Printf.printf "\n\n### %s:\nParser.script %S\n" desc str ;
   AST.pp (Parser.script_of_string str)


let test_statement desc str =
   Printf.printf "\n\n### %s:\nParser.statement %S\n" desc str ;
   Statement.pp (Parser.statement_of_string str)


let incremental_statement desc str =
   Printf.printf "\n\n### %s:\nIncremental.statement %S\n" desc str ;
   let pp stmt = Statement.dehydrate stmt |> Statement.pp in
   (pp, Incremental.statement_of_string str)


let tests () =
   (* Basic statements *)
   test_statement "Simple, single command" "test" ;
   test_statement "Single command, with count" "2test" ;
   (* Basic statements, with parameters *)
   test_statement "Single command, with single positional parameter" "test foo" ;
   test_statement "Single command, count, and single positional parameter" "2test foo" ;
   test_statement "Single command, with multiple positional parameters" "test foo bar" ;
   test_statement "Single command, count, and multiple positional parameters"
      "2test foo bar" ;
   test_statement "Single command, with single boolean flag" "test --foo" ;
   test_statement "Single command, with multiple boolean flags" "test --foo --bar" ;
   test_statement "Single command, with single boolean short-flag" "test -f" ;
   test_statement "Single command, with multiple, concatenated boolean short-flags"
      "test -foo" ;
   test_statement "Single command, with multiple, separated boolean short-flags"
      "test -f -o -o" ;
   test_statement "Single command, with single possibly-parameterized flag"
      "test --foo bar" ;
   test_statement "Single command, with single possibly-parameterized short-flag"
      "test -f bar" ;
   test_statement
      "Single command with single possibly-parameterized flag followed by a positional \
       parameter"
      "test --foo bar baz" ;
   test_statement "Single command with two possibly-parameterized flags"
      "test --foo bar --baz widget" ;
   test_statement "Single command, with single explicitly-parameterized flag"
      "test --foo=bar" ;
   test_statement
      "Single command with single explicitly-parameterized flag followed by a positional \
       parameter"
      "test --foo=bar baz" ;
   test_statement "Single command with mixed flags and parameters"
      "test --foo bar --baz=widget qux -qu ux" ;
   (* Simple multi-statement scripts *)
   test_script "Statements separated by semicolons" "test; 2test; 3test" ;
   test_script "Statements separated by semicolons, with a trailing semicolon"
      "test; 2test; 3test;" ;
   test_script "Statements, with arguments, separated by semicolons"
      "test --foo bar; 2test --foo=bar; 3test --foo bar" ;
   test_script
      "Statements, with arguments, separated by semicolons, with a trailing semicolon"
      "test --foo bar; 2test --foo=bar; 3test --foo bar;" ;
   test_script "Newlines after statements" "test;\n   2test;\n   3test" ;
   test_script "Newlines after statements, with a trailing newline"
      "test;\n   2test;\n   3test;\n   " ;
   (* Incremental API *)
   let pp, entrypoint =
      incremental_statement "An acceptable statement, incrementally" "hello --where=world"
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
