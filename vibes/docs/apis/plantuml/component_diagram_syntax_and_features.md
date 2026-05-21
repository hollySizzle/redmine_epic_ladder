---
created: 2025-07-15T23:31:14 (UTC +09:00)
tags: []
source: https://plantuml.com/en/component-diagram
author: 
---

# Component Diagram syntax and features

> ## Excerpt
> PlantUML component diagram syntax: You can define interfaces, components, relationships, groups, notes...  Changing fonts and colors is also possible.

---
## Component Diagram

**Component Diagram**: A component diagram is a type of structural diagram used in UML (Unified Modeling Language) to visualize the organization and relationships of system components. These diagrams help in breaking down complex systems into manageable components, showcasing their interdependencies, and ensuring efficient system design and architecture.

**Advantages of PlantUML**:

-   **Simplicity**: With PlantUML, you can create component diagrams using simple and intuitive text-based descriptions, eliminating the need for complex drawing tools.
-   **Integration**: PlantUML seamlessly integrates with various tools and platforms, making it a versatile choice for developers and architects.
-   **Collaboration**: The [PlantUML forum](https://forum.plantuml.net/) offers a platform for users to discuss, share, and seek assistance on their diagrams, fostering a collaborative community.

## ![](https://plantuml.com/backtop1.svg "Back to top")Components

Components must be bracketed.

You can also use the `component` keyword to define a component. In this case the brackets can be omitted, but only if the component name does not include white-space or special characters.

You can define an alias, using the `as` keyword. This alias will be used later, when defining relations.

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="imgf873ae2e36958fcf1d974c0bb402fb75" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f873ae2e36958fcf1d974c0bb402fb75')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f873ae2e36958fcf1d974c0bb402fb75')"></td><td><div onclick="javascript:ljs('f873ae2e36958fcf1d974c0bb402fb75')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref873ae2e36958fcf1d974c0bb402fb75"><code onmouseover="az=1" onmouseout="az=0">@startuml

[First component]
[Another component] as Comp2
component Comp3
component [Last\ncomponent] as Comp4

@enduml
</code></pre><p></p><p><img loading="lazy" width="349" height="185" src="https://plantuml.com/imgw/img-f873ae2e36958fcf1d974c0bb402fb75.png"></p></div></td></tr></tbody></table>

### Naming exceptions

Note that component names starting with `$` cannot be hidden or removed later, because `hide` and `remove` command will consider the name a `$tag` instead of a component name. To later remove such component they must have an alias or must be tagged.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img494baef39c192160497331bf67aa6717" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('494baef39c192160497331bf67aa6717')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('494baef39c192160497331bf67aa6717')"></td><td><div onclick="javascript:ljs('494baef39c192160497331bf67aa6717')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre494baef39c192160497331bf67aa6717"><code onmouseover="az=1" onmouseout="az=0">@startuml
component [$C1]
component [$C2] $C2
component [$C2] as dollarC2
remove $C1
remove $C2
remove dollarC2
@enduml
</code></pre><p></p><p><img loading="lazy" width="77" height="59" src="https://plantuml.com/imgw/img-494baef39c192160497331bf67aa6717.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Interfaces

Interface can be defined using the `()` symbol (because this looks like a circle).

You can also use the `interface` keyword to define an interface. And you can define an alias, using the `as` keyword. This alias will be used latter, when defining relations.

We will see latter that interface definition is optional.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img20e3e2e06f48ad61a6698a2dedc89b40" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('20e3e2e06f48ad61a6698a2dedc89b40')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('20e3e2e06f48ad61a6698a2dedc89b40')"></td><td><div onclick="javascript:ljs('20e3e2e06f48ad61a6698a2dedc89b40')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre20e3e2e06f48ad61a6698a2dedc89b40"><code onmouseover="az=1" onmouseout="az=0">@startuml

() "First Interface"
() "Another interface" as Interf2
interface Interf3
interface "Last\ninterface" as Interf4

[component]
footer //Adding "component" to force diagram to be a **component diagram**//
@enduml
</code></pre><p></p><p><img loading="lazy" width="343" height="228" src="https://plantuml.com/imgw/img-20e3e2e06f48ad61a6698a2dedc89b40.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Basic example

Links between elements are made using combinations of dotted line (`..`), straight line (`--`), and arrows (`-->`) symbols.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb3f2c6f5b39a5d0e9a054caaed8c2416" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b3f2c6f5b39a5d0e9a054caaed8c2416')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b3f2c6f5b39a5d0e9a054caaed8c2416')"></td><td><div onclick="javascript:ljs('b3f2c6f5b39a5d0e9a054caaed8c2416')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb3f2c6f5b39a5d0e9a054caaed8c2416"><code onmouseover="az=1" onmouseout="az=0">@startuml

DataAccess - [First Component]
[First Component] ..&gt; HTTP : use

@enduml
</code></pre><p></p><p><img loading="lazy" width="236" height="202" src="https://plantuml.com/imgw/img-b3f2c6f5b39a5d0e9a054caaed8c2416.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Using notes

You can use the `note left of` , `note right of` , `note top of` , `note bottom of` keywords to define notes related to a single object.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgcaed6668cb6d5a41166bce7134786a48" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('caed6668cb6d5a41166bce7134786a48')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('caed6668cb6d5a41166bce7134786a48')"></td><td><div onclick="javascript:ljs('caed6668cb6d5a41166bce7134786a48')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="precaed6668cb6d5a41166bce7134786a48"><code onmouseover="az=1" onmouseout="az=0">@startuml
[Component] as C

note top of C: A top note

note bottom of C
  A bottom note can also
  be on several lines
end note

note left of C
  A left note can also
  be on several lines
end note

note right of C: A right note
@enduml
</code></pre><p></p><p><img loading="lazy" width="413" height="248" src="https://plantuml.com/imgw/img-caed6668cb6d5a41166bce7134786a48.png"></p></div></td></tr></tbody></table>

A note can be also defined alone with the `note` keywords, then linked to other objects using the `..` symbol or whatever arrow symbol (`-`, `--`, ...).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img975827513a3b15ceb9c44c988a74afe2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('975827513a3b15ceb9c44c988a74afe2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('975827513a3b15ceb9c44c988a74afe2')"></td><td><div onclick="javascript:ljs('975827513a3b15ceb9c44c988a74afe2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre975827513a3b15ceb9c44c988a74afe2"><code onmouseover="az=1" onmouseout="az=0">@startuml
[Component] as C

note as N
  A floating note can also
  be on several lines
end note

C .. N
@enduml
</code></pre><p></p><p><img loading="lazy" width="168" height="163" src="https://plantuml.com/imgw/img-975827513a3b15ceb9c44c988a74afe2.png"></p></div></td></tr></tbody></table>

Another note example:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img8067c2e62a3893e1c47565c54b8d0c36" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('8067c2e62a3893e1c47565c54b8d0c36')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('8067c2e62a3893e1c47565c54b8d0c36')"></td><td><div onclick="javascript:ljs('8067c2e62a3893e1c47565c54b8d0c36')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre8067c2e62a3893e1c47565c54b8d0c36"><code onmouseover="az=1" onmouseout="az=0">@startuml

interface "Data Access" as DA

DA - [First Component]
[First Component] ..&gt; HTTP : use

note left of HTTP : Web Service only

note right of [First Component]
  A note can also
  be on several lines
end note

@enduml
</code></pre><p></p><p><img loading="lazy" width="413" height="185" src="https://plantuml.com/imgw/img-8067c2e62a3893e1c47565c54b8d0c36.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Grouping Components

You can use several keywords to group components and interfaces together:

-   `package`
-   `node`
-   `folder`
-   `frame`
-   `cloud`
-   `database`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd445d9ebff789542af6a6dbdbceac754" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d445d9ebff789542af6a6dbdbceac754')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d445d9ebff789542af6a6dbdbceac754')"></td><td><div onclick="javascript:ljs('d445d9ebff789542af6a6dbdbceac754')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred445d9ebff789542af6a6dbdbceac754"><code onmouseover="az=1" onmouseout="az=0">@startuml

package "Some Group" {
  HTTP - [First Component]
  [Another Component]
}

node "Other Groups" {
  FTP - [Second Component]
  [First Component] --&gt; FTP
}

cloud {
  [Example 1]
}


database "MySql" {
  folder "This is my folder" {
    [Folder 3]
  }
  frame "Foo" {
    [Frame 4]
  }
}


[Another Component] --&gt; [Example 1]
[Example 1] --&gt; [Folder 3]
[Folder 3] --&gt; [Frame 4]

@enduml
</code></pre><p></p><p><img loading="lazy" width="483" height="582" src="https://plantuml.com/imgw/img-d445d9ebff789542af6a6dbdbceac754.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Changing arrows direction

By default, links between classes have two dashes `--` and are vertically oriented. It is possible to use horizontal link by putting a single dash (or dot) like this:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img615a0a05bb5fb65eeefc003ee83fa874" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('615a0a05bb5fb65eeefc003ee83fa874')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('615a0a05bb5fb65eeefc003ee83fa874')"></td><td><div onclick="javascript:ljs('615a0a05bb5fb65eeefc003ee83fa874')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre615a0a05bb5fb65eeefc003ee83fa874"><code onmouseover="az=1" onmouseout="az=0">@startuml
[Component] --&gt; Interface1
[Component] -&gt; Interface2
@enduml
</code></pre><p></p><p><img loading="lazy" width="200" height="184" src="https://plantuml.com/imgw/img-615a0a05bb5fb65eeefc003ee83fa874.png"></p></div></td></tr></tbody></table>

You can also change directions by reversing the link:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf9ea3e9619cbadabc1ec910b36bb918c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f9ea3e9619cbadabc1ec910b36bb918c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f9ea3e9619cbadabc1ec910b36bb918c')"></td><td><div onclick="javascript:ljs('f9ea3e9619cbadabc1ec910b36bb918c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref9ea3e9619cbadabc1ec910b36bb918c"><code onmouseover="az=1" onmouseout="az=0">@startuml
Interface1 &lt;-- [Component]
Interface2 &lt;- [Component]
@enduml
</code></pre><p></p><p><img loading="lazy" width="198" height="167" src="https://plantuml.com/imgw/img-f9ea3e9619cbadabc1ec910b36bb918c.png"></p></div></td></tr></tbody></table>

It is also possible to change arrow direction by adding `left`, `right`, `up` or `down` keywords inside the arrow:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf94df2be8f24e7ffe7ddebf8fef25326" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f94df2be8f24e7ffe7ddebf8fef25326')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f94df2be8f24e7ffe7ddebf8fef25326')"></td><td><div onclick="javascript:ljs('f94df2be8f24e7ffe7ddebf8fef25326')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref94df2be8f24e7ffe7ddebf8fef25326"><code onmouseover="az=1" onmouseout="az=0">@startuml
[Component] -left-&gt; left
[Component] -right-&gt; right
[Component] -up-&gt; up
[Component] -down-&gt; down
@enduml
</code></pre><p></p><p><img loading="lazy" width="234" height="281" src="https://plantuml.com/imgw/img-f94df2be8f24e7ffe7ddebf8fef25326.png"></p></div></td></tr></tbody></table>

You can shorten the arrow by using only the first character of the direction (for example, `-d-` instead of `-down-`) or the two first characters (`-do-`).

Please note that you should not abuse this functionality : _Graphviz_ gives usually good results without tweaking.

And with the [`left to right direction`](https://plantuml.com/en/use-case-diagram#d551e48d272b2b07) parameter:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgee1d27988617c163b5f69f7ea8401bfa" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ee1d27988617c163b5f69f7ea8401bfa')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ee1d27988617c163b5f69f7ea8401bfa')"></td><td><div onclick="javascript:ljs('ee1d27988617c163b5f69f7ea8401bfa')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preee1d27988617c163b5f69f7ea8401bfa"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
[Component] -left-&gt; left
[Component] -right-&gt; right
[Component] -up-&gt; up
[Component] -down-&gt; down
@enduml
</code></pre><p></p><p><img loading="lazy" width="322" height="189" src="https://plantuml.com/imgw/img-ee1d27988617c163b5f69f7ea8401bfa.png"></p></div></td></tr></tbody></table>

_See also 'Change diagram orientation' on [Deployment diagram](https://plantuml.com/en/deployment-diagram) page._

## ![](https://plantuml.com/backtop1.svg "Back to top")Use UML2 notation

By default _(from v1.2020.13-14)_, UML2 notation is used.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img99404483e85bd70749154e97b4255112" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('99404483e85bd70749154e97b4255112')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('99404483e85bd70749154e97b4255112')"></td><td><div onclick="javascript:ljs('99404483e85bd70749154e97b4255112')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre99404483e85bd70749154e97b4255112"><code onmouseover="az=1" onmouseout="az=0">@startuml

interface "Data Access" as DA

DA - [First Component]
[First Component] ..&gt; HTTP : use

@enduml
</code></pre><p></p><p><img loading="lazy" width="238" height="202" src="https://plantuml.com/imgw/img-99404483e85bd70749154e97b4255112.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Use UML1 notation

The `skinparam componentStyle uml1` command is used to switch to UML1 notation.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img956ebe92f69ffb1164a0f232bb0d5e3c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('956ebe92f69ffb1164a0f232bb0d5e3c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('956ebe92f69ffb1164a0f232bb0d5e3c')"></td><td><div onclick="javascript:ljs('956ebe92f69ffb1164a0f232bb0d5e3c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre956ebe92f69ffb1164a0f232bb0d5e3c"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam componentStyle uml1

interface "Data Access" as DA

DA - [First Component]
[First Component] ..&gt; HTTP : use

@enduml
</code></pre><p></p><p><img loading="lazy" width="218" height="192" src="https://plantuml.com/imgw/img-956ebe92f69ffb1164a0f232bb0d5e3c.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Use rectangle notation (remove UML notation)

The `skinparam componentStyle rectangle` command is used to switch to rectangle notation _(without any UML notation)_.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3fdbfed52fbfebc744a248ca99200c1d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3fdbfed52fbfebc744a248ca99200c1d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3fdbfed52fbfebc744a248ca99200c1d')"></td><td><div onclick="javascript:ljs('3fdbfed52fbfebc744a248ca99200c1d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3fdbfed52fbfebc744a248ca99200c1d"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam componentStyle rectangle

interface "Data Access" as DA

DA - [First Component]
[First Component] ..&gt; HTTP : use

@enduml
</code></pre><p></p><p><img loading="lazy" width="218" height="192" src="https://plantuml.com/imgw/img-3fdbfed52fbfebc744a248ca99200c1d.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Long description

It is possible to put description on several lines using square brackets.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img79d38c136c917854b9c124308a1c736e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('79d38c136c917854b9c124308a1c736e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('79d38c136c917854b9c124308a1c736e')"></td><td><div onclick="javascript:ljs('79d38c136c917854b9c124308a1c736e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre79d38c136c917854b9c124308a1c736e"><code onmouseover="az=1" onmouseout="az=0">@startuml
component comp1 [
This component
has a long comment
on several lines
]
@enduml
</code></pre><p></p><p><img loading="lazy" width="186" height="102" src="https://plantuml.com/imgw/img-79d38c136c917854b9c124308a1c736e.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Individual colors

You can specify a color after component definition.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd0a78d68736f646f363522541b4684e6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d0a78d68736f646f363522541b4684e6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d0a78d68736f646f363522541b4684e6')"></td><td><div onclick="javascript:ljs('d0a78d68736f646f363522541b4684e6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred0a78d68736f646f363522541b4684e6"><code onmouseover="az=1" onmouseout="az=0">@startuml
component  [Web Server] #Yellow
@enduml
</code></pre><p></p><p><img loading="lazy" width="133" height="67" src="https://plantuml.com/imgw/img-d0a78d68736f646f363522541b4684e6.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Using Sprite in Stereotype

You can use sprites within stereotype components.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgcac62986bae70818e8dc3704ad7bf391" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('cac62986bae70818e8dc3704ad7bf391')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('cac62986bae70818e8dc3704ad7bf391')"></td><td><div onclick="javascript:ljs('cac62986bae70818e8dc3704ad7bf391')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="precac62986bae70818e8dc3704ad7bf391"><code onmouseover="az=1" onmouseout="az=0">@startuml
sprite $businessProcess [16x16/16] {
FFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFF
FFFFFFFFFF0FFFFF
FFFFFFFFFF00FFFF
FF00000000000FFF
FF000000000000FF
FF00000000000FFF
FFFFFFFFFF00FFFF
FFFFFFFFFF0FFFFF
FFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFF
}


rectangle " End to End\nbusiness process" &lt;&lt;$businessProcess&gt;&gt; {
 rectangle "inner process 1" &lt;&lt;$businessProcess&gt;&gt; as src
 rectangle "inner process 2" &lt;&lt;$businessProcess&gt;&gt; as tgt
 src -&gt; tgt
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="311" height="152" src="https://plantuml.com/imgw/img-cac62986bae70818e8dc3704ad7bf391.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Skinparam

You can use the [skinparam](https://plantuml.com/en/skinparam) command to change colors and fonts for the drawing.

You can use this command :

-   In the diagram definition, like any other commands;
-   In an [included file](https://plantuml.com/en/preprocessing);
-   In a configuration file, provided in the [command line](https://plantuml.com/en/command-line) or the [Ant task](https://plantuml.com/en/ant-task).

You can define specific color and fonts for stereotyped components and interfaces.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbba282c1429ea0d44a7a5008af64a128" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('bba282c1429ea0d44a7a5008af64a128')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('bba282c1429ea0d44a7a5008af64a128')"></td><td><div onclick="javascript:ljs('bba282c1429ea0d44a7a5008af64a128')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebba282c1429ea0d44a7a5008af64a128"><code onmouseover="az=1" onmouseout="az=0">@startuml

skinparam interface {
  backgroundColor RosyBrown
  borderColor orange
}

skinparam component {
  FontSize 13
  BackgroundColor&lt;&lt;Apache&gt;&gt; Pink
  BorderColor&lt;&lt;Apache&gt;&gt; #FF6655
  FontName Courier
  BorderColor black
  BackgroundColor gold
  ArrowFontName Impact
  ArrowColor #FF6655
  ArrowFontColor #777777
}

() "Data Access" as DA
Component "Web Server" as WS &lt;&lt; Apache &gt;&gt;

DA - [First Component]
[First Component] ..&gt; () HTTP : use
HTTP - WS

@enduml
</code></pre><p></p><p><img loading="lazy" width="335" height="202" src="https://plantuml.com/imgw/img-bba282c1429ea0d44a7a5008af64a128.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgeea4d877ebf8452f0dba7857f2043563" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('eea4d877ebf8452f0dba7857f2043563')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('eea4d877ebf8452f0dba7857f2043563')"></td><td><div onclick="javascript:ljs('eea4d877ebf8452f0dba7857f2043563')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preeea4d877ebf8452f0dba7857f2043563"><code onmouseover="az=1" onmouseout="az=0">@startuml

skinparam component {
  backgroundColor&lt;&lt;static lib&gt;&gt; DarkKhaki
  backgroundColor&lt;&lt;shared lib&gt;&gt; Green
}

skinparam node {
  borderColor Green
  backgroundColor Yellow
  backgroundColor&lt;&lt;shared_node&gt;&gt; Magenta
}
skinparam databaseBackgroundColor Aqua

[AA] &lt;&lt;static lib&gt;&gt;
[BB] &lt;&lt;shared lib&gt;&gt;
[CC] &lt;&lt;static lib&gt;&gt;

node node1
node node2 &lt;&lt;shared_node&gt;&gt;
database Production

@enduml
</code></pre><p></p><p><img loading="lazy" width="416" height="213" src="https://plantuml.com/imgw/img-eea4d877ebf8452f0dba7857f2043563.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Specific SkinParameter

### componentStyle

-   By default (or with `skinparam componentStyle uml2`), you have an icon for component

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img266ff8de06d03e479718867f5dbce2e1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('266ff8de06d03e479718867f5dbce2e1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('266ff8de06d03e479718867f5dbce2e1')"></td><td><div onclick="javascript:ljs('266ff8de06d03e479718867f5dbce2e1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre266ff8de06d03e479718867f5dbce2e1"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam BackgroundColor transparent
skinparam componentStyle uml2
component A {
   component "A.1" {
}
   component A.44 {
      [A4.1]
}
   component "A.2"
   [A.3]
   component A.5 [
A.5] 
   component A.6 [
]
}
[a]-&gt;[b]
@enduml
</code></pre><p></p><p><img loading="lazy" width="576" height="264" src="https://plantuml.com/imgw/img-266ff8de06d03e479718867f5dbce2e1.png"></p></div></td></tr></tbody></table>

-   If you want to suppress it, and to have only the rectangle, you can use `skinparam componentStyle rectangle`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga8ee3531a6c1668b0757fe185330d01e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a8ee3531a6c1668b0757fe185330d01e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a8ee3531a6c1668b0757fe185330d01e')"></td><td><div onclick="javascript:ljs('a8ee3531a6c1668b0757fe185330d01e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea8ee3531a6c1668b0757fe185330d01e"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam BackgroundColor transparent
skinparam componentStyle rectangle
component A {
   component "A.1" {
}
   component A.44 {
      [A4.1]
}
   component "A.2"
   [A.3]
   component A.5 [
A.5] 
   component A.6 [
]
}
[a]-&gt;[b]
@enduml
</code></pre><p></p><p><img loading="lazy" width="456" height="244" src="https://plantuml.com/imgw/img-a8ee3531a6c1668b0757fe185330d01e.png"></p></div></td></tr></tbody></table>

_\[Ref. [10798](https://forum.plantuml.net/10798)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Hide or Remove unlinked component

By default, all components are displayed:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc2fdc9c0107f4d43959a0b0f5a29d54d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c2fdc9c0107f4d43959a0b0f5a29d54d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c2fdc9c0107f4d43959a0b0f5a29d54d')"></td><td><div onclick="javascript:ljs('c2fdc9c0107f4d43959a0b0f5a29d54d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec2fdc9c0107f4d43959a0b0f5a29d54d"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C1
component C2
component C3
C1 -- C2
@enduml
</code></pre><p></p><p><img loading="lazy" width="162" height="167" src="https://plantuml.com/imgw/img-c2fdc9c0107f4d43959a0b0f5a29d54d.png"></p></div></td></tr></tbody></table>

But you can:

-   `hide @unlinked` components:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img18d633f078fc4daede45d7a6add14dc7" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('18d633f078fc4daede45d7a6add14dc7')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('18d633f078fc4daede45d7a6add14dc7')"></td><td><div onclick="javascript:ljs('18d633f078fc4daede45d7a6add14dc7')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre18d633f078fc4daede45d7a6add14dc7"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C1
component C2
component C3
C1 -- C2

hide @unlinked
@enduml
</code></pre><p></p><p><img loading="lazy" width="162" height="167" src="https://plantuml.com/imgw/img-18d633f078fc4daede45d7a6add14dc7.png"></p></div></td></tr></tbody></table>

-   or `remove @unlinked` components:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4d71c782ad24d332ff6d0e360255c03b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4d71c782ad24d332ff6d0e360255c03b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4d71c782ad24d332ff6d0e360255c03b')"></td><td><div onclick="javascript:ljs('4d71c782ad24d332ff6d0e360255c03b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4d71c782ad24d332ff6d0e360255c03b"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C1
component C2
component C3
C1 -- C2

remove @unlinked
@enduml
</code></pre><p></p><p><img loading="lazy" width="69" height="167" src="https://plantuml.com/imgw/img-4d71c782ad24d332ff6d0e360255c03b.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-11052](https://forum.plantuml.net/11052)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Hide, Remove or Restore tagged component or wildcard

You can put `$tags` (using `$`) on components, then remove, hide or restore components either individually or by tags.

By default, all components are displayed:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4257b2081aa18823ec7324b57c58bfe4" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4257b2081aa18823ec7324b57c58bfe4')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4257b2081aa18823ec7324b57c58bfe4')"></td><td><div onclick="javascript:ljs('4257b2081aa18823ec7324b57c58bfe4')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4257b2081aa18823ec7324b57c58bfe4"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C1 $tag13
component C2
component C3 $tag13
C1 -- C2
@enduml
</code></pre><p></p><p><img loading="lazy" width="162" height="167" src="https://plantuml.com/imgw/img-4257b2081aa18823ec7324b57c58bfe4.png"></p></div></td></tr></tbody></table>

But you can:

-   `hide $tag13` components:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf3c65d5949e01f1e6977795f60464b7d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f3c65d5949e01f1e6977795f60464b7d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f3c65d5949e01f1e6977795f60464b7d')"></td><td><div onclick="javascript:ljs('f3c65d5949e01f1e6977795f60464b7d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref3c65d5949e01f1e6977795f60464b7d"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C1 $tag13
component C2
component C3 $tag13
C1 -- C2

hide $tag13
@enduml
</code></pre><p></p><p><img loading="lazy" width="162" height="167" src="https://plantuml.com/imgw/img-f3c65d5949e01f1e6977795f60464b7d.png"></p></div></td></tr></tbody></table>

-   or `remove $tag13` components:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd55108f2cf5292258f687c87ab912d6f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d55108f2cf5292258f687c87ab912d6f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d55108f2cf5292258f687c87ab912d6f')"></td><td><div onclick="javascript:ljs('d55108f2cf5292258f687c87ab912d6f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred55108f2cf5292258f687c87ab912d6f"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C1 $tag13
component C2
component C3 $tag13
C1 -- C2

remove $tag13
@enduml
</code></pre><p></p><p><img loading="lazy" width="69" height="59" src="https://plantuml.com/imgw/img-d55108f2cf5292258f687c87ab912d6f.png"></p></div></td></tr></tbody></table>

-   or `remove $tag13 and restore $tag1` components:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img131fb733e84025d8d0d4462cde6ec703" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('131fb733e84025d8d0d4462cde6ec703')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('131fb733e84025d8d0d4462cde6ec703')"></td><td><div onclick="javascript:ljs('131fb733e84025d8d0d4462cde6ec703')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre131fb733e84025d8d0d4462cde6ec703"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C1 $tag13 $tag1
component C2
component C3 $tag13
C1 -- C2

remove $tag13
restore $tag1
@enduml
</code></pre><p></p><p><img loading="lazy" width="69" height="167" src="https://plantuml.com/imgw/img-131fb733e84025d8d0d4462cde6ec703.png"></p></div></td></tr></tbody></table>

-   or `remove * and restore $tag1` components:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5ccdd79759e118070948e6f2ab30eefd" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5ccdd79759e118070948e6f2ab30eefd')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5ccdd79759e118070948e6f2ab30eefd')"></td><td><div onclick="javascript:ljs('5ccdd79759e118070948e6f2ab30eefd')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5ccdd79759e118070948e6f2ab30eefd"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C1 $tag13 $tag1
component C2
component C3 $tag13
C1 -- C2

remove *
restore $tag1
@enduml
</code></pre><p></p><p><img loading="lazy" width="69" height="59" src="https://plantuml.com/imgw/img-5ccdd79759e118070948e6f2ab30eefd.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-7337](https://forum.plantuml.net/7337) and [QA-11052](https://forum.plantuml.net/11052)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Display JSON Data on Component diagram

### Simple example

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img1da794c9fd17ea9606f57b22f0674453" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('1da794c9fd17ea9606f57b22f0674453')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('1da794c9fd17ea9606f57b22f0674453')"></td><td><div onclick="javascript:ljs('1da794c9fd17ea9606f57b22f0674453')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre1da794c9fd17ea9606f57b22f0674453"><code onmouseover="az=1" onmouseout="az=0">@startuml
allowmixing

component Component
()        Interface

json JSON {
   "fruit":"Apple",
   "size":"Large",
   "color": ["Red", "Green"]
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="222" height="239" src="https://plantuml.com/imgw/img-1da794c9fd17ea9606f57b22f0674453.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-15481](https://forum.plantuml.net/15481/possible-link-elements-from-two-jsons-with-both-jsons-embeded?show=15567#c15567)\]_

For another example, see on [JSON page](https://plantuml.com/en/json#2fyxla9p9ob6l3t3tjre).

## ![](https://plantuml.com/backtop1.svg "Back to top")Port \[port, portIn, portOut\]

You can add **port** with `port`, `portin`and `portout` keywords.

### Port

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd81067a0a2496a87aeff3e9c03ee9fdb" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d81067a0a2496a87aeff3e9c03ee9fdb')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d81067a0a2496a87aeff3e9c03ee9fdb')"></td><td><div onclick="javascript:ljs('d81067a0a2496a87aeff3e9c03ee9fdb')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred81067a0a2496a87aeff3e9c03ee9fdb"><code onmouseover="az=1" onmouseout="az=0">@startuml
[c]
component C {
  port p1
  port p2
  port p3
  component c1
}

c --&gt; p1
c --&gt; p2
c --&gt; p3
p1 --&gt; c1
p2 --&gt; c1
@enduml
</code></pre><p></p><p><img loading="lazy" width="150" height="256" src="https://plantuml.com/imgw/img-d81067a0a2496a87aeff3e9c03ee9fdb.png"></p></div></td></tr></tbody></table>

### PortIn

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img578a1db795aaa77099afcce2839a9dc3" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('578a1db795aaa77099afcce2839a9dc3')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('578a1db795aaa77099afcce2839a9dc3')"></td><td><div onclick="javascript:ljs('578a1db795aaa77099afcce2839a9dc3')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre578a1db795aaa77099afcce2839a9dc3"><code onmouseover="az=1" onmouseout="az=0">@startuml
[c]
component C {
  portin p1
  portin p2
  portin p3
  component c1
}

c --&gt; p1
c --&gt; p2
c --&gt; p3
p1 --&gt; c1
p2 --&gt; c1
@enduml
</code></pre><p></p><p><img loading="lazy" width="150" height="256" src="https://plantuml.com/imgw/img-578a1db795aaa77099afcce2839a9dc3.png"></p></div></td></tr></tbody></table>

### PortOut

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge1d584d2670cb98035a084a841301c22" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e1d584d2670cb98035a084a841301c22')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e1d584d2670cb98035a084a841301c22')"></td><td><div onclick="javascript:ljs('e1d584d2670cb98035a084a841301c22')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree1d584d2670cb98035a084a841301c22"><code onmouseover="az=1" onmouseout="az=0">@startuml
component C {
  portout p1
  portout p2
  portout p3
  component c1
}
[o]
p1 --&gt; o
p2 --&gt; o
p3 --&gt; o
c1 --&gt; p1
@enduml
</code></pre><p></p><p><img loading="lazy" width="157" height="255" src="https://plantuml.com/imgw/img-e1d584d2670cb98035a084a841301c22.png"></p></div></td></tr></tbody></table>

### Mixing PortIn & PortOut

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9083b6489b57692242d702b4a56cce70" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9083b6489b57692242d702b4a56cce70')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9083b6489b57692242d702b4a56cce70')"></td><td><div onclick="javascript:ljs('9083b6489b57692242d702b4a56cce70')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9083b6489b57692242d702b4a56cce70"><code onmouseover="az=1" onmouseout="az=0">@startuml
[i]
component C {
  portin p1
  portin p2
  portin p3
  portout po1
  portout po2
  portout po3
  component c1
}
[o]

i --&gt; p1
i --&gt; p2
i --&gt; p3
p1 --&gt; c1
p2 --&gt; c1
po1 --&gt; o
po2 --&gt; o
po3 --&gt; o
c1 --&gt; po1
@enduml
</code></pre><p></p><p><img loading="lazy" width="157" height="419" src="https://plantuml.com/imgw/img-9083b6489b57692242d702b4a56cce70.png"></p></div></td></tr></tbody></table>
