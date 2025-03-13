<div align="center">

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![GitHub release](https://img.shields.io/github/v/release/Edirom/Edirom-Online-Backend.svg)](https://github.com/Edirom/Edirom-Online-Backend/releases)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14998458.svg)](https://doi.org/10.5281/zenodo.14998458)

</div>


## Get started

Edirom-Online Backend is the backend for the [Edirom-Online](https://github.com/Edirom/Edirom-Online) software.  It is a web application written in XQuery, and is designed for deployment in [eXist-db]. Its development is closely connected to the [Edirom-Online Frontend](https://github.com/Edirom/Edirom-Online-Frontend) and the Edirom-Online as a whole. Please see the GitHub repository for [Edirom-Online](https://github.com/Edirom/Edirom-Online) for planning information, issue listings, and further documentation. 

### Cloning this repository

```bash
git clone <project url>
```

### Building locally

For building Edirom Online you need *ant* installed on your system. 
Alternatively, you can use a Docker container image for building, e.g. [bwbohl/sencha-cmd]

```bash
docker run --rm -it -v /ABSOLUTE/PATH/TO/YOUR/LOCAL/EDIROM-ONLINE-BACKEND/CLONE:/app --name ediBuild ghcr.io/bwbohl/sencha-cmd:latest
```

When you have your system prepared with all prerequisites or you have your docker container running you are now set up to execute the build command. Do this by calling the build script included in this repository, either in your native shell or in the container shell, e.g.:

```bash
./build.sh
```

### Starting an Edirom instance locally

* prepare **exist-db**
  * also see [exist-db via Docker]
  * `docker run -it -d -p 8080:8080 -p 8443:8443 --name exist stadlerpeter/existdb:6` (see stadlerpeter/existdb)
  * open in browser: `http://localhost:8080` (Note: there were problems opening this in Safari)
  * Login with "admin:[empty]"
* build and deploy **xar of Edirom-Online Backend**
  * also see [building locally] above
  * at `http://localhost:8080/exist/apps/dashboard/admin#` (signed-in) go to "Package Manager" then "Upload" and select the xar file which (supposed above build-method was used) was built at `/PATH_TO_LOCAL_EDIROM_REPO/build-xar/Edirom-Online-Backend-1.0.0-[TIMESTAMP].xar`
* build and deploy **xar of Edirom-Online Frontend**
  * for building the frontend module please see https://github.com/Edirom/Edirom-Online-Frontend
  * at `http://localhost:8080/exist/apps/dashboard/admin#` (signed-in) go to "Package Manager" then "Upload" and select the xar file which (supposed above build-method was used) was built at `/PATH_TO_LOCAL_EDIROM_REPO/build-xar/Edirom-Online-Frontend-1.0.0-[TIMESTAMP].xar`
* build **xar of sample data** for deploying at exist-db
  * also see [building sample data]
  * at `http://localhost:8080/exist/apps/dashboard/admin#` (signed-in) go to "Package Manager" then "Upload" and select the xar file which (supposed above build-method was used) was built at `/PATH_TO_LOCAL_EDIROM_EDITION_EXAMPLE_REPO/build/EditionExample-0.1.xar`
* in **eXist-db Package Manager** click on the "Edirom Online Frontend" entry - you will be directed to the running Edirom at `http://localhost:8080/exist/apps/Edirom-Online-Frontend/index.html`

## Documentation

Some useful information regarding documentation is captured in the [docs](https://github.com/Edirom/Edirom-Online/tree/develop/docs) folder of the Edirom-Online repo. It contains:
* Customize Edirom Online and content
* Edirom Online – Release Workflow
* Setup Edirom Online on a local machine
* a data creation workflow for the Edirom-Online

## Dependencies

Edirom-Online Backend depends on the following libraries:

* ./.


## Roadmap

Versions of this software are planned in [Edirom-Online milestones](https://github.com/Edirom/Edirom-Online/milestones). 
Plans include the specification of an OpenAPI definition for the backend, and thus the refactoring to support REST requests to the backend.

## Contributing

After all this information, you decided to contribute to Edirom-Online Backend, that is awesome! We prepared a [CONTRIBUTING] file to help start your Edirom-Aventure now.

If you encounter a security issue in the code, please see the [Security Policy](.github/SECURITY.md) for further guidance.

## Get in touch

Even if you are not ready (yet) to contribute to this wonderful project, maybe instead you just have a question or want to get to know the people involved in the project a little better, here are some ideas for you: 
* there is an [Edirom mailinglist] with the option for selfsubscription, we send invitations to the community meetings via this list and we have Edirom related discussions on this list
* the edirom community is meeting regularly every month at the first wednesday of a month, see the [wiki] for more information and meeting minutes
* start a discussion at [GitHub Discussions]

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct]. By participating in this project you agree to abide by its terms.

## Citation

Please cite the software/repository using the information provided under "Cite this repository" on the right hand side. The APA and BIBTeX citations are fed by information from the CITATION.cff file in this repository which you can also use as a source.
If you intend to cite unreleased branches or commits please use the commit hash in the citation. 

## License

Edirom-Online Backend is released to the public under the terms of the [MIT] open source license.

[Musikwissenschaftliches Seminar Detmold/Paderborn]: https://www.muwi-detmold-paderborn.de/
[TEI]: https://tei-c.org/
[MEI]: https://music-encoding.org/
[Virtueller Forschungsverbund Edirom]: https://github.com/Edirom 
[Paderborn University]: https://www.uni-paderborn.de/en/
[Entwicklung von Werkzeugen für digitale Formen wissenschaftlich-kritischer Musikeditionen]: https://edirom.de/edirom-projekt/
[eXist-db]: https://exist-db.org/
[Verovio]: https://www.verovio.org/index.xhtml
[docs]: /docs
[Edirom-Online milestones]: https://github.com/Edirom/Edirom-Online/milestones
[CONTRIBUTING]: CONTRIBUTING.md
[bwbohl/sencha-cmd]: https://github.com/bwbohl/sencha-cmd/pkgs/container/sencha-cmd
[exist-db via Docker]: https://exist-db.org/exist/apps/doc/docker
[building sample data]: https://github.com/Edirom/EditionExample?tab=readme-ov-file#building
[Edirom mailinglist]: https://lists.uni-paderborn.de/mailman/listinfo/edirom-l
[wiki]: https://github.com/Edirom/Edirom-Online/wiki
[GitHub Discussions]: https://github.com/Edirom/Edirom-Online/discussions
[Contributor Code of Conduct]: CODE_OF_CONDUCT.md
[MIT]: https://opensource.org/license/mit
[ANT build file]: https://github.com/Edirom/Edirom-Online/blob/develop/build.xml
