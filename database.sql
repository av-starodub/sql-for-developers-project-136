CREATE TYPE program_type_enum AS ENUM ('INTENSIVE', 'PROFESSION');

CREATE TABLE programs
(
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR           NOT NULL,
    price        NUMERIC(12, 2)    NOT NULL CHECK (price >= 0),
    program_type program_type_enum NOT NULL,
    created_at   TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

CREATE TABLE modules
(
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR     NOT NULL,
    description TEXT,
    is_deleted  BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE courses
(
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR     NOT NULL,
    description TEXT,
    is_deleted  BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE lessons
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR     NOT NULL,
    content    TEXT,
    video_url  TEXT,
    position   INTEGER     NOT NULL,
    is_deleted BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    course_id  BIGINT      NOT NULL REFERENCES courses (id) ON DELETE RESTRICT,
    CONSTRAINT lessons_course_position_uq UNIQUE (course_id, position)
);

CREATE TABLE module_courses
(
    module_id BIGINT NOT NULL REFERENCES modules (id) ON DELETE CASCADE,
    course_id BIGINT NOT NULL REFERENCES courses (id) ON DELETE CASCADE,
    PRIMARY KEY (module_id, course_id)
);

CREATE TABLE program_modules
(
    program_id BIGINT NOT NULL REFERENCES programs (id) ON DELETE CASCADE,
    module_id  BIGINT NOT NULL REFERENCES modules (id) ON DELETE CASCADE,
    PRIMARY KEY (program_id, module_id)
);
