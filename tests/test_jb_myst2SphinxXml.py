"""
Simple tests of mapping MyST markdown to Sphinx-XML.
"""

import pytest
from lxml.builder import E
import subprocess
from lxml import etree
from roundtrip_data import round_trip_test_list, OU_XML, SPHINX_XML, MYST
from utils import pretty_xml_from_root, root_from_xml_string, fix_sphinxXml_nodes

c = 0
test_list = [(i[MYST], i[SPHINX_XML], c) for c, i in enumerate(round_trip_test_list)]


@pytest.mark.parametrize(
    "myst_content, expected_output, count",
    (test_list),
)
def test_apply_jb_build(pytestconfig, myst_content, expected_output, count):
    fnamestub = f"dummy{count}"
    with open(pytestconfig.rootdir / "tests" / "book" / f"{fnamestub}.md", "w") as f:
        f.write(f"# HEADER\n\n{myst_content}")
    with open(pytestconfig.rootdir / "tests" / "book" / "_toc.yml", "w") as f:
        f.write(f"root: {fnamestub}")

    _ = subprocess.run(
        "jb build ./tests/book --all --builder custom --custom-builder xml",
        shell=True,
        cwd=pytestconfig.rootdir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    xml_out = (
        pytestconfig.rootdir / "tests" / "book" / "_build" / "xml" / f"{fnamestub}.xml"
    )
    xml_clean_backup = (
        pytestconfig.rootdir / "tests" / "book" / "_buildout" / f"{fnamestub}.xml"
    )
    # shutil.copy2(
    #     xml_out,
    #     xml_clean_backup
    # )
    # xml_content = open(
    #    pytestconfig.rootdir / "tests" / "book" / "_build" / "xml" / "dummy.xml"
    # ).read()
    # xml_doc = etree.fromstring(xml_content)
    tree = etree.parse(
        xml_out, parser=etree.XMLParser(strip_cdata=False, remove_blank_text=True)
    )
    etree.cleanup_namespaces(tree)
    root = tree.getroot()
    result = root.find(".//title").getnext()
    result = root_from_xml_string(pretty_xml_from_root(result))
    fix_sphinxXml_nodes(result)
    desired = root_from_xml_string(expected_output)
    desired = root_from_xml_string(pretty_xml_from_root(desired))
    fix_sphinxXml_nodes(desired)
    assert pretty_xml_from_root(result) == pretty_xml_from_root(desired)


1
