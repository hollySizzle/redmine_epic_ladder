---
created: 2025-07-15T23:31:14 (UTC +09:00)
tags: []
source: https://plantuml.com/en/use-case-diagram
author: 
---

# Use case Diagram syntax and features

> ## Excerpt
> PlantUML use case diagram syntax: You can have use cases, actors, extensions, notes, stereotypes, arrows... Changing fonts and colors is also possible.

---
## Use Case Diagram

**A use case diagram** is a visual representation used in software engineering to depict the interactions between **system actors** and the **system itself**. It captures the dynamic behavior of a system by illustrating its **use cases** and the roles that interact with them. These diagrams are essential in specifying the system's **functional requirements** and understanding how users will interact with the system. By providing a high-level view, use case diagrams help stakeholders understand the system's functionality and its potential value.

**PlantUML** offers a unique approach to creating use case diagrams through its text-based language. One of the primary advantages of using PlantUML is its **simplicity and efficiency**. Instead of manually drawing shapes and connections, users can define their diagrams using intuitive and concise textual descriptions. This not only speeds up the diagram creation process but also ensures **consistency and accuracy**. The ability to integrate with various documentation platforms and its wide range of supported output formats make PlantUML a versatile tool for both developers and non-developers. Lastly, being **open-source**, PlantUML boasts a [strong community](https://forum.plantuml.net/) that continually contributes to its improvement and offers a wealth of resources for users at all levels.

## ![](https://plantuml.com/backtop1.svg "Back to top")Usecases

Use cases are enclosed using between parentheses (because two parentheses looks like an oval).

You can also use the `usecase` keyword to define a usecase. And you can define an alias, using the `as` keyword. This alias will be used later, when defining relations.

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="imgfcc37cf3989af3bcbf76bd40d69a04bd" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('fcc37cf3989af3bcbf76bd40d69a04bd')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('fcc37cf3989af3bcbf76bd40d69a04bd')"></td><td><div onclick="javascript:ljs('fcc37cf3989af3bcbf76bd40d69a04bd')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prefcc37cf3989af3bcbf76bd40d69a04bd"><code onmouseover="az=1" onmouseout="az=0">@startuml

(First usecase)
(Another usecase) as (UC2)
usecase UC3
usecase (Last\nusecase) as UC4

@enduml
</code></pre><p></p><p><img loading="lazy" width="313" height="155" src="https://plantuml.com/imgw/img-fcc37cf3989af3bcbf76bd40d69a04bd.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Actors

The name defining an actor is enclosed between colons.

You can also use the `actor` keyword to define an actor. An alias can be assigned using the `as` keyword and can be used later instead of the actor's name, e. g. when defining relations.

You can see from the following examples, that the actor definitions are optional.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img1d68a2282b4c2e19e2e6c9fbea6fd667" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('1d68a2282b4c2e19e2e6c9fbea6fd667')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('1d68a2282b4c2e19e2e6c9fbea6fd667')"></td><td><div onclick="javascript:ljs('1d68a2282b4c2e19e2e6c9fbea6fd667')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre1d68a2282b4c2e19e2e6c9fbea6fd667"><code onmouseover="az=1" onmouseout="az=0">@startuml

:First Actor:
:Another\nactor: as Man2
actor Woman3
actor :Last actor: as Person1

@enduml
</code></pre><p></p><p><img loading="lazy" width="168" height="242" src="https://plantuml.com/imgw/img-1d68a2282b4c2e19e2e6c9fbea6fd667.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Change Actor style

You can change the actor style from stick man _(by default)_ to:

-   an awesome man with the `skinparam actorStyle awesome` command;
-   a hollow man with the `skinparam actorStyle hollow` command.

### Stick man _(by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc79206975fcf446e2be2c64f8d30c95a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c79206975fcf446e2be2c64f8d30c95a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c79206975fcf446e2be2c64f8d30c95a')"></td><td><div onclick="javascript:ljs('c79206975fcf446e2be2c64f8d30c95a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec79206975fcf446e2be2c64f8d30c95a"><code onmouseover="az=1" onmouseout="az=0">@startuml
:User: --&gt; (Use)
"Main Admin" as Admin
"Use the application" as (Use)
Admin --&gt; (Admin the application)
@enduml
</code></pre><p></p><p><img loading="lazy" width="366" height="186" src="https://plantuml.com/imgw/img-c79206975fcf446e2be2c64f8d30c95a.png"></p></div></td></tr></tbody></table>

### Awesome man

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgcedaf3ee61fd3e5681ec6fb2eb79f4ea" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('cedaf3ee61fd3e5681ec6fb2eb79f4ea')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('cedaf3ee61fd3e5681ec6fb2eb79f4ea')"></td><td><div onclick="javascript:ljs('cedaf3ee61fd3e5681ec6fb2eb79f4ea')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="precedaf3ee61fd3e5681ec6fb2eb79f4ea"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam actorStyle awesome
:User: --&gt; (Use)
"Main Admin" as Admin
"Use the application" as (Use)
Admin --&gt; (Admin the application)
@enduml
</code></pre><p></p><p><img loading="lazy" width="366" height="187" src="https://plantuml.com/imgw/img-cedaf3ee61fd3e5681ec6fb2eb79f4ea.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-10493](https://forum.plantuml.net/10493/how-can-i-customize-the-actor-icon-in-svg-output?show=10513#c10513)\]_

### Hollow man

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3220a0eaeff44cfb5d933b6165e8031e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3220a0eaeff44cfb5d933b6165e8031e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3220a0eaeff44cfb5d933b6165e8031e')"></td><td><div onclick="javascript:ljs('3220a0eaeff44cfb5d933b6165e8031e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3220a0eaeff44cfb5d933b6165e8031e"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam actorStyle Hollow 
:User: --&gt; (Use)
"Main Admin" as Admin
"Use the application" as (Use)
Admin --&gt; (Admin the application)
@enduml
</code></pre><p></p><p><img loading="lazy" width="366" height="159" src="https://plantuml.com/imgw/img-3220a0eaeff44cfb5d933b6165e8031e.png"></p></div></td></tr></tbody></table>

_\[Ref. [PR#396](https://github.com/plantuml/plantuml/pull/396)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Usecases description

If you want to have a description spanning several lines, you can use quotes.

You can also use the following separators:

-   `--` (dashes)
-   `..` (periods)
-   `==` (equals)
-   `__` (underscores)

By using them pairwise and enclosing text between them, you can created separators with titles.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img2acae5a0c63cebc7360e4869befd4bf2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('2acae5a0c63cebc7360e4869befd4bf2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('2acae5a0c63cebc7360e4869befd4bf2')"></td><td><div onclick="javascript:ljs('2acae5a0c63cebc7360e4869befd4bf2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre2acae5a0c63cebc7360e4869befd4bf2"><code onmouseover="az=1" onmouseout="az=0">@startuml

usecase UC1 as "You can use
several lines to define your usecase.
You can also use separators.
--
Several separators are possible.
==
And you can add titles:
..Conclusion..
This allows large description."

@enduml
</code></pre><p></p><p><img loading="lazy" width="315" height="209" src="https://plantuml.com/imgw/img-2acae5a0c63cebc7360e4869befd4bf2.png"></p></div></td></tr></tbody></table>

**Please note** that the alias and the description are switched around from the basic example:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdbdf3d131ecb65cc1e701de904ed7706" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('dbdf3d131ecb65cc1e701de904ed7706')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('dbdf3d131ecb65cc1e701de904ed7706')"></td><td><div onclick="javascript:ljs('dbdf3d131ecb65cc1e701de904ed7706')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predbdf3d131ecb65cc1e701de904ed7706"><code onmouseover="az=1" onmouseout="az=0">@startuml
usecase description1 as alias1
usecase alias2 as "description2"
@enduml
</code></pre><p></p><p><img loading="lazy" width="271" height="41" src="https://plantuml.com/imgw/img-dbdf3d131ecb65cc1e701de904ed7706.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Use package

You can use packages to group actors or use cases.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img1d6ece76f78b225f2bf1c50b2ace4a0c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('1d6ece76f78b225f2bf1c50b2ace4a0c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('1d6ece76f78b225f2bf1c50b2ace4a0c')"></td><td><div onclick="javascript:ljs('1d6ece76f78b225f2bf1c50b2ace4a0c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre1d6ece76f78b225f2bf1c50b2ace4a0c"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
actor Guest as g
package Professional {
  actor Chef as c
  actor "Food Critic" as fc
}
package Restaurant {
  usecase "Eat Food" as UC1
  usecase "Pay for Food" as UC2
  usecase "Drink" as UC3
  usecase "Review" as UC4
}
fc --&gt; UC4
g --&gt; UC1
g --&gt; UC2
g --&gt; UC3
@enduml
</code></pre><p></p><p><img loading="lazy" width="291" height="395" src="https://plantuml.com/imgw/img-1d6ece76f78b225f2bf1c50b2ace4a0c.png"></p></div></td></tr></tbody></table>

You can use `rectangle` to change the display of the package.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img418e0b79d656b97ec09ed81fa28a9141" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('418e0b79d656b97ec09ed81fa28a9141')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('418e0b79d656b97ec09ed81fa28a9141')"></td><td><div onclick="javascript:ljs('418e0b79d656b97ec09ed81fa28a9141')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre418e0b79d656b97ec09ed81fa28a9141"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
actor "Food Critic" as fc
rectangle Restaurant {
  usecase "Eat Food" as UC1
  usecase "Pay for Food" as UC2
  usecase "Drink" as UC3
}
fc --&gt; UC1
fc --&gt; UC2
fc --&gt; UC3
@enduml
</code></pre><p></p><p><img loading="lazy" width="274" height="228" src="https://plantuml.com/imgw/img-418e0b79d656b97ec09ed81fa28a9141.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Basic example

To link actors and use cases, the arrow `-->` is used.

The more dashes `-` in the arrow, the longer the arrow. You can add a label on the arrow, by adding a `:` character in the arrow definition.

In this example, you see that _User_ has not been defined before, and is used as an actor.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb5639c159756380970f9a925aecb688d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b5639c159756380970f9a925aecb688d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b5639c159756380970f9a925aecb688d')"></td><td><div onclick="javascript:ljs('b5639c159756380970f9a925aecb688d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb5639c159756380970f9a925aecb688d"><code onmouseover="az=1" onmouseout="az=0">@startuml

User -&gt; (Start)
User --&gt; (Use the application) : A small label

:Main Admin: ---&gt; (Use the application) : This is\nyet another\nlabel

@enduml
</code></pre><p></p><p><img loading="lazy" width="265" height="341" src="https://plantuml.com/imgw/img-b5639c159756380970f9a925aecb688d.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Extension

If one actor/use case extends another one, you can use the symbol `<|--`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga22d148656154c1179ba29cd676bb31e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a22d148656154c1179ba29cd676bb31e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a22d148656154c1179ba29cd676bb31e')"></td><td><div onclick="javascript:ljs('a22d148656154c1179ba29cd676bb31e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea22d148656154c1179ba29cd676bb31e"><code onmouseover="az=1" onmouseout="az=0">@startuml
:Main Admin: as Admin
(Use the application) as (Use)

User &lt;|-- Admin
(Start) &lt;|-- (Use)

@enduml
</code></pre><p></p><p><img loading="lazy" width="274" height="225" src="https://plantuml.com/imgw/img-a22d148656154c1179ba29cd676bb31e.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Using notes

You can use the `note left of` , `note right of` , `note top of` , `note bottom of` keywords to define notes related to a single object.

A note can be also define alone with the `note` keywords, then linked to other objects using the `..` symbol.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbb68b9c118907f1cd4e78bab38119933" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('bb68b9c118907f1cd4e78bab38119933')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('bb68b9c118907f1cd4e78bab38119933')"></td><td><div onclick="javascript:ljs('bb68b9c118907f1cd4e78bab38119933')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebb68b9c118907f1cd4e78bab38119933"><code onmouseover="az=1" onmouseout="az=0">@startuml
:Main Admin: as Admin
(Use the application) as (Use)

User -&gt; (Start)
User --&gt; (Use)

Admin ---&gt; (Use)

note right of Admin : This is an example.

note right of (Use)
  A note can also
  be on several lines
end note

note "This note is connected\nto several objects." as N2
(Start) .. N2
N2 .. (Use)
@enduml
</code></pre><p></p><p><img loading="lazy" width="476" height="295" src="https://plantuml.com/imgw/img-bb68b9c118907f1cd4e78bab38119933.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Stereotypes

You can add stereotypes while defining actors and use cases using `<<` and `>>`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img010a632596bedeb84052999a9fd26cb5" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('010a632596bedeb84052999a9fd26cb5')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('010a632596bedeb84052999a9fd26cb5')"></td><td><div onclick="javascript:ljs('010a632596bedeb84052999a9fd26cb5')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre010a632596bedeb84052999a9fd26cb5"><code onmouseover="az=1" onmouseout="az=0">@startuml
User &lt;&lt; Human &gt;&gt;
:Main Database: as MySql &lt;&lt; Application &gt;&gt;
(Start) &lt;&lt; One Shot &gt;&gt;
(Use the application) as (Use) &lt;&lt; Main &gt;&gt;

User -&gt; (Start)
User --&gt; (Use)

MySql --&gt; (Use)

@enduml
</code></pre><p></p><p><img loading="lazy" width="342" height="218" src="https://plantuml.com/imgw/img-010a632596bedeb84052999a9fd26cb5.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Changing arrows direction

By default, links between classes have two dashes `--` and are vertically oriented. It is possible to use horizontal link by putting a single dash (or dot) like this:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb3795224bc74642d3d1163057377a160" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b3795224bc74642d3d1163057377a160')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b3795224bc74642d3d1163057377a160')"></td><td><div onclick="javascript:ljs('b3795224bc74642d3d1163057377a160')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb3795224bc74642d3d1163057377a160"><code onmouseover="az=1" onmouseout="az=0">@startuml
:user: --&gt; (Use case 1)
:user: -&gt; (Use case 2)
@enduml
</code></pre><p></p><p><img loading="lazy" width="217" height="179" src="https://plantuml.com/imgw/img-b3795224bc74642d3d1163057377a160.png"></p></div></td></tr></tbody></table>

You can also change directions by reversing the link:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img191432c39dc5beb3d5940a11948e27e6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('191432c39dc5beb3d5940a11948e27e6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('191432c39dc5beb3d5940a11948e27e6')"></td><td><div onclick="javascript:ljs('191432c39dc5beb3d5940a11948e27e6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre191432c39dc5beb3d5940a11948e27e6"><code onmouseover="az=1" onmouseout="az=0">@startuml
(Use case 1) &lt;.. :user:
(Use case 2) &lt;- :user:
@enduml
</code></pre><p></p><p><img loading="lazy" width="217" height="179" src="https://plantuml.com/imgw/img-191432c39dc5beb3d5940a11948e27e6.png"></p></div></td></tr></tbody></table>

It is also possible to change arrow direction by adding `left`, `right`, `up` or `down` keywords inside the arrow:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img13234c9da4cde14973321c5071c6f49f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('13234c9da4cde14973321c5071c6f49f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('13234c9da4cde14973321c5071c6f49f')"></td><td><div onclick="javascript:ljs('13234c9da4cde14973321c5071c6f49f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre13234c9da4cde14973321c5071c6f49f"><code onmouseover="az=1" onmouseout="az=0">@startuml
:user: -left-&gt; (dummyLeft)
:user: -right-&gt; (dummyRight)
:user: -up-&gt; (dummyUp)
:user: -down-&gt; (dummyDown)
@enduml
</code></pre><p></p><p><img loading="lazy" width="329" height="270" src="https://plantuml.com/imgw/img-13234c9da4cde14973321c5071c6f49f.png"></p></div></td></tr></tbody></table>

You can shorten the arrow by using only the first character of the direction (for example, `-d-` instead of `-down-`) or the two first characters (`-do-`).

Please note that you should not abuse this functionality : _Graphviz_ gives usually good results without tweaking.

And with the [`left to right direction`](https://plantuml.com/en/use-case-diagram#d551e48d272b2b07) parameter:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf4b9764d2b9fafb6a0a70cdb3fcd0c76" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f4b9764d2b9fafb6a0a70cdb3fcd0c76')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f4b9764d2b9fafb6a0a70cdb3fcd0c76')"></td><td><div onclick="javascript:ljs('f4b9764d2b9fafb6a0a70cdb3fcd0c76')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref4b9764d2b9fafb6a0a70cdb3fcd0c76"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
:user: -left-&gt; (dummyLeft)
:user: -right-&gt; (dummyRight)
:user: -up-&gt; (dummyUp)
:user: -down-&gt; (dummyDown)
@enduml
</code></pre><p></p><p><img loading="lazy" width="465" height="221" src="https://plantuml.com/imgw/img-f4b9764d2b9fafb6a0a70cdb3fcd0c76.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Splitting diagrams

The `newpage` keywords to split your diagram into several pages or images.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9445fef1f20465f5828460aa62df6317" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9445fef1f20465f5828460aa62df6317')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9445fef1f20465f5828460aa62df6317')"></td><td><div onclick="javascript:ljs('9445fef1f20465f5828460aa62df6317')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9445fef1f20465f5828460aa62df6317"><code onmouseover="az=1" onmouseout="az=0">@startuml
:actor1: --&gt; (Usecase1)
newpage
:actor2: --&gt; (Usecase2)
@enduml
</code></pre><p></p><p><img loading="lazy" width="105" height="179" src="https://plantuml.com/imgw/img-9445fef1f20465f5828460aa62df6317.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Left to right direction

The general default behavior when building diagram is **top to bottom**.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdcba255751e75be0e6d94c4992f2f309" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('dcba255751e75be0e6d94c4992f2f309')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('dcba255751e75be0e6d94c4992f2f309')"></td><td><div onclick="javascript:ljs('dcba255751e75be0e6d94c4992f2f309')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predcba255751e75be0e6d94c4992f2f309"><code onmouseover="az=1" onmouseout="az=0">@startuml
'default
top to bottom direction
user1 --&gt; (Usecase 1)
user2 --&gt; (Usecase 2)

@enduml
</code></pre><p></p><p><img loading="lazy" width="245" height="179" src="https://plantuml.com/imgw/img-dcba255751e75be0e6d94c4992f2f309.png"></p></div></td></tr></tbody></table>

You may change to **left to right** using the `left to right direction` command. The result is often better with this direction.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img42016259f7d9dea0d0170f3c17b4de92" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('42016259f7d9dea0d0170f3c17b4de92')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('42016259f7d9dea0d0170f3c17b4de92')"></td><td><div onclick="javascript:ljs('42016259f7d9dea0d0170f3c17b4de92')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre42016259f7d9dea0d0170f3c17b4de92"><code onmouseover="az=1" onmouseout="az=0">@startuml

left to right direction
user1 --&gt; (Usecase 1)
user2 --&gt; (Usecase 2)

@enduml
</code></pre><p></p><p><img loading="lazy" width="205" height="200" src="https://plantuml.com/imgw/img-42016259f7d9dea0d0170f3c17b4de92.png"></p></div></td></tr></tbody></table>

_See also 'Change diagram orientation' on [Deployment diagram](https://plantuml.com/en/deployment-diagram) page._

## ![](https://plantuml.com/backtop1.svg "Back to top")Skinparam

You can use the [skinparam](https://plantuml.com/en/skinparam) command to change colors and fonts for the drawing.

You can use this command :

-   In the diagram definition, like any other commands,
-   In an [included file](https://plantuml.com/en/preprocessing),
-   In a configuration file, provided in [the command line](https://plantuml.com/en/command-line) or [the ANT task](https://plantuml.com/en/ant-task).

You can define specific color and fonts for stereotyped actors and usecases.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgfc717d6447bd725f09609f2418eeca4c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('fc717d6447bd725f09609f2418eeca4c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('fc717d6447bd725f09609f2418eeca4c')"></td><td><div onclick="javascript:ljs('fc717d6447bd725f09609f2418eeca4c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prefc717d6447bd725f09609f2418eeca4c"><code onmouseover="az=1" onmouseout="az=0">@startuml
!option handwritten true

skinparam usecase {
BackgroundColor DarkSeaGreen
BorderColor DarkSlateGray

BackgroundColor&lt;&lt; Main &gt;&gt; YellowGreen
BorderColor&lt;&lt; Main &gt;&gt; YellowGreen

ArrowColor Olive
ActorBorderColor black
ActorFontName Courier

ActorBackgroundColor&lt;&lt; Human &gt;&gt; Gold
}

User &lt;&lt; Human &gt;&gt;
:Main Database: as MySql &lt;&lt; Application &gt;&gt;
(Start) &lt;&lt; One Shot &gt;&gt;
(Use the application) as (Use) &lt;&lt; Main &gt;&gt;

User -&gt; (Start)
User --&gt; (Use)

MySql --&gt; (Use)

@enduml
</code></pre><p></p><p><img loading="lazy" width="342" height="218" src="https://plantuml.com/imgw/img-fc717d6447bd725f09609f2418eeca4c.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Complete example

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img683ba180fe7a948513c0742c7ab73dfa" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('683ba180fe7a948513c0742c7ab73dfa')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('683ba180fe7a948513c0742c7ab73dfa')"></td><td><div onclick="javascript:ljs('683ba180fe7a948513c0742c7ab73dfa')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre683ba180fe7a948513c0742c7ab73dfa"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
skinparam packageStyle rectangle
actor customer
actor clerk
rectangle checkout {
  customer -- (checkout)
  (checkout) .&gt; (payment) : include
  (help) .&gt; (checkout) : extends
  (checkout) -- clerk
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="381" height="244" src="https://plantuml.com/imgw/img-683ba180fe7a948513c0742c7ab73dfa.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Business Use Case

You can add `/` to make Business Use Case.

### Business Usecase

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge78df63d1f5cbe8853e85584f48ede7b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e78df63d1f5cbe8853e85584f48ede7b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e78df63d1f5cbe8853e85584f48ede7b')"></td><td><div onclick="javascript:ljs('e78df63d1f5cbe8853e85584f48ede7b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree78df63d1f5cbe8853e85584f48ede7b"><code onmouseover="az=1" onmouseout="az=0">@startuml

(First usecase)/
(Another usecase)/ as (UC2)
usecase/ UC3
usecase/ (Last\nusecase) as UC4

@enduml
</code></pre><p></p><p><img loading="lazy" width="338" height="162" src="https://plantuml.com/imgw/img-e78df63d1f5cbe8853e85584f48ede7b.png"></p></div></td></tr></tbody></table>

### Business Actor

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3cb4ec1e7a542b5cba9009cf25ab3778" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3cb4ec1e7a542b5cba9009cf25ab3778')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3cb4ec1e7a542b5cba9009cf25ab3778')"></td><td><div onclick="javascript:ljs('3cb4ec1e7a542b5cba9009cf25ab3778')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3cb4ec1e7a542b5cba9009cf25ab3778"><code onmouseover="az=1" onmouseout="az=0">@startuml

:First Actor:/
:Another\nactor:/ as Man2
actor/ Woman3
actor/ :Last actor: as Person1

@enduml
</code></pre><p></p><p><img loading="lazy" width="168" height="242" src="https://plantuml.com/imgw/img-3cb4ec1e7a542b5cba9009cf25ab3778.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-12179](https://forum.plantuml.net/12179/)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Change arrow color and style (inline style)

You can change the [color](https://plantuml.com/en/color) or style of individual arrows using the inline following notation:

-   `#color;line.[bold|dashed|dotted];text:color`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img29b2b5463dc0eb9451d96f28f70f0f36" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('29b2b5463dc0eb9451d96f28f70f0f36')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('29b2b5463dc0eb9451d96f28f70f0f36')"></td><td><div onclick="javascript:ljs('29b2b5463dc0eb9451d96f28f70f0f36')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre29b2b5463dc0eb9451d96f28f70f0f36"><code onmouseover="az=1" onmouseout="az=0">@startuml
actor foo
foo --&gt; (bar) : normal
foo --&gt; (bar1) #line:red;line.bold;text:red  : red bold
foo --&gt; (bar2) #green;line.dashed;text:green : green dashed 
foo --&gt; (bar3) #blue;line.dotted;text:blue   : blue dotted
@enduml
</code></pre><p></p><p><img loading="lazy" width="354" height="197" src="https://plantuml.com/imgw/img-29b2b5463dc0eb9451d96f28f70f0f36.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-3770](https://forum.plantuml.net/3770) and [QA-3816](https://forum.plantuml.net/3816)\]_ _\[See similar feature on [deployment-diagram](https://plantuml.com/en/deployment-diagram#qjxu5xkj874qkedanfcf) or [class diagram](https://plantuml.com/en/class-diagram#b5b0e4228f2e5022)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Change element color and style (inline style)

You can change the [color](https://plantuml.com/en/color) or style of individual element using the following notation:

-   `#[color|back:color];line:color;line.[bold|dashed|dotted];text:color`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img26361c146db384f4eecfc2d92e0885f9" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('26361c146db384f4eecfc2d92e0885f9')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('26361c146db384f4eecfc2d92e0885f9')"></td><td><div onclick="javascript:ljs('26361c146db384f4eecfc2d92e0885f9')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre26361c146db384f4eecfc2d92e0885f9"><code onmouseover="az=1" onmouseout="az=0">@startuml
actor a
actor b #pink;line:red;line.bold;text:red
usecase c #palegreen;line:green;line.dashed;text:green
usecase d #aliceblue;line:blue;line.dotted;text:blue
@enduml
</code></pre><p></p><p><img loading="lazy" width="104" height="174" src="https://plantuml.com/imgw/img-26361c146db384f4eecfc2d92e0885f9.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-5340](https://forum.plantuml.net/5340) and adapted from [QA-6852](https://forum.plantuml.net/6852)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Display JSON Data on Usecase diagram

### Simple example

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge83e6fc4afdfc22e3629ad20eb0e6a1f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e83e6fc4afdfc22e3629ad20eb0e6a1f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e83e6fc4afdfc22e3629ad20eb0e6a1f')"></td><td><div onclick="javascript:ljs('e83e6fc4afdfc22e3629ad20eb0e6a1f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree83e6fc4afdfc22e3629ad20eb0e6a1f"><code onmouseover="az=1" onmouseout="az=0">@startuml
allowmixing

actor     Actor
usecase   Usecase

json JSON {
   "fruit":"Apple",
   "size":"Large",
   "color": ["Red", "Green"]
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="191" height="261" src="https://plantuml.com/imgw/img-e83e6fc4afdfc22e3629ad20eb0e6a1f.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-15481](https://forum.plantuml.net/15481/possible-link-elements-from-two-jsons-with-both-jsons-embeded?show=15567#c15567)\]_

For another example, see on [JSON page](https://plantuml.com/en/json#2fyxla9p9ob6l3t3tjre).
