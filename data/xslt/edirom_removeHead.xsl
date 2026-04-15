<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs xd" version="3.0">

    <xd:doc scope="stylesheet">
        <xd:desc>This stylesheet is intended asa sceond run on HTML content for the Edirom Online, in order to prepend any ID with a prefix and avoid invalid HTML when an object is open multiple times in one Edirom Online insatnce.</xd:desc>
    </xd:doc>
    
    <xd:doc scope="component">
        <xd:desc>The $idPrefix parameter is submitted externally and is the value prepended to IDs etc.</xd:desc>
    </xd:doc>
    <xsl:param name="idPrefix"/>
    
    <xd:doc scope="component">
        <xd:desc>The root template</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Override the dafault template for elements to also apply templates on the attribute axis.</xd:desc>
    </xd:doc>
    <xsl:template match="*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc scope="component">
        <xd:desc>Override default template for attributes, to copy instead of printing text content.</xd:desc>
    </xd:doc>
    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>Override default templates for text comments and processing instructions to copy nodes.</xd:desc>
    </xd:doc>
    <xsl:template match="text() | comment() | processing-instruction()">
        <xsl:copy/>
    </xsl:template>


    <xd:doc scope="component">
        <xd:desc>Remove head elements like link, meta, title.</xd:desc>
    </xd:doc>
    <xsl:template match="xhtml:link | xhtml:meta | xhtml:title">
        <!-- remove head elements -->
        
    </xsl:template>
    
</xsl:stylesheet>