# Installation and Usage

This guide describes how to set up and run the Animal MoveLab application using RStudio.

## Prerequisites

- An installation of R (version 4.3.3 or higher).
- RStudio Desktop.
- Git command-line tools.

## 1. Clone the Repository

First, clone this repository to your local machine.

You can do this using the `git clone` command in your terminal:

```bash
git clone https://github.com/lynglink/AnimalMoveLab
cd AnimalMoveLab
```

Alternatively, you can create a new project from version control within RStudio:
1.  Go to `File > New Project > Version Control > Git`.
2.  Enter `https://github.com/lynglink/AnimalMoveLab` in the "Repository URL" field.
3.  Choose a local directory to store the project.
4.  Click "Create Project".

## 2. Install Dependencies

This project uses a standard R package structure. All required packages are listed in the `DESCRIPTION` file. To install them, open the project in RStudio and run the following command in the console:

```R
# Installs the 'remotes' package if you don't have it
if (!require("remotes")) {
  install.packages("remotes")
}

# Installs all package dependencies from the DESCRIPTION file
remotes::install_deps(dependencies = TRUE)
```

This command will read the `Imports` and `Suggests` fields in the `DESCRIPTION` file and install all necessary packages.

## 3. Run the Application

Once the dependencies are installed, you can run the Shiny application. Execute the following command in the RStudio console:

```R
run_app()
```

The Animal MoveLab application should now launch in a new window or in the RStudio Viewer pane.
