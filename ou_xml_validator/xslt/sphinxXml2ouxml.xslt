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
        <ProgramListing>
        <xsl:choose>
            <xsl:when test="@language = 'python' or @language='ipython3' or @language = 'xml' or @language = 'text'">
                    <xsl:attribute name="typ">raw</xsl:attribute>
                    <xsl:value-of select="text()" disable-output-escaping="yes"/>
                    <!-- A comment can't have a double dash in it... -->
                    <xsl:comment><xsl:value-of select="translate(., '-', '*')" disable-output-escaping="yes"/></xsl:comment>
                    <language><xsl:value-of select="@language"/></language>
            </xsl:when>
            <xsl:otherwise>
                    <xsl:attribute name="typ">esc</xsl:attribute>
                    <xsl:value-of select="text()"/>
                    <!-- A comment can't have a double dash in it... -->
                    <xsl:comment><xsl:value-of select="translate(., '-', '*')"/></xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
        </ProgramListing>
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

    <xsl:template match="bullet_list[ancestor::bullet_list or ancestor::enumerated_list]">
        <BulletedSubsidiaryList><xsl:apply-templates/></BulletedSubsidiaryList>
    </xsl:template>

    <xsl:template match="enumerated_list[ancestor::bullet_list or ancestor::enumerated_list]">
        <NumberedSubsidiaryList><xsl:apply-templates/></NumberedSubsidiaryList>
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

    <!-- For activity from ou-book-theme -->
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
    <xsl:template match="container[@design_component = 'Wrong']">
        <Wrong><Paragraph><xsl:value-of select="text()"/></Paragraph>
            <xsl:apply-templates select="child::*"/>
        </Wrong>
    </xsl:template>
    <xsl:template match="container[@design_component = 'Right']">
        <Right><Paragraph><xsl:value-of select="text()"/></Paragraph>
            <xsl:apply-templates select="child::*"/>
        </Right>
    </xsl:template>
    <xsl:template match="container[@design_component = 'Feedback']">
        <Feedback><Paragraph><xsl:apply-templates/></Paragraph></Feedback>
    </xsl:template>
    <xsl:template match="container[@design_component = 'ou-interaction']">
        <Interaction>
            <xsl:choose>
                <xsl:when test="@type = 'freeresponse'">
                    <FreeResponse>
                        <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
                        <xsl:attribute name="size"><xsl:value-of select="@size"/></xsl:attribute>
                    </FreeResponse>
                </xsl:when>
                <xsl:when test="@type = 'multiple'">
                    <MultipleChoice>
                        <xsl:apply-templates/>
                    </MultipleChoice>
                </xsl:when>
                <xsl:when test="@type = 'single'">
                    <SingleChoice>
                        <xsl:apply-templates/>
                    </SingleChoice>
                </xsl:when>
            </xsl:choose>
        </Interaction>
    </xsl:template>
    <xsl:template match="container[@design_component = 'ou-exercise']">
        <Exercise><xsl:apply-templates/>

        </Exercise>
    </xsl:template>
    <xsl:template match="container[@design_component = 'ou-title']">
        <Heading><xsl:apply-templates/></Heading>
    </xsl:template>
    <xsl:template match="container[@design_component = 'ou-answer']">
        <Answer><xsl:apply-templates/></Answer>
    </xsl:template>
    <xsl:template match="container[@design_component = 'ou-discussion']">
        <Discussion><xsl:apply-templates/></Discussion>
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

    <!-- sphinx-contrib.ou-xml-tags -->
    <xsl:template match="ou_audio | ou_video | ou_html5 | ou_mol3d | ou_codestyle ">
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
                <!-- The codestyle extension generates an HTML file. -->
                <xsl:when test="name() = 'ou_codestyle'">
                    <xsl:attribute name="type">html5</xsl:attribute>
                </xsl:when>
            </xsl:choose>
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
            <xsl:if test="@keep">
                <xsl:attribute name="keep">
                    <xsl:value-of select="@keep"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@codesnippet='True'">
                    <!-- Default: https://openuniv.sharepoint.com/sites/modules%E2%80%93shared/imd/widgets/CL/codesnippet/cl_codesnippet_v1.0.zip -->
                    <!-- Ideally, this would come from a setting... -->
                    <xsl:attribute name="src">https://openuniv.sharepoint.com/sites/modules%E2%80%93shared/imd/widgets/CL/codesnippet/cl_codesnippet_v1.0.zip</xsl:attribute>
                    <!-- Generate invalid OU-XML handled in post-preocessing -->
                    <xsl:attribute name="codesnippet">True</xsl:attribute>
                    <xsl:attribute name="codesrc"><xsl:value-of select="@src"/></xsl:attribute>
                    <Parameters>
                        <xsl:if test="@codetype">
                            <Parameter>
                                <xsl:attribute name="name">codetype</xsl:attribute>
                                <xsl:attribute name="value"><xsl:value-of select="@codetype"/></xsl:attribute>
                            </Parameter>
                        </xsl:if>
                        <Parameter>
                            <xsl:attribute name="name">theme</xsl:attribute>
                            <xsl:attribute name="value">
                                <xsl:choose>
                                    <xsl:when test="@theme">      
                                        <xsl:value-of select="@theme"/>
                                    </xsl:when>
                                    <xsl:otherwise>light</xsl:otherwise>
                                    </xsl:choose>
                            </xsl:attribute>
                        </Parameter>
                    </Parameters>
                    <Attachments>
					    <Attachment>
                            <xsl:attribute name="name">codesnippet</xsl:attribute>
                            <xsl:attribute name="src"><xsl:value-of select="@src"/></xsl:attribute>
                        </Attachment>
				    </Attachments>
                </xsl:when>
                <xsl:when test="@interactivetype='Xshinylite-py'">
                    <!-- We need to call the appropriate HTML widget... -->
                    
                    <xsl:attribute name="src">https://github.com/innovationOUtside/sphinxcontrib-ou-xml-tags/raw/main/dist/shinylite-py-01.zip</xsl:attribute>
                    <xsl:attribute name="interactivetype"><xsl:value-of select="@interactivetype"/></xsl:attribute>
                    <xsl:attribute name="codesrc"><xsl:value-of select="@src"/></xsl:attribute>
                    <Attachments>
					    <Attachment>
                            <xsl:attribute name="name">codesnippet</xsl:attribute>
                            <xsl:attribute name="src"><xsl:value-of select="@src"/></xsl:attribute>
                        </Attachment>
				    </Attachments>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="src">
                        <xsl:value-of select="@src"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose> <!-- END: test="@codesnippet='True'"-->
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
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="definition_list">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="definition_list_item">
        <GlossaryItem><xsl:apply-templates/></GlossaryItem>
    </xsl:template>
    <xsl:template match="term">
        <Term><xsl:apply-templates/></Term>
    </xsl:template>
     <xsl:template match="definition">
        <Definition><xsl:apply-templates/></Definition>
    </xsl:template>
    
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