//
//  Utils.swift
//  LangSwiftUI
//
//  Created by blake on 2023-11-05.
//

import Foundation

public func isCloseMatch(input: String, suggestion: String) -> Bool {
    // If they are equal, it's a match.
    if input == suggestion {
        return true
    }
    
    // If they differ in length by more than 1, it cannot be a 1 char difference.
    if abs(input.count - suggestion.count) > 1 {
        return false
    }
    
    // If the input is longer by one character, check for a match with any single character removed.
    if input.count > suggestion.count {
        return (0..<input.count).contains {
            let modifiedInput = input.removing(at: $0)
            return modifiedInput == suggestion
        }
    }
    
    // If the suggestion is longer by one character, check for a match with any single character removed from the suggestion.
    if suggestion.count > input.count {
        return (0..<suggestion.count).contains {
            let modifiedSuggestion = suggestion.removing(at: $0)
            return modifiedSuggestion == input
        }
    }
    
    // If they are the same length, check if they differ by only one character.
    let differingCharacters = zip(input, suggestion).filter { $0 != $1 }
    return differingCharacters.count <= 1
}

extension String {
    func removing(at index: Int) -> String {
        var modified = self
        let index = self.index(self.startIndex, offsetBy: index)
        modified.remove(at: index)
        return modified
    }
}
