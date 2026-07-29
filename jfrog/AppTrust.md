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

```
graph TD
    %% Define main SDLC Stages using subgraph for visual grouping
    subgraph IDENTIFY_STAGE [NIST: IDENTIFY / Lifecycle: Requirements]
        A[Plan & Design]
        A_E[Evidence Creation:<br/>Threat Models, GPR, ISR Assessments,<br/>Privacy Impact Assessments]
    end

    %% --- Governance Layer: Compliance Policy Gate (Pre-Build) ---
    G1{Lifecycle Gate:<br/>Compliance & Governance Policy}
    G1_P(Policy: Verify Mandatory Attestations<br/>& metadata)

    subgraph PRE_COMMIT_STAGE [NIST: PROTECT / Lifecycle: Pre-Commit & Commit]
        B[Code]
        B_P[Developer IDE / CLI]
        B_E[Evidence Creation:<br/>SAST Results (SonarQube),<br/>Security Function Tests]

        %% --- Governance Layer: Developer Shift-Left Gate ---
        G2{Lifecycle Gate:<br/>Shift-Left Dev Policies}
        G2_P(Policy: Block Unvetted Dependencies<br/>& Malicious Packages)
    end

    subgraph BUILD_STAGE [NIST: PROTECT / Lifecycle: Build & Package]
        C[Build]
        C_CI[CI/CD Pipeline]
        C_E[Evidence Creation:<br/>Build Info, SCA, Secrets, IaC Scans]

        %% --- Governance Layer: QA Entry Gate ---
        G3{Lifecycle Gate:<br/>Build Integrity Policy}
        G3_P(Policy: Verify Signed Build Provenance,<br/>Block Critical Vulnerabilities)
    end

    subgraph QA_STAGE [NIST: PROTECT / Lifecycle: QA & Staging]
        D[QA / Staging]
        D_E[Evidence Creation:<br/>DAST (OWASP ZAP), API Fuzzing,<br/>Penetration Tests, CIS Benchmarks]

        %% --- Governance Layer: Trusted Release Gate (QA Exit) ---
        G4{Lifecycle Gate:<br/>Final Release Policy}
        G4_P(Policy: Evaluate Full Evidence Bundle,<br/>Hardening Verification)
    end

    %% --- AppTrust Outcomes ---
    T(Trusted Release Certification)
    T_B[[Generate Signed<br/>"Trusted Release" Badge]]
    B_P[[Blocked from<br/>Production Deployment]]

    subgraph PROD_STAGE [NIST: PROTECT / Lifecycle: Release & Deploy]
        E[Release & Deploy]
        E_P(Production Environment)
    end

    subgraph POST_RELEASE_STAGE [NIST: DETECT, RESPOND / Lifecycle: Runtime Governance]
        F[Operate & Monitor]
        F_E[Runtime Evidence:<br/>JFrog Xray Runtime Monitoring,<br/>Post-Release CVE Scans]

        %% --- Feedback Loop back to Identify ---
        FL[[Incident Response /<br/>Blast Radius Analysis]]
    end

    %% Define AppTrust Platform Components & System of Record
    subgraph JFrog_Platform [JFrog Platform: AppTrust System of Record]
        JF_CR[JFrog Curation]
        JF_AR[JFrog Artifactory]
        JF_XR[JFrog Xray]
        JF_AS[JFrog Advanced Security]
    end

    %% Main Flow Connections
    A --> G1
    A_E --> JF_AR

    G1 -- Pass --> B
    G1 -- Fail --> A_E
    G1 -.- G1_P

    B --> B_P
    B_E --> JF_AR
    B_P --> G2

    G2 -- Pass --> C
    G2 -- Fail --> B_P
    G2 -.- G2_P
    JF_CR -. Blocks unsafe downloads .-> B_P

    C --> C_CI
    C_E --> JF_AR
    C_CI --> G3

    G3 -- Pass --> D
    G3 -- Fail --> C_CI
    G3 -.- G3_P

    D --> D_E
    D_E --> JF_AR
    D --> G4

    G4 -- Pass --> T
    G4 -- Fail --> D_E
    G4 -.- G4_P

    T --> T_B
    T_B --> E

    B_P --> B_P
    G4 -- Fail (Blocked) --> B_P

    E --> E_P
    E_P --> F

    F --> F_E
    F_E --> JF_AR

    %% Continuous Feedback
    F_E -. Feedback loop to creation stage .-> A_E
    F_E -. Feedback loop to fix .-> B
    F -.-> FL
    FL -.-> A

    %% platform and evidence relationships
    JF_AR -. Immutable evidence bundle storage .-> G3
    JF_AR -. Immutable evidence bundle storage .-> G4
    JF_AR -. Immutable evidence bundle storage .-> T_B
    JF_XR -. Scans .-> JF_AR
    JF_AS -. Advanced context .-> JF_XR
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
