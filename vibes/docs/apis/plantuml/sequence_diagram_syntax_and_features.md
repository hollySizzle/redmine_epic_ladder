---
created: 2025-07-15T23:31:13 (UTC +09:00)
tags: []
source: https://plantuml.com/en/sequence-diagram
author: 
---

# Sequence Diagram syntax and features

> ## Excerpt
> PlantUML sequence diagram syntax: You can have several kinds of participants (actors and others), arrows, notes, groups... Changing fonts and colors is also possible.

---
## Sequence Diagram

PlantUML streamlines the creation of sequence diagrams through its intuitive and user-friendly syntax. This approach allows both novices and experienced designers to quickly transition from concept to a polished graphical output.

-   **Intuitive syntax:**  
    

The syntax of PlantUML is designed for ease of use, ensuring that users can grasp the fundamentals with minimal effort. This clarity reduces the learning curve and accelerates the diagram creation process.

-   **Direct Text-to-Graphic translation:**  
    

There is a direct correlation between the textual input and the resulting diagram. This consistency guarantees that the visual output closely mirrors the initial draft, minimizing unexpected discrepancies and streamlining the workflow.

-   **Efficient workflow:**  
    

The close relationship between text and image not only simplifies the design process but also speeds it up. By reducing the need for extensive revisions, users can focus on refining their diagrams with greater efficiency.

-   **Real-time visualization:**  
    

The ability to visualize the final outcome while drafting the text enhances productivity. This immediate feedback loop helps in identifying and correcting errors early, ensuring a smoother transition from concept to completion.

-   **Seamless edits and revisions:**  
    

Editing is straightforward when working with text-based diagrams. Adjustments can be made directly in the source text, eliminating the complexities and potential errors associated with graphical editing tools.

In summary, PlantUML offers a robust and efficient approach to sequence diagram creation. Its emphasis on simplicity and precision makes it an invaluable asset for anyone looking to produce clear and accurate diagrams with ease.

For further enhancement of your diagram creation experience, please refer to the [common commands in PlantUML](https://plantuml.com/en/commons).

## ![](https://plantuml.com/backtop1.svg "Back to top")Basic Examples

In PlantUML sequence diagrams, the `->` sequence denotes a message sent between two participants, which are automatically recognized and do not need to be declared beforehand.

Utilize dotted arrows by employing the `-->` sequence, offering a distinct visualization in your diagrams.

To improve readability without affecting the visual representation, use reverse arrows like `<-` or `<--`. However, be aware that this is specifically for sequence diagrams and the rules differ for other diagram types.

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="img6252200f96eb2b46de75c9e02db6d7d6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6252200f96eb2b46de75c9e02db6d7d6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6252200f96eb2b46de75c9e02db6d7d6')"></td><td><div onclick="javascript:ljs('6252200f96eb2b46de75c9e02db6d7d6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6252200f96eb2b46de75c9e02db6d7d6"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice -&gt; Bob: Authentication Request
Bob --&gt; Alice: Authentication Response

Alice -&gt; Bob: Another authentication Request
Alice &lt;-- Bob: Another authentication Response
@enduml
</code></pre><p></p><p><img loading="lazy" width="267" height="214" src="https://plantuml.com/imgw/img-6252200f96eb2b46de75c9e02db6d7d6.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Declaring participant

If the keyword `participant` is used to declare a participant, more control on that participant is possible.

The order of declaration will be the (default) **order of display**.

Using these other keywords to declare participants will **change the shape** of the participant representation:

-   `actor`
-   `boundary`
-   `control`
-   `entity`
-   `database`
-   `collections`
-   `queue`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgec958f98e19fdb46206b04fc8af178a9" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ec958f98e19fdb46206b04fc8af178a9')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ec958f98e19fdb46206b04fc8af178a9')"></td><td><div onclick="javascript:ljs('ec958f98e19fdb46206b04fc8af178a9')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preec958f98e19fdb46206b04fc8af178a9"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Participant as Foo
actor       Actor       as Foo1
boundary    Boundary    as Foo2
control     Control     as Foo3
entity      Entity      as Foo4
database    Database    as Foo5
collections Collections as Foo6
queue       Queue       as Foo7
Foo -&gt; Foo1 : To actor 
Foo -&gt; Foo2 : To boundary
Foo -&gt; Foo3 : To control
Foo -&gt; Foo4 : To entity
Foo -&gt; Foo5 : To database
Foo -&gt; Foo6 : To collections
Foo -&gt; Foo7: To queue
@enduml
</code></pre><p></p><p><img loading="lazy" width="574" height="396" src="https://plantuml.com/imgw/img-ec958f98e19fdb46206b04fc8af178a9.png"></p></div></td></tr></tbody></table>

Rename a participant using the `as` keyword.

You can also change the background [color](https://plantuml.com/en/color) of actor or participant.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge010d356a92131525c2db6dae9b43c3e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e010d356a92131525c2db6dae9b43c3e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e010d356a92131525c2db6dae9b43c3e')"></td><td><div onclick="javascript:ljs('e010d356a92131525c2db6dae9b43c3e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree010d356a92131525c2db6dae9b43c3e"><code onmouseover="az=1" onmouseout="az=0">@startuml
actor Bob #red
' The only difference between actor
'and participant is the drawing
participant Alice
participant "I have a really\nlong name" as L #99FF99
/' You can also declare:
   participant L as "I have a really\nlong name"  #99FF99
  '/

Alice-&gt;Bob: Authentication Request
Bob-&gt;Alice: Authentication Response
Bob-&gt;L: Log transaction
@enduml
</code></pre><p></p><p><img loading="lazy" width="327" height="274" src="https://plantuml.com/imgw/img-e010d356a92131525c2db6dae9b43c3e.png"></p></div></td></tr></tbody></table>

You can use the `order` keyword to customize the display order of participants.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdc225efe2eeed5c08dd51bf19a45d182" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('dc225efe2eeed5c08dd51bf19a45d182')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('dc225efe2eeed5c08dd51bf19a45d182')"></td><td><div onclick="javascript:ljs('dc225efe2eeed5c08dd51bf19a45d182')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predc225efe2eeed5c08dd51bf19a45d182"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Last order 30
participant Middle order 20
participant First order 10
@enduml
</code></pre><p></p><p><img loading="lazy" width="166" height="93" src="https://plantuml.com/imgw/img-dc225efe2eeed5c08dd51bf19a45d182.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Declaring participant on multiline

You can declare participant on multi-line.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5224b9b41714e3d795b41a76eed0b773" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5224b9b41714e3d795b41a76eed0b773')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5224b9b41714e3d795b41a76eed0b773')"></td><td><div onclick="javascript:ljs('5224b9b41714e3d795b41a76eed0b773')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5224b9b41714e3d795b41a76eed0b773"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Participant [
    =Title
    ----
    ""SubTitle""
]

participant Bob

Participant -&gt; Bob
@enduml
</code></pre><p></p><p><img loading="lazy" width="140" height="173" src="https://plantuml.com/imgw/img-5224b9b41714e3d795b41a76eed0b773.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-15232](https://forum.plantuml.net/15232/)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Use non-letters in participants

You can use quotes to define participants. And you can use the `as` keyword to give an alias to those participants.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb07ecbd8f20c63e12d29bd53f10a27a6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b07ecbd8f20c63e12d29bd53f10a27a6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b07ecbd8f20c63e12d29bd53f10a27a6')"></td><td><div onclick="javascript:ljs('b07ecbd8f20c63e12d29bd53f10a27a6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb07ecbd8f20c63e12d29bd53f10a27a6"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice -&gt; "Bob()" : Hello
"Bob()" -&gt; "This is very\nlong" as Long
' You can also declare:
' "Bob()" -&gt; Long as "This is very\nlong"
Long --&gt; "Bob()" : ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="207" height="203" src="https://plantuml.com/imgw/img-b07ecbd8f20c63e12d29bd53f10a27a6.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Message to Self

A participant can send a message to itself.

It is also possible to have multi-line using `\n`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img64814ab3adeade2a8870a6bfe868515d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('64814ab3adeade2a8870a6bfe868515d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('64814ab3adeade2a8870a6bfe868515d')"></td><td><div onclick="javascript:ljs('64814ab3adeade2a8870a6bfe868515d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre64814ab3adeade2a8870a6bfe868515d"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice -&gt; Alice: This is a signal to self.\nIt also demonstrates\nmultiline \ntext
@enduml
</code></pre><p></p><p><img loading="lazy" width="168" height="185" src="https://plantuml.com/imgw/img-64814ab3adeade2a8870a6bfe868515d.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4fb1999114b80123f20c6e9b7a8447e1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4fb1999114b80123f20c6e9b7a8447e1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4fb1999114b80123f20c6e9b7a8447e1')"></td><td><div onclick="javascript:ljs('4fb1999114b80123f20c6e9b7a8447e1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4fb1999114b80123f20c6e9b7a8447e1"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice &lt;- Alice: This is a signal to self.\nIt also demonstrates\nmultiline \ntext
@enduml
</code></pre><p></p><p><img loading="lazy" width="169" height="185" src="https://plantuml.com/imgw/img-4fb1999114b80123f20c6e9b7a8447e1.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-1361](https://forum.plantuml.net/1361)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Text alignment

Text alignment on arrows can be set to `left`, `right` or `center` using `skinparam sequenceMessageAlign`.

You can also use `direction` or `reverseDirection` to align text depending on arrow direction. Further details and examples of this are available on the [skinparam](https://plantuml.com/en/skinparam) page.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgde778c0ff2a0b54a36ff8a50a54447d6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('de778c0ff2a0b54a36ff8a50a54447d6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('de778c0ff2a0b54a36ff8a50a54447d6')"></td><td><div onclick="javascript:ljs('de778c0ff2a0b54a36ff8a50a54447d6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prede778c0ff2a0b54a36ff8a50a54447d6"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam sequenceMessageAlign right
Bob -&gt; Alice : Request
Alice -&gt; Bob : Response
@enduml
</code></pre><p></p><p><img loading="lazy" width="134" height="153" src="https://plantuml.com/imgw/img-de778c0ff2a0b54a36ff8a50a54447d6.png"></p></div></td></tr></tbody></table>

### Text of response message below the arrow

You can put the text of the response message below the arrow, with the `skinparam responseMessageBelowArrow true` command.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9943768f3a2d0c8ae74b0ca20d7be22c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9943768f3a2d0c8ae74b0ca20d7be22c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9943768f3a2d0c8ae74b0ca20d7be22c')"></td><td><div onclick="javascript:ljs('9943768f3a2d0c8ae74b0ca20d7be22c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9943768f3a2d0c8ae74b0ca20d7be22c"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam responseMessageBelowArrow true
Bob -&gt; Alice : hello
Bob &lt;- Alice : ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="153" src="https://plantuml.com/imgw/img-9943768f3a2d0c8ae74b0ca20d7be22c.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Change arrow style

You can change arrow style by several ways:

-   add a final `x` to denote a lost message
-   use `\` or `/` instead of `<` or `>` to have only the bottom or top part of the arrow
-   repeat the arrow head (for example, `>>` or `//`) head to have a thin drawing
-   use `--` instead of `-` to have a dotted arrow
-   add a final "o" at arrow head
-   use bidirectional arrow `<->`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3ca7ea2442f7caffdc45f09ed29223dc" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3ca7ea2442f7caffdc45f09ed29223dc')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3ca7ea2442f7caffdc45f09ed29223dc')"></td><td><div onclick="javascript:ljs('3ca7ea2442f7caffdc45f09ed29223dc')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3ca7ea2442f7caffdc45f09ed29223dc"><code onmouseover="az=1" onmouseout="az=0">@startuml
Bob -&gt;x Alice
Bob -&gt; Alice
Bob -&gt;&gt; Alice
Bob -\ Alice
Bob \\- Alice
Bob //-- Alice

Bob -&gt;o Alice
Bob o\\-- Alice

Bob &lt;-&gt; Alice
Bob &lt;-&gt;o Alice
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="233" src="https://plantuml.com/imgw/img-3ca7ea2442f7caffdc45f09ed29223dc.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Change arrow color

You can change the color of individual arrows using the following notation:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3ab74af43c6a6facb28bd04e393b2e9a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3ab74af43c6a6facb28bd04e393b2e9a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3ab74af43c6a6facb28bd04e393b2e9a')"></td><td><div onclick="javascript:ljs('3ab74af43c6a6facb28bd04e393b2e9a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3ab74af43c6a6facb28bd04e393b2e9a"><code onmouseover="az=1" onmouseout="az=0">@startuml
Bob -[#red]&gt; Alice : hello
Alice -[#0000FF]-&gt;Bob : ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="153" src="https://plantuml.com/imgw/img-3ab74af43c6a6facb28bd04e393b2e9a.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Message sequence numbering

The keyword `autonumber` is used to automatically add an incrementing number to messages.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdacdda5ab771c8cfe91903fc6ee14655" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('dacdda5ab771c8cfe91903fc6ee14655')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('dacdda5ab771c8cfe91903fc6ee14655')"></td><td><div onclick="javascript:ljs('dacdda5ab771c8cfe91903fc6ee14655')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predacdda5ab771c8cfe91903fc6ee14655"><code onmouseover="az=1" onmouseout="az=0">@startuml
autonumber
Bob -&gt; Alice : Authentication Request
Bob &lt;- Alice : Authentication Response
@enduml
</code></pre><p></p><p><img loading="lazy" width="231" height="153" src="https://plantuml.com/imgw/img-dacdda5ab771c8cfe91903fc6ee14655.png"></p></div></td></tr></tbody></table>

You can specify a startnumber with `autonumber <start>` , and also an increment with `autonumber <start> <increment>`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img97d3cf9c014fce24ba655df5a5090c5d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('97d3cf9c014fce24ba655df5a5090c5d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('97d3cf9c014fce24ba655df5a5090c5d')"></td><td><div onclick="javascript:ljs('97d3cf9c014fce24ba655df5a5090c5d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre97d3cf9c014fce24ba655df5a5090c5d"><code onmouseover="az=1" onmouseout="az=0">@startuml
autonumber
Bob -&gt; Alice : Authentication Request
Bob &lt;- Alice : Authentication Response

autonumber 15
Bob -&gt; Alice : Another authentication Request
Bob &lt;- Alice : Another authentication Response

autonumber 40 10
Bob -&gt; Alice : Yet another authentication Request
Bob &lt;- Alice : Yet another authentication Response

@enduml
</code></pre><p></p><p><img loading="lazy" width="308" height="275" src="https://plantuml.com/imgw/img-97d3cf9c014fce24ba655df5a5090c5d.png"></p></div></td></tr></tbody></table>

You can specify a format for your number by using between double-quote.

The formatting is done with the Java class `DecimalFormat` (`0` means digit, `#` means digit and zero if absent).

You can use some html tag in the format.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf9be1a6dcf9d4e1b000e71306596fbbe" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f9be1a6dcf9d4e1b000e71306596fbbe')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f9be1a6dcf9d4e1b000e71306596fbbe')"></td><td><div onclick="javascript:ljs('f9be1a6dcf9d4e1b000e71306596fbbe')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref9be1a6dcf9d4e1b000e71306596fbbe"><code onmouseover="az=1" onmouseout="az=0">@startuml
autonumber "&lt;b&gt;[000]"
Bob -&gt; Alice : Authentication Request
Bob &lt;- Alice : Authentication Response

autonumber 15 "&lt;b&gt;(&lt;u&gt;##&lt;/u&gt;)"
Bob -&gt; Alice : Another authentication Request
Bob &lt;- Alice : Another authentication Response

autonumber 40 10 "&lt;font color=red&gt;&lt;b&gt;Message 0  "
Bob -&gt; Alice : Yet another authentication Request
Bob &lt;- Alice : Yet another authentication Response

@enduml
</code></pre><p></p><p><img loading="lazy" width="373" height="275" src="https://plantuml.com/imgw/img-f9be1a6dcf9d4e1b000e71306596fbbe.png"></p></div></td></tr></tbody></table>

You can also use `autonumber stop` and `autonumber resume <increment> <format>` to respectively pause and resume automatic numbering.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga769a08660368e71e94151477f91422e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a769a08660368e71e94151477f91422e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a769a08660368e71e94151477f91422e')"></td><td><div onclick="javascript:ljs('a769a08660368e71e94151477f91422e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea769a08660368e71e94151477f91422e"><code onmouseover="az=1" onmouseout="az=0">@startuml
autonumber 10 10 "&lt;b&gt;[000]"
Bob -&gt; Alice : Authentication Request
Bob &lt;- Alice : Authentication Response

autonumber stop
Bob -&gt; Alice : dummy

autonumber resume "&lt;font color=red&gt;&lt;b&gt;Message 0  "
Bob -&gt; Alice : Yet another authentication Request
Bob &lt;- Alice : Yet another authentication Response

autonumber stop
Bob -&gt; Alice : dummy

autonumber resume 1 "&lt;font color=blue&gt;&lt;b&gt;Message 0  "
Bob -&gt; Alice : Yet another authentication Request
Bob &lt;- Alice : Yet another authentication Response
@enduml
</code></pre><p></p><p><img loading="lazy" width="373" height="336" src="https://plantuml.com/imgw/img-a769a08660368e71e94151477f91422e.png"></p></div></td></tr></tbody></table>

Your startnumber can also be a 2 or 3 digit sequence using a field delimiter such as `.`, `;`, `,`, `:` or a mix of these. For example: `1.1.1` or `1.1:1`.

Automatically the last digit will increment.

To increment the first digit, use: `autonumber inc A`. To increment the second digit, use: `autonumber inc B`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgce494884d6a0c98eb28acc10e38c2b35" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ce494884d6a0c98eb28acc10e38c2b35')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ce494884d6a0c98eb28acc10e38c2b35')"></td><td><div onclick="javascript:ljs('ce494884d6a0c98eb28acc10e38c2b35')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prece494884d6a0c98eb28acc10e38c2b35"><code onmouseover="az=1" onmouseout="az=0">@startuml
autonumber 1.1.1
Alice -&gt; Bob: Authentication request
Bob --&gt; Alice: Response

autonumber inc A
'Now we have 2.1.1
Alice -&gt; Bob: Another authentication request
Bob --&gt; Alice: Response

autonumber inc B
'Now we have 2.2.1
Alice -&gt; Bob: Another authentication request
Bob --&gt; Alice: Response

autonumber inc A
'Now we have 3.1.1
Alice -&gt; Bob: Another authentication request
autonumber inc B
'Now we have 3.2.1
Bob --&gt; Alice: Response
@enduml
</code></pre><p></p><p><img loading="lazy" width="285" height="336" src="https://plantuml.com/imgw/img-ce494884d6a0c98eb28acc10e38c2b35.png"></p></div></td></tr></tbody></table>

You can also use the value of `autonumber` with the `%autonumber%` variable:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img44322191c2904aca09fc9aa650cec4fd" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('44322191c2904aca09fc9aa650cec4fd')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('44322191c2904aca09fc9aa650cec4fd')"></td><td><div onclick="javascript:ljs('44322191c2904aca09fc9aa650cec4fd')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre44322191c2904aca09fc9aa650cec4fd"><code onmouseover="az=1" onmouseout="az=0">@startuml
autonumber 10
Alice -&gt; Bob
note right
  the &lt;U+0025&gt;autonumber&lt;U+0025&gt; works everywhere.
  Here, its value is ** %autonumber% **
end note
Bob --&gt; Alice: //This is the response %autonumber%//
@enduml
</code></pre><p></p><p><img loading="lazy" width="462" height="176" src="https://plantuml.com/imgw/img-44322191c2904aca09fc9aa650cec4fd.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-7119](https://forum.plantuml.net/7119/create-links-after-creating-a-diagram?show=7137#a7137)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Page Title, Header and Footer

The `title` keyword is used to add a title to the page.

Pages can display headers and footers using `header` and `footer`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgfdf305e9636299c247fcd6056ff5e9ee" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('fdf305e9636299c247fcd6056ff5e9ee')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('fdf305e9636299c247fcd6056ff5e9ee')"></td><td><div onclick="javascript:ljs('fdf305e9636299c247fcd6056ff5e9ee')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prefdf305e9636299c247fcd6056ff5e9ee"><code onmouseover="az=1" onmouseout="az=0">@startuml

header Page Header
footer Page %page% of %lastpage%

title Example Title

Alice -&gt; Bob : message 1
Alice -&gt; Bob : message 2

@enduml
</code></pre><p></p><p><img loading="lazy" width="145" height="222" src="https://plantuml.com/imgw/img-fdf305e9636299c247fcd6056ff5e9ee.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Splitting diagrams

### With `newpage`

The `newpage` keyword is used to split a diagram into several images.

You can put a title for the new page just after the `newpage` keyword. This title overrides the previously specified title if any.

This is very handy with _Word_ to print long diagram on several pages.

(Note: this really does work. Only the first page is shown below, but it is a display artifact.)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0eb880e5cc965f9cc6883f01a82ec94b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0eb880e5cc965f9cc6883f01a82ec94b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0eb880e5cc965f9cc6883f01a82ec94b')"></td><td><div onclick="javascript:ljs('0eb880e5cc965f9cc6883f01a82ec94b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0eb880e5cc965f9cc6883f01a82ec94b"><code onmouseover="az=1" onmouseout="az=0">@startuml

Alice -&gt; Bob : message 1
Alice -&gt; Bob : message 2

newpage

Alice -&gt; Bob : message 3
Alice -&gt; Bob : message 4

newpage A title for the\nlast page

Alice -&gt; Bob : message 5
Alice -&gt; Bob : message 6
@enduml
</code></pre><p></p><p><img loading="lazy" width="145" height="154" src="https://plantuml.com/imgw/img-0eb880e5cc965f9cc6883f01a82ec94b.png"></p></div></td></tr></tbody></table>

### `%page%` and `%lastpage%` variables

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img09009ac0fd730df8d95e8a90a944526c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('09009ac0fd730df8d95e8a90a944526c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('09009ac0fd730df8d95e8a90a944526c')"></td><td><div onclick="javascript:ljs('09009ac0fd730df8d95e8a90a944526c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre09009ac0fd730df8d95e8a90a944526c"><code onmouseover="az=1" onmouseout="az=0">@startuml
footer This is %page% of %lastpage%
Alice --&gt; Bob : A1
newpage
Alice --&gt; Bob : A2
newpage
Alice --&gt; Bob : A3
newpage
Alice --&gt; Bob : A4
@enduml
</code></pre><p></p><p><img loading="lazy" width="109" height="141" src="https://plantuml.com/imgw/img-09009ac0fd730df8d95e8a90a944526c.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-6699](https://forum.plantuml.net/6699/please-provide-macros-insert-current-number-total-number-pages)\]_

### Ignore newpage

You can use the `ignore newpage` command to show all the pages, as if there was no newpage.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img537e4f595efad3601f7a76daccdecdae" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('537e4f595efad3601f7a76daccdecdae')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('537e4f595efad3601f7a76daccdecdae')"></td><td><div onclick="javascript:ljs('537e4f595efad3601f7a76daccdecdae')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre537e4f595efad3601f7a76daccdecdae"><code onmouseover="az=1" onmouseout="az=0">@startuml

ignore newpage

Alice -&gt; Bob : message 1
Alice -&gt; Bob : message 2

newpage

Alice -&gt; Bob : message 3
Alice -&gt; Bob : message 4

newpage A title for the\nlast page

Alice -&gt; Bob : message 5
Alice -&gt; Bob : message 6
@enduml
</code></pre><p></p><p><img loading="lazy" width="139" height="275" src="https://plantuml.com/imgw/img-537e4f595efad3601f7a76daccdecdae.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Grouping message

It is possible to group messages together using the following keywords:

-   `alt/else`
-   `opt`
-   `loop`
-   `par`
-   `break`
-   `critical`
-   `group`, followed by a text to be displayed

It is possible to add a text that will be displayed into the header (for `group`, see next paragraph _'Secondary group label'_).

The `end` keyword is used to close the group.

Note that it is possible to nest groups.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img66b9da900fd754863b6a937eee85575f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('66b9da900fd754863b6a937eee85575f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('66b9da900fd754863b6a937eee85575f')"></td><td><div onclick="javascript:ljs('66b9da900fd754863b6a937eee85575f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre66b9da900fd754863b6a937eee85575f"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice -&gt; Bob: Authentication Request

alt successful case

    Bob -&gt; Alice: Authentication Accepted

else some kind of failure

    Bob -&gt; Alice: Authentication Failure
    group My own label
    Alice -&gt; Log : Log attack start
        loop 1000 times
            Alice -&gt; Bob: DNS Attack
        end
    Alice -&gt; Log : Log attack end
    end

else Another type of failure

   Bob -&gt; Alice: Please repeat

end
@enduml
</code></pre><p></p><p><img loading="lazy" width="319" height="434" src="https://plantuml.com/imgw/img-66b9da900fd754863b6a937eee85575f.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Secondary group label

For `group`, it is possible to add, between`[` and `]`, a secondary text or label that will be displayed into the header.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img61d205a7705d42ffe845829445f854bb" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('61d205a7705d42ffe845829445f854bb')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('61d205a7705d42ffe845829445f854bb')"></td><td><div onclick="javascript:ljs('61d205a7705d42ffe845829445f854bb')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre61d205a7705d42ffe845829445f854bb"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice -&gt; Bob: Authentication Request
Bob -&gt; Alice: Authentication Failure
group My own label [My own label 2]
    Alice -&gt; Log : Log attack start
    loop 1000 times
        Alice -&gt; Bob: DNS Attack
    end
    Alice -&gt; Log : Log attack end
end
@enduml
</code></pre><p></p><p><img loading="lazy" width="292" height="309" src="https://plantuml.com/imgw/img-61d205a7705d42ffe845829445f854bb.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-2503](https://forum.plantuml.net/2503)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Notes on messages

It is possible to put notes on message using the `note left` or `note right` keywords _just after the message_.

You can have a multi-line note using the `end note` keywords.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img2e6afa43a776f0b8695c1ccb1bb607ad" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('2e6afa43a776f0b8695c1ccb1bb607ad')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('2e6afa43a776f0b8695c1ccb1bb607ad')"></td><td><div onclick="javascript:ljs('2e6afa43a776f0b8695c1ccb1bb607ad')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre2e6afa43a776f0b8695c1ccb1bb607ad"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice-&gt;Bob : hello
note left: this is a first note

Bob-&gt;Alice : ok
note right: this is another note

Bob-&gt;Bob : I am thinking
note left
a note
can also be defined
on several lines
end note
@enduml
</code></pre><p></p><p><img loading="lazy" width="320" height="234" src="https://plantuml.com/imgw/img-2e6afa43a776f0b8695c1ccb1bb607ad.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Some other notes

It is also possible to place notes relative to participant with `note left of` , `note right of` or `note over` keywords.

It is possible to highlight a note by changing its background [color](https://plantuml.com/en/color).

You can also have a multi-line note using the `end note` keywords.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img56ab18e86692a68dd51aacd580ceb830" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('56ab18e86692a68dd51aacd580ceb830')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('56ab18e86692a68dd51aacd580ceb830')"></td><td><div onclick="javascript:ljs('56ab18e86692a68dd51aacd580ceb830')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre56ab18e86692a68dd51aacd580ceb830"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice
participant Bob
note left of Alice #aqua
This is displayed
left of Alice.
end note

note right of Alice: This is displayed right of Alice.

note over Alice: This is displayed over Alice.

note over Alice, Bob #FFAAAA: This is displayed\n over Bob and Alice.

note over Bob, Alice
This is yet another
example of
a long note.
end note
@enduml
</code></pre><p></p><p><img loading="lazy" width="332" height="340" src="https://plantuml.com/imgw/img-56ab18e86692a68dd51aacd580ceb830.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Changing notes shape \[hnote, rnote\]

You can use `hnote` and `rnote` keywords to change note shapes :

-   `hnote` for hexagonal note;
-   `rnote` for rectangle note.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img8614c2d10131b6d07e71ee61896c187b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('8614c2d10131b6d07e71ee61896c187b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('8614c2d10131b6d07e71ee61896c187b')"></td><td><div onclick="javascript:ljs('8614c2d10131b6d07e71ee61896c187b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre8614c2d10131b6d07e71ee61896c187b"><code onmouseover="az=1" onmouseout="az=0">@startuml
caller -&gt; server : conReq
hnote over caller : idle
caller &lt;- server : conConf
rnote over server
 "r" as rectangle
 "h" as hexagon
endrnote
rnote over server
 this is
 on several
 lines
endrnote
hnote over caller
 this is
 on several
 lines
endhnote
@enduml
</code></pre><p></p><p><img loading="lazy" width="171" height="373" src="https://plantuml.com/imgw/img-8614c2d10131b6d07e71ee61896c187b.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-1765](https://forum.plantuml.net/1765/is-it-possible-to-have-different-shapes-for-notes?show=1806#c1806)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Note over all participants \[across\]

You can directly make a note over all participants, with the syntax:

-   `note across: note_description`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd05b15c25506f54e15acc3a938b6fe78" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d05b15c25506f54e15acc3a938b6fe78')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d05b15c25506f54e15acc3a938b6fe78')"></td><td><div onclick="javascript:ljs('d05b15c25506f54e15acc3a938b6fe78')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred05b15c25506f54e15acc3a938b6fe78"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice-&gt;Bob:m1
Bob-&gt;Charlie:m2
note over Alice, Charlie: Old method for note over all part. with:\n ""note over //FirstPart, LastPart//"".
note across: New method with:\n""note across""
Bob-&gt;Alice
hnote across:Note across all part.
@enduml
</code></pre><p></p><p><img loading="lazy" width="265" height="308" src="https://plantuml.com/imgw/img-d05b15c25506f54e15acc3a938b6fe78.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-9738](https://forum.plantuml.net/9738)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Several notes aligned at the same level \[/\]

You can make several notes aligned at the same level, with the syntax `/`:

-   without `/` _(by default, the notes are not aligned)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc51b2e71aac64d8aab81df8f008a90f2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c51b2e71aac64d8aab81df8f008a90f2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c51b2e71aac64d8aab81df8f008a90f2')"></td><td><div onclick="javascript:ljs('c51b2e71aac64d8aab81df8f008a90f2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec51b2e71aac64d8aab81df8f008a90f2"><code onmouseover="az=1" onmouseout="az=0">@startuml
note over Alice : initial state of Alice
note over Bob : initial state of Bob
Bob -&gt; Alice : hello
@enduml
</code></pre><p></p><p><img loading="lazy" width="187" height="196" src="https://plantuml.com/imgw/img-c51b2e71aac64d8aab81df8f008a90f2.png"></p></div></td></tr></tbody></table>

-   with `/` _(the notes are aligned)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga47c700bdaf8f153d83507eda36940ad" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a47c700bdaf8f153d83507eda36940ad')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a47c700bdaf8f153d83507eda36940ad')"></td><td><div onclick="javascript:ljs('a47c700bdaf8f153d83507eda36940ad')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea47c700bdaf8f153d83507eda36940ad"><code onmouseover="az=1" onmouseout="az=0">@startuml
note over Alice : initial state of Alice
/ note over Bob : initial state of Bob
Bob -&gt; Alice : hello
@enduml
</code></pre><p></p><p><img loading="lazy" width="272" height="159" src="https://plantuml.com/imgw/img-a47c700bdaf8f153d83507eda36940ad.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-354](https://forum.plantuml.net/354)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Creole and HTML

[It is also possible to use creole formatting:](https://plantuml.com/en/creole)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf171e43c8ab5d73a9dc9a384c4e44900" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f171e43c8ab5d73a9dc9a384c4e44900')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f171e43c8ab5d73a9dc9a384c4e44900')"></td><td><div onclick="javascript:ljs('f171e43c8ab5d73a9dc9a384c4e44900')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref171e43c8ab5d73a9dc9a384c4e44900"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice
participant "The **Famous** Bob" as Bob

Alice -&gt; Bob : hello --there--
... Some ~~long delay~~ ...
Bob -&gt; Alice : ok
note left
  This is **bold**
  This is //italics//
  This is ""monospaced""
  This is --stroked--
  This is __underlined__
  This is ~~waved~~
end note

Alice -&gt; Bob : A //well formatted// message
note right of Alice
 This is &lt;back:cadetblue&gt;&lt;size:18&gt;displayed&lt;/size&gt;&lt;/back&gt;
 __left of__ Alice.
end note
note left of Bob
 &lt;u:red&gt;This&lt;/u&gt; is &lt;color #118888&gt;displayed&lt;/color&gt;
 **&lt;color purple&gt;left of&lt;/color&gt; &lt;s:red&gt;Alice&lt;/strike&gt; Bob**.
end note
note over Alice, Bob
 &lt;w:#FF33FF&gt;This is hosted&lt;/w&gt; by &lt;img:https://plantuml.com/sourceforge.jpg&gt;
end note
@enduml
</code></pre><p></p><p><img loading="lazy" width="390" height="477" src="https://plantuml.com/imgw/img-f171e43c8ab5d73a9dc9a384c4e44900.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Divider or separator

If you want, you can split a diagram using `==` separator to divide your diagram into logical steps.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img248b34e320e6f530c10dfb3cc7d66bd0" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('248b34e320e6f530c10dfb3cc7d66bd0')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('248b34e320e6f530c10dfb3cc7d66bd0')"></td><td><div onclick="javascript:ljs('248b34e320e6f530c10dfb3cc7d66bd0')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre248b34e320e6f530c10dfb3cc7d66bd0"><code onmouseover="az=1" onmouseout="az=0">@startuml

== Initialization ==

Alice -&gt; Bob: Authentication Request
Bob --&gt; Alice: Authentication Response

== Repetition ==

Alice -&gt; Bob: Another authentication Request
Alice &lt;-- Bob: another authentication Response

@enduml
</code></pre><p></p><p><img loading="lazy" width="272" height="303" src="https://plantuml.com/imgw/img-248b34e320e6f530c10dfb3cc7d66bd0.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Reference

You can use reference in a diagram, using the keyword `ref over`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf0ba8b4f0ff98f6948b7741c8c799314" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f0ba8b4f0ff98f6948b7741c8c799314')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f0ba8b4f0ff98f6948b7741c8c799314')"></td><td><div onclick="javascript:ljs('f0ba8b4f0ff98f6948b7741c8c799314')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref0ba8b4f0ff98f6948b7741c8c799314"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice
actor Bob

ref over Alice, Bob : init

Alice -&gt; Bob : hello

ref over Bob
  This can be on
  several lines
end ref
@enduml
</code></pre><p></p><p><img loading="lazy" width="151" height="322" src="https://plantuml.com/imgw/img-f0ba8b4f0ff98f6948b7741c8c799314.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Delay

You can use `...` to indicate a delay in the diagram. And it is also possible to put a message with this delay.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd6530b6b301b55119ea0fd569afdf544" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d6530b6b301b55119ea0fd569afdf544')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d6530b6b301b55119ea0fd569afdf544')"></td><td><div onclick="javascript:ljs('d6530b6b301b55119ea0fd569afdf544')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred6530b6b301b55119ea0fd569afdf544"><code onmouseover="az=1" onmouseout="az=0">@startuml

Alice -&gt; Bob: Authentication Request
...
Bob --&gt; Alice: Authentication Response
...5 minutes later...
Bob --&gt; Alice: Good Bye !

@enduml
</code></pre><p></p><p><img loading="lazy" width="220" height="254" src="https://plantuml.com/imgw/img-d6530b6b301b55119ea0fd569afdf544.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Text wrapping

To break long messages, you can manually add `\n` in your text.

Another option is to use `maxMessageSize` setting:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img13e306d033bdbc28d530e050f022e0af" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('13e306d033bdbc28d530e050f022e0af')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('13e306d033bdbc28d530e050f022e0af')"></td><td><div onclick="javascript:ljs('13e306d033bdbc28d530e050f022e0af')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre13e306d033bdbc28d530e050f022e0af"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam maxMessageSize 50
participant a
participant b
a -&gt; b :this\nis\nmanually\ndone
a -&gt; b :this is a very long message on several words
@enduml
</code></pre><p></p><p><img loading="lazy" width="108" height="301" src="https://plantuml.com/imgw/img-13e306d033bdbc28d530e050f022e0af.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Space

You can use `|||` to indicate some spacing in the diagram.

It is also possible to specify a number of pixel to be used.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img446a181ef57657a86ebb7f32b9d8e99e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('446a181ef57657a86ebb7f32b9d8e99e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('446a181ef57657a86ebb7f32b9d8e99e')"></td><td><div onclick="javascript:ljs('446a181ef57657a86ebb7f32b9d8e99e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre446a181ef57657a86ebb7f32b9d8e99e"><code onmouseover="az=1" onmouseout="az=0">@startuml

Alice -&gt; Bob: message 1
Bob --&gt; Alice: ok
|||
Alice -&gt; Bob: message 2
Bob --&gt; Alice: ok
||45||
Alice -&gt; Bob: message 3
Bob --&gt; Alice: ok

@enduml
</code></pre><p></p><p><img loading="lazy" width="139" height="345" src="https://plantuml.com/imgw/img-446a181ef57657a86ebb7f32b9d8e99e.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Lifeline Activation and Destruction

The `activate` and `deactivate` are used to denote participant activation.

Once a participant is activated, its lifeline appears.

The `activate` and `deactivate` apply on the previous message.

The `destroy` denote the end of the lifeline of a participant.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf4b0b67c3dd1c8c30c8283057c3ee4f4" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f4b0b67c3dd1c8c30c8283057c3ee4f4')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f4b0b67c3dd1c8c30c8283057c3ee4f4')"></td><td><div onclick="javascript:ljs('f4b0b67c3dd1c8c30c8283057c3ee4f4')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref4b0b67c3dd1c8c30c8283057c3ee4f4"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant User

User -&gt; A: DoWork
activate A

A -&gt; B: &lt;&lt; createRequest &gt;&gt;
activate B

B -&gt; C: DoWork
activate C
C --&gt; B: WorkDone
destroy C

B --&gt; A: RequestCreated
deactivate B

A -&gt; User: Done
deactivate A

@enduml
</code></pre><p></p><p><img loading="lazy" width="338" height="275" src="https://plantuml.com/imgw/img-f4b0b67c3dd1c8c30c8283057c3ee4f4.png"></p></div></td></tr></tbody></table>

Nested lifeline can be used, and it is possible to add a [color](https://plantuml.com/en/color) on the lifeline.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img630a0243bfac076e2c8f36cc5b23f934" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('630a0243bfac076e2c8f36cc5b23f934')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('630a0243bfac076e2c8f36cc5b23f934')"></td><td><div onclick="javascript:ljs('630a0243bfac076e2c8f36cc5b23f934')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre630a0243bfac076e2c8f36cc5b23f934"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant User

User -&gt; A: DoWork
activate A #FFBBBB

A -&gt; A: Internal call
activate A #DarkSalmon

A -&gt; B: &lt;&lt; createRequest &gt;&gt;
activate B

B --&gt; A: RequestCreated
deactivate B
deactivate A
A -&gt; User: Done
deactivate A

@enduml
</code></pre><p></p><p><img loading="lazy" width="248" height="257" src="https://plantuml.com/imgw/img-630a0243bfac076e2c8f36cc5b23f934.png"></p></div></td></tr></tbody></table>

Autoactivation is possible and works with the return keywords:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9b5e31d569667a0bcde2766506b5f015" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9b5e31d569667a0bcde2766506b5f015')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9b5e31d569667a0bcde2766506b5f015')"></td><td><div onclick="javascript:ljs('9b5e31d569667a0bcde2766506b5f015')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9b5e31d569667a0bcde2766506b5f015"><code onmouseover="az=1" onmouseout="az=0">@startuml
autoactivate on
alice -&gt; bob : hello
bob -&gt; bob : self call
bill -&gt; bob #005500 : hello from thread 2
bob -&gt; george ** : create
return done in thread 2
return rc
bob -&gt; george !! : delete
return success

@enduml
</code></pre><p></p><p><img loading="lazy" width="332" height="374" src="https://plantuml.com/imgw/img-9b5e31d569667a0bcde2766506b5f015.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Return

Command `return` generates a return message with optional text label.

The return point is that which caused the most recent life-line activation.

The syntax is `return label` where `label` if provided is any string acceptable for conventional messages.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0c1235b8a60efc32ed9563212370edd7" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0c1235b8a60efc32ed9563212370edd7')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0c1235b8a60efc32ed9563212370edd7')"></td><td><div onclick="javascript:ljs('0c1235b8a60efc32ed9563212370edd7')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0c1235b8a60efc32ed9563212370edd7"><code onmouseover="az=1" onmouseout="az=0">@startuml
Bob -&gt; Alice : hello
activate Alice
Alice -&gt; Alice : some action
return bye
@enduml
</code></pre><p></p><p><img loading="lazy" width="164" height="197" src="https://plantuml.com/imgw/img-0c1235b8a60efc32ed9563212370edd7.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Participant creation

You can use the `create` keyword just before the first reception of a message to emphasize the fact that this message is actually _creating_ this new object.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img406b00f3e05f486281be7dfb659696c3" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('406b00f3e05f486281be7dfb659696c3')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('406b00f3e05f486281be7dfb659696c3')"></td><td><div onclick="javascript:ljs('406b00f3e05f486281be7dfb659696c3')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre406b00f3e05f486281be7dfb659696c3"><code onmouseover="az=1" onmouseout="az=0">@startuml
Bob -&gt; Alice : hello

create Other
Alice -&gt; Other : new

create control String
Alice -&gt; String
note right : You can also put notes!

Alice --&gt; Bob : ok

@enduml
</code></pre><p></p><p><img loading="lazy" width="392" height="287" src="https://plantuml.com/imgw/img-406b00f3e05f486281be7dfb659696c3.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Shortcut syntax for activation, deactivation, creation

Immediately after specifying the target participant, the following syntax can be used:

-   `++` Activate the target (optionally a [color](https://plantuml.com/en/color) may follow this)
-   `--` Deactivate the source
-   `**` Create an instance of the target
-   `!!` Destroy an instance of the target

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7d9f75a638a60bc4e5f295d0f842ba88" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7d9f75a638a60bc4e5f295d0f842ba88')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7d9f75a638a60bc4e5f295d0f842ba88')"></td><td><div onclick="javascript:ljs('7d9f75a638a60bc4e5f295d0f842ba88')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7d9f75a638a60bc4e5f295d0f842ba88"><code onmouseover="az=1" onmouseout="az=0">@startuml
alice -&gt; bob ++ : hello
bob -&gt; bob ++ : self call
bob -&gt; bib ++  #005500 : hello
bob -&gt; george ** : create
return done
return rc
bob -&gt; george !! : delete
return success
@enduml
</code></pre><p></p><p><img loading="lazy" width="271" height="374" src="https://plantuml.com/imgw/img-7d9f75a638a60bc4e5f295d0f842ba88.png"></p></div></td></tr></tbody></table>

Then you can mix activation and deactivation, on same line:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb9830b761be097ea6cb34f4120c87153" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b9830b761be097ea6cb34f4120c87153')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b9830b761be097ea6cb34f4120c87153')"></td><td><div onclick="javascript:ljs('b9830b761be097ea6cb34f4120c87153')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb9830b761be097ea6cb34f4120c87153"><code onmouseover="az=1" onmouseout="az=0">@startuml
alice   -&gt;  bob     ++   : hello1
bob     -&gt;  charlie --++ : hello2
charlie --&gt; alice   --   : ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="181" height="184" src="https://plantuml.com/imgw/img-b9830b761be097ea6cb34f4120c87153.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgcd700c0c2e52eb5693cc9f6577797a1a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('cd700c0c2e52eb5693cc9f6577797a1a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('cd700c0c2e52eb5693cc9f6577797a1a')"></td><td><div onclick="javascript:ljs('cd700c0c2e52eb5693cc9f6577797a1a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="precd700c0c2e52eb5693cc9f6577797a1a"><code onmouseover="az=1" onmouseout="az=0">@startuml
alice -&gt; bob   --++ #gold: hello
bob   -&gt; alice --++ #gold: you too
alice -&gt; bob   --: step1
alice -&gt; bob   : step2
@enduml
</code></pre><p></p><p><img loading="lazy" width="121" height="214" src="https://plantuml.com/imgw/img-cd700c0c2e52eb5693cc9f6577797a1a.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-4834](https://forum.plantuml.net/4834/activation-shorthand-for-sequence-diagrams?show=13054#c13054), [QA-9573](https://forum.plantuml.net/9573) and [QA-13234](https://forum.plantuml.net/13234)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Incoming and outgoing messages

You can use incoming or outgoing arrows if you want to focus on a part of the diagram.

Use square brackets to denote the left "`[`" or the right "`]`" side of the diagram.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img872840ee0bd87257216a7ab19193d39f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('872840ee0bd87257216a7ab19193d39f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('872840ee0bd87257216a7ab19193d39f')"></td><td><div onclick="javascript:ljs('872840ee0bd87257216a7ab19193d39f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre872840ee0bd87257216a7ab19193d39f"><code onmouseover="az=1" onmouseout="az=0">@startuml
[-&gt; A: DoWork

activate A

A -&gt; A: Internal call
activate A

A -&gt;] : &lt;&lt; createRequest &gt;&gt;

A&lt;--] : RequestCreated
deactivate A
[&lt;- A: Done
deactivate A
@enduml
</code></pre><p></p><p><img loading="lazy" width="208" height="257" src="https://plantuml.com/imgw/img-872840ee0bd87257216a7ab19193d39f.png"></p></div></td></tr></tbody></table>

You can also have the following syntax:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0d4fa0fdb41891912342a73875c60609" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0d4fa0fdb41891912342a73875c60609')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0d4fa0fdb41891912342a73875c60609')"></td><td><div onclick="javascript:ljs('0d4fa0fdb41891912342a73875c60609')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0d4fa0fdb41891912342a73875c60609"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice
participant Bob #lightblue
Alice -&gt; Bob
Bob -&gt; Carol
...
[-&gt; Bob
[o-&gt; Bob
[o-&gt;o Bob
[x-&gt; Bob
...
[&lt;- Bob
[x&lt;- Bob
...
Bob -&gt;]
Bob -&gt;o]
Bob o-&gt;o]
Bob -&gt;x]
...
Bob &lt;-]
Bob x&lt;-]

@enduml
</code></pre><p></p><p><img loading="lazy" width="165" height="401" src="https://plantuml.com/imgw/img-0d4fa0fdb41891912342a73875c60609.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Short arrows for incoming and outgoing messages

You can have **short** arrows with using `?`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5178d9496f6211b4a26e3151a9c4c6dd" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5178d9496f6211b4a26e3151a9c4c6dd')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5178d9496f6211b4a26e3151a9c4c6dd')"></td><td><div onclick="javascript:ljs('5178d9496f6211b4a26e3151a9c4c6dd')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5178d9496f6211b4a26e3151a9c4c6dd"><code onmouseover="az=1" onmouseout="az=0">@startuml
?-&gt; Alice    : ""?-&gt;""\n**short** to actor1
[-&gt; Alice    : ""[-&gt;""\n**from start** to actor1
[-&gt; Bob      : ""[-&gt;""\n**from start** to actor2
?-&gt; Bob      : ""?-&gt;""\n**short** to actor2
Alice -&gt;]    : ""-&gt;]""\nfrom actor1 **to end**
Alice -&gt;?    : ""-&gt;?""\n**short** from actor1
Alice -&gt; Bob : ""-&gt;"" \nfrom actor1 to actor2
@enduml
</code></pre><p></p><p><img loading="lazy" width="307" height="424" src="https://plantuml.com/imgw/img-5178d9496f6211b4a26e3151a9c4c6dd.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-310](https://forum.plantuml.net/310)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Anchors and Duration

With `teoz` it is possible to add anchors to the diagram and use the anchors to specify duration time.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf3e97cd9412ffa04a5c68585e378b40d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f3e97cd9412ffa04a5c68585e378b40d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f3e97cd9412ffa04a5c68585e378b40d')"></td><td><div onclick="javascript:ljs('f3e97cd9412ffa04a5c68585e378b40d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref3e97cd9412ffa04a5c68585e378b40d"><code onmouseover="az=1" onmouseout="az=0">@startuml
!pragma teoz true

{start} Alice -&gt; Bob : start doing things during duration
Bob -&gt; Max : something
Max -&gt; Bob : something else
{end} Bob -&gt; Alice : finish

{start} &lt;-&gt; {end} : some time

@enduml
</code></pre><p></p><p><img loading="lazy" width="377" height="213" src="https://plantuml.com/imgw/img-f3e97cd9412ffa04a5c68585e378b40d.png"></p></div></td></tr></tbody></table>

You can use the `-P` [command-line](https://plantuml.com/en/command-line) option to specify the pragma:

```
java -jar plantuml.jar -Pteoz=true
```

_\[Ref. [issue-582](https://github.com/plantuml/plantuml/issues/582)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Stereotypes and Spots

It is possible to add stereotypes to participants using `<<` and `>>`.

In the stereotype, you can add a spotted character in a colored circle using the syntax `(X,color)`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img575004fdc8f5d8904223ebaaf956bd9b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('575004fdc8f5d8904223ebaaf956bd9b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('575004fdc8f5d8904223ebaaf956bd9b')"></td><td><div onclick="javascript:ljs('575004fdc8f5d8904223ebaaf956bd9b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre575004fdc8f5d8904223ebaaf956bd9b"><code onmouseover="az=1" onmouseout="az=0">@startuml

participant "Famous Bob" as Bob &lt;&lt; Generated &gt;&gt;
participant Alice &lt;&lt; (C,#ADD1B2) Testable &gt;&gt;

Bob-&gt;Alice: First message

@enduml
</code></pre><p></p><p><img loading="lazy" width="226" height="158" src="https://plantuml.com/imgw/img-575004fdc8f5d8904223ebaaf956bd9b.png"></p></div></td></tr></tbody></table>

By default, the _guillemet_ character is used to display the stereotype. You can change this behavious using the skinparam `guillemet`:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img889c8d0f7a5f42702b4130148fd980da" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('889c8d0f7a5f42702b4130148fd980da')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('889c8d0f7a5f42702b4130148fd980da')"></td><td><div onclick="javascript:ljs('889c8d0f7a5f42702b4130148fd980da')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre889c8d0f7a5f42702b4130148fd980da"><code onmouseover="az=1" onmouseout="az=0">@startuml

skinparam guillemet false
participant "Famous Bob" as Bob &lt;&lt; Generated &gt;&gt;
participant Alice &lt;&lt; (C,#ADD1B2) Testable &gt;&gt;

Bob-&gt;Alice: First message

@enduml
</code></pre><p></p><p><img loading="lazy" width="276" height="158" src="https://plantuml.com/imgw/img-889c8d0f7a5f42702b4130148fd980da.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgca7fea05854101635b4c991adf270b9f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ca7fea05854101635b4c991adf270b9f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ca7fea05854101635b4c991adf270b9f')"></td><td><div onclick="javascript:ljs('ca7fea05854101635b4c991adf270b9f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preca7fea05854101635b4c991adf270b9f"><code onmouseover="az=1" onmouseout="az=0">@startuml

participant Bob &lt;&lt; (C,#ADD1B2) &gt;&gt;
participant Alice &lt;&lt; (C,#ADD1B2) &gt;&gt;

Bob-&gt;Alice: First message

@enduml
</code></pre><p></p><p><img loading="lazy" width="185" height="132" src="https://plantuml.com/imgw/img-ca7fea05854101635b4c991adf270b9f.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Position of the stereotypes

It is possible to define stereotypes position (`top` or `bottom`) with the command `skinparam stereotypePosition`.

### Top postion _(by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd3a65857848ef8994c0eff4d165d6712" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d3a65857848ef8994c0eff4d165d6712')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d3a65857848ef8994c0eff4d165d6712')"></td><td><div onclick="javascript:ljs('d3a65857848ef8994c0eff4d165d6712')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred3a65857848ef8994c0eff4d165d6712"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam stereotypePosition top

participant A&lt;&lt;st1&gt;&gt;
participant B&lt;&lt;st2&gt;&gt;
A --&gt; B : stereo test
@enduml
</code></pre><p></p><p><img loading="lazy" width="142" height="158" src="https://plantuml.com/imgw/img-d3a65857848ef8994c0eff4d165d6712.png"></p></div></td></tr></tbody></table>

### Bottom postion

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf46856f3edf4a5a1bcd9a73145f842cf" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f46856f3edf4a5a1bcd9a73145f842cf')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f46856f3edf4a5a1bcd9a73145f842cf')"></td><td><div onclick="javascript:ljs('f46856f3edf4a5a1bcd9a73145f842cf')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref46856f3edf4a5a1bcd9a73145f842cf"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam stereotypePosition bottom

participant A&lt;&lt;st1&gt;&gt;
participant B&lt;&lt;st2&gt;&gt;
A --&gt; B : stereo test
@enduml
</code></pre><p></p><p><img loading="lazy" width="142" height="158" src="https://plantuml.com/imgw/img-f46856f3edf4a5a1bcd9a73145f842cf.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-18650](https://forum.plantuml.net/18650/example-related-stereotypeposition-guide-please-skinparam)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")More information on titles

You can use [creole formatting](https://plantuml.com/en/creole) in the title.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7a4f948a1a49fb637209eec7bf8043cf" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7a4f948a1a49fb637209eec7bf8043cf')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7a4f948a1a49fb637209eec7bf8043cf')"></td><td><div onclick="javascript:ljs('7a4f948a1a49fb637209eec7bf8043cf')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7a4f948a1a49fb637209eec7bf8043cf"><code onmouseover="az=1" onmouseout="az=0">@startuml

title __Simple__ **communication** example

Alice -&gt; Bob: Authentication Request
Bob -&gt; Alice: Authentication Response

@enduml
</code></pre><p></p><p><img loading="lazy" width="240" height="192" src="https://plantuml.com/imgw/img-7a4f948a1a49fb637209eec7bf8043cf.png"></p></div></td></tr></tbody></table>

You can add newline using `\n` in the title description.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img824c7b77eb078e76545a5fe05a57eaf3" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('824c7b77eb078e76545a5fe05a57eaf3')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('824c7b77eb078e76545a5fe05a57eaf3')"></td><td><div onclick="javascript:ljs('824c7b77eb078e76545a5fe05a57eaf3')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre824c7b77eb078e76545a5fe05a57eaf3"><code onmouseover="az=1" onmouseout="az=0">@startuml

title __Simple__ communication example\non several lines

Alice -&gt; Bob: Authentication Request
Bob -&gt; Alice: Authentication Response

@enduml
</code></pre><p></p><p><img loading="lazy" width="240" height="210" src="https://plantuml.com/imgw/img-824c7b77eb078e76545a5fe05a57eaf3.png"></p></div></td></tr></tbody></table>

You can also define title on several lines using `title` and `end title` keywords.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4f2914e2ece1257552ca1f4981db6d03" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4f2914e2ece1257552ca1f4981db6d03')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4f2914e2ece1257552ca1f4981db6d03')"></td><td><div onclick="javascript:ljs('4f2914e2ece1257552ca1f4981db6d03')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4f2914e2ece1257552ca1f4981db6d03"><code onmouseover="az=1" onmouseout="az=0">@startuml

title
 &lt;u&gt;Simple&lt;/u&gt; communication example
 on &lt;i&gt;several&lt;/i&gt; lines and using &lt;font color=red&gt;html&lt;/font&gt;
 This is hosted by &lt;img:sourceforge.jpg&gt;
end title

Alice -&gt; Bob: Authentication Request
Bob -&gt; Alice: Authentication Response

@enduml
</code></pre><p></p><p><img loading="lazy" width="271" height="228" src="https://plantuml.com/imgw/img-4f2914e2ece1257552ca1f4981db6d03.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Participants encompass

It is possible to draw a box around some participants, using `box` and `end box` commands.

You can add an optional title or a optional background color, after the `box` keyword.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5e29525a00c28c8ea3140e451e96b372" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5e29525a00c28c8ea3140e451e96b372')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5e29525a00c28c8ea3140e451e96b372')"></td><td><div onclick="javascript:ljs('5e29525a00c28c8ea3140e451e96b372')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5e29525a00c28c8ea3140e451e96b372"><code onmouseover="az=1" onmouseout="az=0">@startuml

box "Internal Service" #LightBlue
participant Bob
participant Alice
end box
participant Other

Bob -&gt; Alice : hello
Alice -&gt; Other : hello

@enduml
</code></pre><p></p><p><img loading="lazy" width="163" height="180" src="https://plantuml.com/imgw/img-5e29525a00c28c8ea3140e451e96b372.png"></p></div></td></tr></tbody></table>

It is also possible to nest boxes - to draw a box within a box - when using the teoz rendering engine, for example:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga9f4718bd1ed6856578e73f6d6812d39" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a9f4718bd1ed6856578e73f6d6812d39')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a9f4718bd1ed6856578e73f6d6812d39')"></td><td><div onclick="javascript:ljs('a9f4718bd1ed6856578e73f6d6812d39')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea9f4718bd1ed6856578e73f6d6812d39"><code onmouseover="az=1" onmouseout="az=0">@startuml

!pragma teoz true
box "Internal Service" #LightBlue
participant Bob
box "Subteam"
participant Alice
participant John
end box

end box
participant Other

Bob -&gt; Alice : hello
Alice -&gt; John : hello
John -&gt; Other: Hello

@enduml
</code></pre><p></p><p><img loading="lazy" width="236" height="232" src="https://plantuml.com/imgw/img-a9f4718bd1ed6856578e73f6d6812d39.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Removing Foot Boxes

You can use the `hide footbox` keywords to remove the foot boxes of the diagram.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img320779dabcfefa01dfae4fc6e13ff4e1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('320779dabcfefa01dfae4fc6e13ff4e1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('320779dabcfefa01dfae4fc6e13ff4e1')"></td><td><div onclick="javascript:ljs('320779dabcfefa01dfae4fc6e13ff4e1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre320779dabcfefa01dfae4fc6e13ff4e1"><code onmouseover="az=1" onmouseout="az=0">@startuml

hide footbox
title Foot Box removed

Alice -&gt; Bob: Authentication Request
Bob --&gt; Alice: Authentication Response

@enduml
</code></pre><p></p><p><img loading="lazy" width="220" height="162" src="https://plantuml.com/imgw/img-320779dabcfefa01dfae4fc6e13ff4e1.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Skinparam

You can use the [skinparam](https://plantuml.com/en/skinparam) command to change colors and fonts for the drawing.

You can use this command:

-   In the diagram definition, like any other commands,
-   In an [included file](https://plantuml.com/en/preprocessing),
-   In a configuration file, provided in the [command line](https://plantuml.com/en/command-line) or the [ANT task](https://plantuml.com/en/ant-task).

You can also change other rendering parameter, as seen in the following examples:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img55f0d144a52b8d1fa23edcc8d4320a7f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('55f0d144a52b8d1fa23edcc8d4320a7f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('55f0d144a52b8d1fa23edcc8d4320a7f')"></td><td><div onclick="javascript:ljs('55f0d144a52b8d1fa23edcc8d4320a7f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre55f0d144a52b8d1fa23edcc8d4320a7f"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam sequenceArrowThickness 2
skinparam roundcorner 20
skinparam maxmessagesize 60
skinparam sequenceParticipant underline

actor User
participant "First Class" as A
participant "Second Class" as B
participant "Last Class" as C

User -&gt; A: DoWork
activate A

A -&gt; B: Create Request
activate B

B -&gt; C: DoWork
activate C
C --&gt; B: WorkDone
destroy C

B --&gt; A: Request Created
deactivate B

A --&gt; User: Done
deactivate A

@enduml
</code></pre><p></p><p><img loading="lazy" width="338" height="398" src="https://plantuml.com/imgw/img-55f0d144a52b8d1fa23edcc8d4320a7f.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7065d0c7623a6df29fe7d71d295ee2f4" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7065d0c7623a6df29fe7d71d295ee2f4')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7065d0c7623a6df29fe7d71d295ee2f4')"></td><td><div onclick="javascript:ljs('7065d0c7623a6df29fe7d71d295ee2f4')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7065d0c7623a6df29fe7d71d295ee2f4"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam backgroundColor #EEEBDC
skinparam handwritten true

skinparam sequence {
ArrowColor DeepSkyBlue
ActorBorderColor DeepSkyBlue
LifeLineBorderColor blue
LifeLineBackgroundColor #A9DCDF

ParticipantBorderColor DeepSkyBlue
ParticipantBackgroundColor DodgerBlue
ParticipantFontName Impact
ParticipantFontSize 17
ParticipantFontColor #A9DCDF

ActorBackgroundColor aqua
ActorFontColor DeepSkyBlue
ActorFontSize 17
ActorFontName Aapex
}

actor User
participant "First Class" as A
participant "Second Class" as B
participant "Last Class" as C

User -&gt; A: DoWork
activate A

A -&gt; B: Create Request
activate B

B -&gt; C: DoWork
activate C
C --&gt; B: WorkDone
destroy C

B --&gt; A: Request Created
deactivate B

A --&gt; User: Done
deactivate A

@enduml
</code></pre><p></p><p><img loading="lazy" width="400" height="411" src="https://plantuml.com/imgw/img-7065d0c7623a6df29fe7d71d295ee2f4.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Changing padding

It is possible to tune some padding settings.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img34bf075ef38b7833c2a0c3349b1be908" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('34bf075ef38b7833c2a0c3349b1be908')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('34bf075ef38b7833c2a0c3349b1be908')"></td><td><div onclick="javascript:ljs('34bf075ef38b7833c2a0c3349b1be908')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre34bf075ef38b7833c2a0c3349b1be908"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam ParticipantPadding 20
skinparam BoxPadding 10

box "Foo1"
participant Alice1
participant Alice2
end box
box "Foo2"
participant Bob1
participant Bob2
end box
Alice1 -&gt; Bob1 : hello
Alice1 -&gt; Out : out
@enduml
</code></pre><p></p><p><img loading="lazy" width="504" height="180" src="https://plantuml.com/imgw/img-34bf075ef38b7833c2a0c3349b1be908.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Appendix: Examples of all arrow type

### Normal arrow

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdcf635ca976093112fb49558fb2b758e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('dcf635ca976093112fb49558fb2b758e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('dcf635ca976093112fb49558fb2b758e')"></td><td><div onclick="javascript:ljs('dcf635ca976093112fb49558fb2b758e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predcf635ca976093112fb49558fb2b758e"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice as a
participant Bob   as b
a -&gt;     b : ""-&gt;   ""
a -&gt;&gt;    b : ""-&gt;&gt;  ""
a -\     b : ""-\   ""
a -\\    b : ""-\\\\""
a -/     b : ""-/   ""
a -//    b : ""-//  ""
a -&gt;x    b : ""-&gt;x  ""
a x-&gt;    b : ""x-&gt;  ""
a o-&gt;    b : ""o-&gt;  ""
a -&gt;o    b : ""-&gt;o  ""
a o-&gt;o   b : ""o-&gt;o ""
a &lt;-&gt;    b : ""&lt;-&gt;  ""
a o&lt;-&gt;o  b : ""o&lt;-&gt;o""
a x&lt;-&gt;x  b : ""x&lt;-&gt;x""
a -&gt;&gt;o   b : ""-&gt;&gt;o ""
a -\o    b : ""-\o  ""
a -\\o   b : ""-\\\\o""
a -/o    b : ""-/o  ""
a -//o   b : ""-//o ""
a x-&gt;o   b : ""x-&gt;o ""
@enduml
</code></pre><p></p><p><img loading="lazy" width="114" height="712" src="https://plantuml.com/imgw/img-dcf635ca976093112fb49558fb2b758e.png"></p></div></td></tr></tbody></table>

### Itself arrow

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img43d35cdc635e5f9c5c6fe5073b217597" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('43d35cdc635e5f9c5c6fe5073b217597')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('43d35cdc635e5f9c5c6fe5073b217597')"></td><td><div onclick="javascript:ljs('43d35cdc635e5f9c5c6fe5073b217597')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre43d35cdc635e5f9c5c6fe5073b217597"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice as a
participant Bob   as b
a -&gt;     a : ""-&gt;   ""
a -&gt;&gt;    a : ""-&gt;&gt;  ""
a -\     a : ""-\   ""
a -\\    a : ""-\\\\""
a -/     a : ""-/   ""
a -//    a : ""-//  ""
a -&gt;x    a : ""-&gt;x  ""
a x-&gt;    a : ""x-&gt;  ""
a o-&gt;    a : ""o-&gt;  ""
a -&gt;o    a : ""-&gt;o  ""
a o-&gt;o   a : ""o-&gt;o ""
a &lt;-&gt;    a : ""&lt;-&gt;  ""
a o&lt;-&gt;o  a : ""o&lt;-&gt;o""
a x&lt;-&gt;x  a : ""x&lt;-&gt;x""
a -&gt;&gt;o   a : ""-&gt;&gt;o ""
a -\o    a : ""-\o  ""
a -\\o   a : ""-\\\\o""
a -/o    a : ""-/o  ""
a -//o   a : ""-//o ""
a x-&gt;o   a : ""x-&gt;o ""
@enduml
</code></pre><p></p><p><img loading="lazy" width="104" height="972" src="https://plantuml.com/imgw/img-43d35cdc635e5f9c5c6fe5073b217597.png"></p></div></td></tr></tbody></table>

### Incoming and outgoing messages (with '\[', '\]')

#### Incoming messages (with '\[')

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6ad7e7cebf26032513e0d040fa9650ed" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6ad7e7cebf26032513e0d040fa9650ed')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6ad7e7cebf26032513e0d040fa9650ed')"></td><td><div onclick="javascript:ljs('6ad7e7cebf26032513e0d040fa9650ed')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6ad7e7cebf26032513e0d040fa9650ed"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice as a
participant Bob   as b
[-&gt;      b : ""[-&gt;   ""
[-&gt;&gt;     b : ""[-&gt;&gt;  ""
[-\      b : ""[-\   ""
[-\\     b : ""[-\\\\""
[-/      b : ""[-/   ""
[-//     b : ""[-//  ""
[-&gt;x     b : ""[-&gt;x  ""
[x-&gt;     b : ""[x-&gt;  ""
[o-&gt;     b : ""[o-&gt;  ""
[-&gt;o     b : ""[-&gt;o  ""
[o-&gt;o    b : ""[o-&gt;o ""
[&lt;-&gt;     b : ""[&lt;-&gt;  ""
[o&lt;-&gt;o   b : ""[o&lt;-&gt;o""
[x&lt;-&gt;x   b : ""[x&lt;-&gt;x""
[-&gt;&gt;o    b : ""[-&gt;&gt;o ""
[-\o     b : ""[-\o  ""
[-\\o    b : ""[-\\\\o""
[-/o     b : ""[-/o  ""
[-//o    b : ""[-//o ""
[x-&gt;o    b : ""[x-&gt;o ""
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="712" src="https://plantuml.com/imgw/img-6ad7e7cebf26032513e0d040fa9650ed.png"></p></div></td></tr></tbody></table>

#### Outgoing messages (with '\]')

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9afb49f71430dc48bfb336f7f851fb3a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9afb49f71430dc48bfb336f7f851fb3a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9afb49f71430dc48bfb336f7f851fb3a')"></td><td><div onclick="javascript:ljs('9afb49f71430dc48bfb336f7f851fb3a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9afb49f71430dc48bfb336f7f851fb3a"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice as a
participant Bob   as b
a -&gt;]      : ""-&gt;]   ""
a -&gt;&gt;]     : ""-&gt;&gt;]  ""
a -\]      : ""-\]   ""
a -\\]     : ""-\\\\]""
a -/]      : ""-/]   ""
a -//]     : ""-//]  ""
a -&gt;x]     : ""-&gt;x]  ""
a x-&gt;]     : ""x-&gt;]  ""
a o-&gt;]     : ""o-&gt;]  ""
a -&gt;o]     : ""-&gt;o]  ""
a o-&gt;o]    : ""o-&gt;o] ""
a &lt;-&gt;]     : ""&lt;-&gt;]  ""
a o&lt;-&gt;o]   : ""o&lt;-&gt;o]""
a x&lt;-&gt;x]   : ""x&lt;-&gt;x]""
a -&gt;&gt;o]    : ""-&gt;&gt;o] ""
a -\o]     : ""-\o]  ""
a -\\o]    : ""-\\\\o]""
a -/o]     : ""-/o]  ""
a -//o]    : ""-//o] ""
a x-&gt;o]    : ""x-&gt;o] ""
@enduml
</code></pre><p></p><p><img loading="lazy" width="110" height="712" src="https://plantuml.com/imgw/img-9afb49f71430dc48bfb336f7f851fb3a.png"></p></div></td></tr></tbody></table>

### Short incoming and outgoing messages (with '?')

#### Short incoming (with '?')

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img87e47e8f746b3cb8d565b2ccb7a61717" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('87e47e8f746b3cb8d565b2ccb7a61717')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('87e47e8f746b3cb8d565b2ccb7a61717')"></td><td><div onclick="javascript:ljs('87e47e8f746b3cb8d565b2ccb7a61717')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre87e47e8f746b3cb8d565b2ccb7a61717"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice as a
participant Bob   as b
a -&gt;     b : //Long long label//
?-&gt;      b : ""?-&gt;   ""
?-&gt;&gt;     b : ""?-&gt;&gt;  ""
?-\      b : ""?-\   ""
?-\\     b : ""?-\\\\""
?-/      b : ""?-/   ""
?-//     b : ""?-//  ""
?-&gt;x     b : ""?-&gt;x  ""
?x-&gt;     b : ""?x-&gt;  ""
?o-&gt;     b : ""?o-&gt;  ""
?-&gt;o     b : ""?-&gt;o  ""
?o-&gt;o    b : ""?o-&gt;o ""
?&lt;-&gt;     b : ""?&lt;-&gt;  ""
?o&lt;-&gt;o   b : ""?o&lt;-&gt;o""
?x&lt;-&gt;x   b : ""?x&lt;-&gt;x""
?-&gt;&gt;o    b : ""?-&gt;&gt;o ""
?-\o     b : ""?-\o  ""
?-\\o    b : ""?-\\\\o ""
?-/o     b : ""?-/o  ""
?-//o    b : ""?-//o ""
?x-&gt;o    b : ""?x-&gt;o ""
@enduml
</code></pre><p></p><p><img loading="lazy" width="163" height="743" src="https://plantuml.com/imgw/img-87e47e8f746b3cb8d565b2ccb7a61717.png"></p></div></td></tr></tbody></table>

#### Short outgoing (with '?')

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb483c72c285d9050d0a2a9571a1290a2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b483c72c285d9050d0a2a9571a1290a2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b483c72c285d9050d0a2a9571a1290a2')"></td><td><div onclick="javascript:ljs('b483c72c285d9050d0a2a9571a1290a2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb483c72c285d9050d0a2a9571a1290a2"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice as a
participant Bob   as b
a -&gt;     b : //Long long label//
a -&gt;?      : ""-&gt;?   ""
a -&gt;&gt;?     : ""-&gt;&gt;?  ""
a -\?      : ""-\?   ""
a -\\?     : ""-\\\\?""
a -/?      : ""-/?   ""
a -//?     : ""-//?  ""
a -&gt;x?     : ""-&gt;x?  ""
a x-&gt;?     : ""x-&gt;?  ""
a o-&gt;?     : ""o-&gt;?  ""
a -&gt;o?     : ""-&gt;o?  ""
a o-&gt;o?    : ""o-&gt;o? ""
a &lt;-&gt;?     : ""&lt;-&gt;?  ""
a o&lt;-&gt;o?   : ""o&lt;-&gt;o?""
a x&lt;-&gt;x?   : ""x&lt;-&gt;x?""
a -&gt;&gt;o?    : ""-&gt;&gt;o? ""
a -\o?     : ""-\o?  ""
a -\\o?    : ""-\\\\o?""
a -/o?     : ""-/o?  ""
a -//o?    : ""-//o? ""
a x-&gt;o?    : ""x-&gt;o? ""
@enduml
</code></pre><p></p><p><img loading="lazy" width="163" height="743" src="https://plantuml.com/imgw/img-b483c72c285d9050d0a2a9571a1290a2.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Specific SkinParameter

### By default

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img61d0b686b455a9788b17d230e15900c2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('61d0b686b455a9788b17d230e15900c2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('61d0b686b455a9788b17d230e15900c2')"></td><td><div onclick="javascript:ljs('61d0b686b455a9788b17d230e15900c2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre61d0b686b455a9788b17d230e15900c2"><code onmouseover="az=1" onmouseout="az=0">@startuml
Bob -&gt; Alice : hello
Alice -&gt; Bob : ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="153" src="https://plantuml.com/imgw/img-61d0b686b455a9788b17d230e15900c2.png"></p></div></td></tr></tbody></table>

### LifelineStrategy

-   nosolid _(by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img1d8fc9528b27eda357268b30556e02cc" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('1d8fc9528b27eda357268b30556e02cc')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('1d8fc9528b27eda357268b30556e02cc')"></td><td><div onclick="javascript:ljs('1d8fc9528b27eda357268b30556e02cc')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre1d8fc9528b27eda357268b30556e02cc"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam lifelineStrategy nosolid
Bob -&gt; Alice : hello
Alice -&gt; Bob : ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="153" src="https://plantuml.com/imgw/img-1d8fc9528b27eda357268b30556e02cc.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-9016](https://forum.plantuml.net/9016/)\]_

-   solid

In order to have solid life line in sequence diagrams, you can use: `skinparam lifelineStrategy solid`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img56f8a8266a36314276ce15a2bd2f903c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('56f8a8266a36314276ce15a2bd2f903c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('56f8a8266a36314276ce15a2bd2f903c')"></td><td><div onclick="javascript:ljs('56f8a8266a36314276ce15a2bd2f903c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre56f8a8266a36314276ce15a2bd2f903c"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam lifelineStrategy solid
Bob -&gt; Alice : hello
Alice -&gt; Bob : ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="153" src="https://plantuml.com/imgw/img-56f8a8266a36314276ce15a2bd2f903c.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-2794](https://forum.plantuml.net/2794)\]_

### style strictuml

To be conform to strict UML (_for arrow style: emits triangle rather than sharp arrowheads_), you can use:

-   `skinparam style strictuml`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img74c588b83afb0fb469a6b40ab4b45341" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('74c588b83afb0fb469a6b40ab4b45341')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('74c588b83afb0fb469a6b40ab4b45341')"></td><td><div onclick="javascript:ljs('74c588b83afb0fb469a6b40ab4b45341')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre74c588b83afb0fb469a6b40ab4b45341"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam style strictuml
Bob -&gt; Alice : hello
Alice -&gt; Bob : ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="124" src="https://plantuml.com/imgw/img-74c588b83afb0fb469a6b40ab4b45341.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-1047](https://forum.plantuml.net/1047)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Hide unlinked participant

By default, all participants are displayed.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb3b393e29c814b5228773aea89b89cb8" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b3b393e29c814b5228773aea89b89cb8')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b3b393e29c814b5228773aea89b89cb8')"></td><td><div onclick="javascript:ljs('b3b393e29c814b5228773aea89b89cb8')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb3b393e29c814b5228773aea89b89cb8"><code onmouseover="az=1" onmouseout="az=0">@startuml
participant Alice
participant Bob
participant Carol

Alice -&gt; Bob : hello
@enduml
</code></pre><p></p><p><img loading="lazy" width="160" height="123" src="https://plantuml.com/imgw/img-b3b393e29c814b5228773aea89b89cb8.png"></p></div></td></tr></tbody></table>

But you can `hide unlinked` participant.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc724a797c23560e72ab0b9158284e1ac" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c724a797c23560e72ab0b9158284e1ac')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c724a797c23560e72ab0b9158284e1ac')"></td><td><div onclick="javascript:ljs('c724a797c23560e72ab0b9158284e1ac')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec724a797c23560e72ab0b9158284e1ac"><code onmouseover="az=1" onmouseout="az=0">@startuml
hide unlinked
participant Alice
participant Bob
participant Carol

Alice -&gt; Bob : hello
@enduml
</code></pre><p></p><p><img loading="lazy" width="103" height="123" src="https://plantuml.com/imgw/img-c724a797c23560e72ab0b9158284e1ac.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-4247](https://forum.plantuml.net/4247)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Color a group message

It is possible to [color](https://plantuml.com/en/color) a group messages:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img15589eb819ee679598a40cd70372e57d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('15589eb819ee679598a40cd70372e57d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('15589eb819ee679598a40cd70372e57d')"></td><td><div onclick="javascript:ljs('15589eb819ee679598a40cd70372e57d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre15589eb819ee679598a40cd70372e57d"><code onmouseover="az=1" onmouseout="az=0">@startuml
Alice -&gt; Bob: Authentication Request
alt#Gold #LightBlue Successful case
    Bob -&gt; Alice: Authentication Accepted
else #Pink Failure
    Bob -&gt; Alice: Authentication Rejected
end
@enduml
</code></pre><p></p><p><img loading="lazy" width="241" height="232" src="https://plantuml.com/imgw/img-15589eb819ee679598a40cd70372e57d.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-4750](https://forum.plantuml.net/4750) and [QA-6410](https://forum.plantuml.net/6410)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Mainframe

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5f396abf6323f6b00e68ec135ab99de0" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5f396abf6323f6b00e68ec135ab99de0')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5f396abf6323f6b00e68ec135ab99de0')"></td><td><div onclick="javascript:ljs('5f396abf6323f6b00e68ec135ab99de0')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5f396abf6323f6b00e68ec135ab99de0"><code onmouseover="az=1" onmouseout="az=0">@startuml
mainframe This is a **mainframe**
Alice-&gt;Bob : Hello
@enduml
</code></pre><p></p><p><img loading="lazy" width="156" height="180" src="https://plantuml.com/imgw/img-5f396abf6323f6b00e68ec135ab99de0.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-4019](https://forum.plantuml.net/4019) and [Issue#148](https://github.com/plantuml/plantuml/issues/148)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Slanted or odd arrows

You can use the `(nn)` option (before or after arrow) to make the arrows slanted, where _nn_ is the number of shift pixels.

_\[Available only after v1.2022.6beta+\]_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4917ff262abb24be4685997344f35984" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4917ff262abb24be4685997344f35984')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4917ff262abb24be4685997344f35984')"></td><td><div onclick="javascript:ljs('4917ff262abb24be4685997344f35984')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4917ff262abb24be4685997344f35984"><code onmouseover="az=1" onmouseout="az=0">@startuml
A -&gt;(10) B: text 10
B -&gt;(10) A: text 10

A -&gt;(10) B: text 10
A (10)&lt;- B: text 10
@enduml
</code></pre><p></p><p><img loading="lazy" width="96" height="274" src="https://plantuml.com/imgw/img-4917ff262abb24be4685997344f35984.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0164a87fb04cb20cadb6d462cee32d86" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0164a87fb04cb20cadb6d462cee32d86')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0164a87fb04cb20cadb6d462cee32d86')"></td><td><div onclick="javascript:ljs('0164a87fb04cb20cadb6d462cee32d86')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0164a87fb04cb20cadb6d462cee32d86"><code onmouseover="az=1" onmouseout="az=0">@startuml
A -&gt;(40) B++: Rq
B --&gt;(20) A--: Rs
@enduml
</code></pre><p></p><p><img loading="lazy" width="78" height="233" src="https://plantuml.com/imgw/img-0164a87fb04cb20cadb6d462cee32d86.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-14145](https://forum.plantuml.net/14145/plantuml-draw-odd-line)\]_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd033617075a4ad2a1268cc4e6266d43b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d033617075a4ad2a1268cc4e6266d43b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d033617075a4ad2a1268cc4e6266d43b')"></td><td><div onclick="javascript:ljs('d033617075a4ad2a1268cc4e6266d43b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred033617075a4ad2a1268cc4e6266d43b"><code onmouseover="az=1" onmouseout="az=0">@startuml
!pragma teoz true
A -&gt;(50) C: Starts\nwhen 'B' sends
&amp; B -&gt;(25) C: \nBut B's message\n arrives before A's
@enduml
</code></pre><p></p><p><img loading="lazy" width="272" height="205" src="https://plantuml.com/imgw/img-d033617075a4ad2a1268cc4e6266d43b.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-6684](https://forum.plantuml.net/6684/non-instantaneous-messages-in-sequence-diagram)\]_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4ff116e5df3e6f071e77491a7e1f72b3" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4ff116e5df3e6f071e77491a7e1f72b3')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4ff116e5df3e6f071e77491a7e1f72b3')"></td><td><div onclick="javascript:ljs('4ff116e5df3e6f071e77491a7e1f72b3')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4ff116e5df3e6f071e77491a7e1f72b3"><code onmouseover="az=1" onmouseout="az=0">@startuml
!pragma teoz true

S1 -&gt;(30) S2: msg 1\n
&amp; S2 -&gt;(30) S1: msg 2

note left S1: msg\nS2 to S1
&amp; note right S2: msg\nS1 to S2
@enduml
</code></pre><p></p><p><img loading="lazy" width="226" height="251" src="https://plantuml.com/imgw/img-4ff116e5df3e6f071e77491a7e1f72b3.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-1072](https://forum.plantuml.net/1072/sequence-diagram-crossed-arrows)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Parallel messages _(with teoz)_

You can use the `&` [teoz](https://plantuml.com/en/teoz) command to display parallel messages:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7c46fb60b4dfd03c3e858a162942f9b5" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7c46fb60b4dfd03c3e858a162942f9b5')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7c46fb60b4dfd03c3e858a162942f9b5')"></td><td><div onclick="javascript:ljs('7c46fb60b4dfd03c3e858a162942f9b5')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7c46fb60b4dfd03c3e858a162942f9b5"><code onmouseover="az=1" onmouseout="az=0">@startuml
!pragma teoz true
Alice -&gt; Bob : hello
&amp; Bob -&gt; Charlie : hi
@enduml
</code></pre><p></p><p><img loading="lazy" width="171" height="122" src="https://plantuml.com/imgw/img-7c46fb60b4dfd03c3e858a162942f9b5.png"></p></div></td></tr></tbody></table>

_(See also [Teoz](https://plantuml.com/en/teoz) architecture)_
