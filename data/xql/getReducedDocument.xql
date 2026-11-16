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
declare namespace system = "http://exist-db.org/xquery/system";
declare namespace transform = "http://exist-db.org/xquery/transform";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:media-type "text/html";
declare option output:method "xhtml";
declare option output:indent "yes";
declare option output:omit-xml-declaration "yes";

(: VARIABLE DECLARATIONS =================================================== :)

declare variable $edition := request:get-parameter('edition', '');
declare variable $imageserver := edition:getPreference('image_server', $edition);

declare variable $imagePrefix := edition:getPreference('image_prefix', $edition);

(: QUERY BODY ============================================================== :)

let $uri := request:get-parameter('uri', '')
let $selectionId := request:get-parameter('selectionId', '')
let $subtreeRoot := request:get-parameter('subtreeRoot', '')
let $idPrefix := request:get-parameter('idPrefix', '')

let $doc := eutil:getDoc($uri)
let $xsl := $eutil:xsltBase || '/reduceToSelection.xsl'

let $doc :=
    transform:transform($doc, $xsl,
        <parameters>
            <param name="selectionId" value="{$selectionId}"/>
            <param name="subtreeRoot" value="{$subtreeRoot}"/>
        </parameters>
    )

let $doc := $doc/root()

let $xslInstruction := $doc//processing-instruction(xml-stylesheet)

let $xslInstruction :=
    for $i in serialize($xslInstruction, ())
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

let $xslDoc :=
    if ($xslInstructionDoc) then
        $xslInstructionDoc
    else
        eutil:getDoc($eutil:xsltBase || '/teiBody2HTML.xsl')

let $params := (
    <param name="base" value="{concat($eutil:xsltBase, '/')}"/>,
    <param name="idPrefix" value="{$idPrefix}"/>
)

return
    if ($xslInstructionDoc) then
        (transform:transform($doc/root(), $xslDoc, <parameters>{$params}</parameters>))
    else
        (transform:transform($doc/root(), $xslDoc, <parameters>{$params}<param name="graphicsPrefix" value="{$imagePrefix}"/></parameters>))
