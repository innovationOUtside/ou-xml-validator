"""Follows the pattern of md2ouxml.py. originally by Mark Hall."""

import re
import typer

from lxml import etree
from pathlib import Path
from yaml import safe_load

from .xml_xslt import get_file

app = typer.Typer()

def apply_xml_fixes(config: dict, node: etree.Element,) -> None:
    """Hacks to clean the OU-XML prior to conversion to markdown.
       The must be non-lossy in all essential respects if we are to support round-tripping."""
    subconfig = config["ou"].get("ouxml2md", {})
    if node.tag == "Title":
        if node.text and subconfig.get("remove_header_captions", False):
            pattern = r'^\d+(\.\d+)*\s+'
            node.text = re.sub(pattern, '', node.text)
    elif node.tag == "Caption":
        if node.text and subconfig.get("remove_figure_captions", False):
            # TO DO - use a config param to clean figure captions
            # Define a regular expression pattern to match the figure number
            pattern = r'^Figure \d+(\.\d+)*\s+'
            node.text = re.sub(pattern, '', node.text)
    for child in node:
        apply_xml_fixes(config, child,)

def transform_xml2md(xml, config, xslt="templates/ouxml2md.xslt", output_path_stub=""):
    """Take an OU-XML document as a string 
       and transform the document to one or more markdown files."""
    subconfig = config["ou"].get("ouxml2md", {})
    myst = subconfig.get("myst", False)
    if xml.endswith('.xml') and Path(xml).is_file():
        with open(xml, 'r') as f:
            xml = f.read()
    else:
        print(f"Can't find {xml}?")
        return None

    # Make sure the output directory exisit
    Path(output_path_stub).parent.mkdir(parents=True,
                                         exist_ok=True)

    _xslt = get_file(xslt)

    xslt_doc = etree.fromstring(_xslt)
    xslt_transformer = etree.XSLT(xslt_doc)

    source_doc = etree.fromstring(xml.encode("utf-8"))
    apply_xml_fixes(config, source_doc)

    # It would be handy if we could also retrieve what files the transformer generated?
    # Perhaps better, generate a _toc.yml file?
    # what is the output doc? Is it the root node?
    output_doc = xslt_transformer(
        source_doc,
        filestub=etree.XSLT.strparam("{}".format(output_path_stub)),
        myst=etree.XSLT.strparam(str(myst))
    )
    #print(output_doc)

@app.command()
def convert_to_markdown(source: str, config: str = "./_config.yml", xslt: str = "xslt/ouxml2md.xslt", output_path_stub: str = "",  regenerate: bool = False, numbering_from: int = 1):  # noqa: FBT001 FBT002
    """Convert an OU-XML file into markdown."""
    with open(Path(config)) as in_f:
        config = safe_load(in_f)
    transform_xml2md(source, config, xslt=xslt, output_path_stub=output_path_stub)

def main():
    """Run the application to convert markdown to OU-XML."""
    app()

# Generate OU-XML from md
# jb build . --builder custom --custom-builder xml
# ouseful_obt .

# OU-XML to markdown
#ouseful_ouxml2md XML STUB