(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides document functions
 : and serves as a proxy to document type specific functions
 :
 : @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
 :)

 module namespace doc = "http://www.edirom.de/xquery/document";

(: IMPORTS ================================================================= :)


import module namespace source="http://www.edirom.de/xquery/source" at "source.xqm";
import module namespace teitext="http://www.edirom.de/xquery/teitext" at "teitext.xqm";
import module namespace work="http://www.edirom.de/xquery/work" at "work.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace edirom="http://www.edirom.de/ns/1.3";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Returns a comma separated list of document labels
 :
 : @param $docs The URIs of the documents to process
 : @return The labels
 :)
declare function doc:getDocumentsLabels($docs as xs:string*, $edition as xs:string) as xs:string {

    string-join(
        doc:getDocumentsLabelsAsArray($docs, $edition)
    , ', ')

};

(:~
 : Returns an array of document labels
 :
 : @param $docs The URIs of the documents to process
 : @return The labels
 :)
declare function doc:getDocumentsLabelsAsArray($docs as xs:string*, $edition as xs:string) as xs:string* {

    for $doc in $docs
    return
        doc:getDocumentLabel($doc, $edition)

};

(:~
 : Returns a document's label
 :
 : @param $doc The URIs of the document to process
 : @return The label
 :)
declare function doc:getDocumentLabel($doc as xs:string, $edition as xs:string) as xs:string {

    if(work:isWork($doc)) then
        (work:getLabel($doc, $edition))
    
    else if(source:isSource($doc)) then
        (source:getLabel($doc, $edition))
    
    else if(teitext:isText($doc)) then
        (teitext:getLabel($doc, $edition))

    else
        ('')

};