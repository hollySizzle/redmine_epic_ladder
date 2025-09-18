---
created: 2025-07-15T23:31:13 (UTC +09:00)
tags: []
source: https://plantuml.com/en/deployment-diagram
author: 
---

# Deployment Diagram syntax and features

> ## Excerpt
> PlantUML deployment diagram syntax: Deployment diagrams are not fully supported within PlantUML. This is a draft version of the language can be subject to changes.

---
## Deployment Diagram

A **Deployment Diagram** is a type of diagram that visualizes the architecture of systems, showcasing how software components are deployed onto hardware. It provides a clear picture of the distribution of components across various nodes, such as servers, workstations, and devices.

With [PlantUML](https://plantuml.com/en/deployment-diagram), creating deployment diagrams becomes a breeze. The platform offers a simple and intuitive way to design these diagrams using plain text, ensuring rapid iterations and easy version control. Moreover, the [PlantUML forum](https://forum.plantuml.net/) provides a vibrant community where users can seek help, share ideas, and collaborate on diagramming challenges. One of the key advantages of PlantUML is its ability to integrate seamlessly with various tools and platforms, making it a preferred choice for professionals and enthusiasts alike.

## ![](https://plantuml.com/backtop1.svg "Back to top")Declaring element

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="imga64838dcbfc890181b2d8fcc3e4f9972" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a64838dcbfc890181b2d8fcc3e4f9972')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a64838dcbfc890181b2d8fcc3e4f9972')"></td><td><div onclick="javascript:ljs('a64838dcbfc890181b2d8fcc3e4f9972')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea64838dcbfc890181b2d8fcc3e4f9972"><code onmouseover="az=1" onmouseout="az=0">@startuml
action action
actor actor
actor/ "actor/"
agent agent
artifact artifact
boundary boundary
card card
circle circle
cloud cloud
collections collections
component component
control control
database database
entity entity
file file
folder folder
frame frame
hexagon hexagon
interface interface
label label
node node
package package
person person
process process
queue queue
rectangle rectangle
stack stack
storage storage
usecase usecase
usecase/ "usecase/"
@enduml
</code></pre><p></p><p><img loading="lazy" width="674" height="543" src="https://plantuml.com/imgw/img-a64838dcbfc890181b2d8fcc3e4f9972.png"></p></div></td></tr></tbody></table>

You can optionaly put text using bracket `[]` for a long description.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3300ec5a7ec773888c0dce35347a03f0" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3300ec5a7ec773888c0dce35347a03f0')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3300ec5a7ec773888c0dce35347a03f0')"></td><td><div onclick="javascript:ljs('3300ec5a7ec773888c0dce35347a03f0')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3300ec5a7ec773888c0dce35347a03f0"><code onmouseover="az=1" onmouseout="az=0">@startuml
folder folder [
This is a &lt;b&gt;folder
----
You can use separator
====
of different kind
....
and style
]

node node [
This is a &lt;b&gt;node
----
You can use separator
====
of different kind
....
and style
]

database database [
This is a &lt;b&gt;database
----
You can use separator
====
of different kind
....
and style
]

usecase usecase [
This is a &lt;b&gt;usecase
----
You can use separator
====
of different kind
....
and style
]

card card [
This is a &lt;b&gt;card
----
You can use separator
====
of different kind
....
and style
&lt;i&gt;&lt;color:blue&gt;(add from V1.2020.7)&lt;/color&gt;&lt;/i&gt;
]
@enduml
</code></pre><p></p><p><img loading="lazy" width="606" height="322" src="https://plantuml.com/imgw/img-3300ec5a7ec773888c0dce35347a03f0.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Declaring element (using short form)

We can declare element using some short forms.

<table><tbody><tr><td><b>Long form Keyword</b></td><td><b>Short form Keyword</b></td><td><b>Long form example</b></td><td><b>Short form example</b></td><td><b>Ref.</b></td></tr><tr><td><code>actor</code></td><td><code>:</code> <em>a</em> <code>:</code></td><td><code>actor actor1</code></td><td><code>:actor2:</code></td><td><a href="https://plantuml.com/use-case-diagram#d9b36998c97be687">Actors</a></td></tr><tr><td><code>component</code></td><td><code>[</code> <em>c</em> <code>]</code></td><td><code>component component1</code></td><td><code>[component2]</code></td><td><a href="https://plantuml.com/component-diagram#05bbb43b3d923283">Components</a></td></tr><tr><td><code>interface</code></td><td><code>()</code> <em>i</em></td><td><code>interface interface1</code></td><td><code>() "interface2"</code></td><td><a href="https://plantuml.com/component-diagram#756640f0aea5f5be">Interfaces</a></td></tr><tr><td><code>usecase</code></td><td><code>(</code> <em>u</em> <code>)</code></td><td><code>usecase usecase1</code></td><td><code>(usecase2)</code></td><td><a href="https://plantuml.com/use-case-diagram#5cb617d22da857ea">Usecases</a></td></tr></tbody></table>

### Actor

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img184e6e41a99f82f5cd6a9fd0f5bd4a2f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('184e6e41a99f82f5cd6a9fd0f5bd4a2f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('184e6e41a99f82f5cd6a9fd0f5bd4a2f')"></td><td><div onclick="javascript:ljs('184e6e41a99f82f5cd6a9fd0f5bd4a2f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre184e6e41a99f82f5cd6a9fd0f5bd4a2f"><code onmouseover="az=1" onmouseout="az=0">@startuml

actor actor1
:actor2:

@enduml
</code></pre><p></p><p><img loading="lazy" width="124" height="87" src="https://plantuml.com/imgw/img-184e6e41a99f82f5cd6a9fd0f5bd4a2f.png"></p></div></td></tr></tbody></table>

**NB**: _There is an old syntax for actor with guillemet which is now deprecated and will be removed some days. Please do not use in your diagram._

### Component

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge2e4984cfca9b6ef4d9332b0abd97f1d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e2e4984cfca9b6ef4d9332b0abd97f1d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e2e4984cfca9b6ef4d9332b0abd97f1d')"></td><td><div onclick="javascript:ljs('e2e4984cfca9b6ef4d9332b0abd97f1d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree2e4984cfca9b6ef4d9332b0abd97f1d"><code onmouseover="az=1" onmouseout="az=0">@startuml

component component1
[component2]

@enduml
</code></pre><p></p><p><img loading="lazy" width="281" height="59" src="https://plantuml.com/imgw/img-e2e4984cfca9b6ef4d9332b0abd97f1d.png"></p></div></td></tr></tbody></table>

### Interface

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img186e131201ada84fb380c73980eb0768" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('186e131201ada84fb380c73980eb0768')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('186e131201ada84fb380c73980eb0768')"></td><td><div onclick="javascript:ljs('186e131201ada84fb380c73980eb0768')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre186e131201ada84fb380c73980eb0768"><code onmouseover="az=1" onmouseout="az=0">@startuml

interface interface1
() "interface2"

label "//interface example//"
@enduml
</code></pre><p></p><p><img loading="lazy" width="209" height="136" src="https://plantuml.com/imgw/img-186e131201ada84fb380c73980eb0768.png"></p></div></td></tr></tbody></table>

### Usecase

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img524222ffcb7d382bcf037b6aa542122a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('524222ffcb7d382bcf037b6aa542122a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('524222ffcb7d382bcf037b6aa542122a')"></td><td><div onclick="javascript:ljs('524222ffcb7d382bcf037b6aa542122a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre524222ffcb7d382bcf037b6aa542122a"><code onmouseover="az=1" onmouseout="az=0">@startuml

usecase usecase1
(usecase2)

@enduml
</code></pre><p></p><p><img loading="lazy" width="227" height="41" src="https://plantuml.com/imgw/img-524222ffcb7d382bcf037b6aa542122a.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Linking or arrow

You can create simple links between elements with or without labels:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img51bff1a297e709fb399531a3651edefa" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('51bff1a297e709fb399531a3651edefa')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('51bff1a297e709fb399531a3651edefa')"></td><td><div onclick="javascript:ljs('51bff1a297e709fb399531a3651edefa')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre51bff1a297e709fb399531a3651edefa"><code onmouseover="az=1" onmouseout="az=0">@startuml

node node1
node node2
node node3
node node4
node node5
node1 -- node2 : label1
node1 .. node3 : label2
node1 ~~ node4 : label3
node1 == node5

@enduml
</code></pre><p></p><p><img loading="lazy" width="452" height="195" src="https://plantuml.com/imgw/img-51bff1a297e709fb399531a3651edefa.png"></p></div></td></tr></tbody></table>

It is possible to use several types of links:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img2860d1917d430db4489b76c5bbae53f8" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('2860d1917d430db4489b76c5bbae53f8')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('2860d1917d430db4489b76c5bbae53f8')"></td><td><div onclick="javascript:ljs('2860d1917d430db4489b76c5bbae53f8')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre2860d1917d430db4489b76c5bbae53f8"><code onmouseover="az=1" onmouseout="az=0">@startuml

artifact artifact1
artifact artifact2
artifact artifact3
artifact artifact4
artifact artifact5
artifact artifact6
artifact artifact7
artifact artifact8
artifact artifact9
artifact artifact10
artifact1 --&gt; artifact2
artifact1 --* artifact3
artifact1 --o artifact4
artifact1 --+ artifact5
artifact1 --# artifact6
artifact1 --&gt;&gt; artifact7
artifact1 --0 artifact8
artifact1 --^ artifact9
artifact1 --(0 artifact10

@enduml
</code></pre><p></p><p><img loading="lazy" width="1025" height="153" src="https://plantuml.com/imgw/img-2860d1917d430db4489b76c5bbae53f8.png"></p></div></td></tr></tbody></table>

You can also have the following types:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgfdc757428c4437147d220ff1212e8263" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('fdc757428c4437147d220ff1212e8263')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('fdc757428c4437147d220ff1212e8263')"></td><td><div onclick="javascript:ljs('fdc757428c4437147d220ff1212e8263')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prefdc757428c4437147d220ff1212e8263"><code onmouseover="az=1" onmouseout="az=0">@startuml

cloud cloud1
cloud cloud2
cloud cloud3
cloud cloud4
cloud cloud5
cloud1 -0- cloud2
cloud1 -0)- cloud3
cloud1 -(0- cloud4
cloud1 -(0)- cloud5

@enduml
</code></pre><p></p><p><img loading="lazy" width="413" height="173" src="https://plantuml.com/imgw/img-fdc757428c4437147d220ff1212e8263.png"></p></div></td></tr></tbody></table>

or another example:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbe0c4cf92dfea1190baaeb0fabf863cc" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('be0c4cf92dfea1190baaeb0fabf863cc')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('be0c4cf92dfea1190baaeb0fabf863cc')"></td><td><div onclick="javascript:ljs('be0c4cf92dfea1190baaeb0fabf863cc')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebe0c4cf92dfea1190baaeb0fabf863cc"><code onmouseover="az=1" onmouseout="az=0">@startuml
actor foo1
actor foo2
foo1 &lt;-0-&gt; foo2
foo1 &lt;-(0)-&gt; foo2
 
(ac1) -le(0)-&gt; left1
ac1 -ri(0)-&gt; right1
ac1 .up(0).&gt; up1
ac1 ~up(0)~&gt; up2
ac1 -do(0)-&gt; down1
ac1 -do(0)-&gt; down2
 
actor1 -0)- actor2
 
component comp1
component comp2
comp1 *-0)-+ comp2
[comp3] &lt;--&gt;&gt; [comp4]

boundary b1
control c1
b1 -(0)- c1

component comp1
interface interf1
comp1 #~~( interf1

:mode1actor: -0)- fooa1
:mode1actorl: -ri0)- foo1l

[component1] 0)-(0-(0 [componentC]
() component3 )-0-(0 "foo" [componentC]

[aze1] #--&gt;&gt; [aze2]
@enduml
</code></pre><p></p><p><img loading="lazy" width="1382" height="363" src="https://plantuml.com/imgw/img-be0c4cf92dfea1190baaeb0fabf863cc.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-547](https://forum.plantuml.net/547/composite-structure-diagrams?show=554#a554) and [QA-1736](https://forum.plantuml.net/1736/are-partial-lollipop-for-component-diagrams-supported?show=1737#a1737)\]_

⎘ See all type on **Appendix**.

## ![](https://plantuml.com/backtop1.svg "Back to top")Bracketed arrow style

_Similar as [Bracketed **class** relations (linking or arrow) style](https://plantuml.com/en/class-diagram#chjviqthvhkikfmwbahk)_

### Line style

It's also possible to have explicitly `bold`, `dashed`, `dotted`, `hidden` or `plain` arrows:

-   without label

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9eca94a31a8fc95d04756f063f3c8f8b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9eca94a31a8fc95d04756f063f3c8f8b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9eca94a31a8fc95d04756f063f3c8f8b')"></td><td><div onclick="javascript:ljs('9eca94a31a8fc95d04756f063f3c8f8b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9eca94a31a8fc95d04756f063f3c8f8b"><code onmouseover="az=1" onmouseout="az=0">@startuml
node foo
title Bracketed line style without label
foo --&gt; bar
foo -[bold]-&gt; bar1
foo -[dashed]-&gt; bar2
foo -[dotted]-&gt; bar3
foo -[hidden]-&gt; bar4
foo -[plain]-&gt; bar5
@enduml
</code></pre><p></p><p><img loading="lazy" width="481" height="221" src="https://plantuml.com/imgw/img-9eca94a31a8fc95d04756f063f3c8f8b.png"></p></div></td></tr></tbody></table>

-   with label

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgaeac7d2d9dfbbd307ef175aeb9877824" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('aeac7d2d9dfbbd307ef175aeb9877824')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('aeac7d2d9dfbbd307ef175aeb9877824')"></td><td><div onclick="javascript:ljs('aeac7d2d9dfbbd307ef175aeb9877824')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preaeac7d2d9dfbbd307ef175aeb9877824"><code onmouseover="az=1" onmouseout="az=0">@startuml
title Bracketed line style with label
node foo
foo --&gt; bar          : ∅
foo -[bold]-&gt; bar1   : [bold]
foo -[dashed]-&gt; bar2 : [dashed]
foo -[dotted]-&gt; bar3 : [dotted]
foo -[hidden]-&gt; bar4 : [hidden]
foo -[plain]-&gt; bar5  : [plain]
@enduml
</code></pre><p></p><p><img loading="lazy" width="482" height="239" src="https://plantuml.com/imgw/img-aeac7d2d9dfbbd307ef175aeb9877824.png"></p></div></td></tr></tbody></table>

_\[Adapted from [QA-4181](https://forum.plantuml.net/4181/how-change-width-line-in-a-relationship-between-two-classes?show=4232#a4232)\]_

### Line color

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc0e88a9b2cd304f636b9a0245524a253" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c0e88a9b2cd304f636b9a0245524a253')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c0e88a9b2cd304f636b9a0245524a253')"></td><td><div onclick="javascript:ljs('c0e88a9b2cd304f636b9a0245524a253')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec0e88a9b2cd304f636b9a0245524a253"><code onmouseover="az=1" onmouseout="az=0">@startuml
title Bracketed line color
node  foo
foo --&gt; bar
foo -[#red]-&gt; bar1     : [#red]
foo -[#green]-&gt; bar2   : [#green]
foo -[#blue]-&gt; bar3    : [#blue]
foo -[#blue;#yellow;#green]-&gt; bar4
@enduml
</code></pre><p></p><p><img loading="lazy" width="392" height="239" src="https://plantuml.com/imgw/img-c0e88a9b2cd304f636b9a0245524a253.png"></p></div></td></tr></tbody></table>

### Line thickness

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img105a05e94b0bfffee82e608226b82629" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('105a05e94b0bfffee82e608226b82629')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('105a05e94b0bfffee82e608226b82629')"></td><td><div onclick="javascript:ljs('105a05e94b0bfffee82e608226b82629')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre105a05e94b0bfffee82e608226b82629"><code onmouseover="az=1" onmouseout="az=0">@startuml
title Bracketed line thickness
node foo
foo --&gt; bar                 : ∅
foo -[thickness=1]-&gt; bar1   : [1]
foo -[thickness=2]-&gt; bar2   : [2]
foo -[thickness=4]-&gt; bar3   : [4]
foo -[thickness=8]-&gt; bar4   : [8]
foo -[thickness=16]-&gt; bar5  : [16]
@enduml
</code></pre><p></p><p><img loading="lazy" width="481" height="239" src="https://plantuml.com/imgw/img-105a05e94b0bfffee82e608226b82629.png"></p></div></td></tr></tbody></table>

_\[Adapted from [QA-4949](https://forum.plantuml.net/4949)\]_

### Mix

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd500137c41adb22ab9ff0041d8b50b44" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d500137c41adb22ab9ff0041d8b50b44')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d500137c41adb22ab9ff0041d8b50b44')"></td><td><div onclick="javascript:ljs('d500137c41adb22ab9ff0041d8b50b44')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred500137c41adb22ab9ff0041d8b50b44"><code onmouseover="az=1" onmouseout="az=0">@startuml
title Bracketed line style mix
node foo
foo --&gt; bar                             : ∅
foo -[#red,thickness=1]-&gt; bar1          : [#red,1]
foo -[#red,dashed,thickness=2]-&gt; bar2   : [#red,dashed,2]
foo -[#green,dashed,thickness=4]-&gt; bar3 : [#green,dashed,4]
foo -[#blue,dotted,thickness=8]-&gt; bar4  : [blue,dotted,8]
foo -[#blue,plain,thickness=16]-&gt; bar5  : [blue,plain,16]
foo -[#blue;#green,dashed,thickness=4]-&gt; bar6  : [blue;green,dashed,4]
@enduml
</code></pre><p></p><p><img loading="lazy" width="801" height="239" src="https://plantuml.com/imgw/img-d500137c41adb22ab9ff0041d8b50b44.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Change arrow color and style (inline style)

You can change the [color](https://plantuml.com/en/color) or style of individual arrows using the inline following notation:

-   `#color;line.[bold|dashed|dotted];text:color`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img53086358b61ccbe594da7d466b96d229" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('53086358b61ccbe594da7d466b96d229')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('53086358b61ccbe594da7d466b96d229')"></td><td><div onclick="javascript:ljs('53086358b61ccbe594da7d466b96d229')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre53086358b61ccbe594da7d466b96d229"><code onmouseover="az=1" onmouseout="az=0">@startuml
node foo
foo --&gt; bar : normal
foo --&gt; bar1 #line:red;line.bold;text:red  : red bold
foo --&gt; bar2 #green;line.dashed;text:green : green dashed 
foo --&gt; bar3 #blue;line.dotted;text:blue   : blue dotted
@enduml
</code></pre><p></p><p><img loading="lazy" width="349" height="201" src="https://plantuml.com/imgw/img-53086358b61ccbe594da7d466b96d229.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-3770](https://forum.plantuml.net/3770) and [QA-3816](https://forum.plantuml.net/3816)\]_ _\[See similar feature on [class diagram](https://plantuml.com/en/class-diagram#b5b0e4228f2e5022)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Change element color and style (inline style)

You can change the [color](https://plantuml.com/en/color) or style of individual element using the following notation:

-   `#[color|back:color];line:color;line.[bold|dashed|dotted];text:color`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdeb526b3b31c6719ffd5e4ff1e4fa1c5" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('deb526b3b31c6719ffd5e4ff1e4fa1c5')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('deb526b3b31c6719ffd5e4ff1e4fa1c5')"></td><td><div onclick="javascript:ljs('deb526b3b31c6719ffd5e4ff1e4fa1c5')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predeb526b3b31c6719ffd5e4ff1e4fa1c5"><code onmouseover="az=1" onmouseout="az=0">@startuml
agent a
cloud c #pink;line:red;line.bold;text:red
file  f #palegreen;line:green;line.dashed;text:green
node  n #aliceblue;line:blue;line.dotted;text:blue
@enduml
</code></pre><p></p><p><img loading="lazy" width="131" height="177" src="https://plantuml.com/imgw/img-deb526b3b31c6719ffd5e4ff1e4fa1c5.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img535d8bb48877b6a97d9d3a0456b34389" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('535d8bb48877b6a97d9d3a0456b34389')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('535d8bb48877b6a97d9d3a0456b34389')"></td><td><div onclick="javascript:ljs('535d8bb48877b6a97d9d3a0456b34389')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre535d8bb48877b6a97d9d3a0456b34389"><code onmouseover="az=1" onmouseout="az=0">@startuml
agent a
cloud c #pink;line:red;line.bold;text:red [
c
cloud description
]
file  f #palegreen;line:green;line.dashed;text:green {
[c1]
[c2]
}
frame frame {
node  n #aliceblue;line:blue;line.dotted;text:blue
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="511" height="113" src="https://plantuml.com/imgw/img-535d8bb48877b6a97d9d3a0456b34389.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-6852](https://forum.plantuml.net/6852)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Nestable elements

Here are the nestable elements:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img29c8e5c91f9ad3755c5655b76813ae31" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('29c8e5c91f9ad3755c5655b76813ae31')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('29c8e5c91f9ad3755c5655b76813ae31')"></td><td><div onclick="javascript:ljs('29c8e5c91f9ad3755c5655b76813ae31')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre29c8e5c91f9ad3755c5655b76813ae31"><code onmouseover="az=1" onmouseout="az=0">@startuml
action action {
}
artifact artifact {
}
card card {
}
cloud cloud {
}
component component {
}
database database {
}
file file {
}
folder folder {
}
frame frame {
}
hexagon hexagon {
}
node node {
}
package package {
}
process process {
}
queue queue {
}
rectangle rectangle {
}
stack stack {
}
storage storage {
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="1834" height="73" src="https://plantuml.com/imgw/img-29c8e5c91f9ad3755c5655b76813ae31.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Packages and nested elements

### Example with one level

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgce1f22ecc9a861a50c0c65e153081ad6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ce1f22ecc9a861a50c0c65e153081ad6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ce1f22ecc9a861a50c0c65e153081ad6')"></td><td><div onclick="javascript:ljs('ce1f22ecc9a861a50c0c65e153081ad6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prece1f22ecc9a861a50c0c65e153081ad6"><code onmouseover="az=1" onmouseout="az=0">@startuml
artifact    artifactVeryLOOOOOOOOOOOOOOOOOOOg    as "artifact" {
file f1
}
card        cardVeryLOOOOOOOOOOOOOOOOOOOg        as "card" {
file f2
}
cloud       cloudVeryLOOOOOOOOOOOOOOOOOOOg       as "cloud" {
file f3
}
component   componentVeryLOOOOOOOOOOOOOOOOOOOg   as "component" {
file f4
}
database    databaseVeryLOOOOOOOOOOOOOOOOOOOg    as "database" {
file f5
}
file        fileVeryLOOOOOOOOOOOOOOOOOOOg        as "file" {
file f6
}
folder      folderVeryLOOOOOOOOOOOOOOOOOOOg      as "folder" {
file f7
}
frame       frameVeryLOOOOOOOOOOOOOOOOOOOg       as "frame" {
file f8
}
hexagon     hexagonVeryLOOOOOOOOOOOOOOOOOOOg     as "hexagon" {
file f9
}
node        nodeVeryLOOOOOOOOOOOOOOOOOOOg        as "node" {
file f10
}
package     packageVeryLOOOOOOOOOOOOOOOOOOOg     as "package" {
file f11
}
queue       queueVeryLOOOOOOOOOOOOOOOOOOOg       as "queue" {
file f12
}
rectangle   rectangleVeryLOOOOOOOOOOOOOOOOOOOg   as "rectangle" {
file f13
}
stack       stackVeryLOOOOOOOOOOOOOOOOOOOg       as "stack" {
file f14
}
storage     storageVeryLOOOOOOOOOOOOOOOOOOOg     as "storage" {
file f15
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="1447" height="127" src="https://plantuml.com/imgw/img-ce1f22ecc9a861a50c0c65e153081ad6.png"></p></div></td></tr></tbody></table>

### Other example

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgeb396555c9f7c8625938d38725bfb266" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('eb396555c9f7c8625938d38725bfb266')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('eb396555c9f7c8625938d38725bfb266')"></td><td><div onclick="javascript:ljs('eb396555c9f7c8625938d38725bfb266')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preeb396555c9f7c8625938d38725bfb266"><code onmouseover="az=1" onmouseout="az=0">@startuml
artifact Foo1 {
  folder Foo2
}

folder Foo3 {
  artifact Foo4
}

frame Foo5 {
  database Foo6
}

cloud vpc {
  node ec2 {
    stack stack
  }
}

@enduml
</code></pre><p></p><p><img loading="lazy" width="530" height="185" src="https://plantuml.com/imgw/img-eb396555c9f7c8625938d38725bfb266.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9f231c6b64418aa3e27deb765cdea02b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9f231c6b64418aa3e27deb765cdea02b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9f231c6b64418aa3e27deb765cdea02b')"></td><td><div onclick="javascript:ljs('9f231c6b64418aa3e27deb765cdea02b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9f231c6b64418aa3e27deb765cdea02b"><code onmouseover="az=1" onmouseout="az=0">@startuml
node Foo1 {
 cloud Foo2
}

cloud Foo3 {
  frame Foo4
}

database Foo5  {
  storage Foo6
}

storage Foo7 {
  storage Foo8
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="474" height="132" src="https://plantuml.com/imgw/img-9f231c6b64418aa3e27deb765cdea02b.png"></p></div></td></tr></tbody></table>

### Full nesting

Here is all the nested elements:

-   by alphabetical order:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb8c7d5251431c611575fdc3d1d9b0b5b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b8c7d5251431c611575fdc3d1d9b0b5b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b8c7d5251431c611575fdc3d1d9b0b5b')"></td><td><div onclick="javascript:ljs('b8c7d5251431c611575fdc3d1d9b0b5b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb8c7d5251431c611575fdc3d1d9b0b5b"><code onmouseover="az=1" onmouseout="az=0">@startuml
action action {
artifact artifact {
card card {
cloud cloud {
component component {
database database {
file file {
folder folder {
frame frame {
hexagon hexagon {
node node {
package package {
process process {
queue queue {
rectangle rectangle {
stack stack {
storage storage {
}
}
}
}
}
}
}
}
}
}
}
}
}
}
}
}
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="852" height="1142" src="https://plantuml.com/imgw/img-b8c7d5251431c611575fdc3d1d9b0b5b.png"></p></div></td></tr></tbody></table>

-   or reverse alphabetical order

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc95847e329dac39a557dcfd994dfca70" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c95847e329dac39a557dcfd994dfca70')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c95847e329dac39a557dcfd994dfca70')"></td><td><div onclick="javascript:ljs('c95847e329dac39a557dcfd994dfca70')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec95847e329dac39a557dcfd994dfca70"><code onmouseover="az=1" onmouseout="az=0">@startuml
storage storage {
stack stack {
rectangle rectangle {
queue queue {
process process {
package package {
node node {
hexagon hexagon {
frame frame {
folder folder {
file file {
database database {
component component {
cloud cloud {
card card {
artifact artifact {
action action {
}
}
}
}
}
}
}
}
}
}
}
}
}
}
}
}
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="832" height="1142" src="https://plantuml.com/imgw/img-c95847e329dac39a557dcfd994dfca70.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Alias

### Simple alias with `as`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img152fa73ec0c7cfbe667cb4222d24a410" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('152fa73ec0c7cfbe667cb4222d24a410')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('152fa73ec0c7cfbe667cb4222d24a410')"></td><td><div onclick="javascript:ljs('152fa73ec0c7cfbe667cb4222d24a410')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre152fa73ec0c7cfbe667cb4222d24a410"><code onmouseover="az=1" onmouseout="az=0">@startuml
node Node1 as n1
node "Node 2" as n2
file f1 as "File 1"
cloud c1 as "this
is
a
cloud"
cloud c2 [this
is
another
cloud]

n1 -&gt; n2
n1 --&gt; f1
f1 -&gt; c1
c1 -&gt; c2
@enduml
</code></pre><p></p><p><img loading="lazy" width="302" height="228" src="https://plantuml.com/imgw/img-152fa73ec0c7cfbe667cb4222d24a410.png"></p></div></td></tr></tbody></table>

### Examples of long alias

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc255afabba09979b9693b9bfb576bd27" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c255afabba09979b9693b9bfb576bd27')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c255afabba09979b9693b9bfb576bd27')"></td><td><div onclick="javascript:ljs('c255afabba09979b9693b9bfb576bd27')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec255afabba09979b9693b9bfb576bd27"><code onmouseover="az=1" onmouseout="az=0">@startuml
actor        "actor"       as actorVeryLOOOOOOOOOOOOOOOOOOOg
agent        "agent"       as agentVeryLOOOOOOOOOOOOOOOOOOOg
artifact     "artifact"    as artifactVeryLOOOOOOOOOOOOOOOOOOOg
boundary     "boundary"    as boundaryVeryLOOOOOOOOOOOOOOOOOOOg
card         "card"        as cardVeryLOOOOOOOOOOOOOOOOOOOg
cloud        "cloud"       as cloudVeryLOOOOOOOOOOOOOOOOOOOg
collections  "collections" as collectionsVeryLOOOOOOOOOOOOOOOOOOOg
component    "component"   as componentVeryLOOOOOOOOOOOOOOOOOOOg
control      "control"     as controlVeryLOOOOOOOOOOOOOOOOOOOg
database     "database"    as databaseVeryLOOOOOOOOOOOOOOOOOOOg
entity       "entity"      as entityVeryLOOOOOOOOOOOOOOOOOOOg
file         "file"        as fileVeryLOOOOOOOOOOOOOOOOOOOg
folder       "folder"      as folderVeryLOOOOOOOOOOOOOOOOOOOg
frame        "frame"       as frameVeryLOOOOOOOOOOOOOOOOOOOg
hexagon      "hexagon"     as hexagonVeryLOOOOOOOOOOOOOOOOOOOg
interface    "interface"   as interfaceVeryLOOOOOOOOOOOOOOOOOOOg
label        "label"       as labelVeryLOOOOOOOOOOOOOOOOOOOg
node         "node"        as nodeVeryLOOOOOOOOOOOOOOOOOOOg
package      "package"     as packageVeryLOOOOOOOOOOOOOOOOOOOg
person       "person"      as personVeryLOOOOOOOOOOOOOOOOOOOg
queue        "queue"       as queueVeryLOOOOOOOOOOOOOOOOOOOg
stack        "stack"       as stackVeryLOOOOOOOOOOOOOOOOOOOg
rectangle    "rectangle"   as rectangleVeryLOOOOOOOOOOOOOOOOOOOg
storage      "storage"     as storageVeryLOOOOOOOOOOOOOOOOOOOg
usecase      "usecase"     as usecaseVeryLOOOOOOOOOOOOOOOOOOOg
@enduml
</code></pre><p></p><p><img loading="lazy" width="755" height="533" src="https://plantuml.com/imgw/img-c255afabba09979b9693b9bfb576bd27.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img8f088cbdc4e0288420dc66f00ee2ba50" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('8f088cbdc4e0288420dc66f00ee2ba50')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('8f088cbdc4e0288420dc66f00ee2ba50')"></td><td><div onclick="javascript:ljs('8f088cbdc4e0288420dc66f00ee2ba50')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre8f088cbdc4e0288420dc66f00ee2ba50"><code onmouseover="az=1" onmouseout="az=0">@startuml
actor       actorVeryLOOOOOOOOOOOOOOOOOOOg       as "actor"
agent       agentVeryLOOOOOOOOOOOOOOOOOOOg       as "agent"
artifact    artifactVeryLOOOOOOOOOOOOOOOOOOOg    as "artifact"
boundary    boundaryVeryLOOOOOOOOOOOOOOOOOOOg    as "boundary"
card        cardVeryLOOOOOOOOOOOOOOOOOOOg        as "card"
cloud       cloudVeryLOOOOOOOOOOOOOOOOOOOg       as "cloud"
collections collectionsVeryLOOOOOOOOOOOOOOOOOOOg as "collections"
component   componentVeryLOOOOOOOOOOOOOOOOOOOg   as "component"
control     controlVeryLOOOOOOOOOOOOOOOOOOOg     as "control"
database    databaseVeryLOOOOOOOOOOOOOOOOOOOg    as "database"
entity      entityVeryLOOOOOOOOOOOOOOOOOOOg      as "entity"
file        fileVeryLOOOOOOOOOOOOOOOOOOOg        as "file"
folder      folderVeryLOOOOOOOOOOOOOOOOOOOg      as "folder"
frame       frameVeryLOOOOOOOOOOOOOOOOOOOg       as "frame"
hexagon     hexagonVeryLOOOOOOOOOOOOOOOOOOOg     as "hexagon"
interface   interfaceVeryLOOOOOOOOOOOOOOOOOOOg   as "interface"
label       labelVeryLOOOOOOOOOOOOOOOOOOOg       as "label"
node        nodeVeryLOOOOOOOOOOOOOOOOOOOg        as "node"
package     packageVeryLOOOOOOOOOOOOOOOOOOOg     as "package"
person      personVeryLOOOOOOOOOOOOOOOOOOOg      as "person"
queue       queueVeryLOOOOOOOOOOOOOOOOOOOg       as "queue"
stack       stackVeryLOOOOOOOOOOOOOOOOOOOg       as "stack"
rectangle   rectangleVeryLOOOOOOOOOOOOOOOOOOOg   as "rectangle"
storage     storageVeryLOOOOOOOOOOOOOOOOOOOg     as "storage"
usecase     usecaseVeryLOOOOOOOOOOOOOOOOOOOg     as "usecase"
@enduml
</code></pre><p></p><p><img loading="lazy" width="755" height="533" src="https://plantuml.com/imgw/img-8f088cbdc4e0288420dc66f00ee2ba50.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-12082](https://forum.plantuml.net/12082)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Round corner

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img68925e3a1ff019f75f214db8a6536fb8" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('68925e3a1ff019f75f214db8a6536fb8')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('68925e3a1ff019f75f214db8a6536fb8')"></td><td><div onclick="javascript:ljs('68925e3a1ff019f75f214db8a6536fb8')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre68925e3a1ff019f75f214db8a6536fb8"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam rectangle {
    roundCorner&lt;&lt;Concept&gt;&gt; 25
}

rectangle "Concept Model" &lt;&lt;Concept&gt;&gt; {
rectangle "Example 1" &lt;&lt;Concept&gt;&gt; as ex1
rectangle "Another rectangle"
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="301" height="137" src="https://plantuml.com/imgw/img-68925e3a1ff019f75f214db8a6536fb8.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Specific SkinParameter

### roundCorner

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf862ed75c98667d2598acc01801ead80" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f862ed75c98667d2598acc01801ead80')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f862ed75c98667d2598acc01801ead80')"></td><td><div onclick="javascript:ljs('f862ed75c98667d2598acc01801ead80')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref862ed75c98667d2598acc01801ead80"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam roundCorner 15
actor actor
agent agent
artifact artifact
boundary boundary
card card
circle circle
cloud cloud
collections collections
component component
control control
database database
entity entity
file file
folder folder
frame frame
hexagon hexagon
interface interface
label label
node node
package package
person person
queue queue
rectangle rectangle
stack stack
storage storage
usecase usecase
@enduml
</code></pre><p></p><p><img loading="lazy" width="650" height="534" src="https://plantuml.com/imgw/img-f862ed75c98667d2598acc01801ead80.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-5299](https://forum.plantuml.net/5299), [QA-6915](https://forum.plantuml.net/6915), [QA-11943](https://forum.plantuml.net/11943)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Appendix: All type of arrow line

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6a2761d3781a701b27a7e093a7f9c69f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6a2761d3781a701b27a7e093a7f9c69f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6a2761d3781a701b27a7e093a7f9c69f')"></td><td><div onclick="javascript:ljs('6a2761d3781a701b27a7e093a7f9c69f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6a2761d3781a701b27a7e093a7f9c69f"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
skinparam nodesep 5

f3  ~~  b3  : ""~~""\n//dotted//
f2  ..  b2  : ""..""\n//dashed//
f1  ==  b1  : ""==""\n//bold//
f0  --  b0  : ""--""\n//plain//
@enduml
</code></pre><p></p><p><img loading="lazy" width="185" height="276" src="https://plantuml.com/imgw/img-6a2761d3781a701b27a7e093a7f9c69f.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Appendix: All type of arrow head or '0' arrow

### Type of arrow head

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge01e1db24285c4e4f3a4e03b3a68518c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e01e1db24285c4e4f3a4e03b3a68518c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e01e1db24285c4e4f3a4e03b3a68518c')"></td><td><div onclick="javascript:ljs('e01e1db24285c4e4f3a4e03b3a68518c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree01e1db24285c4e4f3a4e03b3a68518c"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
skinparam nodesep 5

f13 --0   b13 : ""--0""
f12 --@   b12 : ""--@""
f11 --:|&gt; b11 : ""--:|&gt;""
f10 --||&gt; b10 : ""--||&gt;""
f9  --|&gt;  b9  : ""--|&gt;""
f8  --^   b8  : ""--^ ""
f7  --\\  b7  : ""--\\\\""
f6  --#   b6  : ""--# ""
f5  --+   b5  : ""--+ ""
f4  --o   b4  : ""--o ""
f3  --*   b3  : ""--* ""
f2  --&gt;&gt;  b2  : ""--&gt;&gt;""
f1  --&gt;   b1  : ""--&gt; ""
f0  --    b0  : ""--  ""
@enduml
</code></pre><p></p><p><img loading="lazy" width="172" height="908" src="https://plantuml.com/imgw/img-e01e1db24285c4e4f3a4e03b3a68518c.png"></p></div></td></tr></tbody></table>

### Type of '0' arrow or circle arrow

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4293b6f7fc780e5f3994dd5a93f2604e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4293b6f7fc780e5f3994dd5a93f2604e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4293b6f7fc780e5f3994dd5a93f2604e')"></td><td><div onclick="javascript:ljs('4293b6f7fc780e5f3994dd5a93f2604e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4293b6f7fc780e5f3994dd5a93f2604e"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
skinparam nodesep 5

f10 0--0 b10 : "" 0--0 ""
f9 )--(  b9  : "" )--( ""
f8 0)--(0 b8 : "" 0)--(0""
f7 0)--  b7  : "" 0)-- ""
f6 -0)-  b6  : "" -0)- ""
f5 -(0)- b5  : "" -(0)-""
f4 -(0-  b4  : "" -(0- ""
f3 --(0  b3  : "" --(0 ""
f2 --(   b2  : "" --(  ""
f1 --0   b1  : "" --0  ""
@enduml
</code></pre><p></p><p><img loading="lazy" width="191" height="648" src="https://plantuml.com/imgw/img-4293b6f7fc780e5f3994dd5a93f2604e.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Appendix: Test of inline style on all element

### Simple element

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5d71f728004428c37ad00d9ecd2c5124" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5d71f728004428c37ad00d9ecd2c5124')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5d71f728004428c37ad00d9ecd2c5124')"></td><td><div onclick="javascript:ljs('5d71f728004428c37ad00d9ecd2c5124')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5d71f728004428c37ad00d9ecd2c5124"><code onmouseover="az=1" onmouseout="az=0">@startuml
action action           #aliceblue;line:blue;line.dotted;text:blue
actor actor             #aliceblue;line:blue;line.dotted;text:blue
actor/ "actor/"         #aliceblue;line:blue;line.dotted;text:blue
agent agent             #aliceblue;line:blue;line.dotted;text:blue
artifact artifact       #aliceblue;line:blue;line.dotted;text:blue
boundary boundary       #aliceblue;line:blue;line.dotted;text:blue
card card               #aliceblue;line:blue;line.dotted;text:blue
circle circle           #aliceblue;line:blue;line.dotted;text:blue
cloud cloud             #aliceblue;line:blue;line.dotted;text:blue
collections collections #aliceblue;line:blue;line.dotted;text:blue
component component     #aliceblue;line:blue;line.dotted;text:blue
control control         #aliceblue;line:blue;line.dotted;text:blue
database database       #aliceblue;line:blue;line.dotted;text:blue
entity entity           #aliceblue;line:blue;line.dotted;text:blue
file file               #aliceblue;line:blue;line.dotted;text:blue
folder folder           #aliceblue;line:blue;line.dotted;text:blue
frame frame             #aliceblue;line:blue;line.dotted;text:blue
hexagon hexagon         #aliceblue;line:blue;line.dotted;text:blue
interface interface     #aliceblue;line:blue;line.dotted;text:blue
label label             #aliceblue;line:blue;line.dotted;text:blue
node node               #aliceblue;line:blue;line.dotted;text:blue
package package         #aliceblue;line:blue;line.dotted;text:blue
person person           #aliceblue;line:blue;line.dotted;text:blue
process process         #aliceblue;line:blue;line.dotted;text:blue
queue queue             #aliceblue;line:blue;line.dotted;text:blue
rectangle rectangle     #aliceblue;line:blue;line.dotted;text:blue
stack stack             #aliceblue;line:blue;line.dotted;text:blue
storage storage         #aliceblue;line:blue;line.dotted;text:blue
usecase usecase         #aliceblue;line:blue;line.dotted;text:blue
usecase/ "usecase/"     #aliceblue;line:blue;line.dotted;text:blue
@enduml
</code></pre><p></p><p><img loading="lazy" width="674" height="543" src="https://plantuml.com/imgw/img-5d71f728004428c37ad00d9ecd2c5124.png"></p></div></td></tr></tbody></table>

### Nested element

#### Without sub-element

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img84f43f90f6508306d7e79229fb0631e6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('84f43f90f6508306d7e79229fb0631e6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('84f43f90f6508306d7e79229fb0631e6')"></td><td><div onclick="javascript:ljs('84f43f90f6508306d7e79229fb0631e6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre84f43f90f6508306d7e79229fb0631e6"><code onmouseover="az=1" onmouseout="az=0">@startuml
action action #aliceblue;line:blue;line.dotted;text:blue {
}
artifact artifact #aliceblue;line:blue;line.dotted;text:blue {
}
card card #aliceblue;line:blue;line.dotted;text:blue {
}
cloud cloud #aliceblue;line:blue;line.dotted;text:blue {
}
component component #aliceblue;line:blue;line.dotted;text:blue {
}
database database #aliceblue;line:blue;line.dotted;text:blue {
}
file file #aliceblue;line:blue;line.dotted;text:blue {
}
folder folder #aliceblue;line:blue;line.dotted;text:blue {
}
frame frame #aliceblue;line:blue;line.dotted;text:blue {
}
hexagon hexagon #aliceblue;line:blue;line.dotted;text:blue {
}
node node #aliceblue;line:blue;line.dotted;text:blue {
}
package package #aliceblue;line:blue;line.dotted;text:blue {
}
process process #aliceblue;line:blue;line.dotted;text:blue {
}
queue queue #aliceblue;line:blue;line.dotted;text:blue {
}
rectangle rectangle #aliceblue;line:blue;line.dotted;text:blue {
}
stack stack #aliceblue;line:blue;line.dotted;text:blue {
}
storage storage #aliceblue;line:blue;line.dotted;text:blue {
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="1834" height="73" src="https://plantuml.com/imgw/img-84f43f90f6508306d7e79229fb0631e6.png"></p></div></td></tr></tbody></table>

#### With sub-element

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img44283ec3188feb8f8f41ff08063f324e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('44283ec3188feb8f8f41ff08063f324e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('44283ec3188feb8f8f41ff08063f324e')"></td><td><div onclick="javascript:ljs('44283ec3188feb8f8f41ff08063f324e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre44283ec3188feb8f8f41ff08063f324e"><code onmouseover="az=1" onmouseout="az=0">@startuml
action      actionVeryLOOOOOOOOOOOOOOOOOOOg      as "action" #aliceblue;line:blue;line.dotted;text:blue {
file f1
}
artifact    artifactVeryLOOOOOOOOOOOOOOOOOOOg    as "artifact" #aliceblue;line:blue;line.dotted;text:blue {
file f1
}
card        cardVeryLOOOOOOOOOOOOOOOOOOOg        as "card" #aliceblue;line:blue;line.dotted;text:blue {
file f2
}
cloud       cloudVeryLOOOOOOOOOOOOOOOOOOOg       as "cloud" #aliceblue;line:blue;line.dotted;text:blue {
file f3
}
component   componentVeryLOOOOOOOOOOOOOOOOOOOg   as "component" #aliceblue;line:blue;line.dotted;text:blue {
file f4
}
database    databaseVeryLOOOOOOOOOOOOOOOOOOOg    as "database" #aliceblue;line:blue;line.dotted;text:blue {
file f5
}
file        fileVeryLOOOOOOOOOOOOOOOOOOOg        as "file" #aliceblue;line:blue;line.dotted;text:blue {
file f6
}
folder      folderVeryLOOOOOOOOOOOOOOOOOOOg      as "folder" #aliceblue;line:blue;line.dotted;text:blue {
file f7
}
frame       frameVeryLOOOOOOOOOOOOOOOOOOOg       as "frame" #aliceblue;line:blue;line.dotted;text:blue {
file f8
}
hexagon     hexagonVeryLOOOOOOOOOOOOOOOOOOOg     as "hexagon" #aliceblue;line:blue;line.dotted;text:blue {
file f9
}
node        nodeVeryLOOOOOOOOOOOOOOOOOOOg        as "node" #aliceblue;line:blue;line.dotted;text:blue {
file f10
}
package     packageVeryLOOOOOOOOOOOOOOOOOOOg     as "package" #aliceblue;line:blue;line.dotted;text:blue {
file f11
}
process     processVeryLOOOOOOOOOOOOOOOOOOOg     as "process" #aliceblue;line:blue;line.dotted;text:blue {
file f11
}
queue       queueVeryLOOOOOOOOOOOOOOOOOOOg       as "queue" #aliceblue;line:blue;line.dotted;text:blue {
file f12
}
rectangle   rectangleVeryLOOOOOOOOOOOOOOOOOOOg   as "rectangle" #aliceblue;line:blue;line.dotted;text:blue {
file f13
}
stack       stackVeryLOOOOOOOOOOOOOOOOOOOg       as "stack" #aliceblue;line:blue;line.dotted;text:blue {
file f14
}
storage     storageVeryLOOOOOOOOOOOOOOOOOOOg     as "storage" #aliceblue;line:blue;line.dotted;text:blue {
file f15
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="1663" height="127" src="https://plantuml.com/imgw/img-44283ec3188feb8f8f41ff08063f324e.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Appendix: Test of style on all element

### Simple element

#### Global style (on componentDiagram)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img45d203261776abf04147fe08ad318523" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('45d203261776abf04147fe08ad318523')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('45d203261776abf04147fe08ad318523')"></td><td><div onclick="javascript:ljs('45d203261776abf04147fe08ad318523')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre45d203261776abf04147fe08ad318523"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
componentDiagram {
  BackGroundColor palegreen
  LineThickness 1
  LineColor red
}
document {
  BackGroundColor white
}
&lt;/style&gt;
actor actor
actor/ "actor/"
agent agent
artifact artifact
boundary boundary
card card
circle circle
cloud cloud
collections collections
component component
control control
database database
entity entity
file file
folder folder
frame frame
hexagon hexagon
interface interface
label label
node node
package package
person person
queue queue
rectangle rectangle
stack stack
storage storage
usecase usecase
usecase/ "usecase/"
@enduml
</code></pre><p></p><p><img loading="lazy" width="643" height="545" src="https://plantuml.com/imgw/img-45d203261776abf04147fe08ad318523.png"></p></div></td></tr></tbody></table>

#### Style for each element

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0d7d9944916d5cbb8fc558e90dffe109" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0d7d9944916d5cbb8fc558e90dffe109')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0d7d9944916d5cbb8fc558e90dffe109')"></td><td><div onclick="javascript:ljs('0d7d9944916d5cbb8fc558e90dffe109')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0d7d9944916d5cbb8fc558e90dffe109"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
actor {
  BackGroundColor #f80c12
  LineThickness 1
  LineColor black
}
agent {
  BackGroundColor #f80c12
  LineThickness 1
  LineColor black
}
artifact {
  BackGroundColor #ee1100
  LineThickness 1
  LineColor black
}
boundary {
  BackGroundColor #ee1100
  LineThickness 1
  LineColor black
}
card {
  BackGroundColor #ff3311
  LineThickness 1
  LineColor black
}
circle {
  BackGroundColor #ff3311
  LineThickness 1
  LineColor black
}
cloud {
  BackGroundColor #ff4422
  LineThickness 1
  LineColor black
}
collections {
  BackGroundColor #ff4422
  LineThickness 1
  LineColor black
}
component {
  BackGroundColor #ff6644
  LineThickness 1
  LineColor black
}
control {
  BackGroundColor #ff6644
  LineThickness 1
  LineColor black
}
database {
  BackGroundColor #ff9933
  LineThickness 1
  LineColor black
}
entity {
  BackGroundColor #feae2d
  LineThickness 1
  LineColor black
}
file {
  BackGroundColor #feae2d
  LineThickness 1
  LineColor black
}
folder {
  BackGroundColor #ccbb33
  LineThickness 1
  LineColor black
}
frame {
  BackGroundColor #d0c310
  LineThickness 1
  LineColor black
}
hexagon {
  BackGroundColor #aacc22
  LineThickness 1
  LineColor black
}
interface {
  BackGroundColor #69d025
  LineThickness 1
  LineColor black
}
label {
  BackGroundColor black
  LineThickness 1
  LineColor black
}
node {
  BackGroundColor #22ccaa
  LineThickness 1
  LineColor black
}
package {
  BackGroundColor #12bdb9
  LineThickness 1
  LineColor black
}
person {
  BackGroundColor #11aabb
  LineThickness 1
  LineColor black
}
queue {
  BackGroundColor #11aabb
  LineThickness 1
  LineColor black
}
rectangle {
  BackGroundColor #4444dd
  LineThickness 1
  LineColor black
}
stack {
  BackGroundColor #3311bb
  LineThickness 1
  LineColor black
}
storage {
  BackGroundColor #3b0cbd
  LineThickness 1
  LineColor black
}
usecase {
  BackGroundColor #442299
  LineThickness 1
  LineColor black
}
&lt;/style&gt;
actor actor
actor/ "actor/"
agent agent
artifact artifact
boundary boundary
card card
circle circle
cloud cloud
collections collections
component component
control control
database database
entity entity
file file
folder folder
frame frame
hexagon hexagon
interface interface
label label
node node
package package
person person
queue queue
rectangle rectangle
stack stack
storage storage
usecase usecase
usecase/ "usecase/"
@enduml
</code></pre><p></p><p><img loading="lazy" width="643" height="545" src="https://plantuml.com/imgw/img-0d7d9944916d5cbb8fc558e90dffe109.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-13261](https://forum.plantuml.net/13261/)\]_

### Nested element (without level)

#### Global style (on componentDiagram)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img1feedab32006ef5059ef49bed28db6a5" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('1feedab32006ef5059ef49bed28db6a5')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('1feedab32006ef5059ef49bed28db6a5')"></td><td><div onclick="javascript:ljs('1feedab32006ef5059ef49bed28db6a5')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre1feedab32006ef5059ef49bed28db6a5"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
componentDiagram {
  BackGroundColor palegreen
  LineThickness 2
  LineColor red
}
&lt;/style&gt;
artifact artifact {
}
card card {
}
cloud cloud {
}
component component {
}
database database {
}
file file {
}
folder folder {
}
frame frame {
}
hexagon hexagon {
}
node node {
}
package package {
}
queue queue {
}
rectangle rectangle {
}
stack stack {
}
storage storage {
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="1599" height="73" src="https://plantuml.com/imgw/img-1feedab32006ef5059ef49bed28db6a5.png"></p></div></td></tr></tbody></table>

#### Style for each nested element

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img37e0e512a88a48c55d5033c18be36c94" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('37e0e512a88a48c55d5033c18be36c94')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('37e0e512a88a48c55d5033c18be36c94')"></td><td><div onclick="javascript:ljs('37e0e512a88a48c55d5033c18be36c94')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre37e0e512a88a48c55d5033c18be36c94"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
artifact {
  BackGroundColor #ee1100
  LineThickness 1
  LineColor black
}
card {
  BackGroundColor #ff3311
  LineThickness 1
  LineColor black
}
cloud {
  BackGroundColor #ff4422
  LineThickness 1
  LineColor black
}
component {
  BackGroundColor #ff6644
  LineThickness 1
  LineColor black
}
database {
  BackGroundColor #ff9933
  LineThickness 1
  LineColor black
}
file {
  BackGroundColor #feae2d
  LineThickness 1
  LineColor black
}
folder {
  BackGroundColor #ccbb33
  LineThickness 1
  LineColor black
}
frame {
  BackGroundColor #d0c310
  LineThickness 1
  LineColor black
}
hexagon {
  BackGroundColor #aacc22
  LineThickness 1
  LineColor black
}
node {
  BackGroundColor #22ccaa
  LineThickness 1
  LineColor black
}
package {
  BackGroundColor #12bdb9
  LineThickness 1
  LineColor black
}
queue {
  BackGroundColor #11aabb
  LineThickness 1
  LineColor black
}
rectangle {
  BackGroundColor #4444dd
  LineThickness 1
  LineColor black
}
stack {
  BackGroundColor #3311bb
  LineThickness 1
  LineColor black
}
storage {
  BackGroundColor #3b0cbd
  LineThickness 1
  LineColor black
}

&lt;/style&gt;
artifact artifact {
}
card card {
}
cloud cloud {
}
component component {
}
database database {
}
file file {
}
folder folder {
}
frame frame {
}
hexagon hexagon {
}
node node {
}
package package {
}
queue queue {
}
rectangle rectangle {
}
stack stack {
}
storage storage {
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="1599" height="73" src="https://plantuml.com/imgw/img-37e0e512a88a48c55d5033c18be36c94.png"></p></div></td></tr></tbody></table>

### Nested element (with one level)

#### Global style (on componentDiagram)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgec4c7fbb90a4cf487eeed8600f8347d1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ec4c7fbb90a4cf487eeed8600f8347d1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ec4c7fbb90a4cf487eeed8600f8347d1')"></td><td><div onclick="javascript:ljs('ec4c7fbb90a4cf487eeed8600f8347d1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preec4c7fbb90a4cf487eeed8600f8347d1"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
componentDiagram {
  BackGroundColor palegreen
  LineThickness 1
  LineColor red
}
document {
  BackGroundColor white
}
&lt;/style&gt;
artifact e1 as "artifact" {
file f1
}
card e2 as "card" {
file f2
}
cloud e3 as "cloud" {
file f3
}
component e4 as "component" {
file f4
}
database e5 as "database" {
file f5
}
file e6 as "file" {
file f6
}
folder e7 as "folder" {
file f7
}
frame e8 as "frame" {
file f8
}
hexagon e9 as "hexagon" {
file f9
}
node e10 as "node" {
file f10
}
package e11 as "package" {
file f11
}
queue e12 as "queue" {
file f12
}
rectangle e13 as "rectangle" {
file f13
}
stack e14 as "stack" {
file f14
}
storage e15 as "storage" {
file f15
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="1447" height="127" src="https://plantuml.com/imgw/img-ec4c7fbb90a4cf487eeed8600f8347d1.png"></p></div></td></tr></tbody></table>

#### Style for each nested element

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgfebeefcedb67dd8d06a50702be87d3ba" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('febeefcedb67dd8d06a50702be87d3ba')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('febeefcedb67dd8d06a50702be87d3ba')"></td><td><div onclick="javascript:ljs('febeefcedb67dd8d06a50702be87d3ba')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prefebeefcedb67dd8d06a50702be87d3ba"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
artifact {
  BackGroundColor #ee1100
  LineThickness 1
  LineColor black
}
card {
  BackGroundColor #ff3311
  LineThickness 1
  LineColor black
}
cloud {
  BackGroundColor #ff4422
  LineThickness 1
  LineColor black
}
component {
  BackGroundColor #ff6644
  LineThickness 1
  LineColor black
}
database {
  BackGroundColor #ff9933
  LineThickness 1
  LineColor black
}
file {
  BackGroundColor #feae2d
  LineThickness 1
  LineColor black
}
folder {
  BackGroundColor #ccbb33
  LineThickness 1
  LineColor black
}
frame {
  BackGroundColor #d0c310
  LineThickness 1
  LineColor black
}
hexagon {
  BackGroundColor #aacc22
  LineThickness 1
  LineColor black
}
node {
  BackGroundColor #22ccaa
  LineThickness 1
  LineColor black
}
package {
  BackGroundColor #12bdb9
  LineThickness 1
  LineColor black
}
queue {
  BackGroundColor #11aabb
  LineThickness 1
  LineColor black
}
rectangle {
  BackGroundColor #4444dd
  LineThickness 1
  LineColor black
}
stack {
  BackGroundColor #3311bb
  LineThickness 1
  LineColor black
}
storage {
  BackGroundColor #3b0cbd
  LineThickness 1
  LineColor black
}
&lt;/style&gt;
artifact e1 as "artifact" {
file f1
}
card e2 as "card" {
file f2
}
cloud e3 as "cloud" {
file f3
}
component e4 as "component" {
file f4
}
database e5 as "database" {
file f5
}
file e6 as "file" {
file f6
}
folder e7 as "folder" {
file f7
}
frame e8 as "frame" {
file f8
}
hexagon e9 as "hexagon" {
file f9
}
node e10 as "node" {
file f10
}
package e11 as "package" {
file f11
}
queue e12 as "queue" {
file f12
}
rectangle e13 as "rectangle" {
file f13
}
stack e14 as "stack" {
file f14
}
storage e15 as "storage" {
file f15
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="1447" height="127" src="https://plantuml.com/imgw/img-febeefcedb67dd8d06a50702be87d3ba.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Appendix: Test of stereotype with style on all element

### Simple element

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0eabd7d47f8294d3990f0690714487d0" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0eabd7d47f8294d3990f0690714487d0')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0eabd7d47f8294d3990f0690714487d0')"></td><td><div onclick="javascript:ljs('0eabd7d47f8294d3990f0690714487d0')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0eabd7d47f8294d3990f0690714487d0"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
.stereo {
  BackgroundColor palegreen
}
&lt;/style&gt;
actor actor &lt;&lt; stereo &gt;&gt;
actor/ "actor/" &lt;&lt; stereo &gt;&gt;
agent agent &lt;&lt; stereo &gt;&gt;
artifact artifact &lt;&lt; stereo &gt;&gt;
boundary boundary &lt;&lt; stereo &gt;&gt;
card card &lt;&lt; stereo &gt;&gt;
circle circle &lt;&lt; stereo &gt;&gt;
cloud cloud &lt;&lt; stereo &gt;&gt;
collections collections &lt;&lt; stereo &gt;&gt;
component component &lt;&lt; stereo &gt;&gt;
control control &lt;&lt; stereo &gt;&gt;
database database &lt;&lt; stereo &gt;&gt;
entity entity &lt;&lt; stereo &gt;&gt;
file file &lt;&lt; stereo &gt;&gt;
folder folder &lt;&lt; stereo &gt;&gt;
frame frame &lt;&lt; stereo &gt;&gt;
hexagon hexagon &lt;&lt; stereo &gt;&gt;
interface interface &lt;&lt; stereo &gt;&gt;
label label &lt;&lt; stereo &gt;&gt;
node node &lt;&lt; stereo &gt;&gt;
package package &lt;&lt; stereo &gt;&gt;
person person &lt;&lt; stereo &gt;&gt;
queue queue &lt;&lt; stereo &gt;&gt;
rectangle rectangle &lt;&lt; stereo &gt;&gt;
stack stack &lt;&lt; stereo &gt;&gt;
storage storage &lt;&lt; stereo &gt;&gt;
usecase usecase &lt;&lt; stereo &gt;&gt;
usecase/ "usecase/" &lt;&lt; stereo &gt;&gt;
@enduml
</code></pre><p></p><p><img loading="lazy" width="704" height="627" src="https://plantuml.com/imgw/img-0eabd7d47f8294d3990f0690714487d0.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Display JSON Data on Deployment diagram

### Simple example

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgca7caf5ba874e2b73e4efd64f78abe4a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ca7caf5ba874e2b73e4efd64f78abe4a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ca7caf5ba874e2b73e4efd64f78abe4a')"></td><td><div onclick="javascript:ljs('ca7caf5ba874e2b73e4efd64f78abe4a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preca7caf5ba874e2b73e4efd64f78abe4a"><code onmouseover="az=1" onmouseout="az=0">@startuml
allowmixing

component Component
actor     Actor
usecase   Usecase
()        Interface
node      Node
cloud     Cloud

json JSON {
   "fruit":"Apple",
   "size":"Large",
   "color": ["Red", "Green"]
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="323" height="381" src="https://plantuml.com/imgw/img-ca7caf5ba874e2b73e4efd64f78abe4a.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-15481](https://forum.plantuml.net/15481/possible-link-elements-from-two-jsons-with-both-jsons-embeded?show=15567#c15567)\]_

For another example, see on [JSON page](https://plantuml.com/en/json#2fyxla9p9ob6l3t3tjre).

## ![](https://plantuml.com/backtop1.svg "Back to top")Mixing Deployment (Usecase, Component, Deployment) element within a Class or Object diagram

In order to add a Deployment element or a State element within a Class or Object diagram, you can use the `allowmixing` or `allow_mixing` directive.

### Mixing all elements

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0b3a278bdcc46c0d110dc71876dda6a8" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0b3a278bdcc46c0d110dc71876dda6a8')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0b3a278bdcc46c0d110dc71876dda6a8')"></td><td><div onclick="javascript:ljs('0b3a278bdcc46c0d110dc71876dda6a8')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0b3a278bdcc46c0d110dc71876dda6a8"><code onmouseover="az=1" onmouseout="az=0">@startuml

allowmixing

skinparam nodesep 10
abstract        abstract
abstract class  "abstract class"
annotation      annotation
circle          circle
()              circle_short_form
class           class
diamond         diamond
&lt;&gt;              diamond_short_form
entity          entity
enum            enum
exception       exception
interface       interface
metaclass       metaclass
protocol        protocol
stereotype      stereotype
struct          struct
object          object
map map {
 key =&gt; value
}
json JSON {
   "fruit":"Apple",
   "size":"Large",
   "color": ["Red", "Green"]
}
action action
actor actor
actor/ "actor/"
agent agent
artifact artifact
boundary boundary
card card
circle circle
cloud cloud
collections collections
component component
control control
database database
entity entity
file file
folder folder
frame frame
hexagon hexagon
interface interface
label label
node node
package package
person person
process process
queue queue
rectangle rectangle
stack stack
storage storage
usecase usecase
usecase/ "usecase/"
state state
@enduml
</code></pre><p></p><p><img loading="lazy" width="658" height="832" src="https://plantuml.com/imgw/img-0b3a278bdcc46c0d110dc71876dda6a8.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-2335](https://forum.plantuml.net/2335/use-of-actor-inside-class-diagrams) and [QA-5329](https://forum.plantuml.net/5329/language-definition)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Port \[port, portIn, portOut\]

You can added **port** with `port`, `portin`and `portout` keywords.

### Port

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6cdd1ddabd93eb4fb5f48ee94f6a9d9d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6cdd1ddabd93eb4fb5f48ee94f6a9d9d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6cdd1ddabd93eb4fb5f48ee94f6a9d9d')"></td><td><div onclick="javascript:ljs('6cdd1ddabd93eb4fb5f48ee94f6a9d9d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6cdd1ddabd93eb4fb5f48ee94f6a9d9d"><code onmouseover="az=1" onmouseout="az=0">@startuml
[c]
node node {
  port p1
  port p2
  port p3
  file f1
}

c --&gt; p1
c --&gt; p2
c --&gt; p3
p1 --&gt; f1
p2 --&gt; f1
@enduml
</code></pre><p></p><p><img loading="lazy" width="176" height="257" src="https://plantuml.com/imgw/img-6cdd1ddabd93eb4fb5f48ee94f6a9d9d.png"></p></div></td></tr></tbody></table>

### PortIn

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb04f98df81bc4b405087fb5608755a9e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b04f98df81bc4b405087fb5608755a9e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b04f98df81bc4b405087fb5608755a9e')"></td><td><div onclick="javascript:ljs('b04f98df81bc4b405087fb5608755a9e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb04f98df81bc4b405087fb5608755a9e"><code onmouseover="az=1" onmouseout="az=0">@startuml
[c]
node node {
  portin p1
  portin p2
  portin p3
  file f1
}

c --&gt; p1
c --&gt; p2
c --&gt; p3
p1 --&gt; f1
p2 --&gt; f1
@enduml
</code></pre><p></p><p><img loading="lazy" width="176" height="257" src="https://plantuml.com/imgw/img-b04f98df81bc4b405087fb5608755a9e.png"></p></div></td></tr></tbody></table>

### PortOut

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdb7550795b17a9b20cefce86d7add74f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('db7550795b17a9b20cefce86d7add74f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('db7550795b17a9b20cefce86d7add74f')"></td><td><div onclick="javascript:ljs('db7550795b17a9b20cefce86d7add74f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predb7550795b17a9b20cefce86d7add74f"><code onmouseover="az=1" onmouseout="az=0">@startuml
node node {
  portout p1
  portout p2
  portout p3
  file f1
}
[o]
p1 --&gt; o
p2 --&gt; o
p3 --&gt; o
f1 --&gt; p1
@enduml
</code></pre><p></p><p><img loading="lazy" width="182" height="244" src="https://plantuml.com/imgw/img-db7550795b17a9b20cefce86d7add74f.png"></p></div></td></tr></tbody></table>

### Mixing PortIn & PortOut

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img13883224a6b41e0794a6d3f04f79db39" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('13883224a6b41e0794a6d3f04f79db39')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('13883224a6b41e0794a6d3f04f79db39')"></td><td><div onclick="javascript:ljs('13883224a6b41e0794a6d3f04f79db39')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre13883224a6b41e0794a6d3f04f79db39"><code onmouseover="az=1" onmouseout="az=0">@startuml
[i]
node node {
  portin p1
  portin p2
  portin p3
  portout po1
  portout po2
  portout po3
  file f1
}
[o]

i --&gt; p1
i --&gt; p2
i --&gt; p3
p1 --&gt; f1
p2 --&gt; f1
po1 --&gt; o
po2 --&gt; o
po3 --&gt; o
f1 --&gt; po1
@enduml
</code></pre><p></p><p><img loading="lazy" width="182" height="409" src="https://plantuml.com/imgw/img-13883224a6b41e0794a6d3f04f79db39.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Change diagram orientation

You can change (whole) diagram orientation with:

-   `top to bottom direction` _(by default)_
-   `left to right direction`

### Top to bottom _(by default)_

#### With [Graphviz](https://plantuml.com/en/graphviz-dot) _(layout engine by default)_

The main rule is: **Nested element first, then simple element.**

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img422a494bbc81a1fdf68f6f062f7f0617" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('422a494bbc81a1fdf68f6f062f7f0617')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('422a494bbc81a1fdf68f6f062f7f0617')"></td><td><div onclick="javascript:ljs('422a494bbc81a1fdf68f6f062f7f0617')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre422a494bbc81a1fdf68f6f062f7f0617"><code onmouseover="az=1" onmouseout="az=0">@startuml
card a
card b
package A {
  card a1
  card a2
  card a3
  card a4
  card a5
  package sub_a {
   card sa1
   card sa2
   card sa3
  }
}
  
package B {
  card b1
  card b2
  card b3
  card b4
  card b5
  package sub_b {
   card sb1
   card sb2
   card sb3
  }
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="923" height="240" src="https://plantuml.com/imgw/img-422a494bbc81a1fdf68f6f062f7f0617.png"></p></div></td></tr></tbody></table>

#### With [Smetana](https://plantuml.com/en/smetana02) _(internal layout engine)_

The main rule is the opposite: **Simple element first, then nested element.**

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgab2a95d73506ff670b3b1e6aa1affcf7" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ab2a95d73506ff670b3b1e6aa1affcf7')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ab2a95d73506ff670b3b1e6aa1affcf7')"></td><td><div onclick="javascript:ljs('ab2a95d73506ff670b3b1e6aa1affcf7')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preab2a95d73506ff670b3b1e6aa1affcf7"><code onmouseover="az=1" onmouseout="az=0">@startuml
!pragma layout smetana
card a
card b
package A {
  card a1
  card a2
  card a3
  card a4
  card a5
  package sub_a {
   card sa1
   card sa2
   card sa3
  }
}
  
package B {
  card b1
  card b2
  card b3
  card b4
  card b5
  package sub_b {
   card sb1
   card sb2
   card sb3
  }
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="686" height="166" src="https://plantuml.com/imgw/img-ab2a95d73506ff670b3b1e6aa1affcf7.png"></p></div></td></tr></tbody></table>

### Left to right

#### With [Graphviz](https://plantuml.com/en/graphviz-dot) _(layout engine by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0364fd718ef6b60c13c8e6d3344e1951" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0364fd718ef6b60c13c8e6d3344e1951')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0364fd718ef6b60c13c8e6d3344e1951')"></td><td><div onclick="javascript:ljs('0364fd718ef6b60c13c8e6d3344e1951')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0364fd718ef6b60c13c8e6d3344e1951"><code onmouseover="az=1" onmouseout="az=0">@startuml
left to right direction
card a
card b
package A {
  card a1
  card a2
  card a3
  card a4
  card a5
  package sub_a {
   card sa1
   card sa2
   card sa3
  }
}
  
package B {
  card b1
  card b2
  card b3
  card b4
  card b5
  package sub_b {
   card sb1
   card sb2
   card sb3
  }
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="238" height="848" src="https://plantuml.com/imgw/img-0364fd718ef6b60c13c8e6d3344e1951.png"></p></div></td></tr></tbody></table>

#### With [Smetana](https://plantuml.com/en/smetana02) _(internal layout engine)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc93af54981cc10fbc9d703feb0e0985a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c93af54981cc10fbc9d703feb0e0985a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c93af54981cc10fbc9d703feb0e0985a')"></td><td><div onclick="javascript:ljs('c93af54981cc10fbc9d703feb0e0985a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec93af54981cc10fbc9d703feb0e0985a"><code onmouseover="az=1" onmouseout="az=0">@startuml
!pragma layout smetana
left to right direction
card a
card b
package A {
  card a1
  card a2
  card a3
  card a4
  card a5
  package sub_a {
   card sa1
   card sa2
   card sa3
  }
}
  
package B {
  card b1
  card b2
  card b3
  card b4
  card b5
  package sub_b {
   card sb1
   card sb2
   card sb3
  }
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="174" height="612" src="https://plantuml.com/imgw/img-c93af54981cc10fbc9d703feb0e0985a.png"></p></div></td></tr></tbody></table>
