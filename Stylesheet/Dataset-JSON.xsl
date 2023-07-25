<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
	xmlns:odm="http://www.cdisc.org/ns/odm/v1.3" 
	xmlns:def="http://www.cdisc.org/ns/def/v2.x" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>

<!-- Root of the metadata -->
<xsl:variable name="root" select="/odm:ODM"/> 
	
<!-- Variables -->
<xsl:variable name="lf" select="'&#xA;'"/> 

<!-- Parameters -->
<xsl:param name="dsName"/>
<xsl:param name="creationDateTime"/>
<xsl:param name="nbRows"/>
	
<xsl:template match="/"> 
	<xsl:variable name="fileOID" select="normalize-space($root/@FileOID)"/> 
	<xsl:variable name="studyOID" select="normalize-space($root/odm:Study/@OID)"/> 
	<xsl:variable name="metaDataVersionOID" select="normalize-space($root/odm:Study/odm:MetaDataVersion/@OID)"/> 
	<xsl:variable name="originator" select="normalize-space($root/@Originator)"/> 
	<xsl:text>{</xsl:text>
	<xsl:text>&quot;creationDateTime&quot;: &quot;</xsl:text> <xsl:value-of select="$creationDateTime"/> <xsl:text>&quot;, </xsl:text>
	<xsl:text>&quot;datasetJSONVersion&quot;: &quot;1.0.0&quot;, </xsl:text> 
	<xsl:if test="$fileOID">
		<xsl:text>&quot;fileOID&quot;: &quot;</xsl:text> 
		<xsl:value-of select="$fileOID"/> 
		<xsl:text>.</xsl:text> <xsl:value-of select="$dsName"/> <xsl:text>&quot;, </xsl:text>
	</xsl:if>
	<xsl:if test="$originator">
		<xsl:text>&quot;originator&quot;: &quot;</xsl:text> 
		<xsl:value-of select="$originator"/>
		<xsl:text>&quot;, </xsl:text> 
	</xsl:if>
    <xsl:for-each select="$root/odm:Study/odm:MetaDataVersion/odm:ItemGroupDef[upper-case(@Name)=upper-case($dsName)]">
        <xsl:variable name="OID" select="@OID"/>
        <xsl:variable name="Name" select="@Name"/>
        <xsl:variable name="Data" select="if (@IsReferenceData = 'No') then 'clinicalData' else if (@IsReferenceData = 'Yes') then 'referenceData' else ' '"/>
        <xsl:variable name="Label" select="odm:Description/odm:TranslatedText"/>
		<xsl:text>&quot;</xsl:text> <xsl:value-of select="$Data"/> <xsl:text>&quot;: {</xsl:text> 
		<xsl:text>&quot;studyOID&quot;: &quot;</xsl:text> <xsl:value-of select="$studyOID"/> <xsl:text>&quot;, </xsl:text> 
		<xsl:text>&quot;metaDataVersionOID&quot;: &quot;</xsl:text> <xsl:value-of select="$metaDataVersionOID"/> <xsl:text>&quot;, </xsl:text> 
		<xsl:text>&quot;itemGroupData&quot;: {</xsl:text>
		<xsl:text>&quot;</xsl:text> <xsl:value-of select="$Name"/> <xsl:text>&quot;: {</xsl:text> 
		<xsl:text>&quot;records&quot;: </xsl:text> <xsl:value-of select="$nbRows"/> <xsl:text>, </xsl:text> 
		<xsl:text>&quot;name&quot;: &quot;</xsl:text> <xsl:value-of select="$Name"/> <xsl:text>&quot;, </xsl:text> 
		<xsl:text>&quot;label&quot;: &quot;</xsl:text> <xsl:value-of select="$Label"/> <xsl:text>&quot;, </xsl:text> 
		<xsl:text>&quot;items&quot;: [{&quot;OID&quot;: &quot;ITEMGROUPDATASEQ&quot;, &quot;name&quot;: &quot;ITEMGROUPDATASEQ&quot;,	&quot;label&quot;: &quot;Record identifier&quot;, &quot;type&quot;: &quot;integer&quot;}, </xsl:text>
		<xsl:for-each select="odm:ItemRef">
			<xsl:variable name="ItemOID" select="@ItemOID"/>
			<xsl:variable name="OID" select="normalize-space($root/odm:Study/odm:MetaDataVersion/odm:ItemDef[@OID=$ItemOID]/@OID)"/>
			<xsl:variable name="Name" select="normalize-space($root/odm:Study/odm:MetaDataVersion/odm:ItemDef[@OID=$ItemOID]/@Name)"/>
			<xsl:variable name="DataType" select="normalize-space($root/odm:Study/odm:MetaDataVersion/odm:ItemDef[@OID=$ItemOID]/@DataType)"/>
			<xsl:variable name="Label" select="normalize-space($root/odm:Study/odm:MetaDataVersion/odm:ItemDef[@OID=$ItemOID]/odm:Description/odm:TranslatedText)"/>
			<xsl:variable name="Length" select="normalize-space($root/odm:Study/odm:MetaDataVersion/odm:ItemDef[@OID=$ItemOID]/@Length)"/>
			<xsl:variable name="DisplayFormat" select="normalize-space($root/odm:Study/odm:MetaDataVersion/odm:ItemDef[@OID=$ItemOID]/@def:DisplayFormat)"/>
			<xsl:variable name="KeySequence" select="@KeySequence"/>
			<xsl:text>{</xsl:text> 
			<xsl:text>&quot;OID&quot;: &quot;</xsl:text> <xsl:value-of select="$OID"/> <xsl:text>&quot;, </xsl:text>
			<xsl:text>&quot;name&quot;: &quot;</xsl:text> <xsl:value-of select="$Name"/> <xsl:text>&quot;, </xsl:text>
			<xsl:text>&quot;label&quot;: &quot;</xsl:text> <xsl:value-of select="$Label"/> <xsl:text>&quot;, </xsl:text>
			<xsl:text>&quot;type&quot;: &quot;</xsl:text> 
				<xsl:choose>
					<xsl:when test="$DataType = 'text' or $DataType = 'datetime' or $DataType = 'date' or $DataType = 'time' or $DataType = 'partialDate' or $DataType = 'partialTime' or
					                $DataType = 'partialDatetime' or $DataType = 'incompleteDatetime' or $DataType = 'durationDatetime'">
						<xsl:text>string</xsl:text>
					</xsl:when>
					<xsl:when test="$DataType = 'integer'">
						<xsl:text>integer</xsl:text>
					</xsl:when>
					<xsl:when test="$DataType = 'float'">
						<xsl:text>float</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text></xsl:text>
					</xsl:otherwise>
				</xsl:choose> 
			<xsl:text>&quot;</xsl:text>
			<xsl:if test="$Length">
				<xsl:text>, </xsl:text>
				<xsl:text>&quot;length&quot;: </xsl:text> <xsl:value-of select="$Length"/>
			</xsl:if>
			<xsl:if test="$DisplayFormat">
				<xsl:text>, </xsl:text>
				<xsl:text>&quot;displayFormat&quot;: &quot;</xsl:text> <xsl:value-of select="$DisplayFormat"/> <xsl:text>&quot;</xsl:text>
			</xsl:if>
			<xsl:if test="$KeySequence">
				<xsl:text>, </xsl:text>
				<xsl:text>&quot;keySequence&quot;: </xsl:text> <xsl:value-of select="$KeySequence"/>
			</xsl:if>
			<xsl:text>}</xsl:text> 
			<xsl:if test="position() != last()">
				<xsl:text>, </xsl:text>
			</xsl:if>
			<xsl:if test="position() = last()">
				<xsl:text>], </xsl:text>
			</xsl:if>
		</xsl:for-each>
    </xsl:for-each>
	<xsl:text>&quot;itemData&quot;: [</xsl:text> 
	<xsl:text>]}}}}</xsl:text>
</xsl:template> 
	
</xsl:stylesheet>