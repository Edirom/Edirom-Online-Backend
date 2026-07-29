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
        <xd:desc>Copy mei:zone and add a surfaceId attribute from the enclosing mei:surface.</xd:desc>
    </xd:doc>
    <xsl:template match="mei:zone">
        <xsl:copy>
            <xsl:attribute name="surfaceId" select="string(ancestor::mei:surface[1]/@xml:id)"/>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
