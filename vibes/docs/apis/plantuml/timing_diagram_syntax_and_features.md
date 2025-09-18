---
created: 2025-07-15T23:31:14 (UTC +09:00)
tags: []
source: https://plantuml.com/en/timing-diagram
author: 
---

# Timing Diagram syntax and features

> ## Excerpt
> PlantUML Timing diagram syntax: Timing diagrams are not fully supported within PlantUML. This is a draft version of the language can be subject to changes.

---
## Timing Diagram

A [Timing Diagram](https://en.wikipedia.org/wiki/Timing_diagram_%28Unified_Modeling_Language%29) in UML is a specific type of **interaction diagram** that visualizes the **timing constraints** of a system. It focuses on the **chronological order of events**, showcasing how different objects interact with each other over time. **Timing diagrams** are especially useful in **real-time systems** and **embedded systems** to understand the behavior of objects throughout a given period.

## ![](https://plantuml.com/backtop1.svg "Back to top")Declaring element or participant

You declare participant using the following keywords, depending on how you want them to be drawn.

<table><tbody><tr><td><b>Keyword</b></td><td><b>Description</b></td></tr><tr><td><code>analog</code></td><td>An <code>analog</code> signal is continuous, and the values are linearly interpolated between the given setpoints</td></tr><tr><td><code>binary</code></td><td>A <code>binary</code> signal restricted to only 2 states</td></tr><tr><td><code>clock</code></td><td>A <code>clocked</code> signal that repeatedly transitions from high to low, with a <code>period</code>, and an optional <code>pulse</code> and <code>offset</code></td></tr><tr><td><code>concise</code></td><td>A simplified <code>concise</code> signal designed to show the movement of data (great for messages)</td></tr><tr><td><code>robust</code></td><td>A <code>robust</code> complex line signal designed to show the transition from one state to another (can have many states)</td></tr></tbody></table>

You define state change using the `@` notation, and the `is` verb.

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="img9059d1faecae7dd5189b942ec57b49d0" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9059d1faecae7dd5189b942ec57b49d0')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9059d1faecae7dd5189b942ec57b49d0')"></td><td><div onclick="javascript:ljs('9059d1faecae7dd5189b942ec57b49d0')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9059d1faecae7dd5189b942ec57b49d0"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

@0
WU is Idle
WB is Idle

@100
WU is Waiting
WB is Processing

@300
WB is Waiting
@enduml
</code></pre><p></p><p><img loading="lazy" width="295" height="173" src="https://plantuml.com/imgw/img-9059d1faecae7dd5189b942ec57b49d0.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3ee74c704285a4d0aac13a0bf94956d1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3ee74c704285a4d0aac13a0bf94956d1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3ee74c704285a4d0aac13a0bf94956d1')"></td><td><div onclick="javascript:ljs('3ee74c704285a4d0aac13a0bf94956d1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3ee74c704285a4d0aac13a0bf94956d1"><code onmouseover="az=1" onmouseout="az=0">@startuml
clock   "Clock_0"   as C0 with period 50
clock   "Clock_1"   as C1 with period 50 pulse 15 offset 10
binary  "Binary"  as B
concise "Concise" as C
robust  "Robust"  as R
analog  "Analog"  as A


@0
C is Idle
R is Idle
A is 0

@100
B is high
C is Waiting
R is Processing
A is 3

@300
R is Waiting
A is 1
@enduml
</code></pre><p></p><p><img loading="lazy" width="457" height="398" src="https://plantuml.com/imgw/img-3ee74c704285a4d0aac13a0bf94956d1.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-14631](https://forum.plantuml.net/14631), [QA-14647](https://forum.plantuml.net/14647) and [QA-11288](https://forum.plantuml.net/11288/mixed-signal-timing-diagram)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Binary and Clock

It's also possible to have binary and clock signal, using the following keywords:

-   `binary`
-   `clock`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7f48133a9f375aea27b0230c5fa4a9ea" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7f48133a9f375aea27b0230c5fa4a9ea')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7f48133a9f375aea27b0230c5fa4a9ea')"></td><td><div onclick="javascript:ljs('7f48133a9f375aea27b0230c5fa4a9ea')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7f48133a9f375aea27b0230c5fa4a9ea"><code onmouseover="az=1" onmouseout="az=0">@startuml
clock clk with period 1
binary "Enable" as EN

@0
EN is low

@5
EN is high

@10
EN is low
@enduml
</code></pre><p></p><p><img loading="lazy" width="631" height="99" src="https://plantuml.com/imgw/img-7f48133a9f375aea27b0230c5fa4a9ea.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Adding message

You can add message using the following syntax.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img48ce363a2c4cb93ec567f13492525926" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('48ce363a2c4cb93ec567f13492525926')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('48ce363a2c4cb93ec567f13492525926')"></td><td><div onclick="javascript:ljs('48ce363a2c4cb93ec567f13492525926')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre48ce363a2c4cb93ec567f13492525926"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

@0
WU is Idle
WB is Idle

@100
WU -&gt; WB : URL
WU is Waiting
WB is Processing

@300
WB is Waiting
@enduml
</code></pre><p></p><p><img loading="lazy" width="295" height="173" src="https://plantuml.com/imgw/img-48ce363a2c4cb93ec567f13492525926.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Relative time

It is possible to use relative time with `@`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img49c080824235952ff28b6367fa910f18" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('49c080824235952ff28b6367fa910f18')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('49c080824235952ff28b6367fa910f18')"></td><td><div onclick="javascript:ljs('49c080824235952ff28b6367fa910f18')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre49c080824235952ff28b6367fa910f18"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "DNS Resolver" as DNS
robust "Web Browser" as WB
concise "Web User" as WU

@0
WU is Idle
WB is Idle
DNS is Idle

@+100
WU -&gt; WB : URL
WU is Waiting
WB is Processing

@+200
WB is Waiting
WB -&gt; DNS@+50 : Resolve URL

@+100
DNS is Processing

@+300
DNS is Idle
@enduml
</code></pre><p></p><p><img loading="lazy" width="495" height="228" src="https://plantuml.com/imgw/img-49c080824235952ff28b6367fa910f18.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Anchor Points

Instead of using absolute or relative time on an absolute time you can define a time as an anchor point by using the `as` keyword and starting the name with a `:`.

```
@XX as :<anchor point name>
```

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img29a1d217185bda553fa9f2b142c9af04" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('29a1d217185bda553fa9f2b142c9af04')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('29a1d217185bda553fa9f2b142c9af04')"></td><td><div onclick="javascript:ljs('29a1d217185bda553fa9f2b142c9af04')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre29a1d217185bda553fa9f2b142c9af04"><code onmouseover="az=1" onmouseout="az=0">@startuml
clock clk with period 1
binary "enable" as EN
concise "dataBus" as db

@0 as :start
@5 as :en_high 
@10 as :en_low
@:en_high-2 as :en_highMinus2

@:start
EN is low
db is "0x0000"

@:en_high
EN is high

@:en_low
EN is low

@:en_highMinus2
db is "0xf23a"

@:en_high+6
db is "0x0000"
@enduml
</code></pre><p></p><p><img loading="lazy" width="685" height="157" src="https://plantuml.com/imgw/img-29a1d217185bda553fa9f2b142c9af04.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Participant oriented

Rather than declare the diagram in chronological order, you can define it by participant.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img1ac6dd752850fe0890f5c01ede7874ee" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('1ac6dd752850fe0890f5c01ede7874ee')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('1ac6dd752850fe0890f5c01ede7874ee')"></td><td><div onclick="javascript:ljs('1ac6dd752850fe0890f5c01ede7874ee')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre1ac6dd752850fe0890f5c01ede7874ee"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

@WB
0 is idle
+200 is Proc.
+100 is Waiting

@WU
0 is Waiting
+500 is ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="376" height="173" src="https://plantuml.com/imgw/img-1ac6dd752850fe0890f5c01ede7874ee.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Setting scale

You can also set a specific scale.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge1f9b81a3b1ebd766e948c478e571477" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e1f9b81a3b1ebd766e948c478e571477')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e1f9b81a3b1ebd766e948c478e571477')"></td><td><div onclick="javascript:ljs('e1f9b81a3b1ebd766e948c478e571477')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree1f9b81a3b1ebd766e948c478e571477"><code onmouseover="az=1" onmouseout="az=0">@startuml
concise "Web User" as WU
scale 100 as 50 pixels

@WU
0 is Waiting
+500 is ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="336" height="97" src="https://plantuml.com/imgw/img-e1f9b81a3b1ebd766e948c478e571477.png"></p></div></td></tr></tbody></table>

When using absolute Times/Dates, 1 "tick" is equivalent to 1 second.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf2207e753d0e12b05942405bb2a78635" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f2207e753d0e12b05942405bb2a78635')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f2207e753d0e12b05942405bb2a78635')"></td><td><div onclick="javascript:ljs('f2207e753d0e12b05942405bb2a78635')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref2207e753d0e12b05942405bb2a78635"><code onmouseover="az=1" onmouseout="az=0">@startuml
concise "Season" as S
'30 days is scaled to 50 pixels
scale 2592000 as 50 pixels

@2000/11/01
S is "Winter"

@2001/02/01
S is "Spring"

@2001/05/01
S is "Summer"

@2001/08/01
S is "Fall"
@enduml
</code></pre><p></p><p><img loading="lazy" width="541" height="97" src="https://plantuml.com/imgw/img-f2207e753d0e12b05942405bb2a78635.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Initial state

You can also define an inital state.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgcd450e4b3161238369474395178af798" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('cd450e4b3161238369474395178af798')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('cd450e4b3161238369474395178af798')"></td><td><div onclick="javascript:ljs('cd450e4b3161238369474395178af798')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="precd450e4b3161238369474395178af798"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

WB is Initializing
WU is Absent

@WB
0 is idle
+200 is Processing
+100 is Waiting

@WU
0 is Waiting
+500 is ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="435" height="193" src="https://plantuml.com/imgw/img-cd450e4b3161238369474395178af798.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Intricated state

A signal could be in some undefined state.

### Intricated or undefined robust state

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img2e36bc11ee292bf927b579b9ab58c678" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('2e36bc11ee292bf927b579b9ab58c678')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('2e36bc11ee292bf927b579b9ab58c678')"></td><td><div onclick="javascript:ljs('2e36bc11ee292bf927b579b9ab58c678')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre2e36bc11ee292bf927b579b9ab58c678"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Signal1" as S1
robust "Signal2" as S2
S1 has 0,1,2,hello
S2 has 0,1,2
@0
S1 is 0
S2 is 0
@100
S1 is {0,1} #SlateGrey
S2 is {0,1}
@200
S1 is 1
S2 is 0
@300
S1 is hello
S2 is {0,2}
@enduml
</code></pre><p></p><p><img loading="lazy" width="256" height="211" src="https://plantuml.com/imgw/img-2e36bc11ee292bf927b579b9ab58c678.png"></p></div></td></tr></tbody></table>

### Intricated or undefined binary state

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge78ed04451daa3fe198f46a31a3fd607" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e78ed04451daa3fe198f46a31a3fd607')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e78ed04451daa3fe198f46a31a3fd607')"></td><td><div onclick="javascript:ljs('e78ed04451daa3fe198f46a31a3fd607')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree78ed04451daa3fe198f46a31a3fd607"><code onmouseover="az=1" onmouseout="az=0">@startuml
clock "Clock" as C with period 2
binary "Enable" as EN

@0
EN is low
@1
EN is high
@3
EN is low
@5
EN is {low,high}
@10
EN is low
@enduml
</code></pre><p></p><p><img loading="lazy" width="631" height="117" src="https://plantuml.com/imgw/img-e78ed04451daa3fe198f46a31a3fd607.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-11936](https://forum.plantuml.net/11936) and [QA-15933](https://forum.plantuml.net/15933)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Hidden state

It is also possible to hide some state.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img0724d9855078dd0d4c1ea042383182e1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('0724d9855078dd0d4c1ea042383182e1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('0724d9855078dd0d4c1ea042383182e1')"></td><td><div onclick="javascript:ljs('0724d9855078dd0d4c1ea042383182e1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre0724d9855078dd0d4c1ea042383182e1"><code onmouseover="az=1" onmouseout="az=0">@startuml
concise "Web User" as WU

@0
WU is {-}

@100
WU is A1

@200
WU is {-}

@300
WU is {hidden}

@400
WU is A3

@500
WU is {-}
@enduml
</code></pre><p></p><p><img loading="lazy" width="331" height="97" src="https://plantuml.com/imgw/img-0724d9855078dd0d4c1ea042383182e1.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img79ffbea3219a4eaaa3736749662205fa" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('79ffbea3219a4eaaa3736749662205fa')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('79ffbea3219a4eaaa3736749662205fa')"></td><td><div onclick="javascript:ljs('79ffbea3219a4eaaa3736749662205fa')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre79ffbea3219a4eaaa3736749662205fa"><code onmouseover="az=1" onmouseout="az=0">@startuml
scale 1 as 50 pixels

concise state0
concise substate1
robust bit2

bit2 has HIGH,LOW

@state0
0 is 18_start
6 is s_dPause
8 is 10_data
14 is {hidden}

@substate1
0 is sSeq
4 is sPause
6 is {hidden}
8 is dSeq
12 is dPause
14 is {hidden}

@bit2
0 is HIGH
2 is LOW
4 is {hidden}
8 is HIGH
10 is LOW
12 is {hidden}
@enduml
</code></pre><p></p><p><img loading="lazy" width="812" height="210" src="https://plantuml.com/imgw/img-79ffbea3219a4eaaa3736749662205fa.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-12222](https://forum.plantuml.net/12222)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Hide time axis

It is possible to hide time axis.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7c66fcbfa99893155756e5db2ae032f7" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7c66fcbfa99893155756e5db2ae032f7')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7c66fcbfa99893155756e5db2ae032f7')"></td><td><div onclick="javascript:ljs('7c66fcbfa99893155756e5db2ae032f7')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7c66fcbfa99893155756e5db2ae032f7"><code onmouseover="az=1" onmouseout="az=0">@startuml
hide time-axis
concise "Web User" as WU

WU is Absent

@WU
0 is Waiting
+500 is ok
@enduml
</code></pre><p></p><p><img loading="lazy" width="200" height="78" src="https://plantuml.com/imgw/img-7c66fcbfa99893155756e5db2ae032f7.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Using Time and Date

It is possible to use time or date.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdcfbf47d7a1908fc715b39ca36c3797f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('dcfbf47d7a1908fc715b39ca36c3797f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('dcfbf47d7a1908fc715b39ca36c3797f')"></td><td><div onclick="javascript:ljs('dcfbf47d7a1908fc715b39ca36c3797f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predcfbf47d7a1908fc715b39ca36c3797f"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

@2019/07/02
WU is Idle
WB is Idle

@2019/07/04
WU is Waiting : some note
WB is Processing : some other note

@2019/07/05
WB is Waiting
@enduml
</code></pre><p></p><p><img loading="lazy" width="295" height="188" src="https://plantuml.com/imgw/img-dcfbf47d7a1908fc715b39ca36c3797f.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd07ee0f17e93db35c4315b26fb20771a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d07ee0f17e93db35c4315b26fb20771a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d07ee0f17e93db35c4315b26fb20771a')"></td><td><div onclick="javascript:ljs('d07ee0f17e93db35c4315b26fb20771a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred07ee0f17e93db35c4315b26fb20771a"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

@1:15:00
WU is Idle
WB is Idle

@1:16:30
WU is Waiting : some note
WB is Processing : some other note

@1:17:30
WB is Waiting
@enduml
</code></pre><p></p><p><img loading="lazy" width="395" height="188" src="https://plantuml.com/imgw/img-d07ee0f17e93db35c4315b26fb20771a.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-7019](https://forum.plantuml.net/7019/hh-mm-ss-time-format-in-timing-diagram)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Change Date Format

It is also possible to change date format.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgca1b0920c769352384bcefd3bf9f0ea3" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ca1b0920c769352384bcefd3bf9f0ea3')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ca1b0920c769352384bcefd3bf9f0ea3')"></td><td><div onclick="javascript:ljs('ca1b0920c769352384bcefd3bf9f0ea3')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preca1b0920c769352384bcefd3bf9f0ea3"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

use date format "YY-MM-dd"

@2019/07/02
WU is Idle
WB is Idle

@2019/07/04
WU is Waiting : some note
WB is Processing : some other note

@2019/07/05
WB is Waiting
@enduml
</code></pre><p></p><p><img loading="lazy" width="295" height="188" src="https://plantuml.com/imgw/img-ca1b0920c769352384bcefd3bf9f0ea3.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Manage time axis labels

You can manage the time-axis labels.

### Label on each tick _(by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgaa0ac30d9082029f00997121f052a0de" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('aa0ac30d9082029f00997121f052a0de')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('aa0ac30d9082029f00997121f052a0de')"></td><td><div onclick="javascript:ljs('aa0ac30d9082029f00997121f052a0de')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preaa0ac30d9082029f00997121f052a0de"><code onmouseover="az=1" onmouseout="az=0">@startuml
scale 31536000 as 40 pixels
use date format "yy-MM"

concise "OpenGL Desktop" as OD

@1992/01/01
OD is {hidden}

@1992/06/30
OD is 1.0

@1997/03/04
OD is 1.1

@1998/03/16
OD is 1.2

@2001/08/14
OD is 1.3

@2004/09/07
OD is 3.0

@2008/08/01
OD is 3.0

@2017/07/31
OD is 4.6

@enduml
</code></pre><p></p><p><img loading="lazy" width="1099" height="97" src="https://plantuml.com/imgw/img-aa0ac30d9082029f00997121f052a0de.png"></p></div></td></tr></tbody></table>

### Manual label _(only when the state changes)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img841a0adb1baffe0d70240767fb52e78e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('841a0adb1baffe0d70240767fb52e78e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('841a0adb1baffe0d70240767fb52e78e')"></td><td><div onclick="javascript:ljs('841a0adb1baffe0d70240767fb52e78e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre841a0adb1baffe0d70240767fb52e78e"><code onmouseover="az=1" onmouseout="az=0">@startuml
scale 31536000 as 40 pixels

manual time-axis
use date format "yy-MM"

concise "OpenGL Desktop" as OD

@1992/01/01
OD is {hidden}

@1992/06/30
OD is 1.0

@1997/03/04
OD is 1.1

@1998/03/16
OD is 1.2

@2001/08/14
OD is 1.3

@2004/09/07
OD is 3.0

@2008/08/01
OD is 3.0

@2017/07/31
OD is 4.6

@enduml
</code></pre><p></p><p><img loading="lazy" width="1099" height="97" src="https://plantuml.com/imgw/img-841a0adb1baffe0d70240767fb52e78e.png"></p></div></td></tr></tbody></table>

_\[Ref. [GH-1020](https://github.com/plantuml/plantuml/issues/1020)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Adding constraint

It is possible to display time constraints on the diagrams.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img724d223fab385cb8f73bf77105ff2cdb" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('724d223fab385cb8f73bf77105ff2cdb')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('724d223fab385cb8f73bf77105ff2cdb')"></td><td><div onclick="javascript:ljs('724d223fab385cb8f73bf77105ff2cdb')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre724d223fab385cb8f73bf77105ff2cdb"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

WB is Initializing
WU is Absent

@WB
0 is idle
+200 is Processing
+100 is Waiting
WB@0 &lt;-&gt; @50 : {50 ms lag}

@WU
0 is Waiting
+500 is ok
@200 &lt;-&gt; @+150 : {150 ms}
@enduml
</code></pre><p></p><p><img loading="lazy" width="435" height="233" src="https://plantuml.com/imgw/img-724d223fab385cb8f73bf77105ff2cdb.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Highlighted period

You can higlight a part of diagram.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img52835b517c46c690a44edca143d7824c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('52835b517c46c690a44edca143d7824c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('52835b517c46c690a44edca143d7824c')"></td><td><div onclick="javascript:ljs('52835b517c46c690a44edca143d7824c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre52835b517c46c690a44edca143d7824c"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

@0
WU is Idle
WB is Idle

@100
WU -&gt; WB : URL
WU is Waiting #LightCyan;line:Aqua

@200
WB is Proc.

@300
WU -&gt; WB@350 : URL2
WB is Waiting

@+200
WU is ok

@+200
WB is Idle

highlight 200 to 450 #Gold;line:DimGrey : This is my caption
highlight 600 to 700 : This is another\nhighlight
@enduml
</code></pre><p></p><p><img loading="lazy" width="476" height="203" src="https://plantuml.com/imgw/img-52835b517c46c690a44edca143d7824c.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-10868](https://forum.plantuml.net/10868/highlighted-periods-in-timing-diagrams)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Using notes

You can use the `note top of` and `note bottom of` keywords to define notes related to a single object or participant _(available only for_ `concise` _or_ `binary` _object)._

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img754f51e420d280d8e43573d12db61f02" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('754f51e420d280d8e43573d12db61f02')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('754f51e420d280d8e43573d12db61f02')"></td><td><div onclick="javascript:ljs('754f51e420d280d8e43573d12db61f02')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre754f51e420d280d8e43573d12db61f02"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

@0
WU is Idle
WB is Idle

@100
WU is Waiting
WB is Processing
note top of WU : first note\non several\nlines
note bottom of WU : second note\non several\nlines

@300
WB is Waiting
@enduml
</code></pre><p></p><p><img loading="lazy" width="295" height="311" src="https://plantuml.com/imgw/img-754f51e420d280d8e43573d12db61f02.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-6877](https://forum.plantuml.net/6877), [GH-1465](https://github.com/plantuml/plantuml/issues/1465)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Adding texts

You can optionally add a title, a header, a footer, a legend and a caption:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbdae49fc0d864a136a918528fe4b9eaa" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('bdae49fc0d864a136a918528fe4b9eaa')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('bdae49fc0d864a136a918528fe4b9eaa')"></td><td><div onclick="javascript:ljs('bdae49fc0d864a136a918528fe4b9eaa')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebdae49fc0d864a136a918528fe4b9eaa"><code onmouseover="az=1" onmouseout="az=0">@startuml
Title This is my title
header: some header
footer: some footer
legend
Some legend
end legend
caption some caption

robust "Web Browser" as WB
concise "Web User" as WU

@0
WU is Idle
WB is Idle

@100
WU is Waiting
WB is Processing

@300
WB is Waiting
@enduml
</code></pre><p></p><p><img loading="lazy" width="295" height="307" src="https://plantuml.com/imgw/img-bdae49fc0d864a136a918528fe4b9eaa.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Complete example

Thanks to [Adam Rosien](https://twitter.com/arosien) for this example.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga1cac9fb2c1b986253b69d7dc9eac1d8" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a1cac9fb2c1b986253b69d7dc9eac1d8')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a1cac9fb2c1b986253b69d7dc9eac1d8')"></td><td><div onclick="javascript:ljs('a1cac9fb2c1b986253b69d7dc9eac1d8')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea1cac9fb2c1b986253b69d7dc9eac1d8"><code onmouseover="az=1" onmouseout="az=0">@startuml
concise "Client" as Client
concise "Server" as Server
concise "Response freshness" as Cache

Server is idle
Client is idle

@Client
0 is send
Client -&gt; Server@+25 : GET
+25 is await
+75 is recv
+25 is idle
+25 is send
Client -&gt; Server@+25 : GET\nIf-Modified-Since: 150
+25 is await
+50 is recv
+25 is idle
@100 &lt;-&gt; @275 : no need to re-request from server

@Server
25 is recv
+25 is work
+25 is send
Server -&gt; Client@+25 : 200 OK\nExpires: 275
+25 is idle
+75 is recv
+25 is send
Server -&gt; Client@+25 : 304 Not Modified
+25 is idle

@Cache
75 is fresh
+200 is stale
@enduml
</code></pre><p></p><p><img loading="lazy" width="680" height="232" src="https://plantuml.com/imgw/img-a1cac9fb2c1b986253b69d7dc9eac1d8.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Digital Example

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge99853c33cea2fd194b2f02c94dc2515" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e99853c33cea2fd194b2f02c94dc2515')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e99853c33cea2fd194b2f02c94dc2515')"></td><td><div onclick="javascript:ljs('e99853c33cea2fd194b2f02c94dc2515')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree99853c33cea2fd194b2f02c94dc2515"><code onmouseover="az=1" onmouseout="az=0">@startuml
scale 5 as 150 pixels

clock clk with period 1
binary "enable" as en
binary "R/W" as rw
binary "data Valid" as dv
concise "dataBus" as db
concise "address bus" as addr

@6 as :write_beg
@10 as :write_end

@15 as :read_beg
@19 as :read_end


@0
en is low
db is "0x0"
addr is "0x03f"
rw is low
dv is 0

@:write_beg-3
 en is high
@:write_beg-2
 db is "0xDEADBEEF"
@:write_beg-1
dv is 1
@:write_beg
rw is high


@:write_end
rw is low
dv is low
@:write_end+1
rw is low
db is "0x0"
addr is "0x23"

@12
dv is high
@13 
db is "0xFFFF"

@20
en is low
dv is low
@21 
db is "0x0"

highlight :write_beg to :write_end #Gold:Write
highlight :read_beg to :read_end #lightBlue:Read

db@:write_beg-1 &lt;-&gt; @:write_end : setup time
db@:write_beg-1 -&gt; addr@:write_end+1 : hold
@enduml
</code></pre><p></p><p><img loading="lazy" width="887" height="310" src="https://plantuml.com/imgw/img-e99853c33cea2fd194b2f02c94dc2515.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Adding color

You can add [color](https://plantuml.com/en/color).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgac65845cf8b96c924a835e232534cdb6" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ac65845cf8b96c924a835e232534cdb6')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ac65845cf8b96c924a835e232534cdb6')"></td><td><div onclick="javascript:ljs('ac65845cf8b96c924a835e232534cdb6')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preac65845cf8b96c924a835e232534cdb6"><code onmouseover="az=1" onmouseout="az=0">@startuml
concise "LR" as LR
concise "ST" as ST

LR is AtPlace #palegreen
ST is AtLoad #gray

@LR
0 is Lowering
100 is Lowered #pink
350 is Releasing
 
@ST
200 is Moving
@enduml
</code></pre><p></p><p><img loading="lazy" width="512" height="155" src="https://plantuml.com/imgw/img-ac65845cf8b96c924a835e232534cdb6.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-5776](https://forum.plantuml.net/5776)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Using (global) style

### Without style _(by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img724d223fab385cb8f73bf77105ff2cdb" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('724d223fab385cb8f73bf77105ff2cdb')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('724d223fab385cb8f73bf77105ff2cdb')"></td><td><div onclick="javascript:ljs('724d223fab385cb8f73bf77105ff2cdb')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre724d223fab385cb8f73bf77105ff2cdb"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU

WB is Initializing
WU is Absent

@WB
0 is idle
+200 is Processing
+100 is Waiting
WB@0 &lt;-&gt; @50 : {50 ms lag}

@WU
0 is Waiting
+500 is ok
@200 &lt;-&gt; @+150 : {150 ms}
@enduml
</code></pre><p></p><p><img loading="lazy" width="435" height="233" src="https://plantuml.com/imgw/img-724d223fab385cb8f73bf77105ff2cdb.png"></p></div></td></tr></tbody></table>

### With style

You can use [style](https://plantuml.com/en/style-evolution) to change rendering of elements.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbc2b4611b557f5098f01d5b4104920af" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('bc2b4611b557f5098f01d5b4104920af')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('bc2b4611b557f5098f01d5b4104920af')"></td><td><div onclick="javascript:ljs('bc2b4611b557f5098f01d5b4104920af')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebc2b4611b557f5098f01d5b4104920af"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
timingDiagram {
  document {
    BackGroundColor SandyBrown
  }
 constraintArrow {
  LineStyle 2-1
  LineThickness 3
  LineColor Blue
 }
}
&lt;/style&gt;
robust "Web Browser" as WB
concise "Web User" as WU

WB is Initializing
WU is Absent

@WB
0 is idle
+200 is Processing
+100 is Waiting
WB@0 &lt;-&gt; @50 : {50 ms lag}

@WU
0 is Waiting
+500 is ok
@200 &lt;-&gt; @+150 : {150 ms}
@enduml
</code></pre><p></p><p><img loading="lazy" width="435" height="233" src="https://plantuml.com/imgw/img-bc2b4611b557f5098f01d5b4104920af.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-14340](https://forum.plantuml.net/14340/color-of-arrow-in-timing-diagram)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Applying Colors to specific lines

You can use the `<style>` tags and sterotyping to give a name to line attributes.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imga3321a807d9c3fad1fd12c824bd168a9" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('a3321a807d9c3fad1fd12c824bd168a9')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('a3321a807d9c3fad1fd12c824bd168a9')"></td><td><div onclick="javascript:ljs('a3321a807d9c3fad1fd12c824bd168a9')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prea3321a807d9c3fad1fd12c824bd168a9"><code onmouseover="az=1" onmouseout="az=0">@startuml
&lt;style&gt;
timingDiagram {
  .red {
    LineColor red
  }
  .blue {
    LineColor blue
    LineThickness 5
  }
}
&lt;/style&gt;

clock clk with period 1
binary "Input Signal 1"  as IS1
binary "Input Signal 2"  as IS2 &lt;&lt;blue&gt;&gt;
binary "Output Signal 1" as OS1 &lt;&lt;red&gt;&gt;

@0
IS1 is low
IS2 is high
OS1 is low
@2
OS1 is high
@4
OS1 is low
@5
IS1 is high
OS1 is high
@6
IS2 is low
@10
IS1 is low
OS1 is low
@enduml
</code></pre><p></p><p><img loading="lazy" width="689" height="159" src="https://plantuml.com/imgw/img-a3321a807d9c3fad1fd12c824bd168a9.png"></p></div></td></tr></tbody></table>

_\[[Ref. QA-15870](https://forum.plantuml.net/15870/timing-diagram-assign-different-colors-single-participants?show=15870#q15870)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Compact mode

You can use `compact` command to compact the timing layout.

### By default

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img050f937b3d384f965d1828b54d4773a9" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('050f937b3d384f965d1828b54d4773a9')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('050f937b3d384f965d1828b54d4773a9')"></td><td><div onclick="javascript:ljs('050f937b3d384f965d1828b54d4773a9')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre050f937b3d384f965d1828b54d4773a9"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Web Browser" as WB
concise "Web User" as WU
robust "Web Browser2" as WB2

@0
WU is Waiting
WB is Idle
WB2 is Idle

@200
WB is Proc.

@300
WB is Waiting
WB2 is Waiting

@500
WU is ok

@700
WB is Idle
@enduml
</code></pre><p></p><p><img loading="lazy" width="476" height="228" src="https://plantuml.com/imgw/img-050f937b3d384f965d1828b54d4773a9.png"></p></div></td></tr></tbody></table>

#### Global mode with `mode compact`

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img1bd5e565f8ca08ff43c1384640116e12" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('1bd5e565f8ca08ff43c1384640116e12')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('1bd5e565f8ca08ff43c1384640116e12')"></td><td><div onclick="javascript:ljs('1bd5e565f8ca08ff43c1384640116e12')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre1bd5e565f8ca08ff43c1384640116e12"><code onmouseover="az=1" onmouseout="az=0">@startuml
mode compact
robust "Web Browser" as WB
concise "Web User" as WU
robust "Web Browser2" as WB2

@0
WU is Waiting
WB is Idle
WB2 is Idle

@200
WB is Proc.

@300
WB is Waiting
WB2 is Waiting

@500
WU is ok

@700
WB is Idle
@enduml
</code></pre><p></p><p><img loading="lazy" width="588" height="175" src="https://plantuml.com/imgw/img-1bd5e565f8ca08ff43c1384640116e12.png"></p></div></td></tr></tbody></table>

### Local mode with only `compact` on element

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img424d51fbfd6956775b0daeb8bb4ae76b" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('424d51fbfd6956775b0daeb8bb4ae76b')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('424d51fbfd6956775b0daeb8bb4ae76b')"></td><td><div onclick="javascript:ljs('424d51fbfd6956775b0daeb8bb4ae76b')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre424d51fbfd6956775b0daeb8bb4ae76b"><code onmouseover="az=1" onmouseout="az=0">@startuml
compact robust "Web Browser" as WB
compact concise "Web User" as WU
robust "Web Browser2" as WB2

@0
WU is Waiting
WB is Idle
WB2 is Idle

@200
WB is Proc.

@300
WB is Waiting
WB2 is Waiting

@500
WU is ok

@700
WB is Idle
@enduml
</code></pre><p></p><p><img loading="lazy" width="580" height="193" src="https://plantuml.com/imgw/img-424d51fbfd6956775b0daeb8bb4ae76b.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-11130](https://forum.plantuml.net/11130/is-there-a-compact-timing-diagram)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Scaling analog signal

You can scale analog signal.

### Without scaling: 0-max _(by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7909b311c26155a4fed9bbc0874b99bf" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7909b311c26155a4fed9bbc0874b99bf')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7909b311c26155a4fed9bbc0874b99bf')"></td><td><div onclick="javascript:ljs('7909b311c26155a4fed9bbc0874b99bf')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7909b311c26155a4fed9bbc0874b99bf"><code onmouseover="az=1" onmouseout="az=0">@startuml
title Between 0-max (by default)
analog "Analog" as A

@0
A is 350

@100
A is 450

@300
A is 350
@enduml
</code></pre><p></p><p><img loading="lazy" width="318" height="178" src="https://plantuml.com/imgw/img-7909b311c26155a4fed9bbc0874b99bf.png"></p></div></td></tr></tbody></table>

### With scaling: min-max

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc0836d6ee1e376f2f73fae8259cc3c7e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c0836d6ee1e376f2f73fae8259cc3c7e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c0836d6ee1e376f2f73fae8259cc3c7e')"></td><td><div onclick="javascript:ljs('c0836d6ee1e376f2f73fae8259cc3c7e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec0836d6ee1e376f2f73fae8259cc3c7e"><code onmouseover="az=1" onmouseout="az=0">@startuml
title Between min-max
analog "Analog" between 350 and 450 as A

@0
A is 350

@100
A is 450

@300
A is 350
@enduml
</code></pre><p></p><p><img loading="lazy" width="318" height="178" src="https://plantuml.com/imgw/img-c0836d6ee1e376f2f73fae8259cc3c7e.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-17161](https://forum.plantuml.net/17161/timing-diagram-better-scaling-of-analog-values)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Customise analog signal

### Without any customisation _(by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img94d7000810d50585030527873d7b9c58" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('94d7000810d50585030527873d7b9c58')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('94d7000810d50585030527873d7b9c58')"></td><td><div onclick="javascript:ljs('94d7000810d50585030527873d7b9c58')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre94d7000810d50585030527873d7b9c58"><code onmouseover="az=1" onmouseout="az=0">@startuml
analog "Vcore" as VDD
analog "VCC" as VCC

@0
VDD is 0
VCC is 3
@2
VDD is 0
@3
VDD is 6
VCC is 6
VDD@1 -&gt; VCC@2 : "test"
@enduml
</code></pre><p></p><p><img loading="lazy" width="294" height="239" src="https://plantuml.com/imgw/img-94d7000810d50585030527873d7b9c58.png"></p></div></td></tr></tbody></table>

### With customisation (on scale, ticks and height)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb7cdd2a99567eb326325b09398565d4a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b7cdd2a99567eb326325b09398565d4a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b7cdd2a99567eb326325b09398565d4a')"></td><td><div onclick="javascript:ljs('b7cdd2a99567eb326325b09398565d4a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb7cdd2a99567eb326325b09398565d4a"><code onmouseover="az=1" onmouseout="az=0">@startuml
analog "Vcore" as VDD
analog "VCC" between -4.5 and 6.5 as VCC
VCC ticks num on multiple 3
VCC is 200 pixels height

@0
VDD is 0
VCC is 3
@2
VDD is 0
@3
VDD is 6
VCC is 6
VDD@1 -&gt; VCC@2 : "test"
@enduml
</code></pre><p></p><p><img loading="lazy" width="294" height="339" src="https://plantuml.com/imgw/img-b7cdd2a99567eb326325b09398565d4a.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-11288](https://forum.plantuml.net/11288/mixed-signal-timing-diagram?show=11397#c11397)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Order state of robust signal

### Without order _(by default)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7b2e3591cf513dc1cd88bea7aa2eed32" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7b2e3591cf513dc1cd88bea7aa2eed32')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7b2e3591cf513dc1cd88bea7aa2eed32')"></td><td><div onclick="javascript:ljs('7b2e3591cf513dc1cd88bea7aa2eed32')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7b2e3591cf513dc1cd88bea7aa2eed32"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Flow rate" as rate

@0
rate is high

@5
rate is none

@6
rate is low
@enduml
</code></pre><p></p><p><img loading="lazy" width="407" height="115" src="https://plantuml.com/imgw/img-7b2e3591cf513dc1cd88bea7aa2eed32.png"></p></div></td></tr></tbody></table>

### With order

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img99272be0d4819d2e6a36a874c1eafc04" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('99272be0d4819d2e6a36a874c1eafc04')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('99272be0d4819d2e6a36a874c1eafc04')"></td><td><div onclick="javascript:ljs('99272be0d4819d2e6a36a874c1eafc04')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre99272be0d4819d2e6a36a874c1eafc04"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Flow rate" as rate
rate has high,low,none

@0
rate is high

@5
rate is none

@6
rate is low
@enduml
</code></pre><p></p><p><img loading="lazy" width="407" height="115" src="https://plantuml.com/imgw/img-99272be0d4819d2e6a36a874c1eafc04.png"></p></div></td></tr></tbody></table>

### With order and label

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img88e10cc13b5c7cc9238ce4b3f9065c78" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('88e10cc13b5c7cc9238ce4b3f9065c78')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('88e10cc13b5c7cc9238ce4b3f9065c78')"></td><td><div onclick="javascript:ljs('88e10cc13b5c7cc9238ce4b3f9065c78')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre88e10cc13b5c7cc9238ce4b3f9065c78"><code onmouseover="az=1" onmouseout="az=0">@startuml
robust "Flow rate" as rate
rate has "35 gpm" as high
rate has "15 gpm" as low
rate has "0 gpm" as none

@0
rate is high

@5
rate is none

@6
rate is low
@enduml
</code></pre><p></p><p><img loading="lazy" width="421" height="115" src="https://plantuml.com/imgw/img-88e10cc13b5c7cc9238ce4b3f9065c78.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-6651](https://forum.plantuml.net/6651/order-of-states-in-timing-diagram)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Defining a timing diagram

### By Clock _(@clk)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgcd46d88e63030c080f38aaff1355eac8" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('cd46d88e63030c080f38aaff1355eac8')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('cd46d88e63030c080f38aaff1355eac8')"></td><td><div onclick="javascript:ljs('cd46d88e63030c080f38aaff1355eac8')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="precd46d88e63030c080f38aaff1355eac8"><code onmouseover="az=1" onmouseout="az=0">@startuml
clock "clk" as clk with period 50
concise "Signal1" as S1
robust "Signal2" as S2
binary "Signal3" as S3
 
@clk*0
S1 is 0
S2 is 0

@clk*1
S1 is 1
S3 is high

@clk*2
S3 is down

@clk*3
S1 is 1
S2 is 1
S3 is 1

@clk*4
S3 is down
@enduml
</code></pre><p></p><p><img loading="lazy" width="340" height="230" src="https://plantuml.com/imgw/img-cd46d88e63030c080f38aaff1355eac8.png"></p></div></td></tr></tbody></table>

### By Signal _(@S)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img478f9292f4bbfea49c615df9f4f1deff" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('478f9292f4bbfea49c615df9f4f1deff')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('478f9292f4bbfea49c615df9f4f1deff')"></td><td><div onclick="javascript:ljs('478f9292f4bbfea49c615df9f4f1deff')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre478f9292f4bbfea49c615df9f4f1deff"><code onmouseover="az=1" onmouseout="az=0">@startuml
clock "clk" as clk with period 50
concise "Signal1" as S1
robust "Signal2" as S2
binary "Signal3" as S3

@S1
0 is 0
50 is 1
150 is 1

@S2
0 is 0
150 is 1

@S3
50  is 1
100 is low
150 is high
200 is 0
@enduml
</code></pre><p></p><p><img loading="lazy" width="340" height="230" src="https://plantuml.com/imgw/img-478f9292f4bbfea49c615df9f4f1deff.png"></p></div></td></tr></tbody></table>

### By Time _(@time)_

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge5406a8c9513190ad72917fa78f0fbe1" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e5406a8c9513190ad72917fa78f0fbe1')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e5406a8c9513190ad72917fa78f0fbe1')"></td><td><div onclick="javascript:ljs('e5406a8c9513190ad72917fa78f0fbe1')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree5406a8c9513190ad72917fa78f0fbe1"><code onmouseover="az=1" onmouseout="az=0">@startuml
clock "clk" as clk with period 50
concise "Signal1" as S1
robust "Signal2" as S2
binary "Signal3" as S3

@0
S1 is 0
S2 is 0

@50
S1 is 1
S3 is 1

@100
S3 is low

@150
S1 is 1
S2 is 1
S3 is high

@200
S3 is 0
@enduml
</code></pre><p></p><p><img loading="lazy" width="340" height="230" src="https://plantuml.com/imgw/img-e5406a8c9513190ad72917fa78f0fbe1.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-9053](https://forum.plantuml.net/9053/timing-diagrams-for-binary-signal-and-data-buses?show=9057#a9057)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Annotate signal with comment

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd2a8144aac3fab9df0fb0e431ccff2f7" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d2a8144aac3fab9df0fb0e431ccff2f7')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d2a8144aac3fab9df0fb0e431ccff2f7')"></td><td><div onclick="javascript:ljs('d2a8144aac3fab9df0fb0e431ccff2f7')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred2a8144aac3fab9df0fb0e431ccff2f7"><code onmouseover="az=1" onmouseout="az=0">@startuml
binary "Binary Serial Data" as D
robust "Robust" as R
concise "Concise" as C

@-3
D is low: idle
R is lo: idle
C is 1: idle
@-1
D is high: start
R is hi: start
C is 0: start

@0
D is low: 1 lsb
R is lo: 1 lsb
C is 1: lsb

@1
D is high: 0
R is hi: 0
C is 0

@6
D is low: 1
R is lo: 1
C is 1

@7
D is high: 0 msb
R is hi: 0 msb
C is 0: msb

@8
D is low: stop
R is lo: stop
C is 1: stop

@0 &lt;-&gt; @8 : Serial data bits for ASCII "A" (Little Endian)
@enduml
</code></pre><p></p><p><img loading="lazy" width="760" height="218" src="https://plantuml.com/imgw/img-d2a8144aac3fab9df0fb0e431ccff2f7.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-15762](https://forum.plantuml.net/15762/annotate-binary-waveforms), and [QH-888](https://github.com/plantuml/plantuml/issues/888)\]_
