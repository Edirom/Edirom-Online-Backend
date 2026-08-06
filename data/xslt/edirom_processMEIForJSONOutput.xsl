<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xd xs" version="2.0">

    <xsl:param name="addMeasuresToZones" select="true()" as="xs:boolean"/>
    <xsl:param name="followReferenceAttributes" select="()" as="xs:string*"/>
    <xsl:variable name="followReferenceAttributeNames" as="xs:string*" select="for $name in tokenize(normalize-space(string-join($followReferenceAttributes, ' ')), '\s+') return normalize-space($name)"/>

    <xd:doc scope="stylesheet">
        <xd:desc>This stylesheet prepares an XML selection with additional elements and attributes before conversion to JSON , so that the JSON output has the desired structure.</xd:desc>
    </xd:doc>

    <xd:doc scope="component">
        <xd:desc>Identity transform for elements and nodes.</xd:desc>
    </xd:doc>
    <xsl:template match="*">
        <xsl:copy>
            <xsl:for-each select="@*[not(name() = $followReferenceAttributeNames)]">
                <xsl:attribute name="{name()}" select="."/>
            </xsl:for-each>
            <xsl:for-each select="@*[name() = $followReferenceAttributeNames]">
                <xsl:element name="{name()}">
                    <xsl:attribute name="hello" select="'world'"/>
                    <xsl:attribute name="placeholder" select="'true'"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*">
        <xsl:attribute name="{name()}" select="."/>
    </xsl:template>

    <xsl:template match="text()|comment()|processing-instruction()">
        <xsl:copy/>
    </xsl:template>

    <xd:doc scope="component">
        <xd:desc>Create a `zoneType` attribute from the `mei:zone/@type` to distinguish from `measureType`.</xd:desc>
    </xd:doc>
    <xsl:template match="mei:zone/@type">
        <xsl:attribute name="zoneType">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xd:doc scope="component">
        <xd:desc>Copy mei:zone and add surfaceId, width, height, and target attributes from the enclosing mei:surface and its sibling mei:graphic.</xd:desc>
    </xd:doc>
    <xsl:template match="mei:zone">
        <xsl:variable name="surface" select="ancestor::mei:surface[1]"/>
        <xsl:variable name="graphic" select="$surface/mei:graphic[@type = 'facsimile']"/>
        <!-- Identify measures that reference this zone via their @facs attribute -->
        <xsl:variable name="zoneRef" select="concat('#', string(@xml:id))"/>
        <!-- The first predicate with `contains` is just a rough estimate to narrow down the result set.
        It uses the index and is fast while the second (exact) predicate is generally too slow -->
        <xsl:variable name="measures" select="/*//mei:measure[contains(@facs, $zoneRef)][ $zoneRef = tokenize(@facs, '\s+') ]"/>
        <xsl:copy>
            <xsl:attribute name="surfaceId" select="string($surface/@xml:id)"/>
            <xsl:attribute name="width" select="string($graphic/@width)"/>
            <xsl:attribute name="height" select="string($graphic/@height)"/>
            <xsl:attribute name="target" select="string($graphic/@target)"/>
            <xsl:for-each select="@*[not(name() = $followReferenceAttributeNames)]">
                <xsl:attribute name="{name()}" select="."/>
            </xsl:for-each>
            <xsl:for-each select="@*[name() = $followReferenceAttributeNames]">
                <xsl:element name="{name()}">
                    <xsl:attribute name="hello" select="'world'"/>
                    <xsl:attribute name="placeholder" select="'true'"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:if test="$addMeasuresToZones and $measures">
                <xsl:for-each select="$measures">
                    <xsl:variable name="lbl">
                        <xsl:choose>
                            <xsl:when test="@label"><xsl:value-of select="string(@label)"/></xsl:when>
                            <xsl:otherwise><xsl:value-of select="string(@n)"/></xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="name">
                        <xsl:choose>
                            <xsl:when test=".//mei:multiRest">
                                <xsl:value-of select="concat($lbl, '–', number($lbl) + number(.//mei:multiRest/@num) - 1)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$lbl"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="rest">
                        <xsl:choose>
                            <xsl:when test=".//mei:mRest">1</xsl:when>
                            <xsl:when test=".//mei:multiRest"><xsl:value-of select="string(.//mei:multiRest/@num)"/></xsl:when>
                            <xsl:otherwise>0</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <measure measureId="{@xml:id}" name="{$name}" measureType="{string(@type)}" rest="{$rest}"/>
                </xsl:for-each>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc scope="component">
        <xd:desc>Copy mei:measure and add an mdivId attribute with the xml:id of the enclosing mei:mdiv element.</xd:desc>
    </xd:doc>
    <xsl:template match="mei:measure">
        <xsl:variable name="mdiv" select="ancestor::mei:mdiv[1]"/>
        <xsl:copy>
            <xsl:attribute name="mdivId" select="string($mdiv/@xml:id)"/>
            <xsl:for-each select="@*[not(name() = $followReferenceAttributeNames)]">
                <xsl:attribute name="{name()}" select="."/>
            </xsl:for-each>
            <xsl:for-each select="@*[name() = $followReferenceAttributeNames]">
                <xsl:element name="{name()}">
                    <xsl:attribute name="hello" select="'world'"/>
                    <xsl:attribute name="placeholder" select="'true'"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
