#' Run covr on a package and upload the result to codecov.io
#' @param coverage an existing coverage object to submit, if \code{NULL},
#' \code{\link{package_coverage}} will be called with the arguments from
#' \code{...}
#' @param ... arguments passed to \code{\link{package_coverage}}
#' @param base_url Codecov url (change for Enterprise)
#' @param quiet if \code{FALSE}, print the coverage before submission.
#' @export
#' @examples
#' \dontrun{
#' codecov(path = "test")
#' }
codecov <- function(...,
                    coverage = NULL,
                    base_url = "https://codecov.io",
                    quiet = TRUE) {

  if (is.null(coverage)) {
    coverage <- package_coverage(...)
  }

  if (!quiet) {
    print(coverage)
  }

  # -------
  # Jenkins
  # -------
  if (Sys.getenv("JENKINS_URL") != "") {
    # https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project
    # path <- Sys.getenv("WORKSPACE")
    codecov_url <- paste0(base_url, "/upload/v2?service=jenkins") # nolint
    codecov_query <- list(branch = Sys.getenv("GIT_BRANCH"),
                          commit = Sys.getenv("GIT_COMMIT"),
                          build = Sys.getenv("BUILD_NUMBER"),
                          build_url = Sys.getenv("BUILD_URL"))
  # ---------
  # Travis CI
  # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("TRAVIS") == "true") {
    # http://docs.travis-ci.com/user/ci-environment/#Environment-variables
    # path <- Sys.getenv("TRAVIS_BUILD_DIR")
    pr <- ifelse(Sys.getenv("TRAVIS_PULL_REQUEST") != "false", Sys.getenv("TRAVIS_PULL_REQUEST"), "")
    codecov_url <- paste0(base_url, "/upload/v2?service=travis-org") # nolint
    slug_info <- strsplit(Sys.getenv("TRAVIS_REPO_SLUG"), "/")[[1]]
    codecov_query <- list(branch = Sys.getenv("TRAVIS_BRANCH"),
                          build = Sys.getenv("TRAVIS_JOB_NUMBER"),
                          pull_request = pr,
                          travis_job_id = Sys.getenv("TRAVIS_JOB_ID"),
                          owner = slug_info[1],
                          repo = slug_info[2],
                          commit = Sys.getenv("TRAVIS_COMMIT"))
  # --------
  # Codeship
  # --------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("CI_NAME") == "codeship") {
    # https://www.codeship.io/documentation/continuous-integration/set-environment-variables/
    codecov_url <- paste0(base_url, "/upload/v2?service=codeship") # nolint
    codecov_query <- list(branch = Sys.getenv("CI_BRANCH"),
                          build = Sys.getenv("CI_BUILD_NUMBER"),
                          build_url = Sys.getenv("CI_BUILD_URL"),
                          commit = Sys.getenv("CI_COMMIT_ID"))
  # ---------
  # Circle CI
  # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("CIRCLECI") == "true") {
    # https://circleci.com/docs/environment-variables
    codecov_url <- paste0(base_url, "/upload/v2?service=circleci") # nolint
    codecov_query <- list(branch = Sys.getenv("CIRCLE_BRANCH"),
                          build = Sys.getenv("CIRCLE_BUILD_NUM"),
                          owner = Sys.getenv("CIRCLE_PROJECT_USERNAME"),
                          repo = Sys.getenv("CIRCLE_PROJECT_REPONAME"),
                          commit = Sys.getenv("CIRCLE_SHA1"))
  # ---------
  # Semaphore
  # ---------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("SEMAPHORE") == "true") {
    # https://semaphoreapp.com/docs/available-environment-variables.html
    codecov_url <- paste0(base_url, "/upload/v2?service=semaphore") # nolint
    slug_info <- strsplit(Sys.getenv("SEMAPHORE_REPO_SLUG"), "/")[[1]]
    codecov_query <- list(branch = Sys.getenv("BRANCH_NAME"),
                          build = Sys.getenv("SEMAPHORE_BUILD_NUMBER"),
                          owner = slug_info[1],
                          repo = slug_info[2],
                          commit = Sys.getenv("REVISION"))
  # --------
  # drone.io
  # --------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("DRONE") == "true") {
    # http://docs.drone.io/env.html
    codecov_url <- paste0(base_url, "/upload/v2?service=drone.io") # nolint
    codecov_query <- list(branch = Sys.getenv("DRONE_BRANCH"),
                          build = Sys.getenv("DRONE_BUILD_NUMBER"),
                          build_url = Sys.getenv("DRONE_BUILD_URL"),
                          commit = Sys.getenv("DRONE_COMMIT"))
  # --------
  # AppVeyor
  # --------
  } else if (Sys.getenv("CI") == "True" && Sys.getenv("APPVEYOR") == "True") {
    # http://www.appveyor.com/docs/environment-variables
    codecov_url <- paste0(base_url, "/upload/v2?service=AppVeyor") # nolint
    name_info <- strsplit(Sys.getenv("APPVEYOR_REPO_NAME"), "/")[[1]]
    codecov_query <- list(branch = Sys.getenv("APPVEYOR_REPO_BRANCH"),
                          build = Sys.getenv("APPVEYOR_BUILD_NUMBER"),
                          owner = name_info[1],
                          repo = name_info[2],
                          commit = Sys.getenv("APPVEYOR_REPO_COMMIT"))
  # -------
  # Wercker
  # -------
  } else if (Sys.getenv("CI") == "true" && Sys.getenv("WERCKER_GIT_BRANCH") != "") {
    # http://devcenter.wercker.com/articles/steps/variables.html
    codecov_url <- paste0(base_url, "/upload/v2?service=wercker") # nolint
    codecov_query <- list(branch = Sys.getenv("WERCKER_GIT_BRANCH"),
                          build = Sys.getenv("WERCKER_MAIN_PIPELINE_STARTED"),
                          owner = Sys.getenv("WERCKER_GIT_OWNER"),
                          repo = Sys.getenv("WERCKER_GIT_REPOSITORY"),
                          commit = Sys.getenv("WERCKER_GIT_COMMIT"))
  # ---------
  # Local GIT
  # ---------
  } else {
    codecov_url <- paste0(base_url, "/upload/v2") # nolint
    codecov_query <- list(branch = local_branch(),
                          commit = current_commit())
  }

  if (Sys.getenv("CODECOV_TOKEN") != "") {
    codecov_query$token <- Sys.getenv("CODECOV_TOKEN")
  }

  coverage_json <- to_codecov(coverage)

  httr::content(httr::POST(url = codecov_url, query = codecov_query, body = coverage_json, encode = "json"))
}

to_codecov <- function(x) {
  coverages <- unname(lapply(per_line(x),
    function(xx) {
      xx$coverage <- c(NA, xx$coverage)
      xx
    }))

  res <- lapply(coverages,
    function(coverage) {
      list(
        "name" = jsonlite::unbox(display_name(coverage)),
        "coverage" = coverage$coverage
      )
    })

  jsonlite::toJSON(na = "null", list("files" = res, "uploader" = jsonlite::unbox("R")))
}
