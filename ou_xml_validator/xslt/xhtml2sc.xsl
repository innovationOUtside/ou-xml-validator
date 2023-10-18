<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"                
	xmlns:xhtml="http://www.w3.org/1999/xhtml" 
	xmlns:m="http://www.w3.org/1998/Math/MathML"
    exclude-result-prefixes="xsl xhtml m">
    
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>
	
	<xsl:strip-space elements="Item"/>
	
	<xsl:variable name="Testing" select="false()" />
	
	<xsl:variable name="ShowInput" select="false()" />
	
	<xsl:variable name="ShowOutput" select="false()" />
	
	<xsl:variable name="UpperAndSpace" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />
	<xsl:variable name="Lower" select="'abcdefghijklmnopqrstuvwxyz'" />
	
	<xsl:variable name="DocumentLanguage">
		<xsl:apply-templates select="/xhtml:html/xhtml:body" mode="GetLanguage" />
	</xsl:variable>
	
	<xsl:variable name="NormalStyle" select="substring-before (substring-after (substring-after (/xhtml:html/xhtml:head/xhtml:style[count(@id)=0], 'p.MsoNormal'), '{'), '}')"/>  <!-- Need to discount anything with an @id, used when there are comments -->
	
	<xsl:variable name="NormalFont" select="normalize-space(translate(substring-before(substring-after($NormalStyle , ' font-family :') , ';') , '&quot;', ''))" />
	
	<xsl:variable name="InLineTags" select="';span;b;i;a;u;strong;sup;sub;br;'"></xsl:variable>
	
	<xsl:variable name="EndMath">
		<xsl:text disable-output-escaping="yes">&lt;/math&gt;</xsl:text>
	</xsl:variable>

	<xsl:template match="/">
		<xsl:if test="$ShowInput"><xsl:call-template name="ShowInput"/></xsl:if>
		<xsl:choose>
			<xsl:when test="xhtml:html/xhtml:body/*[1]/@class='Transcript'">
				<xsl:apply-templates mode="Transcript" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:html">
		<xsl:apply-templates select="xhtml:body" />
	</xsl:template>
	
	<xsl:template match="xhtml:body">
		<xsl:variable name="NumberOfHeads"><xsl:call-template name="CountHeads" /></xsl:variable>
		<!-- xsl:message>
			<xsl:text>Number of heads='</xsl:text>
			<xsl:value-of select="$NumberOfHeads" />
			<xsl:text>'</xsl:text>
		</xsl:message -->
		<xsl:choose>
			<xsl:when test="count(xhtml:h1) + count(xhtml:h2) + count(xhtml:h3) + count(xhtml:h4) + $NumberOfHeads = 0">
				<xsl:apply-templates select="xhtml:*" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$ShowOutput=true()">
						<!-- If showing output, display as a message and not -->
						<!-- inside the content. Note that any less than or -->
						<!-- greater than characters will be displayed as -->
						<!-- entities in the message area. -->
						<xsl:message>
							<xsl:for-each select="*[1]">
								<xsl:call-template name="ProcessTag">
									<xsl:with-param name="Top" select="0" />
									<xsl:with-param name="Current" select="0" />
								</xsl:call-template>
							</xsl:for-each>
						</xsl:message>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="*[1]">
							<xsl:call-template name="ProcessTag">
								<xsl:with-param name="Top" select="0" />
								<xsl:with-param name="Current" select="0" />
							</xsl:call-template>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="ProcessTag">
		<!-- This templates processes the current tag and then recurses -->
		<!-- to process the next one, if there is one. -->
		<xsl:param name="Top" select="0" /> <!-- The highest level reached so far. -->
		<xsl:param name="Current" select="0" />
		
		<xsl:variable name="NextLevel">
			<xsl:call-template name="GetLevel">
				<xsl:with-param name="Current" select="$Current" />
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="HasOutlineLevel">
			<xsl:call-template name="HasOutlineLevel" />
		</xsl:variable>
		<!-- xsl:message>
			<xsl:text>[ProcessTag]HasOutlineLevel='</xsl:text>
			<xsl:value-of select="$HasOutlineLevel"/>
			<xsl:text>'</xsl:text>
		</xsl:message -->
		
		<xsl:if test="(local-name()='h1') or (local-name() = 'h2') or (local-name() = 'h3') or (local-name() = 'h4') or ($HasOutlineLevel = 'true')">
			<!-- A heading forces a new block -->
			<xsl:call-template name="ProcessLevel">
				<xsl:with-param name="Current" select="$Current" />
				<xsl:with-param name="Next" select="$NextLevel" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:apply-templates select="." />
		<xsl:choose>
			<xsl:when test="count(following-sibling::xhtml:*[1]) != 0">
				<!-- There is a next sibling -->
				<xsl:for-each select="following-sibling::xhtml:*[1]">
					<xsl:call-template name="ProcessTag">
						<xsl:with-param name="Top">
							<xsl:choose>
								<xsl:when test="$Top = 0"><xsl:value-of select="$NextLevel"/></xsl:when>
								<xsl:when test="$Top &lt;= $NextLevel"><xsl:value-of select="$Top"/></xsl:when>
								<xsl:otherwise><xsl:value-of select="$NextLevel"/></xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
						<xsl:with-param name="Current" select="$NextLevel" />
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<!-- End of the document, so close any open blocks -->
				<xsl:call-template name="CloseLevel">
					<xsl:with-param name="Next">
						<xsl:choose>
							<xsl:when test="$Top = 0"><xsl:value-of select="$NextLevel"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="$Top"/></xsl:otherwise>
						</xsl:choose>
					</xsl:with-param>
					<xsl:with-param name="Current" select="$NextLevel" />
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="GetLevel">
		<xsl:param name="Current" select="0" />
		
		<xsl:choose>
			<xsl:when test="(local-name()!='h1') and (local-name() != 'h2') and (local-name() != 'h3') and (local-name() != 'h4')">
				<xsl:variable name="OutlineLevel">
					<xsl:call-template name="GetOutlineLevel" />
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$OutlineLevel &gt; 0"><xsl:value-of select="$OutlineLevel"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$Current" /></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring(local-name(),2,1)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="ProcessLevel">
		<xsl:param name="Current" select="0" />
		<xsl:param name="Next" select="0" />
		
		<xsl:call-template name="CloseLevel">
			<xsl:with-param name="Current" select="$Current" />
			<xsl:with-param name="Next" select="$Next" />
		</xsl:call-template>
		
		<xsl:call-template name="OpenLevel">
			<xsl:with-param name="Current" select="$Current" />
			<xsl:with-param name="Next" select="$Next" />
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="OpenLevel">
		<xsl:param name="Current" select="0" />
		<xsl:param name="Next" select="0" />
		<xsl:param name="Count" select="0" />

		<xsl:choose>
			<xsl:when test="$Count &gt; 5" /> <!-- Make sure no infinite loop! -->
			
			<xsl:when test="($Current = 0) or (($Count = 0) and ($Current &gt;= $Next))">
				<!-- Always open a new block if current and next levels are -->
				<!-- the same the first time through here -->
				<xsl:variable name="LevelName">
					<xsl:call-template name="GetLevelName">
						<xsl:with-param name="Level" select="$Next" />
					</xsl:call-template>
				</xsl:variable>
				<xsl:text disable-output-escaping="yes">&lt;</xsl:text><xsl:value-of select="$LevelName" /><xsl:text disable-output-escaping="yes">&gt;</xsl:text>
			</xsl:when>
			
			<xsl:when test="$Next != $Current">
				<xsl:variable name="LevelName">
					<xsl:call-template name="GetLevelName">
						<xsl:with-param name="Level" select="$Current + 1" />
					</xsl:call-template>
				</xsl:variable>
				<xsl:text disable-output-escaping="yes">&lt;</xsl:text><xsl:value-of select="$LevelName" /><xsl:text disable-output-escaping="yes">&gt;</xsl:text>
				<xsl:variable name="ThisLevel">
					<xsl:call-template name="GetOutlineLevel" />
				</xsl:variable>
				<!--xsl:if test="local-name() != concat('h',string($Current+1))">
					<Title />
				</xsl:if -->
				<xsl:if test="$ThisLevel != $Current+1">
					<Title />
				</xsl:if>
				<xsl:call-template name="OpenLevel">
					<xsl:with-param name="Current" select="$Current + 1" />
					<xsl:with-param name="Next" select="$Next" />
					<xsl:with-param name="Count" select="$Count + 1" />
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="CloseLevel">
		<xsl:param name="Current" select="0" />
		<xsl:param name="Next" select="0" />

		<xsl:if test="($Current != 0) and ($Current &gt;= $Next)">
			<xsl:variable name="CurrentName">
				<xsl:call-template name="GetLevelName">
					<xsl:with-param name="Level" select="$Current" />
				</xsl:call-template>
			</xsl:variable>
			<xsl:text disable-output-escaping="yes">&lt;/</xsl:text><xsl:value-of select="$CurrentName" /><xsl:text disable-output-escaping="yes">&gt;</xsl:text>
			<xsl:call-template name="CloseLevel">
				<xsl:with-param name="Current" select="$Current - 1" />
				<xsl:with-param name="Next" select="$Next" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="GetLevelName">
		<xsl:param name="Level" select="0" />
		<xsl:choose>
			<xsl:when test="$Level=1">Session</xsl:when>
			<xsl:when test="$Level=2">Section</xsl:when>
			<xsl:when test="$Level=3">SubSection</xsl:when>
			<xsl:otherwise>SubSubSection</xsl:otherwise>
			<!-- Any levels at 5 or below will become level 4 -->
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:p[contains(@class,'Head')]">
		<xsl:choose>
			<xsl:when test="contains(@class,'ActivityHead')">
				<Activity>
					<Heading><xsl:apply-templates /></Heading>
					<xsl:if test="contains(following-sibling::*[1]/@class, 'ActivityTiming')">
						<Timing>
							<xsl:apply-templates select="following-sibling::*[1]/node()"/>
						</Timing>
					</xsl:if>
					<Question />
				</Activity>
			</xsl:when>
			<xsl:when test="contains(@class,'ExerciseHead')">
				<Exercise>
					<Heading><xsl:apply-templates /></Heading>
					<xsl:if test="contains(following-sibling::*[1]/@class, 'ExerciseTiming')">
						<Timing>
							<xsl:apply-templates select="following-sibling::*[1]/node()"/>
						</Timing>
					</xsl:if>
					<Question />
				</Exercise>
			</xsl:when>
			<xsl:when test="contains(@class,'ITQHead')">
				<ITQ>
					<Heading><xsl:apply-templates /></Heading>
					<xsl:if test="contains(following-sibling::*[1]/@class, 'ITQTiming')">
						<Timing>
							<xsl:apply-templates select="following-sibling::*[1]/node()"/>
						</Timing>
					</xsl:if>
					<Question />
				</ITQ>
			</xsl:when>
			<xsl:when test="contains(@class,'SAQHead')">
				<SAQ>
					<Heading><xsl:apply-templates /></Heading>
					<xsl:if test="contains(following-sibling::*[1]/@class, 'SAQTiming')">
						<Timing>
							<xsl:apply-templates select="following-sibling::*[1]/node()"/>
						</Timing>
					</xsl:if>
					<Question />
				</SAQ>
			</xsl:when>
			<xsl:when test="contains(@class,'BoxHead')">
				<Box>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</Box>
			</xsl:when>
			<xsl:when test="contains(@class,'CaseStudyHead')">
				<CaseStudy>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</CaseStudy>
			</xsl:when>
			<xsl:when test="contains(@class,'DialogueHead')">
				<Dialogue>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</Dialogue>
			</xsl:when>
			<xsl:when test="contains(@class,'ExampleHead')">
				<Example>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</Example>
			</xsl:when>
			<xsl:when test="contains(@class,'ExtractHead')">
				<Extract>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</Extract>
			</xsl:when>
			<xsl:when test="contains(@class,'QuoteHead')">
				<Quote>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</Quote>
			</xsl:when>
			<xsl:when test="contains(@class,'ReadingHead')">
				<Reading>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</Reading>
			</xsl:when>
			<xsl:when test="contains(@class,'StudyNoteHead')">
				<StudyNote>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</StudyNote>
			</xsl:when>
			<xsl:when test="contains(@class,'VerseHead')">
				<Verse>
					<Heading><xsl:apply-templates /></Heading>
					<Paragraph />
				</Verse>
			</xsl:when>
			<xsl:when test="contains(@class,'TableHead')">
				<!-- TableHead style handled within processing for table, if there is a following table -->
				<xsl:if test="local-name(following-sibling::*[1]) != 'table'">
					<xsl:call-template name="DoParagraphWithMaths" />
					<!-- Paragraph>
						<xsl:apply-templates />
					</Paragraph -->
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="HasOutlineLevel"><xsl:call-template name="HasOutlineLevel" /></xsl:variable>
				<xsl:choose>
					<xsl:when test="$HasOutlineLevel = 'true'">
						<xsl:variable name="OutlineLevel">
							<xsl:call-template name="GetOutlineLevel" />
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="($OutlineLevel &gt; 0) and ($OutlineLevel &lt; 4)">
								<Title><xsl:apply-templates /></Title>
							</xsl:when>
							<xsl:when test="$OutlineLevel = 4">
								<Heading><xsl:apply-templates /></Heading>
							</xsl:when>
							<xsl:otherwise>
								<Paragraph>
									<xsl:apply-templates />
								</Paragraph>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="DoParagraphWithMaths" />
						<!-- Paragraph>
							<xsl:apply-templates />
						</Paragraph -->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:p" mode="InProgramListing">
		<br />
		<xsl:apply-templates />
		<xsl:for-each select="following-sibling::xhtml:*[string-length() &gt; 0][1][contains(@class, 'Program') and not (contains(@class, 'ProgramBlock'))]">
			<xsl:apply-templates select="." mode="InProgramListing"/>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="*" mode="InProgramListing">
		<xsl:apply-templates select="." />
	</xsl:template>
	
	<xsl:template match="xhtml:p" mode="InProgramBlockListing">
		<br />
		<xsl:apply-templates />
		<xsl:for-each select="following-sibling::xhtml:*[string-length() &gt; 0][1][contains(@class, 'ProgramBlock')]">
			<xsl:apply-templates select="." mode="InProgramBlockListing"/>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="*" mode="InProgramBlockListing">
		<xsl:apply-templates select="." />
	</xsl:template>
	
	<xsl:template match="xhtml:p">
		<xsl:if test="$Testing='true'">
			<Paragraph>[pbc p start]</Paragraph>
		</xsl:if>
		<xsl:if test="(string-length(normalize-space()) &gt; 0) and (((@class != 'MsoCommentText') or (count(ancestor::xhtml:div[@style = 'mso-element:comment-list'])=0)) or count(@class)=0)">
			<xsl:choose>
				<xsl:when test="contains(@class,'Head')" /> <!-- Handled in own template -->
				<xsl:when test="contains(@class,'TableFootnote')">
					<xsl:variable name="InTable">
						<xsl:choose>
							<xsl:when test="count(preceding-sibling::*[1]) = 0">
								<xsl:value-of select="false()"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:for-each select="preceding-sibling::*[1]">
									<xsl:call-template name="IsInTable" />
								</xsl:for-each>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="$InTable='false'">
						<Paragraph>
							<xsl:apply-templates />
						</Paragraph>
					</xsl:if>
				</xsl:when>
				<xsl:when test="contains(@class,'SourceReference')">
					<xsl:variable name="InTable">
						<xsl:choose>
							<xsl:when test="count(preceding-sibling::*[1]) = 0">
								<xsl:value-of select="false()"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:for-each select="preceding-sibling::*[1]">
									<xsl:call-template name="IsInTable" />
								</xsl:for-each>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="$InTable='false'">
						<Paragraph>
							<xsl:apply-templates />
						</Paragraph>
					</xsl:if>
				</xsl:when>
				<xsl:when test="contains(@class,'Timing')">
					<xsl:choose>
						<xsl:when test="contains(@class,'ActivityTiming')">
							<xsl:if test="not(contains(preceding-sibling::*[1]/@class,'ActivityHead'))">
							<Paragraph>
								<xsl:apply-templates />
							</Paragraph>
							</xsl:if>
						</xsl:when>
						<xsl:when test="contains(@class,'ExerciseTiming')">
							<xsl:if test="not(contains(preceding-sibling::*[1]/@class,'ExerciseHead'))">
							<Paragraph>
								<xsl:apply-templates />
							</Paragraph>
							</xsl:if>
						</xsl:when>
						<xsl:when test="contains(@class,'ITQTiming')">
							<xsl:if test="not(contains(preceding-sibling::*[1]/@class,'ITQHead'))">
							<Paragraph>
								<xsl:apply-templates />
							</Paragraph>
							</xsl:if>
						</xsl:when>
						<xsl:when test="contains(@class,'SAQTiming')">
							<xsl:if test="not(contains(preceding-sibling::*[1]/@class,'SAQHead'))">
							<Paragraph>
								<xsl:apply-templates />
							</Paragraph>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<Paragraph>
								<xsl:apply-templates />
							</Paragraph>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="contains(@class, 'FigureCaption') and preceding-sibling::xhtml:*[string-length() != 0][(name()='p') and (position()=1) and contains(@class, 'FigureCaption') and (count(xhtml:span[@class='MTConvertedEquation']) != 0) and (normalize-space(.) != $EndMath)]" />
				<xsl:when test="contains(@class,'FigureCaption')">
					<Figure>
						<Image />
						<Caption>
							<xsl:choose>
								<xsl:when test="count(xhtml:span[@class='MTConvertedEquation'])">
									<xsl:call-template name="DoParagraphWithMaths">
										<xsl:with-param name="DoIt" select="true()" />
									</xsl:call-template>
								</xsl:when>
								<xsl:otherwise>
									<xsl:apply-templates />
								</xsl:otherwise>
							</xsl:choose>
						</Caption>
					</Figure>
				</xsl:when>
				<xsl:when test="contains(@class, 'ITQ')">
					<xsl:call-template name="DoITQ" />
				</xsl:when>
				<xsl:when test="contains(@class, 'ProgramBlock')">
					<xsl:if test="not(contains(preceding-sibling::xhtml:*[string-length() &gt; 0][1]/@class, 'ProgramBlock'))">
						<ProgramListing>
							<Paragraph>
								<xsl:apply-templates />
								<xsl:for-each select="following-sibling::xhtml:*[string-length() &gt; 0][1][contains(@class, 'ProgramBlock')]">
									<xsl:apply-templates select="." mode="InProgramBlockListing"/>
								</xsl:for-each>
							</Paragraph>
						</ProgramListing>
					</xsl:if>
				</xsl:when>
				<xsl:when test="contains(@class, 'Program')">
					<xsl:if test="not(contains(preceding-sibling::xhtml:*[string-length() &gt; 0][1]/@class, 'Program')) or (contains(preceding-sibling::xhtml:*[string-length() &gt; 0][1]/@class, 'ProgramBlock'))">
						<ComputerDisplay>
							<Paragraph>
								<xsl:apply-templates />
								<xsl:for-each select="following-sibling::xhtml:*[string-length() &gt; 0][1][contains(@class, 'Program') and not(contains(@class, 'ProgramBlock'))]">
									<xsl:apply-templates select="." mode="InProgramListing"/>
								</xsl:for-each>
							</Paragraph>
						</ComputerDisplay>
					</xsl:if>
				</xsl:when>
				<xsl:when test="contains(@class, 'Equation') and preceding-sibling::xhtml:*[string-length() != 0][(name()='p') and (position()=1) and contains(@class, 'Equation') and (count(xhtml:span[@class='MTConvertedEquation']) != 0)]" />
				<xsl:when test="contains(@class, 'Equation')">
					<xsl:call-template name="DoMaths" />
				</xsl:when>
				<xsl:when test="contains(translate(@style, ' ', ''), 'mso-outline-level:')">
					<xsl:variable name="OutlineLevel" select="substring(substring-after(translate(@style, ' ', ''), 'mso-outline-level:'), 1, 1)" />
					<xsl:choose>
						<xsl:when test="($OutlineLevel &gt; 0) and ($OutlineLevel &lt; 4)">
							<Title><xsl:apply-templates /></Title>
						</xsl:when>
						<xsl:when test="$OutlineLevel = 4">
							<Heading><xsl:apply-templates /></Heading>
						</xsl:when>
						<xsl:otherwise>
							<Paragraph>
								<xsl:apply-templates />
							</Paragraph>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="HasOutlineLevel"><xsl:call-template name="HasOutlineLevel" /></xsl:variable>
					<xsl:choose>
						<xsl:when test="$HasOutlineLevel = 'true'">
							<xsl:variable name="OutlineLevel">
								<xsl:call-template name="GetOutlineLevel" />
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="($OutlineLevel &gt; 0) and ($OutlineLevel &lt; 4)">
									<Title><xsl:apply-templates /></Title>
								</xsl:when>
								<xsl:when test="$OutlineLevel = 4">
									<Heading><xsl:apply-templates /></Heading>
								</xsl:when>
								<xsl:otherwise>
									<Paragraph>
										<xsl:apply-templates />
									</Paragraph>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test="$Testing='true'">
								<Paragraph>
									<xsl:text>[pbc p last otherwise 1: </xsl:text>
									<xsl:for-each select="node()">
										<xsl:text>{</xsl:text>
										<xsl:value-of select="position()"/>
										<xsl:text>: name='</xsl:text>
										<xsl:value-of select="name()"/>
										<xsl:text>', content='</xsl:text>
										<xsl:value-of select="."/>
										<xsl:text>', normalized='</xsl:text>
										<xsl:value-of select="normalize-space()"/>
										<xsl:text>'}</xsl:text>
									</xsl:for-each>
									<xsl:text>]</xsl:text>
								</Paragraph>
							</xsl:if>
							<!-- Paragraph>
								<xsl:for-each select="node()">
									<xsl:choose>
										<xsl:when test="string-length(normalize-space()) &gt; 0">
											<xsl:apply-templates select="."/>
										</xsl:when>
									</xsl:choose -->
									<!-- xsl:if test="(position() != 1) or (string-length(normalize-space()) &gt; 0)">
										<xsl:apply-templates select="."/>
									</xsl:if -->
								<!-- /xsl:for-each>
								</Paragraph -->
							<xsl:call-template name="DoParagraphWithMaths" />
							<!--xsl:if test="(count(xhtml:span[@class='MTConvertedEquation'])=0) or (count(preceding-sibling::xhtml:p[1]) = 0) or (count(preceding-sibling::xhtml:p[string-length()!=0][1]/xhtml:span[@class='MTConvertedEquation']) = 0)">
								<Paragraph>
									<xsl:apply-templates />
									<xsl:if test="count(xhtml:span[@class='MTConvertedEquation']) != 0">
										<xsl:call-template name="DoMaths" />
									</xsl:if>
								</Paragraph>
							</xsl:if -->
							<xsl:if test="$Testing='true'">
								<Paragraph>
									<xsl:text>[pbc p last otherwise 2]</xsl:text>
								</Paragraph>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$Testing='true'">
			<Paragraph>[pbc p 2]</Paragraph>
		</xsl:if>
	</xsl:template>
	
	<!-- Maths templates -->
	
	<xsl:template name="DoParagraphWithMaths">
		<xsl:param name="DoIt" select="false()" />
		<xsl:param name="Parent" />
		<xsl:variable name="WrapperTag">
			<xsl:variable name="TestValue">
				<xsl:text disable-output-escaping="yes">&lt;math display=&apos;block&apos;</xsl:text>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="contains(@class, 'Equation')">Equation</xsl:when>
				<xsl:when test="normalize-space()!= normalize-space(xhtml:span[@class='MTConvertedEquation'])">Paragraph</xsl:when>
				<xsl:when test="$DoIt='true'">Paragraph</xsl:when>
				<xsl:when test="contains(.,$TestValue)">Equation</xsl:when>
				<xsl:otherwise>Paragraph</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="($DoIt='true') or (string-length($Parent) != 0) or (count(xhtml:span[@class='MTConvertedEquation'])=0) or (count(preceding-sibling::xhtml:p[1]) = 0) or (count(preceding-sibling::xhtml:p[string-length()!=0][1]/xhtml:span[@class='MTConvertedEquation']) = 0)">
			<xsl:choose>
				<xsl:when test="$WrapperTag='Equation'">
					<xsl:call-template name="DoMaths" />
				</xsl:when>
				<xsl:when test="$WrapperTag='Paragraph'">
					<xsl:choose>
						<xsl:when test="$DoIt='true'">
							<xsl:apply-templates />
							<xsl:if test="count(xhtml:span[@class='MTConvertedEquation']) != 0">
								<xsl:call-template name="DoMaths" />
							</xsl:if>
						</xsl:when>
						<xsl:when test="string-length($Parent) != 0">
							<xsl:element name="{$Parent}">
								<xsl:apply-templates />
								<xsl:if test="count(xhtml:span[@class='MTConvertedEquation']) != 0">
									<xsl:call-template name="DoMaths" />
								</xsl:if>
							</xsl:element>
						</xsl:when>
						<xsl:otherwise>
							<!--xsl:message>
								<xsl:text>DoParagraphWithMaths: name='</xsl:text>
								<xsl:value-of select="name()"/>
								<xsl:text>', content='</xsl:text>
								<xsl:value-of select="."/>
								<xsl:text>', number of subnodes='</xsl:text>
								<xsl:value-of select="count(node())"/>
								<xsl:text>'</xsl:text>
								<xsl:for-each select="node()">
									<xsl:text>Node </xsl:text>
									<xsl:value-of select="position()"/>
									<xsl:text> name='</xsl:text>
									<xsl:value-of select="name()"/>
									<xsl:text>'; </xsl:text>
								</xsl:for-each>
							</xsl:message-->
							<Paragraph>
								<xsl:apply-templates />
								<xsl:if test="count(xhtml:span[@class='MTConvertedEquation']) != 0">
									<xsl:call-template name="DoMaths" />
								</xsl:if>
							</Paragraph>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<Paragraph>
						<xsl:apply-templates />
						<xsl:if test="count(xhtml:span[@class='MTConvertedEquation']) != 0">
							<xsl:call-template name="DoMaths" />
						</xsl:if>
					</Paragraph>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template name="DoMaths">
		<xsl:variable name="EquationTag">
			<xsl:variable name="TestValue">
				<xsl:text disable-output-escaping="yes">&lt;math display=&apos;block&apos;</xsl:text>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="contains(@class, 'Equation')">Equation</xsl:when>
				<xsl:when test="normalize-space()!= normalize-space(xhtml:span[@class='MTConvertedEquation'])">InlineEquation</xsl:when>
				<xsl:when test="contains(.,$TestValue)">Equation</xsl:when>
				<xsl:otherwise>InlineEquation</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- xsl:message>
			<xsl:text>DoMaths pbc 1: tag='</xsl:text>
			<xsl:value-of select="$EquationTag"/>
			<xsl:text>', content='</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>'</xsl:text>
		</xsl:message -->
		<xsl:choose>
			<xsl:when test="count(xhtml:span[@class='MTConvertedEquation']) = 0">
				<xsl:element name="{$EquationTag}">
					<Image>
						<xsl:apply-templates select="node()" />
					</Image>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$EquationTag='Equation'">
						<xsl:apply-templates select="." mode="Equation"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text disable-output-escaping="yes">&lt;InlineEquation&gt;&lt;MathML&gt;</xsl:text>
						<xsl:apply-templates select="." mode="InlineEquation"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:p" mode="InlineEquation">
		<xsl:if test="string-length(normalize-space(translate(.,' ',' ')))!=0">
			<xsl:variable name="EquationLine" select="xhtml:span[@class='MTConvertedEquation']" />
			<!-- Output current part of the equation -->
			<!--<xsl:value-of select="substring($EquationLine, string-length(substring-before($EquationLine, '&lt;'))+1)" disable-output-escaping="yes"/ -->
			<xsl:variable name="EntityReplacedLine">
				<xsl:call-template name="ReplaceMathTypeEntity">
					<xsl:with-param name="InputText" select="substring($EquationLine, string-length(substring-before($EquationLine, '&lt;'))+1)" />
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="ReplaceMathCharacter">
				<xsl:with-param name="InputText" select="$EntityReplacedLine" />
			</xsl:call-template>
		</xsl:if>
		<!-- Look for next part of the equation -->
		<xsl:if test="count(following-sibling::xhtml:*[1]) = 0">
			<xsl:text disable-output-escaping="yes">&lt;/MathML&gt;&lt;Image&gt;&lt;/Image&gt;&lt;/InlineEquation&gt;</xsl:text>
		</xsl:if>
		<xsl:for-each select="following-sibling::xhtml:*[1]">
			<xsl:choose>
				<xsl:when test="string-length()=0">
					<xsl:apply-templates select="." mode="InlineEquation" />
				</xsl:when>
				<xsl:when test="count(xhtml:span[@class='MTConvertedEquation']) = 0" >
					<xsl:text disable-output-escaping="yes">&lt;/MathML&gt;&lt;Image&gt;&lt;/Image&gt;&lt;/InlineEquation&gt;</xsl:text>
				</xsl:when>
				<xsl:when test="(local-name(*[1])!='span') or (count(*[1]/@class) = 0) or (*[1]/@class!='MTConvertedEquation') or (normalize-space()!= normalize-space(xhtml:span[@class='MTConvertedEquation']))">
					<xsl:text disable-output-escaping="yes">&lt;/MathML&gt;&lt;Image&gt;&lt;/Image&gt;&lt;/InlineEquation&gt;</xsl:text>
					<xsl:call-template name="DoParagraphWithMaths">
						<xsl:with-param name="DoIt" select="true()" />
					</xsl:call-template>
					<!-- xsl:apply-templates select="node()" / -->
					<!--xsl:call-template name="DoMaths" /-->
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="." mode="InlineEquation" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="xhtml:p" mode="Equation">
		<xsl:variable name="EquationLine" select="xhtml:span[@class='MTConvertedEquation']" />
		<xsl:variable name="StartLine">
			<xsl:text disable-output-escaping='yes'>&lt;math </xsl:text>
		</xsl:variable>
		<!-- xsl:message>
			<xsl:text>PBC 1: EquationLine='</xsl:text>
			<xsl:value-of select="$EquationLine"/>
			<xsl:text>'</xsl:text>
		</xsl:message -->
		<xsl:if test="substring($EquationLine,1,6)=$StartLine">
			<xsl:text disable-output-escaping="yes">&lt;Equation&gt;&lt;MathML&gt;</xsl:text>
		</xsl:if>
		<xsl:if test="string-length(normalize-space(translate(.,' ',' ')))!=0">
			<!-- xsl:message>PBC 2: p Equation</xsl:message -->
			<!-- Output current part of the equation -->
			<xsl:variable name="EntityReplacedLine">
				<xsl:call-template name="ReplaceMathTypeEntity">
					<xsl:with-param name="InputText" select="substring($EquationLine, string-length(substring-before($EquationLine, '&lt;'))+1)" />
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="ReplaceMathCharacter">
				<xsl:with-param name="InputText" select="$EntityReplacedLine" />
			</xsl:call-template>
		</xsl:if>
		<!-- Look for next part of the equation -->
		<xsl:choose>
			<xsl:when test="$EquationLine='&lt;/math&gt;'">
				<!-- xsl:message>PBC 3-1: End of maths</xsl:message -->
				<xsl:text disable-output-escaping="yes">&lt;/MathML&gt;</xsl:text>
				<xsl:call-template name="DoLabel" />
				<xsl:text disable-output-escaping="yes">&lt;/Equation&gt;</xsl:text>
				<xsl:call-template name="DoNextMaths" />
				<!-- Paragraph>[p Equation: should be done now!]</Paragraph -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="following-sibling::xhtml:*[1]">
					<xsl:choose>
						<xsl:when test="string-length()=0">
						<!-- xsl:message>PBC 4: p Equation</xsl:message -->
							<xsl:apply-templates select="." mode="Equation" />
						</xsl:when>
						<xsl:when test="count(xhtml:span[@class='MTConvertedEquation']) = 0">
						<!--xsl:message>PBC 5: p Equation</xsl:message -->
						</xsl:when>
						<xsl:when test="(local-name(*[1])!='span') or (count(*[1]/@class) = 0) or (*[1]/@class!='MTConvertedEquation') or (normalize-space()!= normalize-space(xhtml:span[@class='MTConvertedEquation']))">
						<!-- xsl:message>PBC 7: p Equation</xsl:message -->
							<!-- Paragraph>[p Equation (7.1)]</Paragraph -->
							<xsl:apply-templates select="node()" />
							<!-- Paragraph>[p Equation (7.2)]</Paragraph -->
						</xsl:when>
						<xsl:otherwise>
						<!-- xsl:message>PBC 8: p Equation</xsl:message -->
							<xsl:apply-templates select="." mode="Equation" />
						</xsl:otherwise>
					</xsl:choose>
				<!-- xsl:message>PBC 9: p Equation</xsl:message -->
				</xsl:for-each>				
			</xsl:otherwise>
		</xsl:choose>
				<!-- xsl:message>PBC 10: p Equation</xsl:message -->
	</xsl:template>
	
	<xsl:template name="DoNextMaths">
		<!-- xsl:message>DoNextMaths pbc 1:</xsl:message -->
		<xsl:variable name="EquationLine" select="xhtml:span[@class='MTConvertedEquation']" />
		<xsl:variable name="StartLine">
			<xsl:text disable-output-escaping='yes'>&lt;math</xsl:text>
		</xsl:variable>
		<xsl:for-each select="following-sibling::xhtml:*[1]">
		<xsl:variable name="NextEquationLine" select="xhtml:span[@class='MTConvertedEquation']" />
		<!--xsl:message>
			<xsl:text>DoNextMaths pbc 1.1: EquationLine='</xsl:text>
			<xsl:value-of select="$EquationLine"/>
			<xsl:text>', string-length='</xsl:text>
			<xsl:value-of select="string-length()"/>
			<xsl:text>',NextEquationLine='</xsl:text>
			<xsl:value-of select="$NextEquationLine"/>
			<xsl:text>'</xsl:text>
		</xsl:message -->
			<xsl:choose>
				<xsl:when test="string-length()=0">
		<!-- xsl:message>DoNextMaths pbc 2:</xsl:message -->
					<xsl:call-template name="DoNextMaths" />
				</xsl:when>
				<xsl:when test="substring($NextEquationLine,1,5)=$StartLine">
		<!-- xsl:message>DoNextMaths pbc 3:</xsl:message -->
					<xsl:choose>
						<xsl:when test="normalize-space()=normalize-space($NextEquationLine)">
		<!-- xsl:message>DoNextMaths pbc 3.1:</xsl:message -->
							<xsl:call-template name="DoMaths" />
						</xsl:when>
						<xsl:otherwise>
		<!-- xsl:message>DoNextMaths pbc 3.2:</xsl:message>
							<Paragraph>[DoNextMaths 1]</Paragraph -->
							<xsl:call-template name="DoParagraphWithMaths">
								<xsl:with-param name="Parent" select="'Paragraph'" />
							</xsl:call-template>
							<!-- Paragraph>[DoNextMaths 2]</Paragraph -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="count(xhtml:span[@class='MTConvertedEquation']) = 0">
		<!-- xsl:message>DoNextMaths pbc 4:</xsl:message -->
					<xsl:if test="contains(@class,'Equation')">
		<!-- xsl:message>DoNextMaths pbc 5:</xsl:message -->
						<xsl:for-each select="following-sibling::xhtml:*[1]">
							<xsl:if test="normalize-space()=normalize-space(xhtml:span[@class='MTConvertedEquation'])">
		<!-- xsl:message>DoNextMaths pbc 5.1:</xsl:message -->
								<xsl:call-template name="DoMaths" />
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:when>
				<xsl:when test="contains(@class,'Equation')">
		<!-- xsl:message>DoNextMaths pbc 6:</xsl:message -->
					<xsl:call-template name="DoNextMaths" />
				</xsl:when>
			</xsl:choose>
		<!-- xsl:message>DoNextMaths pbc 7:</xsl:message -->
		</xsl:for-each>
		<!-- xsl:message>DoNextMaths pbc 8:</xsl:message -->
	</xsl:template>
	
	<xsl:template name="DoLabel">
		<xsl:for-each select="following-sibling::xhtml:*[1]">
			<xsl:choose>
				<xsl:when test="string-length()=0">
					<xsl:call-template name="DoLabel" />
				</xsl:when>
				<xsl:when test="count(xhtml:span[@class='MTConvertedEquation']) = 0">
					<xsl:if test="contains(@class,'Equation')">
						<Label>
							<xsl:value-of select="text()"/>
						</Label>
					</xsl:if>
				</xsl:when>
				<xsl:when test="contains(@class,'Equation')">
					<xsl:call-template name="DoLabel" />
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="ReplaceMathTypeEntity">
		<xsl:param name="InputText" select="." />
		<xsl:choose>
			<xsl:when test="contains($InputText,'&amp;')">
				<xsl:value-of disable-output-escaping="yes" select="substring-before($InputText,'&amp;')"/>
				<xsl:call-template name="SubstituteEntity">
					<xsl:with-param name="Entity" select="substring-before(substring-after($InputText,'&amp;'),';')" />
				</xsl:call-template>
				<xsl:call-template name="ReplaceMathTypeEntity">
					<xsl:with-param name="InputText" select="substring-after(substring-after($InputText,'&amp;'),';')" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of disable-output-escaping="yes" select="$InputText"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="SubstituteEntity">
		<xsl:param name="Entity" />
		<xsl:choose>
			<xsl:when test="$Entity='nbsp'"><xsl:value-of disable-output-escaping="yes" select="'&amp;#x000A0;'"/></xsl:when>
			<xsl:otherwise>
				<xsl:value-of disable-output-escaping="yes" select="concat('&amp;',$Entity,';')"/></xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template name="ReplaceMathCharacter">
		<xsl:param name="InputText" select="." />
		<xsl:choose>
			<xsl:when test="contains($InputText,'&amp;#x')">
				<xsl:value-of select="substring-before($InputText,'&amp;#x')" disable-output-escaping="yes"/>
				<xsl:variable name="NextBit" select="substring-after($InputText, '&amp;#x')"></xsl:variable>
				<xsl:choose>
					<xsl:when test="substring($NextBit,1,5) = '02DC;'">
						<!-- State symbol or plimsoll line -->
						<xsl:text disable-output-escaping="yes">&amp;#x29B5;</xsl:text>
						<xsl:call-template name="ReplaceMathCharacter">
							<xsl:with-param name="InputText" select="substring-after($NextBit,'02DC;')" />
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="NumericBit" select="substring-before($NextBit,';')"/>
						<xsl:text disable-output-escaping="yes">&amp;#x</xsl:text>
						<xsl:value-of select="concat($NumericBit, ';')" disable-output-escaping="yes"/>
						<xsl:call-template name="ReplaceMathCharacter">
							<xsl:with-param name="InputText" select="substring-after($NextBit,';')" />
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$InputText" disable-output-escaping="yes" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ITQ templates -->
	
	<xsl:template name="DoITQ">
		<!-- Check if first line of ITQ -->
		<xsl:variable name="IsFirstLine">
			<xsl:call-template name="IsFirstLine">
				<xsl:with-param name="Style" select="'ITQ'" />
				<xsl:with-param name="NextStyle" select="'ITQA'" />
				<xsl:with-param name="CurrentStyle" select="@class" />
			</xsl:call-template>
		</xsl:variable>
		<!-- If it is then process it, otherwise ignore it. -->
		<xsl:if test="$IsFirstLine='true'">
			<ITQ>
				<Question>
					<Paragraph>
						<xsl:choose>
							<xsl:when test="count(xhtml:span[@class='MTConvertedEquation'])">
								<xsl:call-template name="DoParagraphWithMaths">
									<xsl:with-param name="DoIt" select="true()" />
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates />
							</xsl:otherwise>
						</xsl:choose>
					</Paragraph>
				</Question>
			</ITQ>
		</xsl:if>
		<xsl:if test="$IsFirstLine!='true'">
			<xsl:call-template name="DoParagraphWithMaths" />
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="IsFirstLine">
		<xsl:param name="Style" select="'none'" />
		<xsl:param name="NextStyle" select="'nonenext'" />
		<xsl:param name="CurrentStyle" />
		
		<xsl:choose>
			<xsl:when test="count(preceding-sibling::xhtml:p[1])=0">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:when test="preceding-sibling::xhtml:p[1]/@class=$CurrentStyle">
				<xsl:value-of select="false()"/>
			</xsl:when>
			<xsl:when test="contains($CurrentStyle,$NextStyle) and contains(preceding-sibling::xhtml:p[1]/@class,$Style)">
				<xsl:value-of select="false()"/>
			</xsl:when>
			<xsl:when test="string-length(normalize-space(preceding-sibling::xhtml:p[1])) &gt; 0">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:when test="count(preceding-sibling::xhtml:p[1][@class='MsoNormal'])=1">
				<xsl:for-each select="preceding-sibling::xhtml:p[1]">
					<xsl:call-template name="IsFirstLine">
						<xsl:with-param name="Style" select="$Style" />
						<xsl:with-param name="NextStyle" select="$NextStyle" />
						<xsl:with-param name="CurrentStyle" select="$CurrentStyle" />
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="string-length(preceding-sibling::xhtml:p[1]/@class)=0">
				<xsl:for-each select="preceding-sibling::xhtml:p[1]">
					<xsl:call-template name="IsFirstLine">
						<xsl:with-param name="Style" select="$Style" />
						<xsl:with-param name="NextStyle" select="$NextStyle" />
						<xsl:with-param name="CurrentStyle" select="$CurrentStyle" />
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="true()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Index templates -->
	
	<xsl:template match="xhtml:p[contains(@class,'Index')]">
		<xsl:variable name="IndexTag">
			<xsl:choose>
				<xsl:when test="contains(@class,'Index1')">Index1</xsl:when>
				<xsl:when test="contains(@class,'Index2')">Index2</xsl:when>
				<xsl:when test="contains(@class,'Index3')">Index3</xsl:when>
				<xsl:otherwise>Paragraph</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{$IndexTag}">
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>
	
	<!-- End of Index templates -->
	
	<xsl:template name="IsInTable">
		<xsl:choose>
			<xsl:when test="local-name()='table'">true</xsl:when>
			<xsl:when test="contains(@class,'TableFootnote')">
				<xsl:choose>
					<xsl:when test="count(preceding-sibling::*[1]) = 0">
						<xsl:value-of select="false()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="preceding-sibling::*[1]">
							<xsl:call-template name="IsInTable" />
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:br">
		<br />
	</xsl:template>
	
	<xsl:template match="xhtml:br[contains(normalize-space(@style), 'page-break-before:always')]" >
		<xsl:processing-instruction name="pagination">layout-hint="pagebreak"</xsl:processing-instruction>
	</xsl:template>
	
	<!-- Inline formatting (processed in xhtml:span template) -->
	<!-- There should be a template for inline formatting within a paragraph -->
	<!-- and also one for mode="Inline" -->

	<xsl:template match="xhtml:b | xhtml:strong" mode="Inline">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<b><xsl:apply-templates /></b>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:p//xhtml:b | xhtml:p//xhtml:strong">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<b><xsl:apply-templates /></b>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:i | xhtml:em" mode="Inline">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<i><xsl:apply-templates /></i>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:p//xhtml:i | xhtml:p//xhtml:em">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<i><xsl:apply-templates /></i>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:u" mode="Inline">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<u><xsl:apply-templates /></u>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:p//xhtml:u">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<u><xsl:apply-templates /></u>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:sub" mode="Inline">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<sub><xsl:apply-templates /></sub>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:p//xhtml:sub">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<sub><xsl:apply-templates /></sub>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:sup" mode="Inline">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<sup><xsl:apply-templates /></sup>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xhtml:p//xhtml:sup">
		<xsl:choose>
			<xsl:when test="(string-length(.) &gt; 0) and (count (.//xhtml:span[translate(@style, ' ', '')='mso-list:Ignore']) = 0)">
				<sup><xsl:apply-templates /></sup>
			</xsl:when>
			<xsl:when test="count(//xhtml:br)&gt; 0"><xsl:apply-templates /></xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="DoSpanAttributes">
		<xsl:if test="(string-length(.) &gt; 0) and (count (ancestor::xhtml:span[@style='mso-list:Ignore']) = 0)">
			<xsl:choose>
				<xsl:when test="local-name()='span'">
					<xsl:variable name="HasSmallCaps" select="contains(@style, 'small-caps')" />
					
					<xsl:variable name="NewFont">
						<xsl:variable name="TempNewFont">
							<xsl:variable name="EditedStyle">
								<xsl:call-template name="EditStyleFontFamily" />
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="contains(translate($EditedStyle, ' ',''),'font-family:&quot;')"><xsl:value-of select="substring-before(substring-after(substring-after($EditedStyle, 'font-family:'), '&quot;'), '&quot;')"/>
								</xsl:when>
								<xsl:when test="contains(substring-after($EditedStyle, 'font-family:'),';')"><xsl:value-of select="substring-before(substring-after(translate($EditedStyle,' ', ''), 'font-family:'), ';')"/></xsl:when>
								<xsl:otherwise><xsl:value-of select="substring-after(translate($EditedStyle, ' ', ''), 'font-family:')"/></xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="count(*[contains(translate(@style, ' ', ''), 'mso-list:Ignore')]) &gt; 0" />
							<xsl:when test="$TempNewFont=$NormalFont"/>
							<xsl:otherwise><xsl:value-of select="$TempNewFont"/></xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<xsl:variable name="HasFont" select="string-length($NewFont) &gt; 0" />
					
					<xsl:variable name="HasLanguage">
						<xsl:call-template name="HasLanguage" />
					</xsl:variable>
					
					<xsl:variable name="HasProgramCode" select="contains(translate(@class, $UpperAndSpace, $Lower), 'program')" />
					
					<xsl:variable name="HasGlossaryTerm" select="contains(translate(@class, $UpperAndSpace, $Lower), 'glossedterm')" />
					
					<xsl:variable name="HasBold">
						<xsl:choose>
							<xsl:when test="contains(translate(@class, $UpperAndSpace, $Lower), 'bdcbold')">
								<xsl:choose>
									<xsl:when test=".//*[@style='mso-list:Ignore'] = .">false</xsl:when>
									<xsl:otherwise>true</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>false</xsl:otherwise>
						</xsl:choose>
					</xsl:variable> 
					
					<xsl:variable name="HasItalic">
						<xsl:choose>
							<xsl:when test="contains(translate(@class, $UpperAndSpace, $Lower), 'itcitalic')">
								<xsl:choose>
									<xsl:when test=".//*[@style='mso-list:Ignore'] = .">false</xsl:when>
									<xsl:otherwise>true</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>false</xsl:otherwise>
						</xsl:choose>
					</xsl:variable> 
					
					<xsl:variable name="xxxHasItalic" select="contains(translate(@class, $UpperAndSpace, $Lower), 'itcitalic')" />
					
					<xsl:if test="$HasSmallCaps='true'">
						<xsl:text disable-output-escaping="yes">&lt;smallCaps&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasFont='true'">
						<xsl:text disable-output-escaping="yes">&lt;font val="</xsl:text>
						<xsl:value-of select="$NewFont"/>
						<xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasLanguage='true'">
							<!-- xsl:text disable-output-escaping="yes">&lt;language val="</xsl:text>
						<xsl:call-template name="GetLanguage" />
						<xsl:text disable-output-escaping="yes">" lang="</xsl:text -->
						<xsl:text disable-output-escaping="yes">&lt;language xml:lang="</xsl:text>
						<xsl:call-template name="GetLanguage" />
						<xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasProgramCode='true'">
						<xsl:text disable-output-escaping="yes">&lt;ComputerCode&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasGlossaryTerm='true'">
						<xsl:text disable-output-escaping="yes">&lt;GlossaryTerm&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasBold='true'">
						<xsl:text disable-output-escaping="yes">&lt;b&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasItalic='true'">
						<xsl:text disable-output-escaping="yes">&lt;i&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$Testing='true'">
						<xsl:text>[pbc DoSpanAttibutes before applying templates: </xsl:text>
						<xsl:for-each select="node()">
							<xsl:text>{name='</xsl:text>
							<xsl:value-of select="name()"/>
							<xsl:text>', value='</xsl:text>
							<xsl:value-of select="."/>
							<xsl:text>'}</xsl:text>
						</xsl:for-each>
						<xsl:text>]</xsl:text>
					</xsl:if>
					
					<xsl:apply-templates />
					
					<xsl:if test="$Testing='true'">
						<xsl:text>[pbc DoSpanAttibutes after applying templates]</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasItalic='true'">
						<xsl:text disable-output-escaping="yes">&lt;/i&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasBold='true'">
						<xsl:text disable-output-escaping="yes">&lt;/b&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasGlossaryTerm='true'">
						<xsl:text disable-output-escaping="yes">&lt;/GlossaryTerm&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasProgramCode='true'">
						<xsl:text disable-output-escaping="yes">&lt;/ComputerCode&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasLanguage='true'">
						<xsl:text disable-output-escaping="yes">&lt;/language&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasFont='true'">
						<xsl:text disable-output-escaping="yes">&lt;/font&gt;</xsl:text>
					</xsl:if>
					
					<xsl:if test="$HasSmallCaps='true'">
						<xsl:text disable-output-escaping="yes">&lt;/smallCaps&gt;</xsl:text>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="." mode="Inline"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="*" mode="DoInline">
		<xsl:choose>
			<xsl:when test="local-name()='span'"><xsl:call-template name="DoSpanAttributes" /></xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="node()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="EditStyleFontFamily">
		<xsl:param name="Style" select="@style" />
		<xsl:choose>
			<xsl:when test="contains($Style, '-font-family')">
				<xsl:call-template name="EditStyleFontFamily">
					<xsl:with-param name="Style" select="concat(substring-before($Style,'-font-family'), substring-after($Style, '-font-family'))"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="$Style"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Lists -->

	<xsl:template match="xhtml:ol"> <!-- Numbered lists -->
		<NumberedList>
			<xsl:apply-templates />
		</NumberedList>
	</xsl:template>
	
	<xsl:template match="xhtml:li">
		<ListItem>
			<xsl:apply-templates />
		</ListItem>
	</xsl:template>
	
	<!-- Lists are identified by their style being "mso-list: l" followed -->
	<!-- by the level e.g. "0 level1" -->
	<xsl:template match="xhtml:p[contains(@style,'mso-list:')]">
		<xsl:variable name="ListLevel">
			<xsl:call-template name="GetListLevel" />
		</xsl:variable>
		<xsl:variable name="InsideList">
			<xsl:call-template name="IsInList">
				<xsl:with-param name="Level" select="$ListLevel" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$InsideList = 'false'">
			<xsl:variable name="FollowsList">
				<xsl:call-template name="FollowsList" />
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$ListLevel='1'">
					<xsl:call-template name="OutputList" />
				</xsl:when>
				<!--xsl:when test="contains(@style, 'level1')">
					<xsl:call-template name="OutputList" />
				</xsl:when-->
				<xsl:when test="$FollowsList = 'true'">
					<xsl:call-template name="OutputSubList" />
				</xsl:when>
				<xsl:otherwise>
					<UnNumberedList>
						<ListItem>
							<xsl:call-template name="OutputSubList" />
						</ListItem>
					</UnNumberedList>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="xhtml:p[(count(.//xhtml:span[contains(translate(@style, ' ', ''), 'mso-list:Ignore')]) &gt; 0) and (not(contains(translate(@style, ' ', ''),'mso-list:')))]">
		<xsl:variable name="ListLevel">
			<xsl:call-template name="GetListLevel" />
		</xsl:variable>
		<xsl:variable name="InsideList">
			<xsl:call-template name="IsInList">
				<xsl:with-param name="Level" select="$ListLevel" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$InsideList='false'">
			<xsl:variable name="FollowsList">
				<xsl:call-template name="FollowsList" />
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$ListLevel='1'">
					<xsl:call-template name="OutputList" />
				</xsl:when>
				<xsl:when test="$FollowsList = 'true'">
					<xsl:call-template name="OutputSubList" />
				</xsl:when>
				<xsl:otherwise>
					<UnNumberedList>
						<ListItem>
							<xsl:call-template name="OutputSubList" />
						</ListItem>
					</UnNumberedList>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="OutputList">
		<xsl:variable name="ListType">
			<xsl:call-template name="GetListType"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$ListType='decimal'">
				<NumberedList class="decimal">
					<xsl:call-template name="OutputListItems"/>
				</NumberedList>
			</xsl:when>
			<xsl:when test="$ListType='lower-alpha'">
				<NumberedList class="lower-alpha">
					<xsl:call-template name="OutputListItems"/>
				</NumberedList>
			</xsl:when>
			<xsl:when test="$ListType='upper-alpha'">
				<NumberedList class="upper-alpha">
					<xsl:call-template name="OutputListItems"/>
				</NumberedList>
			</xsl:when>
			<xsl:when test="$ListType='lower-roman'">
				<NumberedList class="lower-roman">
					<xsl:call-template name="OutputListItems"/>
				</NumberedList>
			</xsl:when>
			<xsl:when test="$ListType='upper-roman'">
				<NumberedList class="upper-roman">
					<xsl:call-template name="OutputListItems"/>
				</NumberedList>
			</xsl:when>
			<xsl:when test="$ListType='bulleted'">
				<BulletedList>
					<xsl:call-template name="OutputListItems"/>
				</BulletedList>
			</xsl:when>
			<xsl:when test="$ListType='unnumbered'">
				<UnNumberedList>
					<xsl:call-template name="OutputListItems"/>
				</UnNumberedList>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="OutputSubList">
		<xsl:variable name="ListType">
			<xsl:call-template name="GetListType"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$ListType='decimal'">
				<NumberedSubsidiaryList class="decimal">
					<xsl:call-template name="OutputSubListItems"/>
				</NumberedSubsidiaryList>
			</xsl:when>
			<xsl:when test="$ListType='lower-alpha'">
				<NumberedSubsidiaryList class="lower-alpha">
					<xsl:call-template name="OutputSubListItems"/>
				</NumberedSubsidiaryList>
			</xsl:when>
			<xsl:when test="$ListType='upper-alpha'">
				<NumberedSubsidiaryList class="upper-alpha">
					<xsl:call-template name="OutputSubListItems"/>
				</NumberedSubsidiaryList>
			</xsl:when>
			<xsl:when test="$ListType='lower-roman'">
				<NumberedSubsidiaryList class="lower-roman">
					<xsl:call-template name="OutputSubListItems"/>
				</NumberedSubsidiaryList>
			</xsl:when>
			<xsl:when test="$ListType='upper-roman'">
				<NumberedSubsidiaryList class="upper-roman">
					<xsl:call-template name="OutputSubListItems"/>
				</NumberedSubsidiaryList>
			</xsl:when>
			<xsl:when test="$ListType='bulleted'">
				<BulletedSubsidiaryList>
					<xsl:call-template name="OutputSubListItems"/>
				</BulletedSubsidiaryList>
			</xsl:when>
			<xsl:when test="$ListType='unnumbered'">
				<UnNumberedSubsidiaryList>
					<xsl:call-template name="OutputSubListItems"/>
				</UnNumberedSubsidiaryList>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="OutputListItems">
		<xsl:variable name="ListLevel">
			<xsl:call-template name="GetListLevel" />
		</xsl:variable>
		<xsl:variable name="InList">
			<xsl:call-template name="IsInList">
				<xsl:with-param name="Level" select="$ListLevel" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$ListLevel = 1">
			<ListItem>
				<xsl:choose>
					<xsl:when test="$ListLevel=1">
						<xsl:apply-templates />
						<xsl:variable name="NextIsSublist">
							<xsl:call-template name="NextIsSubList" />
						</xsl:variable>
						<xsl:if test="$NextIsSublist='true'">
							<xsl:for-each select="following-sibling::xhtml:*[1]">
								<xsl:call-template name="OutputSubList" />
							</xsl:for-each>
						</xsl:if>
					</xsl:when>
				</xsl:choose>
			</ListItem>
		</xsl:if>
		<xsl:for-each select="following-sibling::xhtml:*[1]">
			<xsl:if test="contains(@style, 'mso-list:') or (count(.//xhtml:span[contains(translate(@style, ' ', ''), 'mso-list:Ignore')]) &gt; 0)">
				<xsl:call-template name="OutputListItems"/>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="following-sibling::xhtml:*[1][(local-name()='p') and (string-length(.) = 0)]">
			<xsl:for-each select="following-sibling::xhtml:*[1]">
				<xsl:call-template name="OutputListItems"/>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

	<xsl:template name="OutputSubListItems">
		<xsl:variable name="ListLevel">
			<xsl:call-template name="GetListLevel" />
		</xsl:variable>
		<xsl:if test="$ListLevel &gt; 1">
			<SubListItem>
				<xsl:apply-templates />
			</SubListItem>
		</xsl:if>
		<xsl:for-each select="following-sibling::xhtml:*[1]">
			<xsl:variable name="NextLevel">
				<xsl:call-template name="GetListLevel" />
			</xsl:variable>
			<xsl:if test="(contains(@style, 'mso-list:') or (count(.//xhtml:span[contains(translate(@style, ' ', ''), 'mso-list:Ignore')]) &gt; 0)) and ($NextLevel &gt; 1)">
				<xsl:call-template name="OutputSubListItems"/>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="following-sibling::xhtml:*[1][(local-name()='p') and (string-length(.) = 0)]">
			<xsl:for-each select="following-sibling::xhtml:*[1]">
				<xsl:call-template name="OutputSubListItems"/>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="xhtml:p[contains(@style,'mso-list:') and preceding-sibling::xhtml:*[(position()=1) and contains(@style,'mso-list:')]]" />
	
	<xsl:template name="IsInList">
		<xsl:param name="Level" select="0" />
		<xsl:if test="count(preceding-sibling::xhtml:*[1]) = 0"><xsl:value-of select="false()"/></xsl:if>
		<xsl:for-each select="preceding-sibling::xhtml:*[1]">
			<xsl:choose>
				<xsl:when test="(local-name()='p') and (string-length (.) = 0)">
						<xsl:call-template name="IsInList">
							<xsl:with-param name="Level" select="$Level"></xsl:with-param>
						</xsl:call-template>
				</xsl:when>
				<xsl:when test="contains(@style,'mso-list:')">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="count(.//xhtml:span[contains(translate(@style, ' ', ''), 'mso-list:Ignore')]) &gt; 0"><xsl:value-of select="true()"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="false()"/></xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="FollowsList">
		<xsl:if test="count(preceding-sibling::xhtml:*[1]) = 0"><xsl:value-of select="false()"/></xsl:if>
		<xsl:for-each select="preceding-sibling::xhtml:*[1]">
			<xsl:choose>
				<xsl:when test="(local-name()='p') and (string-length (.) = 0)">
						<xsl:call-template name="FollowsList" />
				</xsl:when>
				<xsl:when test="contains(@style,'mso-list:')">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="count(.//xhtml:span[contains(translate(@style, ' ', ''), 'mso-list:Ignore')]) &gt; 0">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="false()"/></xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="NextIsSubList">
		<xsl:if test="count(following-sibling::xhtml:*[1]) = 0"><xsl:value-of select="false()"/></xsl:if>
		<xsl:for-each select="following-sibling::xhtml:*[1]">
			<xsl:choose>
				<xsl:when test="(local-name()='p') and (string-length (.) = 0)">
						<xsl:call-template name="NextIsSubList" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="ListLevel">
						<xsl:call-template name="GetListLevel" />
					</xsl:variable>
					<xsl:value-of select="$ListLevel &gt; 1"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="GetListLevel">
		<xsl:choose>
			<xsl:when test="contains(@style,'mso-list:')">
				<xsl:value-of select="substring(substring-after(translate(@style, ' ', ''),'level'),1,1)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="Style" select="translate (substring-before (substring-after (substring-after (/xhtml:html/xhtml:head/xhtml:style[count(@id)=0], concat('p.', @class)), '{'), '}'), ' ', '')"/>  <!-- Need to discount anything with an @id, used when there are comments -->
				<xsl:value-of select="substring(substring-after($Style,'level'),1,1)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="GetListType">
		<xsl:variable name="MarkerField" select=".//xhtml:span[contains(translate(@style,' ',''),'mso-list:Ignore')]" />
		
		<xsl:variable name="Marker">
			<xsl:choose>
				<xsl:when test="starts-with($MarkerField,' ')"><xsl:text>null</xsl:text></xsl:when>
				<xsl:when test="starts-with($MarkerField,'(')"><xsl:value-of select="substring(substring-after($MarkerField,'('),1,1)"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="substring($MarkerField,1,1)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="contains(translate(.//xhtml:span[contains(translate(@style,' ',''),'mso-list:Ignore')]/../@style, ' ', ''), 'font-family:Wingdings')">bulleted</xsl:when>
			<xsl:when test="$Marker='null'">unnumbered</xsl:when>
			<xsl:when test="contains('0123456789',$Marker)">decimal</xsl:when>
			<xsl:when test="contains('ivx',$Marker)">lower-roman</xsl:when>
			<xsl:when test="contains('IVX',$Marker)">upper-roman</xsl:when>
			<xsl:when test="contains('abcdefghijklmnopqrstuvwxyz',$Marker)">lower-alpha</xsl:when>
			<xsl:when test="contains('ABCDEFGHIJKLMNOPQRSTUVWXYZ',$Marker)">upper-alpha</xsl:when>
			<xsl:otherwise>bulleted</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- End of lists -->
	
	<!-- Start of tables -->
	
	<xsl:template match="xhtml:table">
		<Table>
			<TableHead>
				<xsl:if test="contains(preceding-sibling::*[1]/@class,'TableHead')">
					<xsl:apply-templates select="preceding-sibling::*[1]/node()" />
				</xsl:if>
			</TableHead>
			<tbody>
				<xsl:apply-templates />
			</tbody>
			<xsl:apply-templates select="following-sibling::*[1]" mode="Table" />
		</Table>
	</xsl:template>
	
	<xsl:template match="xhtml:p[contains(@class,'TableFootnote')]" mode="Table">
		<TableFootnote><xsl:apply-templates /></TableFootnote>
		<xsl:apply-templates select="following-sibling::*[1]" mode="Table" />
	</xsl:template>
	
	<xsl:template match="xhtml:p[contains(@class,'SourceReference')]" mode="Table">
		<SourceReference><xsl:apply-templates /></SourceReference>
	</xsl:template>
	
	<xsl:template match="node()" mode="Table" />
	
	<xsl:template match="xhtml:tr">
		<tr>
			<xsl:apply-templates />
		</tr>
	</xsl:template>
	
	<xsl:template match="xhtml:td">
		<xsl:variable name="CellName">
			<xsl:choose>
				<xsl:when test="contains(xhtml:p/@class,'Head')">th</xsl:when>
				<xsl:otherwise>td</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="CellType">
			<xsl:choose>
				<xsl:when test="contains(xhtml:p/@class,'Head')">
					<xsl:text>ColumnHead</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>Table</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="Alignment">
			<xsl:choose>
				<xsl:when test="contains(xhtml:p/@class,'Right')">
					<xsl:text>Right</xsl:text>
				</xsl:when>
				<xsl:when test="contains(xhtml:p/@class,'Centered') or contains(xhtml:p/@class,'Centred')">
					<xsl:text>Centered</xsl:text>
				</xsl:when>
				<xsl:when test="contains(xhtml:p/@class,'Decimal') and ($CellName = 'td')">
					<xsl:text>Decimal</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>Left</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{$CellName}">
			<xsl:if test="(count(xhtml:p/@class) &gt; 0) and (xhtml:p/@class != 'MsoNormal') and (xhtml:p/@class != 'MsoNormal')">
				<xsl:attribute name="class">
					<xsl:value-of select="concat($CellType,$Alignment)"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="(count(@rowspan) &gt; 0) and (@rowspan != 1)">
				<xsl:attribute name="rowspan">
					<xsl:value-of select="@rowspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="(count(@colspan) &gt; 0) and (@colspan != 1)">
				<xsl:attribute name="colspan">
					<xsl:value-of select="@colspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="(count(xhtml:p)=0) and (string-length() &gt; 0)">
					<xsl:apply-templates />
				</xsl:when>
				<xsl:when test="(count(xhtml:p[string-length() &gt; 0]) = 0) and (count(xhtml:*[local-name() != 'p']) = 0)" />
				<xsl:when test="(count(xhtml:p[string-length() &gt; 0]) = 1) and (count(xhtml:*[local-name() != 'p']) = 0)">
					<xsl:apply-templates select="xhtml:p[string-length() &gt; 0]/node()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>
	
	<!-- End of tables -->
	
	<!-- Sessions, Sections, etc -->
	
	<xsl:template match="xhtml:h1 | xhtml:h2 | xhtml:h3">
		<Title><xsl:apply-templates /></Title>
	</xsl:template>
	
	<xsl:template match="xhtml:h4">
		<Heading><xsl:apply-templates /></Heading>
	</xsl:template>
	
	<xsl:template name="CountHeads">
		<xsl:param name="Count" select="0" />
		<xsl:choose>
			<xsl:when test="count(following::xhtml:p | descendant::xhtml:p) = 0">
				<xsl:value-of select="$Count"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="(following::xhtml:p | descendant::xhtml:p)[1]">
					<xsl:variable name="HasLevel">
						<xsl:call-template name="HasOutlineLevel" />
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$HasLevel ='true'">
							<xsl:call-template name="CountHeads">
								<xsl:with-param name="Count" select="$Count + 1" />
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="CountHeads">
								<xsl:with-param name="Count" select="$Count" />
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="HasOutlineLevel">
		<xsl:variable name="OutlineLevel">
			<xsl:call-template name="GetOutlineLevel" />
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$OutlineLevel &gt; 0">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="GetOutlineLevel">
		<xsl:variable name="Style" select="translate (substring-before (substring-after (substring-after (/xhtml:html/xhtml:head/xhtml:style[count(@id)=0], concat('p.', @class)), '{'), '}'), ' ', '')"/>  <!-- Need to discount anything with an @id, used when there are comments -->
		<xsl:variable name="OutlineLevel">
			<xsl:choose>
				<xsl:when test="local-name()='h1'">1</xsl:when>
				<xsl:when test="local-name()='h2'">2</xsl:when>
				<xsl:when test="local-name()='h3'">3</xsl:when>
				<xsl:when test="local-name()='h4'">4</xsl:when>
				<xsl:when test="contains(translate(@style, ' ', ''), 'mso-outline-level:')"><xsl:value-of select="substring(substring-after(translate(@style, ' ', ''), 'mso-outline-level:'), 1, 1)"/></xsl:when> <!-- Direct formatting overrides everything else -->
				<xsl:when test="contains($Style,'mso-outline-level:')">
					<xsl:value-of select="substring-before(substring-after($Style, 'mso-outline-level:'), ';')"/>
				</xsl:when>
				<xsl:otherwise>0</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$OutlineLevel" />
	</xsl:template>
	
	<xsl:template match="xhtml:a">
		<xsl:if test="$Testing='true'">
			<xsl:text>[pbc a start]</xsl:text>
		</xsl:if>
		<xsl:if test="string-length(.) &gt; 0">
			<xsl:choose>
				<xsl:when test="starts-with(@name,'OLE_') or starts-with(@name,'_Hlk') or starts-with(@name,'_Toc')">
					<xsl:if test="$Testing='true'">
						<xsl:text>[pbc a when 1]</xsl:text>
					</xsl:if>
					<xsl:apply-templates />
					<xsl:if test="$Testing='true'">
						<xsl:text>[pbc a when 2]</xsl:text>
					</xsl:if>
				</xsl:when>
				<xsl:when test="starts-with(@style,'mso-comment-reference')">
					<xsl:variable name="CommentReference" select="concat('_',substring(following::xhtml:span[@class='MsoCommentReference']//xhtml:a/@href,6))" />
					<xsl:variable name="Author" select="substring-before(normalize-space(substring-before(substring-after(@style,'mso-comment-reference:'),';')),'_')" />
					<xsl:variable name="CommentNumber" select="substring-after(normalize-space(substring-before(substring-after(@style,'mso-comment-reference:'),';')),'_')" />
					<xsl:variable name="TimeStamp" select="normalize-space(substring-after(@style,'mso-comment-date:'))" />
					<xsl:processing-instruction name="oxy_comment_start">
						<xsl:text>author="</xsl:text>
						<xsl:value-of select="$Author"/>
						<xsl:text>" timestamp="</xsl:text>
						<xsl:value-of select="$TimeStamp"/>
						<xsl:if test="string-length($TimeStamp = 8)">
							<xsl:text>00</xsl:text>
						</xsl:if>
						<xsl:text>+0000" comment="</xsl:text>
						<xsl:value-of select="normalize-space(substring-after(/.//xhtml:div[@id=$CommentReference]/xhtml:p,']'))"/>
						<xsl:text>"</xsl:text>
					</xsl:processing-instruction>
					<xsl:apply-templates />
					<xsl:processing-instruction name="oxy_comment_end" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="$Testing='true'">
						<xsl:text>[pbc a otherwise 1]</xsl:text>
					</xsl:if>
					<a>
						<xsl:if test="string-length(@name) &gt; 0">
							<xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
						</xsl:if>
						<xsl:if test="string-length(@href)">
							<xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
						</xsl:if>
						<xsl:apply-templates />
					</a>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$Testing='true'">
			<xsl:text>[pbc a end]</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="xhtml:p//xhtml:span">
		<!--xsl:message>p//span: start</xsl:message-->
		<xsl:if test="(translate(@style, ' ', '') != 'mso-list:Ignore') and ((count(@class)=0) or (@class!='MTConvertedEquation'))">
			<!--xsl:message>p//span: in if</xsl:message-->
			<xsl:call-template name="DoSpanAttributes" />
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="xhtml:span[@class='MsoCommentReference']" />
	
	<xsl:template match="xhtml:span[contains(@style,'mso-spacerun:yes')]">
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="xhtml:span[contains(@style,'mso-tabcount:')]">
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="xhtml:span[contains(translate(@class, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'program')]" mode="Inline">
		<ComputerCode><xsl:apply-templates mode="Inline"/></ComputerCode>
	</xsl:template>
	
	<xsl:template match="xhtml:span[contains(translate(@class, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'glossedterm')]" mode="Inline">
		<GlossaryTerm><xsl:apply-templates mode="Inline"/></GlossaryTerm>
	</xsl:template>
	
	<xsl:template match="xhtml:span" mode="Inline">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="xhtml:span | xhtml:b | xhtml:strong | xhtml:i | xhtml:em | xhtml:u | xhtml:sub | xhtml:sup">
		<!-- xsl:text>[pbc span + start, name='</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:text>']</xsl:text -->
		<xsl:variable name="NextSiblingName" select="concat(';', local-name(following-sibling::*[1]), ';')" />
		<xsl:variable name="IsParagraph">
			<xsl:call-template name="IsParagraph" />
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$IsParagraph='true'">
				<Paragraph>
					<xsl:call-template name="DoSpanAttributes" />
					<xsl:for-each select="following-sibling::*[(position()=1) and contains($InLineTags, concat(';', local-name(), ';'))]">
						<xsl:apply-templates select="." mode="InsideParagraph" />
					</xsl:for-each>
				</Paragraph>
			</xsl:when>
			<xsl:when test = "count(preceding-sibling::xhtml:p) + count(preceding-sibling::xhtml:h1) + count(preceding-sibling::xhtml:h2) + count(preceding-sibling::xhtml:h3) + count(preceding-sibling::xhtml:h4) &gt; 0">
			<xsl:if test=".//xhtml:br[contains(normalize-space(@style),'page-break-before:always')]">
					<xsl:processing-instruction name="pagination">layout-hint="pagebreak"</xsl:processing-instruction>
				</xsl:if>
			</xsl:when>
			
			<xsl:otherwise>
				<!-- xsl:text>[pbc span + otherwise - start]</xsl:text -->
				<xsl:if test="(translate(@style, ' ', '') != 'mso-list:Ignore') and ((string-length(@class)=0) or (@class != 'MsoCommentReference'))">
					<xsl:choose>
						<xsl:when test="local-name()='span'">
							<!-- xsl:text>[pbc span + otherwise - when - start]</xsl:text -->
							<xsl:call-template name="DoSpanAttributes" />
							<!-- xsl:text>[pbc span + otherwise - when - end]</xsl:text -->
						</xsl:when>
						<xsl:otherwise>
							<!-- xsl:text>[pbc span + otherwise - otherwise - start]</xsl:text -->
							<xsl:apply-templates select="." mode="Inline" />
							<!-- xsl:text>[pbc span + otherwise - otherwise - end]</xsl:text -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!-- xsl:text>[pbc span + otherwise - end]</xsl:text -->
			</xsl:otherwise>
		</xsl:choose>
		<!-- xsl:text>[pbc span + end, name='</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:text>']</xsl:text -->
	</xsl:template>
	
	<xsl:template match="xhtml:span | xhtml:b |xhtml:strong | xhtml:i | xhtml:em | xhtml:u | xhtml:sub | xhtml:sup" mode="InsideParagraph">
		<!-- xsl:if test="xhtml:br[contains(normalize-space(@style),'page-break-before:always')]">
			<xsl:processing-instruction name="pagination">layout-hint="pagebreak"</xsl:processing-instruction>
		</xsl:if -->
		<xsl:if test="(translate(@style, ' ', '') != 'mso-list:Ignore') and ((string-length(@class)=0) or (@class != 'MsoCommentReference'))">
			<xsl:choose>
				<xsl:when test="contains(translate(@class, $UpperAndSpace, $Lower), 'program')">
					<xsl:apply-templates select="." mode="Inline" />
				</xsl:when>
				<xsl:when test="local-name()='span'"><xsl:call-template name="DoSpanAttributes" /></xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="." mode="Inline" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<xsl:for-each select="following-sibling::*[(position()=1) and contains($InLineTags, concat(';', local-name(), ';'))]">
			<xsl:apply-templates select="." mode="InsideParagraph" />
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="xhtml:*" mode="InsideParagraph">
		<xsl:apply-templates select="." />
	</xsl:template>
	
	<xsl:template name="IsParagraph">
		<xsl:choose>
			<xsl:when test="count(preceding-sibling::*[1]) = 0">false</xsl:when>
			<xsl:when test="contains('p;h1;h2;h3;h4',local-name(preceding-sibling::*[1]))">
				<xsl:variable name="HasContent">
					<xsl:call-template name="HasContent" />
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$HasContent = 'true'">true</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="FollowingContent" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="HasContent">
		<xsl:choose>
			<xsl:when test="(translate(@style, ' ', '') != 'mso-list:Ignore') and ((string-length(@class)=0) or (@class != 'MsoCommentReference')) and (string-length(normalize-space()) &gt; 0)">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="FollowingContent">
		<xsl:param name="Item" select="1" />
		<xsl:variable name="NextSiblingName" select="concat(';', local-name(following-sibling::*[$Item]), ';')" />
		<xsl:choose>
			<xsl:when test="$Item &gt; 100">false</xsl:when> <!-- Prevent infinite loop -->
			<xsl:when test="local-name(following-sibling::*[$Item]) != 'span'">false</xsl:when>
			<xsl:when test="string-length(following-sibling::*[$Item]) = 0">
				<xsl:call-template name="FollowingContent">
					<xsl:with-param name="Item" select="$Item + 1" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="(translate(@style, ' ', '') = 'mso-list:Ignore') or ((string-length(@class) != 0) and (@class = 'MsoCommentReference'))">
				<xsl:call-template name="FollowingContent">
					<xsl:with-param name="Item" select="$Item + 1" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="following-sibling::*[$Item]">
					<xsl:variable name="HasContent">
						<xsl:call-template name="HasContent" />
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$HasContent = 'true'">true</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="FollowingContent">
							<xsl:with-param name="Item" select="$Item + 1" />
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Language templates -->
	
	<xsl:template match="/xhtml:html/xhtml:body" mode="GetLanguage">
		<xsl:call-template name="GetLanguage" />
	</xsl:template>
	
	<xsl:template name="GetLanguage">
		<xsl:choose>
			<xsl:when test="string-length(translate(@lang, ' ', '')) &gt; 0">
				<xsl:choose>
					<xsl:when test="translate(@lang,$UpperAndSpace, $Lower)='en-gb'">
						<xsl:text>en-GB</xsl:text>
					</xsl:when>
					<xsl:when test="translate(@lang,$UpperAndSpace, $Lower)='en-us'">
						<xsl:text>en-US</xsl:text>
					</xsl:when>
					<xsl:when test="contains(substring(@lang, 2), '-')">
						<xsl:value-of select="substring-before(translate(@lang, $UpperAndSpace, $Lower), '-')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="translate(@lang, $UpperAndSpace, $Lower)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>en-GB</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="HasLanguage">
		<xsl:variable name="Language">
			<xsl:call-template name="GetLanguage" />
		</xsl:variable>
		<xsl:value-of select="$Language != $DocumentLanguage" />
	</xsl:template>
	
	<!-- End of Language templates -->
	
	<!-- Process a Transcript document -->
	
	<xsl:template match="xhtml:html" mode="Transcript">
		<xsl:apply-templates select="xhtml:body" mode="Transcript" />
	</xsl:template>
	
	<xsl:template match="xhtml:body" mode="Transcript">
		<xsl:comment>Document pasted as a transcript dialogue document</xsl:comment>
		<xsl:apply-templates select="xhtml:p" mode="Transcript" />
	</xsl:template>
	
	<xsl:template match="xhtml:p" mode="Transcript">
		<xsl:variable name="Speaker">
			<xsl:call-template name="GetSpeaker" />
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="@class='Transcript'">
				<Paragraph>
					<xsl:apply-templates select="node()" />
				</Paragraph>
			</xsl:when>
			<xsl:when test="string-length($Speaker) &gt; 0">
				<Speaker>
					<xsl:value-of select="$Speaker"/>
				</Speaker>
				<Remark>
					<xsl:value-of select="substring-after(., concat($Speaker, ': '))"/>
				</Remark>
			</xsl:when>
			<xsl:otherwise>
				<Remark>
					<xsl:apply-templates select="node()" />
				</Remark>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="GetSpeaker">
		<xsl:choose>
			<xsl:when test="contains(., ': ')">
				<xsl:variable name="Start">
					<xsl:value-of select="substring-before(., ': ')"/>
				</xsl:variable>
				<xsl:if test="$Start=translate($Start,'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"><xsl:value-of select="$Start" /></xsl:if>
				</xsl:when>
			<xsl:otherwise />
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="text()">
		<xsl:call-template name="DoText"/>
	</xsl:template>
	
	<xsl:template match="text()" mode="Inline">
		<xsl:call-template name="DoText"/>
	</xsl:template>
	
	<xsl:template name="DoText">
		<!-- Handle extra spaces inserted by Word that aren't in the content -->
		<!-- Need to include spaces that are in the content! -->
		<xsl:if test="$Testing='true'">
			<xsl:text>[pbc DoText - start]</xsl:text>
			<!--xsl:text>[pbc DoText following='</xsl:text>
			<xsl:value-of select="name(following-sibling::*[1])"/>
			<xsl:text>', parent='</xsl:text>
			<xsl:value-of select="name(..)"/>
			<xsl:text>', position='</xsl:text>
			<xsl:value-of select="position()"/>
			<xsl:text>', last='</xsl:text>
			<xsl:value-of select="last()"/>
			<xsl:text>', number following='</xsl:text>
			<xsl:value-of select="count(following::node())"/>
			<xsl:text>', following={</xsl:text>
			<xsl:for-each select="following::node()">
				<xsl:text>(name='</xsl:text>
				<xsl:value-of select="name()"/>
				<xsl:text>', content='</xsl:text>
				<xsl:value-of select="."/>
				<xsl:text>')</xsl:text>
			</xsl:for-each>
			<xsl:text>}]</xsl:text>
			<xsl:text>[pbc preceding='</xsl:text>
			<xsl:value-of select="name(preceding::*[1])"/>
			<xsl:text>']</xsl:text -->
		</xsl:if>
		<xsl:variable name="Pre">
			<xsl:choose>
				<xsl:when test="position() != 1">
					<xsl:variable name="Previous">
						<xsl:value-of select="local-name(preceding-sibling::*[1])"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$Previous='span'">
							<xsl:variable name="HasSmallCaps" select="contains(preceding-sibling::*[1]/@style, 'small-caps')" />
							
							<xsl:variable name="HasLanguage">
								<xsl:for-each select="preceding-sibling::*[1]">
									<xsl:call-template name="HasLanguage" />
								</xsl:for-each>
							</xsl:variable>
							
							<xsl:variable name="HasProgramCode" select="contains(translate(preceding-sibling::*[1]/@class, $UpperAndSpace, $Lower), 'program')" />
							
							<!--xsl:variable name="HasFontx">
								<xsl:variable name="EditedStyle">
									<xsl:for-each select="preceding-sibling::*[1]">
										<xsl:call-template name="EditStyleFontFamily" />
									</xsl:for-each>
								</xsl:variable>
								<xsl:value-of select="contains(translate($EditedStyle, ' ',''),'font-family:')"/>
							</xsl:variable -->
							
							<xsl:variable name="NewFont">
								<xsl:variable name="TempNewFont">
									<xsl:variable name="EditedStyle">
										<xsl:for-each select="preceding-sibling::*[1]">
											<xsl:call-template name="EditStyleFontFamily" />
										</xsl:for-each>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="contains(translate($EditedStyle, ' ',''),'font-family:&quot;')"><xsl:value-of select="substring-before(substring-after(substring-after($EditedStyle, 'font-family:'), '&quot;'), '&quot;')"/>
										</xsl:when>
										<xsl:when test="contains(substring-after($EditedStyle, 'font-family:'),';')"><xsl:value-of select="substring-before(substring-after(translate($EditedStyle,' ', ''), 'font-family:'), ';')"/></xsl:when>
										<xsl:otherwise><xsl:value-of select="substring-after(translate($EditedStyle, ' ', ''), 'font-family:')"/></xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:choose>
									<xsl:when test="count(*[contains(translate(@style, ' ', ''), 'mso-list:Ignore')]) &gt; 0" />
									<xsl:when test="$TempNewFont=$NormalFont"/>
									<xsl:otherwise><xsl:value-of select="$TempNewFont"/></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<xsl:variable name="HasFont" select="string-length($NewFont) &gt; 0" />
							
							<xsl:choose>
								<xsl:when test="$HasLanguage='true'">xml:lang</xsl:when>
								<xsl:when test="contains(preceding-sibling::*[1]/xhtml:span/@style, 'mso-ansi-language')">xml:lang</xsl:when>
								<xsl:when test="$HasFont='true'">font</xsl:when>
								<xsl:when test="$HasSmallCaps='true'">smallCaps</xsl:when>
								<xsl:otherwise><xsl:value-of select="$Previous"/></xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise><xsl:value-of select="$Previous"/></xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="local-name(..) = 'span'"><xsl:value-of select="local-name(../preceding-sibling::*[1])"/></xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length(normalize-space()) &gt; 0">
				<xsl:if test="$Testing='true'">
					<xsl:text>[pbc DoText when 1]</xsl:text>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="(local-name(preceding-sibling::xhtml:*[1])='br') and starts-with(., ' ')">
				<xsl:if test="$Testing='true'">
					<xsl:text>[pbc DoText when 2]</xsl:text>
				</xsl:if>
						<xsl:value-of select="substring(.,2)" />
					</xsl:when>
					<xsl:otherwise>
				<xsl:if test="$Testing='true'">
					<xsl:text>[pbc DoText when 3]</xsl:text>
				</xsl:if>
					<xsl:value-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="((local-name(..)='p') and (not(contains(../@style, 'mso-list'))) and (local-name(preceding::*[1]) != 'style') and (count(following::*) &gt; 3)) or (count(../@lang) &gt; 0)">
				<xsl:if test="$Testing='true'">
					<xsl:text>[pbc DoText when 4]</xsl:text>
				</xsl:if>
				<xsl:value-of select="."/>
			</xsl:when>
			<!-- xsl:when test="($Pre = 'b') or ($Pre = 'i') or ($Pre = 'u') or ($Pre = 'sup') or ($Pre = 'sub') or ($Pre = 'smallCaps') or ($Pre = 'font')" -->
			<xsl:when test="(($Pre = 'smallCaps') or ($Pre = 'font')) and (count(following::*) &gt; 3)">
				<xsl:if test="$Testing='true'">
					<xsl:text>[pbc DoText when 5]</xsl:text>
				</xsl:if>
				<xsl:value-of select="."/>
			</xsl:when>
			<!-- xsl:when test="contains('span;sub;sup;p;b;u;i;', local-name(..)) and (local-name(following-sibling::*[1]) = 'a') and not(contains(preceding-sibling::*[1]/@style, 'mso-spacerun'))">
				<xsl:value-of select="."/>
			</xsl:when -->
			<xsl:when test="(local-name(following-sibling::*[1]) = 'a') and not(contains(preceding-sibling::*[1]/@style, 'mso-spacerun')) and (count(following::*) &gt; 3)">
				<!-- The last non-blank node is the "EndFragment" comment -->
				<xsl:if test="$Testing='true'">
					<xsl:text>[pbc DoText when 6]</xsl:text>
				</xsl:if>
				<xsl:value-of select="."/>
			</xsl:when>
			<!-- xsl:when test="local-name(following-sibling::*[1]) = 'a'">
				<xsl:value-of select="."/>
				</xsl:when -->
			<xsl:otherwise>
		<xsl:if test="$Testing='true'">
			<xsl:text>[pbc DoText otherwise 7]</xsl:text>
		</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="$Testing='true'">
			<xsl:text>[pbc DoText end]</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- Templates used for testing -->
	<!-- Dump out a tree of the input content to the message area-->
		
	<xsl:template name="ShowInput">
		<xsl:message>
			<xsl:text>The following is a tree of the input content:</xsl:text>
			<xsl:apply-templates mode="ShowInput" />
		</xsl:message>
	</xsl:template>

	<xsl:template match="*" mode="ShowInput">
		<xsl:if test="name() != local-name()">
			<span>[<xsl:value-of select="name()"/>][<xsl:value-of select="namespace-uri()"/>]</span>
		</xsl:if>
		<xsl:element name="{local-name()}">
			<xsl:for-each select="@*">
				<xsl:attribute name="{name()}">
					<xsl:value-of select="."/>
				</xsl:attribute>
			</xsl:for-each>
			<xsl:apply-templates mode="ShowInput" />
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="text ()" mode="ShowInput">
		<xsl:value-of select="." />
	</xsl:template>

	<xsl:template match="processing-instruction ()" mode="ShowInput">
		<xsl:processing-instruction name="{local-name()}"><xsl:value-of select="." /></xsl:processing-instruction>
		<xsl:value-of select="." />
	</xsl:template>
	
	<xsl:template match="comment ()" mode="ShowInput">
		<xsl:comment><xsl:value-of select="." /></xsl:comment>
		<xsl:value-of select="." />
	</xsl:template>

<!-- dev -->
	<xsl:template match="m:annotation[@encoding='MathType-MTEF']"/>    
	
	<xsl:template match="m:math">
		<xsl:choose>
			<xsl:when test="parent::xhtml:p[@class='EQpEquation']">
				<Equation>
					<MathML>
						<math xmlns="http://www.w3.org/1998/Math/MathML" display="block" scriptlevel="0" displaystyle="true">
							<xsl:apply-templates/>
						</math>
					</MathML>
				</Equation>
			</xsl:when>
			<xsl:otherwise>
				<InlineEquation>
					<MathML>
						<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline" scriptlevel="0" displaystyle="false">
							<xsl:apply-templates/>
						</math>
					</MathML>
				</InlineEquation>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="m:*">		
		<xsl:element name="{local-name()}" namespace="http://www.w3.org/1998/Math/MathML">
			<xsl:apply-templates select="@*|node()"/>			
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="@*">		
		<xsl:attribute name="{local-name()}">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

</xsl:stylesheet>
