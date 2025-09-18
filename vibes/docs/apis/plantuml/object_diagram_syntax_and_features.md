---
created: 2025-07-15T23:31:14 (UTC +09:00)
tags: []
source: https://plantuml.com/en/object-diagram
author: 
---

# Object Diagram syntax and features

> ## Excerpt
> PlantUML object diagram syntax: You can define objects, fields, relationships, packages, notes...  Changing fonts and colors is also possible.

---
## Object Diagram

An **object diagram** is a graphical representation that showcases objects and their relationships at a specific moment in time. It provides a snapshot of the system's structure, capturing the static view of the instances present and their associations.

**PlantUML** offers a simple and intuitive way to create object diagrams using plain text. Its user-friendly syntax allows for quick diagram creation without the need for complex GUI tools. Moreover, the [PlantUML forum](https://forum.plantuml.net/) provides a platform for users to discuss, share, and seek assistance, fostering a collaborative community. By choosing PlantUML, users benefit from both the efficiency of markdown-based diagramming and the support of an active community.

## ![](https://plantuml.com/backtop1.svg "Back to top")Definition of objects

You define instances of objects using the `object` keyword.

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="img564af8d5328cf5b3972154f36af05c5f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('564af8d5328cf5b3972154f36af05c5f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('564af8d5328cf5b3972154f36af05c5f')"></td><td><div onclick="javascript:ljs('564af8d5328cf5b3972154f36af05c5f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre564af8d5328cf5b3972154f36af05c5f"><code onmouseover="az=1" onmouseout="az=0">@startuml
object firstObject
object "My Second Object" as o2
@enduml
</code></pre><p></p><p><img loading="lazy" width="252" height="49" src="https://plantuml.com/imgw/img-564af8d5328cf5b3972154f36af05c5f.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Relations between objects

Relations between objects are defined using the following symbols :

<table><tbody><tr><td><b>Type</b></td><td><b>Symbol</b></td><td><b>Purpose</b></td></tr><tr><td>Extension</td><td><code>&lt;|--</code></td><td>Specialization of a class in a hierarchy</td></tr><tr><td>Implementation</td><td><code>&lt;|..</code></td><td>Realization of an interface by a class</td></tr><tr><td>Composition</td><td><code>*--</code></td><td>The part cannot exist without the whole</td></tr><tr><td>Aggregation</td><td><code>o--</code></td><td>The part can exist independently of the whole</td></tr><tr><td>Dependency</td><td><code>--&gt;</code></td><td>The object uses another object</td></tr><tr><td>Dependency</td><td><code>..&gt;</code></td><td>A weaker form of dependency</td></tr></tbody></table>

It is possible to replace `--` by `..` to have a dotted line.

Knowing those rules, it is possible to draw the following drawings.

It is possible a add a label on the relation, using `:` followed by the text of the label.

For cardinality, you can use double-quotes `""` on each side of the relation.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img49eeb30b881d1f28c460eaedc45cd8ce" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('49eeb30b881d1f28c460eaedc45cd8ce')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('49eeb30b881d1f28c460eaedc45cd8ce')"></td><td><div onclick="javascript:ljs('49eeb30b881d1f28c460eaedc45cd8ce')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre49eeb30b881d1f28c460eaedc45cd8ce"><code onmouseover="az=1" onmouseout="az=0">@startuml
object Object01
object Object02
object Object03
object Object04
object Object05
object Object06
object Object07
object Object08

Object01 &lt;|-- Object02
Object03 *-- Object04
Object05 o-- "4" Object06
Object07 .. Object08 : some labels
@enduml
</code></pre><p></p><p><img loading="lazy" width="434" height="165" src="https://plantuml.com/imgw/img-49eeb30b881d1f28c460eaedc45cd8ce.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Associations objects

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6a5092da524496d3b4eb34f0ad5e93d1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6a5092da524496d3b4eb34f0ad5e93d1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6a5092da524496d3b4eb34f0ad5e93d1')"></td><td><div onclick="javascript:ljs('6a5092da524496d3b4eb34f0ad5e93d1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6a5092da524496d3b4eb34f0ad5e93d1"><code onmouseover="az=1" onmouseout="az=0">@startuml
object o1
object o2
diamond dia
object o3

o1  --&gt; dia
o2  --&gt; dia
dia --&gt; o3
@enduml
</code></pre><p></p><p><img loading="lazy" width="106" height="231" src="https://plantuml.com/imgw/img-6a5092da524496d3b4eb34f0ad5e93d1.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Adding fields

To declare fields, you can use the symbol `:` followed by the field's name.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb5d8d6680aed740469b46c16942701cc" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b5d8d6680aed740469b46c16942701cc')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b5d8d6680aed740469b46c16942701cc')"></td><td><div onclick="javascript:ljs('b5d8d6680aed740469b46c16942701cc')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb5d8d6680aed740469b46c16942701cc"><code onmouseover="az=1" onmouseout="az=0">@startuml

object user

user : name = "Dummy"
user : id = 123

@enduml
</code></pre><p></p><p><img loading="lazy" width="141" height="84" src="https://plantuml.com/imgw/img-b5d8d6680aed740469b46c16942701cc.png"></p></div></td></tr></tbody></table>

It is also possible to group all fields between brackets `{}`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga752795394914de08c5c933c6c72bfd2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a752795394914de08c5c933c6c72bfd2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a752795394914de08c5c933c6c72bfd2')"></td><td><div onclick="javascript:ljs('a752795394914de08c5c933c6c72bfd2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea752795394914de08c5c933c6c72bfd2"><code onmouseover="az=1" onmouseout="az=0">@startuml

object user {
  name = "Dummy"
  id = 123
}

@enduml
</code></pre><p></p><p><img loading="lazy" width="141" height="84" src="https://plantuml.com/imgw/img-a752795394914de08c5c933c6c72bfd2.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Common features with class diagrams

-   [Hide attributes, methods...](https://plantuml.com/en/class-diagram#Hide)
-   [Defines notes](https://plantuml.com/en/class-diagram#Notes)
-   [Use packages](https://plantuml.com/en/class-diagram#Using)
-   [Skin the output](https://plantuml.com/en/class-diagram#Skinparam)

## ![](https://plantuml.com/backtop1.svg "Back to top")Map table or associative array

You can define a map table or [associative array](https://en.wikipedia.org/wiki/Associative_array), with `map` keyword and `=>` separator.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf0aeaef891e0265cff26fc8ae678d902" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f0aeaef891e0265cff26fc8ae678d902')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f0aeaef891e0265cff26fc8ae678d902')"></td><td><div onclick="javascript:ljs('f0aeaef891e0265cff26fc8ae678d902')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref0aeaef891e0265cff26fc8ae678d902"><code onmouseover="az=1" onmouseout="az=0">@startuml
map CapitalCity {
 UK =&gt; London
 USA =&gt; Washington
 Germany =&gt; Berlin
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="171" height="106" src="https://plantuml.com/imgw/img-f0aeaef891e0265cff26fc8ae678d902.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img55292359886a9032cdce7607ba805f03" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('55292359886a9032cdce7607ba805f03')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('55292359886a9032cdce7607ba805f03')"></td><td><div onclick="javascript:ljs('55292359886a9032cdce7607ba805f03')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre55292359886a9032cdce7607ba805f03"><code onmouseover="az=1" onmouseout="az=0">@startuml
map "Map **Contry =&gt; CapitalCity**" as CC {
 UK =&gt; London
 USA =&gt; Washington
 Germany =&gt; Berlin
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="207" height="106" src="https://plantuml.com/imgw/img-55292359886a9032cdce7607ba805f03.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img2d44bcbd73bbf6e63bd3ac4896e0adcb" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('2d44bcbd73bbf6e63bd3ac4896e0adcb')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('2d44bcbd73bbf6e63bd3ac4896e0adcb')"></td><td><div onclick="javascript:ljs('2d44bcbd73bbf6e63bd3ac4896e0adcb')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre2d44bcbd73bbf6e63bd3ac4896e0adcb"><code onmouseover="az=1" onmouseout="az=0">@startuml
map "map: Map&lt;Integer, String&gt;" as users {
 1 =&gt; Alice
 2 =&gt; Bob
 3 =&gt; Charlie
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="200" height="106" src="https://plantuml.com/imgw/img-2d44bcbd73bbf6e63bd3ac4896e0adcb.png"></p></div></td></tr></tbody></table>

And add link with object.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img627c3fb91d24a4e57eda8ef5381696f4" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('627c3fb91d24a4e57eda8ef5381696f4')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('627c3fb91d24a4e57eda8ef5381696f4')"></td><td><div onclick="javascript:ljs('627c3fb91d24a4e57eda8ef5381696f4')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre627c3fb91d24a4e57eda8ef5381696f4"><code onmouseover="az=1" onmouseout="az=0">@startuml
object London

map CapitalCity {
 UK *-&gt; London
 USA =&gt; Washington
 Germany =&gt; Berlin
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="266" height="99" src="https://plantuml.com/imgw/img-627c3fb91d24a4e57eda8ef5381696f4.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb4f3f17d4de431035862f8132d950716" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b4f3f17d4de431035862f8132d950716')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b4f3f17d4de431035862f8132d950716')"></td><td><div onclick="javascript:ljs('b4f3f17d4de431035862f8132d950716')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb4f3f17d4de431035862f8132d950716"><code onmouseover="az=1" onmouseout="az=0">@startuml
object London
object Washington
object Berlin
object NewYork

map CapitalCity {
 UK *-&gt; London
 USA *--&gt; Washington
 Germany *---&gt; Berlin
}

NewYork --&gt; CapitalCity::USA
@enduml
</code></pre><p></p><p><img loading="lazy" width="247" height="399" src="https://plantuml.com/imgw/img-b4f3f17d4de431035862f8132d950716.png"></p></div></td></tr></tbody></table>

_\[Ref. [#307](https://github.com/plantuml/plantuml/issues/307)\]_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge919670571458a9b7878acc7c46bff07" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e919670571458a9b7878acc7c46bff07')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e919670571458a9b7878acc7c46bff07')"></td><td><div onclick="javascript:ljs('e919670571458a9b7878acc7c46bff07')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree919670571458a9b7878acc7c46bff07"><code onmouseover="az=1" onmouseout="az=0">@startuml
package foo {
    object baz
}

package bar {
    map A {
        b *-&gt; foo.baz
        c =&gt;
    }
}

A::c --&gt; foo
@enduml
</code></pre><p></p><p><img loading="lazy" width="123" height="274" src="https://plantuml.com/imgw/img-e919670571458a9b7878acc7c46bff07.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-12934](https://forum.plantuml.net/12934)\]_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img87460c32f03992da2598f040b2402232" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('87460c32f03992da2598f040b2402232')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('87460c32f03992da2598f040b2402232')"></td><td><div onclick="javascript:ljs('87460c32f03992da2598f040b2402232')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre87460c32f03992da2598f040b2402232"><code onmouseover="az=1" onmouseout="az=0">@startuml
object Foo
map Bar {
  abc=&gt;
  def=&gt;
}
object Baz

Bar::abc --&gt; Baz : Label one
Foo --&gt; Bar::def : Label two
@enduml
</code></pre><p></p><p><img loading="lazy" width="127" height="315" src="https://plantuml.com/imgw/img-87460c32f03992da2598f040b2402232.png"></p></div></td></tr></tbody></table>

_\[Ref. [#307](https://github.com/plantuml/plantuml/issues/307)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Program (or project) evaluation and review technique (PERT) with map

You can use `map table` in order to make [Program (or project) evaluation and review technique (PERT)](https://en.wikipedia.org/wiki/Program_evaluation_and_review_technique) diagram.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgde9fba5c0f10af005ad65576cf69f028" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('de9fba5c0f10af005ad65576cf69f028')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('de9fba5c0f10af005ad65576cf69f028')"></td><td><div onclick="javascript:ljs('de9fba5c0f10af005ad65576cf69f028')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prede9fba5c0f10af005ad65576cf69f028"><code onmouseover="az=1" onmouseout="az=0">@startuml PERT
left to right direction
' Horizontal lines: --&gt;, &lt;--, &lt;--&gt;
' Vertical lines: -&gt;, &lt;-, &lt;-&gt;
title PERT: Project Name

map Kick.Off {
}
map task.1 {
    Start =&gt; End
}
map task.2 {
    Start =&gt; End
}
map task.3 {
    Start =&gt; End
}
map task.4 {
    Start =&gt; End
}
map task.5 {
    Start =&gt; End
}
Kick.Off --&gt; task.1 : Label 1
Kick.Off --&gt; task.2 : Label 2
Kick.Off --&gt; task.3 : Label 3
task.1 --&gt; task.4
task.2 --&gt; task.4
task.3 --&gt; task.4
task.4 --&gt; task.5 : Label 4
@enduml
</code></pre><p></p><p><img loading="lazy" width="666" height="326" src="https://plantuml.com/imgw/img-de9fba5c0f10af005ad65576cf69f028.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-12337](https://forum.plantuml.net/12337/there-any-support-for-pert-style-project-management-diagrams?show=14426#a14426)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Display JSON Data on Class or Object diagram

### Simple example

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img85e3a54ce88f2ff453d9347180ec7e2e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('85e3a54ce88f2ff453d9347180ec7e2e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('85e3a54ce88f2ff453d9347180ec7e2e')"></td><td><div onclick="javascript:ljs('85e3a54ce88f2ff453d9347180ec7e2e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre85e3a54ce88f2ff453d9347180ec7e2e"><code onmouseover="az=1" onmouseout="az=0">@startuml
class Class
object Object
json JSON {
   "fruit":"Apple",
   "size":"Large",
   "color": ["Red", "Green"]
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="179" height="233" src="https://plantuml.com/imgw/img-85e3a54ce88f2ff453d9347180ec7e2e.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-15481](https://forum.plantuml.net/15481/possible-link-elements-from-two-jsons-with-both-jsons-embeded?show=15567#c15567)\]_

For another example, see on [JSON page](https://plantuml.com/en/json#jinnkhaa7d65l0fkhfec).
