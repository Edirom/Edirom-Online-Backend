xquery version "3.1";

module namespace editions="https://backend.edirom.de/editions";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

import module namespace config="https://backend.edirom.de/config" at "config.xqm";
import module namespace commons="https://backend.edirom.de/commons" at "commons.xqm";

declare
    %rest:GET
    %rest:path("/editions")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
    function editions:editions-json() {
        let $editions := ''
        return (
            commons:set-response-header-totalrecordcount($commons:response-headers, count($total-set)),
            $editions
        )
};

declare
    %rest:GET
    %rest:path("/editions/{$editionID}")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
    function editions:editionsID-json($editionID as xs:string) {
        let $edition := ''
        return (
            $commons:response-headers,
            $edition
        )
};