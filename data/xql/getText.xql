xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace edition = "http://www.edirom.de/xquery/edition" at "../xqm/edition.xqm";

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace request = "http://exist-db.org/xquery/request";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare namespace transform = "http://exist-db.org/xquery/transform";

declare namespace util = "http://exist-db.org/xquery/util";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "xhtml";

declare option output:media-type "text/html";

declare option output:omit-xml-declaration "yes";

declare option output:indent "yes";

(: QUERY BODY ============================================================== :)

let $uri := request:get-parameter('uri', '')
let $idPrefix := request:get-parameter('idPrefix', '')
let $term := request:get-parameter('term', '')
let $path := request:get-parameter('path', '')
let $page := request:get-parameter('page', '')
let $doc := eutil:getDoc($uri)
let $contextPath := request:get-scheme()|| "://" || request:get-server-name() || ":" || request:get-server-port() || request:get-context-path()
let $xslInstruction := $doc//processing-instruction(xml-stylesheet)

let $xslInstruction :=
    for $i in fn:serialize($xslInstruction, ())
    return
        if (matches($i, 'type="text/xsl"')) then
        (substring-before(substring-after($i, 'href="'), '"'))
    else
        ()
let $xslInstructionDoc :=
    if (exists($xslInstruction)) then
        try {eutil:getDoc($xslInstruction)}
        catch * {()}
    else
        ()

let $doc :=
    if ($term eq '') then
        ($doc)
    else
        ($doc//tei:text[ft:query(., $term)]/ancestor::tei:TEI) => util:expand()

let $doc :=
    if ($page eq '') then
        ($doc)
    else (
        let $pb1 := $doc//tei:pb[@facs eq '#' || $page]/@n
        let $pb2 := ($doc//tei:pb[@facs eq '#' || $page]/following::tei:pb)[1]/@n
        
        return
            transform:transform($doc, eutil:getDoc($eutil:xsltBase || '/reduceToPage.xsl'),
                <parameters>
                    <param name="pb1" value="{$pb1}"/>
                    <param name="pb2" value="{$pb2}"/>
                </parameters>
            )
    )

let $edition := request:get-parameter('edition', '')
let $imageserver := edition:getPreference('image_server', $edition)
let $imagePrefix := edition:getPreference('image_prefix', $edition)

let $xslDoc.pass1 :=
    if($xslInstructionDoc) then
        $xslInstructionDoc
    else
        eutil:getDoc($eutil:xsltBase || '/tei/profiles/edirom-body/teiBody2HTML.xsl')

(:TODO introduce injection-point for tei-stylesheet parameters :)
let $params.pass1 :=
    <parameters>
        (: parameters for Edirom-Online :)
        <param name="lang" value="{edition:getLanguage($edition)}"/>,
        <param name="docUri" value="{$uri}"/>,
        <param name="contextPath" value="{$contextPath}"/>,
        <param name="imagePrefix" value="{$imagePrefix}"/>,
        (: parameters for the TEI Stylesheets :)
        <param name="autoHead" value="false"/>,
        <param name="autoToc" value="false"/>,
        <param name="base" value="{concat($eutil:xsltBase, '/')}"/>,
        <param name="documentationLanguage" value="{edition:getLanguage($edition)}"/>,
        <param name="footnoteBackLink" value="true"/>,
        <param name="numberHeadings" value="false"/>,
        <param name="pageLayout" value="CSS"/>
    </parameters>

let $doc.transformed.pass1 :=
    if($doc and $xslDoc.pass1)
    then transform:transform($doc, $xslDoc.pass1, $params.pass1)
    else ()

(: Do a second transformation to add edirom online ID prefixes for unique ID values if object is open multiple times :)
let $xslDoc.pass2 := eutil:getDoc($eutil:xsltBase || '/edirom_idPrefix.xsl')
let $params.pass2 := <parameters><param name="idPrefix" value="{$idPrefix}"/></parameters>
let $doc.transformed.pass2 :=
    if($doc.transformed.pass1 and $xslDoc.pass2)
    then transform:transform($doc.transformed.pass1, $xslDoc.pass2, $params.pass2)
    else ()

let $body := $doc.transformed.pass2//xhtml:body

return
    element div {
        $body/@*,
        $body/node()
    }
