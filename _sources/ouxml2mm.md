# Interactive Mindmap and Treemap Views

We can generate interactive mindmap and treemap views over the navigational heading structure of an OU-XML document:

- interactive mindmap view — [example](./examples/TM129_mm.html) — (using [jsmind](https://jsmind.online/#sample)):

![Example module treemap (partial)](images/mindmap.png)

- interactive treemap view — [example](./examples/TM129_tm.html) — ([plotly treemap](https://plotly.com/python/treemaps/): note that the text layout is a bit dodgy!)

![Example module treemap (partial)](images/treemap.png)

Use the `--use_treemap`/`-t`switch to generate treemap files.

Examples:

`ouseful_ouxml2mm Downloads/tm129_24j-week*.xml -m TM129 -t`

`ouseful_ouxml2mm Downloads/tm129_24j-week1.xml Downloads/tm129_24j-week2.xml`

