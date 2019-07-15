module Helpers where
    import GrammarType
    import TMType

    getDisjoinLetter :: String -> String
    getDisjoinLetter letter = letter ++ "'"

    getDisjoinState :: State -> State
    getDisjoinState (State state) = State (state ++ "'") 

    getDisjoinSquare :: Square -> Square
    getDisjoinSquare (Value s) = Value (s ++ "'")
    getDisjoinSquare c = c --TODO

    getDisjoinSymbol :: Symbol -> Square
    getDisjoinSymbol letter = 
        case letter of
            T (Terminal c) -> Value $ c ++ "'"
            N (Nonterminal c) -> Value c
            E (Epsilon c) -> Value c

    mapValue x = Value x