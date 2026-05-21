---
created: 2025-07-15T22:40:57 (UTC +09:00)
tags: []
source: https://plantuml.com/en/preprocessing
author:
---

# Use the preprocessor

> ## Excerpt
>
> The PlantUML preprocessor provides features close to the C preprocessor. You can include files, define constant and macros. It's also possible to use conditional.

---

## Preprocessing

Some preprocessing capabilities are included in **PlantUML**, and available for _all_ diagrams.

Those functionalities are very similar to the [C language preprocessor](http://en.wikipedia.org/wiki/C_preprocessor), except that the special character `#` has been changed to the exclamation mark `!`.

## ![](https://plantuml.com/backtop1.svg 'Back to top')Variable definition \[=, ?=\]

Although this is not mandatory, we highly suggest that variable names start with a `$`.

There are three types of data:

- **Integer number** _(int)_;
- **String** _(str)_ - these must be surrounded by single quote or double quote;
- **JSON** (JSON) - either JSON Array or JSON Object or JSON value created by `%str2json`.

_(for JSON variable definition and usage, see more details on [Preprocessing-JSON page](https://plantuml.com/en/preprocessing-json))_

Variables created outside function are **global**, that is you can access them from everywhere (including from functions). You can emphasize this by using the optional `global` keyword when defining a variable.

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="img35da8cd356474819450111fd8e22a0a2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('35da8cd356474819450111fd8e22a0a2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('35da8cd356474819450111fd8e22a0a2')"></td><td><div onclick="javascript:ljs('35da8cd356474819450111fd8e22a0a2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre35da8cd356474819450111fd8e22a0a2"><code onmouseover="az=1" onmouseout="az=0">@startuml
!$a  = 42
!$ab = "foo1"
!$cd = "foo2"
!$ef = $ab + $cd
!$foo = { "name": "John", "age" : 30 }

Alice -&gt; Bob : $a
Alice -&gt; Bob : $ab
Alice -&gt; Bob : $cd
Alice -&gt; Bob : $ef
Alice -&gt; Bob : Do you know **$foo.name\*\* ?
@enduml
</code></pre><p></p><p><img loading="lazy" width="196" height="244" src="https://plantuml.com/imgw/img-35da8cd356474819450111fd8e22a0a2.png"></p></div></td></tr></tbody></table>

You can also assign a value to a variable, only if it is not already defined, with the syntax: `!$a ?= "foo"`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7215a7df1311b0d595cfe15271bfcc34" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7215a7df1311b0d595cfe15271bfcc34')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7215a7df1311b0d595cfe15271bfcc34')"></td><td><div onclick="javascript:ljs('7215a7df1311b0d595cfe15271bfcc34')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7215a7df1311b0d595cfe15271bfcc34"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice -&gt; Bob : 1. **$name** should be empty

!$name ?= "Charlie"
Alice -&gt; Bob : 2. **$name\*\* should be Charlie

!$name = "David"
Alice -&gt; Bob : 3. **$name\*\* should be David

!$name ?= "Ethan"
Alice -&gt; Bob : 4. **$name\*\* should be David
@enduml
</code></pre><p></p><p><img loading="lazy" width="238" height="214" src="https://plantuml.com/imgw/img-7215a7df1311b0d595cfe15271bfcc34.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Boolean expression

### Boolean representation \[0 is false\]

There is not real boolean type, but PlantUML use this integer convention:

- Integer `0` means `false`
- and any non-null number (as `1`) or any string (as `"1"`, or even `"0"`) means `true`.

_\[Ref. [QA-9702](https://forum.plantuml.net/9702/%25false-returns-0-not-false-%25true-returns-1-not-true?show=9710#a9710)\]_

### Boolean operation and operator \[&&, ||, ()\]

You can use boolean expression, in the test, with :

- _parenthesis_ `()`;
- _and operator_ `&&`;
- _or operator_ `||`.

_(See next example, within `if` test.)_

### Boolean builtin functions \[%false(), %true(), %not(<exp>), %boolval(<exp>)\]

For convenience, you can use those boolean builtin functions:

- `%false()`
- `%true()`
- `%not(<exp>)`
- `%boolval(<exp>)`

_\[See also [Builtin functions](https://plantuml.com/en/preprocessing#0umqmmdy1n9yk362kjka)\]_ _\[Ref. [PR-1873](https://github.com/plantuml/plantuml/pull/1873)\]_

## ![](https://plantuml.com/backtop1.svg 'Back to top')Conditions \[!if, !else, !elseif, !endif\]

- You can use expression in condition.
- _else_ and _elseif_ are also implemented

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img45b7455d64dc9b9cb0fb39f60ac36831" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('45b7455d64dc9b9cb0fb39f60ac36831')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('45b7455d64dc9b9cb0fb39f60ac36831')"></td><td><div onclick="javascript:ljs('45b7455d64dc9b9cb0fb39f60ac36831')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre45b7455d64dc9b9cb0fb39f60ac36831"><code onmouseover="az=1" onmouseout="az=0">@startuml
!$a = 10
!$ijk = "foo"
Alice -&gt; Bob : A
!if ($ijk == "foo") &amp;&amp; ($a+10&gt;=4)
Alice -&gt; Bob : yes
!else
Alice -&gt; Bob : This should not appear
!endif
Alice -&gt; Bob : B
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="184" src="https://plantuml.com/imgw/img-45b7455d64dc9b9cb0fb39f60ac36831.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')While loop \[!while, !endwhile\]

You can use `!while` and `!endwhile` keywords to have repeat loops.

### While loop (on Activity diagram)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9668f4afa07b24c1a872aae184d9eda2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9668f4afa07b24c1a872aae184d9eda2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9668f4afa07b24c1a872aae184d9eda2')"></td><td><div onclick="javascript:ljs('9668f4afa07b24c1a872aae184d9eda2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9668f4afa07b24c1a872aae184d9eda2"><code onmouseover="az=1" onmouseout="az=0">@startuml
!procedure $foo($arg)
  :procedure start;
  !while $arg!=0
    !$i=3
    #palegreen:arg=$arg;
    !while $i!=0
      :arg=$arg and i=$i;
      !$i = $i - 1
    !endwhile
    !$arg = $arg - 1
  !endwhile
  :procedure end;
!endprocedure

start
$foo(2)
end
@enduml
</code></pre><p></p><p><img loading="lazy" width="121" height="630" src="https://plantuml.com/imgw/img-9668f4afa07b24c1a872aae184d9eda2.png"></p></div></td></tr></tbody></table>

_\[Adapted from [QA-10838](https://forum.plantuml.net/10838/there-better-way-implement-while-loop-perprocess-function?show=10870#a10870)\]_

### While loop (on Mindmap diagram)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdb5ec08f59d411766af29d3ff025cac5" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('db5ec08f59d411766af29d3ff025cac5')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('db5ec08f59d411766af29d3ff025cac5')"></td><td><div onclick="javascript:ljs('db5ec08f59d411766af29d3ff025cac5')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predb5ec08f59d411766af29d3ff025cac5"><code onmouseover="az=1" onmouseout="az=0">@startmindmap
!procedure $foo($arg)
  !while $arg!=0
    !$i=3
    **[#palegreen] arg = $arg
    !while $i!=0
      *** i = $i
      !$i = $i - 1
    !endwhile
    !$arg = $arg - 1
  !endwhile
!endprocedure

\*:While
Loop;
$foo(2)
@endmindmap
</code></pre><p></p><p><img loading="lazy" width="286" height="366" src="https://plantuml.com/imgw/img-db5ec08f59d411766af29d3ff025cac5.png"></p></div></td></tr></tbody></table>

### While loop (on Component/Deployment diagram)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb98bf9139c5cca7f477d53028f467261" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b98bf9139c5cca7f477d53028f467261')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b98bf9139c5cca7f477d53028f467261')"></td><td><div onclick="javascript:ljs('b98bf9139c5cca7f477d53028f467261')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb98bf9139c5cca7f477d53028f467261"><code onmouseover="az=1" onmouseout="az=0">@startuml
!procedure $foo($arg)
  !while $arg!=0
    [Component $arg] as $arg
    !$arg = $arg - 1
  !endwhile
!endprocedure

$foo(4)

1-&gt;2
3--&gt;4
@enduml
</code></pre><p></p><p><img loading="lazy" width="454" height="167" src="https://plantuml.com/imgw/img-b98bf9139c5cca7f477d53028f467261.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-14088](https://forum.plantuml.net/14088/how-to-generate-a-series-of-same-component-at-once?show=14089#a14089)\]_

## ![](https://plantuml.com/backtop1.svg 'Back to top')Procedure \[!procedure, !endprocedure\]

- Procedure names _should_ start with a `$`
- Argument names _should_ start with a `$`
- Procedures can call other procedures

Example:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img51de40dc0b15b831753f39ee5f3ac5e5" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('51de40dc0b15b831753f39ee5f3ac5e5')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('51de40dc0b15b831753f39ee5f3ac5e5')"></td><td><div onclick="javascript:ljs('51de40dc0b15b831753f39ee5f3ac5e5')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre51de40dc0b15b831753f39ee5f3ac5e5"><code onmouseover="az=1" onmouseout="az=0">@startuml
!procedure $msg($source, $destination)
  $source --&gt; $destination
!endprocedure

!procedure $init_class($name)
class $name {
$addCommonMethod()
}
!endprocedure

!procedure $addCommonMethod()
toString()
hashCode()
!endprocedure

$init_class("foo1")
$init_class("foo2")
$msg("foo1", "foo2")
@enduml
</code></pre><p></p><p><img loading="lazy" width="98" height="239" src="https://plantuml.com/imgw/img-51de40dc0b15b831753f39ee5f3ac5e5.png"></p></div></td></tr></tbody></table>

Variables defined in procedures are **local**. It means that the variable is destroyed when the procedure ends.

## ![](https://plantuml.com/backtop1.svg 'Back to top')Return function \[!function, !endfunction\]

A return function does not output any text. It just define a function that you can call:

- directly in variable definition or in diagram text
- from other return functions
- from procedures

- Function name _should_ start with a `$`
- Argument names _should_ start with a `$`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgde42b3af2cff6006905ba296cf26e494" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('de42b3af2cff6006905ba296cf26e494')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('de42b3af2cff6006905ba296cf26e494')"></td><td><div onclick="javascript:ljs('de42b3af2cff6006905ba296cf26e494')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prede42b3af2cff6006905ba296cf26e494"><code onmouseover="az=1" onmouseout="az=0">@startuml
!function $double($a)
!return $a + $a
!endfunction

Alice -&gt; Bob : The double of 3 is $double(3)
@enduml
</code></pre><p></p><p><img loading="lazy" width="189" height="123" src="https://plantuml.com/imgw/img-de42b3af2cff6006905ba296cf26e494.png"></p></div></td></tr></tbody></table>

It is possible to shorten simple function definition in one line:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img254b88138179518cf38f417e71ad0dcc" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('254b88138179518cf38f417e71ad0dcc')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('254b88138179518cf38f417e71ad0dcc')"></td><td><div onclick="javascript:ljs('254b88138179518cf38f417e71ad0dcc')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre254b88138179518cf38f417e71ad0dcc"><code onmouseover="az=1" onmouseout="az=0">@startuml
!function $double($a) !return $a + $a

Alice -&gt; Bob : The double of 3 is $double(3)
Alice -&gt; Bob : $double("This work also for strings.")
@enduml
</code></pre><p></p><p><img loading="lazy" width="370" height="153" src="https://plantuml.com/imgw/img-254b88138179518cf38f417e71ad0dcc.png"></p></div></td></tr></tbody></table>

As in procedure (void function), variable are local by default (they are destroyed when the function is exited). However, you can access to global variables from function. However, you can use the `local` keyword to create a local variable if ever a global variable exists with the same name.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img13338d1ec6b65bd5d0b1a31810e71b57" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('13338d1ec6b65bd5d0b1a31810e71b57')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('13338d1ec6b65bd5d0b1a31810e71b57')"></td><td><div onclick="javascript:ljs('13338d1ec6b65bd5d0b1a31810e71b57')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre13338d1ec6b65bd5d0b1a31810e71b57"><code onmouseover="az=1" onmouseout="az=0">@startuml
!function $dummy()
!local $ijk = "local"
!return "Alice -&gt; Bob : " + $ijk
!endfunction

!global $ijk = "foo"

Alice -&gt; Bob : $ijk
$dummy()
Alice -&gt; Bob : $ijk
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="184" src="https://plantuml.com/imgw/img-13338d1ec6b65bd5d0b1a31810e71b57.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Default argument value

In both procedure and return functions, you can define default values for arguments.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5d47329d0327abc20d50666a49210227" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5d47329d0327abc20d50666a49210227')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5d47329d0327abc20d50666a49210227')"></td><td><div onclick="javascript:ljs('5d47329d0327abc20d50666a49210227')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5d47329d0327abc20d50666a49210227"><code onmouseover="az=1" onmouseout="az=0">@startuml
!function $inc($value, $step=1)
!return $value + $step
!endfunction

Alice -&gt; Bob : Just one more $inc(3)
Alice -&gt; Bob : Add two to three : $inc(3, 2)
@enduml
</code></pre><p></p><p><img loading="lazy" width="188" height="153" src="https://plantuml.com/imgw/img-5d47329d0327abc20d50666a49210227.png"></p></div></td></tr></tbody></table>

Only arguments at the end of the parameter list can have default values.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img58dc1754d6f9408bb64421efb4d9110c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('58dc1754d6f9408bb64421efb4d9110c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('58dc1754d6f9408bb64421efb4d9110c')"></td><td><div onclick="javascript:ljs('58dc1754d6f9408bb64421efb4d9110c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre58dc1754d6f9408bb64421efb4d9110c"><code onmouseover="az=1" onmouseout="az=0">@startuml
!procedure defaulttest($x, $y="DefaultY", $z="DefaultZ")
note over Alice
  x = $x
  y = $y
  z = $z
end note
!endprocedure

defaulttest(1, 2, 3)
defaulttest(1, 2)
defaulttest(1)
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="300" src="https://plantuml.com/imgw/img-58dc1754d6f9408bb64421efb4d9110c.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Unquoted procedure or function \[!unquoted\]

By default, you have to put quotes when you call a function or a procedure. It is possible to use the `unquoted` keyword to indicate that a function or a procedure does not require quotes for its arguments.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img33c6beacc09419517537c125a8abe6c2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('33c6beacc09419517537c125a8abe6c2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('33c6beacc09419517537c125a8abe6c2')"></td><td><div onclick="javascript:ljs('33c6beacc09419517537c125a8abe6c2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre33c6beacc09419517537c125a8abe6c2"><code onmouseover="az=1" onmouseout="az=0">@startuml
!unquoted function id($text1, $text2="FOO") !return $text1 + $text2

alice -&gt; bob : id(aa)
alice -&gt; bob : id(ab,cd)
@enduml
</code></pre><p></p><p><img loading="lazy" width="116" height="153" src="https://plantuml.com/imgw/img-33c6beacc09419517537c125a8abe6c2.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Keywords arguments

Like in Python, you can use keywords arguments :

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6a1c5005e6bd409c972084ba510a319e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6a1c5005e6bd409c972084ba510a319e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6a1c5005e6bd409c972084ba510a319e')"></td><td><div onclick="javascript:ljs('6a1c5005e6bd409c972084ba510a319e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6a1c5005e6bd409c972084ba510a319e"><code onmouseover="az=1" onmouseout="az=0">@startuml

!unquoted procedure $element($alias, $description="", $label="", $technology="", $size=12, $colour="green")
rectangle $alias as "
&lt;color:$colour&gt;&lt;&lt;$alias&gt;&gt;&lt;/color&gt;
==$label==
//&lt;size:$size&gt;[$technology]&lt;/size&gt;//

$description"
!endprocedure

$element(myalias, "This description is %newline()on several lines", $size=10, $technology="Java")
@enduml
</code></pre><p></p><p><img loading="lazy" width="155" height="131" src="https://plantuml.com/imgw/img-6a1c5005e6bd409c972084ba510a319e.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Including files or URL \[!include, !include_many, !include_once\]

Use the `!include` directive to include file in your diagram. Using URL, you can also include file from Internet/Intranet. Protected Internet resources can also be accessed, this is described in [URL authentication](https://plantuml.com/en/url-authentication).

Imagine you have the very same class that appears in many diagrams. Instead of duplicating the description of this class, you can define a file that contains the description.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img17dc8c76fedf718a2c51e02afe6e2afe" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('17dc8c76fedf718a2c51e02afe6e2afe')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('17dc8c76fedf718a2c51e02afe6e2afe')"></td><td><div onclick="javascript:ljs('17dc8c76fedf718a2c51e02afe6e2afe')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre17dc8c76fedf718a2c51e02afe6e2afe"><code onmouseover="az=1" onmouseout="az=0">@startuml

interface List
List : int size()
List : void clear()
List &lt;|.. ArrayList
@enduml
</code></pre><p></p><p><img loading="lazy" width="100" height="204" src="https://plantuml.com/imgw/img-17dc8c76fedf718a2c51e02afe6e2afe.png"></p></div></td></tr></tbody></table>

**File List.iuml**

```
interface List
List : int size()
List : void clear()
```

The file `List.iuml` can be included in many diagrams, and any modification in this file will change all diagrams that include it.

You can also put several `@startuml/@enduml` text block in an included file and then specify which block you want to include adding `!0` where `0` is the block number. The `!0` notation denotes the first diagram.

For example, if you use `!include foo.txt!1`, the second `@startuml/@enduml` block within `foo.txt` will be included.

You can also put an id to some `@startuml/@enduml` text block in an included file using `@startuml(id=MY_OWN_ID)` syntax and then include the block adding `!MY_OWN_ID` when including the file, so using something like `!include foo.txt!MY_OWN_ID`.

By default, a file can only be included once. You can use `!include_many` instead of `!include` if you want to include some file several times. Note that there is also a `!include_once` directive that raises an error if a file is included several times.

## ![](https://plantuml.com/backtop1.svg 'Back to top')Including Subpart \[!startsub, !endsub, !includesub\]

You can also use `!startsub NAME` and `!endsub` to indicate sections of text to include from other files using `!includesub`. For example:

**file1.puml:**

```
@startuml

A -> A : stuff1
!startsub BASIC
B -> B : stuff2
!endsub
C -> C : stuff3
!startsub BASIC
D -> D : stuff4
!endsub
@enduml
```

file1.puml would be rendered exactly as if it were:

```
@startuml

A -> A : stuff1
B -> B : stuff2
C -> C : stuff3
D -> D : stuff4
@enduml
```

However, this would also allow you to have another file2.puml like this:

**file2.puml**

```
@startuml

title this contains only B and D
!includesub file1.puml!BASIC
@enduml
```

This file would be rendered exactly as if:

```
@startuml

title this contains only B and D
B -> B : stuff2
D -> D : stuff4
@enduml
```

## ![](https://plantuml.com/backtop1.svg 'Back to top')Builtin functions \[%\]

Some functions are defined by default. Their name starts by `%`

<table><tbody><tr><td><b>Name</b></td><td><b>Description</b></td><td><b>Example</b></td><td><b>Return</b></td></tr><tr><td><code>%boolval</code></td><td>Convert a value <em>(String, Integer, JSON value)</em> to boolean value</td><td><code>%boolval("true")</code></td><td><code>1</code></td></tr><tr><td><code>%breakline</code></td><td>Return a newline in the PlantUML source code. See more documention on the <a href="https://plantuml.com/en/newline">newline page</a></td><td><code>%breakline()</code></td><td>a newline in the PlantUML source code</td></tr><tr><td><code>%call_user_func</code></td><td>Invoke a return function by its name with given arguments.</td><td><code>%call_user_func("bold", "Hello")</code></td><td>Depends on the called function</td></tr><tr><td><code>%chr</code></td><td>Return a character from a give Unicode value</td><td><code>%chr(65)</code></td><td><code>A</code></td></tr><tr><td><code>%darken</code></td><td>Return a darken color of a given color with some ratio</td><td><code>%darken("red", 20)</code></td><td><code>#CC0000</code></td></tr><tr><td><code>%date</code></td><td>Retrieve current date. You can provide an optional <a href="https://docs.oracle.com/javase/7/docs/api/java/text/SimpleDateFormat.html">format for the date</a></td><td><code>%date("yyyy.MM.dd' at 'HH:mm")</code></td><td>current date</td></tr><tr><td></td><td>You can provide another optional time (<a href="https://en.wikipedia.org/wiki/Epoch%5F%28computing%29">on epoch format</a>)</td><td><code>%date("YYYY-MM-dd", %now() + 1*24*3600)</code></td><td>tomorrow date</td></tr><tr><td><code>%dec2hex</code></td><td>Return the hexadecimal string (String) of a decimal value (Int)</td><td><code>%dec2hex(12)</code></td><td><code>c</code></td></tr><tr><td><code>%dirpath</code></td><td>Retrieve current dirpath</td><td><code>%dirpath()</code></td><td>current path</td></tr><tr><td><code>%feature</code></td><td>Check if some feature is available in the current PlantUML running version</td><td><code>%feature("theme")</code></td><td><code>true</code></td></tr><tr><td><code>%false</code></td><td>Return always <code>false</code></td><td><code>%false()</code></td><td><code>false</code></td></tr><tr><td><code>%file_exists</code></td><td>Check if a file exists on the local filesystem</td><td><code>%file_exists("c:/foo/dummy.txt")</code></td><td><code>true</code> if the file exists</td></tr><tr><td><code>%filename</code></td><td>Retrieve current filename</td><td><code>%filename()</code></td><td>current filename</td></tr><tr><td><code>%function_exists</code></td><td>Check if a function exists</td><td><code>%function_exists("$some_function")</code></td><td><code>true</code> if the function has been defined</td></tr><tr><td><code>%get_all_theme</code></td><td>Retreive a JSON Array of all PlantUML <a href="https://plantuml.com/en/theme">theme</a></td><td><code>%get_all_theme()</code></td><td><code>["_none_", "amiga", ..., "vibrant"]</code></td></tr><tr><td><code>%get_all_stdlib</code></td><td>Retreive a JSON Array of all PlantUML <a href="https://plantuml.com/en/stdlib">stdlib</a> names</td><td><code>%get_all_stdlib()</code></td><td><code>["archimate", "aws", ..., "tupadr3"]</code></td></tr><tr><td><code>%get_all_stdlib</code></td><td>Retreive a JSON Object of all PlantUML <a href="https://plantuml.com/en/stdlib">stdlib</a> information</td><td><code>%get_all_stdlib(detailed)</code></td><td>a JSON Object with stdlib information</td></tr><tr><td><code>%get_variable_value</code></td><td>Retrieve some variable value</td><td><code>%get_variable_value("$my_variable")</code></td><td>the value of the variable</td></tr><tr><td><code>%getenv</code></td><td>Retrieve environment variable value</td><td><code>%getenv("OS")</code></td><td>the value of <code>OS</code> variable</td></tr><tr><td><code>%hex2dec</code></td><td>Return the decimal value (Int) of a hexadecimal string (String)</td><td><code>%hex2dec("d")</code> or <code>%hex2dec(d)</code></td><td><code>13</code></td></tr><tr><td><code>%hsl_color</code></td><td>Return the RGBa color from a HSL color <code>%hsl_color(h, s, l)</code> or <code>%hsl_color(h, s, l, a)</code></td><td><code>%hsl_color(120, 100, 50)</code></td><td><code>#00FF00</code></td></tr><tr><td><code>%intval</code></td><td>Convert a String to Int</td><td><code>%intval("42")</code></td><td><code>42</code></td></tr><tr><td><code>%invoke_procedure</code></td><td>Dynamically invoke a procedure by its name, passing optional arguments to the called procedure.</td><td><code>%invoke_procedure("$go", "hello from Bob...")</code></td><td>Depends on the invoked procedure</td></tr><tr><td><code>%is_dark</code></td><td>Check if a color is a dark one</td><td><code>%is_dark("#000000")</code></td><td><code>true</code></td></tr><tr><td><code>%is_light</code></td><td>Check if a color is a light one</td><td><code>%is_light("#000000")</code></td><td><code>false</code></td></tr><tr><td><code>%lighten</code></td><td>Return a lighten color of a given color with some ratio</td><td><code>%lighten("red", 20)</code></td><td><code>#CC3333</code></td></tr><tr><td><code>%load_json</code></td><td><a href="https://github.com/plantuml/plantuml/pull/755">Load JSON data from local file or external URL</a></td><td><code>%load_json("http://localhost:7778/management/health")</code></td><td>JSON data</td></tr><tr><td><code>%lower</code></td><td>Return a lowercase string</td><td><code>%lower("Hello")</code></td><td><code>hello</code> in that example</td></tr><tr><td><code>%mod</code></td><td>Return the remainder of division of two integers (modulo division)</td><td><code>%mod(10, 3)</code></td><td><code>1</code></td></tr><tr><td><code>%n</code></td><td>Return a newline in rendered text, shortcut to <code>%newline</code> . See more documention on the <a href="https://plantuml.com/en/newline">newline page</a></td><td><code>%n()</code></td><td>a newline</td></tr><tr><td><code>%newline</code></td><td>Return a newline in rendered text, similar to <code>%n</code> . See more documention on the <a href="https://plantuml.com/en/newline">newline page</a></td><td><code>%newline()</code></td><td>a newline</td></tr><tr><td><code>%not</code></td><td>Return the logical negation of an expression</td><td><code>%not(2+2==4)</code></td><td><code>false</code> in that example</td></tr><tr><td><code>%now</code></td><td>Return the current epoch time</td><td><code>%now()</code></td><td><code>1685547132</code> in that example (when updating the doc.)</td></tr><tr><td><code>%ord</code></td><td>Return a Unicode value from a given character</td><td><code>%ord("A")</code></td><td><code>65</code></td></tr><tr><td><code>%lighten</code></td><td>Return a lighten color of a given color with some ratio</td><td><code>%lighten("red", 20)</code></td><td><code>#CC3333</code></td></tr><tr><td><code>%random()</code></td><td>Return randomly the integer <code>0</code> or <code>1</code></td><td><code>%random()</code></td><td><code>0</code> or <code>1</code></td></tr><tr><td><code>%random(n)</code></td><td>Return randomly an interger between <code>0</code> and <code>n - 1</code></td><td><code>%random(5)</code></td><td><code>3</code></td></tr><tr><td><code>%random(min, max)</code></td><td>Return randomly an interger between <code>min</code> and <code>max - 1</code></td><td><code>%random(7, 15)</code></td><td><code>13</code></td></tr><tr><td><code>%reverse_color</code></td><td>Reverse a color using RGB</td><td><code>%reverse_color("#FF7700")</code></td><td><code>#0088FF</code></td></tr><tr><td><code>%reverse_hsluv_color</code></td><td>Reverse a color <a href="https://www.hsluv.org/">using HSLuv</a></td><td><code>%reverse_hsluv_color("#FF7700")</code></td><td><code>#602800</code></td></tr><tr><td><code>%set_variable_value</code></td><td>Set a global variable</td><td><code>%set_variable_value("$my_variable", "some_value")</code></td><td>an empty string</td></tr><tr><td><code>%size</code></td><td>Return the size of any string or JSON structure</td><td><code>%size("foo")</code></td><td><code>3</code> in the example</td></tr><tr><td><code>%splitstr</code></td><td>Split a string into an array based on a specified delimiter.</td><td><code>%splitstr("abc~def~ghi", "~")</code></td><td><code>["abc", "def", "ghi"]</code></td></tr><tr><td><code>%splitstr_regex</code></td><td>Split a string into an array based on a specified REGEX.</td><td><code>%splitstr_regex("AbcDefGhi", "(?=[A-Z])")</code></td><td><code>["Abc", "Def", "Ghi"]</code></td></tr><tr><td><code>%string</code></td><td>Convert an expression to String</td><td><code>%string(1 + 2)</code></td><td><code>3</code> in the example</td></tr><tr><td><code>%strlen</code></td><td>Calculate the length of a String</td><td><code>%strlen("foo")</code></td><td><code>3</code> in the example</td></tr><tr><td><code>%strpos</code></td><td>Search a substring in a string</td><td><code>%strpos("abcdef", "ef")</code></td><td>4 (position of <code>ef</code>)</td></tr><tr><td><code>%substr</code></td><td>Extract a substring. Takes 2 or 3 arguments</td><td><code>%substr("abcdef", 3, 2)</code></td><td><code>"de"</code> in the example</td></tr><tr><td><code>%true</code></td><td>Return always <code>true</code></td><td><code>%true()</code></td><td><code>true</code></td></tr><tr><td><code>%upper</code></td><td>Return an uppercase string</td><td><code>%upper("Hello")</code></td><td><code>HELLO</code> in that example</td></tr><tr><td><code>%variable_exists</code></td><td>Check if a variable exists</td><td><code>%variable_exists("$my_variable")</code></td><td><code>true</code> if the variable has been defined exists</td></tr><tr><td><code>%version</code></td><td>Return PlantUML current version</td><td><code>%version()</code></td><td><code>1.2020.8</code> for example</td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Logging \[!log\]

You can use `!log` to add some log output when generating the diagram. This has no impact at all on the diagram itself. However, those logs are printed in the command line's output stream. This could be useful for debug purpose.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img2e7d2769275c10d301429ed4fc9f3cde" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('2e7d2769275c10d301429ed4fc9f3cde')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('2e7d2769275c10d301429ed4fc9f3cde')"></td><td><div onclick="javascript:ljs('2e7d2769275c10d301429ed4fc9f3cde')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre2e7d2769275c10d301429ed4fc9f3cde"><code onmouseover="az=1" onmouseout="az=0">@startuml
!function bold($text)
!$result = "&lt;b&gt;"+ $text +"&lt;/b&gt;"
!log Calling bold function with $text. The result is $result
!return $result
!endfunction

Alice -&gt; Bob : This is bold("bold")
Alice -&gt; Bob : This is bold("a second call")
@enduml
</code></pre><p></p><p><img loading="lazy" width="198" height="153" src="https://plantuml.com/imgw/img-2e7d2769275c10d301429ed4fc9f3cde.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Memory dump \[!dump_memory\]

You can use `!dump_memory` to dump the full content of the memory when generating the diagram. An optional string can be put after `!dump_memory`. This has no impact at all on the diagram itself. This could be useful for debug purpose.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img307518192ef0219afd556b52fb9aae18" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('307518192ef0219afd556b52fb9aae18')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('307518192ef0219afd556b52fb9aae18')"></td><td><div onclick="javascript:ljs('307518192ef0219afd556b52fb9aae18')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre307518192ef0219afd556b52fb9aae18"><code onmouseover="az=1" onmouseout="az=0">@startuml
!function $inc($string)
!$val = %intval($string)
!log value is $val
!dump_memory
!return $val+1
!endfunction

Alice -&gt; Bob : 4 $inc("3")
!unused = "foo"
!dump_memory EOF
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="123" src="https://plantuml.com/imgw/img-307518192ef0219afd556b52fb9aae18.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Assertion \[!assert\]

You can put assertions in your diagram.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd2f70a24b7c89c6602eb31da0d2516a4" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d2f70a24b7c89c6602eb31da0d2516a4')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d2f70a24b7c89c6602eb31da0d2516a4')"></td><td><div onclick="javascript:ljs('d2f70a24b7c89c6602eb31da0d2516a4')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred2f70a24b7c89c6602eb31da0d2516a4"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice -&gt; Bob : Hello
!assert %strpos("abcdef", "cd")==3 : "This always fails"
@enduml
</code></pre><p></p><p><img loading="lazy" width="532" height="367" src="https://plantuml.com/imgw/img-d2f70a24b7c89c6602eb31da0d2516a4.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Building custom library \[!import, !include\]

It's possible to package a set of included files into a single .zip or .jar archive. This single zip/jar can then be imported into your diagram using `!import` directive.

Once the library has been imported, you can `!include` file from this single zip/jar.

**Example:**

```
@startuml

!import /path/to/customLibrary.zip
' This just adds "customLibrary.zip" in the search path

!include myFolder/myFile.iuml
' Assuming that myFolder/myFile.iuml is located somewhere
' either inside "customLibrary.zip" or on the local filesystem

...
```

## ![](https://plantuml.com/backtop1.svg 'Back to top')Search path

You can specify the java property `plantuml.include.path` in the command line.

For example:

```
java -Dplantuml.include.path="c:/mydir" -jar plantuml.jar atest1.txt
```

Note the this -D option has to put before the -jar option. -D options after the -jar option will be used to define constants within plantuml preprocessor.

## ![](https://plantuml.com/backtop1.svg 'Back to top')Argument concatenation \[##\]

It is possible to append text to a macro argument using the `##` syntax.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd9d364c1b8b587e6b33d89bf968e7011" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d9d364c1b8b587e6b33d89bf968e7011')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d9d364c1b8b587e6b33d89bf968e7011')"></td><td><div onclick="javascript:ljs('d9d364c1b8b587e6b33d89bf968e7011')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred9d364c1b8b587e6b33d89bf968e7011"><code onmouseover="az=1" onmouseout="az=0">@startuml
!unquoted procedure COMP_TEXTGENCOMP(name)
[name] &lt;&lt; Comp &gt;&gt;
interface Ifc &lt;&lt; IfcType &gt;&gt; AS name##Ifc
name##Ifc - [name]
!endprocedure
COMP_TEXTGENCOMP(dummy)
@enduml
</code></pre><p></p><p><img loading="lazy" width="182" height="81" src="https://plantuml.com/imgw/img-d9d364c1b8b587e6b33d89bf968e7011.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Dynamic invocation \[`%invoke_procedure()`, `%call_user_func()`\]

You can dynamically invoke a procedure using the special `%invoke_procedure()` procedure. This procedure takes as first argument the name of the actual procedure to be called. The optional following arguments are copied to the called procedure.

For example, you can have:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbf537e41e9a67b3d2d0aed5f38f1591b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('bf537e41e9a67b3d2d0aed5f38f1591b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('bf537e41e9a67b3d2d0aed5f38f1591b')"></td><td><div onclick="javascript:ljs('bf537e41e9a67b3d2d0aed5f38f1591b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebf537e41e9a67b3d2d0aed5f38f1591b"><code onmouseover="az=1" onmouseout="az=0">@startuml
!procedure $go()
  Bob -&gt; Alice : hello
!endprocedure

!$wrapper = "$go"

%invoke_procedure($wrapper)
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="123" src="https://plantuml.com/imgw/img-bf537e41e9a67b3d2d0aed5f38f1591b.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9805cf787d2d3b196ff14a0a859e49b9" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9805cf787d2d3b196ff14a0a859e49b9')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9805cf787d2d3b196ff14a0a859e49b9')"></td><td><div onclick="javascript:ljs('9805cf787d2d3b196ff14a0a859e49b9')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9805cf787d2d3b196ff14a0a859e49b9"><code onmouseover="az=1" onmouseout="az=0">@startuml
!procedure $go($txt)
  Bob -&gt; Alice : $txt
!endprocedure

%invoke_procedure("$go", "hello from Bob...")
@enduml
</code></pre><p></p><p><img loading="lazy" width="170" height="123" src="https://plantuml.com/imgw/img-9805cf787d2d3b196ff14a0a859e49b9.png"></p></div></td></tr></tbody></table>

For return functions, you can use the corresponding special function `%call_user_func()` :

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4ba4284c1b127c9f544b88ec13f3a086" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4ba4284c1b127c9f544b88ec13f3a086')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4ba4284c1b127c9f544b88ec13f3a086')"></td><td><div onclick="javascript:ljs('4ba4284c1b127c9f544b88ec13f3a086')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4ba4284c1b127c9f544b88ec13f3a086"><code onmouseover="az=1" onmouseout="az=0">@startuml
!function bold($text)
!return "&lt;b&gt;"+ $text +"&lt;/b&gt;"
!endfunction

Alice -&gt; Bob : %call_user_func("bold", "Hello") there
@enduml
</code></pre><p></p><p><img loading="lazy" width="140" height="123" src="https://plantuml.com/imgw/img-4ba4284c1b127c9f544b88ec13f3a086.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Evaluation of addition depending of data types \[+\]

Evaluation of `$a + $b` depending of type of `$a` or `$b`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge8214dfc7d9ca486a56c4e0d9dd84768" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e8214dfc7d9ca486a56c4e0d9dd84768')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e8214dfc7d9ca486a56c4e0d9dd84768')"></td><td><div onclick="javascript:ljs('e8214dfc7d9ca486a56c4e0d9dd84768')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree8214dfc7d9ca486a56c4e0d9dd84768"><code onmouseover="az=1" onmouseout="az=0">@startuml
title
&lt;#LightBlue&gt;|= |=  $a |=  $b |=  &lt;U+0025&gt;string($a + $b)|
&lt;#LightGray&gt;| type | str | str | str (concatenation) |
| example |= "a" |= "b" |= %string("a" + "b") |
&lt;#LightGray&gt;| type | str | int | str (concatenation) |
| ex.|= "a" |=  2  |= %string("a" + 2)   |
&lt;#LightGray&gt;| type | str | int | str (concatenation) |
| ex.|=  1  |= "b" |= %string(1 + "b")   |
&lt;#LightGray&gt;| type | bool | str | str (concatenation) |
| ex.|= &lt;U+0025&gt;true() |= "b" |= %string(%true() + "b") |
&lt;#LightGray&gt;| type | str | bool | str (concatenation) |
| ex.|= "a" |= &lt;U+0025&gt;false() |= %string("a" + %false()) |
&lt;#LightGray&gt;| type |  int  |  int | int (addition of int) |
| ex.|=  1  |=  2  |= %string(1 + 2)     |
&lt;#LightGray&gt;| type |  bool  |  int | int (addition) |
| ex.|= &lt;U+0025&gt;true() |= 2 |= %string(%true() + 2) |
&lt;#LightGray&gt;| type |  int  |  bool | int (addition) |
| ex.|=  1  |= &lt;U+0025&gt;false() |= %string(1 + %false()) |
&lt;#LightGray&gt;| type |  int  |  int | int (addition) |
| ex.|=  1  |=  &lt;U+0025&gt;intval("2")  |= %string(1 + %intval("2")) |
end title
@enduml
</code></pre><p></p><p><img loading="lazy" width="375" height="365" src="https://plantuml.com/imgw/img-e8214dfc7d9ca486a56c4e0d9dd84768.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg 'Back to top')Preprocessing JSON

You can extend the functionality of the current Preprocessing with [JSON Preprocessing](https://plantuml.com/en/preprocessing-json) features:

- JSON Variable definition
- Access to JSON data
- Loop over JSON array

_(See more details on [Preprocessing-JSON page](https://plantuml.com/en/preprocessing-json))_

## ![](https://plantuml.com/backtop1.svg 'Back to top')Including theme \[!theme\]

Use the `!theme` directive to change [the default theme of your diagram](https://plantuml.com/en/theme).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img812a492767bcbc5c3ef3fe452bb68512" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('812a492767bcbc5c3ef3fe452bb68512')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('812a492767bcbc5c3ef3fe452bb68512')"></td><td><div onclick="javascript:ljs('812a492767bcbc5c3ef3fe452bb68512')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre812a492767bcbc5c3ef3fe452bb68512"><code onmouseover="az=1" onmouseout="az=0">@startuml
!theme spacelab
class Example {
  Theme spacelab
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="152" height="112" src="https://plantuml.com/imgw/img-812a492767bcbc5c3ef3fe452bb68512.png"></p></div></td></tr></tbody></table>

You will find more information [on the dedicated page](https://plantuml.com/en/theme).

## ![](https://plantuml.com/backtop1.svg 'Back to top')Migration notes

The current preprocessor is an update from some legacy preprocessor.

Even if some legacy features are still supported with the actual preprocessor, you should not use them any more (they might be removed in some long term future).

- You should not use `!define` and `!definelong` anymore. Use `!function`, `!procedure` or variable definition instead.

- `!define` should be replaced by return `!function`
- `!definelong` should be replaced by `!procedure`.

- `!include` now allows multiple inclusions : you don't have to use `!include_many` anymore
- `!include` now accepts a URL, so you don't need `!includeurl`
- Some features (like `%date%`) have been replaced by builtin functions (for example `%date()`)
- When calling a legacy `!definelong` macro with no arguments, you do have to use parenthesis. You have to use `my_own_definelong()` because `my_own_definelong` without parenthesis is not recognized by the new preprocessor.

Please contact us if you have any issues.

## ![](https://plantuml.com/backtop1.svg 'Back to top')`%splitstr` builtin function

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img2d33923faed4a83d0039dee383100674" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('2d33923faed4a83d0039dee383100674')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('2d33923faed4a83d0039dee383100674')"></td><td><div onclick="javascript:ljs('2d33923faed4a83d0039dee383100674')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre2d33923faed4a83d0039dee383100674"><code onmouseover="az=1" onmouseout="az=0">@startmindmap
!$list = %splitstr("abc~def~ghi", "~")

- root
  !foreach $item in $list
  \*\* $item
  !endfor
  @endmindmap
  </code></pre><p></p><p><img loading="lazy" width="157" height="193" src="https://plantuml.com/imgw/img-2d33923faed4a83d0039dee383100674.png"></p></div></td></tr></tbody></table>

Similar to:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge7965cf70d3f50cd788f0e4f9d285c76" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e7965cf70d3f50cd788f0e4f9d285c76')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e7965cf70d3f50cd788f0e4f9d285c76')"></td><td><div onclick="javascript:ljs('e7965cf70d3f50cd788f0e4f9d285c76')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree7965cf70d3f50cd788f0e4f9d285c76"><code onmouseover="az=1" onmouseout="az=0">@startmindmap
* root
!foreach $item in ["abc", "def", "ghi"]
  ** $item
!endfor
@endmindmap
</code></pre><p></p><p><img loading="lazy" width="157" height="193" src="https://plantuml.com/imgw/img-e7965cf70d3f50cd788f0e4f9d285c76.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-15374](https://forum.plantuml.net/15374/delimited-string-split-into-an-array)\]_

## ![](https://plantuml.com/backtop1.svg 'Back to top')`%splitstr_regex` builtin function

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img8433d497bff9cf77b675a04188748322" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('8433d497bff9cf77b675a04188748322')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('8433d497bff9cf77b675a04188748322')"></td><td><div onclick="javascript:ljs('8433d497bff9cf77b675a04188748322')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre8433d497bff9cf77b675a04188748322"><code onmouseover="az=1" onmouseout="az=0">@startmindmap
!$list = %splitstr_regex("AbcDefGhi", "(?=[A-Z])")

- root
  !foreach $item in $list
  \*\* $item
  !endfor
  @endmindmap
  </code></pre><p></p><p><img loading="lazy" width="159" height="193" src="https://plantuml.com/imgw/img-8433d497bff9cf77b675a04188748322.png"></p></div></td></tr></tbody></table>

Similar to:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img09222bea94a9fad99025121bf1691bf1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('09222bea94a9fad99025121bf1691bf1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('09222bea94a9fad99025121bf1691bf1')"></td><td><div onclick="javascript:ljs('09222bea94a9fad99025121bf1691bf1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre09222bea94a9fad99025121bf1691bf1"><code onmouseover="az=1" onmouseout="az=0">@startmindmap
* root
!foreach $item in ["Abc", "Def", "Ghi"]
  ** $item
!endfor
@endmindmap
</code></pre><p></p><p><img loading="lazy" width="159" height="193" src="https://plantuml.com/imgw/img-09222bea94a9fad99025121bf1691bf1.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-18827](https://forum.plantuml.net/18827/%25splitstr-please-add-regex-support-as-second-argument)\]_

## ![](https://plantuml.com/backtop1.svg 'Back to top')`%get_all_theme` builtin function

You can use the `%get_all_theme()` builtin function to retreive a JSON array of all PlantUML [theme](https://plantuml.com/en/theme).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9a3d4ab94b2cacd481d37b72e3dd8bdd" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9a3d4ab94b2cacd481d37b72e3dd8bdd')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9a3d4ab94b2cacd481d37b72e3dd8bdd')"></td><td><div onclick="javascript:ljs('9a3d4ab94b2cacd481d37b72e3dd8bdd')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9a3d4ab94b2cacd481d37b72e3dd8bdd"><code onmouseover="az=1" onmouseout="az=0">@startjson
%get_all_theme()
@endjson
</code></pre><p></p><p><img loading="lazy" width="160" height="971" src="https://plantuml.com/imgw/img-9a3d4ab94b2cacd481d37b72e3dd8bdd.png"></p></div></td></tr></tbody></table>

_\[from version 1.2024.4\]_

## ![](https://plantuml.com/backtop1.svg 'Back to top')`%get_all_stdlib` builtin function

### Compact version (only standard library name)

You can use the `%get_all_stdlib()` builtin function to retreive a JSON array of all PlantUML [stdlib](https://plantuml.com/en/stdlib) names.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgfb5e73ee9d8f25b5ce61a761bdc503f6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('fb5e73ee9d8f25b5ce61a761bdc503f6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('fb5e73ee9d8f25b5ce61a761bdc503f6')"></td><td><div onclick="javascript:ljs('fb5e73ee9d8f25b5ce61a761bdc503f6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prefb5e73ee9d8f25b5ce61a761bdc503f6"><code onmouseover="az=1" onmouseout="az=0">@startjson
%get_all_stdlib()
@endjson
</code></pre><p></p><p><img loading="lazy" width="128" height="690" src="https://plantuml.com/imgw/img-fb5e73ee9d8f25b5ce61a761bdc503f6.png"></p></div></td></tr></tbody></table>

### Detailed version (with version and source)

With whatever parameter, you can use `%get_all_stdlib(detailed)` to retreive a JSON object of all PlantUML [stdlib](https://plantuml.com/en/stdlib).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3a3f73fba7610b54f00c08bf7e2cf6c9" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3a3f73fba7610b54f00c08bf7e2cf6c9')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3a3f73fba7610b54f00c08bf7e2cf6c9')"></td><td><div onclick="javascript:ljs('3a3f73fba7610b54f00c08bf7e2cf6c9')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3a3f73fba7610b54f00c08bf7e2cf6c9"><code onmouseover="az=1" onmouseout="az=0">@startjson
%get_all_stdlib(detailed)
@endjson
</code></pre><p></p><p><img loading="lazy" width="728" height="2575" src="https://plantuml.com/imgw/img-3a3f73fba7610b54f00c08bf7e2cf6c9.png"></p></div></td></tr></tbody></table>

_\[from version 1.2024.4\]_

## ![](https://plantuml.com/backtop1.svg 'Back to top')`%random` builtin function

You can use the `%random` builtin function to retreive a random integer.

<table><tbody><tr><td><b>Nb param.</b></td><td><b>Input</b></td><td><b>Output</b></td></tr><tr><td>0</td><td>%random()</td><td>returns <em>0</em> or <em>1</em></td></tr><tr><td>1</td><td>%random(n)</td><td>returns an interger between <em>0</em> and <em>n - 1</em></td></tr><tr><td>2</td><td>%random(min, max)</td><td>returns an interger between <em>min</em> and <em>max - 1</em></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbb8562e96ea145eba47234f4e111154d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('bb8562e96ea145eba47234f4e111154d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('bb8562e96ea145eba47234f4e111154d')"></td><td><div onclick="javascript:ljs('bb8562e96ea145eba47234f4e111154d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebb8562e96ea145eba47234f4e111154d"><code onmouseover="az=1" onmouseout="az=0">@startcreole
| Nb param. | Input | Output |
| 0 | &lt;U+0025&gt;random()      | %random()     |
| 1 | &lt;U+0025&gt;random(5)     | %random(5)    |
| 2 | &lt;U+0025&gt;random(7, 15) | %random(7, 15) |
@endcreole
</code></pre><p></p><p><img loading="lazy" width="211" height="73" src="https://plantuml.com/imgw/img-bb8562e96ea145eba47234f4e111154d.png"></p></div></td></tr></tbody></table>

_\[from version 1.2024.2\]_

## ![](https://plantuml.com/backtop1.svg 'Back to top')`%boolval` builtin function

You can use the `%boolval` builtin function to manage boolean value.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge885edc17c1e2f81b64d922a52e3194c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e885edc17c1e2f81b64d922a52e3194c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e885edc17c1e2f81b64d922a52e3194c')"></td><td><div onclick="javascript:ljs('e885edc17c1e2f81b64d922a52e3194c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree885edc17c1e2f81b64d922a52e3194c"><code onmouseover="az=1" onmouseout="az=0">@startcreole
&lt;#ccc&gt;|= Input                               |= Output |
| &lt;U+0025&gt;boolval(1)                         | %boolval(1) |
| &lt;U+0025&gt;boolval(0)                         | %boolval(0) |
| &lt;U+0025&gt;boolval(&lt;U+0025&gt;true())            | %boolval(%true()) |
| &lt;U+0025&gt;boolval(&lt;U+0025&gt;false())           | %boolval(%false()) |
| &lt;U+0025&gt;boolval(true)                      | %boolval(true) |
| &lt;U+0025&gt;boolval(false)                     | %boolval(false) |
| &lt;U+0025&gt;boolval(TRUE)                      | %boolval(TRUE) |
| &lt;U+0025&gt;boolval(FALSE)                     | %boolval(FALSE) |
| &lt;U+0025&gt;boolval("true")                    | %boolval("true") |
| &lt;U+0025&gt;boolval("false")                   | %boolval("false") |
| &lt;U+0025&gt;boolval(&lt;U+0025&gt;str2json("true"))  | %boolval(%str2json("true")) |
| &lt;U+0025&gt;boolval(&lt;U+0025&gt;str2json("false")) | %boolval(%str2json("false")) |
@endcreole
</code></pre><p></p><p><img loading="lazy" width="234" height="233" src="https://plantuml.com/imgw/img-e885edc17c1e2f81b64d922a52e3194c.png"></p></div></td></tr></tbody></table>

_\[Ref. [PR-1873](https://github.com/plantuml/plantuml/pull/1873), from version 1.2024.7\]_

## ![](https://plantuml.com/backtop1.svg 'Back to top')Escape function

Some character are specials, then we can escape them with some escape functions:

<table><tbody><tr><td><b>Escape function</b></td><td><b>Output</b></td></tr><tr><td><code>%dollar()</code></td><td><code>$</code></td></tr><tr><td><code>%percent()</code></td><td><code>%</code></td></tr><tr><td><code>%backslash()</code></td><td><code>\</code></td></tr></tbody></table>

_\[Ref. [QA-19607](https://forum.plantuml.net/19607/1-2025-0-has-%25newline-bug-older-version-1-2024-7-was-working?show=19651#c19651)\]_
