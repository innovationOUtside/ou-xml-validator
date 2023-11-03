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
        <Paragraph><xsl:apply-templates /></Paragraph>
    </xsl:template>
    <xsl:template match="paragraph[image]">
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="paragraph/image">
        <Figure>
            <Image>
                <xsl:attribute name="src">
                    <xsl:value-of select="@uri"/>
                </xsl:attribute>
            </Image>
        </Figure>
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
        <!-- We don't want to re-escape any escaped elements in Pyhton code at least... -->
        <xsl:choose>
            <xsl:when test="@language = 'python' or @language = 'xml'">
                <ProgramListing>
                    <xsl:attribute name="typ">raw</xsl:attribute>
                    <xsl:value-of select="text()" disable-output-escaping="yes"/>
                </ProgramListing>
            </xsl:when>
            <xsl:otherwise>
                <ProgramListing>
                    <xsl:attribute name="typ">esc</xsl:attribute>
                    <xsl:value-of select="text()"/>
                </ProgramListing>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="literal">
        <ComputerCode><xsl:value-of select="text()"/></ComputerCode>
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

    <xsl:template match="raw[@format = 'html']">
        <MediaContent type="html5" src="">
            <xsl:apply-templates/>
        </MediaContent>
    </xsl:template>

    <!-- sphinx-contrig.ou-xml-tags -->
    <xsl:template match="ou_audio | ou_video | ou_html5 | ou_mol3d ">
        <MediaContent>
            <xsl:choose>
                <xsl:when test="name() = 'ou_audio'">
                    <xsl:attribute name="type">audio</xsl:attribute>
                </xsl:when>
                <xsl:when test="name() = 'ou_video'">
                    <xsl:attribute name="type">video</xsl:attribute>
                </xsl:when>
                <xsl:when test="name() = 'ou_html5'">
                    <xsl:attribute name="type">html5</xsl:attribute>
                </xsl:when>
                <!-- The mol3d extension generates an HTML package. -->
                <xsl:when test="name() = 'ou_mol3d'">
                    <xsl:attribute name="type">html5</xsl:attribute>
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
            <xsl:apply-templates/>
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

    <!-- Glossary templates -->
    <xsl:template match="glossary">
        <!-- <Glossary><xsl:apply-templates/></Glossary> -->
        <!-- SKIP FOR NOW - needs to be in backmatter -->
    </xsl:template>
    <!--
    <xsl:template match="definition_list/definition_list_item/term">
        <term><xsl:apply-templates/></term>
    </xsl:template>
    <xsl:template match="definition_list/definition_list_item/definition">
        <definition><xsl:apply-templates/></definition>
    </xsl:template>
    -->
    
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
</xsl:stylesheet>