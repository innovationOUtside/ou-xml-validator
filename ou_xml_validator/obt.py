"""Original code from OU Book Theme CLI application."""
"""Original author: Mark Hall, The Open Univerity."""
"""Extend by: Tony Hirst, The Open Univerity."""
from datetime import UTC, datetime
from os import makedirs, path
from shutil import copy, rmtree
from subprocess import run
from urllib.parse import urljoin

import typer
from lxml import etree
from rich import print as stdout
from rich.progress import Progress
from yaml import safe_load
import pkg_resources
import os
import zipfile
import uuid

from .xml_xslt import get_file

app = typer.Typer()


def hack_uuid():
    while True:
        # Generate a random UUID
        uid = uuid.uuid4().hex
        # There are conditions...
        # - first character is not a digit
        # - max 20 chars
        if not uid[0].isdigit():
            return uid[:20]
        
def xpath_single(start: etree.Element, xpath: str):
    """Retrieve a single element using XPath."""
    return start.xpath(xpath)[0]


def create_text_node(tag: str, text: str) -> etree.Element:
    """Create a new text node."""
    element = etree.Element(tag)
    element.text = text
    return element


def fix_sub_list(node: etree.Element):
    """Fix the nested list tags."""
    # Fix sub lists so that they use the correct tags
    if node.tag == "BulletedList":
        node.tag = "BulletedSubsidiaryList"
    elif node.tag == "NumberedList":
        node.tag = "NumberedSubsidiaryList"
    elif node.tag == "ListItem":
        node.tag = "SubListItem"
    for child in node:
        fix_sub_list(child)

# TO DO - should we pass a prefixex dict?
def apply_fixes(
    config: dict,
    source: str,
    node: etree.Element,
    module_code: str,
    block: int,
    part: int,
    presentation: str,
    counters: dict,
    part_title: str,
    toc: dict,
    item_title: str,
    use_caption_as_title: bool,
    backmatter: dict,
    # noqa: FBT001
) -> None:
    """Apply a range of post-processing fixes."""
    # Postprocessing required:
    # * Remove non-document cross-links
    image_path_prefix = config["ou"]["image_path_prefix"] if "image_path_prefix" in config["ou"] else ""
    audio_path_prefix = config["ou"]["audio_path_prefix"] if "audio_path_prefix" in config["ou"] else ""

    if node.tag == "olink":
        targetdoc = node.get("targetdoc")
        if targetdoc:
            # If presented with filename#id in targetptr, we need to:
            # - use the id as targetptr
            # - check the filename for use as targetdoc (the name/heading of the doc):
            #   - if the filename is consumed as a part chapter, use the part name/heading
            #   - if the filename is from elsewhere, it should take the name of the part it is from
            #     [CURRENTLY PARTIALLY BROKEN]
            if targetdoc.startswith("#"):
                node.set("targetptr", targetdoc.split("#")[1])
                targetdoc = part["caption"] if use_caption_as_title else item_title.replace("$PART_TITLE", part_title)
                node.set("targetdoc", targetdoc)
            # A document is referenced...
            # ...so let's see if it's a document in the _toc.yml
            elif "parts" in toc:
                # Check each part...
                for part in toc["parts"]:
                    # ...and each file in each part...
                    for filenames in part["chapters"]:
                        # If we are referencing a file in a part...
                        if "#" in targetdoc and targetdoc.startswith(filenames["file"]):
                            node.set("targetptr", targetdoc.split("#")[1])
                            targetdoc = (
                                part["caption"]
                                if use_caption_as_title
                                else item_title.replace("$PART_TITLE", part_title)
                            )
                            # ...set the targetdoc appropriately
                            node.set("targetdoc", targetdoc)
                        # TO DO - if we have just passed eg a filename and no suffix
                        # and no #, or ending .md, if we assume first header is same
                        # name as the filename, we can repair the link to FILENAME.md#FILENAME
            else:
                # Check to see if the targetdoc is a chapter file...
                for filenames in toc["chapters"]:
                    # ...and if it is, use that as the targetdoc
                    if "#" in targetdoc and targetdoc.startswith(filenames["file"]):
                        node.set("targetptr", targetdoc.split("#")[1])
                        node.set("targetdoc", item_title.replace("$PART_TITLE", part_title))
            # We now do another fix:
            # - if the targetdoc is the current doc, i.e. link is within the doc, use a CrossRef
            # https://learn3.open.ac.uk/mod/oucontent/view.php?id=185750&section=5
            if node.get("targetdoc") == item_title.replace("$PART_TITLE", part_title):
                node.tag = "CrossRef"
                node.attrib["idref"] = node.attrib.pop("targetptr")
                node.attrib.pop("targetdoc")
    elif node.tag == "ProgramListing":
        # Add paragraphs into block-level computer displays
        lines = etree.tostring(node, encoding=str).strip()
        lines = lines[len("<ProgramListing typ='esc'>") : -len("</ProgramListing>")]
        lines = lines.split("\n")
        if lines[-1].strip() == "":
            lines = lines[:-1]
        if node.get("typ")=="rawx":
            pass
        elif node.get("typ")=="raw":
            para = etree.Element("Paragraph")
            para.text = None
            for line in lines:
                br = etree.Element("br")
                para.append(br)
                br.tail = line
            node.text = None
            node.append(para)
        else:
            node.text = None
            for line in lines:
                para = etree.Element("Paragraph")
                para.text = line
                node.append(para)
        # Delete the typ attribute
        del node.attrib["typ"]
        
    elif node.tag == "Reference":
        # Remove paragraphs from references
        if len(node) == 1:
            node.text = node[0].text
            para = node[0]
            del node[0]
            node.extend(para)
    elif node.tag == "Table":
        # Fix table heads
        thead = None
        tbody = None
        has_caption = False
        for child in node:
            if child.tag == "thead":
                thead = child
            elif child.tag == "tbody":
                tbody = child
            elif child.tag == "TableHead":
                has_caption = True
        if thead is not None and tbody is not None:
            for row in thead:
                for cell in row:
                    cell.tag = "th"
                    cell.attrib["class"] = "ColumnHeadLeft"
            for row in reversed(thead):
                tbody.insert(0, row)
            node.remove(thead)
        if not has_caption:
            node.insert(0, create_text_node("TableHead", ""))
    elif node.tag == "Title":
        parent = node.getparent()
        parent_previous_sibling = parent.getprevious()
        # Check if the parent is a Session tag and has no previous Session siblings
        if parent.tag == "Session" and (parent_previous_sibling is None or parent_previous_sibling.tag != "Session"):
            if "overwrite" in config["ou"] and "introduction_title" in config["ou"]["overwrite"]:
                node.text = config["ou"]["overwrite"]["introduction_title"]
        # Add numbers to the titles
        if parent.tag == "Session":
            counters["session"] = counters["session"] + 1
            node.text = f'{counters["session"]} {node.text}'
            counters["section"] = 0
        elif parent.tag == "Section":
            counters["section"] = counters["section"] + 1
            node.text = f'{counters["session"]}.{counters["section"]} {node.text}'
    elif node.tag == "Caption":
        # Add figure numbering
        # Also support figure level numbering
        # numfig_secnum_depth
        # WARNING: this is at odds with Sphinx, where the default is numfig_secnum_depth:1
        counters["figure"] += 1
        numfig_secnum_depth = config["sphinx"]["config"].get("numfig_secnum_depth", 0)
        if numfig_secnum_depth == 1:
            if "figure_ref" not in counters:
                counters["figure_ref"] = {counters["session"]: 0}
            elif counters["session"] not in counters["figure_ref"]:
                counters["figure_ref"][counters["session"]] = 0
            counters["figure_ref"][counters["session"]] += 1
            node.text = f'Figure {counters["session"]}.{counters["figure_ref"][counters["session"]]} {node.text}'
        else:
            node.text = f'Figure {counters["figure"]} {node.text}'
    elif node.tag == "TableHead":
        # Add table numbering
        counters["table"] = counters["table"] + 1
        node.text = f'Table {counters["table"]} {node.text}'
    elif node.tag == "Mermaid":
        # Render the Mermaid graphs
        #mermaid_cli = files("ou_book_theme.cli") / "mermaid-cli"
        #with as_file(mermaid_cli) as mermaid_cli_path:
        resource_path = pkg_resources.resource_filename(__name__, 'mermaid-cli/package.json')
        mermaid_cli_path = os.path.dirname(resource_path)
        run(["npm", "install"], cwd=mermaid_cli_path, capture_output=True, check=True)  # noqa: S603 S607
        filename = f'{module_code.lower()}_b{block}_p{part}_{presentation.lower()}_fig{counters["figure"]}.png'
        filepath = path.join(source, "_build", "ouxml", filename)
        run(
            [path.join(mermaid_cli_path, "node_modules", ".bin", "mmdc"), "-i", "-", "-o", filepath],  # noqa: S603
            input=node.text.encode(),
            capture_output=True,
            check=True,
        )
        img = etree.Element("Image")
        img.attrib["src"] = urljoin(image_path_prefix, filename)
        node.getparent().replace(node, img)
    elif node.tag == "Image":
        # Copy images
        image_src = path.join(source, node.attrib["src"])
        if path.exists(image_src):
            filename = f'{module_code.lower()}_b{block}_p{part}_{presentation.lower()}_fig{counters["figure"]}.png'
            filepath = path.join(source, "_build", "ouxml", filename)
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            copy(image_src, filepath)
            node.attrib["src"] = urljoin(image_path_prefix, filename)
    elif node.tag == "MediaContent":
        if "type" in node.attrib and node.attrib["type"]=="html5":
            # This seems to expect:
            # - id, height and width attributes to be set
            # - a link to a zip file
            # - zip file must contain at least index.html
            node.set("height", "200")
            node.set("width", "600")

            filename_stub = f'{module_code.lower()}_b{block}_p{part}_{presentation.lower()}_html{counters["html"]}'
            filename = "index.html"
            zipfilename = f"{filename_stub}.zip"
            zipfilepath = path.join(source, "_build", "ouxml", zipfilename)
            with zipfile.ZipFile(zipfilepath, "w", zipfile.ZIP_DEFLATED) as zf:
                zf.writestr(filename, node.text)
            counters["html"] += 1
            node.text = None
            node.attrib["id"] = hack_uuid()
            node.attrib["src"] = urljoin(audio_path_prefix, zipfilename)
        elif "src" in node.attrib:
            media_src = path.join(source, node.attrib["src"])
            filename = node.attrib["src"]
            if path.exists(media_src):
                filename = f'{module_code.lower()}_b{block}_p{part}_{presentation.lower()}_media_{os.path.basename(filename)}'
                # TO DO - better naminmg convention
                # TO DO - Needs a corresponding counter?
                filepath = path.join(source, "_build", "ouxml", filename)
                os.makedirs(os.path.dirname(filepath), exist_ok=True)
                copy(media_src, filepath)
                node.attrib["src"] = urljoin(audio_path_prefix, filename)
            else:
                stdout(f"can't find {media_src}")
            if node.attrib["type"]=="audio":
                node.attrib["src"] = urljoin(audio_path_prefix, filename)
    elif node.tag == "Activity":
        # Wrap the activity content in a Question
        question = None
        for child in list(node):
            if child.tag not in ["Heading", "Timing", "Question", "Answer"]:
                if question is None:
                    question = etree.Element("Question")
                    node.replace(child, question)
                    question.append(child)
                else:
                    question.append(child)
    elif node.tag == "meta":
        # Fix the meta attribute part title
        node.attrib["content"] = node.attrib["content"].replace("$PART_TITLE", part_title)
    elif node.tag == "BulletedList":
        for list_item in node:
            for child in list_item:
                fix_sub_list(child)
    elif node.tag == "Paragraph" and node.text:
        if node.text.startswith("$$") and node.text.endswith("$$") and not bool(node.xpath("ancestor::ProgramListing")):
            node.text = node.text.strip("$")
            node.tag = "TeX"
            eq = etree.Element("Equation")
            parent = node.getparent()
            parent.insert(parent.index(node), eq)
            eq.append(node)
    if node.text is not None and "$PART_TITLE" in node.text:
        # Fix any in-text part titles
        node.text = node.text.replace("$PART_TITLE", part_title)

    for child in node:
        apply_fixes(
            config,
            source,
            child,
            module_code,
            block,
            part,
            presentation,
            counters,
            part_title,
            toc,
            item_title,
            use_caption_as_title,
            backmatter
        )


def transform_content(node: etree.Element, root_node: str = "Section") -> etree.Element:
    """Apply the XSLT transforms from Sphinx XML to OU XML."""
    
    stylesheet = etree.XML(get_file("templates/sphinxXml2ouxml.xslt").format(root_node=root_node))
    transform = etree.XSLT(stylesheet)
    return transform(xpath_single(node, "/document/section")).getroot()


def create_section(input_base: str, root: etree.Element, section: dict) -> None:
    """Create the structure for a single section, which writes to a single part file."""
    with open(path.join(input_base, f'{section["file"]}.xml')) as in_f:
        doc = etree.parse(in_f)  # noqa: S320
        section = transform_content(doc, root_node="Section")
        root.append(section)


def create_session(input_base: str, root: etree.Element, chapter: dict) -> None:
    """Create a sesssion within a file."""
    with open(path.join(input_base, f'{chapter["file"]}.xml')) as in_f:
        doc = etree.parse(in_f)  # noqa: S320
        session = transform_content(doc, root_node="Session")
        if "sections" in chapter:
            for section in chapter["sections"]:
                create_section(input_base, session, section)
        root.append(session)


def create_unit(config: dict, root: etree.Element, part: dict, input_base: str, unit_id: str, unit_title: str) -> None:
    """Create a single unit."""
    unit = etree.Element("Unit")
    root.append(unit)
    unit.append(create_text_node("UnitID", unit_id))
    unit.append(create_text_node("UnitTitle", unit_title))
    unit.append(create_text_node("ByLine", config["author"]))
    for chapter in part["chapters"]:
        create_session(input_base, unit, chapter)
    create_backmatter(unit, config)


def create_frontmatter(root: etree.Element, config: dict) -> None:
    """Create the frontmatter XML structure."""
    frontmatter = etree.XML(get_file("templates/ouxml_template.xml").format(config=config,
                                                                            module_code=config["ou"]["module_code"],
                                                                            module_title=config["ou"]["module_title"],
                                                                            author=config["author"],
                                                                            first_published=config["ou"]["first_published"],
                                                                            isbn=config["ou"]["isbn"],
                                                                            edition=config["ou"]["edition"],
                                                                            year=datetime.now(tz=UTC).year))
    root.append(frontmatter)


def create_backmatter(root: etree.Element, config: dict) -> None:
    """Create the backmatter XML structure."""
    node = etree.Element("BackMatter")
    root.append(node)

def create_root(config: dict, file_id: str, title: str) -> etree.Element:
    """Create the root structure."""
    module_code = config["ou"]["module_code"]
    module_title = config["ou"]["module_title"]

    root = etree.Element("Item")
    root.attrib["TextType"] = "CompleteItem"
    root.attrib["SchemaVersion"] = "2.0"
    root.attrib["id"] = file_id
    root.attrib["Template"] = "Generic_A4_Unnumbered"
    root.attrib["Rendering"] = "VLE2 staff (learn3)"
    root.attrib["DiscussionAlias"] = "Comment"
    root.attrib["vleglossary"] = "manual"
    meta = etree.Element("meta")
    meta.attrib["content"] = title
    root.append(meta)
    root.append(create_text_node("CourseCode", module_code))
    root.append(create_text_node("CourseTitle", module_title))
    root.append(etree.Element("ItemID"))
    root.append(create_text_node("ItemTitle", title))

    return root


@app.command()
def convert_to_ouxml(source: str, regenerate: bool = False, numbering_from: int = 1):  # noqa: FBT001 FBT002
    """Convert the content into OU XML."""
    input_base = path.join(source, "_build", "xml")
    if not path.exists(input_base) or regenerate:
        result = run(
            ["jb", "build", "--builder", "custom", "--custom-builder", "xml", source], check=True  # noqa: S603 S607
        )
        stdout("")
        if result.returncode == 0:
            stdout("[green]XML (re)built[/green] ✓")
            stdout("")
            stdout("[bold]Converting to OU XML[/bold]")
        else:
            stdout("[red]XML building failed[/red]")
            return
    if not path.exists(input_base):
        stdout(f"[red]Source XML directory {input_base} does not exist. Please build this first.[/red]")
    with Progress() as progress:
        clearing_task = progress.add_task("Preparing", total=3)
        output_base = path.join(source, "_build", "ouxml")
        if path.exists(output_base):
            rmtree(output_base)
        makedirs(output_base, exist_ok=True)
        progress.update(clearing_task, completed=1)

        with open(path.join(source, "_toc.yml")) as in_f:
            toc = safe_load(in_f)
        progress.update(clearing_task, completed=2)
        with open(path.join(source, "_config.yml")) as in_f:
            config = safe_load(in_f)
        progress.update(clearing_task, completed=3)

        module_code = config["ou"]["module_code"]
        block = str(config["ou"]["block"])
        presentation = config["ou"]["presentation"]
        use_caption_as_title = False if "caption_as_title" not in config["ou"] else config["ou"]["caption_as_title"]
        counters = {"session": 0, "section": 0, "figure": 0, "table": 0, "html": 0}
        backmatter = {}
        if "parts" in toc:
            main_task = progress.add_task("Converting", total=len(toc["parts"]))
            for part_idx, part in enumerate(toc["parts"]):
                part_idx = numbering_from + part_idx  # noqa: PLW2901 TODO: Clean this up
                item_title = (
                    part["caption"]
                    if use_caption_as_title
                    else f"{module_code} Block {block}, Part {part_idx}: $PART_TITLE"
                )
                root = create_root(
                    config, f"X_{module_code.lower()}_b{block}_p{part_idx}_{presentation.lower()}", item_title
                )
                create_frontmatter(root, config)
                create_unit(
                    config,
                    root,
                    part,
                    input_base,
                    f'Block {block}: {config["ou"]["block_title"]}',
                    f'{part["caption"]}: $PART_TITLE',
                )
                part_title = xpath_single(root, "/Item/Unit/Session[1]/Title/text()")
                apply_fixes(
                    config,
                    source,
                    root,
                    module_code,
                    block,
                    part_idx,
                    presentation,
                    counters,
                    part_title,
                    toc,
                    item_title,
                    use_caption_as_title,
                    backmatter,
                )

                with open(
                    path.join(output_base, f"{module_code.lower()}_b{block}_p{part_idx}_{presentation.lower()}.xml"),
                    "wb",
                ) as out_f:
                    out_f.write(etree.tostring(root, pretty_print=True, encoding="utf-8", xml_declaration=True))
                progress.update(main_task, advance=1)
        else:
            main_task = progress.add_task("Converting", total=1)
            # We can force the item name and olink reference targetdoc values from an `ou.item_title` _config.yml
            # setting
            item_title = (
                config["ou"]["item_title"] if "item_title" in config["ou"] else f"{module_code} {block}: $PART_TITLE"
            )
            root = create_root(
                config,
                # Is there a code format we can use for previewing that does not
                # duplicate any other codes?
                f"X_{module_code.lower()}_b{block.lower()}_{presentation.lower()}",
                item_title,
            )
            create_frontmatter(root, config)
            create_unit(config, root, toc, input_base, f"{block}: $PART_TITLE", f"{module_code} {block}: $PART_TITLE")
            part_title = xpath_single(root, "/Item/Unit/Session[1]/Title/text()")

            apply_fixes(
                config,
                source,
                root,
                module_code,
                block,
                1,
                presentation,
                counters,
                part_title,
                toc,
                item_title,
                use_caption_as_title,
                backmatter
            )
            with open(path.join(output_base, f"{module_code.lower()}_{block.lower()}.xml"), "wb") as out_f:
                out_f.write(etree.tostring(root, pretty_print=True, encoding="utf-8", xml_declaration=True))
            progress.update(main_task, advance=1)

def main():
    """Run the OBT application."""
    app()
