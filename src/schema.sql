CREATE TABLE room (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
name TEXT DEFAULT NULL,
description TEXT DEFAULT NULL,
level INTEGER DEFAULT NULL REFERENCES level (id)
);

CREATE TABLE objects (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
name TEXT DEFAULT NULL,
detail TEXT DEFAULT NULL,
room_id INTEGER DEFAULT NULL REFERENCES room (id)
);

CREATE TABLE exittypes (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
name TEXT DEFAULT NULL,
possible_exit_id INTEGER DEFAULT NULL REFERENCES possible_exits (id)
);

CREATE TABLE exits (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
type_id INTEGER DEFAULT NULL REFERENCES exittypes (id),
room_id INTEGER DEFAULT NULL REFERENCES room (id)
);

CREATE TABLE level (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
name TEXT DEFAULT NULL,
parent INTEGER DEFAULT NULL REFERENCES level (id)
);

CREATE TABLE triggers (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
name TEXT DEFAULT NULL,
script TEXT DEFAULT NULL,
type_id INTEGER DEFAULT NULL REFERENCES triggertypes (id),
room_id INTEGER DEFAULT NULL REFERENCES room (id)
);

CREATE TABLE conversations (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
level INTEGER DEFAULT NULL REFERENCES level (id)
);

CREATE TABLE conversationdata (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
text TEXT DEFAULT NULL,
conversation_id INTEGER DEFAULT NULL REFERENCES conversations (id),
parent INTEGER DEFAULT NULL REFERENCES conversationdata (id)
);

CREATE TABLE responses (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
text TEXT DEFAULT NULL,
promptedtext INTEGER DEFAULT NULL REFERENCES conversationdata (id),
childdata INTEGER DEFAULT NULL REFERENCES conversationdata (id)
);

CREATE TABLE possible_exits (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
exit INTEGER DEFAULT NULL REFERENCES exittypes (id)
);

CREATE TABLE triggertypes (
id INTEGER DEFAULT NULL PRIMARY KEY AUTOINCREMENT,
name TEXT DEFAULT NULL
);