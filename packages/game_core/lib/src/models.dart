enum Phase { lobby, choosingCategory, answering, voting, roundResults, gameOver }

/// Names must match the server's category strings (api/_lib/engine.ts).
enum Category { history, literature, football, movies, flags, songs, geography, cars, whoPlayer, whoCelebrity }

/// Number of distinct avatars. Server assigns an index, app draws it.
const kAvatarCount = 12;
