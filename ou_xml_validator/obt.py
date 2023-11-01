"""Original code from OU Book Theme CLI application."""
"""Original author: Mark Hall, The Open Univerity."""
"""Extend by: Tony Hirst, The Open Univerity."""
from datetime import UTC, datetime
from importlib.resources import as_file, files
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

app = typer.Typer()


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
    image_path_prefix: str,
    audio_path_prefix: str,
    toc: dict,
    item_title: str,
    use_caption_as_title: bool,  # noqa: FBT001
) -> None:
    """Apply a range of post-processing fixes."""
    # Postprocessing required:
    # * Remove non-document cross-links
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
        lines = lines[len("<ProgramListing>") : -len("</ProgramListing>")]
        lines = lines.split("\n")
        if lines[-1].strip() == "":
            lines = lines[:-1]
        node.text = None
        for line in lines:
            para = etree.Element("Paragraph")
            para.text = line
            node.append(para)
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
        if "src" in node.attrib:
            media_src = path.join(source, node.attrib["src"])
            filename = node.attrib["src"]
            if path.exists(media_src):
                filename = f'{module_code.lower()}_b{block}_p{part}_{presentation.lower()}_media_{os.path.basename(filename)}'
                # TO DO - better naminmg convention
                # TO DO - Needs a corresponding counter?
                filepath = path.join(source, "_build", "ouxml", filename)
                os.makedirs(os.path.dirname(filepath), exist_ok=True)
                copy(media_src, filepath)
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
            image_path_prefix,
            audio_path_prefix,
            toc,
            item_title,
            use_caption_as_title,
        )


def transform_content(node: etree.Element, root_node: str = "Section") -> etree.Element:
    """Apply the XSLT transforms from Sphinx XML to OU XML."""
    stylesheet = etree.XML(
        f"""\
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- Section templates -->
    <xsl:template match="/section">
        <{root_node}><xsl:apply-templates/></{root_node}>
    </xsl:template>
    <xsl:template match="section">
        <InternalSection><xsl:apply-templates/></InternalSection>
    </xsl:template>

    <!-- Heading templates -->
    <xsl:template match="/section/title">
        <Title><xsl:apply-templates/></Title>
    </xsl:template>
    <xsl:template match="title">
        <Heading><xsl:apply-templates/></Heading>
    </xsl:template>

    <!-- Paragraph templates -->
    <xsl:template match="paragraph">
        <Paragraph><xsl:apply-templates/></Paragraph>
    </xsl:template>

    <!-- Admonition templates -->
    <xsl:template match="admonition">
        <Box><xsl:apply-templates/></Box>
    </xsl:template>
    <xsl:template match="hint">
        <Box><Heading>Hint</Heading><xsl:apply-templates/></Box>
    </xsl:template>
    <xsl:template match="warning">
        <Box><Heading>Warning</Heading><xsl:apply-templates/></Box>
    </xsl:template>
    <xsl:template match="attention">
        <Box><Heading>Attention</Heading><xsl:apply-templates/></Box>
    </xsl:template>
    <xsl:template match="note">
        <Box><Heading>Note</Heading><xsl:apply-templates/></Box>
    </xsl:template>

    <!-- Code block templates -->
    <xsl:template match="inline[@classes = 'guilabel']">
        <ComputerUI><xsl:apply-templates/></ComputerUI>
    </xsl:template>
    <xsl:template match="inline[@classes = 'menuselection']">
        <ComputerUI><xsl:apply-templates/></ComputerUI>
    </xsl:template>
    <xsl:template match="literal_block">
        </!-- We don't want to re-escape any escaped elements... -->
        <ProgramListing><xsl:value-of select="text()" disable-output-escaping="yes"/></ProgramListing>
    </xsl:template>
    <xsl:template match="literal">
        <ComputerCode><xsl:value-of select="text()" disable-output-escaping="yes"/></ComputerCode>
    </xsl:template>

    <!-- List templates -->
    <xsl:template match="bullet_list">
        <BulletedList><xsl:apply-templates/></BulletedList>
    </xsl:template>
    <xsl:template match="enumerated_list">
        <NumberedList><xsl:apply-templates/></NumberedList>
    </xsl:template>
    <xsl:template match="list_item">
        <ListItem><xsl:apply-templates/></ListItem>
    </xsl:template>

    <!-- Styling templates -->
    <xsl:template match="emphasis"><i><xsl:apply-templates/></i></xsl:template>
    <xsl:template match="strong"><b><xsl:apply-templates/></b></xsl:template>

    <!-- Reference templates -->
    <xsl:template match="number_reference">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="number_reference/inline">
        <xsl:value-of select="text()"/>
    </xsl:template>

    <xsl:template match="reference[@internal = 'True' and @refuri]" priority="10">
        <olink>
            <xsl:attribute name="targetdoc">
                <xsl:value-of select="@refuri" />
            </xsl:attribute>
            <xsl:attribute name="targetptr">
            </xsl:attribute>
            <xsl:apply-templates/>
        </olink>
    </xsl:template>
    <xsl:template match="reference[@refuri]">
        <a>
            <xsl:attribute name="href">
                <xsl:value-of select="@refuri"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </a>
    </xsl:template>
    <xsl:template match="reference/inline">
        <xsl:value-of select="text()"/>
    </xsl:template>
    <xsl:template match="citation">
        <Reference><xsl:apply-templates/></Reference>
    </xsl:template>
    <xsl:template match="citation/label"></xsl:template>

    <!-- Figure templates -->
    <xsl:template match="figure">
        <Figure><xsl:apply-templates/></Figure>
    </xsl:template>
    <xsl:template match="image">
        <Image>
            <xsl:attribute name="src">
                <xsl:value-of select="@uri"/>
            </xsl:attribute>
        </Image>
    </xsl:template>
    <xsl:template match="caption">
        <Caption><xsl:apply-templates/></Caption>
    </xsl:template>
    <xsl:template match="legend">
        <Description><xsl:apply-templates/></Description>
    </xsl:template>

    <xsl:template match="/section[@ids]">
        <{root_node}>
            <xsl:attribute name="id">
                <xsl:value-of select="@ids"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </{root_node}>
    </xsl:template>
    <xsl:template match="section/section[@ids]">
        <InternalSection>
            <xsl:attribute name="id">
                <xsl:value-of select="@ids"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </InternalSection>
    </xsl:template>
    <xsl:template match="reference[@internal = 'True' and @refid]" priority="10">
        <CrossRef>
            <xsl:attribute name="idref">
                <xsl:value-of select="@refid"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </CrossRef>
    </xsl:template>

    <!-- Activity templates -->
    <xsl:template match="container[@design_component = 'ou-activity']">
        <Activity><xsl:apply-templates/></Activity>
    </xsl:template>
    <xsl:template match="container[@design_component = 'ou-activity-title']">
        <Heading><xsl:apply-templates/></Heading>
    </xsl:template>
    <xsl:template match="container[@design_component = 'ou-time']">
        <Timing><xsl:apply-templates/></Timing>
    </xsl:template>
    <xsl:template match="container[@design_component = 'ou-activity-answer']">
        <Answer><xsl:apply-templates/></Answer>
    </xsl:template>

    <!-- Jupyter notebook code cell templates -->
    <xsl:template match="container[@nb_element = 'cell_code']">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="container[@nb_element = 'cell_code_source']">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="container[@nb_element = 'cell_code_output']">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- sphinx-contrig.ou-xml-tags -->
    <xsl:template match="ou_audio | ou_video">
        <MediaContent>
            <xsl:choose>
                <xsl:when test="name() = 'ou_audio'">
                    <xsl:attribute name="type">audio</xsl:attribute>
                </xsl:when>
                <xsl:when test="name() = 'ou_video'">
                    <xsl:attribute name="type">video</xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:attribute name="src">
                <xsl:value-of select="@src"/>
            </xsl:attribute>
            <xsl:if test="@height">
                <xsl:attribute name="height">
                    <xsl:value-of select="@height"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="@width">
                <xsl:attribute name="width">
                    <xsl:value-of select="@width"/>
                </xsl:attribute>
            </xsl:if>
        </MediaContent>
    </xsl:template>

    <!-- Video templates -->
    <!-- sphinx-contrib.youtube -->
    <xsl:template match="youtube">
        <MediaContent>
            <xsl:attribute name="type">oembed</xsl:attribute>
            <xsl:attribute name="src">
                <xsl:value-of select="@platform_url"/><xsl:value-of select="@id"/>
            </xsl:attribute>
        </MediaContent>
    </xsl:template>

    <!-- Where next templates -->
    <xsl:template match="container[@design_component = 'ou-where-next']">
        <Box><Heading>Now go to ...</Heading><xsl:apply-templates/></Box>
    </xsl:template>

    <!-- TOC Tree templates -->
    <xsl:template match="compound[@classes = 'toctree-wrapper']"></xsl:template>

    <!-- Mermaid templates -->
    <xsl:template match="mermaid">
        <Mermaid><xsl:value-of select="@code"/></Mermaid>
    </xsl:template>

    <!-- Quote templates -->
    <!-- Transform Quote elements (via ChatGPT) -->
    <xsl:template match="block_quote">
        <Quote>
            <xsl:apply-templates select="*[position() &lt; last()]" />
            <!-- Check if the last child is a paragraph starting with "Source:" -->
            <xsl:variable name="lastPara" select="./paragraph[last()]" />
            <xsl:choose>
                <xsl:when test="starts-with(normalize-space($lastPara), 'Source:')">
                    <SourceReference>
                        <xsl:value-of select="normalize-space(substring-after($lastPara, 'Source:'))" />
                    </SourceReference>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$lastPara" />
                </xsl:otherwise>
            </xsl:choose>
        </Quote>
    </xsl:template>

    <!-- Cross-reference templates -->
    <xsl:template match="inline[@ids]"><xsl:apply-templates/></xsl:template>
    <xsl:template match="container[@ids]"><xsl:apply-templates/></xsl:template>

    <xsl:template match="glossary">
        <!--<Glossary><xsl:apply-templates/></Glossary> -->
        <!-- SKIP FOR NOW - needs to be in backmatter -->
    </xsl:template>
    <!--
    <!-- Table templates -->
    <xsl:template match="table">
        <Table><xsl:apply-templates/></Table>
    </xsl:template>
    <xsl:template match="table/title">
        <TableHead><xsl:apply-templates/></TableHead>
    </xsl:template>
    <xsl:template match="tgroup"><xsl:apply-templates/></xsl:template>
    <xsl:template match="colspec"><xsl:apply-templates/></xsl:template>
    <xsl:template match="tbody">
        <tbody><xsl:apply-templates/></tbody>
    </xsl:template>
    <xsl:template match="thead">
        <thead><xsl:apply-templates/></thead>
    </xsl:template>
    <xsl:template match="row">
        <tr><xsl:apply-templates/></tr>
    </xsl:template>
    <xsl:template match="entry">
        <td><xsl:apply-templates/></td>
    </xsl:template>

    <!-- Math templates -->
    <xsl:template match="math">
        <InlineEquation><TeX><xsl:apply-templates/></TeX></InlineEquation>
    </xsl:template>
    <xsl:template match="math_block">
        <Equation>
            <xsl:attribute name="id">
                <xsl:value-of select="@label"/>
            </xsl:attribute>
            <TeX><xsl:value-of select="text()"/></TeX>
        </Equation>
    </xsl:template>
    <!-- Remove unwanted target tag as generated in Sphinx XML -->
    <xsl:template match="target"></xsl:template>

    <xsl:template match="*">
        <UnknownTag><xsl:value-of select="name(.)"/></UnknownTag>
    </xsl:template>
</xsl:stylesheet>"""
    )
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


def create_frontmatter(root: etree.Element, config: dict) -> None:
    """Create the frontmatter XML structure."""
    frontmatter = etree.XML(
        f"""\
<FrontMatter>
  <ByLine>{config["author"]}</ByLine>
  <Imprint>
    <Standard>
      <GeneralInfo>
        <Paragraph>This publication forms part of the Open University module {config["ou"]["module_code"]} {config["ou"]["module_title"]}. [The complete list of texts which make up this module can be found at the back (where applicable)]. Details of this and other Open University modules can be obtained from the Student Registration and Enquiry Service, The Open University, PO Box 197, Milton Keynes MK7 6BJ, United Kingdom (tel. +44 (0)845 300 60 90; email general-enquiries@open.ac.uk).</Paragraph>
        <Paragraph>Alternatively, you may visit the Open University website at www.open.ac.uk where you can learn more about the wide range of modules and packs offered at all levels by The Open University.</Paragraph>
        <Paragraph>To purchase a selection of Open University materials visit www.ouw.co.uk, or contact Open University Worldwide, Walton Hall, Milton Keynes MK7 6AA, United Kingdom for a brochure (tel. +44 (0)1908 858793; fax +44 (0)1908 858787; email ouw-customer-services@open.ac.uk).</Paragraph>
      </GeneralInfo>
      <Address>
        <AddressLine>The Open University,</AddressLine>
        <AddressLine>Walton Hall, Milton Keynes</AddressLine>
        <AddressLine>MK7 6AA</AddressLine>
      </Address>
      <FirstPublished>
        <Paragraph>First published {config["ou"]["first_published"]}</Paragraph>
      </FirstPublished>
      <Copyright>
        <Paragraph>Unless otherwise stated, copyright © {datetime.now(tz=UTC).year} The Open University, all rights reserved.</Paragraph>
      </Copyright>
      <Rights>
        <Paragraph>All rights reserved. No part of this publication may be reproduced, stored in a retrieval system, transmitted or utilised in any form or by any means, electronic, mechanical, photocopying, recording or otherwise, without written permission from the publisher or a licence from the Copyright Licensing Agency Ltd. Details of such licences (for reprographic reproduction) may be obtained from the Copyright Licensing Agency Ltd, Saffron House, 6-10 Kirby Street, London EC1N 8TS (website www.cla.co.uk).</Paragraph>
        <Paragraph>Open University materials may also be made available in electronic formats for use by students of the University. All rights, including copyright and related rights and database rights, in electronic materials and their contents are owned by or licensed to The Open University, or otherwise used by The Open University as permitted by applicable law.</Paragraph>
        <Paragraph>In using electronic materials and their contents you agree that your use will be solely for the purposes of following an Open University course of study or otherwise as licensed by The Open University or its assigns.</Paragraph>
        <Paragraph>Except as permitted above you undertake not to copy, store in any medium (including electronic storage or use in a website), distribute, transmit or retransmit, broadcast, modify or show in public such electronic materials in whole or in part without the prior written consent of The Open University or in accordance with the Copyright, Designs and Patents Act 1988.</Paragraph>
      </Rights>
      <Edited>
        <Paragraph>Edited and designed by The Open University.</Paragraph>
      </Edited>
      <Typeset>
        <Paragraph>Typeset by The Open University</Paragraph>
      </Typeset>
      <Printed>
        <Paragraph>Printed and bound in the United Kingdom by [name and address of the printer].</Paragraph>
        <Paragraph />
      </Printed>
      <ISBN>{config["ou"]["isbn"]}</ISBN>
      <Edition>{config["ou"]["edition"]}</Edition>
    </Standard>
  </Imprint>
</FrontMatter>
"""  # noqa: E501
    )
    root.append(frontmatter)


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
        image_path_prefix = config["ou"]["image_path_prefix"] if "image_path_prefix" in config["ou"] else ""
        audio_path_prefix = config["ou"]["audio_path_prefix"] if "audio_path_prefix" in config["ou"] else ""
        use_caption_as_title = False if "caption_as_title" not in config["ou"] else config["ou"]["caption_as_title"]

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
                    {"session": 0, "section": 0, "figure": 0, "table": 0},
                    part_title,
                    image_path_prefix,
                    audio_path_prefix,
                    toc,
                    item_title,
                    use_caption_as_title,
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
                {"session": 0, "section": 0, "figure": 0, "table": 0},
                part_title,
                image_path_prefix,
                audio_path_prefix,
                toc,
                item_title,
                use_caption_as_title,
            )
            with open(path.join(output_base, f"{module_code.lower()}_{block.lower()}.xml"), "wb") as out_f:
                out_f.write(etree.tostring(root, pretty_print=True, encoding="utf-8", xml_declaration=True))
            progress.update(main_task, advance=1)

def main():
    """Run the OBT application."""
    app()
