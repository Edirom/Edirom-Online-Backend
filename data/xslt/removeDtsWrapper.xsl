<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dts="https://w3id.org/dts/api#"
                exclude-result-prefixes="dts"
                version="2.0">

  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dts:wrapper">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>

</xsl:stylesheet>
