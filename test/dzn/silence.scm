;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Tests for the makreel module.
;;;
;;; Code:

(define-module (test dzn silence)
  #:use-module (srfi srfi-64)
  #:use-module (test dzn automake)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast util)
  #:use-module (dzn code language makreel)
  #:use-module (dzn parse))

(test-begin "silence")

(test-assert "dummy"
  #t)

(let* ((test "
interface test
{
  in void hello ();
  behavior
  {
    void silent () {}
    on hello: silent ();
  }
}
")
       (ast (string->ast test))
       (functions (tree-collect (is? <function>) ast)))
  (test-equal "silent"
    '(#f)
    (map .noisy? functions)))

(let* ((test "
interface test
{
  in void hello ();
  behavior
  {
    bool idle = true;
    void silent_if ()
    {
      if (idle)
        ;
      else
        ;
    }
    on hello: silent_if ();
  }
}
")
       (ast (string->ast test))
       (functions (tree-collect (is? <function>) ast)))
  (test-equal "silent if"
    '(#f)
    (map .noisy? functions)))

(let* ((test "
interface test
{
  in void hello ();
  behavior
  {
    void silent_recurse ()
    {
      bool b = false;
      if (b)
        silent_recurse ();
    }
    on hello: silent_recurse ();
  }
}
")
       (ast (string->ast test))
       (functions (tree-collect (is? <function>) ast)))
  (test-equal "silent recurse"
    '(#f)
    (map .noisy? functions)))

(let* ((test "
interface test
{
  in void hello ();
  out void world ();
  behavior
  {
    void noisy_action ()
    {
      world;
    }
    on hello: noisy_action ();
  }
}
")
       (ast (string->ast test))
       (functions (tree-collect (is? <function>) ast)))
  (test-equal "noisy action"
    '(#t)
    (map .noisy? functions)))

(let* ((test "
interface test
{
  in void hello ();
  behavior
  {
    bool idle = true;
    void noisy_assign ()
    {
      idle = true;
    }
    on hello: noisy_assign ();
  }
}
")
       (ast (string->ast test))
       (functions (tree-collect (is? <function>) ast)))
  (test-equal "noisy assign"
    '(#t)
    (map .noisy? functions)))

(let* ((test "
interface test
{
  in void hello ();
  out void world ();
  behavior
  {
    bool idle = true;
    void noisy_if ()
    {
      if (idle)
        ;
      else
        world;
    }
    on hello: noisy_if ();
  }
}
")
       (ast (string->ast test))
       (functions (tree-collect (is? <function>) ast)))
  (test-equal "noisy if"
    '(#t)
    (map .noisy? functions)))

(let* ((test "
interface test
{
  in void hello ();
  out void world ();
  behavior
  {
    void noisy_call ()
    {
      bool b = false;
      if (b)
        noisy_mutual ();
    }
    void noisy_mutual ()
    {
      bool b = false;
      if (b)
        noisy_call ();
      else
        world;
    }
    on hello: noisy_mutual ();
  }
}
")
       (ast (string->ast test))
       (functions (tree-collect (is? <function>) ast)))
  (test-equal "mutual recurse"
    '(#t #t)
    (map .noisy? functions)))

(test-end)
