xquery version "1.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace repo="http://exist-db.org/xquery/repo";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace sm="http://exist-db.org/xquery/securitymanager";
import module namespace config="https://backend.edirom.de/config" at "modules/config.xqm";
import module namespace functx="http://www.functx.com";
import module namespace util="http://exist-db.org/xquery/util";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

(:~
 : Need to read the repo.xml from file because apparently it's 
 : stored to the db *after* the execution of the post-install script
 :)
declare variable $local:repo-descriptor := doc(concat('file://', $dir, '/repo.xml'))/repo:meta;

declare function local:set-options() as xs:string* {
    (
    for $opt in available-environment-variables()
    return
        config:set-option($opt, string(environment-variable($opt)))
    ,
    for $opt in available-environment-variables()[starts-with(., 'SWAGGER_')]
    return
        config:set-swagger-option(substring($opt, 9), string(environment-variable($opt)))
    )
};

(: set options passed as environment variables :)
local:set-options()