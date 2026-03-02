xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides library functions for Texts
 :
 : @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
 :)
module namespace teitext="http://www.edirom.de/xquery/teitext";

(: IMPORTS ================================================================= :)

import module namespace edition="http://www.edirom.de/xquery/edition" at "edition.xqm";
import module namespace eutil="http://www.edirom.de/xquery/eutil" at "eutil.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Returns whether a document is a work or not
 :
 : @param $uri The URI of the document
 : @return Is work or not
 :)
declare function teitext:isText($uri as xs:string) as xs:boolean {

    exists(eutil:getDoc($uri)/tei:TEI)

};

(:~
 : Returns a text's label
 :
 : @param $source The URIs of the Text's document to process
 : @return The label
 :)
declare function teitext:getLabel($uri as xs:string, $edition as xs:string) as xs:string {

    eutil:getLocalizedTitle(eutil:getDoc($uri), edition:getLanguage($edition))

};

(:~
    API endpoint for TEI as HTML output
 : 
 : @param $apiVersion The API version to decide on output format
 : @param $uri The URI of the document to process
 : @param $idPrefix An ID prefix to add to all unique ID values in the document
 : @param $term An optional search term to filter the text by
 : @param $page An optional page to filter the text by
 : @param $contextPath The context path of the server to build absolute URLs for images and links
 : @return HTML for the text    
:)
declare
    %rest:GET
    %rest:path("/{$apiVersion}/tei/html")
    %rest:query-param("edition", "{$edition}", "")
    %rest:query-param("uri", "{$uri}", "")
    %rest:query-param("idPrefix", "{$idPrefix}", "")
    %rest:query-param("term", "{$term}", "")
    %rest:query-param("page", "{$page}", "")
    %rest:query-param("contextPath", "{$contextPath}", "")
    %rest:query-param("lang", "{$lang}", "")
    %rest:produces("text/html") 
    %output:media-type("text/html")
    %output:method("html")
function teitext:getHtmlAPI($apiVersion as xs:string, $edition as xs:string*, $uri as xs:string*, $idPrefix as xs:string*, $term as xs:string*,
                        $page as xs:string*, $contextPath as xs:string*, $lang as xs:string*) as element() {

    let $doc := teitext:getHTML($edition, $uri, $idPrefix, $term, $page, $contextPath, $lang)
    let $body := $doc//xhtml:body
    
    return 

        (: for API v1 return body/* wrapped in div :)
        if($apiVersion eq "v1") then
            element div {
                for $attribute in $body/@*
                return
                    $attribute,
                for $node in $body/node()
                return
                    $node
            }
        else

        (: for API v2 return complete $doc :)
        if($apiVersion eq "v2") then
            ($doc)

        (: otherwise :)
        else
            element p {
                "Invalid API version: " || $apiVersion
            }
    
};

(:~
 : Returns HTML for TEI text
 :
 : @param $source The URIs of the Text's document to process
 : @return HTML
 :)
declare function teitext:getHTML(
    $edition as xs:string*, 
    $uri as xs:string*, 
    $idPrefix as xs:string*, 
    $term as xs:string*,
    $page as xs:string*, 
    $contextPath as xs:string*,
    $lang as xs:string*) as element() {

    (: get preferences :)
    let $imagePrefix := edition:getPreference('image_prefix', $edition)
    let $lang := if ($lang != "") then $lang else edition:getLanguage($edition)

    (: get TEI from $uri :)
    let $doc := eutil:getDoc($uri)/root()

    (: get XSLTs from processing instruction :)
    let $xslInstruction := $doc//processing-instruction(xml-stylesheet)
    let $xslInstruction :=
        for $i in fn:serialize($xslInstruction, ())
        return
            if (matches($i, 'type="text/xsl"')) then
            (substring-before(substring-after($i, 'href="'), '"'))
        else
            ()

    (: get TEI root by $term if provided :)
    let $doc :=
        if ($term eq '') then
            ($doc)
        else
            ($doc//tei:text[ft:query(., $term)]/ancestor::tei:TEI)

    (: apply util:expand if $term is provided :)
    let $doc :=
        if ($term eq '') then
            ($doc)
        else
            (util:expand($doc))

    let $base := replace(system:get-module-load-path(), 'embedded-eXist-server', '')
    
    let $xsl :=
        if ($xslInstruction) then
            ($xslInstruction)
        else
            ('../xslt/tei/profiles/edirom-body/teiBody2HTML.xsl')

    (:TODO introduce injection-point for tei-stylesheet parameters :)
    let $params := (
        (: parameters for Edirom-Online :)
        <param name="lang" value="{$lang}"/>,
        <param name="docUri" value="{$uri}"/>,
        <param name="contextPath" value="{$contextPath}"/>,
        <param name="imagePrefix" value="{$imagePrefix}"/>,
        (: parameters for the TEI Stylesheets :)
        <param name="autoHead" value="false"/>,
        <param name="autoToc" value="false"/>,
        <param name="base" value="{concat($base, '/../xslt/')}"/>,
        <param name="documentationLanguage" value="{$lang}"/>,
        <param name="footnoteBackLink" value="true"/>,
        <param name="numberHeadings" value="false"/>,
        <param name="pageLayout" value="CSS"/>
    )

    let $doc := transform:transform($doc, doc($xsl), <parameters>{$params}</parameters>)

    (: Do a second transformation to add edirom online ID prefixes for unique ID values if object is open mutiple times :)
    let $xsl := '../xslt/edirom_idPrefix.xsl'

    let $params := (
        <param name="idPrefix" value="{$idPrefix}"/>
    )

    let $doc := transform:transform($doc, doc($xsl), <parameters>{$params}</parameters>)

    return
        $doc
        

};