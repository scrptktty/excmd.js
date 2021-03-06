(** {2 Describing structures }

    Some of our data-structures provide conversion functions to produce alternative
    formats of themselves. These are automatically generated at compile-time by
    {{https://ocamlverse.github.io/content/ppx.html}PPX preprocessors} in OCaml.

    Unfortunately, we use different data-structures per compile-target: in native OCaml,
    we use [{{https://github.com/ocaml-ppx/ppx_deriving_yojson} ppx_deriving_yojson}] to
    produce a value of type
    [{{https://mjambon.github.io/mjambon2016/yojson-doc/Yojson.Basic.html#TYPEjson}
    Yojson.Basic.json}]; but when being compiled to JavaScript, we use BuckleScript's
    [{{https://bucklescript.github.io/docs/en/generate-converters-accessors.html#convert-between-jst-object-and-record}
    jsConverter}] tooling to generate the built-in
    [{{https://bucklescript.github.io/bucklescript/api/Js.html#TYPEt} Js.t}] type. These
    generators also produce functions of different names: {!to_yojson} is available on
    the native side, and {!tToJs} on the BuckleScript side.

    Due to the fact that the relevant types differ between platforms, fully generic code
    involving alternative-format representations like the above isn't clean and easy.
    Both of the above flavours of conversion-function will raise a runtime exception if
    called on a platform that doesn't support them; if you need to, you can catch said
    exception and swap implementations based on that. *)

exception WrongPlatform of [`Native | `JavaScript] * string

(* These are initially declared as runtime errors, so they can be shadowed by the 'valid'
   functions generated by the below ppxes. *)
let unavailable_on target name = raise (WrongPlatform (target, name))

let tOfJs _ = unavailable_on `Native "tOfJs"

let tToJs _ = unavailable_on `Native "tToJs"

let statementOfJs _ = unavailable_on `Native "statementOfJs"

let statementToJs _ = unavailable_on `Native "statementToJs"

let to_yojson _ = unavailable_on `JavaScript "to_yojson"

let of_yojson _ = unavailable_on `JavaScript "of_yojson"

let statement_to_yojson _ = unavailable_on `JavaScript "statement_to_yojson"

let statement_of_yojson _ = unavailable_on `JavaScript "statement_of_yojson"

type 'a unresolved = Unresolved | Resolved of 'a | Absent
[@@bs.deriving jsConverter] [@@deriving to_yojson]

type flag = {name : string; mutable payload : string unresolved}
[@@bs.deriving jsConverter] [@@deriving to_yojson]

type arg = Positional of string | Flag of flag
[@@bs.deriving jsConverter] [@@deriving to_yojson]

type statement = {count : int; cmd : string; mutable args : arg array}
[@@bs.deriving jsConverter] [@@deriving to_yojson]

type t = {statements : statement array}
[@@bs.deriving jsConverter] [@@deriving to_yojson]

let make_statement ?count ~cmd ~args =
   { count = (match count with Some c -> int_of_string c | None -> 1)
   ; cmd
   ; args = Array.of_list args }


let pp_bs ast =
   let obj = tToJs ast in
   Js.Json.stringifyAny obj |> Js.log


let pp_native ast =
   let json = to_yojson ast in
   let out = Format.formatter_of_out_channel stdout in
   Yojson.Safe.pretty_print out json


let pp ast = try pp_bs ast with WrongPlatform (`Native, _) -> pp_native ast

let pp_statement_bs stmt =
   let obj = statementToJs stmt in
   Js.Json.stringifyAny obj |> Js.log


let pp_statement_native stmt =
   let json = statement_to_yojson stmt in
   let out = Format.formatter_of_out_channel stdout in
   Yojson.Safe.pretty_print out json


let pp_statement ast =
   try pp_statement_bs ast with WrongPlatform (`Native, _) -> pp_statement_native ast
