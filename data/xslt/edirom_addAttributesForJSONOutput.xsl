<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xd" version="2.0">

    <xd:doc scope="stylesheet">
        <xd:desc>This stylesheet prepares an XML selection with additional elements and attributes before conversion to JSON , so that the JSON output has the desired structure.</xd:desc>
    </xd:doc>

    <xd:doc scope="component">
        <xd:desc>Identity transform.</xd:desc>
    </xd:doc>
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc scope="component">
        <xd:desc>Copy mei:zone and add surfaceId, width, height, and target attributes from the enclosing mei:surface and its sibling mei:graphic.</xd:desc>
    </xd:doc>
    <xsl:template match="mei:zone">
        <xsl:variable name="surface" select="ancestor::mei:surface[1]"/>
        <xsl:variable name="graphic" select="$surface/mei:graphic[@type = 'facsimile']"/>
        <xsl:copy>
            <xsl:attribute name="surfaceId" select="string($surface/@xml:id)"/>
            <xsl:attribute name="width" select="string($graphic/@width)"/>
            <xsl:attribute name="height" select="string($graphic/@height)"/>
            <xsl:attribute name="target" select="string($graphic/@target)"/>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc scope="component">
        <xd:desc>Copy mei:measure and add an mdivId attribute with the xml:id of the enclosing mei:mdiv element.</xd:desc>
    </xd:doc>
    <xsl:template match="mei:measure">
        <xsl:variable name="mdiv" select="ancestor::mei:mdiv[1]"/>
        <xsl:copy>
            <xsl:attribute name="mdivId" select="string($mdiv/@xml:id)"/>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
