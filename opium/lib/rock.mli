(** A tiny clone of ruby's Rack protocol in OCaml. Which is slightly more
    general and inspired by Finagle. It's not imperative to have this to for
    such a tiny framework but it makes extensions a lot more straightforward *)

module Request : sig
  type t = {request: Cohttp.Request.t; body: Cohttp_lwt.Body.t; env: Hmap0.t}
  [@@deriving fields, sexp_of]

  val create : ?body:Cohttp_lwt.Body.t -> ?env:Hmap0.t -> Cohttp.Request.t -> t

  (* Convenience accessors on the request field *)
  val uri : t -> Uri.t

  val meth : t -> Cohttp.Code.meth

  val headers : t -> Cohttp.Header.t
end

module Response : sig
  type t =
    { code: Cohttp.Code.status_code
    ; headers: Cohttp.Header.t
    ; body: Cohttp_lwt.Body.t
    ; env: Hmap0.t }
  [@@deriving fields, sexp_of]

  val create :
       ?env:Hmap0.t
    -> ?body:Cohttp_lwt.Body.t
    -> ?headers:Cohttp.Header.t
    -> ?code:Cohttp.Code.status_code
    -> unit
    -> t

  val of_string_body :
       ?env:Hmap0.t
    -> ?headers:Cohttp.Header.t
    -> ?code:Cohttp.Code.status_code
    -> string
    -> t

  val of_response_body : Cohttp.Response.t * Cohttp_lwt.Body.t -> t
end

(** A handler is a rock specific service *)
module Handler : sig
  type t = (Request.t, Response.t) Opium_core.Service.t [@@deriving sexp_of]

  val default : t

  val not_found : t
end

(** Middleware is a named, simple filter, that only works on rock
    requests/response *)
module Middleware : sig
  type t [@@deriving sexp_of]

  val filter : t -> (Request.t, Response.t) Opium_core.Filter.simple

  val apply :
       t
    -> (Request.t, Response.t) Opium_core.Service.t
    -> Request.t
    -> Response.t Lwt.t

  val name : t -> string

  val create :
    filter:(Request.t, Response.t) Opium_core.Filter.simple -> name:string -> t
end

module App : sig
  type t [@@deriving sexp_of]

  val handler : t -> Handler.t

  val middlewares : t -> Middleware.t list

  val append_middleware : t -> Middleware.t -> t

  val create : ?middlewares:Middleware.t list -> handler:Handler.t -> t
end
