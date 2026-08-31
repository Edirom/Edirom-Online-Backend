xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace api="http://www.edirom.de/api";
declare namespace json="http://www.json.org";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace exist="http://exist.sourceforge.net/NS/exist";

(: IMPORTS ================================================================= :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace roaster="http://e-editiones.org/roaster";

import module namespace errors="http://www.edirom.de/xquery/errors" at "../xqm/errors.xqm";
import module namespace dts-common="http://www.edirom.de/api/dts-common" at "../xqm/dts-common.xqm";
import module namespace dts-document="http://www.edirom.de/api/dts-document" at "../xqm/dts-document.xqm";
import module namespace dts-navigation="http://www.edirom.de/api/dts-navigation" at "../xqm/dts-navigation.xqm";

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : list of definition files to use
 :)
declare variable $api:definitions := ("data/api/api.json");


(:~
 : DTS-oriented route handlers
 :)
declare function api:entryPoint ($request as map(*)) {
    let $base-url := substring-before(request:get-url(), "/api")
    return
        <json:value>
            <context json:name="@context">https://dtsapi.org/context/v1.0.json</context>
            <dtsVersion>1.0</dtsVersion>
            <id json:name="@id">{concat($base-url, "/api/")}</id>
            <type json:name="@type">EntryPoint</type>
            <collection>{dts-common:buildCollectionURI($base-url, (), (), ())}</collection>
            <navigation>{dts-common:buildNavigationURI($base-url, (), (), (), (), (), (), ())}</navigation>
            <document>{dts-common:buildDocumentURI($base-url, (), (), (), (), (), (), (), (), ())}</document>
        </json:value>
};

declare function api:collection ($request as map(*)) {
    map {
        "message": "This is a collection endpoint."
     }
};

declare function api:navigation ($request as map(*)) {
    let $resource := xs:string($request?parameters?resource)
    let $mediaType := "application/ld+json"
    return
        try {
            let $navigation := dts-navigation:navigation(
                $resource,
                if (exists($request?parameters?ref)) then xs:string($request?parameters?ref) else "",
                if (exists($request?parameters?start)) then xs:string($request?parameters?start) else "",
                if (exists($request?parameters?end)) then xs:string($request?parameters?end) else "",
                if (exists($request?parameters?down)) then xs:integer($request?parameters?down) else (),
                if (exists($request?parameters?tree)) then xs:string($request?parameters?tree) else "",
                if (exists($request?parameters?page)) then xs:integer($request?parameters?page) else ()
            )
            return
                roaster:response(200, $mediaType, $navigation)
        } catch * {
            errors:sendResponse($err:code, $err:description)
        }
};

declare function api:document ($request as map(*)) {
    let $base-url := substring-before(request:get-url(), "/api")
    let $resource := xs:string($request?parameters?resource)
    let $mediaType := xs:string($request?parameters?mediaType)
    let $headers := map {
        "Link": concat($base-url, '/api/collection/?resource=', $resource, '; rel="collection"')
    }
    let $htmlParameters := map {
        "lang": if (exists($request?parameters?lang)) then xs:string($request?parameters?lang) else "",
        "idPrefix": if (exists($request?parameters?idPrefix)) then xs:string($request?parameters?idPrefix) else "",
        "htmlProfile": if (exists($request?parameters?htmlProfile)) then xs:string($request?parameters?htmlProfile) else $dts-document:defaultHTMLProfile
    }
    return
        try {
            let $document := dts-document:document(
                $resource,
                if (exists($request?parameters?ref)) then xs:string($request?parameters?ref) else "",
                if (exists($request?parameters?start)) then xs:string($request?parameters?start) else "",
                if (exists($request?parameters?end)) then xs:string($request?parameters?end) else "",
                xs:string($request?parameters?tree),
                $mediaType,
                $htmlParameters
            )
            return
                roaster:response(200, $mediaType, $document, $headers)
        } catch * {
            errors:sendResponse($err:code, $err:description)
        }
    

    
};
(: end of route handlers :)

(:~
 : This function "knows" all modules and their functions
 : that are imported here 
 : You can leave it as it is, but it has to be here
 :)
declare function api:lookup ($name as xs:string) {
    function-lookup(xs:QName($name), 1)
};

(: util:declare-option("output:indent", "no"), :)
roaster:route($api:definitions, api:lookup#1)
