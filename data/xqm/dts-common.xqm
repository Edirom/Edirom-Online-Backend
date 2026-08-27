xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides common functions for the Distributed Text Services API.
 :
 : @author Francesco Maccarini
 :)
module namespace dts-common = "http://www.edirom.de/api/dts-common";

(: VARIABLE DECLARATIONS ================================================== :)

(:~
 : Maps special resource aliases to internal application resources.
 :)
declare variable $dts-common:specialResourcesAliases as map(xs:string, xs:string) := map {
    "help_en": "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_en.xml",
    "help_de": "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_de.xml"
}; (: TODO: this is a temporary solution.
    There should be a collection also.
    Make them available to collection and navigation endopoints. :)

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Resolves special resource aliases to their backing application resources.
 :
 : @param $resource The requested resource identifier
 : @return The resolved resource URI
 :)
declare function dts-common:resolveSpecialResourceAlias(
    $resource as xs:string?
) as xs:string {
    if (map:contains($dts-common:specialResourcesAliases, $resource)) then
        map:get($dts-common:specialResourcesAliases, $resource)
    else
        $resource
};
