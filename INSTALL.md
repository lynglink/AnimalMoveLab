### Install and Run: Animal MoveLab

This guide walks you through installing dependencies, installing R packages, and running the Shiny/Golem app.

---

### 1) Prerequisites

- R (version 4.2 or newer recommended)
- Internet access to install R packages from CRAN
- System dependencies for geospatial R packages (`sf`, `terra`)

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
  libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
  libtiff-dev libsqlite3-dev libcurl4-openssl-dev libxml2-dev \
  build-essential
```

#### macOS (Homebrew)
```bash
# Install Homebrew if needed: https://brew.sh/
brew update
brew install gdal geos proj udunits libtiff sqlite
```

#### Windows
- Install R from CRAN: `https://cran.r-project.org/`
- (Recommended) Install RTools: `https://cran.r-project.org/bin/windows/Rtools/`
- CRAN provides binary builds for `sf` and `terra` on Windows; system libraries are not usually required.

---

### 2) Get the source code
```bash
# Using SSH or HTTPS (pick one)
git clone <your-repo-url>
cd <your-repo-folder>
```

---

### 3) Install required R packages

Start R in the project root, then run:

```r
# Use a CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

install.packages(c(
  "devtools",   # for install/test/develop
  "golem",      # app framework
  "shiny",
  "ggplot2",
  "sf",
  "yaml",
  "terra",
  "adehabitatHR",
  "sp",
  "ctmm",
  "DT",
  "amt",
  "config"
))
```

If you prefer `pak`, you can do:
```r
install.packages("pak")
pak::pak(c(
  "devtools","golem","shiny","ggplot2","sf","yaml","terra",
  "adehabitatHR","sp","ctmm","DT","amt","config"
))
```

---

### 4) Run the app (development)

From the project root in R:
```r
# Option A: Document/reload, then run (recommended during development)
source("dev/run_dev.R")
```

Or explicitly:
```r
devtools::load_all(".")
animal.movement.analysis::run_app()
```

---

### 5) Run the app (installed package)

Install the package, then launch:
```r
devtools::install(".")
library(animal.movement.analysis)
run_app(options = list(host = "0.0.0.0", port = 8080))
```

---

### 6) Running tests

```r
# From the project root
devtools::test()
```

---

### 7) Troubleshooting

- "sf/terra failed to compile" on Linux/macOS: ensure GDAL/GEOS/PROJ/UDUNITS are installed (see prerequisites) and that headers are discoverable in your environment (e.g., `/usr/include`, Homebrew paths).
- If R cannot find system libraries, you may need to set environment variables like `PKG_CONFIG_PATH` or `PATH` to point to your GDAL/PROJ installations.
- On Windows, prefer CRAN binaries; if build from source is attempted, ensure RTools is installed and on PATH.

---

### 8) What to run
- Development: `source("dev/run_dev.R")`
- Installed package: `library(animal.movement.analysis); run_app()`