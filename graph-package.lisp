(in-package #:cl-user)

(defpackage #:graph-utils
  (:use #:cl #:cl-ppcre #:dso-lex #:yacc #:bordeaux-threads
        #+sbcl #:cl-skip-list)
  (:export #:make-graph
           #:make-typed-graph
           #:typed-graph?
           #:add-edge-type
	   #:graph
	   #:copy-graph
	   #:graph=
	   #:graph?
	   #:directed?
	   #:undirected?
	   #:add-node
	   #:adjust-adjacency-matrix
	   #:lookup-node
	   #:map-nodes
	   #:list-nodes
           #:random-node-id
           #:random-node
	   #:rename-node
	   #:node-count
	   #:leaves
	   #:leaf?
	   #:neighbors
	   #:inbound-neighbors
	   #:outbound-neighbors
	   #:edges
	   #:edge-exists?
	   #:add-edge
	   #:delete-edge
	   #:map-edges
	   #:list-edges
	   #:edge-count
	   #:edge-weight
	   #:density
	   #:degree
	   #:in-degree
	   #:out-degree
	   #:degree-distribution
	   #:in-degree-distribution
	   #:find-shortest-path
	   #:calculate-shortest-paths
           #:spanning-tree
	   #:distance-map
	   #:find-components
	   #:score-edges
	   #:cluster
	   #:minimal-cut
	   #:minimal-cut!
           #:compute-maximum-flow
           #:compute-maximum-matching
           #:bipartite?
	   #:visualize
	   #:generate-random-graph
	   #:compute-page-rank-distribution
	   #:compute-page-rank
	   #:compute-hub-authority-values
	   #:compute-center-nodes
	   #:parse-pajek
	   #:parse-gml

           ;; Prolog
           #:def-global-prolog-functor
           #:def-prolog-compiler-macro
           #:compile-body
           #:args
           #:*prolog-global-functors*
           #:deref-exp
           #:unify
           #:select
           #:?-
           #:q-
           #:get-triples
           #:add-triple
           #:delete-triple
           #:make-triple
           #:lookup-triple
           #:subject
           #:predicate
           #:object
           #:weight
           #:var-deref
           #:replace-?-vars
           #:variables-in
           #:make-functor-symbol
           #:*trail*
           #:*var-counter*
           #:*functor*
           #:make-functor
           #:maybe-add-undo-bindings
           #:compile-clause
           #:show-prolog-vars
           #:prolog-error
           #:prolog-ignore
           #:delete-functor
           #:set-functor-fn
           #:*select-list*
           #:select-flat
           #:select-first
           #:do-query
           #:map-query
           #:valid-prolog-query?
           #:init-prolog
           #:*prolog-graph*
           #:*prolog-trace*
           #:trace-prolog
           #:untrace-prolog
           ))
