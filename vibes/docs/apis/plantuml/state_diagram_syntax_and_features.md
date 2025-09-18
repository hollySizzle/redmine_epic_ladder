---
created: 2025-07-15T23:31:14 (UTC +09:00)
tags: []
source: https://plantuml.com/en/state-diagram
author: 
---

# State Diagram syntax and features

> ## Excerpt
> PlantUML state diagram syntax: You can have simple state, composite state, concurrent state, relationship, notes... Changing fonts and colors is also possible.

---
## State Diagram

[**State diagrams**](https://en.wikipedia.org/wiki/State_diagram) provide a visual representation of the various states a system or an object can be in, as well as the transitions between those states. They are essential in modeling the dynamic behavior of systems, capturing how they respond to different events over time. State diagrams depict the system's life cycle, making it easier to understand, design, and optimize its behavior.

Using [**PlantUML**](https://plantuml.com/) to create state diagrams offers several advantages:

-   **Text-Based Language**: Quickly define and visualize the states and transitions without the hassle of manual drawing.
-   **Efficiency and Consistency**: Ensure streamlined diagram creation and easy version control.
-   **Versatility**: Integrate with various documentation platforms and support multiple output formats.
-   **Open-Source & Community Support**: Backed by a [**strong community**](https://forum.plantuml.net/) that continuously contributes to its enhancements and offers invaluable resources.

## ![](https://plantuml.com/backtop1.svg "Back to top")Simple State

You can use `[*]` for the starting point and ending point of the state diagram.

Use `-->` for arrows.

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="imgb4fd47130f7f7ea5c968813953d3e14a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b4fd47130f7f7ea5c968813953d3e14a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b4fd47130f7f7ea5c968813953d3e14a')"></td><td><div onclick="javascript:ljs('b4fd47130f7f7ea5c968813953d3e14a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb4fd47130f7f7ea5c968813953d3e14a"><code onmouseover="az=1" onmouseout="az=0">@startuml

[*] --&gt; State1
State1 --&gt; [*]
State1 : this is a string
State1 : this is another string

State1 -&gt; State2
State2 --&gt; [*]

@enduml
</code></pre><p></p><p><img loading="lazy" width="235" height="241" src="https://plantuml.com/imgw/img-b4fd47130f7f7ea5c968813953d3e14a.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Change state rendering

You can use `hide empty description` to render state as simple box.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc671f819b2d50ea87a33a82906a23537" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c671f819b2d50ea87a33a82906a23537')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c671f819b2d50ea87a33a82906a23537')"></td><td><div onclick="javascript:ljs('c671f819b2d50ea87a33a82906a23537')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec671f819b2d50ea87a33a82906a23537"><code onmouseover="az=1" onmouseout="az=0">@startuml
hide empty description
[*] --&gt; State1
State1 --&gt; [*]
State1 : this is a string
State1 : this is another string

State1 -&gt; State2
State2 --&gt; [*]
@enduml
</code></pre><p></p><p><img loading="lazy" width="224" height="241" src="https://plantuml.com/imgw/img-c671f819b2d50ea87a33a82906a23537.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Composite state

A state can also be composite. You have to define it using the `state` keywords and brackets.

### Internal sub-state

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9e074ac100ea929d526e278f999eaec7" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9e074ac100ea929d526e278f999eaec7')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9e074ac100ea929d526e278f999eaec7')"></td><td><div onclick="javascript:ljs('9e074ac100ea929d526e278f999eaec7')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9e074ac100ea929d526e278f999eaec7"><code onmouseover="az=1" onmouseout="az=0">@startuml
scale 350 width
[*] --&gt; NotShooting

state NotShooting {
  [*] --&gt; Idle
  Idle --&gt; Configuring : EvConfig
  Configuring --&gt; Idle : EvConfig
}

state Configuring {
  [*] --&gt; NewValueSelection
  NewValueSelection --&gt; NewValuePreview : EvNewValue
  NewValuePreview --&gt; NewValueSelection : EvNewValueRejected
  NewValuePreview --&gt; NewValueSelection : EvNewValueSaved

  state NewValuePreview {
     State1 -&gt; State2
  }

}
@enduml
</code></pre><p></p><p><img loading="lazy" width="350" height="480" src="https://plantuml.com/imgw/img-9e074ac100ea929d526e278f999eaec7.png"></p></div></td></tr></tbody></table>

### Sub-state to sub-state

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga545fb5fd155c1d820196fd1ae2adfea" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a545fb5fd155c1d820196fd1ae2adfea')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a545fb5fd155c1d820196fd1ae2adfea')"></td><td><div onclick="javascript:ljs('a545fb5fd155c1d820196fd1ae2adfea')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea545fb5fd155c1d820196fd1ae2adfea"><code onmouseover="az=1" onmouseout="az=0">@startuml
state A {
  state X {
  }
  state Y {
  }
}
 
state B {
  state Z {
  }
}

X --&gt; Z
Z --&gt; Y
@enduml
</code></pre><p></p><p><img loading="lazy" width="180" height="240" src="https://plantuml.com/imgw/img-a545fb5fd155c1d820196fd1ae2adfea.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-3300](https://forum.plantuml.net/3300/add-a-new-state-diagram-example)\]_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgfe7a423313d0461b4aebb04ec0066af5" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('fe7a423313d0461b4aebb04ec0066af5')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('fe7a423313d0461b4aebb04ec0066af5')"></td><td><div onclick="javascript:ljs('fe7a423313d0461b4aebb04ec0066af5')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prefe7a423313d0461b4aebb04ec0066af5"><code onmouseover="az=1" onmouseout="az=0">@startuml
state A.X
state A.Y
 
state B.Z

X --&gt; Z
Z --&gt; Y
@enduml
</code></pre><p></p><p><img loading="lazy" width="180" height="240" src="https://plantuml.com/imgw/img-fe7a423313d0461b4aebb04ec0066af5.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Long name

You can also use the `state` keyword to use long description for states.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7813b013e90e1349ef4c85080eefc169" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7813b013e90e1349ef4c85080eefc169')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7813b013e90e1349ef4c85080eefc169')"></td><td><div onclick="javascript:ljs('7813b013e90e1349ef4c85080eefc169')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7813b013e90e1349ef4c85080eefc169"><code onmouseover="az=1" onmouseout="az=0">@startuml
scale 600 width

[*] -&gt; State1
State1 --&gt; State2 : Succeeded
State1 --&gt; [*] : Aborted
State2 --&gt; State3 : Succeeded
State2 --&gt; [*] : Aborted
state State3 {
  state "Accumulate Enough Data\nLong State Name" as long1
  long1 : Just a test
  [*] --&gt; long1
  long1 --&gt; long1 : New Data
  long1 --&gt; ProcessData : Enough Data
}
State3 --&gt; State3 : Failed
State3 --&gt; [*] : Succeeded / Save Result
State3 --&gt; [*] : Aborted

@enduml
</code></pre><p></p><p><img loading="lazy" width="600" height="682" src="https://plantuml.com/imgw/img-7813b013e90e1349ef4c85080eefc169.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")History \[\[H\], \[H\*\]\]

You can use `[H]` for the history and `[H*]` for the deep history of a substate.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc6855a206cacf32c21c3ac3856a562eb" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c6855a206cacf32c21c3ac3856a562eb')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c6855a206cacf32c21c3ac3856a562eb')"></td><td><div onclick="javascript:ljs('c6855a206cacf32c21c3ac3856a562eb')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec6855a206cacf32c21c3ac3856a562eb"><code onmouseover="az=1" onmouseout="az=0">@startuml
[*] -&gt; State1
State1 --&gt; State2 : Succeeded
State1 --&gt; [*] : Aborted
State2 --&gt; State3 : Succeeded
State2 --&gt; [*] : Aborted
state State3 {
  state "Accumulate Enough Data" as long1
  long1 : Just a test
  [*] --&gt; long1
  long1 --&gt; long1 : New Data
  long1 --&gt; ProcessData : Enough Data
  State2 --&gt; [H]: Resume
}
State3 --&gt; State2 : Pause
State2 --&gt; State3[H*]: DeepResume
State3 --&gt; State3 : Failed
State3 --&gt; [*] : Succeeded / Save Result
State3 --&gt; [*] : Aborted
@enduml
</code></pre><p></p><p><img loading="lazy" width="682" height="614" src="https://plantuml.com/imgw/img-c6855a206cacf32c21c3ac3856a562eb.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Fork \[fork, join\]

You can also fork and join using the `<<fork>>` and `<<join>>` stereotypes.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img59d75e5fb96bdc307aa9d763f2a3ad1a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('59d75e5fb96bdc307aa9d763f2a3ad1a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('59d75e5fb96bdc307aa9d763f2a3ad1a')"></td><td><div onclick="javascript:ljs('59d75e5fb96bdc307aa9d763f2a3ad1a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre59d75e5fb96bdc307aa9d763f2a3ad1a"><code onmouseover="az=1" onmouseout="az=0">@startuml

state fork_state &lt;&lt;fork&gt;&gt;
[*] --&gt; fork_state
fork_state --&gt; State2
fork_state --&gt; State3

state join_state &lt;&lt;join&gt;&gt;
State2 --&gt; join_state
State3 --&gt; join_state
join_state --&gt; State4
State4 --&gt; [*]

@enduml
</code></pre><p></p><p><img loading="lazy" width="168" height="469" src="https://plantuml.com/imgw/img-59d75e5fb96bdc307aa9d763f2a3ad1a.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Concurrent state \[--, ||\]

You can define concurrent state into a composite state using either `--` or `||` symbol as separator.

### Horizontal separator `--`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img77425ac3988d135036ad04d69be61e91" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('77425ac3988d135036ad04d69be61e91')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('77425ac3988d135036ad04d69be61e91')"></td><td><div onclick="javascript:ljs('77425ac3988d135036ad04d69be61e91')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre77425ac3988d135036ad04d69be61e91"><code onmouseover="az=1" onmouseout="az=0">@startuml
[*] --&gt; Active

state Active {
  [*] -&gt; NumLockOff
  NumLockOff --&gt; NumLockOn : EvNumLockPressed
  NumLockOn --&gt; NumLockOff : EvNumLockPressed
  --
  [*] -&gt; CapsLockOff
  CapsLockOff --&gt; CapsLockOn : EvCapsLockPressed
  CapsLockOn --&gt; CapsLockOff : EvCapsLockPressed
  --
  [*] -&gt; ScrollLockOff
  ScrollLockOff --&gt; ScrollLockOn : EvScrollLockPressed
  ScrollLockOn --&gt; ScrollLockOff : EvScrollLockPressed
}

@enduml
</code></pre><p></p><p><img loading="lazy" width="301" height="626" src="https://plantuml.com/imgw/img-77425ac3988d135036ad04d69be61e91.png"></p></div></td></tr></tbody></table>

### Vertical separator `||`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img82c655cf3b1cbcfef13999ccf9d99154" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('82c655cf3b1cbcfef13999ccf9d99154')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('82c655cf3b1cbcfef13999ccf9d99154')"></td><td><div onclick="javascript:ljs('82c655cf3b1cbcfef13999ccf9d99154')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre82c655cf3b1cbcfef13999ccf9d99154"><code onmouseover="az=1" onmouseout="az=0">@startuml
[*] --&gt; Active

state Active {
  [*] -&gt; NumLockOff
  NumLockOff --&gt; NumLockOn : EvNumLockPressed
  NumLockOn --&gt; NumLockOff : EvNumLockPressed
  ||
  [*] -&gt; CapsLockOff
  CapsLockOff --&gt; CapsLockOn : EvCapsLockPressed
  CapsLockOn --&gt; CapsLockOff : EvCapsLockPressed
  ||
  [*] -&gt; ScrollLockOff
  ScrollLockOff --&gt; ScrollLockOn : EvScrollLockPressed
  ScrollLockOn --&gt; ScrollLockOff : EvScrollLockPressed
}

@enduml
</code></pre><p></p><p><img loading="lazy" width="825" height="298" src="https://plantuml.com/imgw/img-82c655cf3b1cbcfef13999ccf9d99154.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-3086](https://forum.plantuml.net/3086/state-diagram-concurrent-state-horizontal-line)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Conditional \[choice\]

The stereotype `<<choice>>` can be used to use conditional state.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga59ebd731e9ead8b3da2b2fbb644bf7f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a59ebd731e9ead8b3da2b2fbb644bf7f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a59ebd731e9ead8b3da2b2fbb644bf7f')"></td><td><div onclick="javascript:ljs('a59ebd731e9ead8b3da2b2fbb644bf7f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea59ebd731e9ead8b3da2b2fbb644bf7f"><code onmouseover="az=1" onmouseout="az=0">@startuml
state "Req(Id)" as ReqId &lt;&lt;sdlreceive&gt;&gt;
state "Minor(Id)" as MinorId
state "Major(Id)" as MajorId
 
state c &lt;&lt;choice&gt;&gt;
 
Idle --&gt; ReqId
ReqId --&gt; c
c --&gt; MinorId : [Id &lt;= 10]
c --&gt; MajorId : [Id &gt; 10]
@enduml
</code></pre><p></p><p><img loading="lazy" width="200" height="384" src="https://plantuml.com/imgw/img-a59ebd731e9ead8b3da2b2fbb644bf7f.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Stereotypes full example \[start, choice, fork, join, end, history, history\*\]

### Start, choice, fork, join, end

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc368aa0e1c9b7407b3b639f3ad23e311" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c368aa0e1c9b7407b3b639f3ad23e311')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c368aa0e1c9b7407b3b639f3ad23e311')"></td><td><div onclick="javascript:ljs('c368aa0e1c9b7407b3b639f3ad23e311')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec368aa0e1c9b7407b3b639f3ad23e311"><code onmouseover="az=1" onmouseout="az=0">@startuml
state start1  &lt;&lt;start&gt;&gt;
state choice1 &lt;&lt;choice&gt;&gt;
state fork1   &lt;&lt;fork&gt;&gt;
state join2   &lt;&lt;join&gt;&gt;
state end3    &lt;&lt;end&gt;&gt;

[*]     --&gt; choice1 : from start\nto choice
start1  --&gt; choice1 : from start stereo\nto choice

choice1 --&gt; fork1   : from choice\nto fork
choice1 --&gt; join2   : from choice\nto join
choice1 --&gt; end3    : from choice\nto end stereo

fork1   ---&gt; State1 : from fork\nto state
fork1   --&gt; State2  : from fork\nto state

State2  --&gt; join2   : from state\nto join
State1  --&gt; [*]     : from state\nto end

join2   --&gt; [*]     : from join\nto end
@enduml
</code></pre><p></p><p><img loading="lazy" width="356" height="669" src="https://plantuml.com/imgw/img-c368aa0e1c9b7407b3b639f3ad23e311.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-404](https://forum.plantuml.net/404/choice-pseudostate?show=436#c436), [QA-1159](https://forum.plantuml.net/1159/choice-pseudostate-and-guard-condition-in-state-diagrams?show=1161#a1161) and [GH-887](https://github.com/plantuml/plantuml/pull/887)\]_

### History, history\*

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgcc0971d4bd0ff63b70942fd7db388ae4" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('cc0971d4bd0ff63b70942fd7db388ae4')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('cc0971d4bd0ff63b70942fd7db388ae4')"></td><td><div onclick="javascript:ljs('cc0971d4bd0ff63b70942fd7db388ae4')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="precc0971d4bd0ff63b70942fd7db388ae4"><code onmouseover="az=1" onmouseout="az=0">@startuml
state A {
   state s1 as "Start 1" &lt;&lt;start&gt;&gt;
   state s2 as "H 2" &lt;&lt;history&gt;&gt;
   state s3 as "H 3" &lt;&lt;history*&gt;&gt;
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="132" height="82" src="https://plantuml.com/imgw/img-cc0971d4bd0ff63b70942fd7db388ae4.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-16824](https://forum.plantuml.net/16824/can-history-deep-history-substates-specified-alias-manner)\]_

### Minimal example with all stereotypes

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img17ef252a32edfcd656e9e7d6e95ac77d" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('17ef252a32edfcd656e9e7d6e95ac77d')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('17ef252a32edfcd656e9e7d6e95ac77d')"></td><td><div onclick="javascript:ljs('17ef252a32edfcd656e9e7d6e95ac77d')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre17ef252a32edfcd656e9e7d6e95ac77d"><code onmouseover="az=1" onmouseout="az=0">@startuml
state start1  &lt;&lt;start&gt;&gt;
state choice1 &lt;&lt;choice&gt;&gt;
state fork1   &lt;&lt;fork&gt;&gt;
state join2   &lt;&lt;join&gt;&gt;
state end3    &lt;&lt;end&gt;&gt;
state sdlreceive &lt;&lt;sdlreceive&gt;&gt;
state history &lt;&lt;history&gt;&gt;
state history2 &lt;&lt;history*&gt;&gt;
@enduml
</code></pre><p></p><p><img loading="lazy" width="642" height="59" src="https://plantuml.com/imgw/img-17ef252a32edfcd656e9e7d6e95ac77d.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-19174](https://forum.plantuml.net/19174/is-there-a-list-of-things-like-sdlreceive)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Point \[entryPoint, exitPoint\]

You can add **point** with `<<entryPoint>>` and `<<exitPoint>>` stereotypes:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img76229053e840ac826d863c666ebc9770" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('76229053e840ac826d863c666ebc9770')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('76229053e840ac826d863c666ebc9770')"></td><td><div onclick="javascript:ljs('76229053e840ac826d863c666ebc9770')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre76229053e840ac826d863c666ebc9770"><code onmouseover="az=1" onmouseout="az=0">@startuml
state Somp {
  state entry1 &lt;&lt;entryPoint&gt;&gt;
  state entry2 &lt;&lt;entryPoint&gt;&gt;
  state sin
  entry1 --&gt; sin
  entry2 -&gt; sin
  sin -&gt; sin2
  sin2 --&gt; exitA &lt;&lt;exitPoint&gt;&gt;
}

[*] --&gt; entry1
exitA --&gt; Foo
Foo1 -&gt; entry2
@enduml
</code></pre><p></p><p><img loading="lazy" width="239" height="433" src="https://plantuml.com/imgw/img-76229053e840ac826d863c666ebc9770.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Pin \[inputPin, outputPin\]

You can add **pin** with `<<inputPin>>` and `<<outputPin>>` stereotypes:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge8e5b6852c2d06507bab29c12a31c135" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e8e5b6852c2d06507bab29c12a31c135')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e8e5b6852c2d06507bab29c12a31c135')"></td><td><div onclick="javascript:ljs('e8e5b6852c2d06507bab29c12a31c135')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree8e5b6852c2d06507bab29c12a31c135"><code onmouseover="az=1" onmouseout="az=0">@startuml
state Somp {
  state entry1 &lt;&lt;inputPin&gt;&gt;
  state entry2 &lt;&lt;inputPin&gt;&gt;
  state sin
  entry1 --&gt; sin
  entry2 -&gt; sin
  sin -&gt; sin2
  sin2 --&gt; exitA &lt;&lt;outputPin&gt;&gt;
}

[*] --&gt; entry1
exitA --&gt; Foo
Foo1 -&gt; entry2
@enduml
</code></pre><p></p><p><img loading="lazy" width="239" height="433" src="https://plantuml.com/imgw/img-e8e5b6852c2d06507bab29c12a31c135.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-4309](https://forum.plantuml.net/4309/entrypoints-exitpoints-expansioninput-expansionoutput)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Expansion \[expansionInput, expansionOutput\]

You can add **expansion** with `<<expansionInput>>` and `<<expansionOutput>>` stereotypes:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img32d4614c687899acd2f765846eb67957" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('32d4614c687899acd2f765846eb67957')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('32d4614c687899acd2f765846eb67957')"></td><td><div onclick="javascript:ljs('32d4614c687899acd2f765846eb67957')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre32d4614c687899acd2f765846eb67957"><code onmouseover="az=1" onmouseout="az=0">@startuml
state Somp {
  state entry1 &lt;&lt;expansionInput&gt;&gt;
  state entry2 &lt;&lt;expansionInput&gt;&gt;
  state sin
  entry1 --&gt; sin
  entry2 -&gt; sin
  sin -&gt; sin2
  sin2 --&gt; exitA &lt;&lt;expansionOutput&gt;&gt;
}

[*] --&gt; entry1
exitA --&gt; Foo
Foo1 -&gt; entry2
@enduml
</code></pre><p></p><p><img loading="lazy" width="243" height="433" src="https://plantuml.com/imgw/img-32d4614c687899acd2f765846eb67957.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-4309](https://forum.plantuml.net/4309/entrypoints-exitpoints-expansioninput-expansionoutput)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Arrow direction

You can use `->` for horizontal arrows. It is possible to force arrow's direction using the following syntax:

-   `-down->` or `-->`
-   `-right->` or `->` _(default arrow)_
-   `-left->`
-   `-up->`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img26c07fc9e8a4570f8562a487bfcade92" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('26c07fc9e8a4570f8562a487bfcade92')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('26c07fc9e8a4570f8562a487bfcade92')"></td><td><div onclick="javascript:ljs('26c07fc9e8a4570f8562a487bfcade92')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre26c07fc9e8a4570f8562a487bfcade92"><code onmouseover="az=1" onmouseout="az=0">@startuml

[*] -up-&gt; First
First -right-&gt; Second
Second --&gt; Third
Third -left-&gt; Last

@enduml
</code></pre><p></p><p><img loading="lazy" width="203" height="172" src="https://plantuml.com/imgw/img-26c07fc9e8a4570f8562a487bfcade92.png"></p></div></td></tr></tbody></table>

You can shorten the arrow definition by using only the first character of the direction (for example, `-d-` instead of `-down-`) or the two first characters (`-do-`).

Please note that you should not abuse this functionality : _Graphviz_ gives usually good results without tweaking.

## ![](https://plantuml.com/backtop1.svg "Back to top")Change line color and style

You can change line [color](https://plantuml.com/en/color) and/or line style.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img98d49747c1847c81c90468741fcdd36e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('98d49747c1847c81c90468741fcdd36e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('98d49747c1847c81c90468741fcdd36e')"></td><td><div onclick="javascript:ljs('98d49747c1847c81c90468741fcdd36e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre98d49747c1847c81c90468741fcdd36e"><code onmouseover="az=1" onmouseout="az=0">@startuml
State S1
State S2
S1 -[#DD00AA]-&gt; S2
S1 -left[#yellow]-&gt; S3
S1 -up[#red,dashed]-&gt; S4
S1 -right[dotted,#blue]-&gt; S5

X1 -[dashed]-&gt; X2
Z1 -[dotted]-&gt; Z2
Y1 -[#blue,bold]-&gt; Y2
@enduml
</code></pre><p></p><p><img loading="lazy" width="488" height="282" src="https://plantuml.com/imgw/img-98d49747c1847c81c90468741fcdd36e.png"></p></div></td></tr></tbody></table>

_\[Ref. [Incubation: Change line color in state diagrams](http://wiki.plantuml.net/site/incubation#change_line_color_in_state_diagrams)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Note

You can also define notes using `note left of`, `note right of`, `note top of`, `note bottom of` keywords.

You can also define notes on several lines.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdf2a8ab812d3ae4c1cf287fb5921bc99" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('df2a8ab812d3ae4c1cf287fb5921bc99')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('df2a8ab812d3ae4c1cf287fb5921bc99')"></td><td><div onclick="javascript:ljs('df2a8ab812d3ae4c1cf287fb5921bc99')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predf2a8ab812d3ae4c1cf287fb5921bc99"><code onmouseover="az=1" onmouseout="az=0">@startuml

[*] --&gt; Active
Active --&gt; Inactive

note left of Active : this is a short\nnote

note right of Inactive
  A note can also
  be defined on
  several lines
end note

@enduml
</code></pre><p></p><p><img loading="lazy" width="354" height="261" src="https://plantuml.com/imgw/img-df2a8ab812d3ae4c1cf287fb5921bc99.png"></p></div></td></tr></tbody></table>

You can also have floating notes.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbdd336c714f78a9138c56bfbfdd31b14" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('bdd336c714f78a9138c56bfbfdd31b14')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('bdd336c714f78a9138c56bfbfdd31b14')"></td><td><div onclick="javascript:ljs('bdd336c714f78a9138c56bfbfdd31b14')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebdd336c714f78a9138c56bfbfdd31b14"><code onmouseover="az=1" onmouseout="az=0">@startuml

state foo
note "This is a floating note" as N1

@enduml
</code></pre><p></p><p><img loading="lazy" width="241" height="62" src="https://plantuml.com/imgw/img-bdd336c714f78a9138c56bfbfdd31b14.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Note on link

You can put notes on state-transition or link, with `note on link` keyword.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgcada715ded0826054355856f7c36e267" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('cada715ded0826054355856f7c36e267')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('cada715ded0826054355856f7c36e267')"></td><td><div onclick="javascript:ljs('cada715ded0826054355856f7c36e267')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="precada715ded0826054355856f7c36e267"><code onmouseover="az=1" onmouseout="az=0">@startuml
[*] -&gt; State1
State1 --&gt; State2
note on link 
  this is a state-transition note 
end note
@enduml
</code></pre><p></p><p><img loading="lazy" width="288" height="208" src="https://plantuml.com/imgw/img-cada715ded0826054355856f7c36e267.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")More in notes

You can put notes on composite states.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3fb1a016728ce0a42757eea2e2ae6800" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3fb1a016728ce0a42757eea2e2ae6800')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3fb1a016728ce0a42757eea2e2ae6800')"></td><td><div onclick="javascript:ljs('3fb1a016728ce0a42757eea2e2ae6800')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3fb1a016728ce0a42757eea2e2ae6800"><code onmouseover="az=1" onmouseout="az=0">@startuml

[*] --&gt; NotShooting

state "Not Shooting State" as NotShooting {
  state "Idle mode" as Idle
  state "Configuring mode" as Configuring
  [*] --&gt; Idle
  Idle --&gt; Configuring : EvConfig
  Configuring --&gt; Idle : EvConfig
}

note right of NotShooting : This is a note on a composite state

@enduml
</code></pre><p></p><p><img loading="lazy" width="427" height="350" src="https://plantuml.com/imgw/img-3fb1a016728ce0a42757eea2e2ae6800.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Inline color

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img97d299d61dc724acd8f340fac5299c79" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('97d299d61dc724acd8f340fac5299c79')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('97d299d61dc724acd8f340fac5299c79')"></td><td><div onclick="javascript:ljs('97d299d61dc724acd8f340fac5299c79')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre97d299d61dc724acd8f340fac5299c79"><code onmouseover="az=1" onmouseout="az=0">@startuml
state CurrentSite #pink {
    state HardwareSetup #lightblue {
       state Site #brown
        Site -[hidden]-&gt; Controller
        Controller -[hidden]-&gt; Devices
    }
    state PresentationSetup{
        Groups -[hidden]-&gt; PlansAndGraphics
    }
    state Trends #FFFF77
    state Schedule #magenta
    state AlarmSupression
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="649" height="333" src="https://plantuml.com/imgw/img-97d299d61dc724acd8f340fac5299c79.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-1812](https://forum.plantuml.net/1812)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Skinparam

You can use the [skinparam](https://plantuml.com/en/skinparam) command to change colors and fonts for the drawing.

You can use this command :

-   In the diagram definition, like any other commands,
-   In an [included file](https://plantuml.com/en/preprocessing),
-   In a configuration file, provided in the [command line](https://plantuml.com/en/command-line) or the [Ant task](https://plantuml.com/en/ant-task).

You can define specific color and fonts for stereotyped states.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img60abf1ae3ed7e1f977ad17ab1fcfa192" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('60abf1ae3ed7e1f977ad17ab1fcfa192')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('60abf1ae3ed7e1f977ad17ab1fcfa192')"></td><td><div onclick="javascript:ljs('60abf1ae3ed7e1f977ad17ab1fcfa192')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre60abf1ae3ed7e1f977ad17ab1fcfa192"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam backgroundColor LightYellow
skinparam state {
  StartColor MediumBlue
  EndColor Red
  BackgroundColor Peru
  BackgroundColor&lt;&lt;Warning&gt;&gt; Olive
  BorderColor Gray
  FontName Impact
}

[*] --&gt; NotShooting

state "Not Shooting State" as NotShooting {
  state "Idle mode" as Idle &lt;&lt;Warning&gt;&gt;
  state "Configuring mode" as Configuring
  [*] --&gt; Idle
  Idle --&gt; Configuring : EvConfig
  Configuring --&gt; Idle : EvConfig
}

NotShooting --&gt; [*]
@enduml
</code></pre><p></p><p><img loading="lazy" width="167" height="432" src="https://plantuml.com/imgw/img-60abf1ae3ed7e1f977ad17ab1fcfa192.png"></p></div></td></tr></tbody></table>

### Test of all specific skinparam to State Diagrams

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5b7530b016b57785f23cc399bcf6c837" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5b7530b016b57785f23cc399bcf6c837')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5b7530b016b57785f23cc399bcf6c837')"></td><td><div onclick="javascript:ljs('5b7530b016b57785f23cc399bcf6c837')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5b7530b016b57785f23cc399bcf6c837"><code onmouseover="az=1" onmouseout="az=0">@startuml
skinparam State {
  AttributeFontColor blue
  AttributeFontName serif
  AttributeFontSize  9
  AttributeFontStyle italic
  BackgroundColor palegreen
  BorderColor violet
  EndColor gold
  FontColor red
  FontName Sanserif
  FontSize 15
  FontStyle bold
  StartColor silver
}

state A : a a a\na
state B : b b b\nb

[*] -&gt; A  : start
A -&gt; B : a2b
B -&gt; [*] : end
@enduml
</code></pre><p></p><p><img loading="lazy" width="339" height="88" src="https://plantuml.com/imgw/img-5b7530b016b57785f23cc399bcf6c837.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Changing style

You can change [style](https://plantuml.com/en/style-evolution).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdd4388085179dc928ea756788351c80b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('dd4388085179dc928ea756788351c80b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('dd4388085179dc928ea756788351c80b')"></td><td><div onclick="javascript:ljs('dd4388085179dc928ea756788351c80b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predd4388085179dc928ea756788351c80b"><code onmouseover="az=1" onmouseout="az=0">@startuml

&lt;style&gt;
stateDiagram {
  BackgroundColor Peru
  'LineColor Gray
  FontName Impact
  FontColor Red
  arrow {
    FontSize 13
    LineColor Blue
  }
}
&lt;/style&gt;


[*] --&gt; NotShooting

state "Not Shooting State" as NotShooting {
  state "Idle mode" as Idle &lt;&lt;Warning&gt;&gt;
  state "Configuring mode" as Configuring
  [*] --&gt; Idle
  Idle --&gt; Configuring : EvConfig
  Configuring --&gt; Idle : EvConfig
}

NotShooting --&gt; [*]
@enduml
</code></pre><p></p><p><img loading="lazy" width="156" height="431" src="https://plantuml.com/imgw/img-dd4388085179dc928ea756788351c80b.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb9d3ffa8a23b6d7be8f54eef6a5e1bb2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b9d3ffa8a23b6d7be8f54eef6a5e1bb2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b9d3ffa8a23b6d7be8f54eef6a5e1bb2')"></td><td><div onclick="javascript:ljs('b9d3ffa8a23b6d7be8f54eef6a5e1bb2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb9d3ffa8a23b6d7be8f54eef6a5e1bb2"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
  diamond {
    BackgroundColor #palegreen
    LineColor #green
    LineThickness 2.5
}
&lt;/style&gt;
state state1
state state2 
state choice1 &lt;&lt;choice&gt;&gt;
state end3    &lt;&lt;end&gt;&gt;

state1  --&gt; choice1 : 1
choice1 --&gt; state2  : 2
choice1 --&gt; end3    : 3
@enduml
</code></pre><p></p><p><img loading="lazy" width="127" height="292" src="https://plantuml.com/imgw/img-b9d3ffa8a23b6d7be8f54eef6a5e1bb2.png"></p></div></td></tr></tbody></table>

_\[Ref. [GH-880](https://github.com/plantuml/plantuml/issues/880#issuecomment-1022278138)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Change state color and style (inline style)

You can change the [color](https://plantuml.com/en/color) or style of individual state using the following notation:

-   `#color ##[style]color`

With background color first (`#color`), then line style and line color (`##[style]color` ).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc2af9a63ab099411cff6dfdc864a6bf6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c2af9a63ab099411cff6dfdc864a6bf6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c2af9a63ab099411cff6dfdc864a6bf6')"></td><td><div onclick="javascript:ljs('c2af9a63ab099411cff6dfdc864a6bf6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec2af9a63ab099411cff6dfdc864a6bf6"><code onmouseover="az=1" onmouseout="az=0">@startuml
state FooGradient #red-green ##00FFFF
state FooDashed #red|green ##[dashed]blue {
}
state FooDotted ##[dotted]blue {
}
state FooBold ##[bold] {
}
state Foo1 ##[dotted]green {
state inner1 ##[dotted]yellow
}

state out ##[dotted]gold

state Foo2 ##[bold]green {
state inner2 ##[dotted]yellow
}
inner1 -&gt; inner2
out -&gt; inner2
@enduml
</code></pre><p></p><p><img loading="lazy" width="778" height="114" src="https://plantuml.com/imgw/img-c2af9a63ab099411cff6dfdc864a6bf6.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-1487](https://forum.plantuml.net/1487)\]_

-   `#color;line:color;line.[bold|dashed|dotted];text:color`

FIXME

🚩 `text:color` seems not to be taken into account

FIXME

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img1e3849d94c85d515f5367009e2652bcc" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('1e3849d94c85d515f5367009e2652bcc')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('1e3849d94c85d515f5367009e2652bcc')"></td><td><div onclick="javascript:ljs('1e3849d94c85d515f5367009e2652bcc')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre1e3849d94c85d515f5367009e2652bcc"><code onmouseover="az=1" onmouseout="az=0">@startuml
@startuml
state FooGradient #red-green;line:00FFFF
state FooDashed #red|green;line.dashed;line:blue {
}
state FooDotted #line.dotted;line:blue {
}
state FooBold #line.bold {
}
state Foo1 #line.dotted;line:green {
state inner1 #line.dotted;line:yellow
}

state out #line.dotted;line:gold

state Foo2 #line.bold;line:green {
state inner2 #line.dotted;line:yellow
}
inner1 -&gt; inner2
out -&gt; inner2
@enduml
@enduml
</code></pre><p></p><p><img loading="lazy" width="778" height="114" src="https://plantuml.com/imgw/img-1e3849d94c85d515f5367009e2652bcc.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf9a60f2e7e533c938a8c7bc389dffff2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f9a60f2e7e533c938a8c7bc389dffff2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f9a60f2e7e533c938a8c7bc389dffff2')"></td><td><div onclick="javascript:ljs('f9a60f2e7e533c938a8c7bc389dffff2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref9a60f2e7e533c938a8c7bc389dffff2"><code onmouseover="az=1" onmouseout="az=0">@startuml
state s1 : s1 description
state s2 #pink;line:red;line.bold;text:red : s2 description
state s3 #palegreen;line:green;line.dashed;text:green : s3 description
state s4 #aliceblue;line:blue;line.dotted;text:blue   : s4 description
@enduml
</code></pre><p></p><p><img loading="lazy" width="494" height="64" src="https://plantuml.com/imgw/img-f9a60f2e7e533c938a8c7bc389dffff2.png"></p></div></td></tr></tbody></table>

_\[Adapted from [QA-3770](https://forum.plantuml.net/3770)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Alias

With State you can use `alias`, like:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf78ad526d7d3a760f2293e1432ac4895" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f78ad526d7d3a760f2293e1432ac4895')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f78ad526d7d3a760f2293e1432ac4895')"></td><td><div onclick="javascript:ljs('f78ad526d7d3a760f2293e1432ac4895')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref78ad526d7d3a760f2293e1432ac4895"><code onmouseover="az=1" onmouseout="az=0">@startuml
state alias1 
state "alias2"
state "long name" as alias3
state alias4 as "long name"

alias1 : ""state alias1""
alias2 : ""state "alias2"""
alias3 : ""state "long name" as alias3""
alias4 : ""state alias4 as "long name"""

alias1 -&gt; alias2
alias2 -&gt; alias3
alias3 -&gt; alias4
@enduml
</code></pre><p></p><p><img loading="lazy" width="767" height="65" src="https://plantuml.com/imgw/img-f78ad526d7d3a760f2293e1432ac4895.png"></p></div></td></tr></tbody></table>

or:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img20b301fe260419e04691c08a854fcc1f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('20b301fe260419e04691c08a854fcc1f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('20b301fe260419e04691c08a854fcc1f')"></td><td><div onclick="javascript:ljs('20b301fe260419e04691c08a854fcc1f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre20b301fe260419e04691c08a854fcc1f"><code onmouseover="az=1" onmouseout="az=0">@startuml
state alias1 : ""state alias1""
state "alias2" : ""state "alias2"""
state "long name" as alias3 : ""state "long name" as alias3""
state alias4 as "long name" : ""state alias4 as "long name"""

alias1 -&gt; alias2
alias2 -&gt; alias3
alias3 -&gt; alias4
@enduml
</code></pre><p></p><p><img loading="lazy" width="767" height="65" src="https://plantuml.com/imgw/img-20b301fe260419e04691c08a854fcc1f.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-1748](https://forum.plantuml.net/1748/one-line-declaration-in-state-diagram), [QA-14560](https://forum.plantuml.net/14560/how-to-properly-use-as-with-state-declaration)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Display JSON Data on State diagram

### Simple example

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img5f163ddc4776165af356016764eca91c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('5f163ddc4776165af356016764eca91c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('5f163ddc4776165af356016764eca91c')"></td><td><div onclick="javascript:ljs('5f163ddc4776165af356016764eca91c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre5f163ddc4776165af356016764eca91c"><code onmouseover="az=1" onmouseout="az=0">@startuml
state "A" as stateA
state "C" as stateC {
 state B
}

json jsonJ {
   "fruit":"Apple",
   "size":"Large",
   "color": ["Red", "Green"]
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="301" height="121" src="https://plantuml.com/imgw/img-5f163ddc4776165af356016764eca91c.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-17275](https://forum.plantuml.net/17275/composite-state-functionality-with-allow_mixing?show=17287#a17287)\]_

For another example, see on [JSON page](https://plantuml.com/en/json#wqimfur1rox7ld5sjljq).

## ![](https://plantuml.com/backtop1.svg "Back to top")State description

You can add description to a state or to a composite state.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4e68da0963160536ca2f46abb85a6dac" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4e68da0963160536ca2f46abb85a6dac')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4e68da0963160536ca2f46abb85a6dac')"></td><td><div onclick="javascript:ljs('4e68da0963160536ca2f46abb85a6dac')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4e68da0963160536ca2f46abb85a6dac"><code onmouseover="az=1" onmouseout="az=0">@startuml
hide empty description 

state s0

state "This is the State 1" as s1 {
  s1: State description
  state s2
  state s3: long descr.
  state s4
  s4: long descr.
}

[*] -&gt; s0
s0 --&gt; s2

s2 -&gt; s3
s3 -&gt; s4
@enduml
</code></pre><p></p><p><img loading="lazy" width="362" height="193" src="https://plantuml.com/imgw/img-4e68da0963160536ca2f46abb85a6dac.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-16719](https://forum.plantuml.net/16719/how-state-description-when-using-composite-state-notation)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Style for Nested State Body

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd0007956e4d198823638223b2c8cece0" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d0007956e4d198823638223b2c8cece0')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d0007956e4d198823638223b2c8cece0')"></td><td><div onclick="javascript:ljs('d0007956e4d198823638223b2c8cece0')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred0007956e4d198823638223b2c8cece0"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
.foo {
  state,stateBody {
    BackGroundColor lightblue;
  }
}
&lt;/style&gt;

state MainState &lt;&lt;foo&gt;&gt; {
  state SubA
}
@enduml
</code></pre><p></p><p><img loading="lazy" width="96" height="112" src="https://plantuml.com/imgw/img-d0007956e4d198823638223b2c8cece0.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-16774](https://forum.plantuml.net/16774/state-and-sub-states-background)\]_
