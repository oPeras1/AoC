% Main predicate to read and process the file
readfile(Count) :-
    FileName = '../../input.txt',
    open(FileName, read, Stream),
    ler_linhas(Stream, Linhas),  % Lê todas as linhas do ficheiro
    close(Stream),               % Fecha o ficheiro
    separar_linhas(Linhas, Pares, Listas),
    filter_incorrect_updates(Pares, Listas, IncorrectUpdates),
    correct_updates(Pares, IncorrectUpdates, CorrectedUpdates),
    find_middle_pages(CorrectedUpdates, Middles),
    sum_list(Middles, Count),
    !.

correct_updates(_, [], []).
correct_updates(Rules, [Update|Rest], [Corrected|CorrectedRest]) :-
    sort_update(Rules, Update, Corrected),
    correct_updates(Rules, Rest, CorrectedRest).

sort_update(Rules, Update, Sorted) :-
    findall([X, Y], (member([X, Y], Rules), member(X, Update), member(Y, Update)), RelevantRules),
    predsort(compare_pages(RelevantRules), Update, Sorted).

compare_pages(Rules, '<', X, Y) :-
    member([X, Y], Rules), !.
compare_pages(Rules, '>', X, Y) :-
    member([Y, X], Rules), !.
compare_pages(_, '=', _, _).

filter_incorrect_updates(_, [], []).
filter_incorrect_updates(Rules, [Update|Rest], [Update|IncorrectUpdates]) :-
    \+ is_correct_order(Update, Rules),
    filter_incorrect_updates(Rules, Rest, IncorrectUpdates).
filter_incorrect_updates(Rules, [_|Rest], IncorrectUpdates) :-
    filter_incorrect_updates(Rules, Rest, IncorrectUpdates).

is_correct_order(Update, Rules) :-
    forall(member([X, Y], Rules), rule_respected(Update, X, Y)).

rule_respected(Update, X, Y) :-
    \+ (member(X, Update), member(Y, Update), nth1(IdxX, Update, X), nth1(IdxY, Update, Y), IdxX > IdxY).

% Finds middle pages of updates
find_middle_pages([], []).
find_middle_pages([Update|Rest], [Middle|Middles]) :-
    length(Update, Len),
    MiddleIndex is (Len // 2) + 1,
    nth1(MiddleIndex, Update, Middle),
    find_middle_pages(Rest, Middles).

% Lê todas as linhas de um fluxo e as retorna em uma lista
ler_linhas(Stream, []) :-
    at_end_of_stream(Stream), !.  % Condição de parada quando chega ao fim do ficheiro
ler_linhas(Stream, [Linha|Resto]) :-
    read_line_to_string(Stream, Linha), % Lê uma linha como string
    ler_linhas(Stream, Resto).

% Processa as linhas separando pares e listas
separar_linhas([], [], []).
separar_linhas([Linha|Resto], [[X, Y]|Pares], Listas) :-
    % Caso a linha contenha um par X|Y
    sub_atom(Linha, _, _, _, "|"),
    split_string(Linha, "|", "", [SX, SY]),
    number_string(X, SX),
    number_string(Y, SY),
    separar_linhas(Resto, Pares, Listas).
separar_linhas([Linha|Resto], Pares, [[X|Lista]|Listas]) :-
    % Caso a linha contenha uma lista X,Y,...
    \+ sub_atom(Linha, _, _, _, "|"),
    split_string(Linha, ",", "", Strings),
    maplist(number_string, [X|Lista], Strings),
    separar_linhas(Resto, Pares, Listas).