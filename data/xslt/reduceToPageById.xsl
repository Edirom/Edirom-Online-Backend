<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jun 11, 2014</xd:p>
            <xd:p><xd:b>Author:</xd:b> Daniel Röwenstrunk</xd:p>
            <xd:p></xd:p>
            <xd:p>Modified by Francesco Maccarini on Jun 10, 2026</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:param name="pb1_id"/>
    <xsl:param name="pb2_id"/>
    
    <xsl:output indent="yes"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:choose>
            <xsl:when test=".[./descendant-or-self::tei:pb[@xml:id eq $pb1_id]]">
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()[./descendant-or-self::tei:pb[@xml:id eq $pb1_id] or ./preceding::tei:pb[@xml:id eq $pb1_id]]"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test=".[./descendant::tei:pb[@xml:id eq $pb2_id]]">
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()[./descendant-or-self::tei:pb[@xml:id eq $pb2_id] or ./following::tei:pb[@xml:id eq $pb2_id] or $pb2_id eq '']"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test=".[./preceding::tei:pb[@xml:id eq $pb1_id] and (./following::tei:pb[@xml:id eq $pb2_id] or $pb2_id eq '')]">
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:pb">
        <xsl:choose>
            <xsl:when test="@xml:id eq $pb1_id">
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="@xml:id eq $pb2_id and @rend eq '-'">
                <xsl:copy>
                    <xsl:apply-templates select="@* except @xml:id"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="not(@xml:id = $pb2_id)">
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>
    <xsl:template match="text()">
        <xsl:choose><xsl:when test=".[./preceding::tei:pb[@xml:id eq $pb1_id] and (./following::tei:pb[@xml:id eq $pb2_id] or $pb2_id eq '')]">
                <xsl:copy/>
    </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>