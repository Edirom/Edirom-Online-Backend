xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : Serves an X3D document stored in eXist-db for use by the edirom-3d-viewer web component.
 :
 : @param uri The eXist-db URI of the X3D document (xmldb:exist://...)
 : @return The X3D document
 :)

import module namespace request = "http://exist-db.org/xquery/request";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "xml";
declare option output:media-type "model/x3d+xml";

let $uri := request:get-parameter('uri', '')
return doc($uri)
