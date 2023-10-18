<?xml version="1.0" encoding="iso-8859-1"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" schemaVersion="ISO19757-3">
    <ns uri="http://www.w3.org/1998/Math/MathML" prefix="mml"/>
    <title>Validate your SC document against VLE requirements.</title>
    <pattern id="item">
        <rule context="/Item">
            <report test="(number(@SchemaVersion) &gt;= 1.2) and (normalize-space(@id)='' or contains(@id, ' ') or
                (not(starts-with(@id, 'X')) and not(starts-with(@id, 'OC_')) and
                (not(starts-with(@id,'not') and (string-length(@id)=14 or string-length(@id)=17) and number(substring(@id, 5, string-length(@id))))) and
                (not(starts-with(@id,'SUP') or starts-with(@id,'WEB') and string-length(@id)=9 and number(substring(@id, 4, string-length(@id)))))))">
                Must contain an id= attribute. The ID should be an Item code prefixed with a capital 'X' (e.g. X_ITM1234567) if available;
                otherwise, you can use any string of characters as long as it begins with a capital X and does not contain any spaces or
                presentation-specific information (i.e. it should not include the presentation year or an ISBN/SUP code/WEB code).
                IDs should be unique within a website and should never need to be updated.
            </report>
            <report test="normalize-space(CourseCode) = ''">
                &lt;CourseCode&gt;: Enter an OU module code or
                (if this document is not for a module) the VLE 'short name' of the site
                you are saving the document to.
            </report>
            <report test="normalize-space(ItemTitle) = ''">
                &lt;ItemTitle&gt; tag: Enter the title of the item. The title will be used to create the link to this document
                when it is saved to a module page.
            </report>
			 <report test="@Rendering='PDF via Asura'">
                'PDF via Asura' is no longer a valid rendering option, please choose a valid value from the selection in the Item tag's 'Rendering' attribute drop-down.
            </report>
        </rule>
    </pattern>

    <pattern id="session">
        <rule context="Session/Title">
            <report test="(preceding::Session[ancestor::Unit] or
                following::Session[ancestor::Unit]) and normalize-space(.)=''">
                &lt;Session&gt;: &lt;Title&gt;must not be blank. If you have more than one Session,
                each must have a Title.
            </report>
        </rule>
    </pattern>

    <pattern id="activity">
        <rule context="Activity|Exercise|SAQ|ITQ">
            <report test="ancestor::Exercise|ancestor::SAQ|
                ancestor::ITQ|ancestor::Activity|ancestor::Part">
                &lt;Activity&gt;, &lt;SAQ&gt;, &lt;ITQ&gt;, &lt;Exercise&gt;: cannot be nested inside
                &lt;<value-of select="name(ancestor::Exercise|ancestor::SAQ|
                    ancestor::ITQ|ancestor::Activity|ancestor::Part)"/>&gt;
            </report>
            <report test="self::ITQ and
                (descendant::Discussion or descendant::Multipart/Part/Discussion)">
                Discussion tag is not supported within the ITQ tag.
            </report>     
        </rule>
    </pattern>
    
    <pattern id="Interaction">
        <rule context="Interaction">
          <report test="count(child::Matching) > 1">
              Interaction tag cannot have more than one Matching tag.
          </report>
        </rule>
    </pattern>

	<pattern id="internalsection">
        <rule context="InternalSection">
            <report test="ancestor::Exercise|ancestor::SAQ|
                ancestor::ITQ|ancestor::Activity">
                Warning: Use of InternalSection within an Activity, ITQ, SAQ and Exercise  is not advised
                nor supported in the design; you are strongly advised to use alternative tagging.
            </report>
        </rule>
    </pattern>


    <pattern id="interaction">
        <rule context="Interaction">
            <report test="VoiceRecorder">
                Warning: The SC Voice Recorder is no longer available to use in new documents as it is has been
                replaced by the Record audio quiz question.It will continue to be supported for existing documents until September 2022.
            </report>
        </rule>
    </pattern>

    <pattern id="voicerecorder">
        <rule context="VoiceRecorder/Listen|VoiceRecorder/Model|VoiceRecorder/Record">
            <report test="normalize-space(@src) = ''">
                &lt;VoiceRecorder&gt;, &lt;<value-of select="name(.)"/>&gt;: The 'src' attribute does not have
                    an audio file specified. If you do not wish to have an audio file
                    for this function, delete the &lt;<value-of select="name(.)"/>&gt;tag entirely.
            </report>
            <report test="normalize-space(@src) != '' and not(contains(@src,'.mp3') and
                (substring-after(normalize-space(@src),'.mp3')=''))">
                &lt;VoiceRecorder&gt;, &lt;<value-of select="name(.)"/>&gt;: The audio file in the src attribute('<value-of select="normalize-space(@src)"/>')
                must have an extension of .mp3.
            </report>
        </rule>
    </pattern>
    <pattern id="FrontMatter">
        <rule context="FrontMatter/Covers/Cover">
            <report test="normalize-space(@src) = ''">
                &lt;Cover&gt;, &lt;<value-of select="name(.)"/>&gt;: The 'src' attribute does not have
                an image file specified. If you do not wish to have an cover image
                for this function, delete the &lt;<value-of select="name(.)"/>&gt;tag entirely.
            </report>
        </rule>
    </pattern>

    <pattern id="freeresponse">
        <rule context="FreeResponse">
            <let name="ID" value="@id"/>
            <!-- Unique id should be restrctied in the OU schema
                as how it has done for the id of the voicerecorder -->
            <report test="preceding::FreeResponse[@id = $ID] or following::FreeResponse[@id = $ID]">
                &lt;FreeResponse&gt;: Value of 'id' attribute must be unique.
                '<value-of select="@id"/>' is used more than once.
            </report>
            <report test="normalize-space(@id) = ''">
                &lt;FreeResponse&gt;: 'id' attribute cannot be empty or blank.
            </report>
            <report test="count(../FreeResponse) >  1">
                &lt;FreeResponse&gt;: Use of more than one FreeResponse within one &lt;Question&gt; is not supported on the VLE; please use alternative tagging.
            </report>
        </rule>
    </pattern>

    <pattern id="speaker">
        <rule context="Speaker">
            <!-- However an empty Remark tag followed the Speak tag is allowed. -->
            <report test="not(following-sibling::*[position()=1 and local-name()='Remark'])">
                &lt;Speaker&gt;: Must be paired with &lt;Remark&gt;. &lt;Remark&gt; can stand alone.
            </report>
        </rule>
    </pattern>

    <pattern id="sidenote">
        <rule context="SideNote">
            <report test="ancestor::Table">
                &lt;SideNote&gt;: Not supported in tables.
            </report>
            <report test="ancestor::Caption">
                &lt;SideNote&gt;: Not supported in captions.
            </report>
        </rule>
    </pattern>

    <pattern id="table">
        <rule context="Table">
            <report test="not(parent::MultiColumnBody) and
                count(descendant::td) = 0 and count(descendant::th) = 0">
                &lt;Tables&gt;: Must contain ay least one &lt;th&gt; or &lt;tr&gt;.
            </report>
            <report test="descendant::tr[count(*) = 0]">
                Error:  &lt;Table&gt;: contains &lt;tr/&gt; (a null tag), which needs to be removed. It can only be seen and deleted in 'Text' mode.
            </report>
        </rule>
    </pattern>

    <pattern id="multicolumntext">
        <rule context="MultiColumnText//Table">
            <report test="descendant::*[@rowspan or @colspan]">
                &lt;MultiColumnText&gt;, Table: may not include merged cells
                (i.e. 'Colspan' or 'Rowspan' not blank)
            </report>
            <report test="(descendant::tbody/tr[1]/*[local-name() != 'th' or
                    (@class and @class != 'ColumnHeadLeft') or (normalize-space(.)='')]) or
                    descendant::tr[1][count(th) &lt; 2]">
                &lt;MultiColumnText&gt;, Table: 1st row must contain at least 2 cells tagged &lt;th&gt; with
                'class' = ColumnHeadLeft and with text content. Set &lt;MultiColumnText&gt; 'headingrow' attribute
                to 'hide' for headings to be visible only in the VLE render and then only to screenreaders.
            </report>
            <report test="descendant::td[@class and @class!='TableLeft']">
                &lt;MultiColumnText&gt;, Table: only 'tableleft' is supported in the 'class' attribute.
            </report>
            <report test="descendant::th[parent::tr/preceding-sibling::tr]">
                &lt;MultiColumnText&gt;, Table: &lt;th&gt; is only supported in the first rwo.
            </report>
            <report test="descendant::tr[1][count(th) > 4]">
                &lt;MultiColumnText&gt;, Table: must contain a maximum of 4 columns.
            </report>
        </rule>
    </pattern>

    <pattern id="total">
        <rule context="Total">
            <report test="normalize-space(.) = ''">
                &lt;Total&gt;: must have content.
            </report>
            <report test="not(parent::td and ancestor::Table)">
                &lt;Total&gt;: only valid within &lt;td&gt;.
            </report>
            <report test="preceding-sibling::* or following-sibling::* or
                preceding-sibling::text()[normalize-space(.)!=''] or
                following-sibling::text()[normalize-space(.)!='']">
                &lt;Total&gt;: all contents of the table cell must be within &lt;total&gt;.
            </report>
        </rule>
    </pattern>

    <pattern id="olink">
        <rule context="olink">
            <report test="descendant::a">
                &lt;olink&gt;: &lt;a&gt; not allowed, insert only the text to be displayed
                as the link. Use 'targetdoc' and 'targetptr' attributes for the link location and position within it.
            </report>
            <report test="ancestor::Heading or ancestor::Title">
                &lt;olink&gt;: &lt;a&gt; not allowed inside
                &lt;<value-of select="name(ancestor::Title|ancestor::Heading)"/>&gt;.
            </report>
        </rule>
    </pattern>

    <pattern id="CrossRef">
        <rule context="CrossRef">
            <report test="ancestor::Heading or ancestor::Title">
                &lt;CrossRef&gt;: &lt;a&gt; not allowed inside
                &lt;<value-of select="name(ancestor::Title|ancestor::Heading)"/>&gt;.
            </report>
        </rule>
    </pattern>

    <pattern id="footnote">
        <rule context="footnote">
            <report test="ancestor::Title or ancestor::Transcript or ancestor::Description or
                    ancestor::Alternative or ancestor::Caption">
                &lt;footnote&gt;: not allowed inside &lt;
                <value-of select="name(ancestor::Title|ancestor::Transcript|ancestor::Description|ancestor::Alternative|ancestor::Caption)"/>&gt;.
            </report>
        </rule>
    </pattern>

    <pattern id="glossary">
        <rule context="Glossary">
            <report test="normalize-space(/Item/@vleglossary) = 'manual'">
                &lt;Glossary&gt;: invalid when 'vleglossary' attribute of &lt;item&gt; set to 'manual'.
            </report>
        </rule>
    </pattern>

    <pattern id="sym">
        <rule context="sym">
            <report test=".">
                &lt;sym&gt;: Non-standard characters are not supported in the online render, replace with standard Unicode characters, or with images.
            </report>
        </rule>
    </pattern>

    <pattern id="font">
        <rule context="font">
            <report test="@val='Wingdings' or @val='Webdings' or
                @val='Wingdings 2' or @val='Wingdings 3'">
                &lt;font&gt;: symbol fonts (in this case <value-of select="@val"/>) not supported
                in the online render; replace with standard Unicode characters or images.
            </report>
        </rule>
    </pattern>

    <pattern id="image">
        <rule context="Image">
            <report test="normalize-space(@src)='' and not(parent::Equation or parent::InlineEquation)">
                &lt;Image&gt;: 'src' attribute not specified.
            </report>
        </rule>
    </pattern>

	<pattern id="ecm">
        <rule context="*[@src]">
            <report test="contains(@src, '\\DCTM_FSS\')">
                &lt;<value-of select="name(.)"/>&gt;: Use of ECM Documentum links are no longer supported.
            </report>
        </rule>
    </pattern>

	<pattern id="portal">
        <rule context="*[@src]">
            <report test="contains(@src, 'sharepoint.com') and contains(@src, 'portals') and contains(@src, 'pvid')">
                &lt;<value-of select="name(.)"/>&gt;: Use of SharePoint Portal links are no longer supported, please link to the asset in the main SharePoint site instead.
            </report>
        </rule>
    </pattern>

    <pattern id="inline">
        <rule context="InlineEquation|InlineChemistry|InlineFigure|Paragraph/Equation|
                LearningOutcome/Equation|Reference/Equation|Term/Equation|
                Definition/Equation|Remark/Equation|Speaker/Equation|
                KeyPoint/Equation|SourceReference/Equation|Caption/Equation|Description/Equation">
            <report test="Image/@webthumbnail='true'">
                Thumbnails are not supported for inline images. If you need
                thumbnails, please use a standalone Figure tag instead.
            </report>
            <report test="Description">
                Inline figures may not have long descriptions. Inline figures are intended
                for use only for small images, such as icons, that relate directly to
                associated text on the same line. The Alternative tag (providing a short
                one-sentence alternative) should be sufficient in this situation.
            </report>
        </rule>
    </pattern>

    <pattern id="mediacontent">
        <rule context="MediaContent">
            <!-- OU schema has restricted the type options here such as flash, video etc
                but allowing the type attribute to be to ommit. -->
            <report test="normalize-space(@type) = ''">
                &lt;MediaContent&gt;: 'type' attribute must be set.
            </report>
            <report test="normalize-space(@src) = ''">
                &lt;MediaContent&gt;: 'src' attribute must be set.
            </report>
            <report test="@type='java' and not(contains(@src,'.jar'))">
                &lt;MediaContent&gt;: <value-of select="@src"/> does not appear to be a Java file;
                name does not end in '.jar'.
            </report>
            <report test="@type='audio' and not(contains(@src,'.mp3') or contains(@src,'.m4a')
                or contains(@src,'https://mediaspace') or contains(@src, '_manifest.xml'))">
                &lt;MediaContent&gt;: file type .<value-of select="substring-after(@src, '.')"/> is not supported,
                .mp3 or .m4a or _manifest.xml or Kaltura MediaSpace link required.
            </report>
            <report test="@type='video' and not(contains(@src,'.flv') or contains(@src,'.mp4') or contains(@src,'.m4v')
                or contains(@src,'https://mediaspace') or contains(@src, '_manifest.xml'))">
                &lt;MediaContent&gt;: file type .<value-of select="substring-after(@src, '.')"/> is not supported,
                .flv, .mp4 or .m4v or _manifest.xml or Kaltura MediaSpace link required.
            </report>
            <report test="@type='flash' and not(contains(@src,'.swf'))">
                &lt;MediaContent&gt;: file type .<value-of select="substring-after(@src, '.')"/> is not supported,
                .swf required.
            </report>
            <report test="@type='moodlequestion' and not(contains(@src,'/'))">
                &lt;MediaContent&gt;: 'src' attribute must contain the string
               [question category idnumber]/[question idnumber].
            </report>
            <report test="@type='html5' and
                (normalize-space(@width)='' or normalize-space(@height)='')">
                &lt;MediaContent&gt;, HTML5: 'width' and 'height' attributes required.
            </report>
            <report test="@type='html5' and not(contains(@src,'.zip'))">
                &lt;MediaContent&gt;: file type .<value-of select="substring-after(@src, '.')"/> is not supported,
                .zip required.
            </report>
            <report test="(@type='file' or @type='moodlequestion') and (normalize-space(@width)!=''
                or normalize-space(@height)!='')">
                &lt;MediaContent&gt;, <value-of select="name(@type)"/>: 'width' and 'height' attributes must be blank.
            </report>
            <report test="@type='file' and
                (descendant::SourceReference or descendant::Description or
                descendant::Transcript or descendant::Parameters or descendant::Attachments or
                descendant::Figure)">
                &lt;MediaContent&gt;, file: only 'Caption' sub-tag is allowed.
            </report>
            <report test="@width &gt; 600 and @type='openmark'">
                &lt;MediaContent&gt;, 'OpenMark': width 600 pixels maximum.
            </report>
            <report test="normalize-space(@height)='' and @type='openmark'">
                &lt;MediaContent&gt;, 'OpenMark': 'height' must be set.
            </report>
            <report test="@width &gt; 880 and @webthumbnail='true'">
                &lt;MediaContent&gt;: specified width &gt;880 pixels maximum.
            </report>
            <report test="@webthumbnail='true' and
                not(@type='flash' or @type='java' or @type='html5' or @type='video')">
                &lt;MediaContent&gt;: 'webthumbnail' only valid if 'type' is flash, java, html5 or video. 
            </report>
            <report test="not(@type='flash' or @type='java' or @type='html5')
                and Attachments">
                &lt;MediaContent&gt;: 'Attachments' sub-tag only valid if 'type' is flash, html5 or java.
            </report>
            <report test="not(@type='flash' or @type='java' or @type='html5' or @type='moodlequestion')
                and Parameters">
                &lt;MediaContent&gt;: 'Parameters' sub-tag only valid if 'type' is flash, html5, java or moodlequestion.
            </report>
            <report test="Parameters/Parameter[normalize-space(@name)='']">
                &lt;MediaContent&gt;, &lt;Parameters&gt;: 'name' attribute must be set.
            </report>
            <report test="Attachments/Attachment[normalize-space(@src)='']">
                &lt;MediaContent&gt;, &lt;Attachments&gt;: 'src' attribute must be set.
            </report>
            <report test="@type='html5' and string-length(@id) &gt; 20">
                &lt;MediaContent&gt;, html5: 'id' attribute value must be &lt;=20 characters.
            </report>
            <report test="@type='video' and Figure/Image/@webthumbnail='true'">
                &lt;MediaContent&gt;, video: 'webthumbnail' not supported.
            </report>
            
        </rule>
        <rule context="MediaContent/@width">
            <report test="parent::MediaContent[@type='html5'] and normalize-space(.) != '*'" role="info">
                &lt;MediaContent&gt;, html5: Consider making this activity support a responsive design so it will display correctly on mobile devices.
            </report>
        </rule>
    </pattern>

    <pattern id="icon">
        <rule context="Icon">
            <report test="ancestor::Table|ancestor::Caption|ancestor::Heading">
                Icon is not supported in tables.
            </report>
            <report test="(normalize-space(@resource1) = '' or normalize-space(@resource1) = 'none')">
                &lt;Icon&gt;: not supported in <value-of select="name(ancestor::Table|ancestor::Caption|ancestor::Heading)"/>.
            </report>
        </rule>
    </pattern>

    <pattern id="resourceicons">
        <rule context="*[(normalize-space(@resource1) != '' and normalize-space(@resource1) != 'none') or
            (normalize-space(@resource2) != '' and normalize-space(@resource2) != 'none') or
            (normalize-space(@resource3) != '' and normalize-space(@resource3) != 'none') or
            (normalize-space(@resource4) != '' and normalize-space(@resource4) != 'none')]">
            <report test="self::MediaContent[@width > 342]">
                &lt;MediaContent&gt;: 'resource1/2/3' attributes invalid if 'width' &gt; 342.
            </report>
            <report test="(normalize-space(@resource1) = '' or normalize-space(@resource1) = 'none') and
                (normalize-space(@resource2) != '' and normalize-space(@resource2) != 'none')">
                &lt;MediaContent&gt;, 'resource2': use 'resource1' first.
            </report>
            <report test="(normalize-space(@resource2) = '' or normalize-space(@resource2) = 'none') and
                (normalize-space(@resource3) != '' and normalize-space(@resource3) != 'none')">
                &lt;MediaContent&gt;, 'resource3': use 'resource2' before.
            </report>
        </rule>
    </pattern>

    <pattern id="glossaryterm">
        <rule context="GlossaryTerm">
            <report test="ancestor::GlossaryTerm">
                &lt;GlossaryTerm&gt; cannot be nested within &lt;GlossaryTerm&gt;.
            </report>
        </rule>
    </pattern>

    <pattern id="freeresponsedisplay">
        <rule context="FreeResponseDisplay">
            <report test="@targetdoc and (not(@targetidref) or @idref) or
                (not(@targetdoc) and (not(@idref) or @targetidref))">
                &lt;FreeResponseDisplay&gt;: either 'idref' attribute, or
                'targetdoc' and 'targetidref' attributes must be set. Other combinations are not valid.
            </report>
        </rule>
    </pattern>

    <pattern id="contentaftersections">
        <rule context="Session/*">
            <report test="self::*[
                (preceding-sibling::Section or preceding-sibling::Introduction or
                preceding-sibling::LearningOutcomes)
                and not(self::Section or self::LearningOutcomes or self::Summary or
                self::References or self::FurtherReading)]">
                &lt;<value-of select="name(.)"/>&gt;: &lt;Section&gt;&lt;Introduction&gt;&lt;LearningOutcomes&gt; can only be followed by 
                &lt;Section&gt;, &lt;LearningOutcomes&gt;, &lt;Summary&gt;, &lt;References&gt; or &lt;FurtherReading&gt;.
            </report>
        </rule>
        <rule context="Section/*">
            <report test="self::*[preceding-sibling::SubSection and not(self::SubSection or
                self::Summary or self::References or self::FurtherReading)]">
                &lt;<value-of select="name(.)"/>&gt;: &lt;SubSection&gt; can only be followed by 
                &lt;SubSection&gt;, &lt;Summary&gt;, &lt;References&gt; or &lt;FurtherReading&gt;.
            </report>
        </rule>
        <rule context="SubSection/*">
            <report test="self::*[preceding-sibling::SubSubSection and not(self::SubSubSection or
                self::Summary or self::References or self::FurtherReading)]">
                &lt;<value-of select="name(.)"/>&gt;: &lt;SubSubSection&gt; can only be followed by 
                &lt;SubSubSection&gt;, &lt;Summary&gt;, &lt;References&gt; or &lt;FurtherReading&gt;.
            </report>
        </rule>
    </pattern>
    
    <pattern id="common_computer_code_computer_ui_nesting">
        <rule context="ComputerUI|ComputerCode">
            <report test="ancestor::ComputerUI|ancestor::ComputerCode">
                &lt;<value-of select="name(.)"/>&gt;: cannot be nested within <value-of select="name(ancestor::ComputerUI|ancestor::ComputerCode)"/>.
            </report>
        </rule>
    </pattern>
    
    <pattern id="list_item">
        <rule context="ListItem | SubListItem">
            <assert test="not(normalize-space(text()) and child::*[self::SideNote|self::Paragraph|self::Equation|self::ChemistryStructure|self::Figure
                |self::ComputerDisplay
                |self::ProgramListing
                ])" role="warning">
                Please ensure that ListItems and SubListItems do not have a mixture of tagged and untagged content.
            </assert>
        </rule>
    </pattern>
    
    <pattern id="mathml_font">
        <rule context="mml:*">
            <report test="@fontfamily">
                &lt;MathMl&gt;, &lt;<value-of select="name(.)"/>&gt;: The fontfamily attribute should not be set. Switch to Text mode to delete it.
            </report>
        </rule>
    </pattern>
    
    <pattern id="nesting">
        <rule context="Activity[ancestor::Activity] | ITQ[ancestor::Activity]| Exercise[ancestor::Activity] | SAQ[ancestor::Activity] | Box[ancestor::Activity] | StudyNote[ancestor::Activity]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;Activity&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::Exercise] | ITQ[ancestor::Exercise]| Exercise[ancestor::Exercise] | SAQ[ancestor::Exercise] | Box[ancestor::Exercise] | StudyNote[ancestor::Exercise]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;Exercise&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::ITQ] | ITQ[ancestor::ITQ]| Exercise[ancestor::ITQ] | SAQ[ancestor::ITQ] | Box[ancestor::ITQ] | StudyNote[ancestor::ITQ] | CaseStudy[ancestor::ITQ] | Example[ancestor::ITQ] | Extract[ancestor::ITQ] | Proof[ancestor::ITQ] | Reading[ancestor::ITQ]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;ITQ&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::SAQ] | ITQ[ancestor::SAQ]| Exercise[ancestor::SAQ] | SAQ[ancestor::SAQ] | Box[ancestor::SAQ] | StudyNote[ancestor::SAQ] | CaseStudy[ancestor::SAQ] | Example[ancestor::SAQ] | Extract[ancestor::SAQ] | Proof[ancestor::SAQ] | Reading[ancestor::SAQ]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;SAQ&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::Box] | ITQ[ancestor::Box]| Exercise[ancestor::Box] | SAQ[ancestor::Box] | Box[ancestor::Box] | StudyNote[ancestor::Box] | CaseStudy[ancestor::Box] | Example[ancestor::Box] | Extract[ancestor::Box] | Reading[ancestor::Box]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;Box&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::CaseStudy] | ITQ[ancestor::CaseStudy]| Exercise[ancestor::CaseStudy] | SAQ[ancestor::CaseStudy] | Box[ancestor::CaseStudy] | StudyNote[ancestor::CaseStudy] | CaseStudy[ancestor::CaseStudy] | Example[ancestor::CaseStudy] | Extract[ancestor::CaseStudy] | Reading[ancestor::CaseStudy]">
            <report test="*" role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;CaseStudy&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::Example] | ITQ[ancestor::Example]| Exercise[ancestor::Example] | SAQ[ancestor::Example] | Box[ancestor::Example] | StudyNote[ancestor::Example] | CaseStudy[ancestor::Example] | Example[ancestor::Example] | Extract[ancestor::Example] | Reading[ancestor::Example]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;Example&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::Extract] | ITQ[ancestor::Extract]| Exercise[ancestor::Extract] | SAQ[ancestor::Extract] | Box[ancestor::Extract] | StudyNote[ancestor::Extract] | CaseStudy[ancestor::Extract] | Example[ancestor::Extract] | Extract[ancestor::Extract] | Reading[ancestor::Extract]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;Extract&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::Proof] | ITQ[ancestor::Proof]| Exercise[ancestor::Proof] | SAQ[ancestor::Proof] | Box[ancestor::Proof] | StudyNote[ancestor::Proof] | CaseStudy[ancestor::Proof] | Example[ancestor::Proof] | Extract[ancestor::Proof] | Reading[ancestor::Proof] | Proof[ancestor::Proof]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;Proof&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::Reading] | ITQ[ancestor::Reading]| Exercise[ancestor::Reading] | SAQ[ancestor::Reading] | Box[ancestor::Reading] | StudyNote[ancestor::Reading] | CaseStudy[ancestor::Reading] | Example[ancestor::Reading] | Extract[ancestor::Reading] | Reading[ancestor::Reading]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;Reading&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
        <rule context="Activity[ancestor::StudyNote] | ITQ[ancestor::StudyNote]| Exercise[ancestor::StudyNote] | SAQ[ancestor::StudyNote] | Box[ancestor::StudyNote] | StudyNote[ancestor::StudyNote] | CaseStudy[ancestor::StudyNote] | Example[ancestor::StudyNote] | Extract[ancestor::StudyNote] | Reading[ancestor::StudyNote]">
            <report test="." role="warn">
                &lt;<value-of select="name(.)"/>&gt;, inside &lt;StudyNote&gt;:
                This combination of tags is not considered best practice and, although allowed, is not supported
                (in either the design or functional maintenance) and will lead to undesirable results.
            </report>
        </rule>
    </pattern>

	<pattern id="copyright">
        <rule context="Copyright/Paragraph">
            <report test="normalize-space(parent::Copyright) = ''" role="warn">
                You have not included any content in &lt;Copyright&gt;, if none is included the standard text will be automatically added to the VLE page display.
            </report>
			<report test="not(parent::Copyright//*[text()[contains(., 'Unless otherwise stated, copyright') and contains(., 'The Open University, all rights reserved.')]])" role="warn">
                The text in &lt;Copyright&gt; is non-standard. If it is not what you intend to use please correct it. This text will appear on the VLE web pages.
            </report>
        </rule>
    </pattern>
    
    <pattern id="link_names">
        <rule context="@href">
            <assert test="starts-with(normalize-space(.),'http://') or starts-with(normalize-space(.),'https://') or starts-with(normalize-space(.),'ftp://') or starts-with(normalize-space(.),'telnet://') or starts-with(normalize-space(.),'gopher://') or starts-with(normalize-space(.),'mailto:') or starts-with(normalize-space(.),'file:')">
                Error: '<value-of select="."/>' is an invalid href. It does not start with a recognised scheme i.e. https://.</assert>
        </rule>
    </pattern>
</schema>
