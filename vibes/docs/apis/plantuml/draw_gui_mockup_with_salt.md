---
created: 2025-07-15T23:31:14 (UTC +09:00)
tags: []
source: https://plantuml.com/en/salt
author: 
---

# Draw GUI mockup with Salt

> ## Excerpt
> Salt is a subproject included in PlantUML that may help you to design graphical interface. You can define button, radio button, checkbox, window, tree, menu, table…

---
## Salt (Wireframe)

**Salt** is a subproject of PlantUML that may help you to design graphical interface or [_Website Wireframe or Page Schematic or Screen Blueprint_](https://en.wikipedia.org/wiki/Website_wireframe).

It is very useful in crafting **graphical interfaces**, schematics, and blueprints. It aids in aligning **conceptual structures** with **visual design**, emphasizing **functionality over aesthetics**. **Wireframes**, central to this process, are used across various disciplines.

Developers, designers, and user experience professionals employ them to visualize **interface elements**, **navigational systems**, and to facilitate collaboration. They vary in **fidelity**, from low-detail sketches to high-detail representations, crucial for **prototyping** and **iterative design**. This collaborative process integrates different expertise, from **business analysis** to **user research**, ensuring that the end design aligns with both **business** and **user requirements**.

## ![](https://plantuml.com/backtop1.svg "Back to top")Basic widgets

You can use either `@startsalt` keyword, or `@startuml` followed by a line with `salt` keyword.

A window must start and end with brackets. You can then define:

-   Button using `[` and `]`.
-   Radio button using `(` and `)`.
-   Checkbox using `[` and `]`.
-   User text area using `"`.
-   Droplist using `^`.

<table><tbody><tr><td><p>🎉 Copied!</p><img width="16" height="16" id="imgf1bf934fe623a1c6b05799021df47752" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f1bf934fe623a1c6b05799021df47752')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f1bf934fe623a1c6b05799021df47752')"></td><td><div onclick="javascript:ljs('f1bf934fe623a1c6b05799021df47752')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref1bf934fe623a1c6b05799021df47752"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
  Just plain text
  [This is my button]
  ()  Unchecked radio
  (X) Checked radio
  []  Unchecked box
  [X] Checked box
  "Enter text here   "
  ^This is a droplist^
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="179" height="160" src="https://plantuml.com/imgw/img-f1bf934fe623a1c6b05799021df47752.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Text area

Here is an attempt to create a [text area](https://html.spec.whatwg.org/multipage/form-elements.html#the-textarea-element):

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6fc8d22b26621a3a7895c1343acb89bd" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6fc8d22b26621a3a7895c1343acb89bd')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6fc8d22b26621a3a7895c1343acb89bd')"></td><td><div onclick="javascript:ljs('6fc8d22b26621a3a7895c1343acb89bd')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6fc8d22b26621a3a7895c1343acb89bd"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{+
   This is a long
   text in a textarea
   .
   "                         "
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="219" height="81" src="https://plantuml.com/imgw/img-6fc8d22b26621a3a7895c1343acb89bd.png"></p></div></td></tr></tbody></table>

Note:

-   the dot (`.`) to fill up vertical space;
-   the last line of space (`"  "`) to make the area wider.

_\[Ref. [QA-14765](https://forum.plantuml.net/14765/)\]_

Then you can add [scroll bar](https://plantuml.com/en/salt#6b6xvjbaj4gpk362kjkx):

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img46b8169c86e561fb98cddcf9e6d7eb5c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('46b8169c86e561fb98cddcf9e6d7eb5c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('46b8169c86e561fb98cddcf9e6d7eb5c')"></td><td><div onclick="javascript:ljs('46b8169c86e561fb98cddcf9e6d7eb5c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre46b8169c86e561fb98cddcf9e6d7eb5c"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{SI
   This is a long
   text in a textarea
   .
   "                         "
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="238" height="81" src="https://plantuml.com/imgw/img-46b8169c86e561fb98cddcf9e6d7eb5c.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6ce6308043209a7e35dc9539e6f3871f" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6ce6308043209a7e35dc9539e6f3871f')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6ce6308043209a7e35dc9539e6f3871f')"></td><td><div onclick="javascript:ljs('6ce6308043209a7e35dc9539e6f3871f')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6ce6308043209a7e35dc9539e6f3871f"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{S-
   This is a long
   text in a textarea
   .
   "                         "
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="219" height="100" src="https://plantuml.com/imgw/img-6ce6308043209a7e35dc9539e6f3871f.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Open, close droplist

You can open a droplist, by adding values enclosed by `^`, as:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6677a7171250628bee3475f136851f03" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6677a7171250628bee3475f136851f03')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6677a7171250628bee3475f136851f03')"></td><td><div onclick="javascript:ljs('6677a7171250628bee3475f136851f03')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6677a7171250628bee3475f136851f03"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
  ^This is a closed droplist^ |
  ^This is an open droplist^^ item 1^^ item 2^ |
  ^This is another open droplist^ item 1^ item 2^ 
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="695" height="59" src="https://plantuml.com/imgw/img-6677a7171250628bee3475f136851f03.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-4184](https://forum.plantuml.net/4184)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Using grid \[| and #, !, -, +\]

A table is automatically created when you use an opening bracket `{`. And you have to use `|` to separate columns.

For example:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img8f0399be9eea0c9e7a01ab8804d994b7" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('8f0399be9eea0c9e7a01ab8804d994b7')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('8f0399be9eea0c9e7a01ab8804d994b7')"></td><td><div onclick="javascript:ljs('8f0399be9eea0c9e7a01ab8804d994b7')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre8f0399be9eea0c9e7a01ab8804d994b7"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="147" height="70" src="https://plantuml.com/imgw/img-8f0399be9eea0c9e7a01ab8804d994b7.png"></p></div></td></tr></tbody></table>

Just after the opening bracket, you can use a character to define if you want to draw lines or columns of the grid :

<table><tbody><tr><td><b>Symbol</b></td><td><b>Result</b></td></tr><tr><td><code>#</code></td><td>To display all vertical and horizontal lines</td></tr><tr><td><code>!</code></td><td>To display all vertical lines</td></tr><tr><td><code>-</code></td><td>To display all horizontal lines</td></tr><tr><td><code>+</code></td><td>To display external lines</td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img7c44097659cd5261f19e05bffe64bdf4" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('7c44097659cd5261f19e05bffe64bdf4')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('7c44097659cd5261f19e05bffe64bdf4')"></td><td><div onclick="javascript:ljs('7c44097659cd5261f19e05bffe64bdf4')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre7c44097659cd5261f19e05bffe64bdf4"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{+
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="150" height="75" src="https://plantuml.com/imgw/img-7c44097659cd5261f19e05bffe64bdf4.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Group box \[^\]

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgbc3f11b2540f220a2c24153643bb28ef" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('bc3f11b2540f220a2c24153643bb28ef')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('bc3f11b2540f220a2c24153643bb28ef')"></td><td><div onclick="javascript:ljs('bc3f11b2540f220a2c24153643bb28ef')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prebc3f11b2540f220a2c24153643bb28ef"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{^"My group box"
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="150" height="90" src="https://plantuml.com/imgw/img-bc3f11b2540f220a2c24153643bb28ef.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-5840](http://forum.plantuml.net/5840/please-allow-to-create-groupboxes-in-salt?show=5840#q5840)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Using separator \[.., ==, ~~, --\]

You can use several horizontal lines as separator.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgef4bb48b099c60d4e556df47abdfb408" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ef4bb48b099c60d4e556df47abdfb408')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ef4bb48b099c60d4e556df47abdfb408')"></td><td><div onclick="javascript:ljs('ef4bb48b099c60d4e556df47abdfb408')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preef4bb48b099c60d4e556df47abdfb408"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
  Text1
  ..
  "Some field"
  ==
  Note on usage
  ~~
  Another text
  --
  [Ok]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="99" height="134" src="https://plantuml.com/imgw/img-ef4bb48b099c60d4e556df47abdfb408.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Tree widget \[T\]

To have a Tree, you have to start with `{T` and to use `+` to denote hierarchy.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img51f918570b311dcb1c7995b6a45225ac" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('51f918570b311dcb1c7995b6a45225ac')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('51f918570b311dcb1c7995b6a45225ac')"></td><td><div onclick="javascript:ljs('51f918570b311dcb1c7995b6a45225ac')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre51f918570b311dcb1c7995b6a45225ac"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
{T
 + World
 ++ America
 +++ Canada
 +++ USA
 ++++ New York
 ++++ Boston
 +++ Mexico
 ++ Europe
 +++ Italy
 +++ Germany
 ++++ Berlin
 ++ Africa
}
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="104" height="191" src="https://plantuml.com/imgw/img-51f918570b311dcb1c7995b6a45225ac.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Tree table \[T\]

You can combine trees with tables.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4129a955e4e46ae24435cf155f6d9a08" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4129a955e4e46ae24435cf155f6d9a08')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4129a955e4e46ae24435cf155f6d9a08')"></td><td><div onclick="javascript:ljs('4129a955e4e46ae24435cf155f6d9a08')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4129a955e4e46ae24435cf155f6d9a08"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
{T
+Region        | Population    | Age
+ World        | 7.13 billion  | 30
++ America     | 964 million   | 30
+++ Canada     | 35 million    | 30
+++ USA        | 319 million   | 30
++++ NYC       | 8 million     | 30
++++ Boston    | 617 thousand  | 30
+++ Mexico     | 117 million   | 30
++ Europe      | 601 million   | 30
+++ Italy      | 61 million    | 30
+++ Germany    | 82 million    | 30
++++ Berlin    | 3 million     | 30
++ Africa      | 1 billion     | 30
}
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="205" height="207" src="https://plantuml.com/imgw/img-4129a955e4e46ae24435cf155f6d9a08.png"></p></div></td></tr></tbody></table>

And add lines.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img8202950deb95578c3508c77882d5ae15" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('8202950deb95578c3508c77882d5ae15')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('8202950deb95578c3508c77882d5ae15')"></td><td><div onclick="javascript:ljs('8202950deb95578c3508c77882d5ae15')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre8202950deb95578c3508c77882d5ae15"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
..
== with T!
{T!
+Region        | Population    | Age
+ World        | 7.13 billion  | 30
++ America     | 964 million   | 30
}
..
== with T-
{T-
+Region        | Population    | Age
+ World        | 7.13 billion  | 30
++ America     | 964 million   | 30
}
..
== with T+
{T+
+Region        | Population    | Age
+ World        | 7.13 billion  | 30
++ America     | 964 million   | 30
}
..
== with T#
{T#
+Region        | Population    | Age
+ World        | 7.13 billion  | 30
++ America     | 964 million   | 30
}
..
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="179" height="315" src="https://plantuml.com/imgw/img-8202950deb95578c3508c77882d5ae15.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-1265](https://forum.plantuml.net/1265/feature-request-tree-tables)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Enclosing brackets \[{, }\]

You can define subelements by opening a new opening bracket.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4cfe817e5112a5db7e4d414354148707" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4cfe817e5112a5db7e4d414354148707')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4cfe817e5112a5db7e4d414354148707')"></td><td><div onclick="javascript:ljs('4cfe817e5112a5db7e4d414354148707')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4cfe817e5112a5db7e4d414354148707"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
Name         | "                 "
Modifiers:   | { (X) public | () default | () private | () protected
                [] abstract | [] final   | [] static }
Superclass:  | { "java.lang.Object " | [Browse...] }
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="328" height="88" src="https://plantuml.com/imgw/img-4cfe817e5112a5db7e4d414354148707.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Adding tabs \[/\]

You can add tabs using `{/` notation. Note that you can use HTML code to have bold text.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img615a566d894ace98bada69f587720133" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('615a566d894ace98bada69f587720133')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('615a566d894ace98bada69f587720133')"></td><td><div onclick="javascript:ljs('615a566d894ace98bada69f587720133')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre615a566d894ace98bada69f587720133"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{+
{/ &lt;b&gt;General | Fullscreen | Behavior | Saving }
{
{ Open image in: | ^Smart Mode^ }
[X] Smooth images when zoomed
[X] Confirm image deletion
[ ] Show hidden images
}
[Close]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="257" height="130" src="https://plantuml.com/imgw/img-615a566d894ace98bada69f587720133.png"></p></div></td></tr></tbody></table>

Tab could also be vertically oriented:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6c19b57fb3507ded10671681410b2726" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6c19b57fb3507ded10671681410b2726')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6c19b57fb3507ded10671681410b2726')"></td><td><div onclick="javascript:ljs('6c19b57fb3507ded10671681410b2726')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6c19b57fb3507ded10671681410b2726"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{+
{/ &lt;b&gt;General
Fullscreen
Behavior
Saving } |
{
{ Open image in: | ^Smart Mode^ }
[X] Smooth images when zoomed
[X] Confirm image deletion
[ ] Show hidden images
[Close]
}
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="257" height="133" src="https://plantuml.com/imgw/img-6c19b57fb3507ded10671681410b2726.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Using menu \[\*\]

You can add a menu by using `{*` notation.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgae127f805ac7660956fa7eb7be4f8625" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('ae127f805ac7660956fa7eb7be4f8625')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('ae127f805ac7660956fa7eb7be4f8625')"></td><td><div onclick="javascript:ljs('ae127f805ac7660956fa7eb7be4f8625')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preae127f805ac7660956fa7eb7be4f8625"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{+
{* File | Edit | Source | Refactor }
{/ General | Fullscreen | Behavior | Saving }
{
{ Open image in: | ^Smart Mode^ }
[X] Smooth images when zoomed
[X] Confirm image deletion
[ ] Show hidden images
}
[Close]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="255" height="147" src="https://plantuml.com/imgw/img-ae127f805ac7660956fa7eb7be4f8625.png"></p></div></td></tr></tbody></table>

It is also possible to open a menu:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img09b88503eac8ca530d17d85b74c33497" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('09b88503eac8ca530d17d85b74c33497')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('09b88503eac8ca530d17d85b74c33497')"></td><td><div onclick="javascript:ljs('09b88503eac8ca530d17d85b74c33497')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre09b88503eac8ca530d17d85b74c33497"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{+
{* File | Edit | Source | Refactor
 Refactor | New | Open File | - | Close | Close All }
{/ General | Fullscreen | Behavior | Saving }
{
{ Open image in: | ^Smart Mode^ }
[X] Smooth images when zoomed
[X] Confirm image deletion
[ ] Show hidden images
}
[Close]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="255" height="147" src="https://plantuml.com/imgw/img-09b88503eac8ca530d17d85b74c33497.png"></p></div></td></tr></tbody></table>

Like it is possible to open a droplist:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc45488a7359530eac0850595d7bb0482" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c45488a7359530eac0850595d7bb0482')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c45488a7359530eac0850595d7bb0482')"></td><td><div onclick="javascript:ljs('c45488a7359530eac0850595d7bb0482')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec45488a7359530eac0850595d7bb0482"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{+
{* File | Edit | Source | Refactor }
{/ General | Fullscreen | Behavior | Saving }
{
{ Open image in: | ^Smart Mode^^Normal Mode^ }
[X] Smooth images when zoomed
[X] Confirm image deletion
[ ] Show hidden images
}
[Close]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="255" height="147" src="https://plantuml.com/imgw/img-c45488a7359530eac0850595d7bb0482.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-4184](https://forum.plantuml.net/4184)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Advanced table

You can use two special notations for table :

-   `*` to indicate that a cell with span with left
-   `.` to denotate an empty cell

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc9759ec04e3453dc94e6a4a53cc74385" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c9759ec04e3453dc94e6a4a53cc74385')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c9759ec04e3453dc94e6a4a53cc74385')"></td><td><div onclick="javascript:ljs('c9759ec04e3453dc94e6a4a53cc74385')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec9759ec04e3453dc94e6a4a53cc74385"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{#
. | Column 2 | Column 3
Row header 1 | value 1 | value 2
Row header 2 | A long cell | *
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="194" height="62" src="https://plantuml.com/imgw/img-c9759ec04e3453dc94e6a4a53cc74385.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Scroll Bars \[S, SI, S-\]

You can use `{S` notation for [scroll bar](https://en.wikipedia.org/wiki/Scrollbar) like in following examples:

-   `{S`: for horizontal and vertical scrollbars

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb31382b22e734a4df07ceccf3e580200" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b31382b22e734a4df07ceccf3e580200')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b31382b22e734a4df07ceccf3e580200')"></td><td><div onclick="javascript:ljs('b31382b22e734a4df07ceccf3e580200')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb31382b22e734a4df07ceccf3e580200"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{S
Message
.
.
.
.
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="80" height="115" src="https://plantuml.com/imgw/img-b31382b22e734a4df07ceccf3e580200.png"></p></div></td></tr></tbody></table>

-   `{SI` : for vertical scrollbar only

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9924f6db5af2a755174e8595e472bd99" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9924f6db5af2a755174e8595e472bd99')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9924f6db5af2a755174e8595e472bd99')"></td><td><div onclick="javascript:ljs('9924f6db5af2a755174e8595e472bd99')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9924f6db5af2a755174e8595e472bd99"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{SI
Message
.
.
.
.
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="80" height="96" src="https://plantuml.com/imgw/img-9924f6db5af2a755174e8595e472bd99.png"></p></div></td></tr></tbody></table>

-   `{S-` : for horizontal scrollbar only

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf325b815e3af5cb0f58f10bf3eccda00" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f325b815e3af5cb0f58f10bf3eccda00')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f325b815e3af5cb0f58f10bf3eccda00')"></td><td><div onclick="javascript:ljs('f325b815e3af5cb0f58f10bf3eccda00')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref325b815e3af5cb0f58f10bf3eccda00"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{S-
Message
.
.
.
.
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="61" height="115" src="https://plantuml.com/imgw/img-f325b815e3af5cb0f58f10bf3eccda00.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Colors

It is possible to change text [color](https://plantuml.com/en/color) of widget.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgdd7c37bb39351e978b1b87eccb544b78" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('dd7c37bb39351e978b1b87eccb544b78')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('dd7c37bb39351e978b1b87eccb544b78')"></td><td><div onclick="javascript:ljs('dd7c37bb39351e978b1b87eccb544b78')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="predd7c37bb39351e978b1b87eccb544b78"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
  &lt;color:Blue&gt;Just plain text
  [This is my default button]
  [&lt;color:green&gt;This is my green button]
  [&lt;color:#9a9a9a&gt;This is my disabled button]
  []  &lt;color:red&gt;Unchecked box
  [X] &lt;color:green&gt;Checked box
  "Enter text here   "
  ^This is a droplist^
  ^&lt;color:#9a9a9a&gt;This is a disabled droplist^
  ^&lt;color:red&gt;This is a red droplist^
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="251" height="220" src="https://plantuml.com/imgw/img-dd7c37bb39351e978b1b87eccb544b78.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-12177](https://forum.plantuml.net/12177/change-color-of-salt-button-to-represent-disabled-status)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Creole on Salt

You can use [Creole or HTML Creole](https://plantuml.com/en/creole) on salt:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf61faa00a3564e82e5cf463a767c6b30" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f61faa00a3564e82e5cf463a767c6b30')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f61faa00a3564e82e5cf463a767c6b30')"></td><td><div onclick="javascript:ljs('f61faa00a3564e82e5cf463a767c6b30')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref61faa00a3564e82e5cf463a767c6b30"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{{^==Creole
  This is **bold**
  This is //italics//
  This is ""monospaced""
  This is --stricken-out--
  This is __underlined__
  This is ~~wave-underlined~~
  --test Unicode and icons--
  This is &lt;U+221E&gt; long
  This is a &lt;&amp;code&gt; icon
  Use image : &lt;img:https://plantuml.com/logo3.png&gt;
}|
{^&lt;b&gt;HTML Creole 
 This is &lt;b&gt;bold&lt;/b&gt;
  This is &lt;i&gt;italics&lt;/i&gt;
  This is &lt;font:monospaced&gt;monospaced&lt;/font&gt;
  This is &lt;s&gt;stroked&lt;/s&gt;
  This is &lt;u&gt;underlined&lt;/u&gt;
  This is &lt;w&gt;waved&lt;/w&gt;
  This is &lt;s:green&gt;stroked&lt;/s&gt;
  This is &lt;u:red&gt;underlined&lt;/u&gt;
  This is &lt;w:#0000FF&gt;waved&lt;/w&gt;
  -- other examples --
  This is &lt;color:blue&gt;Blue&lt;/color&gt;
  This is &lt;back:orange&gt;Orange background&lt;/back&gt;
  This is &lt;size:20&gt;big&lt;/size&gt;
}|
{^Creole line
You can have horizontal line
----
Or double line
====
Or strong line
____
Or dotted line
..My title..
Or dotted title
//and title... //
==Title==
Or double-line title
--Another title--
Or single-line title
Enjoy!
}|
{^Creole list item
**test list 1**
* Bullet list
* Second item
** Sub item
*** Sub sub item
* Third item
----
**test list 2**
# Numbered list
# Second item
## Sub item
## Another sub item
# Third item
}|
{^Mix on salt
  ==&lt;color:Blue&gt;Just plain text
  [This is my default button]
  [&lt;b&gt;&lt;color:green&gt;This is my green button]
  [ ---&lt;color:#9a9a9a&gt;This is my disabled button-- ]
  []  &lt;size:20&gt;&lt;color:red&gt;Unchecked box
  [X] &lt;color:green&gt;Checked box
  "//Enter text here//   "
  ^This is a droplist^
  ^&lt;color:#9a9a9a&gt;This is a disabled droplist^
  ^&lt;b&gt;&lt;color:red&gt;This is a red droplist^
}}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="933" height="327" src="https://plantuml.com/imgw/img-f61faa00a3564e82e5cf463a767c6b30.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Pseudo sprite \[<<, >>\]

Using `<<` and `>>` you can define a pseudo-sprite or sprite-like drawing and reusing it latter.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgc3b3d3cfec36724632c3cc9e6bd8f51e" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('c3b3d3cfec36724632c3cc9e6bd8f51e')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('c3b3d3cfec36724632c3cc9e6bd8f51e')"></td><td><div onclick="javascript:ljs('c3b3d3cfec36724632c3cc9e6bd8f51e')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="prec3b3d3cfec36724632c3cc9e6bd8f51e"><code onmouseover="az=1" onmouseout="az=0">@startsalt
 {
 [X] checkbox|[] checkbox
 () radio | (X) radio
 This is a text|[This is my button]|This is another text
 "A field"|"Another long Field"|[A button]
 &lt;&lt;folder
 ............
 .XXXXX......
 .X...X......
 .XXXXXXXXXX.
 .X........X.
 .X........X.
 .X........X.
 .X........X.
 .XXXXXXXXXX.
 ............
 &gt;&gt;|&lt;color:blue&gt;other folder|&lt;&lt;folder&gt;&gt;
^Droplist^
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="347" height="133" src="https://plantuml.com/imgw/img-c3b3d3cfec36724632c3cc9e6bd8f51e.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-5849](https://forum.plantuml.net/5849/support-for-sprites-salt?show=5851#a5851)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")OpenIconic

[OpenIconic](https://useiconic.com/open/) is a very nice open source icon set. Those icons have been integrated into the [creole parser](https://plantuml.com/en/creole), so you can use them out-of-the-box. You can use the following syntax: `<&ICON_NAME>`.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img57d76f6029b84bd676e7439771aebb95" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('57d76f6029b84bd676e7439771aebb95')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('57d76f6029b84bd676e7439771aebb95')"></td><td><div onclick="javascript:ljs('57d76f6029b84bd676e7439771aebb95')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre57d76f6029b84bd676e7439771aebb95"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
  Login&lt;&amp;person&gt; | "MyName   "
  Password&lt;&amp;key&gt; | "****     "
  [Cancel &lt;&amp;circle-x&gt;] | [OK &lt;&amp;account-login&gt;]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="171" height="70" src="https://plantuml.com/imgw/img-57d76f6029b84bd676e7439771aebb95.png"></p></div></td></tr></tbody></table>

The complete list is available on OpenIconic Website, or you can use the following special diagram:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgf2196305965375c5626ac53710242b3c" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('f2196305965375c5626ac53710242b3c')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('f2196305965375c5626ac53710242b3c')"></td><td><div onclick="javascript:ljs('f2196305965375c5626ac53710242b3c')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pref2196305965375c5626ac53710242b3c"><code onmouseover="az=1" onmouseout="az=0">@startuml
listopeniconic
@enduml
</code></pre><p></p><p><img loading="lazy" width="889" height="502" src="https://plantuml.com/imgw/img-f2196305965375c5626ac53710242b3c.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Add title, header, footer, caption or legend

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img319c798fb6e728edd510ee6603cc4ef3" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('319c798fb6e728edd510ee6603cc4ef3')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('319c798fb6e728edd510ee6603cc4ef3')"></td><td><div onclick="javascript:ljs('319c798fb6e728edd510ee6603cc4ef3')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre319c798fb6e728edd510ee6603cc4ef3"><code onmouseover="az=1" onmouseout="az=0">@startsalt
title My title
header some header
footer some footer
caption This is caption
legend
The legend
end legend

{+
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}

@endsalt
</code></pre><p></p><p><img loading="lazy" width="150" height="214" src="https://plantuml.com/imgw/img-319c798fb6e728edd510ee6603cc4ef3.png"></p></div></td></tr></tbody></table>

_(See also: [Common commands](https://plantuml.com/en/commons))_

## ![](https://plantuml.com/backtop1.svg "Back to top")Zoom, DPI

### Whitout zoom (by default)

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img48a1a9ab7a1e44e941c738dd41955cb7" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('48a1a9ab7a1e44e941c738dd41955cb7')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('48a1a9ab7a1e44e941c738dd41955cb7')"></td><td><div onclick="javascript:ljs('48a1a9ab7a1e44e941c738dd41955cb7')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre48a1a9ab7a1e44e941c738dd41955cb7"><code onmouseover="az=1" onmouseout="az=0">@startsalt
{
  &lt;&amp;person&gt; Login  | "MyName   "
  &lt;&amp;key&gt; Password  | "****     "
  [&lt;&amp;circle-x&gt; Cancel ] | [ &lt;&amp;account-login&gt; OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="180" height="70" src="https://plantuml.com/imgw/img-48a1a9ab7a1e44e941c738dd41955cb7.png"></p></div></td></tr></tbody></table>

### Scale

You can use the `scale` command to zoom the generated image.

You can use either a number or a fraction to define the scale factor. You can also specify either width or height (in pixel). And you can also give both width and height: the image is scaled to fit inside the specified dimension.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img9bcaab86995d76adcc44cc0c421b0d19" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('9bcaab86995d76adcc44cc0c421b0d19')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('9bcaab86995d76adcc44cc0c421b0d19')"></td><td><div onclick="javascript:ljs('9bcaab86995d76adcc44cc0c421b0d19')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre9bcaab86995d76adcc44cc0c421b0d19"><code onmouseover="az=1" onmouseout="az=0">@startsalt
scale 2
{
  &lt;&amp;person&gt; Login  | "MyName   "
  &lt;&amp;key&gt; Password  | "****     "
  [&lt;&amp;circle-x&gt; Cancel ] | [ &lt;&amp;account-login&gt; OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="361" height="141" src="https://plantuml.com/imgw/img-9bcaab86995d76adcc44cc0c421b0d19.png"></p></div></td></tr></tbody></table>

_(See also: [Zoom on Common commands](https://plantuml.com/en/commons#zw5yrgax40mpk362kjbn))_

### DPI

You can also use the `skinparam dpi`command to zoom the generated image.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgd51a6e62a7d6191f3c29919330f6f3f2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('d51a6e62a7d6191f3c29919330f6f3f2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('d51a6e62a7d6191f3c29919330f6f3f2')"></td><td><div onclick="javascript:ljs('d51a6e62a7d6191f3c29919330f6f3f2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pred51a6e62a7d6191f3c29919330f6f3f2"><code onmouseover="az=1" onmouseout="az=0">@startsalt
skinparam dpi 200
{
  &lt;&amp;person&gt; Login  | "MyName   "
  &lt;&amp;key&gt; Password  | "****     "
  [&lt;&amp;circle-x&gt; Cancel ] | [ &lt;&amp;account-login&gt; OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="376" height="147" src="https://plantuml.com/imgw/img-d51a6e62a7d6191f3c29919330f6f3f2.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Include Salt "on activity diagram"

You can [read the following explanation](http://forum.plantuml.net/2427/salt-with-minimum-flowchat-capabilities?show=2427#q2427).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img6994f9b5ac9aa1b6dfe1adaca2e6bac2" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('6994f9b5ac9aa1b6dfe1adaca2e6bac2')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('6994f9b5ac9aa1b6dfe1adaca2e6bac2')"></td><td><div onclick="javascript:ljs('6994f9b5ac9aa1b6dfe1adaca2e6bac2')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre6994f9b5ac9aa1b6dfe1adaca2e6bac2"><code onmouseover="az=1" onmouseout="az=0">@startuml
(*) --&gt; "
{{
salt
{+
&lt;b&gt;an example
choose one option
()one
()two
[ok]
}
}}
" as choose

choose -right-&gt; "
{{
salt
{+
&lt;b&gt;please wait
operation in progress
&lt;&amp;clock&gt;
[cancel]
}
}}
" as wait
wait -right-&gt; "
{{
salt
{+
&lt;b&gt;success
congratulations!
[ok]
}
}}
" as success

wait -down-&gt; "
{{
salt
{+
&lt;b&gt;error
failed, sorry
[ok]
}
}}
"
@enduml
</code></pre><p></p><p><img loading="lazy" width="445" height="327" src="https://plantuml.com/imgw/img-6994f9b5ac9aa1b6dfe1adaca2e6bac2.png"></p></div></td></tr></tbody></table>

It can also be combined with [define macro](https://plantuml.com/en/preprocessing#macro_definition).

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imgb8c02b7c04f31459fdc7332e1c377491" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('b8c02b7c04f31459fdc7332e1c377491')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('b8c02b7c04f31459fdc7332e1c377491')"></td><td><div onclick="javascript:ljs('b8c02b7c04f31459fdc7332e1c377491')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="preb8c02b7c04f31459fdc7332e1c377491"><code onmouseover="az=1" onmouseout="az=0">@startuml
!unquoted procedure SALT($x)
"{{
salt
%invoke_procedure("_"+$x)
}}" as $x
!endprocedure

!procedure _choose()
{+
&lt;b&gt;an example
choose one option
()one
()two
[ok]
}
!endprocedure

!procedure _wait()
{+
&lt;b&gt;please wait
operation in progress
&lt;&amp;clock&gt;
[cancel]
}
!endprocedure

!procedure _success()
{+
&lt;b&gt;success
congratulations!
[ok]
}
!endprocedure

!procedure _error()
{+
&lt;b&gt;error
failed, sorry
[ok]
}
!endprocedure

(*) --&gt; SALT(choose)
-right-&gt; SALT(wait)
wait -right-&gt; SALT(success)
wait -down-&gt; SALT(error)
@enduml
</code></pre><p></p><p><img loading="lazy" width="445" height="327" src="https://plantuml.com/imgw/img-b8c02b7c04f31459fdc7332e1c377491.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Include salt "on while condition of activity diagram"

You can include `salt` on while condition of activity diagram.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img303cb5a39fef41e60a222b0159357684" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('303cb5a39fef41e60a222b0159357684')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('303cb5a39fef41e60a222b0159357684')"></td><td><div onclick="javascript:ljs('303cb5a39fef41e60a222b0159357684')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre303cb5a39fef41e60a222b0159357684"><code onmouseover="az=1" onmouseout="az=0">@startuml
start
while (\n{{\nsalt\n{+\nPassword | "****     "\n[Cancel] | [  OK   ]}\n}}\n) is (Incorrect)
  :log attempt;
  :attempt_count++;
  if (attempt_count &gt; 4) then (yes)
    :increase delay timer;
    :wait for timer to expire;
  else (no)
  endif
endwhile (correct)
:log request;
:disable service;
@enduml
</code></pre><p></p><p><img loading="lazy" width="258" height="617" src="https://plantuml.com/imgw/img-303cb5a39fef41e60a222b0159357684.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-8547](https://forum.plantuml.net/8547/mixing-wireframes-and-activity-diagrames?show=12221#a12221)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Include salt "on repeat while condition of activity diagram"

You can include `salt` on 'repeat while' condition of activity diagram.

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge089f058bbf2a3f84196c7a1c1a68dc8" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e089f058bbf2a3f84196c7a1c1a68dc8')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e089f058bbf2a3f84196c7a1c1a68dc8')"></td><td><div onclick="javascript:ljs('e089f058bbf2a3f84196c7a1c1a68dc8')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree089f058bbf2a3f84196c7a1c1a68dc8"><code onmouseover="az=1" onmouseout="az=0">@startuml
start
repeat :read data;
  :generate diagrams;
repeat while (\n{{\nsalt\n{^"Next step"\n  Do you want to continue? \n[Yes]|[No]\n}\n}}\n)
stop
@enduml
</code></pre><p></p><p><img loading="lazy" width="256" height="316" src="https://plantuml.com/imgw/img-e089f058bbf2a3f84196c7a1c1a68dc8.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-14287](https://forum.plantuml.net/14287/salt-in-activity-beta-diagrams)\]_

## ![](https://plantuml.com/backtop1.svg "Back to top")Skinparam

You can use **\[only\]** some [skinparam](https://plantuml.com/en/skinparam) command to change the skin of the drawing.

Some example:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge9c297694396e606d50a4d3a5fa96863" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e9c297694396e606d50a4d3a5fa96863')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e9c297694396e606d50a4d3a5fa96863')"></td><td><div onclick="javascript:ljs('e9c297694396e606d50a4d3a5fa96863')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree9c297694396e606d50a4d3a5fa96863"><code onmouseover="az=1" onmouseout="az=0">@startsalt
skinparam Backgroundcolor palegreen
{+
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="150" height="75" src="https://plantuml.com/imgw/img-e9c297694396e606d50a4d3a5fa96863.png"></p></div></td></tr></tbody></table>

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img3b7de23e991c4701927d30740f304873" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('3b7de23e991c4701927d30740f304873')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('3b7de23e991c4701927d30740f304873')"></td><td><div onclick="javascript:ljs('3b7de23e991c4701927d30740f304873')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre3b7de23e991c4701927d30740f304873"><code onmouseover="az=1" onmouseout="az=0">@startsalt
!option handwritten true
{+
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="150" height="75" src="https://plantuml.com/imgw/img-3b7de23e991c4701927d30740f304873.png"></p></div></td></tr></tbody></table>

FIXME

🚩 FYI, some other skinparam does not work with salt, as:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="imge3b3e27891dcb16d956516a84c5ee176" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('e3b3e27891dcb16d956516a84c5ee176')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('e3b3e27891dcb16d956516a84c5ee176')"></td><td><div onclick="javascript:ljs('e3b3e27891dcb16d956516a84c5ee176')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pree3b3e27891dcb16d956516a84c5ee176"><code onmouseover="az=1" onmouseout="az=0">@startsalt
skinparam defaultFontName monospaced
{+
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="150" height="75" src="https://plantuml.com/imgw/img-e3b3e27891dcb16d956516a84c5ee176.png"></p></div></td></tr></tbody></table>

## ![](https://plantuml.com/backtop1.svg "Back to top")Style

You can use **\[only\]** some [style](https://plantuml.com/en/style-evolution) command to change the skin of the drawing.

Some example:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img4d62efa7b5114855b9aeb82e0f1a004a" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('4d62efa7b5114855b9aeb82e0f1a004a')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('4d62efa7b5114855b9aeb82e0f1a004a')"></td><td><div onclick="javascript:ljs('4d62efa7b5114855b9aeb82e0f1a004a')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre4d62efa7b5114855b9aeb82e0f1a004a"><code onmouseover="az=1" onmouseout="az=0">@startsalt
&lt;style&gt;
saltDiagram {
  BackgroundColor palegreen
}
&lt;/style&gt;
{+
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="150" height="75" src="https://plantuml.com/imgw/img-4d62efa7b5114855b9aeb82e0f1a004a.png"></p></div></td></tr></tbody></table>

FIXME

🚩 FYI, some other style does not work with salt, as:

<table><tbody><tr><td><p>🎉 Copied!</p><img loading="lazy" width="16" height="16" id="img8456ce9a31ff81e1d236ed6b9dd08530" title="Copy to clipboard" src="https://plantuml.com/clipboard1.svg" onclick="ctc('8456ce9a31ff81e1d236ed6b9dd08530')"><br><img loading="lazy" width="16" height="16" title="Edit online" src="https://plantuml.com/edit1.svg" onclick="javascript:ljs('8456ce9a31ff81e1d236ed6b9dd08530')"></td><td><div onclick="javascript:ljs('8456ce9a31ff81e1d236ed6b9dd08530')"><p><code onmouseover="az=1" onmouseout="az=0"></code></p><pre id="pre8456ce9a31ff81e1d236ed6b9dd08530"><code onmouseover="az=1" onmouseout="az=0">@startsalt
&lt;style&gt;
saltDiagram {
  Fontname Monospaced
  FontSize 10
  FontStyle italic
  LineThickness 0.5
  LineColor red
}
&lt;/style&gt;
{+
  Login    | "MyName   "
  Password | "****     "
  [Cancel] | [  OK   ]
}
@endsalt
</code></pre><p></p><p><img loading="lazy" width="150" height="75" src="https://plantuml.com/imgw/img-8456ce9a31ff81e1d236ed6b9dd08530.png"></p></div></td></tr></tbody></table>

_\[Ref. [QA-13460](https://forum.plantuml.net/13460/there-skinparam-change-font-used-salt-like-other-diagram-types?show=13461#a13461)\]_
