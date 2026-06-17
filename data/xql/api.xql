xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace api="http://www.edirom.de/api";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace exist="http://exist.sourceforge.net/NS/exist";

(: IMPORTS ================================================================= :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace roaster="http://e-editiones.org/roaster";

import module namespace errors="http://www.edirom.de/xquery/errors" at "../xqm/errors.xqm";
import module namespace dts-document="http://www.edirom.de/api/dts-document" at "../xqm/dts-document.xqm";

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
    map {
        "@context": "https://dtsapi.org/context/v1.0.json",
        "dtsVersion": "1.0",
        "@id": concat($base-url, "/api/"),
        "@type": "EntryPoint",
        "collection": concat($base-url, "/api/collection/{?id,page,nav}"),
        "navigation" : concat($base-url, "/api/navigation/{?resource,ref,start,end,down,tree,page}"),
        "document": concat($base-url, "/api/document/{?resource,ref,start,end,tree,mediaType,lang,idPrefix,autoHead,autoToc,tocDepth,footnoteBackLink,numberHeadings}")
    }
};

declare function api:collection ($request as map(*)) {
    map {
        "message": "This is a collection endpoint."
     }
};

declare function api:navigation ($request as map(*)) {
    map {
        "message": "This is a navigation endpoint."
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
        "autoHead": if (exists($request?parameters?autoHead)) then xs:string($request?parameters?autoHead) else "false",
        "autoToc": if (exists($request?parameters?autoToc)) then xs:string($request?parameters?autoToc) else "false",
        "tocDepth": if (exists($request?parameters?tocDepth)) then xs:string($request?parameters?tocDepth) else "1",
        "footnoteBackLink": if (exists($request?parameters?footnoteBackLink)) then xs:string($request?parameters?footnoteBackLink) else "true",
        "numberHeadings": if (exists($request?parameters?numberHeadings)) then xs:string($request?parameters?numberHeadings) else "false"
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
