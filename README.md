XP: XP Common Lisp pretty printer for xyzzy
===========================================

origin: [Package: lang/lisp/code/io/xp/][1]

  [1]: http://www.cs.cmu.edu/afs/cs.cmu.edu/project/ai-repository/ai/lang/lisp/code/io/xp/0.html

Status: 作業中
--------------
`xp-code.lisp` を（コンパイルして）読み込んで `(xp::install)` すれば一応
動いてるっぽい。

~~~lisp
user> (pprint (macroexpand `(defpackage foo
                              (:use :lisp :editor)
                              (:shadowing-import-from :ansi-loop
                                #:loop #:loop-finish)
                              (:shadowing-import-from :ansify
                                #:destructuring-bind #:&allow-other-keys))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (let* ((package (or (find-package "foo") (make-package "foo")))
         (lisp::use '("lisp" "editor")))
    (unuse-package (package-use-list package) package)
    (shadowing-import '(ansi-loop:loop-finish ansi-loop:loop
                                              ansify:&allow-other-keys
                                              ansify:destructuring-bind)
                      package)
    (use-package lisp::use package)
    package))
~~~


Bugs etc.
---------
とりあえずわかってる範囲で

しんどそうなの
- <del>array の出力がおかしい</del>
  - おかしかったのはテストの方だった
- justification は相変わらず使えない
- printer control variable をちゃんと見てないことがある
  - `*print-escape*`
  - `*print-case*`
  - `*print-radix*`
  - `*print-base*`
  - `*print-array*`
  - `*print-gensym*`
  - 他にもあるかも
- コードが読めない
- テストがエラーになった場合に failure が表示されてないっぽい？
- backquote の対応
  - xyzzy のリーダは `cons` とか `list*` にしてしまうので難しい
- 循環の検出あたりがあやしい？

カンタンなの
- <del>拡張 loop のキーワードが大文字のまま</del> done.
- 拡張 loop のキーワードが足りてない
  - hash-table とか package あたりの

悩ましいの
- defstruct どうしよ


その他メモ
----------
できたら ansify に突っ込む予定

