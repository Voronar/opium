# Opium Core

The core pieces provided by `Opium_core` are Services and Filter.

## Services

Services are simple functions with the following type:

```ocaml
type ('req, 'res) t = 'req -> 'res Lwt.t
```

They take a request of type `'req` and return a [Lwt](https://ocsigen.org/lwt/4.3.0/manual/manual) promise, a reference that will eventually be filled asynchronously with the result of type `'res`.

An example of a simple service that takes an integer and returns a string promise:

```ocaml
let my_simple_service : (int, string) Service.t =
  fun request -> Lwt.return (string_of_int request)
;;
```

The type signature is shown just for demonstration purpose for the example.

Services can also be used to represent an HTTP handler if they work with an HTTP request and return a promise that will be filled by its response.

```ocaml
let http_service : (Cohttp.Request.t, Cohttp.Response.t * Cohttp_lwt.Body.t)
  = Lwt.return (...)
;;
```

## Filters

Filters are defined by the type:

```ocaml
type ('req, 'res, 'req', 'res') t
  = ('req, 'res) Service.t -> ('req', 'res') Service.t
```

Filters are simple functions that can be used to transform a service. Given a service of type `('req, 'res) Service.t` a filter can modify it to a new service that will respond with a type of `'res'`. But in simple scenario a filter can be used to just perform some operations on a given service while keeping the same types for request and response. In such scenarios a filter represent by the type:

```ocaml
type ('req, 'res) simple = ('req, 'res) Service.t -> ('req, 'res) Service.t
```

Example: We can define a new filter which can transform the `my_simple_service` defined above by tweaking the incoming integer `request` by adding 2 to it, before forwarding it to the original service.

```ocaml
let add_two_filter : (int, string) Filter.simple =
  fun service req -> service (req + 2)
;;

(* Applying the filter to get a new service *)
let new_service = add_two_filter my_simple_service;;

(* Using the new service to get results. This will return a Lwt promise that'll eventually be filled with "14" *)
new_service 12;;
- : string = "14"
```

There is a shortcut to apply a collection of simple filters to a given service.

```ocaml
let new_service = Filter.apply_all [add_two_filter; add_two_filter; add_two_filter] my_simple_service;;

(* If we call our new service with the number 12 now, we'll get a promise that'll eventually be filled with "18" *)
new_service 12;;
- : string = "18"
```
