xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

 (:~
 : This module implements the navigation endpoint for the Distributed Text Services API.
 :
 : @author Francesco Maccarini
 :)
module namespace dts-navigation = "http://www.edirom.de/api/dts-navigation";

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "eutil.xqm";
import module namespace errors = "http://www.edirom.de/xquery/errors" at "errors.xqm";
import module namespace dts-common = "http://www.edirom.de/api/dts-common" at "dts-common.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace array = "http://www.w3.org/2005/xpath-functions/array";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace system = "http://exist-db.org/xquery/system";
declare namespace transform = "http://exist-db.org/xquery/transform";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace request = "http://exist-db.org/xquery/request";


(: FUNCTION DECLARATIONS =================================================== :)

declare function dts-navigation:getCitationTrees($document as document-node()) as element()* {
    let $namespace := eutil:getNamespace($document/*)
    let $allTrees := eutil:getDoc($eutil:app-root || '/data/trees/citationTrees' || upper-case($namespace) || '.xml')/refsDecl/citeStructure
    return $allTrees
};

declare function dts-navigation:convertCiteStructureToMap(
    $citeStructure as element(citeStructure)
) as item() {
    let $result := map:merge((
        map:entry("@type", "CiteStructure"),
        map:entry("citeType", string($citeStructure/@unit))
    ))
    return
        if ($citeStructure/citeStructure) then
            map:put(
                $result,
                "citeStructure",
                array:join(
                    $citeStructure/citeStructure ! [dts-navigation:convertCiteStructureToMap(.)]
                )
            )
        else
            $result
};

declare function dts-navigation:convertCitationTreesToMap(
    $citationTrees as element(citeStructure)*
) as item() {
    array:join(
        for $citationTree in $citationTrees
        return [
            map:merge((
                map:entry("@type", "CitationTree"),
                if ($citationTree/@xml:id) then
                    map:entry("identifier", string($citationTree/@xml:id))
                else
                    (),
                (:
                TODO: According to DTS specifications,
                the behaiour of the identifier must be changed here
                and in the document endpoint.

                If a Resource has a single CitationTree,
                that CitationTree object cannot have an identifier.
                If a Resource has multiple CitationTrees,
                then the first listed in citationTrees
                is the default CitationTree and cannot have an identifier.
                :)
                map:entry(
                    "citeStructure",
                    [dts-navigation:convertCiteStructureToMap($citationTree)]
                )
            ))
        ]
    )
};

declare function dts-navigation:buildResourceObject($document as document-node(),
    $resource as xs:string
) as map(*) {
    let $base-url := substring-before(request:get-url(), "/api")
    let $citationTreesXML := dts-navigation:getCitationTrees($document)
    let $resourceObject := map {
        "@id": $resource,
        "@type": "Resource",
        "collection": dts-common:buildCollectionURI($base-url, $resource, (), ()),
        "navigation": dts-common:buildNavigationURI($base-url, $resource, (), (), (), (), (), ()),
        "document": dts-common:buildDocumentURI($base-url, $resource, (), (), (), (), (), (), (), ()),
        "citationTrees": dts-navigation:convertCitationTreesToMap($citationTreesXML)
    }
    return $resourceObject
};

(:~
 : Returns the navigation structure for a given resource.
 :
 : @param $resource The resource for which to retrieve the navigation structure.
 : @param $ref The reference point within the resource (optional).
 : @param $start The starting point of the navigation (optional).
 : @param $end The ending point of the navigation (optional).
 : @param $down The depth of the navigation tree (optional).
 : @param $tree The citation tree identifier to use (optional).
 : @param $page The number of identifying a page in paginated query results (optional).
 :)
declare function dts-navigation:navigation(
    $resource as xs:string,
    $ref as xs:string?,
    $start as xs:string?,
    $end as xs:string?,
    $down as xs:integer?,
    $tree as xs:string?,
    $page as xs:integer?
) as map(*) {
    if ($ref and ($start or $end)) then
        error($errors:INVALID_PARAMETERS, "The 'ref' parameter cannot be used together with 'start' or 'end'.")
    else if (($start and not($end)) or ($end and not($start))) then
        error($errors:INVALID_PARAMETERS, "Both 'start' and 'end' parameters must be provided together.")
    else if (not($down) and not($ref) and not($start) and not($end)) then
        error($errors:INVALID_PARAMETERS, "At least one of 'ref', 'start/end', or 'down' parameters must be provided.")
    else if ($down eq 0 and not($ref)) then
        error($errors:INVALID_PARAMETERS, "The 'down' parameter cannot be 0 when no 'ref' parameter is provided.")
    else
        let $resource := dts-common:resolveSpecialResourceAlias($resource)
        let $document := eutil:getDoc($resource)/root()
        let $document :=
            if ($document) then
                eutil:add-xml-ids($document)
            else
                error($errors:NOT_FOUND, "The requested resource was not found.")
        let $namespace := eutil:getNamespace($document/*)
        let $citationTree := eutil:getDoc($eutil:app-root || '/data/trees/citationTrees' || upper-case($namespace) || '.xml')/refsDecl/citeStructure[
            not($tree) or @xml:id = $tree
        ]

        let $resourceObject := dts-navigation:buildResourceObject($document, $resource)
        let $output := map {
            "@context": "https://dtsapi.org/context/v1.0.json",
            "dtsVersion": "1.0",
            "@id": request:get-url(),
            "@type": "Navigation",
            "resource": $resourceObject
        }

        return $output
};