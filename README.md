Ming Literacy Sieve
===================

Designed for Professor Schneewind's Primer Literacy project, this program filters Chinese characters that aren't present in selected primers out of the selected source text (such as steles). This provides a representation of approximately what a person educated only on those primers could read. 

## Running the Sieve
To run this software you will need to obtain a build of LuaJIT suitable for
your computer. If you are on Windows, run `launch.bat`; otherwise, use `launch.sh`.

## Adding a Text

To add a primer, save it as UTF-8 and place it in the primers subdirectory.

To add a stele, save it as UTF-8 and place it in the steles subdirectory.

After adding a text, run the sieve again and reload output.html.


## Adding a Comment to a Text

In addition to the body of a text, the system allows for comments and
information about authorship.  The title and the author are both displayed
in the user interface, so it is useful to set them.

They are set within the document itself, before the body of the text.  The
result might look something like the following:

```
:comment:
Some characters were too faded to identify.

:title: 移建朱文公祠記
:author: 陳仲述

:body:
晉江為泉州附邑...
```


## Licensing

This software is made available freely, without warranty express or
implied, and with no declaration of fitness for any purpose.

