xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

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

(: QUERY BODY ============================================================== :)

let $lang := eutil:getSetLanguage(())
let $idPrefix := request:get-parameter('idPrefix', '')

let $base := replace(system:get-module-load-path(), 'embedded-eXist-server', '') (:TODO:)

let $uri := concat('xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_', $lang, '.xml')
let $doc := eutil:getDoc($uri)
let $contextPath := request:get-scheme()|| "://" || request:get-server-name() || ":" || request:get-server-port() || request:get-context-path()

let $xsl := eutil:getDoc($eutil:xsltBase || '/edirom_langReplacement.xsl')
let $doc := 
    transform:transform($doc, $xsl,
        <parameters>
            <param name="base" value="{concat($eutil:xsltBase, '/')}"/>
            <param name="lang" value="{$lang}"/>
        </parameters>
    )

let $xsl := eutil:getDoc($eutil:xsltBase || '/tei/profiles/edirom-body/teiBody2HTML.xsl')
let $doc :=
    transform:transform($doc, $xsl,
        <parameters>
            <param name="base" value="{concat($eutil:xsltBase, '/')}"/>
            <param name="lang" value="{$lang}"/>
            <param name="tocDepth" value="1"/>
            <param name="contextPath" value="{$contextPath}"/>
            <param name="docUri" value="{$uri}"/>
        </parameters>
    )

(: XSLT for removing unnecessary/disturbing head tags, e.g. meta, title, link - because those end up breaking CSS in other windows:)
let $xsl := eutil:getDoc($eutil:xsltBase || '/edirom_removeHead.xsl')
let $doc :=
    transform:transform($doc, $xsl,
        <parameters></parameters>
    )

return
    transform:transform($doc, eutil:getDoc($eutil:xsltBase || '/edirom_idPrefix.xsl'),
        <parameters>
            <param name="idPrefix" value="{$idPrefix}"/>
        </parameters>
    )
