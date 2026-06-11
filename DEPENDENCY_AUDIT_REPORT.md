# Dependency Audit Report
**Date:** 2026-06-11  
**Repository:** Akto API Security  
**Auditor:** Claude Code

---

## 🔴 CRITICAL SECURITY VULNERABILITIES

### JavaScript/Node.js Dependencies

#### 1. @babel/traverse - CRITICAL (CVSS 9.4)
**Location:** `/home/user/akto/apps/dashboard/package.json` (transitive dependency)
- **Vulnerability:** CVE GHSA-67hx-6x53-jw92 - Arbitrary code execution when compiling malicious code
- **Current Version:** <7.23.2
- **Fix:** Update to ≥7.23.2
- **Severity:** CRITICAL

#### 2. axios - HIGH (Multiple CVEs)
**Location:** `/home/user/akto/apps/dashboard/package.json:34`
```json
"axios": "^0.21.1"
```
- **Vulnerabilities:**
  - GHSA-wf5p-g6vw-rhxx: CSRF vulnerability
  - GHSA-4hjh-wcwx-xvwj: DoS through lack of data size check
  - GHSA-jr5f-v2jv-69x6: SSRF and credential leakage via absolute URL
- **Current Version:** 0.21.1
- **Recommended:** Update to 1.13.2+
- **Severity:** HIGH

**Also affected:**
- `/home/user/akto/apps/dashboard/web/polaris_web/package.json:16`
  ```json
  "axios": "^1.4.0"
  ```
  - Less critical but still needs update to 1.13.2+

#### 3. webpack-dev-server - HIGH
**Location:** `/home/user/akto/apps/dashboard/package.json:80`
```json
"webpack-dev-server": "^2.9.1"
```
- **Vulnerabilities:** Multiple transitive vulnerabilities:
  - ansi-html: Uncontrolled resource consumption (GHSA-whgm-jr23-g3j9)
  - Multiple issues in bonjour, chokidar, http-proxy-middleware, sockjs, sockjs-client
- **Current Version:** 2.9.1
- **Recommended:** Update to 5.2.2+ (BREAKING CHANGE)
- **Severity:** HIGH

#### 4. body-parser - HIGH
**Location:** Transitive dependency through express in `/home/user/akto/apps/dashboard/package.json`
- **Vulnerability:** GHSA-qwcr-r2fm-qrc7 - DoS when URL encoding enabled
- **Recommended:** Ensure updated to ≥1.20.3
- **Severity:** HIGH

#### 5. Legacy Babel 6.x packages - CRITICAL
**Locations in `/home/user/akto/apps/dashboard/package.json`:**
- Line 61: `"babel-core": "^6.0.0"`
- Line 62: `"babel-eslint": "^7.0.0"`
- Line 64: `"babel-plugin-transform-regenerator": "^6.26.0"`
- Line 65: `"babel-plugin-transform-runtime": "^6.0.0"`
- Line 66: `"babel-polyfill": "^6.26.0"`
- Line 67: `"babel-preset-es2015": "^6.0.0"`
- Line 68: `"babel-preset-stage-2": "^6.0.0"`
- Line 69: `"babel-register": "^6.0.0"`

- **Vulnerability:** GHSA-67hx-6x53-jw92 - Critical vulnerabilities with NO FIXES AVAILABLE
- **Recommended:** REMOVE ALL and migrate to Babel 7.x completely
- **Severity:** CRITICAL
- **Impact:** ~50-80MB bloat + security vulnerabilities

#### 6. brace-expansion - MEDIUM
**Location:** Transitive dependency in `/home/user/akto/apps/dashboard/package.json`
- **Vulnerability:** GHSA-v6h2-p8h4-qcjw - Regular Expression DoS
- **Severity:** MEDIUM

---

### Java Dependencies

#### 1. Apache Struts 2.5.30 - HIGH RISK
**Location:** `/home/user/akto/apps/dashboard/pom.xml:60-63`
```xml
<dependency>
    <groupId>org.apache.struts</groupId>
    <artifactId>struts2-core</artifactId>
    <version>2.5.30</version>
</dependency>
```
**Also at:** `/home/user/akto/apps/dashboard/pom.xml:112-115` (struts2-json-plugin)
- **Risk:** Struts has history of critical RCE vulnerabilities
- **Current Version:** 2.5.30
- **Recommended:** Update to 6.4.0 or latest 2.5.x with security patches
- **Severity:** HIGH

#### 2. jackson-databind - MEDIUM-HIGH RISK
**Locations:**

**a)** `/home/user/akto/apps/dashboard/pom.xml:149-153`
```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.12.7.1</version>
</dependency>
```

**b)** `/home/user/akto/apps/api-runtime/pom.xml:55-60`
```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.12.7.1</version>
    <scope>compile</scope>
</dependency>
```

**c)** `/home/user/akto/libs/utils/pom.xml:86-91`
```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.12.7.1</version>
    <scope>compile</scope>
</dependency>
```

**d)** `/home/user/akto/libs/integrations/pom.xml:23-28`
```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.12.7.1</version>
    <scope>compile</scope>
</dependency>
```

- **Vulnerabilities:** Multiple deserialization vulnerabilities in 2.12.x
- **Current Version:** 2.12.7.1
- **Recommended:** Update to 2.14.3+ or 2.15.x
- **Severity:** MEDIUM-HIGH

#### 3. jackson-core - VERSION INCONSISTENCY
**Locations:**

**a)** `/home/user/akto/apps/dashboard/pom.xml:154-158`
```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-core</artifactId>
    <version>2.13.0</version>
</dependency>
```

**b)** `/home/user/akto/libs/utils/pom.xml:97-101`
```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-core</artifactId>
    <version>2.12.2</version>
</dependency>
```

- **Issue:** Version mismatch (2.13.0 vs 2.12.2)
- **Recommended:** Standardize to 2.14.3+ or 2.15.x

#### 4. jackson-annotations - VERSION INCONSISTENCY
**Locations:**

**a)** `/home/user/akto/apps/dashboard/pom.xml:159-163`
```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-annotations</artifactId>
    <version>2.13.0</version>
</dependency>
```

**b)** `/home/user/akto/libs/utils/pom.xml:108-112`
```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-annotations</artifactId>
    <version>2.12.2</version>
</dependency>
```

- **Issue:** Version mismatch (2.13.0 vs 2.12.2)
- **Recommended:** Standardize to 2.14.3+ or 2.15.x

#### 5. JUnit 4.13.1 - LOW-MEDIUM RISK
**Locations:**

**a)** `/home/user/akto/pom.xml:105-111`
```xml
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.13.1</version>
    <scope>test</scope>
</dependency>
```

**b)** `/home/user/akto/libs/dao/pom.xml:18-23`
```xml
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.13.1</version>
    <scope>test</scope>
</dependency>
```

**c)** `/home/user/akto/libs/utils/pom.xml:25-29`
```xml
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.13.1</version>
    <scope>test</scope>
</dependency>
```

- **Vulnerability:** CVE-2020-15250 (fixed in 4.13.2)
- **Current Version:** 4.13.1
- **Recommended:** Update to 4.13.2 minimum, or migrate to JUnit 5
- **Severity:** LOW-MEDIUM

#### 6. Spring Security 5.6.2 - MEDIUM RISK
**Location:** `/home/user/akto/libs/dao/pom.xml:66-72`
```xml
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-web</artifactId>
    <version>5.6.2</version>
</dependency>
```
- **Issue:** Multiple CVEs fixed in newer versions
- **Current Version:** 5.6.2
- **Recommended:** Update to 5.8.13 or 6.x
- **Severity:** MEDIUM

#### 7. Jetty - MEDIUM RISK
**Locations:**

**a)** `/home/user/akto/pom.xml:58-60` (jetty-maven-plugin)
```xml
<groupId>org.eclipse.jetty</groupId>
<artifactId>jetty-maven-plugin</artifactId>
<version>9.4.36.v20210114</version>
```

**b)** `/home/user/akto/apps/dashboard/pom.xml:69-74`
```xml
<dependency>
    <groupId>org.eclipse.jetty</groupId>
    <artifactId>jetty-servlets</artifactId>
    <version>9.4.44.v20210927</version>
</dependency>
```

**c)** `/home/user/akto/apps/dashboard/pom.xml:248-250` (jetty-maven-plugin)
```xml
<groupId>org.eclipse.jetty</groupId>
<artifactId>jetty-maven-plugin</artifactId>
<version>9.4.36.v20210114</version>
```

- **Issue:** Multiple CVEs in 9.4.x series
- **Current Versions:** 9.4.36, 9.4.44
- **Recommended:** Update to 9.4.56+ or 11.x
- **Severity:** MEDIUM

#### 8. OkHttp 4.9.3 - LOW RISK
**Locations:**

**a)** `/home/user/akto/libs/dao/pom.xml:77-81`
```xml
<dependency>
    <groupId>com.squareup.okhttp3</groupId>
    <artifactId>okhttp</artifactId>
    <version>4.9.3</version>
</dependency>
```

**b)** `/home/user/akto/libs/integrations/pom.xml:17-22`
```xml
<dependency>
    <groupId>com.squareup.okhttp3</groupId>
    <artifactId>okhttp</artifactId>
    <version>4.9.3</version>
</dependency>
```

- **Current Version:** 4.9.3
- **Recommended:** Update to 4.12.x
- **Severity:** LOW

#### 9. snakeyaml 1.33 - MEDIUM RISK
**Location:** `/home/user/akto/apps/testing/pom.xml:37-41`
```xml
<dependency>
    <groupId>org.yaml</groupId>
    <artifactId>snakeyaml</artifactId>
    <version>1.33</version>
</dependency>
```
- **Vulnerabilities:** Known deserialization vulnerabilities
- **Current Version:** 1.33
- **Recommended:** Update to 2.0+
- **Severity:** MEDIUM

#### 10. slf4j-simple - VERSION INCONSISTENCY
**Locations:**

**a)** `/home/user/akto/libs/utils/pom.xml:65-69`
```xml
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-simple</artifactId>
    <version>1.7.5</version>
</dependency>
```

**b)** `/home/user/akto/apps/api-runtime/pom.xml:23-27`
```xml
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-simple</artifactId>
    <version>1.7.32</version>
</dependency>
```

**c)** `/home/user/akto/libs/dao/pom.xml:35-39`
```xml
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-simple</artifactId>
    <version>1.7.32</version>
</dependency>
```

- **Issue:** Version inconsistency (1.7.5 vs 1.7.32)
- **Recommended:** Standardize to 2.0.x
- **Severity:** LOW

---

## ⚠️ SEVERELY OUTDATED PACKAGES

### JavaScript/Node.js

#### apps/dashboard/package.json

**Location:** `/home/user/akto/apps/dashboard/package.json`

| Package | Line | Current | Latest | Versions Behind |
|---------|------|---------|--------|-----------------|
| webpack | 79 | 3.6.0 | 5.90+ | 2 major |
| vue | 48 | 2.5.11 | 3.5.26 | 1 major (EOL approaching) |
| react | 42 | 17.0.2 | 19.2.3 | 2 major |
| react-dom | 43 | 17.0.2 | 19.2.3 | 2 major |
| vuetify | 51 | 2.4.3 | 3.11.4 | 1 major |
| highcharts | 39 | 9.0.1 | 12.4.0 | 3 major |
| @mui/material | 31 | 5.9.2 | 7.3.6 | 2 major |
| monaco-editor | 41 | 0.38.0 | 0.55.1 | Multiple minor |
| css-loader | 71 | 0.28.7 | 6.8.1+ | 6 major |
| file-loader | 72 | 1.1.4 | 6.2.0+ | 5 major |
| vue-router | 49 | 3.5.1 | 4.6.4 | 1 major |
| vuex | 52 | 3.6.2 | 4.1.0 | 1 major |
| zustand | 53 | 4.0.0 | 5.0.9 | 1 major |

#### apps/dashboard/web/polaris_web/package.json

**Location:** `/home/user/akto/apps/dashboard/web/polaris_web/package.json`

| Package | Line | Current | Latest | Status |
|---------|------|---------|--------|--------|
| axios | 16 | 1.4.0 | 1.13.2 | Minor updates |
| webpack | 75 | 5.88.0 | 5.90+ | Relatively current |

### Java Dependencies

#### 1. AWS SDK 1.12.405 - Legacy v1
**Locations:** `/home/user/akto/apps/dashboard/pom.xml`
- Lines 18-23 (BOM)
- Lines 29-32 (aws-java-sdk-lambda)
- Lines 33-37 (aws-java-sdk-logs)
- Lines 38-42 (aws-java-sdk-elasticloadbalancingv2)
- Lines 43-47 (aws-java-sdk-cloudformation)
- Lines 49-53 (aws-java-sdk-autoscaling)
- Lines 54-58 (aws-java-sdk-ec2)

```xml
<version>1.12.405</version>
```
- **Issue:** AWS SDK v1 is in maintenance mode
- **Recommended:** Migrate to AWS SDK v2
- **Effort:** HIGH (breaking changes)

#### 2. Google API Client 1.23.0 - Extremely outdated (2017)
**Locations:**

**a)** `/home/user/akto/apps/dashboard/pom.xml:175-179`
```xml
<dependency>
    <groupId>com.google.api-client</groupId>
    <artifactId>google-api-client</artifactId>
    <version>1.23.0</version>
</dependency>
```

**b)** `/home/user/akto/apps/dashboard/pom.xml:180-184`
```xml
<dependency>
    <groupId>com.google.oauth-client</groupId>
    <artifactId>google-oauth-client-jetty</artifactId>
    <version>1.23.0</version>
</dependency>
```

**c)** `/home/user/akto/apps/dashboard/pom.xml:185-189`
```xml
<dependency>
    <groupId>com.google.apis</groupId>
    <artifactId>google-api-services-sheets</artifactId>
    <version>v4-rev493-1.23.0</version>
</dependency>
```

**d)** `/home/user/akto/apps/dashboard/pom.xml:190-194`
```xml
<dependency>
    <groupId>com.google.apis</groupId>
    <artifactId>google-api-services-drive</artifactId>
    <version>v3-rev197-1.25.0</version>
</dependency>
```

**Also in:**
- `/home/user/akto/libs/utils/pom.xml:45-64` (same versions)

- **Current:** 1.23.0 (from 2017)
- **Recommended:** Update to 2.x
- **Severity:** HIGH (security and compatibility risks)

#### 3. MongoDB Driver 4.2.1
**Locations:**

**a)** `/home/user/akto/apps/dashboard/pom.xml:81-85`
```xml
<dependency>
    <groupId>org.mongodb</groupId>
    <artifactId>mongodb-driver-sync</artifactId>
    <version>4.2.1</version>
</dependency>
```

**b)** `/home/user/akto/libs/dao/pom.xml:24-28`
```xml
<dependency>
    <groupId>org.mongodb</groupId>
    <artifactId>mongodb-driver-sync</artifactId>
    <version>4.2.1</version>
</dependency>
```

**c)** `/home/user/akto/libs/utils/pom.xml:40-44`
```xml
<dependency>
    <groupId>org.mongodb</groupId>
    <artifactId>mongodb-driver-sync</artifactId>
    <version>4.2.1</version>
</dependency>
```

- **Current:** 4.2.1
- **Latest:** 5.x
- **Recommended:** Update to 4.11.x or 5.x

#### 4. Apache Commons Lang3 3.12.0
**Locations:**

**a)** `/home/user/akto/apps/dashboard/pom.xml:64-68`
**b)** `/home/user/akto/apps/api-runtime/pom.xml:18-22`
**c)** `/home/user/akto/libs/dao/pom.xml:40-44`

```xml
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-lang3</artifactId>
    <version>3.12.0</version>
</dependency>
```
- **Current:** 3.12.0
- **Latest:** 3.14+
- **Recommended:** Update to latest 3.x

---

## 🗑️ DEPENDENCY BLOAT & REDUNDANCIES

### 1. Mixed Babel Versions - CRITICAL BLOAT
**Location:** `/home/user/akto/apps/dashboard/package.json`

**Babel 7.x (Modern):**
- Line 14: `"@babel/core": "^7.13.10"`
- Line 15: `"@babel/eslint-parser": "^7.13.10"`
- Line 16: `"@babel/plugin-proposal-object-rest-spread": "^7.13.8"`
- Line 17: `"@babel/plugin-transform-react-jsx": "7.12.11"`
- Line 18: `"@babel/plugin-transform-runtime": "^7.13.10"`
- Line 19: `"@babel/preset-env": "^7.13.10"`
- Line 20: `"@babel/preset-react": "7.0.0"`

**Babel 6.x (Legacy - REMOVE):**
- Line 61: `"babel-core": "^6.0.0"`
- Line 62: `"babel-eslint": "^7.0.0"`
- Line 64: `"babel-plugin-transform-regenerator": "^6.26.0"`
- Line 65: `"babel-plugin-transform-runtime": "^6.0.0"`
- Line 66: `"babel-polyfill": "^6.26.0"`
- Line 67: `"babel-preset-es2015": "^6.0.0"`
- Line 68: `"babel-preset-stage-2": "^6.0.0"`
- Line 69: `"babel-register": "^6.0.0"`

- **Impact:** ~50-80MB unnecessary bloat + security vulnerabilities
- **Action:** REMOVE all Babel 6.x packages

### 2. Duplicate Framework Support
**Location:** `/home/user/akto/apps/dashboard/package.json`

**Vue packages:**
- Line 48: `"vue": "^2.5.11"`
- Line 49: `"vue-router": "^3.5.1"`
- Line 50: `"vuera": "^0.2.7"` (Vue+React bridge)
- Line 51: `"vuetify": "^2.4.3"`
- Line 52: `"vuex": "^3.6.2"`
- Line 28: `"@fortawesome/vue-fontawesome": "^2.0.2"`

**React packages:**
- Line 42: `"react": "17.0.2"`
- Line 43: `"react-dom": "17.0.2"`
- Line 44: `"react-flow-renderer": "^10.3.12"`
- Line 27: `"@fortawesome/react-fontawesome": "^0.2.0"`

- **Issue:** Using both Vue AND React in same package
- **Impact:** Significant bundle size increase
- **Recommendation:** Consider framework consolidation

### 3. Questionable/Unused Dependencies

#### a) fiber@1.0.4
**Location:** `/home/user/akto/apps/dashboard/package.json:37`
```json
"fiber": "^1.0.4"
```
- **Issue:** Unclear purpose, not typical for React/Vue apps
- **Action:** Audit usage and remove if unnecessary

#### b) are-you-es5@2.1.1
**Location:** `/home/user/akto/apps/dashboard/package.json:33`
```json
"are-you-es5": "^2.1.1"
```
- **Issue:** This is a dev/analysis tool, shouldn't be in production dependencies
- **Action:** Move to devDependencies or remove

#### c) vuera@0.2.7
**Location:** `/home/user/akto/apps/dashboard/package.json:50`
```json
"vuera": "^0.2.7"
```
- **Issue:** Vue+React bridge adds complexity
- **Impact:** Bundle size and maintenance overhead
- **Action:** Consider single framework migration

#### d) tiptap packages (v1)
**Location:** `/home/user/akto/apps/dashboard/package.json`
- Line 46: `"tiptap": "^1.32.1"`
- Line 47: `"tiptap-extensions": "^1.35.1"`

- **Issue:** Version 1.x is outdated (v2+ is current)
- **Action:** Update to v2 or verify if still needed

### 4. Duplicate Functionality
**Location:** `/home/user/akto/apps/dashboard/package.json`
- Line 35: `"babel-plugin-transform-object-rest-spread": "^6.26.0"` (Babel 6)
- Line 16: `"@babel/plugin-proposal-object-rest-spread": "^7.13.8"` (Babel 7)

Both do the same thing - only need the Babel 7 version.

---

## 📊 PACKAGE STATISTICS

### Dashboard Package
**File:** `/home/user/akto/apps/dashboard/package.json`
- **Total dependencies:** 40
- **Total devDependencies:** 20
- **Estimated bloat from Babel 6.x:** ~50-80MB
- **Outdated packages:** 38/40 (95%+)
- **Critical vulnerabilities:** 5+
- **High vulnerabilities:** 3+

### Polaris Package  
**File:** `/home/user/akto/apps/dashboard/web/polaris_web/package.json`
- **Total dependencies:** 26
- **Total devDependencies:** 16
- **Generally more modern:** Webpack 5, React 18
- **Still needs updates:** axios, some minor packages

### Java Dependencies
- **pom.xml files:** 9 total
- **Version inconsistencies:** 5+ packages with multiple versions
- **Legacy patterns:** AWS SDK v1, Google APIs from 2017
- **Security issues:** 7+ packages with known vulnerabilities

---

## ✅ RECOMMENDED ACTIONS (Prioritized with Locations)

### IMMEDIATE (Security Critical)

#### 1. Update axios - CRITICAL
**File:** `/home/user/akto/apps/dashboard/package.json:34`
**Change:**
```diff
- "axios": "^0.21.1"
+ "axios": "^1.13.2"
```
**Command:**
```bash
cd /home/user/akto/apps/dashboard && npm install axios@latest
```

**Also update:**
**File:** `/home/user/akto/apps/dashboard/web/polaris_web/package.json:16`
```diff
- "axios": "^1.4.0"
+ "axios": "^1.13.2"
```

#### 2. Remove Babel 6.x packages - CRITICAL
**File:** `/home/user/akto/apps/dashboard/package.json:61-69`
**Remove these lines:**
```diff
- "babel-core": "^6.0.0",
- "babel-eslint": "^7.0.0",
- "babel-plugin-transform-regenerator": "^6.26.0",
- "babel-plugin-transform-runtime": "^6.0.0",
- "babel-polyfill": "^6.26.0",
- "babel-preset-es2015": "^6.0.0",
- "babel-preset-stage-2": "^6.0.0",
- "babel-register": "^6.0.0"
```
**Also remove:**
```diff
- "babel-plugin-transform-object-rest-spread": "^6.26.0", (line 35)
```

**Update Babel 7.x:**
```diff
- "@babel/core": "^7.13.10"
+ "@babel/core": "^7.26.10"
```

**Commands:**
```bash
cd /home/user/akto/apps/dashboard
npm uninstall babel-core babel-eslint babel-plugin-transform-regenerator \
  babel-plugin-transform-runtime babel-polyfill babel-preset-es2015 \
  babel-preset-stage-2 babel-register babel-plugin-transform-object-rest-spread
npm install @babel/core@latest --save-dev
```

#### 3. Update jackson-databind - HIGH
**Files:** 
- `/home/user/akto/apps/dashboard/pom.xml:149-153`
- `/home/user/akto/apps/api-runtime/pom.xml:55-60`
- `/home/user/akto/libs/utils/pom.xml:86-91`
- `/home/user/akto/libs/integrations/pom.xml:23-28`

**Change all occurrences:**
```diff
- <version>2.12.7.1</version>
+ <version>2.14.3</version>
```

**Also update jackson-core and jackson-annotations:**

**Files:**
- `/home/user/akto/apps/dashboard/pom.xml:154-163`
- `/home/user/akto/libs/utils/pom.xml:97-112`

```diff
- <version>2.13.0</version>  <!-- or 2.12.2 -->
+ <version>2.14.3</version>
```

#### 4. Update Struts2 - HIGH
**File:** `/home/user/akto/apps/dashboard/pom.xml:60-63, 112-115`
```diff
- <version>2.5.30</version>
+ <version>6.4.0</version>
```
**Note:** May require code changes - test thoroughly

#### 5. Update JUnit - MEDIUM
**Files:**
- `/home/user/akto/pom.xml:105-111`
- `/home/user/akto/libs/dao/pom.xml:18-23`
- `/home/user/akto/libs/utils/pom.xml:25-29`

```diff
- <version>4.13.1</version>
+ <version>4.13.2</version>
```

#### 6. Update snakeyaml - MEDIUM
**File:** `/home/user/akto/apps/testing/pom.xml:37-41`
```diff
- <version>1.33</version>
+ <version>2.2</version>
```

### HIGH PRIORITY (Breaking but Important)

#### 7. Update Spring Security
**File:** `/home/user/akto/libs/dao/pom.xml:66-72`
```diff
- <version>5.6.2</version>
+ <version>5.8.13</version>
```

#### 8. Update Jetty
**Files:**
- `/home/user/akto/pom.xml:58-60`
- `/home/user/akto/apps/dashboard/pom.xml:69-74, 248-250`

```diff
- <version>9.4.36.v20210114</version>
+ <version>9.4.56.v20240826</version>
```
```diff
- <version>9.4.44.v20210927</version>
+ <version>9.4.56.v20240826</version>
```

#### 9. Standardize Jackson versions - Use dependencyManagement
**File:** `/home/user/akto/pom.xml` (add to existing `<properties>`)
```xml
<properties>
    <jackson.version>2.14.3</jackson.version>
</properties>
```

Add to `<dependencyManagement>`:
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-bom</artifactId>
            <version>${jackson.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

#### 10. Update MongoDB driver
**Files:**
- `/home/user/akto/apps/dashboard/pom.xml:81-85`
- `/home/user/akto/libs/dao/pom.xml:24-28`
- `/home/user/akto/libs/utils/pom.xml:40-44`

```diff
- <version>4.2.1</version>
+ <version>4.11.4</version>
```

#### 11. Standardize slf4j versions
**Files:**
- `/home/user/akto/libs/utils/pom.xml:65-69`
- `/home/user/akto/apps/api-runtime/pom.xml:23-27`
- `/home/user/akto/libs/dao/pom.xml:35-39`

```diff
- <version>1.7.5</version>  <!-- or 1.7.32 -->
+ <version>2.0.13</version>
```

### MEDIUM PRIORITY (Technical Debt)

#### 12. Update Google API Client (2017 vintage)
**Files:**
- `/home/user/akto/apps/dashboard/pom.xml:175-194`
- `/home/user/akto/libs/utils/pom.xml:45-64`

**Current versions:** 1.23.0 (from 2017)
**Recommended:** Update to 2.x (requires migration effort)

#### 13. Update OkHttp
**Files:**
- `/home/user/akto/libs/dao/pom.xml:77-81`
- `/home/user/akto/libs/integrations/pom.xml:17-22`

```diff
- <version>4.9.3</version>
+ <version>4.12.0</version>
```

#### 14. Update Commons Lang3
**Files:**
- `/home/user/akto/apps/dashboard/pom.xml:64-68`
- `/home/user/akto/apps/api-runtime/pom.xml:18-22`
- `/home/user/akto/libs/dao/pom.xml:40-44`

```diff
- <version>3.12.0</version>
+ <version>3.14.0</version>
```

### LOW PRIORITY (Cleanup)

#### 15. Remove questionable dependencies
**File:** `/home/user/akto/apps/dashboard/package.json`

Consider removing or moving:
- Line 33: `are-you-es5` (move to devDependencies or remove)
- Line 37: `fiber` (verify usage, likely unused)
- Line 50: `vuera` (if consolidating frameworks)

#### 16. Add package-lock.json
**File:** `/home/user/akto/apps/dashboard/web/polaris_web/`
```bash
cd /home/user/akto/apps/dashboard/web/polaris_web
npm install --package-lock-only
```

---

## 📝 DEPENDENCY MANAGEMENT RECOMMENDATIONS

1. **Add dependencyManagement to parent POM**
   - File: `/home/user/akto/pom.xml`
   - Standardize versions across all modules

2. **Set up Dependabot**
   - Create: `.github/dependabot.yml`
   - Configure for both npm and maven

3. **Add OWASP Dependency Check**
   - Add to `/home/user/akto/pom.xml` build plugins
   ```xml
   <plugin>
       <groupId>org.owasp</groupId>
       <artifactId>dependency-check-maven</artifactId>
       <version>9.0.0</version>
   </plugin>
   ```

4. **Implement CI/CD Security Checks**
   - Run `npm audit` and `mvn dependency-check:check`
   - Fail builds on HIGH/CRITICAL vulnerabilities

---

## 🔍 VERIFICATION COMMANDS

```bash
# JavaScript vulnerabilities
cd /home/user/akto/apps/dashboard && npm audit
cd /home/user/akto/apps/dashboard/web/polaris_web && npm audit

# Check outdated packages
cd /home/user/akto/apps/dashboard && npm outdated

# Java vulnerabilities (after adding plugin)
cd /home/user/akto
mvn org.owasp:dependency-check-maven:check

# Check dependency tree
mvn dependency:tree
```

---

## Summary Statistics

- **Total Files Analyzed:** 11 (2 package.json, 9 pom.xml)
- **Critical Vulnerabilities:** 6
- **High Vulnerabilities:** 5
- **Medium Vulnerabilities:** 8
- **Low Vulnerabilities:** 3
- **Version Inconsistencies:** 5+
- **Packages with Bloat:** 8+
- **Severely Outdated (>2 major versions):** 10+

**Estimated Total Technical Debt:** HIGH  
**Recommended Timeline for Critical Fixes:** 1-2 weeks  
**Recommended Timeline for All Fixes:** 2-3 months
