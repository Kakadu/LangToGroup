module TMInterpreter where
    import TMType
    import ConfigType
    import Data.Set (Set)
    import qualified Data.Set as Set
    import Debug.Trace
    import Data.Maybe
    import Helpers

    checkCommandTapeToTape :: [([Square], State, [Square])] -> [TapeCommand] -> Bool
    checkCommandTapeToTape config command =
        case (command, config) of
            ([], []) -> True
            ((SingleTapeCommand ((r1, s1, l1), (r2, s2, l2)) : t1), ((r, s, l) : t2)) 
                            |   s1 == s && 
                                (r1 == emptySymbol && l1 == rightBoundingLetter && r2 /= emptySymbol && l2 == rightBoundingLetter && l == [rightBoundingLetter] ||
                                r /= [leftBoundingLetter] && r1 == (last r) && l1 == rightBoundingLetter && r2 == emptySymbol && l2 == rightBoundingLetter && l == [rightBoundingLetter] ||
                                (last r) == r1 && (head l) == l1 ||
                                r1 == emptySymbol && r2 == emptySymbol && l1 == rightBoundingLetter && l2 == l1) -> checkCommandTapeToTape t2 t1
                            | otherwise -> False

    getApplicableCommands :: [([Square], State, [Square])] -> [[TapeCommand]] -> [[TapeCommand]] -> [[TapeCommand]] 
    getApplicableCommands config commands acc =
        case commands of
            [] -> acc
            c : t   | checkCommandTapeToTape config c -> getApplicableCommands config t $ c : acc
                    | otherwise -> getApplicableCommands config t acc

    getApplicableCommandss :: [[[([Square], State, [Square])]]] -> [[TapeCommand]] -> [[[TapeCommand]]] -> [[[TapeCommand]]]
    getApplicableCommandss configss commands acc =
        case configss of
            [] -> reverse acc
            h : t -> getApplicableCommandss t commands $ (getApplicableCommands (last h) commands []) : acc

    applyCommand :: [([Square], State, [Square])] -> [TapeCommand] -> [[([Square], State, [Square])]] -> [([Square], State, [Square])] -> [[([Square], State, [Square])]]
    applyCommand config command configs acc = 
        case (command, config) of
            ([], []) -> configs ++ [reverse acc]
            (SingleTapeCommand ((r1, s1, l1), (r2, s2, l2)) : t1, (r, s, l) : t2) 
                    --insert
                    | r1 == emptySymbol && r2 /= emptySymbol && l1 == rightBoundingLetter && l2 == l1 -> applyCommand t2 t1 configs $ (r ++ [r2], s2, l) : acc
                    --remove
                    | l1 == rightBoundingLetter && r2 == emptySymbol && r1 /= emptySymbol && l2 == l1 -> applyCommand t2 t1 configs $ (init r, s2, l) : acc
                    --stay
                    | r1 == emptySymbol && r2 == emptySymbol && l1 == rightBoundingLetter && l2 == l1 -> applyCommand t2 t1 configs $ (r, s2, l) : acc
                    --replace
                    | r1 == (last r) && l1 == (head l) -> applyCommand t2 t1 configs $ (init r ++ [r2], s2, l2 : (tail l)) : acc
                    | otherwise -> error ("Wrong command " ++ show command)
            ([], _) -> configs

    applyCommands :: [[([Square], State, [Square])]] -> [[TapeCommand]] -> [[[([Square], State, [Square])]]] -> [[[([Square], State, [Square])]]]
    applyCommands configs commands acc =
        case commands of
            [] -> acc
            h : t -> applyCommands configs t $ (applyCommand (last configs) h configs []) : acc
    
    applyCommandss :: [[[([Square], State, [Square])]]] -> [[[TapeCommand]]] -> [[[([Square], State, [Square])]]] -> [[[([Square], State, [Square])]]]
    applyCommandss configss commandss acc =
        case (configss, commandss) of
            ([], []) -> acc
            (configs : t1, commands : t2) -> applyCommandss t1 t2 $ (applyCommands configs commands []) ++ acc
            _ -> error "Commandss and configss don't match"
    
    checkFinalEmptyStates :: [State] -> [([Square], State, [Square])] -> Bool
    checkFinalEmptyStates accessStates config =
        case (accessStates, config) of
            ([], []) -> True
            (s1 : t1, ([l2], s2, [r2]) : t2) | l2 ==  leftBoundingLetter && r2 == rightBoundingLetter && s1 == s2 -> checkFinalEmptyStates t1 t2
            _ -> False

    isHereEmptyConfigss :: [State] -> [[[([Square], State, [Square])]]] -> Maybe [[([Square], State, [Square])]]
    isHereEmptyConfigss accessStates configss =
        case configss of
            [] -> Nothing
            h : t   | checkFinalEmptyStates accessStates (last h) -> Just h
                    | otherwise -> isHereEmptyConfigss accessStates t
            

    startInterpreting accessStates configss commands =
        case isHereEmptyConfigss accessStates configss of
            Just configs -> configs
            Nothing -> startInterpreting accessStates (applyCommandss configss (getApplicableCommandss configss commands []) []) commands

    interpretTM :: [String] -> TM -> Configs
    interpretTM input (TM
        (InputAlphabet inputAlphabet,
        tapeAlphabets, 
        MultiTapeStates multiTapeStates, 
        Commands commands, 
        StartStates startStates, 
        AccessStates accessStates)) = do
            -- check input
            let inputSquare = mapValue input
            let isInputCorrect = Set.isSubsetOf (Set.fromList inputSquare) inputAlphabet
            let startConfigss = [[([leftBoundingLetter] ++ inputSquare, (head startStates), [rightBoundingLetter]) : 
                                    (map (\s -> ([leftBoundingLetter], s, [rightBoundingLetter])) (tail startStates))]]
            case isInputCorrect of
                False -> error "Incorrect input"
                True -> Configs (startInterpreting accessStates startConfigss (Set.toList commands))
            