xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

 (:~
 : This module provides library functions for handling errors
 :
 : @author Francesco Maccarini
 :)
module namespace errors = "http://www.edirom.de/xquery/errors";

(: IMPORTS ================================================================= :)

import module namespace roaster="http://e-editiones.org/roaster";

(: NAMESPACE DECLARATIONS ================================================== :)

(: VARIABLE DECLARATIONS =================================================== :)

(:
    Error codes for the DTS API
 :)
declare variable $errors:INVALID_PARAMETERS := QName("http://www.edirom.de/xquery/errors", "InvalidParametersError");
declare variable $errors:UNSUPPORTED_MEDIA_TYPE := QName("http://www.edirom.de/xquery/errors", "UnsupportedMediaTypeError");
declare variable $errors:UNSUPPORTED_DOCUMENT_FORMAT := QName("http://www.edirom.de/xquery/errors", "UnsupportedDocumentFormatError");
declare variable $errors:NOT_FOUND := QName("http://www.edirom.de/xquery/errors", "NotFoundError");

(: FUNCTION DECLARATIONS =================================================== :)

declare function errors:sendResponse ($errCode as xs:QName, $errDescription as xs:string) {
    switch($errCode)
        case $errors:INVALID_PARAMETERS return
            roaster:response(400, "application/json", map {
                "error": "InvalidParameters",
                "message": $errDescription
            })
        case $errors:UNSUPPORTED_MEDIA_TYPE return
            roaster:response(415, "application/json", map {
                "error": "UnsupportedMediaType",
                "message": $errDescription
            })
        case $errors:UNSUPPORTED_DOCUMENT_FORMAT return
            roaster:response(404, "application/json", map {
                "error": "UnsupportedDocumentFormat",
                "message": $errDescription
            })
        case $errors:NOT_FOUND return
            roaster:response(404, "application/json", map {
                "error": "NotFound",
                "message": $errDescription
            })
        default return
            roaster:response(500, "application/json", map {
                "error": "InternalServerError",
                "message": $errCode || ": " || $errDescription
            })
};