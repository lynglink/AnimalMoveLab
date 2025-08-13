# Load the package
devtools::load_all()
# Run the tests
testthat::test_package("tests/testthat")
