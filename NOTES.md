# NOTES

Various notes and observations on the translation process. The sort of thing that might be appropriate in documentation, somewhere...

## Formatting

The conversion utililities process and generate MyST markdown formatted using the opinionated [`mdformat`](https://github.com/executablebooks/mdformat) formatter and several `mdformat` plugins:

`pip3 install mdformat mdformat-myst mdformat-tables mdformat-web`


## Converting executed notebooks to markdown

If we have a notebook, execute and render to markdown:

`jupyter nbconvert --to markdown --execute demo-notebook.ipynb`

BUT: this loses things like cell tags. So instead we need a custom `nbconvert` template to extend the output style.

https://nbconvert.readthedocs.io/en/latest/external_exporters.html

Bard suggests something like:

```python
# setup.py
from setuptools import setup

setup(
    name="my-template-package",
    version="0.1.0",
    author="Your Name",
    author_email="youremail@example.com",
    description="A custom nbconvert template package",
    packages=["my_template_package"],
    entry_points={
        "nbconvert.exporters": ["my_template = my_template_package.exporter:MyTemplateExporter"],
    },
    package_data={
        "my_template_package": [
            "templates/conf.json",
            "templates/index.md.j2",
        ],
    },
)
```

and:

```python
from nbconvert.exporters.template import TemplateExporter
from jinja2 import Environment, FileSystemLoader
from pathlib import Path

class MyTemplateExporter(TemplateExporter):

    def create_template_context(self):
        return super().create_template_context()

    def render(self, nb, resources):
            context = self.create_template_context()
            context["nb"] = nb

            template_dir = os.path.join(
                os.path.dirname(my_template_package.__file__), "templates"
            )
            loader = FileSystemLoader(template_dir)
            environment = Environment(loader=loader)

            # Load the configuration file
            conf_file = Path(template_dir, "conf.json")
            with open(conf_file) as f:
                conf = json.load(f)

            # Merge the configuration data into the context
            context.update(conf)

            # Load the main template file
            template_file = Path(template_dir, "index.md.j2")

            return environment.get_template(template_file.name).render(context=context)
            
```

and then call as: `nbconvert --to markdown --template my-template notebook.ipynb`

See also: ouxml-roundtripping / README / nbconvert myst

## Conversion to MyST for Rendering as Notebooks

One of the advantages of using MyST is that is can be rendered and edited in a Jupyter notebook user interface via a Jupytext conversion process.

The following MyST markdown example shows the the Jupytext header, unstyled  markdown and code cells, empinken tag styled markdown and code cells, and a markdown code block:

````text
---
jupytext:
  formats: ipynb,md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.15.2
kernelspec:
  display_name: Python 3 (ipykernel)
  language: python
  name: python3
---

# Header

text

+++ {"tags": ["style-commentate"]}

styled md cell

+++

unstyled md cell

```python
# some code
# in markdown
```

```{code-cell} ipython3
:tags: [style-activity]

#styled code
```

```{code-cell} ipython3
#unstyled code
```

unstyled md

````

In particular, note that:

- markdown cells are separated using a `+++` delimiter;
- markdown cell tags are identified as: `+++ {"tags": ["style-commentate"]}`
- code cells are `{code-cell}` admonition blocks;
- code cell tags are cell block attributes: `:tags: [style-activity]`

For collapsed cells, in the line before a collapsed header we add a cell beak: `+++ {"heading_collapsed": true}`. Under a collapsed header, the markdown and code cells are tagged as *hidden* (`+++ {"hidden": true}` and `:hidden: true` respectively).

A markdown cell break (`+++`) inserts a comment into the SphinxXML of the form `<comment classes="block_break" xml:space="preserve"></comment>`.

If tags are associated with the markdown cell, these are included as comment text: `<comment classes="block_break" xml:space="preserve">{"tags": ["style-commentate"]}</comment>`.

If a `{code-cell}` has a tag, the block is mapped to a `<container>` with a `cell_metadata` attribute capturing the tag(s): `<container cell_index="1" cell_metadata="{'tags': ['hide-input']}" ... > ...`.

Non-executable code in a markdown block is rendered to Sphinx-XML as a `<literal>` block:

```xml
<literal_block language="python" linenos="False" xml:space="preserve"># non-executable code
# via a markdown code block
</literal_block>
```

But a code cell's mapping is more elaborate, into a container with an embedded continer for the input:

```xml
            <container cell_index="1" cell_metadata="{'tags': ['hide-input']}" classes="cell tag_hide-input" exec_count="True" hide_mode="input" nb_element="cell_code" prompt_hide="Hide code cell {type}" prompt_show="Show code cell {type}">
                <container classes="cell_input" nb_element="cell_code_source">
                    <literal_block language="python" linenos="False" xml:space="preserve"># Code in an executable {code-cell} admonition block
import numpy as np
import pandas as pd

np.random.seed(24)
df = pd.DataFrame({'A': np.linspace(1, 10, 10)})</literal_block>
                </container>
            </container>
```

If we configure Sphinx via `_config,yml` to execute code via the `execute.execute_notebooks` setting, we also obtain an output field:

```xml
<container cell_index="1" cell_metadata="{'tags': ['hide-input']}" classes="cell tag_hide-input" exec_count="1" hide_mode="input" nb_element="cell_code" prompt_hide="Hide code cell {type}" prompt_show="Show code cell {type}">
    <container classes="cell_input" nb_element="cell_code_source">
                    <literal_block language="ipython3" linenos="False" xml:space="preserve"># Code in an executable {code-cell} admonition block
import numpy as np
import pandas as pd

np.random.seed(24)
df = pd.DataFrame({'A': np.linspace(1, 10, 10)})
df</literal_block>
    </container>
    <container classes="cell_output" nb_element="cell_code_output">
                    <literal_block classes="output text_plain" language="myst-ansi" linenos="False" xml:space="preserve">      A
0   1.0
1   2.0
2   3.0
3   4.0
4   5.0
5   6.0
6   7.0
7   8.0
8   9.0
9  10.0</literal_block>
    </container>
</container>
```

Currently, only text outputs make it into the Sphinx-XML. To embed an output image generated as cell output within a Jupyter notebook into a MyST markdown document, we can modify the `jupytext` MyST converter to insert any generated image or embedded HTML output into a specially identified markdown cell (for example, a markeddown cell tagged as `previous-cell-output`) immediately following the code cell.

## Converting SphinxXML to OU-XML


```python
from ou_xml_validator.utils import apply_xslt
SPHINX2OUXML_XSLT_PATH = "xslt/sphinxXml2ouxml.xslt"

xml_content = etree.tostring(root, pretty_print=True, encoding="utf-8")
xml_tree = apply_xslt(xml_content, SPHINX2OUXML_XSLT_PATH, set_root="Section").getroot()
```

We can flatten text, eg for search indexing, with:

```python
from ou_xml_validator.utils import flatten_to_text
flatten_to_text(xml_tree)
```
