xquery version "3.1";

(:~
 : Main executable XQuery for running XQSuite unit tests
 : @see http://exist-db.org/exist/apps/doc/xqsuite.xml
:)

(: the following line must be added to each of the modules that include unit tests :)
import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
 
import module namespace eut="http://www.edirom.de/xquery/xqsuite/eutil-tests" at "eutil-tests.xqm";
import module namespace edt="http://www.edirom.de/xquery/xqsuite/edition-tests" at "edition-tests.xqm";
import module namespace ddt="http://www.edirom.de/xquery/xqsuite/dts-document-tests" at "dts-document-tests.xqm";
import module namespace tax="http://www.edirom.de/xquery/xqsuite/taxonomy-tests" at "taxonomy-tests.xqm";
import module namespace ann="http://www.edirom.de/xquery/xqsuite/annotation-tests" at "annotation-tests.xqm";

(: the test:suite() function will run all the test-annotated functions in the module whose namespace URI you provide :)
test:suite((
    util:list-functions("http://www.edirom.de/xquery/xqsuite/eutil-tests"),
    util:list-functions("http://www.edirom.de/xquery/xqsuite/edition-tests"),
    util:list-functions("http://www.edirom.de/xquery/xqsuite/dts-document-tests"),
    util:list-functions("http://www.edirom.de/xquery/xqsuite/taxonomy-tests"),
    util:list-functions("http://www.edirom.de/xquery/xqsuite/annotation-tests")
))
