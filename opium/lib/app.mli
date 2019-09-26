open Rock
(** An opium app provides a set of convenience functions and types to construct
    a rock app.

    - Re-exporting common functions needed in handlers
    - Easy handling of routes and bodies
    - Automatic generation of a command line app *)

type t [@@deriving sexp_of]
(** An opium app is a simple builder wrapper around a rock app *)

val empty : t
(** A basic empty app *)

type builder = t -> t [@@deriving sexp_of]
(** A builder is a function that transforms an [app] by adding some
    functionality. Builders are usuallys composed with a base app using (|>) to
    create a full app *)

val port : int -> builder
val debug : bool -> builder
val verbose : bool -> builder

val ssl : cert:string -> key:string -> builder

val cmd_name : string -> builder

type route = string -> Handler.t -> builder [@@deriving sexp_of]
(** A route is a function that returns a buidler that hooks up a handler to a
    url mapping *)

val get : route
(** Method specific routes *)

val post : route

val delete : route

val put : route

val patch : route
(** Less common method specific routes *)

val options : route

val head : route

val any : Cohttp.Code.meth list -> route
(** any [methods] will bind a route to any http method inside of [methods] *)

val all : route
(** all [methods] will bind a route to a URL regardless of the http method. You
    may escape the actual method used from the request passed. *)

val action : Cohttp.Code.meth -> route

val middleware : Middleware.t -> builder

val to_rock : t -> Rock.App.t
(** Convert an opium app to a rock app *)

val app_handler : Rock.App.t ->
  (Conduit_lwt_unix.flow * Cohttp.Connection.t) ->
  Cohttp.Request.t ->
  Cohttp_lwt.Body.t -> (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t

type ssl_t = [ `Crt_file_path of string ] * [ `Key_file_path of string ]

type run = ?ssl:ssl_t -> Rock.App.t -> port:int -> unit Lwt.t

val run_unix : run

val start : ?run:run -> t -> unit Lwt.t
(** Start an opium server. The thread returned can be cancelled to shutdown the
    server *)

val run_command : t -> unit
(** Create a cmdliner command from an app and run lwt's event loop *)

(* Run a cmdliner command from an app. Does not launch Lwt's event loop. `Error
   is returned if the command line arguments are incorrect. `Not_running is
   returned if the command was completed without the server being launched *)
val run_command' : t -> [> `Ok of unit Lwt.t | `Error | `Not_running]

type body =
  [ `Html of string
  | `Json of Yojson.Safe.t
  | `Xml of string
  | `String of string ]
(** Convenience functions for a running opium app *)

val json_of_body_exn : Request.t -> Yojson.Safe.t Lwt.t

val string_of_body_exn : Request.t -> string Lwt.t

val urlencoded_pairs_of_body : Request.t -> (string * string list) list Lwt.t

val param : Request.t -> string -> string

val splat : Request.t -> string list

val respond :
     ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> Response.t

(* Same as return (respond ...) *)
val respond' :
     ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> Response.t Lwt.t

val redirect : ?headers:Cohttp.Header.t -> Uri.t -> Response.t

(* Same as return (redirect ...) *)
val redirect' : ?headers:Cohttp.Header.t -> Uri.t -> Response.t Lwt.t
