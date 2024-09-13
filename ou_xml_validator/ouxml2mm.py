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
        <title>jsMind</title>
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


def generate_mindmap(DG, filename=None, typ="jsmind"):
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
                f.write(template_jsmind_html.format(full_node_array=jsondata))

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


@app.command()
def convert_to_mindmap(
    source: list[str] = typer.Argument(
        ...,
        help="Source file(s), directory, or glob pattern",
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
    use_treemap: bool = typer.Option(False, "--use-treemap", "-t", help="Use treemap"),
):  # noqa: FBT001 FBT002
    """Generate a mindmap view from one or more OU-XML files."""
    # Check if the source is a directory
    xmls = []
    if output_file is None:
        subscript = "_tm" if use_treemap else "_mm"
        output_file = f"{modulecode}{subscript}.html"
    for path in source:
        # Expand glob patterns
        expanded_paths = glob.glob(path, recursive=True)
        if not expanded_paths:
            # If glob didn't match anything, treat it as a literal path
            expanded_paths = [path]

        for path in expanded_paths:
            path = Path(path)
            if path.is_dir():
                # Process all files in the directory
                for file in sorted(path.glob("*.xml")):  # Adjust the pattern as needed
                    with open(file) as f:
                        xmls.append(f.read())
            else:
                # Process individual file
                with open(path) as f:
                    xmls.append(f.read())

    if xmls:
        DG, _ = module_mindmapper(modulecode=modulecode, xmls=xmls)
        if use_treemap:
            plotly_treemap(DG, filename=output_file, display=False)
        else:
            generate_mindmap(DG, filename=output_file)


def main():
    """Run the application to convert markdown to OU-XML."""
    app()
