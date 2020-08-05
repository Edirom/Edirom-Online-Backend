xquery version "3.1";

module namespace utils="https://backend.edirom.de/utils";


declare function utils:uri($elem as element()) as xs:string {
    "xmldb:exist://" || base-uri($elem)
};


