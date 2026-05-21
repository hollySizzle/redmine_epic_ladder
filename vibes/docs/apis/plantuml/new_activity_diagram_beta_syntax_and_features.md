---
created: 2025-07-15T23:31:13 (UTC +09:00)
tags: []
source: https://plantuml.com/en/activity-diagram-beta
author: 
---

# New Activity Diagram Beta syntax and features

> ## Excerpt
> The new syntax is more consistent. You can have start, stop, labels, conditions, while loops, repeat loops, notes, partitions. Changing fonts and colors is also possible.

---
## Activity Diagram (New Syntax)

The [previous syntax used for activity diagrams](https://plantuml.com/en/activity-diagram-legacy) encountered several limitations and maintainability issues. Recognizing these drawbacks, we have introduced a wholly revamped syntax and implementation that is not only user-friendly but also more stable.

### Benefits of the New Syntax

-   No Dependency on Graphviz: Just like with sequence diagrams, the new syntax eliminates the necessity for Graphviz installation, thereby simplifying the setup process.
-   Ease of Maintenance: The intuitive nature of the new syntax means it is easier to manage and maintain your diagrams.

### Transition to the New Syntax

While we will continue to support the old syntax to maintain compatibility, we highly encourage users to migrate to the new syntax to leverage the enhanced features and benefits it offers.

Make the shift today and experience a more streamlined and efficient diagramming process with the new activity diagram syntax.

## ![](https://plantuml.com/backtop1.svg "Back to top")Simple action

Activities label starts with `:` and ends with `;`.

Text formatting can be done using [creole wiki syntax](https://plantuml.com/en/creole).

They are implicitly linked in their definition order.

```plantuml
@startuml
:Hello world;
:This is defined on
several **lines**;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-8873ead4fa866ab0fa4396508ed569b4.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Start/Stop/End

You can use `start` and `stop` keywords to denote the beginning and the end of a diagram.

```plantuml
@startuml
start
:Hello world;
:This is defined on
several **lines**;
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-7ddf80bba7bc688d7709e01417a5529a.png)

You can also use the `end` keyword.

```plantuml
@startuml
start
:Hello world;
:This is defined on
several **lines**;
end
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-bf5bf29755daff5890f336e5d4486ff7.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Conditional \[if, then, else, endif\]

You can use `if`, `then`, `else` and `endif` keywords to put tests in your diagram. Labels can be provided using parentheses.

The 3 syntaxes are possible:

-   `if (...) then (...) ... [else (...) ...] endif`

```plantuml
@startuml

start

if (Graphviz installed?) then (yes)
  :process all\ndiagrams;
else (no)
  :process only
  __sequence__ and __activity__ diagrams;
endif

stop

@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-7cd47753a6fe54e86dda92cc6ed01dcb.png)

-   `if (...) is (...) then ... [else (...) ...] endif`

```plantuml
@startuml
if (color?) is (<color:red>red) then
:print red;
else 
:print not red;
endif
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-4de4728f715b901d8f90c693e1831ec2.png)

-   `if (...) equals (...) then ... [else (...) ...] endif`

```plantuml
@startuml
if (counter?) equals (5) then
:print 5;
else 
:print not 5;
endif
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-79a23268a318ff070e7c1c8a6e4bcff9.png)

_\[Ref. [QA-301](https://forum.plantuml.net/301/activity-diagram-beta?show=302#a302)\]_

### Several tests (horizontal mode)

You can use the `elseif` keyword to have several tests _(by default, it is the horizontal mode)_:

```plantuml
@startuml
start
if (condition A) then (yes)
  :Text 1;
elseif (condition B) then (yes)
  :Text 2;
  stop
(no) elseif (condition C) then (yes)
  :Text 3;
(no) elseif (condition D) then (yes)
  :Text 4;
else (nothing)
  :Text else;
endif
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-88aa90ec0f4cf1de0cd845c2f620e45f.png)

### Several tests (vertical mode)

You can use the command `!pragma useVerticalIf on` to have the tests in vertical mode:

```plantuml
@startuml
!pragma useVerticalIf on
start
if (condition A) then (yes)
  :Text 1;
elseif (condition B) then (yes)
  :Text 2;
  stop
elseif (condition C) then (yes)
  :Text 3;
elseif (condition D) then (yes)
  :Text 4;
else (nothing)
  :Text else;
endif
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-96f8a024f0371af796090ea3ced458f4.png)

You can use the `-P` [command-line](https://plantuml.com/en/command-line) option to specify the pragma:

```
java -jar plantuml.jar -PuseVerticalIf=on
```

_\[Refs. [QA-3931](https://forum.plantuml.net/3931/please-provide-elseif-structure-vertically-activity-diagrams), [GH-582](https://github.com/plantuml/plantuml/issues/582)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Switch and case \[switch, case, endswitch\]

You can use `switch`, `case` and `endswitch` keywords to put switch in your diagram.

Labels can be provided using parentheses.

```plantuml
@startuml
start
switch (test?)
case ( condition A )
  :Text 1;
case ( condition B ) 
  :Text 2;
case ( condition C )
  :Text 3;
case ( condition D )
  :Text 4;
case ( condition E )
  :Text 5;
endswitch
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-d174e9e561c01333f18f136e2b660dc1.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Conditional with stop on an action \[kill, detach\]

You can stop action on a if loop.

```plantuml
@startuml
if (condition?) then
  :error;
  stop
endif
#palegreen:action;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-901794f5efe8b9c05a9a0a51f4e1d16e.png)

But if you want to stop at the precise action, you can use the `kill` or `detach` keyword:

-   `kill`

```plantuml
@startuml
if (condition?) then
  #pink:error;
  kill
endif
#palegreen:action;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-82132c1fda1911deb33b57f6240f5e80.png)

_\[Ref. [QA-265](https://forum.plantuml.net/265/new-activity-diagram-syntax-direction-of-links?show=306#a306)\]_

-   `detach`

```plantuml
@startuml
if (condition?) then
  #pink:error;
  detach
endif
#palegreen:action;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-82be3cdf9a95459ecd290d4f85dfc400.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Repeat loop

### Simple repeat loop

You can use `repeat` and `repeat while` keywords to have repeat loops.

```plantuml
@startuml

start

repeat
  :read data;
  :generate diagrams;
repeat while (more data?) is (yes) not (no)

stop

@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-bbdd2ed66adee2435c01b82fe5dbb4dd.png)

### Repeat loop with repeat action and backward action

It is also possible to use a full action as `repeat` target and insert an action in the return path using the `backward` keyword.

```plantuml
@startuml

start

repeat :foo as starting label;
  :read data;
  :generate diagrams;
backward:This is backward;
repeat while (more data?) is (yes)
->no;

stop

@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-f9894b93943b72ecda6a7eece99a2734.png)

_\[Ref. [QA-5826](https://forum.plantuml.net/5826/please-provide-action-repeat-loop-start-instead-condition?show=5831#a5831)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Break on a repeat loop \[break\]

You can use the `break` keyword after an action on a loop.

```plantuml
@startuml
start
repeat
  :Test something;
    if (Something went wrong?) then (no)
      #palegreen:OK;
      break
    endif
    ->NOK;
    :Alert "Error with long text";
repeat while (Something went wrong with long text?) is (yes) not (no)
->//merged step//;
:Alert "Success";
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-213b89a0ca4c75930ed29bc3d6bf8218.png)

_\[Ref. [QA-6105](https://forum.plantuml.net/6105/possible-to-draw-a-line-to-another-box-via-id-or-label?show=6107#a6107)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Goto and Label Processing \[label, goto\]

⚠ It is currently only experimental 🚧

You can use `label` and `goto` keywords to denote goto processing, with:

-   `label <label_name>`
-   `goto <label_name>`

```plantuml
@startuml
title Point two queries to same activity\nwith `goto`
start
if (Test Question?) then (yes)
'space label only for alignment
label sp_lab0
label sp_lab1
'real label
label lab
:shared;
else (no)
if (Second Test Question?) then (yes)
label sp_lab2
goto sp_lab1
else
:nonShared;
endif
endif
:merge;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-606788044f8e14653370bedf4b091fca.png)

_\[Ref. [QA-15026](https://forum.plantuml.net/15026/), [QA-12526](https://forum.plantuml.net/12526/) and initially [QA-1626](https://forum.plantuml.net/1626)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")While loop

### Simple while loop

You can use `while` and `endwhile` keywords to have while loop.

```plantuml
@startuml

start

while (data available?)
  :read data;
  :generate diagrams;
endwhile

stop

@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-731110c39a28d296b8d7a22511bec3fc.png)

It is possible to provide a label after the `endwhile` keyword, or using the `is` keyword.

```plantuml
@startuml
while (check filesize ?) is (not empty)
  :read file;
endwhile (empty)
:close file;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-7e5d98a96aa1a1f044db60fb0492cbb9.png)

### While loop with backward action

It is also possible to insert an action in the return path using the `backward` keyword.

```plantuml
@startuml
while (check filesize ?) is (not empty)
  :read file;
  backward:log;
endwhile (empty)
:close file;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-978816560cd961a25a495a9b5acabae4.png)

_\[Ref. [QA-11144](https://forum.plantuml.net/11144/backward-for-while-endwhile)\]_

### Infinite while loop

If you are using `detach` to form an infinite while loop, then you will want to also hide the partial arrow that results using `-[hidden]->`

```plantuml
@startuml
:Step 1;
if (condition1) then
  while (loop forever)
   :Step 2;
  endwhile
  -[hidden]->
  detach
else
  :end normally;
  stop
endif
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-f0fc38efbe49bc81eb8e652fdc8088f2.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Parallel processing \[fork, fork again, end fork, end merge\]

You can use `fork`, `fork again` and `end fork` or `end merge` keywords to denote parallel processing.

### Simple `fork`

```plantuml
@startuml
start
fork
  :action 1;
fork again
  :action 2;
end fork
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-664ed36255ab75416bbae8669e73a7c4.png)

### `fork` with end merge

```plantuml
@startuml
start
fork
  :action 1;
fork again
  :action 2;
end merge
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-c4a90b331bad67c7e29f0127c64b99ee.png)

_\[Ref. [QA-5320](https://forum.plantuml.net/5320/please-provide-fork-without-join-with-merge-activity-diagrams?show=5321#a5321)\]_

```plantuml
@startuml
start
fork
  :action 1;
fork again
  :action 2;
fork again
  :action 3;
fork again
  :action 4;
end merge
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-5f391ae26a085a9b5d282a42f7b23e34.png)

```plantuml
@startuml
start
fork
  :action 1;
fork again
  :action 2;
  end
end merge
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-8a4b55a830d564412a66cfee744c1e61.png)

_\[Ref. [QA-13731](https://forum.plantuml.net/13731)\]_

### Label on `end fork` (or UML joinspec):

```plantuml
@startuml
start
fork
  :action A;
fork again
  :action B;
end fork {or}
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-51a7a629274b6077ef428b906f6da4f0.png)

```plantuml
@startuml
start
fork
  :action A;
fork again
  :action B;
end fork {and}
stop
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-f3884570b28a918655adb43203842f3a.png)

_\[Ref. [QA-5346](https://forum.plantuml.net/5346/please-inplement-joinspec-for-join-nodes?show=5348#a5348)\]_

### Other example

```plantuml
@startuml

start

if (multiprocessor?) then (yes)
  fork
    :Treatment 1;
  fork again
    :Treatment 2;
  end fork
else (monoproc)
  :Treatment 1;
  :Treatment 2;
endif

@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-f3f22b983a2d6936a4e370debbb1632e.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Split processing

### Split

You can use `split`, `split again` and `end split` keywords to denote split processing.

```plantuml
@startuml
start
split
   :A;
split again
   :B;
split again
   :C;
split again
   :a;
   :b;
end split
:D;
end
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-a8bcd1769b4a6499c23b314ad9f56db2.png)

### Input split (multi-start)

You can use `hidden` arrows to make an input split (multi-start):

```plantuml
@startuml
split
   -[hidden]->
   :A;
split again
   -[hidden]->
   :B;
split again
   -[hidden]->
   :C;
end split
:D;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-1defff55d086c8c7ced18ec38b6089a8.png)

```plantuml
@startuml
split
   -[hidden]->
   :A;
split again
   -[hidden]->
   :a;
   :b;
split again
   -[hidden]->
   (Z)
end split
:D;
@enduml
```

![PlantUML diagram](https://plantuml.com/imgw/img-a4714c696cd535fe105b2f93fb0a0095.png)

_\[Ref. [QA-8662](https://forum.plantuml.net/8662)\]_

### Output split (multi-end)

You can use `kill` or `detach` to make an output split (multi-end):



\![PlantUML diagram](https://plantuml.com/imgw/img-9f69535683c6de2544e2732457764505.png)



\![PlantUML diagram](https://plantuml.com/imgw/img-1285c4dec44fd86994ba8a8a839835c4.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Notes

Text formatting can be done using [creole wiki syntax](https://plantuml.com/en/creole).

A note can be floating, using `floating` keyword.



\![PlantUML diagram](https://plantuml.com/imgw/img-4ec1aa7edc03f95a0a05a63153ff1792.png)

You can add note on backward activity:



\![PlantUML diagram](https://plantuml.com/imgw/img-df18ae5ed8a0db13e952d7025127343e.png)

_\[Ref. [QA-11788](https://forum.plantuml.net/11788/is-it-possible-to-add-a-note-to-backward-activity?show=11802#a11802)\]_

You can add note on partition activity:



\![PlantUML diagram](https://plantuml.com/imgw/img-b7a0588f5ebe62965274a8f9d93b61d0.png)

_\[Ref. [QA-2398](https://forum.plantuml.net/2398/is-it-possible-to-add-a-comment-on-top-of-a-activity-partition?show=2403#a2403)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Colors

You can specify a [color](https://plantuml.com/en/color) for some activities.



\![PlantUML diagram](https://plantuml.com/imgw/img-f8e4de2656dd9bba589a2d2f7e959921.png)

You can also use [gradient color](https://plantuml.com/en/color).



\![PlantUML diagram](https://plantuml.com/imgw/img-6736e5b841f5a7e06025363c6d500769.png)

_\[Ref. [QA-4906](https://forum.plantuml.net/4906/setting-ad-hoc-gradient-backgrounds-in-activity?show=4917#a4917)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Lines without arrows

You can use `skinparam ArrowHeadColor none` in order to connect activities using lines only, without arrows.



\![PlantUML diagram](https://plantuml.com/imgw/img-872923dc3bb2bf2cab827fe144aeec3c.png)



\![PlantUML diagram](https://plantuml.com/imgw/img-4aa8c2d699cd69b35b4d3ac868895bcd.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Arrows

Using the `->` notation, you can add texts to arrow, and change their [color](https://plantuml.com/en/color).

It's also possible to have dotted, dashed, bold or hidden arrows.



\![PlantUML diagram](https://plantuml.com/imgw/img-ab9c138d89285c1ea32b34e6740cb054.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Multiple colored arrow

You can use multiple colored arrow.



\![PlantUML diagram](https://plantuml.com/imgw/img-b072b01f01ff6f5aa075c37087a8daa0.png)

_\[Ref. [QA-4411](https://forum.plantuml.net/4411)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Connector (or Circle)

You can use parentheses to denote connector.



\![PlantUML diagram](https://plantuml.com/imgw/img-3d89295b5587f4e7e04663900deb1534.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Color on connector

You can add [color](https://plantuml.com/en/color) on connector.



\![PlantUML diagram](https://plantuml.com/imgw/img-eec6bdc790d8e01956a3af9270862457.png)

_\[Ref. [QA-10077](https://forum.plantuml.net/10077/assigning-color-to-connectors?show=10080#c10080)\]_

And even use style on Circle:



\![PlantUML diagram](https://plantuml.com/imgw/img-f67679e63b59a5730d5ae46f5e9f5e9c.png)

_\[Ref. [QA-19975](https://forum.plantuml.net/19975/please-provide-change-background-connectors-activity-diagrams?show=19976#a19976)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Grouping or partition

### Group

You can group activity together by defining group:



\![PlantUML diagram](https://plantuml.com/imgw/img-3f6a4a46be0042f42a63f10b73d699ec.png)

### Partition

You can group activity together by defining partition:



\![PlantUML diagram](https://plantuml.com/imgw/img-f48fa19b601f6cfa2d4a59b3a1b70c5a.png)

It's also possible to change partition [color](https://plantuml.com/en/color):



\![PlantUML diagram](https://plantuml.com/imgw/img-bb17f109b2f8dfc8b0475525738b50c9.png)

_\[Ref. [QA-2793](https://forum.plantuml.net/2793/activity-beta-partition-name-more-than-one-word-does-not-work?show=2798#a2798)\]_

It's also possible to add [link](https://plantuml.com/en/link) to partition:



\![PlantUML diagram](https://plantuml.com/imgw/img-1ef3ff333e32b7ebd93e34ce18361643.png)

_\[Ref. [QA-542](https://forum.plantuml.net/542/ability-to-define-hyperlink-on-diagram-elements?show=14003#c14003)\]_

### Group, Partition, Package, Rectangle or Card

You can group activity together by defining:

-   group;
-   partition;
-   package;
-   rectangle;
-   card.



\![PlantUML diagram](https://plantuml.com/imgw/img-b9cffd12d682c71855d7a06a9367d0ec.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Swimlanes

Using pipe `|`, you can define swimlanes.

It's also possible to change swimlanes [color](https://plantuml.com/en/color).



\![PlantUML diagram](https://plantuml.com/imgw/img-fdeec644511beac92478993d68f19bb0.png)

You can add `if` conditional or `repeat` or `while` loop within swimlanes.



\![PlantUML diagram](https://plantuml.com/imgw/img-8f9b12198f4475b26d0a189c5bfdd0a8.png)

You can also use `alias` with swimlanes, with this syntax:

-   `|[#<color>|]<swimlane_alias>| <swimlane_title>`



\![PlantUML diagram](https://plantuml.com/imgw/img-0e5971cc80bd4c4752869b70743f28fb.png)

_\[Ref. [QA-2681](https://forum.plantuml.net/2681/possible-define-alias-swimlane-place-alias-everywhere-else?show=2685#a2685)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Detach or kill \[detach, kill\]

It's possible to remove an arrow using the `detach` or `kill` keyword:

-   `detach`



\![PlantUML diagram](https://plantuml.com/imgw/img-4504ea1d2ae04b63058d4d2ff8455ba6.png)

-   `kill`



\![PlantUML diagram](https://plantuml.com/imgw/img-1646c4bcb74735a64981f68dffdd3613.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")SDL (Specification and Description Language)

### Table of SDL Shape Name

| Name | Old syntax | Stereotype syntax |
|------|------------|-------------------|
| Input | `<` | `<<input>>` |
| Output | `>` | `<<output>>` |
| Procedure | `|` | `<<procedure>>` |
| Load | `\` | `<<load>>` |
| Save | `/` | `<<save>>` |
| Continuous | `}` | `<<continuous>>` |
| Task | `]` | `<<task>>` |

_\[Ref. [QA-11518](https://forum.plantuml.net/11518/issues-with-final-separator-latex-math-expression-activity?show=17268#a17268), [GH-1270](https://github.com/plantuml/plantuml/discussions/1270)\]_

### SDL using final separator _(Deprecated form)_

By changing the final `;` separator, you can set different rendering for the activity:

-   `|`
-   `<`
-   `>`
-   `/`
-   `\\`
-   `]`
-   `}`



\![PlantUML diagram](https://plantuml.com/imgw/img-66353d2607e37279e816378a76b228c0.png)

### SDL using Normal separator and Stereotype _(Current official form)_



\![PlantUML diagram](https://plantuml.com/imgw/img-aa63e17bb2ed94210a2fbe9a8fe1e755.png)



\![PlantUML diagram](https://plantuml.com/imgw/img-f32d09cd2970cc07a9a4bee5ffedbfb1.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")UML (Unified Modeling Language) Shape

### Table of UML Shape Name

| Name | Stereotype syntax |
|------|-------------------|
| ObjectNode | `<<object>>` |
| ObjectNode<br>typed by signal | `<<objectSignal>>` or `<<object-signal>>` |
| AcceptEventAction<br>without TimeEvent trigger | `<<acceptEvent>>` or `<<accept-event>>` |
| AcceptEventAction<br>with TimeEvent trigger | `<<timeEvent>>` or `<<time-event>>` |
| SendSignalAction<br>SendObjectAction<br>with signal type | `<<sendSignal>>` or `<<send-signal>>` |
| Trigger | `<<trigger>>` |

_\[Ref. [GH-2185](https://github.com/plantuml/plantuml/pull/2185)\]_

### UML Shape Example using Stereotype



\![PlantUML diagram](https://plantuml.com/imgw/img-567dff1d6e4570bc505452c07c4bbe80.png)

_\[Ref. [GH-2185](https://github.com/plantuml/plantuml/pull/2185), [QA-16558](https://forum.plantuml.net/16558), [GH-1659](https://github.com/plantuml/plantuml/issues/1659)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Complete example



\![PlantUML diagram](https://plantuml.com/imgw/img-06b4922b7d246c2abf934bc592b7fc51.png)

## ![](https://plantuml.com/backtop1.svg "Back to top")Condition Style

### Inside style (by default)



\![PlantUML diagram](https://plantuml.com/imgw/img-85fc5270b0538ab9f40f3e5cc7d28ba0.png)



\![PlantUML diagram](https://plantuml.com/imgw/img-d74d76a68cd0979212e39d6ea1c748c4.png)

### Diamond style



\![PlantUML diagram](https://plantuml.com/imgw/img-162a60913105e0f8dfc18d5fac65f86f.png)

### InsideDiamond (or _Foo1_) style



\![PlantUML diagram](https://plantuml.com/imgw/img-0c779520844d7e76d6904ee41dd9da41.png)



\![PlantUML diagram](https://plantuml.com/imgw/img-0dcdce34f58fd483792b8d273b198364.png)

_\[Ref. [QA-1290](https://forum.plantuml.net/1290/plantuml-condition-rendering) and [#400](https://github.com/plantuml/plantuml/issues/400#issuecomment-721287124)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Condition End Style

### Diamond style (by default)

-   With one branch



\![PlantUML diagram](https://plantuml.com/imgw/img-026af36958559df0e08ce015a355b48e.png)

-   With two branches (`B1`, `B2`)



\![PlantUML diagram](https://plantuml.com/imgw/img-d38830dba5a107a652a2957818f59575.png)

### Horizontal line (hline) style

-   With one branch



\![PlantUML diagram](https://plantuml.com/imgw/img-34a524b6ff185be71640693618c2b727.png)

-   With two branches (`B1`, `B2`)



\![PlantUML diagram](https://plantuml.com/imgw/img-f991de9a0c441c91868db87ba4012af6.png)

_\[Ref. [QA-4015](https://forum.plantuml.net/4015/its-possible-to-draw-if-else-endif-without-merge-symbol)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Using (global) style

### Without style _(by default)_



\![PlantUML diagram](https://plantuml.com/imgw/img-74e4ccb6e4841dac3217855b13bdd836.png)

### With style

You can use [style](https://plantuml.com/en/style-evolution) to change rendering of elements.



\![PlantUML diagram](https://plantuml.com/imgw/img-2c1ca30b6667b93b6dd8eadfeaff7847.png)
