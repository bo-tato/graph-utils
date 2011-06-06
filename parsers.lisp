(in-package #:graph-utils)

(defun snip (s) (subseq s 1 (1- (length s))))
(defun un-squote (s) (regex-replace-all "''" (snip s) "'"))
(defun un-dquote (s) (regex-replace-all "\"\"" (snip s) "\""))
(defun strip-whitespace (s) (regex-replace-all "(^\\s+|\\s+$)" s ""))

(deflexer scan-gml ()
  ("\\s+" whitespace strip-whitespace)
  ("[^\"'\\[\\]\\s]+" val strip-whitespace)
  ("(\\[|\\])" bracket)
  ("'(?:[^']|'')*'" val un-squote)
  ("\"(?:[^\"]|\"\")*\"" val un-dquote))

(defun lex-gml (lexer input)
  (labels ((my-scan (start tokens)
             (if (> (length input) start)
                 (multiple-value-bind (class image remainder)
                     (funcall lexer input start)
                   (when class
		     (if (> (length image) 0)
			 (my-scan remainder (cons (list class image) tokens))
			 (my-scan remainder tokens))))
                 (nreverse tokens))))
    (my-scan 0 '())))

(define-parser *gml-parser*
  (:start-symbol lst-opt)
  (:terminals (val bracket sq-val dq-val))
  (lst-opt
   lst
   ())
  (lst
   (keyvalue lst-opt))
  (keyvalue
   (key value))
  (key
   val)
  (value
   val
   (bracket lst bracket)))

(defun build-node (node-def)
  "Builds a node as a list of '(id label value)"
  (let ((node (make-list 3)))
    (labels ((walk-node (n)
	       (cond ((null n) nil)
		     ((atom n) nil)
		     ((consp n)
		      (cond ((consp (first n))
			     (walk-node (first n)))
			    ((equal "id" (first n))
			     (setf (nth 0 node) (second n)))
			    ((equal "label" (first n))
			     (setf (nth 1 node) (second n)))
			    ((equal "value" (first n))
			     (setf (nth 2 node) (second n))))
		      (walk-node (second n))))))
      (walk-node (second node-def))
      node)))

(defun build-edge (edge-def)
  "Builds an edge as a list if '(source target value)"
  (let ((edge (make-list 3)))
    (labels ((walk-edge (n)
	       (cond ((null n) nil)
		     ((atom n) nil)
		     ((consp n)
		      (cond ((consp (first n))
			     (walk-edge (first n)))
			    ((equal "value" (first n))
			     (setf (nth 2 edge) (second n)))
			    ((equal "source" (first n))
			     (setf (nth 0 edge) (second n)))
			    ((equal "target" (first n))
			     (setf (nth 1 edge) (second n))))
		      (walk-edge (second n))))))
      (walk-edge (second edge-def))
      edge)))

(defun build-graph (gml-tree)
  (let ((graph nil) (directed? nil) (nodes nil) (edges nil) 
	(id-table (make-hash-table :test 'equal)))
    (labels ((walk-tree (tree)
	       (cond ((null tree) nil)
		     ((atom tree) nil)
		     ((consp tree)
		      (let ((this (first tree)))
			(cond ((and (equal (first this) "directed") (equal (second this) "1"))
			       (setq directed? t))
			      ((equal (first this) "node")
			       (push (build-node this) nodes))
			      ((equal (first this) "edge")
			       (push (build-edge this) edges))))
		      (walk-tree (second tree))))))
      (walk-tree gml-tree))
    (setq graph (make-graph :directed? directed?))
    (dolist (node (nreverse nodes))
      (add-node graph (or (second node) (first node)) :no-expand? t)
      (setf (gethash (first node) id-table) (or (second node) (first node))))
    (adjust-adjacency-matrix graph)
    (dolist (edge (nreverse edges))
      (let ((n1 (lookup-node graph (gethash (first edge) id-table)))
	    (n2 (lookup-node graph (gethash (second edge) id-table)))
	    (w (if (third edge) (parse-integer (third edge)) 1)))
	(add-edge graph n1 n2 :weight w)))
    graph))

(defun parse-gml (file)
  (let ((tokens nil) graph)
    (with-open-file (in file :direction :input)
      (do ((input (read-line in nil :eof) (read-line in nil :eof)))
	  ((or (eql input :eof) (equal input "")))
	(setq tokens (nconc tokens (lex-gml 'scan-gml input)))))
    (let ((tree (parse-with-lexer (lambda () (values-list (pop tokens))) *gml-parser*)))
      (dolist (branch tree)
	(when (and (consp branch) (consp (first branch)) (equal "graph" (first (first branch))))
	  (setq graph (build-graph (second (second (first branch))))))))
    graph))

(defun check-nodes (graph vertex-count)
  (unless (= vertex-count (node-count graph))
    (dotimes (i vertex-count)
      (add-node graph i :no-expand? t)))
  (adjust-adjacency-matrix graph))
    
(defun parse-pajek (file)
  "Parse a .net file and make a graph out of it."
  (let ((graph (make-graph :directed? nil))
        (vertices? nil) (vertex-count 0)
        (arcs? nil)
        (index (make-hash-table :test 'equal)))
    (with-open-file (in file :direction :input)
      (do ((line (read-line in nil :eof) (read-line in nil :eof)))
          ((eql line :eof))
        (setq line (regex-replace "^\\s+" line ""))
        (cond ((scan "^\%" line) nil)
	      ((scan "^\*[Vv]ertices" line) 
	       (do-register-groups (count) ("^\*[Vv]ertices\\s+([0-9]+)\\s*" line)
		 (when count
		   (setq vertex-count (parse-integer count))))
	       (setq vertices? t arcs? nil))
              ((scan "^\*[Aa]rcs" line)
	       (check-nodes graph vertex-count)
               (setq arcs? t vertices? nil))
              ((scan "^\*[Ee]dge" line)
	       (check-nodes graph vertex-count)
	       (setf (directed? graph) t)
               (setq arcs? t vertices? nil))
              (vertices?
	       (do-register-groups (id value rest)
		   ("^([0-9]+)\\s+(\"(?:[^\"]|\"\")*\"|\\w+)\\s+(.*)$" line nil :start 0 :sharedp t)
                 (declare (ignore rest))
                 (setq value (regex-replace-all "\"" value ""))
                 (setf (gethash id index) value)
                 (add-node graph value :no-expand? t)))
              (arcs?
               (destructuring-bind (source &rest destinations) (split "\\s+" line)
		 (dolist (d destinations)
		   (add-edge graph 
			     (or (gethash source index) source)
			     (or (gethash d index) d))
		   (when (not (directed? graph))
		     (add-edge graph 
			       (or (gethash d index) d)
			       (or (gethash source index) source)))))))))
    graph))
