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
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE TABLE courses
(
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR     NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE TABLE lessons
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR     NOT NULL,
    content    TEXT,
    video_url  TEXT,
    position   INTEGER     NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    course_id  BIGINT      NOT NULL REFERENCES courses (id) ON DELETE RESTRICT,
    CONSTRAINT lessons_course_position_uq UNIQUE (course_id, position)
);

CREATE TABLE course_modules
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

CREATE TYPE user_role_enum AS ENUM ('student', 'teacher', 'admin');

CREATE TABLE teaching_groups
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug       VARCHAR     NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users
(
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name              VARCHAR        NOT NULL UNIQUE,
    email             VARCHAR        NOT NULL UNIQUE,
    password_hash     TEXT           NOT NULL,
    role              user_role_enum NOT NULL,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    teaching_group_id BIGINT         NOT NULL
        REFERENCES teaching_groups (id) ON DELETE RESTRICT
);

CREATE INDEX idx_users_teaching_group_id ON users (teaching_group_id);

CREATE TYPE enrollment_status_enum AS ENUM (
    'active',
    'pending',
    'cancelled',
    'completed'
);

CREATE TYPE payment_status_enum AS ENUM (
    'pending',
    'paid',
    'failed',
    'refunded'
);

CREATE TYPE program_completion_status_enum AS ENUM (
    'active',
    'completed',
    'pending',
    'cancelled'
);

CREATE TABLE enrollments
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    BIGINT                 NOT NULL
        REFERENCES users (id) ON DELETE RESTRICT,
    program_id BIGINT                 NOT NULL
        REFERENCES programs (id) ON DELETE RESTRICT,
    status     enrollment_status_enum NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ            NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ            NOT NULL DEFAULT NOW(),
    CONSTRAINT enrollments_user_program_uq UNIQUE (user_id, program_id)
);

CREATE INDEX idx_enrollments_user_id ON enrollments (user_id);
CREATE INDEX idx_enrollments_program_id ON enrollments (program_id);

CREATE TABLE payments
(
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id BIGINT              NOT NULL
        REFERENCES enrollments (id) ON DELETE CASCADE,
    amount        NUMERIC(12, 2)      NOT NULL CHECK (amount >= 0),
    status        payment_status_enum NOT NULL DEFAULT 'pending',
    paid_at       TIMESTAMPTZ,
    created_at    TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_enrollment_id ON payments (enrollment_id);

CREATE TABLE program_completions
(
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id      BIGINT                         NOT NULL
        REFERENCES users (id) ON DELETE RESTRICT,
    program_id   BIGINT                         NOT NULL
        REFERENCES programs (id) ON DELETE RESTRICT,
    status       program_completion_status_enum NOT NULL DEFAULT 'pending',
    started_at   TIMESTAMPTZ                    NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ                    NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ                    NOT NULL DEFAULT NOW(),

    CONSTRAINT program_completions_user_program_uq UNIQUE (user_id, program_id)
);

CREATE INDEX idx_prog_comp_user_id ON program_completions (user_id);
CREATE INDEX idx_prog_comp_program_id ON program_completions (program_id);

CREATE TABLE certificates
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    BIGINT      NOT NULL
        REFERENCES users (id) ON DELETE RESTRICT,
    program_id BIGINT      NOT NULL
        REFERENCES programs (id) ON DELETE RESTRICT,
    url        TEXT        NOT NULL,
    issued_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT certificates_user_program_uq UNIQUE (user_id, program_id)
);

CREATE INDEX idx_certificates_user_id ON certificates (user_id);
CREATE INDEX idx_certificates_program_id ON certificates (program_id);

CREATE
EXTENSION IF NOT EXISTS ltree;

CREATE TABLE quizzes
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lesson_id  BIGINT      NOT NULL
        REFERENCES lessons (id) ON DELETE CASCADE,
    name       VARCHAR     NOT NULL,
    content    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT quizzes_lesson_uq UNIQUE (lesson_id)
);

CREATE INDEX idx_quizzes_lesson_id ON quizzes (lesson_id);

CREATE TABLE quiz_questions
(
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    quiz_id        BIGINT      NOT NULL
        REFERENCES quizzes (id) ON DELETE CASCADE,
    path           LTREE       NOT NULL,
    question_text  TEXT        NOT NULL,
    options        JSONB,
    correct_answer JSONB,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT quiz_questions_quiz_path_uq UNIQUE (quiz_id, path)
);

CREATE INDEX idx_quiz_questions_path ON quiz_questions USING GIST (quiz_id, path);

CREATE TABLE exercises
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lesson_id  BIGINT      NOT NULL
        REFERENCES lessons (id) ON DELETE CASCADE,
    name       VARCHAR     NOT NULL,
    url        TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT exercises_lesson_uq UNIQUE (lesson_id)
);

CREATE INDEX idx_exercises_lesson_id ON exercises (lesson_id);

CREATE TYPE blog_status_enum AS ENUM (
    'created',
    'in moderation',
    'published',
    'archived'
);

CREATE TABLE discussions
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lesson_id  BIGINT      NOT NULL
        REFERENCES lessons (id) ON DELETE CASCADE,
    user_id    BIGINT      NOT NULL
        REFERENCES users (id) ON DELETE RESTRICT,
    path       LTREE       NOT NULL,
    text       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT discussions_lesson_path_uq UNIQUE (lesson_id, path)
);

CREATE INDEX idx_discussions_lesson_path ON discussions USING GIST (lesson_id, path);
CREATE INDEX idx_discussions_user_id ON discussions (user_id);

CREATE TABLE blogs
(
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    BIGINT           NOT NULL
        REFERENCES users (id) ON DELETE RESTRICT,
    name       VARCHAR          NOT NULL,
    content    TEXT             NOT NULL,
    status     blog_status_enum NOT NULL DEFAULT 'created',
    created_at TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_blog_user_id ON blogs (user_id);
CREATE INDEX idx_blog_status ON blogs (status);
