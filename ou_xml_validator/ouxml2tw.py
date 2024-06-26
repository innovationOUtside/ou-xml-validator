"""Follows the pattern of md2ouxml.py. originally by Mark Hall."""


"""
TO DO:
    insert_jupytext_header: true
    activate_code_cells: true # eg if we want to use as executable nb
    code_language: python # the default codestyling language
    code_cell_language: ipython3 # the default execution code langauge
    handle Mark's activity tag
    add sphinx exercise tag
"""

import re
import typer

from lxml import etree
from pathlib import Path
from yaml import safe_load

from .xml_xslt import get_file

DEFAULT_LANG = "python"

app = typer.Typer()


def apply_xml_fixes(
    config: dict,
    node: etree.Element,
) -> None:
    """Hacks to clean the OU-XML prior to conversion to markdown.
    The must be non-lossy in all essential respects if we are to support round-tripping.
    """
    subconfig = config.get("ou", {}).get("ouxml2md", {})
    if node.tag == "Title":
        if node.text and subconfig.get("remove_header_numbering", False):
            pattern = r"^\d+(\.\d+)*\s+"
            node.text = re.sub(pattern, "", node.text)
    elif node.tag == "Caption":
        if node.text and subconfig.get("remove_figure_numbering", False):
            # Define a regular expression pattern to match the figure number
            pattern = r"^Figure \d+(\.\d+)*\s+"
            node.text = re.sub(pattern, "", node.text)
    elif node.tag == "ProgramListing":
        node.set("language", subconfig.get("code_lang", DEFAULT_LANG))
        first_para = node.find(".//Paragraph")
        if len(first_para):
            if first_para.text.startswith("`"):
                consecutive_backticks = re.match(r"`+", first_para.text)
                fence_len = (
                    len(consecutive_backticks.group(0)) if consecutive_backticks else 3
                )
                node.set("fence", "`" * (fence_len + 1))
                node.set("language", "text")

    for child in node:
        apply_xml_fixes(
            config,
            child,
        )


def transform_xml2tw(xml, config, xslt="templates/ouxml2tiddlywiki.xslt", output_path_stub=""):
    """Take an OU-XML document as a string
    and transform the document to tiddlywiki files."""
    subconfig = config.get("ou", {}).get("ouxml2tw", {})
    subconfig["code_lang"] = subconfig.get("code_lang", DEFAULT_LANG)
    myst = subconfig.get("myst", True)
    # TO DO  - the stylesheet should depend on the md flavour
    # By default use myst, but TO DO  also add support for simple md
    # TO DO - propagate in kernel displayname, name and language from settings
    xml_ = Path(xml)
    if xml_.suffix == ".xml" and xml_.is_file():
        with open(xml_, "r") as f:
            xml_raw = f.read()
    else:
        print(f"Can't find {xml_raw}?")
        return None

    # Make sure the output directory exisit
    Path(output_path_stub).parent.mkdir(parents=True, exist_ok=True)

    _xslt = get_file(xslt)

    xslt_doc = etree.fromstring(_xslt)
    xslt_transformer = etree.XSLT(xslt_doc)

    source_doc = etree.fromstring(xml_raw.encode("utf-8"))
    apply_xml_fixes(config, source_doc)

    # It would be handy if we could also retrieve what files the transformer generated?
    # Perhaps better, generate a _toc.yml file?
    # what is the output doc? Is it the root node?
    output_doc = xslt_transformer(
        source_doc,
        filestub=etree.XSLT.strparam("{}".format(output_path_stub)),
        myst=etree.XSLT.strparam(str(myst)),
    )
    # print(output_doc)


@app.command()
def convert_to_markdown(
    source: str,
    config: str = "./_config.yml",
    xslt: str = "xslt/ouxml2tw.xslt",
    output_path_stub: str = "",
    regenerate: bool = False,
    numbering_from: int = 1,
):  # noqa: FBT001 FBT002
    """Convert an OU-XML file into markdown."""
    if Path(config).is_file():
        with open(Path(config)) as in_f:
            config = safe_load(in_f)
    else:
        config = {}
    # Check if the source is a directory
    source = Path(source)
    if source.is_dir():
        # If it's a directory, process each file in the directory
        #
        for file_path in source.glob("*.xml"):
            transform_xml2tw(
                file_path,
                config,
                xslt=xslt,
                output_path_stub=f"{output_path_stub}{file_path.stem}",
            )
    else:
        transform_xml2tw(source, config, xslt=xslt, output_path_stub=output_path_stub)


def main():
    """Run the application to convert markdown to OU-XML."""
    app()


# Generate OU-XML from md
# jb build . --builder custom --custom-builder xml
# ouseful_obt .

# OU-XML to markdown
# ouseful_ouxml2myst XML STUB
