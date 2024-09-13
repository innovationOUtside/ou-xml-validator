# OU-XML to Mindmap

import json
import glob

import plotly.graph_objects as go
import pandas as pd

from lxml import etree
import networkx as nx
from networkx.readwrite import json_graph
import unicodedata

from pathlib import Path

import plotly.express as px

import typer

app = typer.Typer()

# Utils


# ===
# via http://stackoverflow.com/questions/5757201/help-or-advice-me-get-started-with-lxml/5899005#5899005
def flatten(el):
    """Utility function for flattening XML tags."""
    if el is None:
        return
    result = [(el.text or "")]
    for sel in el:
        result.append(flatten(sel))
        result.append(sel.tail or "")
    return unicodedata.normalize("NFKD", "".join(result)) or " "


# ===


def ascii(s):
    return "".join(i for i in s if ord(i) < 128)


# NAME = "topic"
NAME = "name"

# WORDCOUNT = "wc"
# WORDCOUNT = "value"
WORDCOUNT = "size"


def simpleRoot(DG, title, currRoot):
    """Get the title of a page and add it as a topic attribute to the current node."""
    # DG.add_node(currRoot,topic=ascii(title))
    DG.add_node(currRoot)
    DG.nodes[currRoot][NAME] = ascii(title)
    DG.nodes[currRoot]["typ"] = "root"
    DG.nodes[currRoot][WORDCOUNT] = 0
    return DG


def graphMMRoot(DG, xml, currRoot=1, currNode=-1):
    """Generate the root node for a mindmap."""
    # Parse is from file - could do this form local file?
    # tree = etree.parse(xml)
    # courseRoot = tree.getroot()
    courseRoot = etree.fromstring(xml)

    # courseRoot: The course title is not represented consistently in the T151 SA docs, so we need to flatten it
    if currNode == -1:
        title = flatten(courseRoot.find("CourseTitle"))
    else:
        title = flatten(courseRoot.find("ItemTitle"))
    print(title)
    if currNode == -1:
        # DG.add_node(currRoot,topic=ascii(title))
        DG.add_node(currRoot)
        DG.nodes[currRoot][NAME] = ascii(title)
        currNode = currRoot
    else:
        # Add an edge from currRoot to incremented currNode displaying title
        print(currRoot, currNode, title, {WORDCOUNT: len(flatten(courseRoot).split())})
        DG, currNode = gNodeAdd(
            DG,
            currRoot,
            currNode,
            title,
            {WORDCOUNT: len(flatten(courseRoot).split()), "typ": "unit"},
        )
    # courseroot is the parsed xml doc
    # currNode is the node counter
    return DG, courseRoot, currNode, currRoot


def gNodeAdd(DG, root, node, name, attrs=None):
    """Add an edge from root to increment node count."""

    _attrs = {NAME: ascii(name), "expanded": False}

    # If we've passed in attributes, merge them over the default values
    attrs = _attrs if attrs is None else {**_attrs, **attrs}

    node = node + 1
    DG.add_node(node)

    # Add node attributes
    for attr in attrs:
        DG.nodes[node][attr] = attrs[attr]

    DG.add_edge(root, node)
    return DG, node


def session_parser(unit, DG, unitroot, nc):
    """Parse metadata out of each session and construct subtree of subsessions.
    Should probably handle these things recursively?"""
    sessions = unit.findall(".//Session")
    for session in sessions:
        title = flatten(session.find(".//Title"))
        if title == "":
            continue

        # This may cause issues in the tree views
        # The session count includes the section word counts?
        # Plots should show just section counts and calculate other areas from that?
        # But is there word content between the start of a session and a new section?
        DG, nc = gNodeAdd(
            DG,
            unitroot,
            nc,
            title,
            {WORDCOUNT: len(flatten(session).split()), "typ": "session"},
        )
        sessionRoot = nc

        sections = session.findall(".//Section")
        for section in sections:
            heading = section.find(".//Title")
            if heading != None:
                title = flatten(heading)
                if title.strip() != "":
                    DG, nc = gNodeAdd(
                        DG,
                        sessionRoot,
                        nc,
                        title,
                        {WORDCOUNT: len(flatten(section).split()), "typ": "section"},
                    )

    return DG, nc


def graphParsePage(
    courseRoot, DG, currRoot, currCount=-1, unit_title=False, itemTitle=False
):
    """Parse an OU-XML document."""
    if currCount == -1:
        currCount = currRoot
    unitTitle = courseRoot.find(".//ItemTitle")

    if itemTitle:
        DG, nc = gNodeAdd(DG, currRoot, currCount, flatten(unitTitle))
    else:
        nc = currCount

    units = courseRoot.findall(".//Unit")
    for unit in units:
        title = flatten(unit.find(".//Title"))
        if title == "":
            continue
        if unit_title:
            DG, nc = gNodeAdd(
                DG,
                currRoot,
                nc,
                title,
                {WORDCOUNT: len(flatten(unit).split()), "typ": "base"},
            )
        unitroot = nc
        DG, nc = session_parser(unit, DG, unitroot, nc)
    return DG, nc


def module_mindmapper(DG=None, currnode=1, rootnode=1, modulecode="Module", xmls=None):
    """Generate a mindmap from one more XML documents."""

    if DG is None:
        DG = nx.DiGraph()
        DG = simpleRoot(DG, modulecode, 1)
        currnode = 1

    if xmls is None:
        return DG, currnode

    # If we only pass in a single XML doc rather than a list of docs, use a list format
    xmls = xmls if isinstance(xmls, list) else [xmls]

    # Process each OU-XML document
    for xml in xmls:
        # Should test before doing this?
        # Need a reg exp way of doing this
        for cleaner in [
            "<?sc-transform-do-oumusic-to-unicode?>",
            "<?sc-transform-do-oxy-pi?>",
            '<?xml version="1.0" encoding="utf-8"?>',
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<?xml version="1.0" encoding="UTF-8" standalone="no"?>',
        ]:
            xml = xml.replace(cleaner, "")
        # print(xml[:100])

        # By default, parse all the docs into a single tree
        # Add a node for each new OU-XML doc to the root node
        DG, courseRoot, currnode, rootnode = graphMMRoot(DG, xml, rootnode, currnode)

        # Add the subtree for each doc to the corresponding node
        DG, currnode = graphParsePage(courseRoot, DG, currnode)
    return DG, currnode


template_jsmind_html = """
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>{title}</title>
        <link
            type="text/css"
            rel="stylesheet"
            href="https://cdn.jsdelivr.net/npm/jsmind@0.8.5/style/jsmind.css"
        />
        <style type="text/css">
            #jsmind_container {{
                width: 100vw;
                height: 100vh;
                border: solid 1px #ccc;
                background: #f4f4f4;
            }}
        </style>
    </head>

    <body>
        <div id="jsmind_container"></div>
        <script src="https://cdn.jsdelivr.net/npm/jsmind@0.8.5/es6/jsmind.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/jsmind@0.8.5/es6/jsmind.draggable-node.js"></script>
        <script type="text/javascript">
            function load_jsmind() {{
                var mind = {full_node_array}
                var options = {{
                    container: 'jsmind_container',
                    editable: true,
                    theme: 'primary',
                }};
                var jm = new jsMind(options);
                jm.show(mind);
                // jm.set_readonly(true);
                // var mind_data = jm.get_data();
                // alert(mind_data);
                //jm.add_node('sub2', 'sub23', 'new node', {{ 'background-color': 'red' }});
                //jm.set_node_color('sub21', 'green', '#ccc');
            }}

            load_jsmind();
        </script>
    </body>
</html>
"""


## JSMIND
# JSON format for jsmind http://hizzgdev.github.io/jsmind/
# Claude
def digraph_to_jsmind_format(G, json_format=False):
    def process_node(node):
        data = G.nodes[node]
        node_data = {
            "id": str(node),
            "topic": data.get("name", str(node)),
        }

        if G.in_degree(node) == 0:
            node_data["isroot"] = True
        else:
            parent = list(G.predecessors(node))[0]
            node_data["parentid"] = str(parent)

        # Add any additional attributes from the node data
        for key, value in data.items():
            if key not in ["name"]:
                node_data[key] = value

        return node_data

    jsmind_data = [process_node(node) for node in G.nodes()]
    if json_format:
        return json.dumps(jsmind_data)

    return jsmind_data


# digraph_to_jsmind_format(xx[0], True)


# TO DO - walk the tree and calculate a size attribute for each node based on something
# eg wordcount. Build this up from leaf values.
# size attribute can then be used by netwulf

# Possibly useful:
# https://stackoverflow.com/questions/51914087/i-have-a-recursive-function-to-validate-tree-graph-and-need-a-return-condition
# https://stackoverflow.com/a/49315058/454773
# Maybe:
# Find leaf nodes and set a size for them:
# [x for x in G.nodes() if G.out_degree(x)==0 and G.in_degree(x)==1]
# Then starting at root, find successors, for each successor, recurse,
# then size set to sum of returned values over all successors and return size as value;;
# if leaf, return value;


def generate_mindmap(DG, filename=None, typ="jsmind", title="course map"):
    """Save a networkx graph as a JSON file."""
    filename = "testmm.html" if filename is None else filename

    if DG is not None:
        data = json_graph.tree_data(DG, root=1)

        if typ == "jsmind":

            # jsondata = json.dumps(data)

            data = {
                "meta": {"name": "example", "author": "th", "version": "0.2"},
                "format": "node_array",
                "data": digraph_to_jsmind_format(DG, False),
            }
            jsondata = json.dumps(data)

            # Node tree format for http://hizzgdev.github.io/jsmind/example/2_features.html
            # with open(filename, "w") as o:
            #    o.write(jsondata)

            with open(filename, "w") as f:
                f.write(template_jsmind_html.format(full_node_array=jsondata, title=title))

            print(f"Mindmap output HTML file: {filename}")

        # _save_mindmap(jsondata, filename=filename)


def get_named_edgelist(G):
    # Get the edge list with node IDs
    df = nx.to_pandas_edgelist(G)

    # Create a mapping of node IDs to names
    name_map = nx.get_node_attributes(G, "name")
    size_map = nx.get_node_attributes(G, "size")

    # If some nodes don't have 'name' attribute, use the node ID as fallback
    name_map = {node: name_map.get(node, node) for node in G.nodes()}

    # Replace source and target IDs with names
    df["source_label"] = df["source"].map(name_map)
    df["target_label"] = df["target"].map(name_map)
    df["size"] = df["target_label"].map(
        lambda x: size_map.get(
            next(node for node, name in name_map.items() if name == x), None
        )
    )

    return df


def plotly_treemap(DG, filename=None, display=True):
    df = get_named_edgelist(DG)
    # fig = px.treemap(
    #    names=df[
    #        "target"
    #    ].to_list(),  # ["Robotics study week 1 Introduction", "Robotics study week 2 Things that think", "1 Introduction", "1.1 Learning outcomes"],
    #    parents=df[
    #        "source"
    #    ].to_list(),  # [ "Module","Module" , "Robotics study week 2 Things that think", "1 Introduction" ],
    #    # values = df["size"].to_list()
    # )
    fig = go.Figure(go.Treemap(
        parents = df['source'],
        values=[1]*len(df['source']),
        labels =  df['target_label'],
        ids = df['target'],
    ))
    fig.update_layout(
        uniformtext=dict(minsize=10, mode="show"), 
        margin=dict(t=50, l=25, r=25, b=25)
    )

    # fig.update_traces(root_color="lightgrey")
    fig.update_layout(margin=dict(t=50, l=25, r=25, b=25))

    if filename is not None:
        fig.write_html(filename)
        print(f"Treemap output HTML file: {filename}")
    if display:
        fig.show()


# -- notebook mindmapper from claude.ai
import json
import re
from nbformat import read as read_notebook


def extract_headings_from_markdown(markdown_text, max_level=6):
    """
    Extract headings from markdown text, ignoring code blocks.

    Args:
    markdown_text (str): The markdown text to parse
    max_level (int): The maximum heading level to extract (default: 6)

    Returns:
    list of tuples: (heading level, heading text)
    """
    # Remove code blocks
    code_block_pattern = r"```[\s\S]*?```"
    markdown_text = re.sub(code_block_pattern, "", markdown_text)

    # Extract headings
    heading_pattern = r"^(#{1," + str(max_level) + r"})\s+(.+)$"
    headings = []

    for line in markdown_text.split("\n"):
        match = re.match(heading_pattern, line)
        if match:
            level = len(match.group(1))
            text = match.group(2).strip()
            headings.append((level, text))

    return headings


def parse_jupyter_notebook(notebook_path, max_heading_level=6):
    """
    Parse a Jupyter notebook and extract headings from markdown cells.

    Args:
    notebook_path (str): Path to the Jupyter notebook file
    max_heading_level (int): Maximum heading level to extract (default: 6)

    Returns:
    list of tuples: (heading level, heading text)
    """
    with open(notebook_path, "r", encoding="utf-8") as f:
        notebook = read_notebook(f, as_version=4)

    all_headings = []

    for cell in notebook.cells:
        if cell.cell_type == "markdown":
            cell_headings = extract_headings_from_markdown(
                cell.source, max_heading_level
            )
            all_headings.extend(cell_headings)

    return all_headings


def integrate_notebook_headings(DG, notebook_path, parent_node, current_node):
    """
    Integrate headings from a Jupyter notebook into the existing graph structure.

    Args:
    DG (networkx.DiGraph): The existing graph
    notebook_path (str): Path to the Jupyter notebook file
    parent_node (int): The node ID to attach the notebook node to
    current_node (int): The current node ID for new nodes

    Returns:
    tuple: (Updated DiGraph, Next available node ID)
    """
    headings = parse_jupyter_notebook(notebook_path)

    # Create a node for the notebook itself
    notebook_name = Path(notebook_path).stem
    DG, notebook_node = gNodeAdd(
        DG, parent_node, current_node, notebook_name, {"typ": "notebook"}
    )
    current_node += 1

    level_to_node = {0: notebook_node}

    for level, text in headings:
        # Find the closest parent level
        parent_level = max(l for l in level_to_node.keys() if l < level)
        parent = level_to_node[parent_level]

        DG, current_node = gNodeAdd(
            DG, parent, current_node, text, {"typ": f"notebook_h{level}"}
        )
        level_to_node[level] = current_node
        current_node += 1

    return DG, current_node


def process_directory(DG, dir_path, parent_node, current_node):
    """
    Process a directory, creating nodes for subdirectories and notebooks.

    Args:
    DG (networkx.DiGraph): The existing graph
    dir_path (Path): Path to the directory
    parent_node (int): The node ID to attach this directory to
    current_node (int): The current node ID for new nodes

    Returns:
    tuple: (Updated DiGraph, Next available node ID)
    """
    # Create a node for the directory
    dir_name = dir_path.name
    DG, dir_node = gNodeAdd(
        DG, parent_node, current_node, dir_name, {"typ": "directory"}
    )
    current_node += 1

    # Process subdirectories
    for subdir in sorted(dir_path.glob("*")):
        if subdir.is_dir():
            DG, current_node = process_directory(DG, subdir, dir_node, current_node)

    # Process notebooks in this directory
    for notebook in sorted(dir_path.glob("*.ipynb")):
        DG, current_node = integrate_notebook_headings(
            DG, str(notebook), dir_node, current_node
        )

    return DG, current_node


@app.command()
def convert_to_mindmap(
    source: list[str] = typer.Argument(
        ...,
        help="Source file(s), directory, or glob pattern",
    ),
    file_type: str = typer.Option(
        "xml",
        "--type",
        "-t",
        help="File type to process: 'xml' or 'ipynb'",
    ),
    modulecode: str = typer.Option("MODULE", "--modulecode", "-m", help="Module code"),
    output_file: Path = typer.Option(
        None,
        "--output",
        "-o",
        help="Output filename or path/filename",
        file_okay=True,
        dir_okay=False,
        writable=True,
        resolve_path=True,
    ),
    use_treemap: bool = typer.Option(False, "--use-treemap", "-u", help="Use treemap"),
):
    """Generate a mindmap view from one or more XML or Jupyter Notebook files."""
    if file_type not in ["xml", "ipynb"]:
        raise typer.BadParameter("File type must be either 'xml' or 'ipynb'")

    srctyp = "-nb" if file_type=="ipynb" else "-VLE"
    if output_file is None:
        subscript = "_tm" if use_treemap else "_mm"
        output_file = f"{modulecode}{subscript}{srctyp}.html"

    DG = nx.DiGraph()
    DG = simpleRoot(DG, f"{modulecode}{srctyp}", 1)
    current_node = 2  # Start from 2 as 1 is the root node

    for path in source:
        path = Path(path)
        if path.is_dir():
            if file_type == "ipynb":
                DG, current_node = process_directory(DG, path, 1, current_node)
            else:  # xml
                for xml_file in sorted(path.glob("*.xml")):
                    with open(xml_file, "r", encoding="utf-8") as f:
                        xml_content = f.read()
                    DG, current_node = module_mindmapper(
                        DG=DG, currnode=current_node, rootnode=1, xmls=[xml_content]
                    )
        elif path.is_file():
            if file_type == "ipynb" and path.suffix.lower() == ".ipynb":
                DG, current_node = integrate_notebook_headings(
                    DG, str(path), 1, current_node
                )
            elif file_type == "xml" and path.suffix.lower() == ".xml":
                with open(path, "r", encoding="utf-8") as f:
                    xml_content = f.read()
                DG, current_node = module_mindmapper(
                    DG=DG, currnode=current_node, rootnode=1, xmls=[xml_content]
                )

    if use_treemap:
        plotly_treemap(DG, filename=output_file, display=False)
    else:
        generate_mindmap(DG, filename=output_file, title=modulecode)

    typer.echo(f"Mindmap generated: {output_file}")


def main():
    """Run the application to convert markdown to OU-XML."""
    app()
