# AppTrust (Application Lifecycle)

Local CLI flow: [`jfcli-apptrust.sh`](./jfcli-apptrust.sh)  
Project: `ps-apptrust-rlm` · Application: `app-spring-petclinic` · Virtual repo: `rbv2-spring-petclinic-mvn-virtual`

## CLI sequence (`jfcli-apptrust.sh`)

```mermaid
sequenceDiagram
    autonumber
    actor Op as Operator
    participant CLI as JFrog CLI
    participant MVN as Maven / Local
    participant RT as Artifactory
    participant AT as AppTrust
    participant EVD as Evidence

    Op->>CLI: jf config use (psazuse)
    Op->>CLI: jf mvnc (resolve/deploy → virtual repo)
    CLI->>MVN: jf mvn clean install<br/>--build-name / --build-number / --project
    MVN-->>CLI: artifacts + Surefire reports + SBOM

    Note over CLI,RT: Build info publish
    CLI->>RT: jf rt bag (git)
    CLI->>RT: jf rt bce (env)
    CLI->>RT: jf rt bp (publish build)

    Note over CLI,AT: Application version
    CLI->>CLI: write at-app-spec.json<br/>(build name/number/repo)
    CLI->>AT: jf apptrust version-create<br/>APPLICATION_KEY / APPLICATION_VERSION<br/>--spec --tag=Package
    AT-->>CLI: app version created

    Note over CLI,EVD: Gate evidence before DEV promote
    CLI->>MVN: convertXml2Json (Surefire → JSON)
    CLI->>MVN: convertReport2Md (Surefire HTML → MD)
    CLI->>EVD: jf evd create (CycloneDX SBOM)
    CLI->>EVD: jf evd create (test-results + markdown)
    CLI->>CLI: write approval-predicate.json
    CLI->>EVD: jf evd create (approval/v1)

    Note over CLI,AT: Promote / release
    CLI->>AT: jf apptrust version-promote → DEV
    CLI->>AT: jf apptrust version-promote → QA
    CLI->>AT: jf apptrust version-release → PROD
    AT-->>CLI: version released

    CLI->>CLI: cleanup spec + predicate JSON
```

![GitHub Actions workflow](./images/github-actions.png)
![GitHub Security](./images/github-security-codescan.png)


# Project & Repos
![Project](./images/at-project.png)

## Build

![JFrog Build](./images/builds.png)

## Docker
![JFrog dkr](./images/psj-dkr-4-publishmodules.png)
![JFrog dkr](./images/psj-dkr-4-xraydata.png)
![JFrog dkr](./images/psj-dkr-4-vcs.png)
![JFrog dkr](./images/psj-dkr-4-evidence.png)
![JFrog dkr](./images/psj-dkr-4-rbv2.png)
![JFrog dkr](./images/psj-dkr-4-rbv2-evd.png)
![JFrog dkr](./images/summary-dkr.png)
![JFrog dkr](./images/summary-dkr-rbv2.png)

## MVN
![JFrog mvn](./images/psj-mvn-4-publishmodules.png)
![JFrog mvn](./images/psj-mvn-4-xraydata.png)
![JFrog mvn](./images/psj-mvn-4-evidence.png)
![JFrog mvn](./images/psj-mvn-4-rbv2.png)
![JFrog mvn](./images/psj-mvn-4-distribute.png)
![JFrog mvn](./images/summary-mvn.png)
![JFrog mvn](./images/summary-mvn-rbv2.png)

## Gradle
![JFrog gradle](./images/psj-gdl-4-publishmodules.png)
![JFrog gradle](./images/psj-gdl-4-vcs.png)
![JFrog gradle](./images/psj-gdl-4-xraydata.png)
![JFrog gradle](./images/summary-gradle.png)

## XRAY
![JFrog XRay](./images/xray-scans.png)
![JFrog XRay](./images/xray-scan-issues.png)
![JFrog XRay](./images/xray-scan-ondemand.png)
![JFrog XRay](./images/xray-scans-rbv2.png)
![JFrog XRay](./images/xray-scan-dkr-rbv2.png)
![JFrog XRay](./images/xray-scan-dkr-rbv2-sbom.png)
![JFrog XRay](./images/xray-scan-mvn-rbv2.png)
![JFrog XRay](./images/xray-scan-mvn-rbv2-vun.png)


## GitHub Actions - Status
 - [![AppTrust: Package](https://github.com/ps-jfrog/spring-petclinic/actions/workflows/jfcli-apptrust.yml/badge.svg)](https://github.com/ps-jfrog/spring-petclinic/actions/workflows/jfcli-apptrust.yml)
 - [![AppTrust: RBv2 Promote](https://github.com/ps-jfrog/spring-petclinic/actions/workflows/jfcli-apptrust-promote.yml/badge.svg)](https://github.com/ps-jfrog/spring-petclinic/actions/workflows/jfcli-apptrust-promote.yml)
 - [![AppTrust: RBv2 Distribute](https://github.com/ps-jfrog/spring-petclinic/actions/workflows/jfcli-apptrust-distribute.yml/badge.svg)](https://github.com/ps-jfrog/spring-petclinic/actions/workflows/jfcli-apptrust-distribute.yml)
