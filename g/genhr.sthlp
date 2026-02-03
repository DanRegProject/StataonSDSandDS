genHR — Generate Cox proportional-hazards hazard-ratio (HR) summaries

Syntax
    genHR [iweight aweight pweight fweight] [if] , ///
        ENDPoints(string) at(numlist) Origin(string) Enter(string) Scale(string) EXPosure(string) ///
        [SAVing(string) label(string) id(string) coxopt(string) ADJust(string) ref(string) ///
         show append estore elabel(string) postest(string) headlev(string) assumption]

Short description
    Run Cox (stcox) models for one or more endpoints and follow-up times and
    produce/store a concise table of hazard ratios (HRs) for the exposure
    levels. Optionally saves HR results to a dataset, stores estimates, and
    checks the proportional-hazards assumption with stphplot/estat phtest.

Required options
    ENDPoints(string)   Name root of endpoint variables. genHR expects variables
                        named `endpoint'EndDate and `endpoint'Status for each
                        endpoint listed. Provide endpoint names as a string.
    at(numlist)         Follow-up times (in the same units as Scale) at which
                        to set exit times (e.g., at(1 5)).
    Origin(string)      Variable (or expression) providing the origin time for
                        stset (e.g., birth date).
    Enter(string)       Variable (or expression) for enter() in stset.
    Scale(string)       Time scaling used in stset (e.g., 365.25 for years).
    EXPosure(string)    Exposure or covariates of interest (one or more
                        variables). If a categorical exposure has a reference
                        category, use ref() to indicate it.

Main optional options
    SAVing(string)      Path/filename of a Stata dataset to append/store a
                        one-row-per-level table of HRs (creates or appends).
    label(string)       Short label to identify the analysis when saved.
    id(string)          id() specification passed to stset (cluster/subject id).
    coxopt(string)      Additional options passed to stcox (default: "nolog noshow").
    ADJust(string)      Adjustment variables (covariates) to include in the model.
    ref(string)         Reference level for ib# coding when exposure is a factor
                        (default: 1). When single exposure, genHR uses ib`ref'.
    show                Request progress and example output to be printed.
    append              When saving, append to existing SAVing file instead of overwriting.
    estore              Store estimates (uses elabel or label to name stored estimates).
    elabel(string)      Label to use for estimates storage (overrides label).
    postest(string)     Post-estimation expressions to evaluate (pipe-separated).
    headlev(string)     Prefix text printed before model output headings.
    assumption          When specified, genHR runs proportional-hazards checks
                        (stphplot and estat phtest) and exports PH diagnostic graphs.

Description
    genHR automates repeated stcox analyses across one or multiple endpoints
    and across a list of follow-up times (the at() list). For each combination
    it:
      - stsets the data with origin(), enter(), scale(), and an exit time set
        to origin + at*scale,
      - fits stcox for the specified exposure and adjustment covariates,
      - (optionally) checks proportional-hazards assumption and exports plots,
      - (optionally) computes level-specific HR, confidence bounds and p-values
        and saves these to the dataset named by SAVing(),
      - (optionally) stores estimates using estimates store.

Notes and implementation details
    - genHR expects endpoint variables named consistently: `endpoint'EndDate and
      `endpoint'Status for each endpoint provided to ENDPoints().
    - When exposure has multiple levels, genHR performs lincom to obtain HRs
      relative to the chosen reference and saves level labels with levelsof.
    - Low-event results (fewer than 5 events) are suppressed from display.
    - Graphs produced by the assumption option are exported to the working
      output directory (as png/eps) and filenames include endpoint, follow-up
      time and exposure name.

Examples
    * Single endpoint, 1- and 5-year follow-up, exposure sex, adjust for age:
    . genHR, endpoints("Cardio") at(1 5) origin(dob) enter(enrolldate) scale(365.25) ///
        exposure(sex) adjust(age) saving("hr_cardio.dta") label("Sex effect")

    * Multiple exposures and store estimates:
    . genHR, endpoints("Cancer") at(3) origin(birthdate) enter(entrydate) scale(365.25) ///
        exposure(smoking bmi) adjust(age i.sex) estore elabel("CancerModel")

Author
    Adapted/packaged for this repo. Original ado authored by Flemming Skjøth.

See also
    stset, stcox, stphplot, estat phtest, lincom
