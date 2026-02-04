genFlowline — Generate a labelled flowchart line in a variable

Syntax
    genFlowline varname, text(string) CRITerion(string) [new] [SAMEline]

Short description
    Populate (or create) a string variable with a flowchart-style label
    "<flow-number>: <text>" for observations that satisfy a logical criterion.
    Maintains two globals to track the current flow number and the most
    recent flow text: `gl_flowline' and `gl_flowtxt'.

Description
    genFlowline evaluates the supplied CRITerion() expression for each
    observation. For observations where the criterion is true and the
    target variable equals "OK" (or was just created), the command
    replaces that observation's value with a label consisting of the
    current flow number and the provided text.

    Globals used/updated:
    - gl_flowline: numeric identifier for the current flow line. If the
      option `new' is specified the command creates/initializes the
      target variable and sets gl_flowline to 100. By default (when
      `SAMEline' is not used) each call increments gl_flowline by 1.
    - gl_flowtxt: stores the most recently used flow text.

Options
    text(string)      Required. The text to use for the flow label.
    CRITerion(string) Required. Logical expression evaluated per
                      observation (e.g., `x==1' or `_n==1').
    new               Optional. Create the variable (dropping any
                      existing variable with that name), initialize it
                      to "OK", and reset gl_flowline to 100.
    SAMEline          Optional. Do not advance the flow number; append
                      the new text to the previous flow text so that the
                      label remains on the same flow line.

Notes
    - The command expects a string variable name as the first (positional)
      argument (anything). If you use `new' the variable is created for you.
    - The CRITerion() argument should be a valid Stata expression (no
      surrounding quotes in typical use).
    - Option names are case-insensitive.
    - The program modifies globals gl_flowline and gl_flowtxt; if you
      rely on their values elsewhere, take care or reset them as needed.

Examples
    * Create a new flow variable and mark the first line
    genFlowline flow, text("Start") CRITerion(_n==1) new

    * Add another flow line for observations where x==1
    genFlowline flow, text("Choice A") CRITerion(x==1)

    * Append text to the same flow line
    genFlowline flow, text("continued") CRITerion(x==1) SAMEline

Author
    Flemming Skj�th
    (original: 21 Jun 2017)

See also
    generate, replace
