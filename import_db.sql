PRAGMA foreign_keys = ON;

CREATE TABLE users(
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

CREATE TABLE questions(
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    student_id INTEGER NOT NULL,

    FOREIGN KEY (student_id) REFERENCES users(id)
);

CREATE TABLE question_follows(
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,

    FOREIGN KEY (student_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies(
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,
    body TEXT NOT NULL,
    parent_id INTEGER,

    FOREIGN KEY (student_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (parent_id) REFERENCES replies(id)
);

CREATE TABLE question_likes(
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,

    FOREIGN KEY (student_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
    users (fname, lname)
VALUES
    ("Torben", "Ginsberg"),
    ("Alex", "Malos");

INSERT INTO
    questions (title, body, student_id)
VALUES
    ("syntax question", "what is the proper syntax", (SELECT id FROM users WHERE fname = 'Torben')),
    ("lunch question", "what's for lunch", (SELECT id FROM users WHERE fname = 'Alex'));

INSERT INTO
    question_follows (question_id, student_id)
VALUES
    (
        (SELECT id FROM questions WHERE title = 'syntax question'),
        (SELECT id FROM users WHERE fname = 'Alex')
    ),
    (
        (SELECT id FROM questions WHERE title = 'lunch question'),
        (SELECT id FROM users WHERE fname = 'Torben')
    ); =>

INSERT INTO
    question_likes (question_id, student_id)
VALUES
    (
        (SELECT id FROM questions WHERE title = 'syntax question'),
        (SELECT id FROM users WHERE fname = 'Alex')
    ),
    (
        (SELECT id FROM questions WHERE title = 'lunch question'),
        (SELECT id FROM users WHERE fname = 'Torben')
    );

INSERT INTO
    replies (question_id, student_id, body, parent_id)
VALUES
    (
        (SELECT id FROM questions WHERE title = 'syntax question'),
        (SELECT id FROM users WHERE fname = 'Alex'),
        "you forgot the semicolon",
        NULL
    );

INSERT INTO
    replies (question_id, student_id, body, parent_id)
VALUES
    (
        (SELECT id FROM questions WHERE title = 'syntax question'),
        (SELECT id FROM users WHERE fname = 'Torben'),
        "thanks",
        (SELECT id FROM replies WHERE body = 'you forgot the semicolon')
    );