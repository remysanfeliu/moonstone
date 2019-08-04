//
//  MoonStone.swift
//  MoonStone
//
//  Created by SANFELIU Remy on 02/08/2019.
//  Copyright © 2019 Rémy Sanfeliu. All rights reserved.
//

import Foundation
import Version

public class MoonStone {
    
    /// A reference to the bundle MoonStone is managing the update for
    private var clientBundle: Bundle
    
    /// The UserDefaults instance in which the current version and other registries will be stored
    /// for MoonStone
    private var userDefaults: UserDefaults
    
    /// The prefix of the keys used by MoonStone in the UserDefaults
    private var defaultsMoonstonePrefix: String
    
    /// A flag indicating if MoonStone needs to perform predicate evolutions before versions
    private var runPredicatesBeforeVersion: Bool
    
    /// A list of Evolution based on their stages. Is not ordered.
    private var evolStagesFromVersion = [Version:Evolution]()
    
    /// A list of Evolution based on predicates. Evolutions will be applied in the order
    /// in which the Evolution have been provided, but after the version Evolutions. Evolutions
    /// from predicates will be ran even at first run (for instance, if using MoonStone for the
    /// first time on an existing install
    private var evolStagesFromPredicates = [EvolutionBasedOnPredicate]()
    
    public init(for bundle: Bundle,
                userDefaults: UserDefaults = UserDefaults.standard,
                defaultsMoonstonePrefix: String = "MoonStone",
                runPredicatesBeforeVersion: Bool = false) {
        self.clientBundle = bundle
        self.userDefaults = userDefaults
        self.defaultsMoonstonePrefix = defaultsMoonstonePrefix
        self.runPredicatesBeforeVersion = runPredicatesBeforeVersion
    }
    
    public func evolution(to stage: String, _ action: @escaping Evolution) throws -> MoonStone {
        guard let v = Version(stage) else {
            throw MoonStoneError.couldNotParseCurrentVersion
        }
        if (evolStagesFromVersion[v] != nil) {
            Log.it.w("An evolution has already been added for the stage \(stage). Will be overriden")
        }
        evolStagesFromVersion[v] = action
        return self
    }
    
    public func evolution(if predicate: @escaping EvolutionPredicate, description: String? = nil, _ action: @escaping Evolution) -> MoonStone {
        evolStagesFromPredicates.append((predicate: predicate, description: description, evolution: action))
        return self
    }
    
    public func evolve() -> EvolutionResult {
        if self.runPredicatesBeforeVersion {
            return self.evolveWithPredicates() ** self.evolveWithVersions()
        } else {
            return self.evolveWithVersions() ** self.evolveWithPredicates()
        }
    }
    
}

// MARK: - Supporting the [evolve()] method

extension MoonStone {
    internal func sortEvolutionsByVersion() -> [(key: Version, value: Evolution)] {
        return self.evolStagesFromVersion.sorted {
            return $0.key < $1.key
        }
    }
    
    internal func evolveWithVersions() -> EvolutionResult {
        
        guard let currentVersion = Version(self.getClientBundleVersionString()) else {
            return .failed(error: .couldNotParseCurrentVersion)
        }
        
        let previousVersionString = self.userDefaults.string(forKey: "\(defaultsMoonstonePrefix).version")
        var previousVersion: Version
        if previousVersionString == nil {
            self.userDefaults.set(currentVersion, forKey: "\(defaultsMoonstonePrefix).version")
            previousVersion = currentVersion
        } else {
            previousVersion = Version(previousVersionString!)
        }
        
        if (previousVersion < currentVersion) {
            for (version, evolution) in self.evolStagesFromVersion {
                if previousVersion < version {
                    do {
                        try evolution()
                        self.userDefaults.set(version, forKey: "\(defaultsMoonstonePrefix).version")
                        previousVersion = version
                    } catch let error {
                        Log.it.e("An evolution based on version failed. The version will be locked to the latest valid update. Aborting evolutions.")
                        return .failed(error: .evolutionBasedOnVersionFailed(error: error, version: version.description))
                    }
                }
            }
        }
        
        return .succeeded
    }
    
    internal func evolveWithPredicates() -> EvolutionResult {
        for (predicate, description, evolution) in evolStagesFromPredicates {
            if predicate() {
                do {
                    try evolution()
                } catch let error {
                    Log.it.e("An evolution based on a predicate failed. Aborting evolutions.")
                    return .failed(error: .evolutionBasedOnPredicateFailed(error: error, description: description))
                }
            }
        }
        return .succeeded
    }
}

// MARK: - Utils and misc.

extension MoonStone {
    /// Grabs the version string of the client Bundle, by accessing the Bundle dictionarty
    internal func getClientBundleVersionString() -> String {
        let version = clientBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = clientBundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        return version == build ? "\(version)" : "\(version)+\(build)"
    }
}

infix operator **
func **(lhs: EvolutionResult, rhs: EvolutionResult) -> EvolutionResult {
    if case EvolutionResult.failed = lhs {
        return lhs
    } else if case EvolutionResult.failed = rhs {
        return rhs
    } else {
        return lhs
    }
}

public enum EvolutionResult {
    case succeeded
    case failed(error: MoonStoneError)
}

public enum MoonStoneError: Error {
    
    /// The current version number could not be parsed from the Bundle provided in the initializer
    case couldNotParseCurrentVersion
    
    /// An evolution based on a predicate has failed. Passing the description for easier debug
    case evolutionBasedOnPredicateFailed(error: Error, description: String?)
    
    /// An evolution based on a version has failed
    case evolutionBasedOnVersionFailed(error: Error, version: String)
    
}

public typealias Evolution = () throws -> Void
public typealias EvolutionPredicate = () -> Bool
public typealias EvolutionBasedOnPredicate = (predicate: EvolutionPredicate, description: String?, evolution: Evolution)
