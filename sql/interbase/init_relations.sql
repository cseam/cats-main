
CREATE TABLE default_de (
    id          INTEGER NOT NULL PRIMARY KEY,
    code        INTEGER NOT NULL UNIQUE,
    description VARCHAR(200),
    file_ext    VARCHAR(200),
    default_file_ext VARCHAR(200),
    in_contests INTEGER DEFAULT 1 CHECK (in_contests IN (0, 1)),
    in_banks    INTEGER DEFAULT 1 CHECK (in_banks IN (0, 1)),
    in_tsess    INTEGER DEFAULT 1 CHECK (in_tsess IN (0, 1)),
    memory_handicap INTEGER DEFAULT 0,
    err_regexp  VARCHAR(200),
    syntax      VARCHAR(200) /* For highilghter. */
);

CREATE TABLE accounts (
    id               INTEGER NOT NULL PRIMARY KEY,
    login            VARCHAR(50) NOT NULL UNIQUE,
    passwd           VARCHAR(100) DEFAULT '',
    sid              VARCHAR(30),
    srole            INTEGER NOT NULL, /* 0 - root, 1 - user, 2 - can create contests, 4 - can delete messages */
    last_login       TIMESTAMP,
    last_ip          VARCHAR(100) DEFAULT '',
    restrict_ips     VARCHAR(200), /* NULL - unrestricted */
    locked           INTEGER DEFAULT 0 CHECK (locked IN (0, 1)),
    team_name        VARCHAR(200),
    capitan_name     VARCHAR(200),
    git_author_name  VARCHAR(200) DEFAULT NULL,
    country          VARCHAR(30),
    motto            VARCHAR(200),
    email            VARCHAR(200),
    git_author_email VARCHAR(200) DEFAULT NULL,
    home_page        VARCHAR(200),
    icq_number       VARCHAR(200),
    phone            VARCHAR(200),
    settings         BLOB SUB_TYPE 0,
    city             VARCHAR(200),
    affiliation      VARCHAR(200),
    affiliation_year INTEGER
);
CREATE INDEX accounts_sid_idx ON accounts(sid);

CREATE TABLE judges (
    id               INTEGER NOT NULL PRIMARY KEY,
    account_id       INTEGER UNIQUE REFERENCES accounts(id) ON DELETE SET NULL,
    nick             VARCHAR(32) NOT NULL,
    pin_mode         INTEGER DEFAULT 0,
    is_alive         INTEGER DEFAULT 0 CHECK (is_alive IN (0, 1)),
    alive_date       TIMESTAMP
);
ALTER TABLE judges ADD CONSTRAINT chk_judge_pin_mode
    CHECK (pin_mode IN (0, 1, 2, 3));

CREATE TABLE judge_de_bitmap_cache (
    judge_id    INTEGER NOT NULL UNIQUE REFERENCES judges(id) ON DELETE CASCADE,
    version     INTEGER NOT NULL,
    de_bits1    BIGINT DEFAULT 0,
    de_bits2    BIGINT DEFAULT 0
);

CREATE TABLE contests (
    id            INTEGER NOT NULL PRIMARY KEY,
    title         VARCHAR(200) NOT NULL,
    short_descr   BLOB SUB_TYPE TEXT,
    start_date    TIMESTAMP,
    finish_date   TIMESTAMP,
    freeze_date   TIMESTAMP,
    defreeze_date TIMESTAMP,
    closed        INTEGER DEFAULT 0 CHECK (closed IN (0, 1)),
    is_hidden     SMALLINT DEFAULT 0 CHECK (is_hidden IN (0, 1)),
    penalty       INTEGER,
    ctype         INTEGER, /* 0 -- normal, 1 -- training session */

    is_official   INTEGER DEFAULT 0 CHECK (is_official IN (0, 1)),
    run_all_tests INTEGER DEFAULT 0 CHECK (run_all_tests IN (0, 1)),

    show_all_tests       INTEGER DEFAULT 0 CHECK (show_all_tests IN (0, 1)),
    show_test_resources  INTEGER DEFAULT 0 CHECK (show_test_resources IN (0, 1)),
    show_checker_comment INTEGER DEFAULT 0 CHECK (show_checker_comment IN (0, 1)),
    show_packages        INTEGER DEFAULT 0 CHECK (show_packages IN (0, 1)),
    show_all_results     SMALLINT DEFAULT 1 NOT NULL CHECK (show_all_results IN (0, 1)),
    rules                INTEGER DEFAULT 0, /* 0 - ACM, 1 - school */
    local_only           SMALLINT DEFAULT 0 CHECK (local_only IN (0, 1)),
    show_flags           SMALLINT DEFAULT 0 CHECK (show_flags IN (0, 1)),
    /* Maximum requests per participant per problem. */
    max_reqs             INTEGER DEFAULT 0,
    /* TODO: output runs in a frozen table. */
    show_frozen_reqs     SMALLINT DEFAULT 0 CHECK (show_frozen_reqs IN (0, 1)),
    show_test_data       SMALLINT DEFAULT 0 CHECK (show_test_data IN (0, 1)),
    /* 0 - last, 1 - best */
    req_selection        SMALLINT DEFAULT 0 NOT NULL CHECK (req_selection IN (0, 1)),
    pinned_judges_only   SMALLINT DEFAULT 0 NOT NULL,

    CHECK (
        start_date <= finish_date AND freeze_date >= start_date
        AND freeze_date <= finish_date AND defreeze_date >= freeze_date
    )
);
ALTER TABLE contests ADD CONSTRAINT chk_pinned_judges_only
    CHECK (pinned_judges_only IN (0, 1));

CREATE TABLE sites (
    id       INTEGER NOT NULL PRIMARY KEY,
    name     VARCHAR(200) NOT NULL,
    region   VARCHAR(200),
    city     VARCHAR(200),
    org_name VARCHAR(200),
    address  BLOB SUB_TYPE TEXT
);

CREATE TABLE contest_sites (
    contest_id  INTEGER NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
    site_id     INTEGER NOT NULL REFERENCES sites(id),
    diff_time   DOUBLE PRECISION,
    ext_time    DOUBLE PRECISION
);
ALTER TABLE contest_sites
    ADD CONSTRAINT contest_sites_pk PRIMARY KEY (contest_id, site_id);

CREATE TABLE contest_accounts (
    id          INTEGER NOT NULL PRIMARY KEY,
    contest_id  INTEGER NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
    account_id  INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    is_admin    INTEGER DEFAULT 0 CHECK (is_admin IN (0, 1)),
    is_jury     INTEGER DEFAULT 0 CHECK (is_jury IN (0, 1)),
    is_pop      INTEGER DEFAULT 0 CHECK (is_pop IN (0, 1)), /* printer operator */
    is_hidden   INTEGER DEFAULT 0 CHECK (is_hidden IN (0, 1)),
    is_ooc      INTEGER DEFAULT 0 CHECK (is_ooc IN (0, 1)),
    is_remote   INTEGER DEFAULT 0 CHECK (is_remote IN (0, 1)),
    tag         VARCHAR(200),
    is_virtual  INTEGER,
    diff_time   FLOAT,
    ext_time    DOUBLE PRECISION,
    site_id     INTEGER REFERENCES sites(id),
    is_site_org SMALLINT DEFAULT 0 NOT NULL,
    UNIQUE(contest_id, account_id)
);
ALTER TABLE contest_accounts
    ADD CONSTRAINT contest_account_site_org CHECK (is_site_org IN (0, 1));

CREATE TABLE limits (
    id              INTEGER NOT NULL PRIMARY KEY,
    time_limit      FLOAT,
    memory_limit    INTEGER,
    process_limit   INTEGER,
    write_limit     INTEGER,
    save_output_prefix INTEGER
);

CREATE TABLE problems (
    id                 INTEGER NOT NULL PRIMARY KEY,
    contest_id         INTEGER NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
    title              VARCHAR(200) NOT NULL,
    lang               VARCHAR(200) DEFAULT '',
    time_limit         INTEGER DEFAULT 0,
    memory_limit       INTEGER,
    write_limit        INTEGER,
    save_output_prefix INTEGER,
    save_input_prefix  INTEGER,
    save_answer_prefix INTEGER,
    difficulty         INTEGER DEFAULT 100,
    author             VARCHAR(200) DEFAULT '',
    repo               VARCHAR(200) DEFAULT '', /* Default -- based on id. */
    commit_sha         CHAR(40),
    input_file         VARCHAR(200) NOT NULL,
    output_file        VARCHAR(200) NOT NULL,
    upload_date        TIMESTAMP,
    std_checker        VARCHAR(60),
    statement          BLOB,
    explanation        BLOB,
    pconstraints       BLOB,
    input_format       BLOB,
    output_format      BLOB,
    formal_input       BLOB,
    json_data          BLOB,
    zip_archive        BLOB,
    last_modified_by   INTEGER REFERENCES accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
    max_points         INTEGER,
    hash               VARCHAR(200),
    run_method         SMALLINT DEFAULT 0,
    players_count      VARCHAR(200),
    statement_url      VARCHAR(200) DEFAULT '',
    explanation_url    VARCHAR(200) DEFAULT ''
);
ALTER TABLE problems ADD CONSTRAINT chk_run_method CHECK (run_method IN (0, 1, 2));

CREATE TABLE problem_de_bitmap_cache (
    problem_id  INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
    version     INTEGER NOT NULL,
    de_bits1    BIGINT DEFAULT 0,
    de_bits2    BIGINT DEFAULT 0
);

CREATE TABLE contest_problems (
    id              INTEGER NOT NULL PRIMARY KEY,
    problem_id      INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
    contest_id      INTEGER NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
    code            CHAR,
    /* See $cats::problem_st constants */
    status          INTEGER DEFAULT 1 NOT NULL,
    testsets        VARCHAR(200),
    points_testsets VARCHAR(200),
    max_points      INTEGER,
    tags            VARCHAR(200),
    limits_id       INTEGER REFERENCES limits(id),
    UNIQUE (problem_id, contest_id)
);
ALTER TABLE contest_problems
    ADD CONSTRAINT chk_contest_problems_st CHECK (0 <= status AND status <= 5);

CREATE TABLE problem_sources (
    id          INTEGER NOT NULL PRIMARY KEY,
    stype       INTEGER, /* stype: See Constants.pm */
    problem_id  INTEGER REFERENCES problems(id) ON DELETE CASCADE,
    de_id       INTEGER NOT NULL REFERENCES default_de(id) ON DELETE CASCADE,
    src         BLOB,
    fname       VARCHAR(200),
    name        VARCHAR(60),
    input_file  VARCHAR(200),
    output_file VARCHAR(200),
    guid        VARCHAR(100), /* For cross-contest references. */
    time_limit  FLOAT, /* In seconds. */
    memory_limit INTEGER, /* In mebibytes. */
    write_limit INTEGER, /* In bytes */
    main        VARCHAR(200)
);
ALTER TABLE problem_sources
    ADD CONSTRAINT chk_problem_sources_1 CHECK (0 <= stype AND stype <= 15);
CREATE INDEX ps_guid_idx ON problem_sources(guid);

CREATE TABLE problem_sources_import (
    problem_id  INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
    /* Reference to problem_sources.guid, no constraint to simplify update of the referenced problem. */
    guid        VARCHAR(100) NOT NULL,
    PRIMARY KEY (problem_id, guid)
);

CREATE TABLE problem_attachments (
    id          INTEGER NOT NULL PRIMARY KEY,
    problem_id  INTEGER REFERENCES problems(id) ON DELETE CASCADE,
    name        VARCHAR(200) NOT NULL,
    file_name   VARCHAR(200) NOT NULL,
    data        BLOB
);

CREATE TABLE pictures (
    id          INTEGER NOT NULL PRIMARY KEY,
    problem_id  INTEGER REFERENCES problems(id) ON DELETE CASCADE,
    name        VARCHAR(30) NOT NULL,
    extension   VARCHAR(20),
    pic         BLOB
);

CREATE TABLE tests (
    problem_id      INTEGER REFERENCES problems(id) ON DELETE CASCADE,
    rank            INTEGER CHECK (rank > 0),
    input_validator_id INTEGER DEFAULT NULL REFERENCES problem_sources(id) ON DELETE CASCADE,
    generator_id    INTEGER DEFAULT NULL REFERENCES problem_sources(id) ON DELETE CASCADE,
    param           VARCHAR(200) DEFAULT NULL,
    std_solution_id INTEGER DEFAULT NULL REFERENCES problem_sources(id) ON DELETE CASCADE,
    in_file         BLOB, /* For generated input, length = min(in_file_size, save_input_prefix). */
    in_file_size    INTEGER, /* Size of generated input, else NULL. */
    out_file        BLOB, /* For generated answer, length = min(out_file_size, save_answer_prefix). */
    out_file_size   INTEGER, /* Size of generated answer, else NULL. */
    points          INTEGER,
    gen_group       INTEGER
);

CREATE TABLE testsets (
    id              INTEGER NOT NULL,
    problem_id      INTEGER NOT NULL,
    name            VARCHAR(200) NOT NULL,
    tests           VARCHAR(200) NOT NULL,
    points          INTEGER,
    comment         VARCHAR(400),
    /* Do not display individual test results until defreeze_date. */
    hide_details    SMALLINT DEFAULT 0 NOT NULL CHECK (hide_details IN (0, 1)),
    depends_on      VARCHAR(200),
    CONSTRAINT testsets_pk PRIMARY KEY (id),
    /*CONSTRAINT testsets_uniq UNIQUE (name, problem_id),*/
    FOREIGN KEY (problem_id) REFERENCES problems (id) ON DELETE CASCADE
);

CREATE TABLE samples (
    problem_id      INTEGER REFERENCES problems(id) ON DELETE CASCADE,
    rank            INTEGER CHECK (rank > 0),
    in_file         BLOB,
    out_file        BLOB
);

/* id is the same as reqs, questions or messages */
CREATE TABLE events (
    id         INTEGER NOT NULL PRIMARY KEY,
    /* 1 - req, 3 - message */
    event_type SMALLINT DEFAULT 0 NOT NULL,
    ts         TIMESTAMP NOT NULL,
    account_id INTEGER REFERENCES accounts(id) ON DELETE CASCADE,
    ip         VARCHAR(100) DEFAULT ''
);
CREATE DESCENDING INDEX idx_events_ts ON events(ts);

CREATE TABLE questions (
    id          INTEGER NOT NULL PRIMARY KEY,
    clarified   INTEGER DEFAULT 0 CHECK (clarified IN (0, 1)),
    submit_time TIMESTAMP,
    clarification_time  TIMESTAMP,
    question    BLOB,
    answer      BLOB,
    account_id  INTEGER REFERENCES contest_accounts(id) ON DELETE CASCADE,
    received    INTEGER DEFAULT 0 CHECK (received IN (0, 1))
);
CREATE DESCENDING INDEX idx_questions_submit_time ON questions(submit_time);

CREATE TABLE messages (
    id          INTEGER NOT NULL PRIMARY KEY,
    text        BLOB SUB_TYPE TEXT,
    received    INTEGER DEFAULT 0 CHECK (received IN (0, 1)),
    broadcast   INTEGER DEFAULT 0 CHECK (broadcast IN (0, 1)),
    contest_id  INTEGER REFERENCES contests(id) ON DELETE CASCADE,
    problem_id  INTEGER REFERENCES problems(id) ON DELETE CASCADE
);

CREATE TABLE reqs (
    id          INTEGER NOT NULL PRIMARY KEY,
    account_id  INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    problem_id  INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
    contest_id  INTEGER REFERENCES contests(id) ON DELETE CASCADE,
    submit_time TIMESTAMP,
    test_time   TIMESTAMP, /* Time of testing start. */
    result_time TIMESTAMP, /* Time of testing finish. */
    state       INTEGER,
    failed_test INTEGER,
    judge_id    INTEGER REFERENCES judges(id) ON DELETE SET NULL,
    received    INTEGER DEFAULT 0 CHECK (received IN (0, 1)),
    points      INTEGER,
    testsets    VARCHAR(200),
    limits_id   INTEGER REFERENCES limits(id),
    elements_count INTEGER DEFAULT 0,
    tag         VARCHAR(200)
);
CREATE DESCENDING INDEX idx_reqs_submit_time ON reqs(submit_time);

CREATE TABLE req_de_bitmap_cache (
    req_id      INTEGER NOT NULL REFERENCES reqs(id) ON DELETE CASCADE,
    version     INTEGER NOT NULL,
    de_bits1    BIGINT DEFAULT 0,
    de_bits2    BIGINT DEFAULT 0
);

CREATE TABLE req_groups (
    group_id    INTEGER NOT NULL REFERENCES reqs(id) ON DELETE CASCADE,
    element_id  INTEGER NOT NULL REFERENCES reqs(id) ON DELETE CASCADE,
    CONSTRAINT req_groups_pk PRIMARY KEY (group_id, element_id)
);

CREATE TABLE req_details (
    req_id            INTEGER NOT NULL REFERENCES REQS(ID) ON DELETE CASCADE,
    test_rank         INTEGER NOT NULL /*REFERENCES TESTS(RANK) ON DELETE CASCADE*/,
    result            INTEGER,
    points            INTEGER,
    time_used         FLOAT,
    memory_used       INTEGER,
    disk_used         INTEGER,
    checker_comment   VARCHAR(400),

    UNIQUE(req_id, test_rank)
);

CREATE TABLE solution_output (
    req_id          INTEGER NOT NULL,
    test_rank       INTEGER NOT NULL,
    output          BLOB NOT NULL,
    output_size     INTEGER NOT NULL, /* Size is reserved */
    create_time     TIMESTAMP NOT NULL,

    CONSTRAINT so_fk FOREIGN KEY (req_id, test_rank) REFERENCES req_details(req_id, test_rank) ON DELETE CASCADE
);

CREATE TABLE log_dumps (
    id      INTEGER NOT NULL PRIMARY KEY,
    dump    BLOB,
    req_id  INTEGER REFERENCES reqs(id) ON DELETE CASCADE
);

CREATE TABLE sources (
    req_id  INTEGER NOT NULL REFERENCES reqs(id) ON DELETE CASCADE,
    de_id   INTEGER NOT NULL REFERENCES default_de(id) ON DELETE CASCADE,
    src     BLOB,
    fname   VARCHAR(200),
    hash    CHAR(32) /* md5_hex */
);

CREATE TABLE keywords (
    id          INTEGER NOT NULL PRIMARY KEY,
    name_ru     VARCHAR(200),
    name_en     VARCHAR(200),
    code        VARCHAR(200)
);

CREATE TABLE problem_keywords (
    problem_id  INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
    keyword_id  INTEGER NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
    PRIMARY KEY (problem_id, keyword_id)
);

CREATE TABLE contest_groups (
    id     INTEGER NOT NULL PRIMARY KEY,
    name   VARCHAR(200) NOT NULL,
    /* Comma-separated sorted list of contest ids. */
    clist  VARCHAR(200)
);
CREATE INDEX idx_contest_groups_clist ON contest_groups(clist);

CREATE TABLE prizes (
    id     INTEGER NOT NULL PRIMARY KEY,
    cg_id  INTEGER NOT NULL REFERENCES contest_groups(id) ON DELETE CASCADE,
    name   VARCHAR(200) NOT NULL,
    rank   INTEGER NOT NULL
);

CREATE GENERATOR key_seq;
CREATE GENERATOR login_seq;

SET GENERATOR key_seq TO 1000;

CREATE SEQUENCE de_bitmap_cache_seq;
ALTER SEQUENCE de_bitmap_cache_seq RESTART WITH 1000;
